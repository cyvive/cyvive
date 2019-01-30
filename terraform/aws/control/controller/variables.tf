# Passthrough Variables
## Generic
variable "user_data_base64" {
	type				= "string"
}

## Locals
variable "cluster_fqdn" {
	type				= "string"
}

variable "debug" {
	type				= "string"
}

variable "image_id" {
	type				= "string"
}

variable "instance_type" {
	type				= "string"
}

variable "is_public_cluster" {
	type				= "string"
}

variable "name_prefix" {
	type				= "string"
}

variable "ssh_key" {
	type				= "string"
}

## Variables
variable "cluster_name" {
	type				= "string"
}

variable "oci_cache_disk_size" {
	type				= "string"
}

variable "oci_cache_disk_type" {
	type				= "string"
}

# Descriptive
variable "az" {
	description = "Availability Zone for Controller to Bind to"
	type				= "string"
}

variable "iam_instance_profile" {
	description	= "IAM profile to associate with the instances"
	type				= "string"
}

variable "lb_dashboard" {
	description = "ARN's of dashboard target group"
	type				= "string"
}

variable "lb_dashboard_https" {
	description = "ARN's of dashboard https target group"
	type				= "string"
}

variable "lb_healthz" {
	description = "ID of Kubelet ELB healthcheck"
	type				= "string"
}

variable "lb_private" {
	description = "ID of private control plane ELB"
	type				= "string"
}

variable "lb_public" {
	description = "ID of public control plane ELB"
	type				= "string"
}

variable "pet_placement" {
	description = "Generated pet name for placement groups"
	type				= "string"
}

variable "subnet_id" {
	description = "Subnet to apply pool into"
	type				= "string"
}

variable "zone_id_private" {
	description = "Route53 private Zone ID"
	type				= "string"
}

variable "zone_id_public" {
	description = "Route53 public Zone ID"
	type				= "string"
}

variable "security_groups" {
	description	= "Security Groups to associate with instances"
	type				= "list"
}
