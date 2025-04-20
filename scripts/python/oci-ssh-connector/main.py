import os
import re
import oci
import cutie
import fileinput
import sys
from dopplersdk import DopplerSDK

SECRETS_MAIN_PROJECT_NAME = "cloud-iac-main"
SECRETS_MAIN_CONFIG = "prd"
DOPPLER_MAIN_TOKEN = os.environ["DOPPLER_MAIN_TOKEN"]
COMPUTE_SSH_PRIVATE_KEY_PATH = os.environ["COMPUTE_SSH_PRIVATE_KEY_PATH"]
SSH_CONFIG_PATH = os.environ["SSH_CONFIG_PATH"]

accounts = ["gaia", "helios", "poseidon"]
regions = ["af-johannesburg-1", "uk-london-1"]


def retrieve_bastion_ip(command):
    ip_pattern = r"\b(?:[0-9]{1,3}\.){3}[0-9]{1,3}\b"

    ip_address = re.search(ip_pattern, command)

    if ip_address:
        return ip_address.group(0)


def replace_proxy_command_for_host(file_path, host, new_command, bastion_ip):
    # Reformat host name
    host = f"oci-{host}".lower()
    inside_host_block = False
    with fileinput.input(files=(file_path), inplace=True, backup=".bak") as f:
        for line in f:
            stripped = line.strip()
            if stripped.startswith("Host ") and host in stripped:
                inside_host_block = True
            if inside_host_block and stripped.startswith("ProxyCommand"):
                line = "ProxyCommand " + new_command + "\n"
            if inside_host_block and stripped.startswith("HostName"):
                line = "HostName " + bastion_ip + "\n"
            if stripped == "":
                inside_host_block = False
            sys.stdout.write(line)


def extract_proxy_command(command):
    match = re.search(r'ProxyCommand\s*=\s*"([^"]*)"', command)
    if match:
        return match.group(1)
    else:
        return None


def make_a_choice(message, choices):
    # Show question
    print(message)

    # Get the seelciton index
    index = cutie.select(choices)

    # Get choice from user
    selection = choices[index]

    # Show output
    print(f"{selection} has been selected. \n")

    # Return the choice
    return index, selection


def extract_secret(secrets, name):
    return secrets.get(
        project=SECRETS_MAIN_PROJECT_NAME,
        config=SECRETS_MAIN_CONFIG,
        name=name,
    ).value["raw"]


def get_secrets():
    # * Secrets manager Doppler
    doppler = DopplerSDK()
    doppler.set_access_token(DOPPLER_MAIN_TOKEN)

    # * Return secrets
    return doppler.secrets


def generate_oci_config(selected_account, selected_region, secrets):
    #  Retrieve account info from secrets
    user_id = extract_secret(secrets, f"OCI_{selected_account.upper()}_USER_OCID")
    tenancy_id = extract_secret(secrets, f"OCI_{selected_account.upper()}_TENANCY_OCID")
    key_content = extract_secret(secrets, f"OCI_{selected_account.upper()}_PRIVATE_KEY")
    fingerprint = extract_secret(secrets, f"OCI_{selected_account.upper()}_FINGERPRINT")

    # Return the config
    return {
        "user": user_id,
        "key_content": key_content,
        "fingerprint": fingerprint,
        "tenancy": tenancy_id,
        "region": selected_region,
    }


def select_instance(secrets, selected_account, compute_client):
    # List instances
    instances = compute_client.list_instances(
        compartment_id=extract_secret(
            secrets, f"OCI_{selected_account.upper()}_COMPARTMENT_PRODUCTION_ID"
        ),
        lifecycle_state="RUNNING",
    ).data

    # Get instance names
    instances_names = [instance.display_name for instance in instances]

    # Get choice from user
    selected_instace_index, _ = make_a_choice(
        message="Please choose the instance you want to connect to:",
        choices=instances_names,
    )

    # Return the selected instance
    return instances[selected_instace_index]


def select_bastion(secrets, selected_account, bastion_client):
    # Get a list of bastion available
    bastions = bastion_client.list_bastions(
        compartment_id=extract_secret(
            secrets, f"OCI_{selected_account.upper()}_COMPARTMENT_PRODUCTION_ID"
        ),
        bastion_lifecycle_state="ACTIVE",
    ).data

    # Get bastion names
    bastion_names = [bastion.name for bastion in bastions]

    # Get choice from user
    selected_bastion_index, _ = make_a_choice(
        message="Please choose the bastion you want to jump to:",
        choices=bastion_names,
    )

    # Return the selected bastion
    return bastions[selected_bastion_index]


def get_active_sessions(bastion_client, selected_instance, selected_bastion):
    # Get a list of sessions available for this bastion
    sessions = bastion_client.list_sessions(
        bastion_id=selected_bastion.id,
        session_lifecycle_state="ACTIVE",
    ).data

    # Retrieve sessions that matches the target and return it
    return [
        session
        for session in sessions
        if session.target_resource_details.target_resource_id == selected_instance.id
    ]


def create_session(
    bastion_client, selected_bastion, selected_instance, compute_ssh_pub_key
):
    create_session_response = bastion_client.create_session(
        create_session_details=oci.bastion.models.CreateSessionDetails(
            bastion_id=selected_bastion.id,
            target_resource_details=oci.bastion.models.CreateManagedSshSessionTargetResourceDetails(
                session_type="MANAGED_SSH",
                target_resource_operating_system_user_name="th3pl4gu3",
                target_resource_id=selected_instance.id,
                target_resource_port=22,
            ),
            key_details=oci.bastion.models.PublicKeyDetails(
                public_key_content=compute_ssh_pub_key
            ),
            display_name=f"ssh-connection-{selected_instance.display_name.lower()}",
            key_type="PUB",
            session_ttl_in_seconds=10800,
        )
    )

    # Get the bastion session
    get_session_response = bastion_client.get_session(
        session_id=create_session_response.data.id
    )

    # Wait for session to become active
    oci.wait_until(
        bastion_client,
        get_session_response,
        "lifecycle_state",
        "ACTIVE",
        max_interval_seconds=15,
        max_wait_seconds=600,
    )

    # Retrieve the session id
    return get_session_response.data.id


def get_ssh_command(bastion_client, session_id):
    # Retrieve the ssh command
    ssh_command = bastion_client.get_session(session_id=session_id).data.ssh_metadata[
        "command"
    ]

    # Replace the private key path adn return the ssh command
    return ssh_command.replace("<privateKey>", COMPUTE_SSH_PRIVATE_KEY_PATH)


def main():
    # Get the account from user choice
    _, selected_account = make_a_choice(
        message="Please choose an OCI account:", choices=accounts
    )

    # Get the region from user choice
    _, selected_region = make_a_choice(
        message="Please choose an OCI region:", choices=regions
    )

    # Get the secrets
    secrets = get_secrets()

    # Get the OCI config
    config = generate_oci_config(secrets=secrets, selected_account=selected_account, selected_region=selected_region,)

    # Validate oci config
    oci.config.validate_config(config)

    # Create a compute client
    compute = oci.core.ComputeClient(config)

    # Get the selected instance data
    selected_instance = select_instance(
        secrets=secrets, selected_account=selected_account, compute_client=compute
    )

    # Create a bastion client
    bastion = oci.bastion.BastionClient(config)

    # Get the selected bastion
    selected_bastion = select_bastion(
        secrets=secrets, selected_account=selected_account, bastion_client=bastion
    )

    # Retrive the compute ssh pub key
    compute_ssh_pub_key = extract_secret(
        secrets, f"OCI_{selected_account.upper()}_COMPUTE_KEY_PUBLIC"
    )

    # Get all active sessions for this bastion
    active_sessions = get_active_sessions(
        bastion_client=bastion,
        selected_bastion=selected_bastion,
        selected_instance=selected_instance,
    )

    # If there are no active sessions
    # create a new one
    if len(active_sessions) == 0:
        # Print message
        print("There are no active sessions. Creating one...")

        # Create the session
        session_id = create_session(
            bastion_client=bastion,
            selected_bastion=selected_bastion,
            selected_instance=selected_instance,
            compute_ssh_pub_key=compute_ssh_pub_key,
        )
    else:
        # Print message
        print("There is an active session. Retrieving it...")

        # Get the active session
        session_id = active_sessions[0].id

    # Get the ssh command
    ssh_command = get_ssh_command(bastion_client=bastion, session_id=session_id)

    # Extract the proxy command
    proxy_command = extract_proxy_command(ssh_command)

    # Retrieve the bastion IP
    bastion_ip = retrieve_bastion_ip(ssh_command)

    print(f"bi: {bastion_ip} pc: {proxy_command}")

    # Replace the proxy command in the ssh config file
    replace_proxy_command_for_host(
        file_path=SSH_CONFIG_PATH,
        host=selected_instance.display_name,
        new_command=proxy_command,
        bastion_ip=bastion_ip,
    )

    # Print the command
    print(f"SSH command: {ssh_command}")


main()
