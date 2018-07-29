# Select latest pool AMI
data "aws_ami" "most_recent_cyvive_pool" {
  most_recent = true
  owners = ["self"]
	name_regex = "aws"
}

resource "aws_launch_configuration" "cyvive_pool" {
  image_id				= "${data.aws_ami.most_recent_cyvive_pool.id}"
  instance_type		= "${var.pool_type}"
  key_name        = "${aws_key_pair.ssh.key_name}"
  security_groups = ["${aws_security_group.linuxkit.id}"]
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

module "pool_itstarts" {
	source = "nodes"

	pool_maximum_size				= "${var.pool_maximum_size}"
	vpc_id									= "${var.vpc_id}"
	pet_placement						=	"${aws_placement_group.cluster.*.id}"
	subnet_size							= "1"
	subnet_ids							= "${data.aws_subnet.selected.*.id}"
	subnet_azs							=	"${data.aws_subnet.selected.*.availability_zone}"
	launch_configuration		= "${aws_launch_configuration.cyvive_pool.name}"
	pool_name								= "itstarts"
	instance_type						=	"${var.pool_type}" # Inherited, don't override
	cluster_name						= "${var.cluster_name}"
}
/*
module "workers" {
  source = "workers"
  name   = "${var.cluster_name}"

  # AWS
  vpc_id          = "${aws_vpc.network.id}"
  subnet_ids      = ["${aws_subnet.public.*.id}"]
  security_groups = ["${aws_security_group.worker.id}"]
  count           = "${var.worker_count}"
  instance_type   = "${var.worker_type}"
  os_image        = "${var.os_image}"
  disk_size       = "${var.disk_size}"
  spot_price      = "${var.worker_price}"

  # configuration
  kubeconfig            = "${module.bootkube.kubeconfig}"
  ssh_authorized_key    = "${var.ssh_authorized_key}"
  service_cidr          = "${var.service_cidr}"
  cluster_domain_suffix = "${var.cluster_domain_suffix}"
  clc_snippets          = "${var.worker_clc_snippets}"
}
*/


