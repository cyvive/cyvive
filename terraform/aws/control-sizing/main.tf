################## INSTANCE SIZING ##################
data "external" "control_sizing" {
	program = [ "./local-exec/hostnumber.sh" ]
	query = {
		cidr = "${join(" ", data.aws_subnet.pools.*.cidr_block)}"
		asg  = "${join(" ", data.aws_autoscaling_group.current_state.*.desired_capacity)}"
	}
}

################## ASG INFORMATION ##################
data "aws_autoscaling_groups" "current_state" {
	filter {
		name			= "key"
		values		= ["cyvive"]
	}

	filter {
		name			= "value"
		values		= ["${var.cluster_name}"]
	}
}

data "aws_autoscaling_group" "current_state" {
	count				= "${length(data.aws_autoscaling_groups.current_state.names)}"
	name				= "${data.aws_autoscaling_groups.current_state.names[count.index]}"
}

################## VPC INFORMATION ##################
data "aws_region" "current" {}

data "aws_vpc" "selected" {
	id					= "${var.vpc_id}"
}

data "aws_subnet_ids" "pools" {
	vpc_id			= "${data.aws_vpc.selected.id}"
	tags {
		Cyvive		= "Pools"
	}
}

data "aws_subnet" "pools" {
	count		= "${length(data.aws_subnet_ids.pools.ids)}"
	id			= "${data.aws_subnet_ids.pools.ids[count.index]}"
}

