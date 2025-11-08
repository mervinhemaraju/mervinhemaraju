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

# * List the versions for a specific package in AWS CodeArtifact
fn_aws_ca_versions() {
  aws codeartifact list-package-versions --package "$1" --repository euw1pypackages --domain cko-it-packages --format pypi | jq '.versions[] | .version'
}

# > OCI Functions
oci_zeus() {
    oci "$@" --profile ZEUS --compartment-id $OCI_ZEUS_PRODUCTION_CID
}

oci_poseidon() {
    oci "$@" --profile POSEIDON --compartment-id $OCI_POSEIDON_PRODUCTION_CID
}

oci_gaia() {
    oci "$@" --profile GAIA --compartment-id $OCI_GAIA_PRODUCTION_CID
}

oci_helios() {
    oci "$@" --profile HELIOS --compartment-id $OCI_HELIOS_PRODUCTION_CID
}

# > Google Cloud functions
gsetproject() {
  # $1 is the first argument you provide to the function
  gcloud config set project $(gcloud projects list --filter="NAME='$1'" --format="value(PROJECT_ID)")
}