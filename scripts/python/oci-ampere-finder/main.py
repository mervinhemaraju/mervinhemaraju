import oci
import logging
from kink import di
from di import main_injection

# Initialize Logging
logging.getLogger().setLevel(logging.INFO)


def get_image(compute, compartment_id, shape):
    list_images_response = oci.pagination.list_call_get_all_results(
        compute.list_images,
        compartment_id,
        operating_system="Oracle Linux",
        shape=shape,
    )
    images = list_images_response.data
    if len(images) == 0:
        raise RuntimeError("No available image was found.")

    # For demonstration, we just return the first image but for Production code you should have a better
    # way of determining what is needed
    image = images[0]

    logging.info("Found Image: {}".format(image.id))

    return image


def get_compute_subnet(vcn, compartment_id):
    response = vcn.list_subnets(compartment_id=compartment_id)

    return [
        subnet for subnet in response.data if subnet.display_name != "private-mgmt"
    ][0]


def get_availability_domains(identity, compartment_id):
    # Send the request to service, some parameters are not required, see API
    # doc for more info
    list_availability_domains_response = identity.list_availability_domains(
        compartment_id=compartment_id
    )

    # Get the data from response
    return list_availability_domains_response.data


def launch_instance(
    compute, shape, image, subnet, ssh_public_key, availability_domain, compartment_id
):
    # Specify the details for the instance
    instance_details = oci.core.models.LaunchInstanceDetails(
        compartment_id=compartment_id,
        availability_domain=availability_domain,
        shape=shape,
        display_name="mongo",
        image_id=image.id,
        shape_config=oci.core.models.LaunchInstanceShapeConfigDetails(
            ocpus=4, vcpus=4, memory_in_gbs=24
        ),
        subnet_id=subnet.id,
        metadata={"ssh_authorized_keys": ssh_public_key},
    )

    # Launch the instance
    launch_response = compute.launch_instance(instance_details)

    logging.info(launch_response.data)

    return launch_response.data.id


@main_injection
def main():
    # Define vars
    instance_ids = []
    errors = []

    try:
        # Create the OCI clients
        compute = oci.core.ComputeClient(di["config"])
        vcn = oci.core.VirtualNetworkClient(di["config"])
        identity = oci.identity.IdentityClient(di["config"])

        # Define the shape
        shape = "VM.Standard.A1.Flex"

        # Get the image
        image = get_image(
            compute=compute, compartment_id=di["COMPARTMENT_PRODUCTION_ID"], shape=shape
        )

        # Get the subnet
        subnet = get_compute_subnet(
            vcn=vcn, compartment_id=di["COMPARTMENT_PRODUCTION_ID"]
        )

        # GEt availability domains
        ads = get_availability_domains(
            identity=identity, compartment_id=di["COMPARTMENT_PRODUCTION_ID"]
        )

        # Iterate through each availability domains
        for ad in ads:
            try:
                # Launch the instance
                instance_id = launch_instance(
                    availability_domain=ad.name,
                    compute=compute,
                    shape=shape,
                    image=image,
                    subnet=subnet,
                    ssh_public_key=di["COMPUTE_KEY_PUBLIC"],
                    compartment_id=di["COMPARTMENT_PRODUCTION_ID"],
                )

                # Append instance id
                instance_ids.append(instance_id)
            except Exception as e:
                logging.error(f"Error on AD {ad.name}: {str(e.message)}")
                errors.append(f"{str(e.message)} on AD {ad.name}")
                continue

        # Verify if an instance was created
        if len(instance_ids) > 0:
            # Log event
            logging.info(f"Instances were creaed: {instance_ids}")
        else:
            raise Exception(f"No instance was created: {errors}")

    except Exception as e:
        # Log event
        logging.error(f"Error: {str(e)}")
