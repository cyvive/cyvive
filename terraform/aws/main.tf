data "template_file" "policy" {
  template = "${file("templates/policy.tpl")}"
  vars {
    bucket = "${aws_s3_bucket.cyvive_storage_bucket.id}"
  }
}

################## S3 ###################

resource "aws_s3_bucket" "cyvive_storage_bucket" {
	bucket = "${random_pet.cyvive_ami_bucket.id}"
}

################## IAM ##################

resource "aws_iam_role" "vmimport" {
  name               = "vmimport"
  assume_role_policy = "${file("templates/assume-role-policy.json")}"
}


resource "aws_iam_role_policy" "import_disk_image" {
  name   = "import_disk_image"
  role   = "${aws_iam_role.vmimport.name}"
  policy = "${data.template_file.policy.rendered}"
}

resource "aws_key_pair" "ssh" {
  key_name   = "ssh"
  public_key = "${file("~/.ssh/id_rsa.pub")}"
}

resource "aws_security_group" "linuxkit" {
  name        = "linuxkit"
}

resource "aws_security_group_rule" "ssh" {
  type              = "ingress"
  security_group_id = "${aws_security_group.linuxkit.id}"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
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

resource "aws_placement_group" "cluster" {
	count			= "${length(data.aws_subnet_ids.selected.ids)}"
	name			= "${random_pet.placement_cluster.*.id[count.index]}"
	strategy	= "cluster"
}

resource "random_pet" "placement_cluster" {
	count = "${length(data.aws_subnet_ids.selected.ids)}"
	keepers = {
		placement = "${var.rename_placement_groups}"
	}
	prefix = "cyvive-${substr(data.aws_subnet.selected.*.availability_zone[count.index], -2, -1)}"
}

resource "random_pet" "cyvive_ami_bucket" {
	keepers = {
		bucket = "${var.cluster_name}"
	}
	prefix = "cyvive-ami-${var.cluster_name}"
}

