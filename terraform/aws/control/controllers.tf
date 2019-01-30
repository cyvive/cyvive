################## LOCAL KUBECTL - ADMIN ##################
resource "null_resource" "controller_a" {
	triggers = {
		controller_a_id = "${module.az_a.controller_id}"
	}

	provisioner "local-exec" {
		command		= "./local-exec/wait-for-admin.sh ${var.s3_config_bucket}"
	}

	depends_on	= [ "module.az_a" ]
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

################## CONTROL INSTANCES ##################

module "az_a" {
	source	= "controller"

	az											= "a"

	iam_instance_profile		= "${data.aws_iam_instance_profile.controller.name}"
	lb_dashboard						= "${data.aws_lb_target_group.controllers_dashboard_http.arn}"
	lb_dashboard_https			= "${data.aws_lb_target_group.controllers_dashboard_https.arn}"
	lb_healthz							= "${data.aws_elb.healthz.id}"
	lb_private							= "${data.aws_elb.control_plane_private.id}"
	lb_public								= "${data.aws_lb_target_group.controllers_public.arn}"
	pet_placement						=	"${element(aws_placement_group.spread.*.name, 0)}"
	subnet_id								= "${data.aws_subnet.a.id}"
	zone_id_private					= "${data.aws_route53_zone.private.id}"
	zone_id_public					= "${data.aws_route53_zone.public.id}"

	security_groups					= [ "${data.aws_security_group.intra_cluster.id}",
															"${data.aws_security_group.controllers.id}" ]

	# Direct Map of Locals
	cluster_fqdn						= "${local.cluster_fqdn}"
	debug										= "${local.debug}"
	image_id								= "${local.ami_image}"
	instance_type 					=	"${local.instance_type}"
	is_public_cluster				= "${local.is_public_cluster}"
	name_prefix							= "${local.name_prefix}"
	ssh_key									= "${local.ssh_key}"

	# Direct Map from Variables
	cluster_name						= "${var.cluster_name}"
	oci_cache_disk_size			= "${var.oci_cache_disk_size}"
	oci_cache_disk_type			= "${var.oci_cache_disk_type}"

  #tags										= "${map("Name", "${local.name_prefix}-controllers")}"

	user_data_base64				= "${base64encode(jsonencode(local.init_controller))}"
}

module "az_b" {
	source	= "controller"

	az											= "b"

	iam_instance_profile		= "${data.aws_iam_instance_profile.controller.name}"
	lb_dashboard						= "${data.aws_lb_target_group.controllers_dashboard_http.arn}"
	lb_dashboard_https			= "${data.aws_lb_target_group.controllers_dashboard_https.arn}"
	lb_healthz							= "${data.aws_elb.healthz.id}"
	lb_private							= "${data.aws_elb.control_plane_private.id}"
	lb_public								= "${data.aws_lb_target_group.controllers_public.arn}"
	pet_placement						=	"${element(aws_placement_group.spread.*.name, 1)}"
	subnet_id								= "${data.aws_subnet.b.id}"
	zone_id_private					= "${data.aws_route53_zone.private.id}"
	zone_id_public					= "${data.aws_route53_zone.public.id}"

	security_groups					= [ "${data.aws_security_group.intra_cluster.id}",
															"${data.aws_security_group.controllers.id}" ]

	# Direct Map of Locals
	cluster_fqdn						= "${local.cluster_fqdn}"
	debug										= "${local.debug}"
	image_id								= "${local.ami_image}"
	instance_type 					=	"${local.instance_type}"
	is_public_cluster				= "${local.is_public_cluster}"
	name_prefix							= "${local.name_prefix}"
	ssh_key									= "${local.ssh_key}"

	# Direct Map from Variables
	cluster_name						= "${var.cluster_name}"
	oci_cache_disk_size			= "${var.oci_cache_disk_size}"
	oci_cache_disk_type			= "${var.oci_cache_disk_type}"

  #tags										= "${map("Name", "${local.name_prefix}-controllers")}"

	user_data_base64				= "${base64encode(jsonencode(local.init_controller))}"
}

module "az_c" {
	source	= "controller"

	az											= "c"

	iam_instance_profile		= "${data.aws_iam_instance_profile.controller.name}"
	lb_dashboard						= "${data.aws_lb_target_group.controllers_dashboard_http.arn}"
	lb_dashboard_https			= "${data.aws_lb_target_group.controllers_dashboard_https.arn}"
	lb_healthz							= "${data.aws_elb.healthz.id}"
	lb_private							= "${data.aws_elb.control_plane_private.id}"
	lb_public								= "${data.aws_lb_target_group.controllers_public.arn}"
	pet_placement						=	"${element(aws_placement_group.spread.*.name, 2)}"
	subnet_id								= "${data.aws_subnet.c.id}"
	zone_id_private					= "${data.aws_route53_zone.private.id}"
	zone_id_public					= "${data.aws_route53_zone.public.id}"

	security_groups					= [ "${data.aws_security_group.intra_cluster.id}",
															"${data.aws_security_group.controllers.id}" ]

	# Direct Map of Locals
	cluster_fqdn						= "${local.cluster_fqdn}"
	debug										= "${local.debug}"
	image_id								= "${local.ami_image}"
	instance_type 					=	"${local.instance_type}"
	is_public_cluster				= "${local.is_public_cluster}"
	name_prefix							= "${local.name_prefix}"
	ssh_key									= "${local.ssh_key}"

	# Direct Map from Variables
	cluster_name						= "${var.cluster_name}"
	oci_cache_disk_size			= "${var.oci_cache_disk_size}"
	oci_cache_disk_type			= "${var.oci_cache_disk_type}"

  #tags										= "${map("Name", "${local.name_prefix}-controllers")}"

	user_data_base64				= "${base64encode(jsonencode(local.init_controller))}"
}

