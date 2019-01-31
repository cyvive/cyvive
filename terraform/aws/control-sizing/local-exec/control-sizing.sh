#!/bin/bash

# Exit if any of the intermediate steps fail
set -e

eval "$(jq -r '@sh "MAX=\(.max) DYNAMIC=\(.dynamic)"')"

SIZING=""
jq -n --arg max "$MAX" '{"max":$max}'
exit
case  1:${MAX:--} in
(1:*[!0-9]*|1:0*[89]*)
  ! echo NAN
;;
($((MAX<81))*)
	SIZING="c5"
;;
($((MAX<101))*)
	SIZING="c6"
;;
($((MAX<121))*)
	SIZING="C7"
;;
($((MAX<301))*)
	SIZING="c8"
;;
esac

jq -n --arg max "$SIZING" '{"max":$max}'
exit
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

jq -n --arg max "$MAX" --arg dynamic "$DYNAMIC" '{"max":$max, "dynamic":$dynamic}'

