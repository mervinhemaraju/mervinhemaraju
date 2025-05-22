#!/bin/zsh

# > Functions are defined here and reference in other bash scripts

# * Get the current AWS account number
fn_aws_current_account()
{
	# Check if AWS credentials have been initialized
	if [[ -z "$AWS_ACCESS_KEY_ID" || -z "$AWS_SECRET_ACCESS_KEY" ]]; then
		echo "AWS credentials are not initialized. Please configure your AWS credentials first."
		exit 1
	fi

	aws sts get-caller-identity --query Account --output text
}

# * Switch AWS region between ireland and london
fn_aws_switch_region()
{
	if [ "$AWS_REGION" = "eu-west-1" ]
	then
		AWS_REGION="eu-west-2"
	else
		AWS_REGION="eu-west-1"
	fi
}

# * Load the CKO Git Config
fn_git_load_config_work()
{
	# * Set the Git username and user email
	git config --local user.name 'Mervin Hemaraju' && git config --local user.email 'mervin.hemaraju@duokey.com'

	# * Set the github domain alias to reference the account
	GITHUB_DOMAIN="github-dke"
}

# * Load the Personal Git Config
fn_git_load_config_personal()
{
	# * Set the Git username and user email
	git config --local user.name 'Mervin Hemaraju' && git config --local user.email 'th3pl4gu33@gmail.com'

	# * Set the github domain alias to reference the account
	GITHUB_DOMAIN="github-personal"
}

# * Git clone on Steroids
fn_git_clone() {

	# * Verify if the GITHUB_DOMAIN variable is empty
	if [ -z "$GITHUB_DOMAIN" ]; then
		echo "GITHUB_DOMAIN has not been initialized";
	else

		# * If variable is not empty, retrieve the project link and location path
		project="$1"; location="$2"; 

		# * Replace 'github.com' with the ssh domain on machine
		project=$(echo $project | sed -r "s/github.com/${GITHUB_DOMAIN}/g")

		# * Get the org name
		org=$(echo ${project#*:} | cut -d'/' -f1)

		# * Get the repo name
		repo=$(basename "${project}" .git)

		# * Verify if cko is in the org name
		if [[ $org == cko-* ]]; then

			# * Get the domain name
			dom=${org#cko-}

			# * Re assign the location
			location="$HOME/Projects/cko/$dom"

			# echo message
			echo "Creating the directory $location"

			# * Create the directory path
		  	mkdir -p $location
			
		fi

		# echo message
		echo "Creating repo at $location/$repo"

		# * clone the repo
		git clone $project "$location/$repo"
	fi
}

# * List the versions for a specific package in AWS CodeArtifact
fn_aws_ca_versions() {
  aws codeartifact list-package-versions --package "$1" --repository euw1pypackages --domain cko-it-packages --format pypi | jq '.versions[] | .version'
}