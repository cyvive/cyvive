variable "pool_maximum_size" {
	description	=	"Maximum Size of All Pools"
	type				= "string"
}

variable "vpc_id" {
	description = "Configured VPC ID (e.g. vpc-ce867bab)"
	type				= "string"
}

variable "lb_target_group_arn" {
	description = "ARN's to ensure this Pool registers against"
	type				= "list"
	default			= [""]
}

variable "pet_placement" {
	description = "Generated pet names for placement groups"
	type				= "list"
}

variable "subnet_size" {
	description = "Required for module workaround total computed number of subnets"
	type				= "string"
}

variable "subnet_ids" {
	description = "All Subnets available in the VPC"
	type				= "list"
}

variable "subnet_azs" {
	description = "List containing Subnet Availability Zone Names"
	type				= "list"
}

variable "launch_configuration" {
	description = "ASG Launch Configuration to use"
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

variable "instance_type" {
	description = "Instance Type Assigned to this Pool"
	type				= "string"
}

variable "cluster_name" {
	description	= "Name of the Cluster"
	type				= "string"
}

