from dopplersdk import DopplerSDK


class DopplerSecrets:
    def __init__(self, token, project, config):
        # Secrets manager Doppler
        doppler = DopplerSDK()
        doppler.set_access_token(token)

        self.secrets = doppler.secrets
        self.project = project
        self.config = config

    def extract_secret(self, name):
        return self.secrets.get(
            project=self.project,
            config=self.config,
            name=name,
        ).value["raw"]
