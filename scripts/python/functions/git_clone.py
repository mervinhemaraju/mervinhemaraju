import sys
import os

# azure devops = "git@ssh.dev.azure.com:v3/duokeych/dke-devops/dke-devops"
# gitlab = "git@gitlab.com:duokeyCH/dke-devops.git"
# github = "git@github.com:n8n-io/n8n-kubernetes-hosting.git"

# Global vars
WORK_DIR = "$PROJECTS/work/{}"
PERSONAL_DIR = "$PROJECTS/personal/{}"


def _get_arguments() -> int:
    # Check if arguments are provided
    if len(sys.argv) > 1:
        return sys.argv[1]
    else:
        # If no argument is raise an exception
        raise ValueError("No git url provided. Please provide a valid ssh url.")


def _sanitize_git_url(git_url: str) -> str:
    # Sanitize the git url by removing any leading or trailing whitespace
    stripped_url = git_url.strip()

    # Check if the url starts with "git@"
    if stripped_url.startswith("git@"):
        # Remove the first 4 characters (the "git@" prefix)
        stripped_url = stripped_url[4:]

    # Check if the url ends with ".git"
    if stripped_url.endswith(".git"):
        # Remove the git@ prefix and .git suffix
        stripped_url = stripped_url[:-4]

    # Return the sanitized url
    return stripped_url


def get_domain_and_path(git_url: str) -> tuple:
    # Sanitize the git url
    sanitized_url = _sanitize_git_url(git_url)

    # Split the url into domain and path
    parts = sanitized_url.split(":")

    # Check if the url has a valid format
    if len(parts) != 2:
        raise ValueError("Invalid git url format. Expected format: 'git@domain:path'.")

    # Return the domain and path as a tuple
    return parts[0], parts[1]


def path_sanitization(domain: str, path: str) -> str:
    # Add any extra sanitization logic for specific domains here

    # If domain is azure devops
    if domain == "ssh.dev.azure.com":
        # Remove the "v3" part from the path
        if path.startswith("v3/"):
            path = path[3:]

        # Return the sanitized path for azure devops
        return WORK_DIR.format(f"azuredev/{path}")

    # If domain is gitlab
    elif domain == "gitlab.com":
        # Return the sanitized path for gitlab
        return WORK_DIR.format(f"gitlab/{path}")

    # If domain is github
    elif domain == "github.com":
        # Check if the path starts with "mervinhemaraju/" or "plagueworks-org/"
        if path.startswith("mervinhemaraju/") or path.startswith("plagueworks-org/"):
            # Return a different path for these specific cases
            return PERSONAL_DIR.format(path)
        # Otherwise, return the default work path for github
        return WORK_DIR.format(f"github/{path}")
    else:
        raise ValueError(f"Unsupported domain: {domain}.")


def domain_sanitization(domain: str) -> str:
    # Add any extra sanitization logic for specific domains here

    # Check if the domain is github
    if domain == "github.com":
        # Get the value for the env var $GITHUB_DOMAIN
        github_domain = os.getenv("GITHUB_DOMAIN", None)

        # Check if github_domain is not None
        if github_domain is not None:
            # Return the sanitized domain
            return github_domain
        else:
            # If the env var is not set, raise an exception
            raise ValueError("GITHUB_DOMAIN environment variable is not set.")

    return domain


def main():
    # Add a try-except block to handle exceptions
    try:
        # Get the git url from command line arguments
        git_url = _get_arguments()

        # Print the git url
        print(f"Cloning git repository from: {git_url}")

        # Sanitize the git url
        git__sanitized_url = _sanitize_git_url(git_url)

        # Get the domain and path from the sanitized git url
        domain, path = get_domain_and_path(git__sanitized_url)

        # Sanitize the path based on the domain
        path = path_sanitization(
            domain,
            path,
        )

        # Sanitize the domain
        domain = domain_sanitization(domain)

        # Print the domain and path
        print(f"Domain: {domain}")
        print(f"Path: {path}")

        # Clone the git repository
        os.system(f"git clone {git_url} {path}")

    except Exception as e:
        # Handle any exceptions that occur
        print(f"Error: {e}")

        # Exit the script with a non-zero status code
        sys.exit(1)


if __name__ == "__main__":
    main()
