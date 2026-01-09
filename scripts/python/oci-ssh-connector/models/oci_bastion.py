import oci


class OciBastion:
    def __init__(self, oci_config, selected_bastion_details):
        self.bastion_client = oci.bastion.BastionClient(oci_config)
        self.selected_bastion_details = selected_bastion_details

    @staticmethod
    def list_bastions(oci_config, compartment_id):
        # Create a bastion client
        bastion_client = oci.bastion.BastionClient(oci_config)

        # Get a list of bastion available
        bastions = bastion_client.list_bastions(
            compartment_id=compartment_id,
            bastion_lifecycle_state="ACTIVE",
        ).data

        # Return the list of bastions
        return bastions

    def get_active_pf_sessions(self, target_ip, target_port):
        # Get a list of port forwarding sessions available for this bastion
        sessions = self.bastion_client.list_sessions(
            bastion_id=self.selected_bastion_details.id,
            session_lifecycle_state="ACTIVE",
        ).data

        # Retrieve sessions that matches the target and return it
        return [
            session
            for session in sessions
            if session.target_resource_details.target_resource_private_ip_address
            == target_ip
            and str(session.target_resource_details.target_resource_port) == target_port
            and session.target_resource_details.session_type == "PORT_FORWARDING"
        ]

    def get_active_node_sessions(self, selected_instance, selected_username):
        # Get a list of sessions available for this bastion
        sessions = self.bastion_client.list_sessions(
            bastion_id=self.selected_bastion_details.id,
            session_lifecycle_state="ACTIVE",
        ).data

        # Retrieve sessions that matches the target and return it
        return [
            session
            for session in sessions
            if session.target_resource_details.target_resource_id
            == selected_instance.id
            and session.target_resource_details.target_resource_operating_system_user_name
            == selected_username
        ]

    def create_session(
        self,
        connection_name,
        target_resource_details,
        compute_ssh_pub_key,
    ):
        create_session_response = self.bastion_client.create_session(
            create_session_details=oci.bastion.models.CreateSessionDetails(
                bastion_id=self.selected_bastion_details.id,
                target_resource_details=target_resource_details,
                key_details=oci.bastion.models.PublicKeyDetails(
                    public_key_content=compute_ssh_pub_key
                ),
                # display_name=f"ssh-connection-{selected_instance.display_name.lower()}",
                display_name=connection_name,
                key_type="PUB",
                session_ttl_in_seconds=10800,
            )
        )

        # Get the bastion session
        get_session_response = self.bastion_client.get_session(
            session_id=create_session_response.data.id
        )

        # Wait for session to become active
        oci.wait_until(
            self.bastion_client,
            get_session_response,
            "lifecycle_state",
            "ACTIVE",
            max_interval_seconds=15,
            max_wait_seconds=600,
        )

        # Retrieve the session id
        return get_session_response.data.id

    def get_ssh_command(self, session_id, private_key_path):
        # Retrieve the ssh command
        sshc = self.bastion_client.get_session(session_id=session_id).data.ssh_metadata[
            "command"
        ]

        # Replace the private key path and return the ssh command
        return sshc.replace("<privateKey>", private_key_path)
