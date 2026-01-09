import oci


class OciInstance:
    def __init__(self, oci_config, selected_instance):
        self.compute_client = oci.core.ComputeClient(oci_config)
        self.selected_instance = selected_instance

    @staticmethod
    def list_instances(oci_config, compartment_id):
        # Create a compute client
        compute_client = oci.core.ComputeClient(oci_config)

        # Get a list of instances available
        instances = compute_client.list_instances(
            compartment_id=compartment_id,
            lifecycle_state="RUNNING",
        ).data

        # Return the list of instances
        return instances
