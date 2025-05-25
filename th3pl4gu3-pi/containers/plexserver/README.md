# Plex Server

This is the docker compose file to spin up the plex server container for my local Raspberry Pi.

## Getting Started

1. Clone the Github Repo to a safe location
2. Create a `.env` file with the below values

```
PLEX_CLAIM="<YOUR_PLEX_CLAIM>"
MAIN_PLEX_PATH="<THE_MAIN_PLEX_PATH>"
COLLECTIONS_PATH="<THE_PATH_TO_COLLECTIONS>"
```

3. Run the command `docker compose up -d`
