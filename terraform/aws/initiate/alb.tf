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
	count											= "${local.is_public_cluster}"
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
  load_balancer_type = "application"
  internal           = "${local.is_alb_public_cluster}"

  subnets = ["${data.aws_subnet.ingress.*.id}"]
	# TODO Security Group for Load Balancer
	security_groups		 = ["${aws_security_group.controllers.id}"]

	# TODO upgrade to IPV6 as well
	# ip_address_type		 = "dualstack"

  enable_cross_zone_load_balancing = true
}

/*
resource "aws_acm_certificate" "apiserver_https" {
	domain_name							= "api-${local.cluster_fqdn}"
	validation_method				= "DNS"

	lifecycle {
		create_before_destroy	= "true"
	}
}

resource "aws_route53_record" "apiserver_https_validation" {
	zone_id			= "${data.aws_route53_zone.private.id}"

	name				= "${aws_acm_certificate.apiserver_https.domain_validation_options.resource_record_name}"
  type				= "${aws_acm_certificate.apiserver_https.domain_validation_options.resource_record_type}"
  records			= ["${aws_acm_certificate.apiserver_https.domain_validation_options.resource_record_value}"]
}
*/

/*
module "certificate_apiserver_https" {
	source = "github.com/azavea/terraform-aws-acm-certificate?ref=0.1.0"

	domain_name								= "api-${local.cluster_fqdn}"
	subject_alternative_names	= []
	#subject_alternative_names	= ["api-${local.cluster_fqdn}"]
	# Must be used against a public zone for certificate validation
	hosted_zone_id						=	"${data.aws_route53_zone.public.id}"
	validation_record_ttl			= "60"
}
*/

resource "tls_private_key" "bootstrap" {
	algorithm	= "ECDSA"
}

resource "tls_self_signed_cert" "apiserver_https" {
	key_algorithm					= "${tls_private_key.bootstrap.algorithm}"
	private_key_pem				=	"${tls_private_key.bootstrap.private_key_pem}"

	subject {
		common_name					= "${local.cluster_fqdn}"
		organization				= "Cyvive"
	}

	validity_period_hours	= 8760
	allowed_uses					= [
		"server_auth",
		"client_auth",
		"key_encipherment",
		"key_agreement",
		"digital_signature",
		"cert_signing"
	]

	dns_names							= ["api-${local.cluster_fqdn}", "${local.cluster_fqdn}"]
}

# Forward TCP apiserver traffic to controllers
/*
resource "aws_lb_listener" "apiserver-https" {
  load_balancer_arn = "${aws_lb.control_plane.arn}"
  protocol          = "HTTPS"
  port              = "6443"
	ssl_policy				= "ELBSecurityPolicy-2016-08"
	certificate_arn		= "${aws_iam_server_certificate.apiserver_https.arn}"

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
    protocol						= "HTTPS"
    port								= 6443

    # NLBs required to use same healthy and unhealthy thresholds
    healthy_threshold   = 3
    unhealthy_threshold = 3

    # Interval between health checks required to be 10 or 30
    interval						= 10
  }
}
