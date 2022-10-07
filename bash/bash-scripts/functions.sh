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
	GITHUB_DOMAIN="git@github-cko"
}

# * Load the Personal Git Config
fn_git_load_config_personal()
{
	# * Set the Git username and user email
	git config --local user.name 'Mervin Hemaraju' && git config --local user.email 'th3pl4gu33@gmail.com'

	# * Set the github domain alias to reference the account
	GITHUB_DOMAIN="git@github-personal"
}

# * Git clone on Steroids
fn_git_clone() {
	
	# * Verify if the GOTHUB_DOMAIN variable is empty
	if [ -z "$GITHUB_DOMAIN" ]; then
		echo "GITHUB_DOMAIN has not been initialized";
	else
		project="$1"; location="$2"; 
		git clone "${GITHUB_DOMAIN}:${project}" ${location}
	fi
}