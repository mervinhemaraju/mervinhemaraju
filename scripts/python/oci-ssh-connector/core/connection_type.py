from enum import Enum


class ConnectionType(Enum):
    NODE = "node"
    K8_API = "k8_api"

    @classmethod
    def values(cls):
        """Returns a list of all enum member values."""
        return [member.value for member in cls]
