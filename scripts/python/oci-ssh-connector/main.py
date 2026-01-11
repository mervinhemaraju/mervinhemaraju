import os
import oci
import logging
from models.oci_oke import OciOke
from models.oci_bastion import OciBastion
from models.oci_instance import OciInstance
from models.doppler_secrets import DopplerSecrets
from core.accounts import Accounts
from core.connection_type import ConnectionType
from core.functions import (
    make_a_choice,
    extract_proxy_command,
    replace_proxy_command_for_host,
    retrieve_bastion_ip,
)
from utils.mappings import ACCOUNT_REGION_MAPPING

# Set logging level
logging.basicConfig(level=logging.INFO)

# Set variables
SECRETS_PROJECT_CLOUD_OCI = "cloud-oci-creds"
SECRETS_CONFIG = "prd"
DOPPLER_MAIN_TOKEN = os.environ["DOPPLER_MAIN_TOKEN"]
COMPUTE_SSH_PRIVATE_KEY_PATH = os.environ["COMPUTE_SSH_PRIVATE_KEY_PATH"]
SSH_CONFIG_PATH = os.environ["SSH_CONFIG_PATH"]

usernames = ["th3pl4gu3", "opc"]


def main():
    # Define an empty list of active_bastion_sessions
    active_bastion_sessions = []
    session_target_resource = None
    session_name = None

    # Intiialize doppler secrets
    doppler_oci_secrets = DopplerSecrets(
        token=DOPPLER_MAIN_TOKEN,
        project=SECRETS_PROJECT_CLOUD_OCI,
        config=SECRETS_CONFIG,
    )

    _, sa = make_a_choice(
        message="Please choose an OCI account:", choices=Accounts.values()
    )

    # Convert the account to enum
    selected_account = Accounts(sa)

    # Determine the compartment id
    compartment_id = doppler_oci_secrets.extract_secret(
        f"OCI_{selected_account.value.upper()}_COMPARTMENT_PRODUCTION_ID"
    )

    # Get the connection type from user choice
    _, sct = make_a_choice(
        message="Please choose a connection type:", choices=ConnectionType.values()
    )

    # Convert the connection type to enum
    selected_connection_type = ConnectionType(sct)

    # Retrieve the region
    selected_region = ACCOUNT_REGION_MAPPING[selected_account]

    # Get the OCI config
    config = {
        "user": doppler_oci_secrets.extract_secret(
            f"OCI_{selected_account.upper()}_USER_OCID"
        ),
        "key_content": doppler_oci_secrets.extract_secret("OCI_API_KEY_PRIVATE"),
        "fingerprint": doppler_oci_secrets.extract_secret("OCI_API_FINGERPRINT"),
        "tenancy": doppler_oci_secrets.extract_secret(
            f"OCI_{selected_account.upper()}_TENANCY_OCID"
        ),
        "region": selected_region,
    }

    # Validate oci config
    oci.config.validate_config(config)

    # List the bastions
    bastions = OciBastion.list_bastions(
        oci_config=config,
        compartment_id=compartment_id,
    )

    # If there are no bastions
    if len(bastions) == 0:
        logging.error(f"No bastions found in account {selected_account.value}")
        exit(0)

    # Get the selected bastion
    # Get choice from user
    selected_bastion_index, _ = make_a_choice(
        message="Please choose the bastion you want to jump to:",
        choices=[bastion.name for bastion in bastions],
    )

    # Return the selected bastion
    selected_bastion = bastions[selected_bastion_index]

    # Create a bastion object
    bastion_object = OciBastion(
        oci_config=config,
        selected_bastion_details=selected_bastion,
    )

    # Check if the connection type is node
    if selected_connection_type == ConnectionType.K8_API:
        # List the clusters
        clusters = OciOke.list_clusters(
            oci_config=config,
            compartment_id=compartment_id,
        )

        # If there are no clusters
        if len(clusters) == 0:
            logging.error(f"No clusters found in account {selected_account.value}")
            exit(0)

        # Get the cluster from user choice
        _, selected_cluster = make_a_choice(
            message="Please choose a cluster:",
            choices=[
                f"{cluster.name}:{cluster.endpoints.private_endpoint}"
                for cluster in clusters
            ],
        )

        # Get the selected cluster split
        selected_cluster_split = selected_cluster.split(":")

        # Get the cluster name
        selected_cluster_name = selected_cluster_split[0]

        # Get the cluster ip
        selected_cluster_ip = selected_cluster_split[1]

        # Get the cluster port
        selected_cluster_port = selected_cluster_split[2]

        # Get active bastion pf sessions
        active_sessions = bastion_object.get_active_pf_sessions(
            target_ip=selected_cluster_ip,
            target_port=selected_cluster_port,
        )

        # Add the active sessions to the list
        active_bastion_sessions.extend(active_sessions)

        # Set the target resource details
        session_target_resource = (
            oci.bastion.models.CreateManagedSshSessionTargetResourceDetails(
                session_type="PORT_FORWARDING",
                target_resource_private_ip_address=selected_cluster_ip,
                target_resource_port=int(selected_cluster_port),
            )
        )

        # Set the session name
        session_name = (
            f"k8-api-connection-{selected_cluster_name}-{selected_cluster_port}"
        )

    else:
        # Get the username from user choice
        _, selected_username = make_a_choice(
            message="Please choose a username:", choices=usernames
        )

        # Create a new instance object
        instances = OciInstance.list_instances(
            oci_config=config,
            compartment_id=compartment_id,
        )

        # Get the instance names
        instances_names = [instance.display_name for instance in instances]

        # Get choice from user
        selected_instace_index, _ = make_a_choice(
            message="Please choose the instance you want to connect to:",
            choices=instances_names,
        )

        # Get the selected instance
        selected_instance = instances[selected_instace_index]

        # Get all active sessions for this bastion
        active_sessions = bastion_object.get_active_node_sessions(
            selected_instance=selected_instance,
            selected_username=selected_username,
        )

        # Add the active sessions to the list
        active_bastion_sessions.extend(active_sessions)

        # Set the target resource details
        session_target_resource = (
            oci.bastion.models.CreateManagedSshSessionTargetResourceDetails(
                session_type="MANAGED_SSH",
                target_resource_operating_system_user_name=selected_username,
                target_resource_id=selected_instance.id,
                target_resource_port=22,
            )
        )

        # Set the session name
        session_name = f"ssh-connection-{selected_instance.display_name.lower()}"

    # If there are no active sessions
    # create a new one
    if len(active_bastion_sessions) == 0:
        # Print message
        print("There are no active sessions. Creating one...")

        # Retrive the compute ssh pub key
        compute_ssh_pub_key = doppler_oci_secrets.extract_secret(
            "OCI_COMPUTE_KEY_PUBLIC"
        )

        # Create the session
        session_id = bastion_object.create_session(
            target_resource_details=session_target_resource,
            compute_ssh_pub_key=compute_ssh_pub_key,
            connection_name=session_name,
        )
    else:
        # Print message
        print("There is an active session. Retrieving it...")

        # Get the active session
        session_id = active_sessions[0].id

    # Get the ssh command
    ssh_command = bastion_object.get_ssh_command(
        session_id=session_id,
        private_key_path=COMPUTE_SSH_PRIVATE_KEY_PATH,
    )

    # if connection type is node
    if selected_connection_type == ConnectionType.K8_API:
        # Replace the local port
        ssh_command = ssh_command.replace("<localPort>", selected_cluster_port)

    else:
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
