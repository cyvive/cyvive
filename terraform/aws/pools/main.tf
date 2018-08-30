################## LOCALS ##################

locals {
	is_public_cluster			= "${var.cluster_public == "true" ? "1" : "0"}"
	is_nlb_public_cluster	= "${var.cluster_public == "true" ? "false" : "true"}"
	cluster_zone_id				= "${var.cluster_public == "true" ? data.aws_route53_zone.public.id: data.aws_route53_zone.private.id}"
	cluster_zone					= "${data.aws_route53_zone.private.name}"
	cluster_fqdn					= "${var.cluster_name}.${replace(local.cluster_zone, "/[.]$/", "")}"

	is_private_amis				= "${var.s3_private_amis_bucket == "" ? 0 : 1}"
	is_public_amis				= "${var.s3_private_amis_bucket == "" ? 1 : 0}"
	ami_owner							= "${var.s3_private_amis_bucket == "" ? "self" : "742773893669"}"

	is_ssh								= "${var.ssh_enabled == "0" ? 0 : 1}"
	ssh_key								= "${var.ssh_enabled == "0" ? "" : var.ssh_authorized_key}"

	is_upgrade_rolling		= "${var.rolling_upgrades == "true" ? "true" : "false"}"
	is_upgrade_batch			= "${var.rolling_upgrades == "true" ? "false" : "true"}"

	ami_image_a						= "${var.ami_image_a == "" ? data.aws_ami.most_recent_cyvive_generic.id : var.ami_image_a}"
	ami_image_b						= "${var.ami_image_b == "" ? data.aws_ami.most_recent_cyvive_generic.id : var.ami_image_b}"
	ami_image_c						= "${var.ami_image_b == "" ? data.aws_ami.most_recent_cyvive_generic.id : var.ami_image_c}"

	name_prefix						=	"cyvive-${var.cluster_name}"

	token_id							= "${var.pool_token}"

	init_pool = {
		kubenode = {
			entries = {
				join = {
					content = "--token ${local.token_id} --discovery-token-unsafe-skip-ca-verification api-${local.cluster_fqdn}:6443"
				}
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

resource "random_pet" "placement_cluster" {
	count				= "${length(data.aws_subnet_ids.pools.ids)}"
	keepers = {
		placement = "${var.rename_placement_groups}"
	}
	prefix			= "${local.name_prefix}-pool"
}

resource "aws_placement_group" "cluster" {
	count				= "${length(data.aws_subnet_ids.pools.ids)}"
	name				= "${random_pet.placement_cluster.*.id[count.index]}"
	strategy		= "cluster"
}

################## LATEST AMI's (Standard) ##################

# TODO ability to specify a specific AMI
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

# TODO rename such that pool / pool comes first for sorting / relationships
data "aws_security_group" "hardwired_pools" {
  name        = "${local.name_prefix}-hardwired-pools"

	vpc_id = "${data.aws_vpc.selected.id}"

	# TODO broken out smaller tag searches to ensure 32 char limit not reached
  tags = "${map("Name", "${local.name_prefix}-hardwired-pools")}"
}

data "aws_security_group" "linked_pools" {
  name        = "${local.name_prefix}-linked-pools"

	vpc_id = "${data.aws_vpc.selected.id}"

  tags = "${map("Name", "${local.name_prefix}-linked-pools")}"
}

################## IAM PROFILE ##################

data "aws_iam_instance_profile" "pool" {
	name	= "${local.name_prefix}-pool"
}

################## LOAD BALANCERS ##################

data "aws_elb" "healthz" {
	name									= "${local.name_prefix}-healthz"
}

################## S3 BUCKETS ##################

data "aws_s3_bucket" "cluster_config" {
	bucket							= "${var.s3_config_bucket}"
}

data "aws_s3_bucket" "is_private_amis" {
	count								= "${local.is_private_amis}"
	bucket							= "${var.s3_private_amis_bucket}"
}

/* Due both sides of conditional logic being checked in < v0.12 this must be pushed in externally
data "aws_instances" "rolling_update_asg" {
	count = "${var.rolling_update_asg != "0" ? 1 : 0}"
	instance_tags {
		cyvive = "cyvive"
	}
}
*/
/*
data "aws_vpc" "selected" {
	id = "${var.vpc_id}"
}

data "aws_subnet_ids" "selected" {
	vpc_id						= "${data.aws_vpc.selected.id}"
}

data "aws_subnet" "selected" {
	count = "${length(data.aws_subnet_ids.selected.ids)}"
	id		= "${data.aws_subnet_ids.selected.ids[count.index]}"
}
*/
