from core.accounts import Accounts
from core.regions import Regions

ACCOUNT_REGION_MAPPING = {
    Accounts.ZEUS: Regions.AF_JOHANNESBURG_1,
    Accounts.HELIOS: Regions.AF_JOHANNESBURG_1,
    Accounts.GAIA: Regions.AF_JOHANNESBURG_1,
    Accounts.POSEIDON: Regions.UK_LONDON_1,
}

K8_ENDPOINT_PORT_MAPPINGS = {
    Accounts.ZEUS: "6442",
    Accounts.HELIOS: "6440",
    Accounts.POSEIDON: "6441",
}
