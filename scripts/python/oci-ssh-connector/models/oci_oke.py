import oci


class OciOke:
    def __init__(self, oci_config):
        self.oke_client = oci.container_engine.ContainerEngineClient(oci_config)

    @staticmethod
    def list_clusters(oci_config, compartment_id):
        # Create an OKE client
        oke_client = oci.container_engine.ContainerEngineClient(oci_config)

        # List the clusters
        clusters = oke_client.list_clusters(
            compartment_id=compartment_id,
            lifecycle_state=["ACTIVE"],
        )

        # Return the clusters
        return clusters.data
