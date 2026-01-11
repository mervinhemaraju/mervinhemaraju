import logging
import re
import sys
import cutie
import fileinput


def make_a_choice(message, choices):
    # Show question
    print(message)

    # Get the seelciton index
    index = cutie.select(choices)

    # Get choice from user
    selection = choices[index]

    # Show output
    logging.info(f"{selection} has been selected. \n")

    # Return the choice
    return index, selection


def extract_proxy_command(command):
    match = re.search(r'ProxyCommand\s*=\s*"([^"]*)"', command)
    if match:
        return match.group(1)
    else:
        return None


def replace_proxy_command_for_host(file_path, host, new_command, bastion_ip):
    # Reformat host name
    host = f"oci-{host}".lower()
    inside_host_block = False
    with fileinput.input(files=(file_path), inplace=True, backup=".bak") as f:
        for line in f:
            stripped = line.strip()
            if stripped.startswith("Host ") and host in stripped:
                inside_host_block = True
            if inside_host_block and stripped.startswith("ProxyCommand"):
                line = "ProxyCommand " + new_command + "\n"
            if inside_host_block and stripped.startswith("HostName"):
                line = "HostName " + bastion_ip + "\n"
            if stripped == "":
                inside_host_block = False
            sys.stdout.write(line)


def retrieve_bastion_ip(command):
    ip_pattern = r"\b(?:[0-9]{1,3}\.){3}[0-9]{1,3}\b"

    ip_address = re.search(ip_pattern, command)

    if ip_address:
        return ip_address.group(0)
