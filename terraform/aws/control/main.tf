################## LOCALS ##################

locals {
	is_public_cluster			= "${var.cluster_public == "true" ? "1" : 0}"
	is_nlb_public_cluster	= "${var.cluster_public == "true" ? "false" : "true"}"
	cluster_zone_id				= "${var.cluster_public == "true" ? data.aws_route53_zone.public.id: data.aws_route53_zone.private.id}"
	cluster_zone					= "${data.aws_route53_zone.private.name}"
	cluster_fqdn					= "${var.cluster_name}.${replace(local.cluster_zone, "/[.]$/", "")}"

	is_private_amis				= "${var.s3_private_amis_bucket == "" ? 0 : 1}"
	is_public_amis				= "${var.s3_private_amis_bucket == "" ? 1 : 0}"
	ami_owner							= "${var.s3_private_amis_bucket == "" ? "self" : "742773893669"}"

	is_ssh								= "${var.ssh_enabled == "0" ? 0 : 1}"
	ssh_key								= "${var.ssh_enabled == "0" ? "" : var.ssh_authorized_key}"

	name_prefix						=	"cyvive-${var.cluster_name}"

	token_id							= "${var.pool_token}"

	init_controller = {
		kubeadm = {
			entries = {
				join = {
					content = "--token ${local.token_id} --discovery-token-unsafe-skip-ca-verification api-${local.cluster_fqdn}:6443"
				},
				/*
				s3down					= {
					content				= "s3://${data.aws_s3_bucket.cluster_config.bucket}/kubeadm"
				}
				*/
			}
		}
	}
}

/*
>>> HERE Kublets still struggling to come oneline <<< @ Monday
- Create a private NLB and register the internal nodes against it
- port 10256 for healthcheck of kubelet security group should allow access within any of the private cidr_blocks
- private-api should be also available on this nlb set healthcheck port to same as kublet
- change cloudformation script to use the private nlb for healthchecks (much easier, and needed anyway) 30sec is fine as k8's operates on a different life cycle

create public one for external access.


BROKEN s3sync container has timing issues it needs to not sync anything until after the kublet fully comes online, just leave disabled and focus on pools for the moment
*/

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
/*
data "aws_s3_bucket" "is_private_amis" {
	count								= "${local.is_private_amis}"
	bucket							= "${var.bucket_private_amis}"
}
/*
resource "aws_instance" "controller" {
  count = 1
  #ami          = "${data.aws_ami.most_recent_cyvive_controller_sd.id}"
	ami													= "ami-0816b76a"
  instance_type     = "c4.large"
  key_name          = "ssh"
	vpc_security_group_ids = ["sg-4312cf26"]
	#subnet_id = "subnet-099a536c"
  associate_public_ip_address = true
	ebs_block_device {
		device_name		= "/dev/sdb"
		volume_size		= "10"
		delete_on_termination = true
	}
	#user_data_base64 = "${base64encode(jsonencode(local.init_controller))}"
}
*/
/*
resource "aws_instance" "pool" {
  count = 1
  ami          = "${data.aws_ami.most_recent_cyvive_controller_sd.id}"
  instance_type     = "m4.large"
  key_name          = "ssh"
	vpc_security_group_ids = ["sg-4312cf26"]
	#subnet_id = "subnet-099a536c"
  associate_public_ip_address = true
	ebs_block_device {
		device_name		= "/dev/sdb"
		volume_size		= "10"
		delete_on_termination = true
	}
	tags = {
		Name	= "${var.cluster_name}-pool-${count.index}"
	}
	user_data_base64 = "${base64encode(jsonencode(local.init_pool))}"
}
/*
resource "aws_launch_configuration" "cyvive_controller" {
  image_id				= "${data.aws_ami.most_recent_cyvive_controller.id}"
  instance_type		= "${var.controller_type}"
  key_name        = "${aws_key_pair.ssh.key_name}"
  security_groups	= ["${aws_security_group.linuxkit.id}"]
	#iam_instance_profile
	#user_data_base64

  associate_public_ip_address = true

	ebs_block_device {
		device_name		= "/dev/sda2"
		volume_size		= "10"
	}

	lifecycle {
    create_before_destroy = true
  }
}
*/
################## S3 ###################
/*
resource "aws_s3_bucket" "cyvive_storage_bucket" {
	bucket = "${random_pet.cyvive_ami_bucket.id}"
}
*/
################## IAM ##################

/*
resource "aws_key_pair" "ssh" {
  key_name   = "ssh"
  public_key = "${file("~/.ssh/id_rsa.pub")}"
}

resource "aws_security_group" "linuxkit" {
  name    = "linuxkit"
	vpc_id	= "${var.vpc_id}"
}

resource "aws_security_group_rule" "ssh" {
  type              = "ingress"
  security_group_id = "${aws_security_group.linuxkit.id}"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
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
