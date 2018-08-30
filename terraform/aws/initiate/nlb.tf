################## PUBLIC NLB ###################
########### @CONTROL PLANE & DASHBOAD ###########

resource "aws_route53_record" "apiserver" {
	count											= "${local.is_public_cluster}"
  zone_id										= "${local.cluster_zone_id}"

  #name = "${format("%s.%s.", var.cluster_name, var.dns_zone)}"
	# TODO strip redundant 'API' from all control plane records as NLB handles the port routing
	name											= "api-${local.cluster_fqdn}"
  type											= "A"

  # AWS recommends their special "alias" records for ELBs
  alias {
    name                   = "${aws_lb.control_plane.dns_name}"
    zone_id                = "${aws_lb.control_plane.zone_id}"
    evaluate_target_health = true
  }
}

resource "aws_eip" "nlb_control_plane" {
	count							= "3"
}

resource "aws_lb" "control_plane" {
	count								= "${local.is_public_cluster}"
	name								= "${local.name_prefix}-control-plane"
  load_balancer_type	= "network"
  internal						= "false"

  #subnets = ["${data.aws_subnet.ingress.*.id}"]
	subnet_mapping {
		subnet_id					= "${data.aws_subnet.ingress.0.id}"
		allocation_id			= "${aws_eip.nlb_control_plane.0.id}"
	}

	subnet_mapping {
		subnet_id					= "${data.aws_subnet.ingress.1.id}"
		allocation_id			= "${aws_eip.nlb_control_plane.1.id}"
	}

	subnet_mapping {
		subnet_id					= "${data.aws_subnet.ingress.2.id}"
		allocation_id			= "${aws_eip.nlb_control_plane.2.id}"
	}

	enable_cross_zone_load_balancing = true
}

# Forward TCP apiserver traffic to controllers
resource "aws_lb_listener" "control_plane_api_public" {
	count							= "${local.is_public_cluster}"
  load_balancer_arn = "${aws_lb.control_plane.arn}"
  protocol          = "TCP"
  port              = "6443"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.controllers_public.arn}"
  }
}

# Forward TCP apiserver traffic to controllers
resource "aws_lb_listener" "control_plane_dashboard_http" {
	count							= "${local.is_public_cluster}"
  load_balancer_arn = "${aws_lb.control_plane.arn}"
  protocol          = "TCP"
  port              = "80"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.controllers_dashboard_http.arn}"
  }
}

# Forward TCP apiserver traffic to controllers
resource "aws_lb_listener" "control_plane_dashboard_https" {
	count							= "${local.is_public_cluster}"
  load_balancer_arn = "${aws_lb.control_plane.arn}"
  protocol          = "TCP"
  port              = "443"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.controllers_dashboard_https.arn}"
  }
}

################## PRIVATE ELB ###################
########### @NODE HEALTH CHECKS & MESH ###########

# Network Load Balancer DNS Record
resource "aws_route53_record" "private_apiserver" {
	zone_id										= "${data.aws_route53_zone.private.id}"

	name											= "api-${local.cluster_fqdn}"
  type											= "A"

  # AWS recommends their special "alias" records for ELBs
  alias {
    name                   = "${aws_elb.control_plane_private.dns_name}"
    zone_id                = "${aws_elb.control_plane_private.zone_id}"
    evaluate_target_health = true
  }
}

resource "aws_elb" "healthz" {
	name									= "${local.name_prefix}-healthz"
  subnets								= ["${data.aws_subnet.pools.*.id}"]
	internal							= "true"
	security_groups				= ["${aws_security_group.hardwired_controllers.id}", "${aws_security_group.hardwired_pools.id}"]

	listener {
		instance_port				= 10256
		instance_protocol		= "TCP"
		lb_port							= 10256
		lb_protocol					= "TCP"
	}

	health_check {
		healthy_threshold		= 2
		unhealthy_threshold	= 2
		timeout							= 2
		target							= "HTTP:10256/healthz"
		interval						= 10
	}

	cross_zone_load_balancing = "true"
}

resource "aws_elb" "control_plane_private" {
	name									= "${local.name_prefix}-control-private"
  subnets								= ["${data.aws_subnet.pools.*.id}"]
	internal							= "true"

	listener {
		instance_port				= 6443
		instance_protocol		= "TCP"
		lb_port							= 6443
		lb_protocol					= "TCP"
	}

	listener {
		instance_port				= 10250
		instance_protocol		= "TCP"
		lb_port							= 10250
		lb_protocol					= "TCP"
	}

	listener {
		instance_port				= 10255
		instance_protocol		= "TCP"
		lb_port							= 10255
		lb_protocol					= "TCP"
	}

	listener {
		instance_port				= 10256
		instance_protocol		= "TCP"
		lb_port							= 10256
		lb_protocol					= "TCP"
	}

	health_check {
		healthy_threshold		= 2
		unhealthy_threshold	= 2
		timeout							= 2
		target							= "TCP:6443"
		interval						= 10
	}

	cross_zone_load_balancing = "true"
}

################## TARGET GROUPS ###################

resource "aws_lb_target_group" "controllers_public" {
	name									= "${local.name_prefix}-controllers-public"
  vpc_id								= "${data.aws_vpc.selected.id}"
  target_type						= "instance"
	proxy_protocol_v2			= "false"
	stickiness {
		type								= "lb_cookie"
		enabled							= "false"
	}

	#deregistration_delay	=	300
	#slow_start						= 120

  protocol							= "TCP"
  port									= 6443

  # TCP health check for apiserver
  health_check {
    protocol						= "TCP"
    port								= 10256

    # NLBs required to use same healthy and unhealthy thresholds
    healthy_threshold   = 2
    unhealthy_threshold = 2

    # Interval between health checks required to be 10 or 30
    interval						= 30
  }
}

resource "aws_lb_target_group" "controllers_private" {
	name									= "${local.name_prefix}-controllers-private"
  vpc_id								= "${data.aws_vpc.selected.id}"
  target_type						= "instance"
	proxy_protocol_v2			= "false"
	stickiness {
		type								= "lb_cookie"
		enabled							= "false"
	}

	#deregistration_delay	=	300
	#slow_start						= 120

  protocol							= "HTTPS"
  port									= 6443

  # TCP health check for apiserver
  health_check {
    protocol						= "HTTP"
		path								= "/healthz"
    port								= 10256
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval						= 30
  }
}


resource "aws_lb_target_group" "controllers_dashboard_http" {
	name									= "${local.name_prefix}-dashboard-http"
  vpc_id								= "${data.aws_vpc.selected.id}"
  target_type						= "instance"
	proxy_protocol_v2			= "false"
	stickiness {
		type								= "lb_cookie"
		enabled							= "false"
	}
	#deregistration_delay	=	300
	#slow_start						= 120

  protocol							= "TCP"
  port									= 80
  health_check {
    protocol						= "TCP"
    port								= 80
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval						= 30
  }
}

resource "aws_lb_target_group" "controllers_dashboard_https" {
	name									= "${local.name_prefix}-dashboard-https"
  vpc_id								= "${data.aws_vpc.selected.id}"
  target_type						= "instance"
	proxy_protocol_v2			= "false"
	stickiness {
		type								= "lb_cookie"
		enabled							= "false"
	}

	#deregistration_delay	=	300
	#slow_start						= 120

  protocol							= "TCP"
  port									= 443
  health_check {
    protocol						= "TCP"
    port								= 443
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval						= 30
  }
}

resource "aws_lb_target_group" "healthz" {
	name									= "${local.name_prefix}-healthz"
  vpc_id								= "${data.aws_vpc.selected.id}"
  target_type						= "instance"
	proxy_protocol_v2			= "false"
	stickiness {
		type								= "lb_cookie"
		enabled							= "false"
	}

	#deregistration_delay	=	300
	#slow_start						= 120

  protocol							= "HTTP"
  port									= 10256

  # TCP health check for apiserver
  health_check {
		protocol						= "HTTP"
		path								= "/healthz"
    port								= 10256

    # NLBs required to use same healthy and unhealthy thresholds
    healthy_threshold   = 2
    unhealthy_threshold = 2

    # Interval between health checks required to be 10 or 30
		# TODO upgrade to 30sec healthchecks
    interval						= 10
  }
}

