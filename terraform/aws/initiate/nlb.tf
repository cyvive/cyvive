################## NLB @ CONTROL PLANE ###################
# Network Load Balancer DNS Record
resource "aws_route53_record" "private_apiserver" {
	zone_id										= "${data.aws_route53_zone.private.id}"

	name											= "api-${local.cluster_fqdn}"
  type											= "A"

  # AWS recommends their special "alias" records for ELBs
  alias {
    name                   = "${aws_lb.control_plane.dns_name}"
    zone_id                = "${aws_lb.control_plane.zone_id}"
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "apiserver" {
	#count											= "${local.is_public_cluster}"
  zone_id										= "${local.cluster_zone_id}"

  #name = "${format("%s.%s.", var.cluster_name, var.dns_zone)}"
	name											= "api-${local.cluster_fqdn}"
  type											= "A"

  # AWS recommends their special "alias" records for ELBs
  alias {
    name                   = "${aws_lb.control_plane.dns_name}"
    zone_id                = "${aws_lb.control_plane.zone_id}"
    evaluate_target_health = true
  }
}

# Network Load Balancer for apiservers and ingress
resource "aws_lb" "control_plane" {
	name               = "${local.name_prefix}-control-plane"
  load_balancer_type = "network"
  internal           = "${local.is_nlb_public_cluster}"

  subnets = ["${data.aws_subnet.ingress.*.id}"]

  enable_cross_zone_load_balancing = true
}

# Forward TCP apiserver traffic to controllers
resource "aws_lb_listener" "apiserver-https" {
  load_balancer_arn = "${aws_lb.control_plane.arn}"
  protocol          = "TCP"
  port              = "6443"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.controllers.arn}"
  }
}

/*
# Forward HTTP ingress traffic to workers
resource "aws_lb_listener" "ingress-http" {
  load_balancer_arn = "${aws_lb.control_plane.arn}"
  protocol          = "TCP"
  port              = 80

  default_action {
    type             = "forward"
    target_group_arn = "${module.workers.target_group_http}"
  }
}

# Forward HTTPS ingress traffic to workers
resource "aws_lb_listener" "ingress-https" {
  load_balancer_arn = "${aws_lb.control_plane.arn}"
  protocol          = "TCP"
  port              = 443

  default_action {
    type             = "forward"
    target_group_arn = "${module.workers.target_group_https}"
  }
}
*/
# Target group of controllers
resource "aws_lb_target_group" "controllers" {
	name									= "${local.name_prefix}-controllers"
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
    healthy_threshold   = 3
    unhealthy_threshold = 3

    # Interval between health checks required to be 10 or 30
    interval						= 10
  }
}
