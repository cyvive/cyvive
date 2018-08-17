################## LOCALS ##################

locals {
	is_private_amis			= "${var.s3_private_amis_bucket == "" ? 0 : 1}"
	is_public_amis			= "${var.s3_private_amis_bucket == "" ? 1 : 0}"
	ami_owner						= "${var.s3_private_amis_bucket == "" ? "self" : "742773893669"}"
	is_ssh							= "${var.ssh_enabled == "0" ? 0 : 1}"
	ssh_key							= "${var.ssh_enabled == "0" ? "" : var.ssh_authorized_key}"
	name_prefix					=	"${var.cluster_name}"
	cluster_zone				= "${var.cluster_public == "true" ? data.aws_route53_zone.public.name : data.aws_route53_zone.private.name}"
	cluster_fqdn				= "${var.cluster_name}.${replace(local.cluster_zone, "/[.]$/", "")}"
	token_combiner			= "${random_string.tokenA.result}.${random_string.tokenB.result}"
	token_id						= "${var.pool_token == "" ? local.token_combiner : var.pool_token}"

	init_bootstrap = {
		kubeadm = {
			entries = {
				init = {
					content			= ""
				},
				kubeadm.yaml	= {
					content			= "${data.template_file.kubeadm.rendered}"
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

data "aws_vpc" "selected" {
	id			= "${var.vpc_id}"
}

data "aws_subnet_ids" "selected" {
	vpc_id	= "${data.aws_vpc.selected.id}"
}

data "aws_subnet" "selected" {
	count		= "${length(data.aws_subnet_ids.selected.ids)}"
	id			= "${data.aws_subnet_ids.selected.ids[count.index]}"
}

################## ROUTE53 INFORMATION ##################

data "aws_route53_zone" "public" {
	name	= "${var.dns_zone}"
}

data "aws_route53_zone" "private" {
	name	= "${var.dns_zone}"
}



################## PLACEMENT GROUPS ##################

resource "random_pet" "placement_cluster" {
	count				= "${length(data.aws_subnet_ids.selected.ids)}"
	keepers = {
		placement = "${var.rename_placement_groups}"
	}
	prefix			= "cyvive-${local.name_prefix}-${substr(data.aws_subnet.selected.*.availability_zone[count.index], -2, -1)}"
}

resource "random_pet" "placement_spread" {
	count				= "${length(data.aws_subnet_ids.selected.ids)}"
	keepers = {
		placement = "${var.rename_placement_groups}"
	}
	prefix			= "cyvive-${local.name_prefix}-${substr(data.aws_subnet.selected.*.availability_zone[count.index], -2, -1)}"
}

resource "aws_placement_group" "cluster" {
	count				= "${length(data.aws_subnet_ids.selected.ids)}"
	name				= "${random_pet.placement_cluster.*.id[count.index]}"
	strategy		= "cluster"
}

resource "aws_placement_group" "spread" {
	count				= "${length(data.aws_subnet_ids.selected.ids)}"
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

/*
resource "aws_instance" "linuxkit" {
  count = 1
  ami          = "ami-1944e27b"
  instance_type     = "t2.micro"
  key_name          = "${aws_key_pair.ssh.key_name}"
  security_groups             = ["${aws_security_group.linuxkit.name}"]
  associate_public_ip_address = true
}
*/

# AutoScaling / Rollout Approach
/*
data "aws_ami" "most_recent_cyvive_pool" {
  most_recent = true
  owners = ["self"]
	name_regex = "cyvive-pool"
}
*/

/*
resource "aws_launch_configuration" "sample_lc" {
  image_id = "${data.aws_ami.most_recent_cyvive_controller.id}"
  instance_type = "${var.pool_type}"

	lifecycle {
    create_before_destroy = true
  }
}
*/


/* Due both sides of conditional logic being checked in < v0.12 this must be pushed in externally
data "aws_instances" "rolling_update_asg" {
	count = "${var.rolling_update_asg != "0" ? 1 : 0}"
	instance_tags {
		cyvive = "cyvive"
	}
}
*/
