import cutie
import boto3


# > Functions
def retrieve_log_group_names(client, pattern):
    # * Describe the log group name
    response_log_groups = client.describe_log_groups(logGroupNamePattern=pattern)

    # * Return the log group name
    return [group["logGroupName"] for group in response_log_groups["logGroups"]]


def retrieve_log_stream_names(client, log_group_name, limit):
    # * Describe the log stream names
    response = client.describe_log_streams(
        logGroupName=log_group_name,
        orderBy="LastEventTime",
        descending=True,
        limit=limit,
    )

    # * Return the stream names
    return [stream["logStreamName"] for stream in response["logStreams"]]


def retrieve_log_events(client, log_group_name, log_stream_names):
    # * Iterate through stream names
    for stream_name in log_stream_names:
        # * Sanitize name for file name
        sanitized_stream_name = stream_name.replace("/", "-")

        # * Get the event logs
        events = client.get_log_events(
            logGroupName=log_group_name,
            logStreamName=stream_name,
        )["events"]

        # * Get the messages
        messages = [event["message"] for event in events]

        # * Output to file
        write_to_file(sanitized_stream_name, messages)


def write_to_file(file_name, contents):
    # * Create a file with the stream name
    with open(f"{file_name}.log", "w") as filehandle:
        for content in contents:
            filehandle.write("%s\n" % content)


# * Create the boto3 clients
client_logs = boto3.client("logs")

# * User input for the log group name
log_group_name = input("Enter the log group name: ")

# * Retrieve the log group names
log_group_names = retrieve_log_group_names(client_logs, log_group_name)

# * Check if log group name is valid
if len(log_group_names) < 1:
    print("No log group name found.")
    exit()

# * Ask the user to select the log group name and the limit
selected_log_group_name = log_group_names[cutie.select(log_group_names)]
limit = cutie.get_number(
    "How many recent logs do you need ?", min_value=0, allow_float=False
)

# print a message for the user
print(f"Looking for {limit} logs with the group name {selected_log_group_name}")

# * Retrieve the log stream names
log_stream_names = retrieve_log_stream_names(
    client_logs, selected_log_group_name, limit=limit
)

# * Check if streams are available
if len(log_stream_names) < 1:
    print("No log stream found.")
    exit()

# * Get the log events
events = retrieve_log_events(client_logs, selected_log_group_name, log_stream_names)

# print a message for the user
print("Files created.")
