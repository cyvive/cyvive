# Select latest controller AMI
/*
data "aws_ami" "most_recent_cyvive_controller_ena" {
  most_recent = true
  owners = ["self"]
	name_regex = "cyvive-ena-controller"
}
*/
data "aws_ami" "most_recent_cyvive_controller_sd" {
  most_recent = true
  owners = ["self"]
	name_regex = "cyvive-controller"
}

/* Disabled until kubeadm join supports it
data "template_file" "kubecontrol" {
	template = "${file("templates/kubecontrol.yaml")}"
	vars {
		token_id = "${local.token_id}"
		bootstrap = "${aws_instance.bootstrap.private_ip}:6443"
	}
}

data "template_file" "kubenode" {
	template = "${file("templates/kubenode.yaml")}"
	vars {
		token_id = "${local.token_id}"
		bootstrap = "${aws_instance.bootstrap.private_ip}:6443"
	}
}
*/

locals {
	cluster_zone = "${var.cluster_public == "true" ? data.aws_route53_zone.public.name : data.aws_route53_zone.private.name}"
	cluster_fqdn = "${var.cluster_name}.${replace(local.cluster_zone, "/[.]$/", "")}"
	init_controller = {
		kubeadm = {
			entries = {
				join = {
					content = "--token ${local.token_id} --discovery-token-unsafe-skip-ca-verification ${aws_instance.bootstrap.private_ip}:6443"
				},
				/* Currently disabled due to a bug in kubeadm join --config where its still enforcing DockerShim
				kubeadm.yaml = {
					content = "${data.template_file.kubecontrol.rendered}"
				}
				*/
			}
		}
	}
	init_pool = {
		kubenode = {
			entries = {
				join = {
					content = "--token ${local.token_id} --discovery-token-unsafe-skip-ca-verification ${aws_instance.bootstrap.private_ip}:6443"
				},
				/* Currently disabled due to a bug in kubeadm join --config where its still enforcing DockerShim
				config.yaml = {
					content = "${data.template_file.kubenode.rendered}"
				},
				*/
			}
		}
	}
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
