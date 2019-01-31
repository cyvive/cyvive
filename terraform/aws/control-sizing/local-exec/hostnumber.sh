#!/bin/bash

# Exit if any of the intermediate steps fail
set -e

eval "$(jq -r '@sh "CIDR=\(.cidr) ASG=\(.asg)"')"

# Calculate Hosts Available in Subnets
MAX=0
for az in $CIDR; do
	AZ=$(ipcalc $az -b | grep "Hosts/Net:" | cut -d' ' -f2)
	MAX=$(expr $MAX + $AZ)
done

# Calculate Current Allocated Hosts belonging to Cyvive
DYNAMIC=0
for hosts in $ASG; do
	[ $hosts -gt 0 ] && DYNAMIC=$(expr $DYNAMIC + $hosts)
done

retval_size=""
size_instance () {
	SIZING=""
	number=$1
	case  1:${number:--} in
	(1:*[!0-9]*|1:0*[89]*)
		! SIZING="NAN"
	;;
	($((number<51))*)
		SIZING="c5d.xlarge"
	;;
	($((number<501))*)
		SIZING="c5d.2xlarge"
	;;
	($((number<1501))*)
		SIZING="c5d.4xlarge"
	;;
	($((number<6001))*)
		SIZING="c5d.9xlarge"
	;;
	($((number<13001))*)
		SIZING="c5d.18xlarge"
	;;
	esac
	retval_size=$SIZING
}

# Retrieve Appropriate Sizes from Instances
size_instance $MAX
MAXINSTANCE=$retval_size

retval_size=""

size_instance $DYNAMIC
DYNAMICINSTANCE=$retval_size

# Return JSON for Terraform to injest
jq -n --arg max "$MAX" --arg maxinstance "$MAXINSTANCE" --arg dynamic "$DYNAMIC" --arg dynamicinstance "$DYNAMICINSTANCE" '{"maxcount":$max, "maxinstance":$maxinstance, "dynamiccount":$dynamic, "dynamicinstance":$dynamicinstance}'
