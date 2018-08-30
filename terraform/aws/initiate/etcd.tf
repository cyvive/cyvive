################## ETCD ##################

# Create the ELB's for each ETCD instance in the cluster
# TODO replace ELB's directly with a Lambda function & route53 updates
# https://www.npmjs.com/package/route53-controller
/*
resource "aws_elb" "etcd" {
	count											= "3"
	name											= "${local.name_prefix}-etcd-${count.index}"
	subnets										= ["${data.aws_subnet.pools.*.id}"]
	internal									= "true"
	cross_zone_load_balancing	= "true"

	listener {
		instance_port				= 2379
		instance_protocol		= "TCP"
		lb_port							= 2379
		lb_protocol					= "TCP"
	}

	listener {
		instance_port				= 2380
		instance_protocol		= "TCP"
		lb_port							= 2380
		lb_protocol					= "TCP"
	}

	listener {
		instance_port				= 2381
		instance_protocol		= "TCP"
		lb_port							= 2381
		lb_protocol					= "TCP"
	}

	health_check {
		healthy_threshold		= 2
		unhealthy_threshold	= 2
		timeout							= 2
		target							= "TCP:2379"
		interval						= 10
	}
}

resource "aws_route53_record" "etcd" {
	count											= "3"
  zone_id										= "${data.aws_route53_zone.private.id}"

	name											= "etcd${count.index}-${local.cluster_fqdn}"
  type											= "A"

  # AWS recommends their special "alias" records for ELBs
  alias {
    name										= "${element(aws_elb.etcd.*.dns_name, count.index)}"
    zone_id									= "${element(aws_elb.etcd.*.zone_id, count.index)}"
    evaluate_target_health	= true
  }
}
*/
resource "aws_route53_record" "etcda" {
  zone_id										= "${data.aws_route53_zone.private.id}"

	name											= "etcda-${local.cluster_fqdn}"
  type											= "CNAME"
	records	= ["${aws_instance.bootstrap.private_dns}"]
	ttl			= 10
}

