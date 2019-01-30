#!/bin/bash

# Timeouts are tight @ 5 seconds x 20 iterations
# Split into two separate queries to extend the timeout without the necessity of 'sleep'
aws s3api wait object-exists --bucket $1 --key kubeadm/.kubeadm-init.sh-started


if aws s3api wait object-exists --bucket $1 --key kubeadm/admin.conf; then
	aws s3api get-object --bucket $1 --key kubeadm/admin.conf ../../../.nixconfig/kubectl
	declare -a arr=("ca.crt" "healthcheck-client.crt" "healthcheck-client.key")
	mkdir -p ../../../.nixconfig/etcd
	for file in "${arr[@]}"
	do
		aws s3api get-object --bucket $1 --key kubeadm/az/a/etcd/$file ../../../.nixconfig/etcd/$file
	done
else
	echo 'kubernetes admin.conf timed out in S3 cluster config bucket'
	exit 1
fi
