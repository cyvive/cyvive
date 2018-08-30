################## LOCALS ##################

locals {
	is_public_cluster			= "${var.cluster_public == "true" ? "1" : 0}"
	cluster_zone_id				= "${var.cluster_public == "true" ? data.aws_route53_zone.public.id: data.aws_route53_zone.private.id}"
	cluster_zone					= "${data.aws_route53_zone.private.name}"
	cluster_fqdn					= "${var.cluster_name}.${replace(local.cluster_zone, "/[.]$/", "")}"

	is_private_amis				= "${var.s3_private_amis_bucket == "" ? 0 : 1}"
	is_public_amis				= "${var.s3_private_amis_bucket == "" ? 1 : 0}"
	ami_owner							= "${var.s3_private_amis_bucket == "" ? "self" : "742773893669"}"

	is_ssh								= "${var.ssh_enabled == "0" ? 0 : 1}"
	ssh_key								= "${var.ssh_enabled == "0" ? "" : var.ssh_authorized_key}"

	name_prefix						=	"cyvive-${var.cluster_name}"

	token_combiner				= "${random_string.tokenA.result}.${random_string.tokenB.result}"
	token_id							= "${var.pool_token == "" ? local.token_combiner : var.pool_token}"

	init_controller = {
		kubeadm = {
			entries = {
				# TODO rename init to etcd
				/*
				bootstrap = {
					content				= ""
				},
				*/
				kubeadm.yaml		= {
					content				= "${data.template_file.kubeadm.rendered}"
				},
				/*
				terraform.tfvars = {
					content				= "${data.template_file.terraform_vars.rendered}"
				},
				main.tf = {
					content				= "${data.template_file.terraform_main.rendered}"
				},
				*/
			}
		},
		cyvive = {
			entries = {
				s3config				= {
					content				= "s3://${var.s3_config_bucket}/kubeadm"
				},
				cluster.fqdn = {
					content				=	"${local.cluster_fqdn}"
				}
			}
		},
		/*
		kubelet = {
			entries = {
				disabled = {
					content = ""
				},
				disabledexec = {
					content = ""
				}
			}
		}
		*/
	}
}

################## VPC INFORMATION ##################

data "aws_region" "current" {}

data "aws_vpc" "selected" {
	id			= "${var.vpc_id}"
}

/*
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
*/

data "aws_subnet_ids" "pools" {
	vpc_id	= "${data.aws_vpc.selected.id}"
	tags {
		Cyvive	= "Pools"
	}
}

data "aws_subnet" "a" {
	vpc_id						= "${data.aws_vpc.selected.id}"
	availability_zone	= "${data.aws_region.current.name}a"
	tags {
		Cyvive					= "Pools"
	}
}

data "aws_subnet" "b" {
	vpc_id						= "${data.aws_vpc.selected.id}"
	availability_zone	= "${data.aws_region.current.name}b"
	tags {
		Cyvive					= "Pools"
	}
}

data "aws_subnet" "c" {
	vpc_id						= "${data.aws_vpc.selected.id}"
	availability_zone	= "${data.aws_region.current.name}c"
	tags {
		Cyvive					= "Pools"
	}
}

################## ROUTE53 INFORMATION ##################

data "aws_route53_zone" "public" {
	name					= "${var.dns_zone}"
}

data "aws_route53_zone" "private" {
	name					= "${var.dns_zone}"
	private_zone	= "true"
}

################## PLACEMENT GROUPS ##################

resource "random_pet" "placement_spread" {
	count				= "${length(data.aws_subnet_ids.pools.ids)}"
	keepers = {
		placement = "${var.rename_placement_groups}"
	}
	prefix			= "${local.name_prefix}-controller"
	#prefix			= "${local.name_prefix}-${substr(data.aws_subnet.pools.*.availability_zone[count.index], -2, -1)}"
}

resource "aws_placement_group" "spread" {
	count				= "${length(data.aws_subnet_ids.pools.ids)}"
	name				= "${random_pet.placement_spread.*.id[count.index]}"
	strategy		= "spread"
}

################## LATEST AMI's (Standard) ##################

data "aws_ami" "most_recent_cyvive_generic" {
  most_recent = true
  owners			= ["${local.ami_owner}"]
	name_regex	= "cyvive-generic"
}

################## LATEST AMI's (ENA) ##################

data "aws_ami" "most_recent_cyvive_ena_generic" {
  most_recent = true
  owners			= ["${local.ami_owner}"]
	name_regex	= "cyvive-ena-generic"
}

################## SECURITY GROUP ##################

data "aws_security_group" "hardwired_controllers" {
  name        = "${local.name_prefix}-hardwired-controllers"

	vpc_id = "${data.aws_vpc.selected.id}"

  tags = "${map("Name", "${local.name_prefix}-hardwired-controllers")}"
}

data "aws_security_group" "linked_controllers" {
  name        = "${local.name_prefix}-linked-controllers"

	vpc_id = "${data.aws_vpc.selected.id}"

  tags = "${map("Name", "${local.name_prefix}-linked-controllers")}"
}

################## IAM PROFILE ##################

data "aws_iam_instance_profile" "controller" {
	name	= "${local.name_prefix}-controller"
}

################## LOAD BALANCERS ##################

data "aws_lb_target_group" "controllers_public" {
	count									= "${local.is_public_cluster}"
	name									= "${local.name_prefix}-controllers-public"
}

data "aws_elb" "healthz" {
	name									= "${local.name_prefix}-healthz"
}

data "aws_elb" "control_plane_private" {
	name									= "${local.name_prefix}-control-private"
}

################## S3 BUCKETS ##################

data "aws_s3_bucket" "cluster_config" {
	bucket							= "${var.s3_config_bucket}"
}

data "aws_s3_bucket" "is_private_amis" {
	count								= "${local.is_private_amis}"
	bucket							= "${var.s3_private_amis_bucket}"
}

################## RANDOM TOKEN GENERATION ##################

resource "random_string" "tokenA" {
	length				= 6
	special				= false
	upper					= false
	keepers	= {
		pool_token	= "${var.pool_token}"
	}
}

resource "random_string" "tokenB" {
	length				= 16
	special				= false
	upper					= false
	keepers = {
		pool_token	= "${var.pool_token}"
	}
}

