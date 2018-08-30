################## SECURITY GROUPS ##################

resource "aws_security_group" "intra_cluster" {
  name        = "${local.name_prefix}-intra"
  description = "${local.name_prefix} intra-cluster access"

  vpc_id = "${data.aws_vpc.selected.id}"

  tags = "${map("Name", "${local.name_prefix}-intra")}"

	ingress {
		protocol					= "-1"
		from_port					= 0
		to_port						= 0
		self							=	true
		description				= "intra-cluster-communication"
	}

	egress {
		protocol					= "-1"
	  from_port					= 0
		to_port						= 0
		self							=	true
		cidr_blocks				= [ "${concat(data.aws_subnet.ingress.*.cidr_block, data.aws_subnet.pools.*.cidr_block)}" ]
		description				= "intra-cluster-communication"
	}

}
resource "aws_security_group" "controllers" {
  name        = "${local.name_prefix}-controllers"
  description = "${local.name_prefix} controllers external access"

  vpc_id = "${data.aws_vpc.selected.id}"

  tags = "${map("Name", "${local.name_prefix}-controllers")}"

	ingress {
	  protocol    = "icmp"
		from_port   = 0
	  to_port     = 0
		cidr_blocks = [ "${local.enabled_cidrs}" ]
		description	= "icmp"
	}

	ingress {
	  protocol    = "tcp"
	  from_port   = 22
		to_port     = 22
		cidr_blocks = [ "${local.enabled_cidrs}" ]
		description = "ssh"
	}

	ingress {
		protocol    = "tcp"
	  from_port   = 80
		to_port     = 80
		cidr_blocks = [ "${local.enabled_cidrs}" ]
		description	= "dashboard"
	}

	ingress {
	  protocol		= 4
	  from_port		= 0
		to_port			= 0
		cidr_blocks	= [ "${local.enabled_cidrs}" ]
		description	= "ipip"
	}

	ingress {
		protocol		= 94
	  from_port		= 0
		to_port			= 0
		cidr_blocks = [ "${local.enabled_cidrs}" ]
		description	= "ipip"
	}

	ingress {
		protocol    = "tcp"
	  from_port   = 443
		to_port     = 443
		cidr_blocks = [ "${local.enabled_cidrs}" ]
		description	= "dashboard-tls"
	}

	ingress {
	  protocol    = "tcp"
		from_port   = 6443
	  to_port     = 6443
		cidr_blocks = [ "${local.enabled_cidrs}" ]
		description = "apiserver"
	}

	ingress {
		protocol		= "tcp"
	  from_port		= 9100
		to_port			= 9100
		cidr_blocks = [ "${local.enabled_cidrs}" ]
		description = "node-exporter"
	}

	# As control plane, restricted to CIDR's for egress
	egress {
	  protocol		= "-1"
	  from_port		= 0
		to_port			= 0
		cidr_blocks = [ "${local.enabled_cidrs}" ]
		description	= "egress-external"
	}
}

resource "aws_security_group" "pools" {
  name					= "${local.name_prefix}-pools"
  description		= "${local.name_prefix} pools external"

  vpc_id				= "${data.aws_vpc.selected.id}"

  tags					= "${map("Name", "${local.name_prefix}-pools")}"

	ingress {
		protocol		= "icmp"
	  from_port		= 0
		to_port			= 0
		cidr_blocks = [ "${local.enabled_cidrs}" ]
		description	= "icmp"
	}

	ingress {
		protocol    = "tcp"
	  from_port   = 22
		to_port     = 22
		cidr_blocks = [ "${local.enabled_cidrs}" ]
		description	= "ssh"
	}

	ingress {
		protocol    = "tcp"
	  from_port   = 80
		to_port     = 80
		cidr_blocks = [ "${local.enabled_cidrs}" ]
		description	= "http"
	}

	ingress {
	  protocol				= 4
	  from_port				= 0
		to_port					= 0
		cidr_blocks = [ "${local.enabled_cidrs}" ]
		description			= "ipip"
	}

	ingress {
		protocol				= 94
	  from_port				= 0
		to_port					= 0
		cidr_blocks = [ "${local.enabled_cidrs}" ]
		description			= "ipip"
	}

	ingress {
		protocol    = "tcp"
	  from_port   = 443
		to_port     = 443
		cidr_blocks = [ "${local.enabled_cidrs}" ]
		description	= "https"
	}

	ingress {
		protocol		= "tcp"
	  from_port		= 9100
		to_port			= 9100
		cidr_blocks = [ "${local.enabled_cidrs}" ]
		description	= "node-exporter"
	}

	egress {
		protocol					= "-1"
	  from_port					= 0
		to_port						= 0
	  cidr_blocks				= ["0.0.0.0/0"]
	  ipv6_cidr_blocks	= ["::/0"]
		description				= "egress-external"
	}
}

