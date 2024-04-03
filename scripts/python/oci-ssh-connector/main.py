import os
import oci
import cutie
from dopplersdk import DopplerSDK

SECRETS_MAIN_PROJECT_NAME = "cloud-iac-main"
SECRETS_MAIN_CONFIG = "prd"
DOPPLER_MAIN_TOKEN = os.environ["DOPPLER_MAIN_TOKEN"]
COMPUTE_SSH_PRIVATE_KEY_PATH = os.environ["COMPUTE_SSH_PRIVATE_KEY_PATH"]

accounts = ["gaia", "helios"]


def make_a_choice(message, choices):
    # Show question
    print(message)

    # Get the seelciton index
    index = cutie.select(choices)

    # Get choice from user
    selection = choices[index]

    # Show output
    print(f"{selection} has been selected.")

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


def generate_oci_config(selected_account, secrets):
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
        "region": "af-johannesburg-1",
    }


def main():
    # Get the account from user choice
    _, selected_account = make_a_choice(
        message="Please choose an OCI account:", choices=accounts
    )

    # Get the secrets
    secrets = get_secrets()

    # Get the OCI config
    config = generate_oci_config(secrets=secrets, selected_account=selected_account)

    # Validate oci config
    oci.config.validate_config(config)

    # Create a compute client
    compute = oci.core.ComputeClient(config)

    # List instances
    instances = compute.list_instances(
        compartment_id=extract_secret(secrets, "OCI_GAIA_COMPARTMENT_PRODUCTION_ID"),
        lifecycle_state="RUNNING",
    ).data

    # Get instance names
    instances_names = [instance.display_name for instance in instances]

    # Get choice from user
    selected_instace_index, selected_instance = make_a_choice(
        message="Please choose the instance you want to connect to:",
        choices=instances_names,
    )

    # Get the selected instance data
    selected_instance = instances[selected_instace_index]

    # Create a bastion client
    bastion = oci.bastion.BastionClient(config)

    # Get a list of bastion available
    bastions = bastion.list_bastions(
        compartment_id=extract_secret(secrets, "OCI_GAIA_COMPARTMENT_PRODUCTION_ID"),
        bastion_lifecycle_state="ACTIVE",
    ).data

    # Get bastion names
    bastion_names = [bastion.name for bastion in bastions]

    # Get choice from user
    selected_bastion_index, selected_bastion = make_a_choice(
        message="Please choose the bastion you want to jump to:",
        choices=bastion_names,
    )

    # Get the selected bastion
    selected_bastion = bastions[selected_bastion_index]

    # Retrive the compute ssh pub key
    compute_ssh_pub_key = extract_secret(
        secrets, f"OCI_{selected_account.upper()}_COMPUTE_KEY_PUBLIC"
    )

    # Create the session
    create_session_response = bastion.create_session(
        create_session_details=oci.bastion.models.CreateSessionDetails(
            bastion_id=selected_bastion.id,
            target_resource_details=oci.bastion.models.CreateManagedSshSessionTargetResourceDetails(
                session_type="MANAGED_SSH",
                target_resource_operating_system_user_name="opc",
                target_resource_id=selected_instance.id,
                target_resource_port=22,
            ),
            key_details=oci.bastion.models.PublicKeyDetails(
                public_key_content=compute_ssh_pub_key
            ),
            display_name="test-sesh",
            key_type="PUB",
            session_ttl_in_seconds=1800,
        )
    )

    # Get the bastion session
    get_session_response = bastion.get_session(
        session_id=create_session_response.data.id
    )

    # Wait for session to become active
    oci.wait_until(bastion, get_session_response, "lifecycle_state", "ACTIVE")

    # Retrieve the ssh command
    ssh_command = bastion.get_session(
        session_id=get_session_response.data.id
    ).data.ssh_metadata["command"]

    # Replace the private key path
    ssh_command = ssh_command.replace("<privateKey>", COMPUTE_SSH_PRIVATE_KEY_PATH)

    print(f"SSH Command: {ssh_command}")


main()
