################## ETCD DNS ENTRIES ##################

resource "aws_route53_record" "etcda" {
  zone_id										= "${data.aws_route53_zone.private.id}"

	name											= "etcda-${local.cluster_fqdn}"
  type											= "CNAME"
	records	= ["${aws_instance.controller_a.private_dns}"]
	ttl			= 10
}

################## BOOTSTRAP ##################
data "template_file" "kubeadm" {
  template										= "${file("templates/kubeadm.yaml")}"
  vars {
    token_id									= "${local.token_id}"
		cluster_domain						= "${var.cluster_domain_suffix}"
		cluster_fqdn							=	"${local.cluster_fqdn}"
  }
}

/*
data "template_file" "terraform_main" {
  template										= "${file("templates/terraform_main.tf")}"
	vars {
  }
}

data "template_file" "terraform_vars" {
  template										= "${file("templates/terraform_vars.tpl")}"
	vars {
		lb_arn										= "${aws_lb.healthz.arn}"
  }
}
*/

resource "aws_instance" "controller_a" {
	ami													= "${data.aws_ami.most_recent_cyvive_generic.id}"
  instance_type								= "${var.controller_type}"
  key_name										= "${local.ssh_key}"
	#vpc_security_group_ids			= ["sg-8514c9e0"]
	vpc_security_group_ids			= [ "${data.aws_security_group.intra_cluster.id}",
																	"${data.aws_security_group.controllers.id}" ]
	subnet_id										= "${data.subnet_id.a}"
  associate_public_ip_address = true
	ebs_block_device {
		device_name								= "/dev/sdb"
		volume_size								= "${var.oci_cache_disk_size}"
		volume_type								=	"${var.oci_cache_disk_type}"
		iops											= "${var.oci_cache_disk_iops}"
		encrypted									= true
	}
	iam_instance_profile				= "${data.aws_iam_instance_profile.controller.name}"
	tags = {
		Name	= "${local.name_prefix}-control-a"
	}
	user_data_base64 = "${base64encode(jsonencode(local.init_controller))}"
}

# Attach controller instances to apiserver NLB
resource "aws_lb_target_group_attachment" "controller_a_public" {
	count							= "${local.is_public_cluster}"
  target_group_arn	= "${data.aws_lb_target_group.controllers_public.arn}"
  target_id					= "${aws_instance.controller_a.id}"
}

resource "aws_lb_target_group_attachment" "controller_a_dashboard" {
	count							= "${local.is_public_cluster}"
  target_group_arn	= "${data.aws_lb_target_group.controllers_dashboard_http.arn}"
  target_id					= "${aws_instance.controller_a.id}"
}

resource "aws_lb_target_group_attachment" "controller_a_dashboard_https" {
	count							= "${local.is_public_cluster}"
  target_group_arn	= "${data.aws_lb_target_group.controllers_dashboard_https.arn}"
  target_id					= "${aws_instance.controller_a.id}"
}

resource "aws_elb_attachment" "controller_a_private" {
	elb				= "${data.aws_elb.control_plane_private.id}"
	instance	= "${aws_instance.controller_a.id}"
}

resource "aws_elb_attachment" "controller_a_healthz" {
	elb				= "${data.aws_elb.healthz.id}"
	instance	= "${aws_instance.controller_a.id}"
}

