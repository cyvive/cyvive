variable "pool_maximum_size" {
	description	=	"Maximum Size of All Pools"
	type				= "string"
}

variable "vpc_id" {
	description = "Configured VPC ID (e.g. vpc-ce867bab)"
	type				= "string"
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

variable "min_alive_instances" {
	description = "Minimum number of instances that must be kept alive during rolling update"
	default			=	"1"
}

