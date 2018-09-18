################## LOCALS ##################

locals {
	is_public_cluster			= "${var.cluster_public == "true" ? "1" : 0}"
	cluster_zone_id				= "${var.cluster_public == "true" ? data.aws_route53_zone.public.id: data.aws_route53_zone.private.id}"
	cluster_zone					= "${data.aws_route53_zone.private.name}"
	cluster_fqdn					= "${var.cluster_name}.${replace(local.cluster_zone, "/[.]$/", "")}"

	is_private_amis				= "${var.s3_private_amis_bucket == "" ? 0 : 1}"
	is_public_amis				= "${var.s3_private_amis_bucket == "" ? 1 : 0}"
	ami_owner							= "${var.s3_private_amis_bucket == "" ? "742773893669" : "self"}"

	enabled_cidrs					= "${compact(concat(data.aws_subnet.ingress.*.cidr_block, data.aws_subnet.pools.*.cidr_block, var.authorized_external_cidrs))}"

	debug									= "${var.debug == "true" ? 1 : 0}"
	debug_subdomain				= "${var.debug == "true" ? "debug." : ""}"

	name_prefix						=	"cyvive-${var.cluster_name}"
}

################## VPC INFORMATION ##################

data "aws_vpc" "selected" {
	id			= "${var.vpc_id}"
}

data "aws_subnet_ids" "ingress" {
	vpc_id	= "${data.aws_vpc.selected.id}"
	tags {
		Cyvive	= "Ingress"
	}
}

data "aws_subnet" "ingress" {
	count		= "${length(data.aws_subnet_ids.ingress.ids)}"
	id			= "${data.aws_subnet_ids.ingress.ids[count.index]}"
}

data "aws_subnet_ids" "pools" {
	vpc_id	= "${data.aws_vpc.selected.id}"
	tags {
		Cyvive	= "Pools"
	}
}

data "aws_subnet" "pools" {
	count		= "${length(data.aws_subnet_ids.pools.ids)}"
	id			= "${data.aws_subnet_ids.pools.ids[count.index]}"
}

################## ROUTE53 INFORMATION ##################

data "aws_route53_zone" "public" {
	name					= "${var.dns_zone}"
}

data "aws_route53_zone" "private" {
	name					= "${var.dns_zone}"
	private_zone	= "true"
}

################## LATEST AMI's (Standard) ##################

data "aws_ami" "most_recent_cyvive" {
  most_recent = true
  owners			= ["${local.ami_owner}"]
	name_regex	= "cyvive-kubernetes"
}

################## LATEST AMI's (ENA) ##################

data "aws_ami" "most_recent_cyvive_ena" {
  most_recent = true
  owners			= ["${local.ami_owner}"]
	name_regex	= "cyvive-ena-kubernetes"
}

