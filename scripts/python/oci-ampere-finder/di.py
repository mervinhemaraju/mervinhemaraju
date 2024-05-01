import os
import oci
import cutie
from kink import di
from functools import wraps
from dopplersdk import DopplerSDK


def main_injection(func):
    def extract_secret(secrets, name):
        return secrets.get(
            project="cloud-iac-main",
            config="prd",
            name=name,
        ).value["raw"]

    def generate_oci_config(selected_account, region, secrets):
        #  Retrieve account info from secrets
        user_id = extract_secret(secrets, f"OCI_{selected_account.upper()}_USER_OCID")
        tenancy_id = extract_secret(
            secrets, f"OCI_{selected_account.upper()}_TENANCY_OCID"
        )
        key_content = extract_secret(
            secrets, f"OCI_{selected_account.upper()}_PRIVATE_KEY"
        )
        fingerprint = extract_secret(
            secrets, f"OCI_{selected_account.upper()}_FINGERPRINT"
        )

        # Return the config
        return {
            "user": user_id,
            "key_content": key_content,
            "fingerprint": fingerprint,
            "tenancy": tenancy_id,
            "region": region,
        }

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

    @wraps(func)
    def wrapper(*args, **kwargs):
        # * DI for os variables
        di["DOPPLER_MAIN_TOKEN"] = os.environ["DOPPLER_MAIN_TOKEN"]

        # * Define choices
        available_accounts = ["helios", "poseidon"]
        available_regions = ["af-johannesburg-1", "uk-london-1"]

        # * Ask user input
        _, di["OCI_ACCOUNT_NAME"] = make_a_choice(
            "Select the account to use:", available_accounts
        )

        _, di["REGION"] = make_a_choice("Select the region to use:", available_regions)

        # * Initialize Doppler secrets
        doppler = DopplerSDK()
        doppler.set_access_token(di["DOPPLER_MAIN_TOKEN"])
        di["secrets"] = doppler.secrets

        # OCI Configs
        di["COMPARTMENT_PRODUCTION_ID"] = extract_secret(
            di["secrets"],
            f"OCI_{di['OCI_ACCOUNT_NAME'].upper()}_COMPARTMENT_PRODUCTION_ID",
        )

        di["COMPUTE_KEY_PUBLIC"] = extract_secret(
            di["secrets"],
            f"OCI_{di['OCI_ACCOUNT_NAME'].upper()}_COMPUTE_KEY_PUBLIC",
        )

        # * Get the OCI config
        config = generate_oci_config(
            secrets=di["secrets"],
            selected_account=di["OCI_ACCOUNT_NAME"],
            region=di["REGION"],
        )

        # * Validate oci config
        oci.config.validate_config(config)

        di["config"] = config

        return func(*args, **kwargs)

    return wrapper
