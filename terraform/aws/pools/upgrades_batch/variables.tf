# Passthrough Variables
variable "instance_types" {
	type				= "list"
}

variable "pool_maximum_size" {
	type				= "string"
}

variable "user_data_base64" {
	type				= "string"
}

variable "oci_cache_disk_type" {
	type				= "string"
}

variable "oci_cache_disk_size" {
	type				= "string"
}

# Descriptive
variable "lb_target_group_arn" {
	description = "ARN's to ensure this Pool registers against"
	type				= "list"
	default			= [""]
}

variable "pet_placement" {
	description = "Generated pet names for placement groups"
	type				= "string"
}

variable "subnet_id" {
	description = "Subnet to apply pool into"
	type				= "string"
}

variable "elb_names" {
	description = "ELB Load Balancers to associate with the instances"
	type				= "list"
}

variable "min_alive_instances" {
	description = "Minimum number of instances that must be kept alive during rolling update"
	default			=	"1"
}

variable "disable_placement" {
	description = "Allows smaller instance sizing by disabling placement rules"
	type				= "string"
	default			= "false"
}

variable "pool_name" {
	description = "name of the current module"
	type				= "string"
}

variable "cluster_name" {
	description	= "passthrough"
	type				= "string"
}

variable "image_id" {
	description	= "AMI Image ID"
	type				= "string"
}

variable "ssh_key" {
	description	= "SSH Key to associate with the instance if debug enabled upstream"
	type				= "string"
}

variable "security_groups" {
	description	= "Security Groups to associate with instances"
	type				= "list"
}

variable "iam_instance_profile" {
	description	= "IAM profile to associate with the instances in this pool"
	type				= "string"
}

variable "enable" {
	description = "Enable / Disable the Module"
	type				= "string"
}
