import sys
import random
import string


def _get_arguments() -> int:
    # Check if arguments are provided
    if len(sys.argv) > 1:
        # Try to convert the first argument to an integer
        length = int(sys.argv[1])

        # Validate the length
        if length < 5:
            raise ValueError("Password length must be at least 5 characters.")

        # Check if the length exceeds the maximum allowed
        if length > 128:
            raise ValueError("Password length must not exceed 128 characters.")

        # Return the validated length
        return length
    else:
        # If no argument is provided, use the default length
        return 12


def _generate_password(length=12):
    # Define the character sets to use in the password
    lower = string.ascii_lowercase
    upper = string.ascii_uppercase
    digits = string.digits
    punctuation = "".join(["@", "#", "$", "%", "&", "+", "{", "}"])

    # Combine all character sets
    all_characters = lower + upper + digits + punctuation

    return "".join(random.choice(all_characters) for _ in range(length))


def main():
    # Add a try-except block to handle exceptions
    try:
        #  Get the password length from command line arguments
        length = _get_arguments()

        # Generate the password
        password = _generate_password(length=length)

        # Print the generated password
        print(password)

    except Exception as e:
        # Handle any exceptions that occur
        print(f"Error: {e}")

        # Exit the script with a non-zero status code
        sys.exit(1)


if __name__ == "__main__":
    main()
