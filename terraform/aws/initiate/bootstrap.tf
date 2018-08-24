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

################## BOOTSTRAP ##################
data "template_file" "kubeadm" {
  template										= "${file("templates/kubeadm.yaml")}"
  vars {
    token_id									= "${local.token_id}"
		cluster_domain						= "${var.cluster_domain_suffix}"
		cluster_api_endpoint			=	"api-${local.cluster_fqdn}"
  }
}

data "template_file" "bootstrap_lb" {
  template										= "${file("templates/bootstrap_lb.tpl")}"
	vars {
		lb_arn										= "${aws_lb.control_plane.arn}"
		target_group_arn					= "${aws_lb_target_group.controllers.arn}"
  }
}

resource "aws_instance" "bootstrap" {
	ami													= "${data.aws_ami.most_recent_cyvive_generic.id}"
  instance_type								= "m4.large"
  key_name										= "${local.ssh_key}"
	vpc_security_group_ids			= ["${aws_security_group.controllers.id}"]
	#subnet_id = "subnet-099a536c"
  associate_public_ip_address = true
	ebs_block_device {
		device_name								= "/dev/sdb"
		volume_size								= "10"
		delete_on_termination			= true
	}
	iam_instance_profile				= "${aws_iam_instance_profile.controller.name}"
	tags = {
		Name	= "${local.name_prefix}-bootstrap"
	}
	user_data_base64 = "${base64encode(jsonencode(local.init_bootstrap))}"
}

# Attach controller instances to apiserver NLB
resource "aws_lb_target_group_attachment" "controllers" {
  target_group_arn = "${aws_lb_target_group.controllers.arn}"
  target_id        = "${aws_instance.bootstrap.id}"
  #target_id        = "${element(aws_instance.controllers.*.id, count.index)}"
  port             = 6443
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
