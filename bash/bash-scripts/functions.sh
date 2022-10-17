#!/bin/zsh

# > Functions are defined here and reference in other bash scripts

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
fn_git_load_config_cko()
{
	# * Set the Git username and user email
	git config --local user.name 'Mervin Hemaraju' && git config --local user.email 'mervin.hemaraju@checkout.com'

	# * Set the github domain alias to reference the account
	GITHUB_DOMAIN="github-cko"
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

		# * clone the repo
		git clone $project $location
	fi
}