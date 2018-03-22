#!/bin/bash

# Creates the following files if they do not already exist: VERSION CHANGES
# VERSION contains the semver version, e.g., 1.0.0
# CHANGES contains the git commit messages for each commit for each version

# Assumes that the next version number is a single increment to the MINOR number
# If anything else (MAJOR or PATCH) then you must pass that value as 1st parameter

# works with a file called VERSION in the current directory,
# the contents of which should be a semantic version number
# such as "1.2.3"

# this script will display the current version, automatically
# suggest a "minor" version update, and ask for input to use
# the suggestion, or a newly entered value.

# once the new version number is determined, the script will
# pull a list of changes from git history, prepend this to
# a file called CHANGES (under the title of the new version
# number) and create a GIT tag.

function echoUsage() {
    echo "Usage:   $(basename $0) [<SEMVER_VERSION> | --silent | --help]"
    echo "Example: $(basename $0)"
    echo "Example: $(basename $0) --silent"
    echo "Example: $(basename $0) 2.0.0"
    echo "Example: $(basename $0) 2.1.1"
}
function createVersionFile() {
	 echo "0.1.0" > VERSION
	 echo "Version 0.1.0" > CHANGES
	 git log --pretty=format:" - %s" >> CHANGES
	 echo "" >> CHANGES
	 echo "" >> CHANGES
	 git add VERSION CHANGES
	 git commit -m "Added VERSION and CHANGES files, Version bump to v0.1.0"
	 git tag -a -m "Tagging version 0.1.0" "v0.1.0"
	 git push origin --tags
}

if [ ! -d \.git ]; then
	echo "Aborting.  $(basename $0) assumes that the .git directory exists."
	exit 2
fi

if [ -f VERSION ]; then
	BASE_STRING=`cat VERSION`
	BASE_LIST=(`echo $BASE_STRING | tr '.' ' '`)
	V_MAJOR=${BASE_LIST[0]}
	V_MINOR=${BASE_LIST[1]}
	V_PATCH=${BASE_LIST[2]}
	echo "Current version : $BASE_STRING"
	V_MINOR=$((V_MINOR + 1))
	V_PATCH=0
	SUGGESTED_VERSION="$V_MAJOR.$V_MINOR.$V_PATCH"
	 if [ "$@" == "" ]; then
		read -p "Enter a version number [$SUGGESTED_VERSION]: " INPUT_STRING
		echo "Will set new version to be $INPUT_STRING"
	 elif [ "$1" != '--silent' ]; then
		 INPUT_STRING="$1"
	 elif [ "$1" != '--help' ]; then
		 echoUsage
	 fi
	if [ "$INPUT_STRING" = "" ]; then
		INPUT_STRING=$SUGGESTED_VERSION
	fi
	echo $INPUT_STRING > VERSION
	echo "Version $INPUT_STRING:" > tmpfile
	git log --pretty=format:" - %s" "v$BASE_STRING"...HEAD >> tmpfile
	echo "" >> tmpfile
	echo "" >> tmpfile
	cat CHANGES >> tmpfile
	mv tmpfile CHANGES
	git add CHANGES VERSION
	git commit -m "Version bump to $INPUT_STRING"
	git tag -a -m "Tagging version $INPUT_STRING" "v$INPUT_STRING"
	git push origin --tags
else
    if [ "$1" == '--silent' ]; then
        createVersionFile
        echo "Created VERSION file"
    else
        echo "Could not find a VERSION file"
        read -p "Do you want to create a version file and start from scratch? [y]" RESPONSE
        if [ "$RESPONSE" = "" ]; then RESPONSE="y"; fi
        if [ "$RESPONSE" = "Y" ]; then RESPONSE="y"; fi
        if [ "$RESPONSE" = "Yes" ]; then RESPONSE="y"; fi
        if [ "$RESPONSE" = "yes" ]; then RESPONSE="y"; fi
        if [ "$RESPONSE" = "YES" ]; then RESPONSE="y"; fi
        if [ "$RESPONSE" = "y" ]; then
            createVersionFile
        fi
    fi
fi