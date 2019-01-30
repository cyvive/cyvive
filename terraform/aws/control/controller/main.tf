################## ETCD DNS ENTRIES ##################
resource "aws_route53_record" "etcd_private" {
  zone_id										= "${var.zone_id_private}"

	name											= "etcd${var.az}-${var.cluster_fqdn}"
  type											= "CNAME"
	records	= ["${aws_instance.per_instance.private_dns}"]
	ttl			= 10
}

################## INSTANCE MANAGEMENT ##################
# Transitory point for ASG replacement ~ https://github.com/cyvive/cyvive/issues/48
resource "aws_instance" "per_instance" {
	ami																		= "${var.image_id}"
	iam_instance_profile									= "${var.iam_instance_profile}"
	instance_initiated_shutdown_behavior	= "terminate"
	monitoring														= false
  instance_type													= "${var.instance_type}"
  key_name															= "${var.ssh_key}"
  vpc_security_group_ids								= ["${var.security_groups}"]

	# Disks
	ephemeral_block_device {
		device_name						= "/dev/sdb"
		virtual_name					= "ephemeral0"
	}

	# Networking
	subnet_id															= "${var.subnet_id}"
  associate_public_ip_address						= true
	#ipv6_address_count										= 1

	tags = {
		Name	= "${var.name_prefix}-control-a"
	}

	user_data_base64 = "${var.user_data_base64}"
}

# Placeholder for ASG upgrade
resource "aws_launch_template" "per_instance" {
	image_id								= "${var.image_id}"
  instance_type						= "${var.instance_type}"
  key_name								= "${var.ssh_key}"
  vpc_security_group_ids	= ["${var.security_groups}"]

	block_device_mappings {
		device_name						= "/dev/sdb"
		virtual_name					= "ephemeral0"
	}

	capacity_reservation_specification {
		capacity_reservation_preference = "open"
	}

	iam_instance_profile {
		name									= "${var.iam_instance_profile}"
	}

	instance_initiated_shutdown_behavior = "terminate"

	monitoring {
		enabled								= false
	}

	network_interfaces {
		associate_public_ip_address = true
		delete_on_termination				= true
		ipv4_address_count					= 1
		ipv6_address_count					= 1
		subnet_id										= "${var.subnet_id}"
		device_index								= 0
	}

	placement {
		group_name									= "${var.pet_placement}"
	}

	tags = {
		Name	= "${var.name_prefix}-control-b"
	}

	user_data											= "${var.user_data_base64}"

	/*
	lifecycle {
    create_before_destroy = true
  }
	*/
}

################## ELB ATTACHMENTS ##################
resource "aws_lb_target_group_attachment" "public" {
	count							= "${var.is_public_cluster}"
  target_group_arn	= "${var.lb_public}"
  target_id					= "${aws_instance.per_instance.id}"
}

resource "aws_lb_target_group_attachment" "dashboard" {
	count							= "${var.is_public_cluster}"
  target_group_arn	= "${var.lb_dashboard}"
  target_id					= "${aws_instance.per_instance.id}"
}

resource "aws_lb_target_group_attachment" "dashboard_https" {
	count							= "${var.is_public_cluster}"
  target_group_arn	= "${var.lb_dashboard_https}"
  target_id					= "${aws_instance.per_instance.id}"
}

resource "aws_elb_attachment" "private" {
	elb				= "${var.lb_private}"
	instance	= "${aws_instance.per_instance.id}"
}

resource "aws_elb_attachment" "healthz" {
	elb				= "${var.lb_healthz}"
	instance	= "${aws_instance.per_instance.id}"
}

################## ANTI/AKIDO PATTERN  ##################

data "aws_elb" "debug_private" {
	count									=	"${var.debug}"
	name									= "${var.name_prefix}-debug-private"
}

data "aws_elb" "debug_public" {
	count									=	"${var.debug * var.is_public_cluster}"
	name									= "${var.name_prefix}-debug-public"
}

resource "aws_elb_attachment" "debug_private" {
	count			= "${var.debug}"
	elb				= "${data.aws_elb.debug_private.id}"
	instance	= "${aws_instance.per_instance.id}"
}

resource "aws_elb_attachment" "debug_public" {
	count			= "${var.debug}"
	elb				= "${data.aws_elb.debug_public.id}"
	instance	= "${aws_instance.per_instance.id}"
}

# TODO testing only!!!
# TODO anti-pattern... enable this as a variable for external etcd access (external backup.. should be disabled by default)

resource "aws_route53_record" "etcd_public" {
  zone_id										= "${var.zone_id_public}"

	name											= "etcda-${var.cluster_fqdn}"
  type											= "CNAME"
	records	= ["${aws_instance.per_instance.public_dns}"]
	ttl			= 10
}

################## AUTOSCALING  ##################
/*
resource "aws_autoscaling_group" "per_instance" {
	count											=	"${var.enable == "true" ? length(var.instance_types) : 0}"

	name											= "${var.cluster_name}-${var.pet_placement}-${replace(var.instance_types[count.index], ".", "-")}"
	max_size									= "${var.pool_maximum_size}"
	min_size									= "0"
	launch_configuration			= "${element(aws_launch_configuration.per_instance.*.name, count.index)}"
	health_check_grace_period = 120
	health_check_type					= "ELB"
	load_balancers						= ["${var.elb_names}"]
	vpc_zone_identifier				= ["${var.subnet_id}"]
	termination_policies			= [ "OldestLaunchConfiguration", "ClosestToNextInstanceHour" ]
}
*/
