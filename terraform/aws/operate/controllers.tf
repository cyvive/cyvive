# Discrete DNS records for each controller's private IPv4 for etcd usage
/*
resource "aws_route53_record" "etcds" {
  count = "${var.controller_count}"

  # DNS Zone where record should be created
  zone_id = "${var.dns_zone_id}"

  name = "${format("%s-etcd%d.%s.", var.cluster_name, count.index, var.dns_zone)}"
  type = "A"
  ttl  = 300

  # private IPv4 address for etcd
  records = ["${element(aws_instance.controllers.*.private_ip, count.index)}"]
}
*/

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

module "pool_controller" {
	source = "nodes"

	pool_maximum_size				= "${var.pool_maximum_size}"
	vpc_id									= "${var.vpc_id}"
	pet_placement						=	"${aws_placement_group.cluster.*.id}"
	subnet_size							= "${length(data.aws_subnet_ids.selected.ids)}"
	subnet_ids							= "${data.aws_subnet.selected.*.id}"
	subnet_azs							=	"${data.aws_subnet.selected.*.availability_zone}"
	launch_configuration		= "${aws_launch_configuration.cyvive_controller.name}"
	pool_name								= "controller"
	instance_type						=	"${var.controller_type}" # Inherited, don't override
	cluster_name						= "${var.cluster_name}"
}













# Controller instances
/* Moving into CloudFormation
resource "aws_instance" "controllers" {
  count = "${var.controller_count}"

  tags = {
    Name = "${var.cluster_name}-controller-${count.index}"
  }

  instance_type = "${var.controller_type}"

  ami       = "${local.ami_id}"
  user_data = "${element(data.ct_config.controller_ign.*.rendered, count.index)}"

  # storage
  root_block_device {
    volume_type = "${var.disk_type}"
    volume_size = "${var.disk_size}"
  }

  # network
  associate_public_ip_address = true
  subnet_id                   = "${element(aws_subnet.public.*.id, count.index)}"
  vpc_security_group_ids      = ["${aws_security_group.controller.id}"]

  lifecycle {
    ignore_changes = ["ami"]
  }
}

# Controller Container Linux Config
data "template_file" "controller_config" {
  count = "${var.controller_count}"

  template = "${file("${path.module}/cl/controller.yaml.tmpl")}"

  vars = {
    # Cannot use cyclic dependencies on controllers or their DNS records
    etcd_name   = "etcd${count.index}"
    etcd_domain = "${var.cluster_name}-etcd${count.index}.${var.dns_zone}"

    # etcd0=https://cluster-etcd0.example.com,etcd1=https://cluster-etcd1.example.com,...
    etcd_initial_cluster = "${join(",", data.template_file.etcds.*.rendered)}"

    kubeconfig            = "${indent(10, module.bootkube.kubeconfig)}"
    ssh_authorized_key    = "${var.ssh_authorized_key}"
    k8s_dns_service_ip    = "${cidrhost(var.service_cidr, 10)}"
    cluster_domain_suffix = "${var.cluster_domain_suffix}"
  }
}

data "template_file" "etcds" {
  count    = "${var.controller_count}"
  template = "etcd$${index}=https://$${cluster_name}-etcd$${index}.$${dns_zone}:2380"

  vars {
    index        = "${count.index}"
    cluster_name = "${var.cluster_name}"
    dns_zone     = "${var.dns_zone}"
  }
}

data "ct_config" "controller_ign" {
  count        = "${var.controller_count}"
  content      = "${element(data.template_file.controller_config.*.rendered, count.index)}"
  pretty_print = false
  snippets     = ["${var.controller_clc_snippets}"]
}
*/
