from enum import Enum


class Accounts(Enum):
    GAIA = "gaia"
    HELIOS = "helios"
    POSEIDON = "poseidon"
    ZEUS = "zeus"

    @classmethod
    def values(cls):
        """Returns a list of all enum member values."""
        return [member.value for member in cls]
