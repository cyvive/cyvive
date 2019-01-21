#!/bin/bash

RELEASE="${RELEASE:-$(ls -1 releases/*.md | tail -1 | cut -d'.' -f1 | cut -d'/' -f2)}"

TXT_FILE="./releases/${RELEASE}.md"

if $(cat $TXT_FILE | grep "Disk Images" -q); then
 echo "Release: ${RELEASE} already generated... aborting"
 exit
fi

# Update Version in Package.json
cat package.json | jq ".version=$(jq .version package.json | sed 's/\.[^\.]*$/\.'$RELEASE\"'/')" > package.json

# Update ChangeLog file to current release
conventional-changelog -p angular -i CHANGELOG.md -s

# Process & Build Release Notes
NOTE_GEN=$(cat $TXT_FILE | sed -E '/^@@@@@@@@@@$/,$d')

TXT=$(cat $TXT_FILE | sed '0,/^@@@@@@@@@@$/d' | tail -n +2)
TXT="$TXT
## Disk Images

"

if $(echo "$NOTE_GEN" | grep "AWS" -q); then
	AMI_ALL=$(aws ec2 describe-images --filters "Name=name,Values=*${RELEASE}" "Name=name,Values=cyvive*" --query 'sort_by(Images, &CreationDate)[].ImageId' --output text)
	AMI_1=$(echo ${AMI_ALL} | cut -f1 -d' ' | cut -f1 -d'	')
	AMI_2=$(echo ${AMI_ALL} | cut -f2 -d' ' | cut -f2 -d'	')
	TXT="$TXT
### Amazon Web Services

* **Standard**: $AMI_1
* **Enhanced Networking**: $AMI_2
"
fi

########## ChangeLog ##########

CYVIVE=$(cat ./CHANGELOG.md | tail -n +3 | sed -n '/^<a /q;p')
TXT="$TXT

## ChangeLog Cyvive
$CYVIVE
"

if $(echo "$NOTE_GEN" | grep "Kubernetes" -q); then
	K8=$(curl -L https://raw.githubusercontent.com/cyvive/kubernetes/master/CHANGELOG.md | tail -n +3 | sed -n '/^## \[/q;p')
	TXT="$TXT

## ChangeLog Kubernetes

$K8
"
fi
echo "$TXT" > $TXT_FILE

git add package.json $TXT_FILE CHANGELOG.md
git commit -m "chore: Release $(jq .version package.json)"
