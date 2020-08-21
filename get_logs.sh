#!/bin/bash

#  (The MIT License)
#
#  Copyright (c) 2020 Igor Nemykin
#  
#  Recieves space separated values grom a bitbucket repo: issue Id, issue title, commets.
#
#  Use:
#  1. Create an app password: 
# 	 — From your avatar in the bottom left, click Personal settings.
# 	 — Click App passwords under Access management.
# 	 — Click Create app password.
#  2. Make the file exutable: `sudo chmod +x ./get_comments.sh`
#  3. Run the command: `./get_comments.sh -u [user_name] -p [password] -r [repository]`

while getopts u:p:r: option
do
case "${option}" in
    u) USER=${OPTARG};;
    p) PASSWORD=${OPTARG};;
    r) REPOSITORY=${OPTARG};;
esac
done

ISSUES="https://api.bitbucket.org/2.0/repositories/$USER/virtlabs/issues"
COMMENTS="https://api.bitbucket.org/2.0/repositories/$USER/virtlabs/issues/{issue_id}/comments"

function getComments {
	url=$(echo $COMMENTS|sed "s/{issue_id}/$1/")
	curl --silent -u "$USER:$PASSWORD" "$url" | jq -j '.values[].content.raw | strings + " "'
}

function getValues {
	for ((i=0; i<$1; i++))
	do
		id=$(echo $2 | jq ".[$i] | .id")
		title=$(echo $2 | jq ".[$i] | .title")
		url=$(echo $COMMENTS|sed "s/{issue_id}/$id/")
		comments=$(getComments $id)
		echo "issue#$id $title $comments"
	done
}

function getJson {
	json=$(curl --silent -u "$USER:$PASSWORD" "$1")
	values=$(echo $json | jq '[.values[] | select(.state == "resolved")]')
	next_page=$(echo $json | jq -r '.next')
	length=$(echo $values | jq 'length')
	
	getValues "$length" "$values"

	if [ "$next_page" != "null" ]
	then
		getJson $next_page
	fi
}

getJson "$ISSUES"
