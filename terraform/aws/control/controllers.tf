################## ETCD DNS ENTRIES ##################

resource "aws_route53_record" "etcda" {
  zone_id										= "${data.aws_route53_zone.private.id}"

	name											= "etcda-${local.cluster_fqdn}"
  type											= "CNAME"
	records	= ["${aws_instance.controller_a.private_dns}"]
	ttl			= 10
}
resource "aws_route53_record" "etcdb" {
  zone_id										= "${data.aws_route53_zone.private.id}"

	name											= "etcdb-${local.cluster_fqdn}"
  type											= "CNAME"
	records	= ["${aws_instance.controller_b.private_dns}"]
	ttl			= 10
}
resource "aws_route53_record" "etcdc" {
  zone_id										= "${data.aws_route53_zone.private.id}"

	name											= "etcdc-${local.cluster_fqdn}"
  type											= "CNAME"
	records	= ["${aws_instance.controller_c.private_dns}"]
	ttl			= 10
}

# TODO testing only!!!
# TODO anti-pattern... enable this as a variable for external etcd access (external backup.. should be disabled by default)
resource "aws_route53_record" "etcda_public" {
  zone_id										= "${data.aws_route53_zone.public.id}"

	name											= "etcda-${local.cluster_fqdn}"
  type											= "CNAME"
	records	= ["${aws_instance.controller_a.public_dns}"]
	ttl			= 10
}
################## LOCAL KUBECTL - ADMIN ##################
resource "null_resource" "controller_a" {
	triggers = {
		controller_a_id = "${aws_instance.controller_a.id}"
	}

	provisioner "local-exec" {
		command		= "./local-exec/wait-for-admin.sh ${var.s3_config_bucket}"
	}

	depends_on	= [ "aws_instance.controller_a" ]
}

################## BOOTSTRAP ##################
data "template_file" "kubeadm" {
  template										= "${file("templates/kubeadm.yaml")}"
  vars {
		cluster_name							= "${var.cluster_name}"
    token_id									= "${local.token_id}"
		cluster_domain						= "${var.cluster_domain_suffix}"
		cluster_fqdn							=	"${local.cluster_fqdn}"
		debug_subdomain						=	"debug."
		kubernetes_version				= "${local.kubernetes_version}"
  }
}

data "template_file" "kubecontrol" {
  template										= "${file("templates/kubecontrol.yaml")}"
  vars {
    token_id									= "${local.token_id}"
		cluster_name							= "${var.cluster_name}"
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
	ami													= "${local.ami_image}"
  instance_type								= "${var.controller_type}"
  key_name										= "${local.ssh_key}"
	vpc_security_group_ids			= [ "${data.aws_security_group.intra_cluster.id}",
																	"${data.aws_security_group.controllers.id}" ]
	subnet_id										= "${data.aws_subnet.a.id}"
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

resource "aws_instance" "controller_b" {
	ami													= "${local.ami_image}"
  instance_type								= "${var.controller_type}"
  key_name										= "${local.ssh_key}"
	vpc_security_group_ids			= [ "${data.aws_security_group.intra_cluster.id}",
																	"${data.aws_security_group.controllers.id}" ]
	subnet_id										= "${data.aws_subnet.b.id}"
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
		Name	= "${local.name_prefix}-control-b"
	}
	user_data_base64 = "${base64encode(jsonencode(local.init_controller))}"

	#depends_on			 = [ "null_resource.controller_a" ]
}

resource "aws_instance" "controller_c" {
	ami													= "${local.ami_image}"
  instance_type								= "${var.controller_type}"
  key_name										= "${local.ssh_key}"
	vpc_security_group_ids			= [ "${data.aws_security_group.intra_cluster.id}",
																	"${data.aws_security_group.controllers.id}" ]
	subnet_id										= "${data.aws_subnet.c.id}"
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
		Name	= "${local.name_prefix}-control-c"
	}
	user_data_base64 = "${base64encode(jsonencode(local.init_controller))}"

	#depends_on			 = [ "null_resource.controller_a" ]
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

resource "aws_elb_attachment" "debug_private" {
	count			= "${local.debug}"
	elb				= "${data.aws_elb.debug_private.id}"
	instance	= "${aws_instance.controller_a.id}"
}

resource "aws_elb_attachment" "debug_public" {
	count			= "${local.debug}"
	elb				= "${data.aws_elb.debug_public.id}"
	instance	= "${aws_instance.controller_a.id}"
}

