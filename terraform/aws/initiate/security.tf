################## SECURITY GROUPS ##################

resource "aws_security_group" "hardwired_controllers" {
  name        = "${local.name_prefix}-hardwired-controllers"
  description = "${local.name_prefix} hardwired controllers security group"

  vpc_id = "${data.aws_vpc.selected.id}"

  tags = "${map("Name", "${local.name_prefix}-hardwired-controllers")}"

	ingress {
	  protocol    = "icmp"
		from_port   = 0
	  to_port     = 0
		cidr_blocks = "${var.authorized_external_cidrs}"
		description	= "controllers-icmp"
	}

	ingress {
	  protocol    = "tcp"
	  from_port   = 22
		to_port     = 22
	  cidr_blocks = "${var.authorized_external_cidrs}"
		description = "controllers-ssh"
	}

	ingress {
	  protocol    = "tcp"
		from_port   = 6443
	  to_port     = 6443
		self				= true
		cidr_blocks = "${var.authorized_external_cidrs}"
		description = "controllers-apiserver"
	}

	ingress {
		protocol		= "tcp"
	  from_port		= 2379
		to_port			= 2379
	  self				= true
		description = "controllers-etcd-clients"
	}

	ingress {
		protocol		= "tcp"
	  from_port		= 2380
		to_port			= 2380
	  self				= true
		description	= "controllers-etcd-peers"
	}

	ingress {
	  protocol		=	"tcp"
	  from_port		= 10256
		to_port			= 10256
		self				= true
		description	= "kubelet-healthcheck"
	}

	egress {
	  protocol					= "-1"
	  from_port					= 0
		to_port						= 0
	  cidr_blocks				= "${var.authorized_external_cidrs}"
		ipv6_cidr_blocks	= ["::/0"]
		description				= "controllers-egress"
	}
}

resource "aws_security_group" "linked_controllers" {
  name        = "${local.name_prefix}-linked-controllers"
  description = "${local.name_prefix} linked controllers security group"

  vpc_id = "${data.aws_vpc.selected.id}"

  tags = "${map("Name", "${local.name_prefix}-linked-controllers")}"

	ingress {
		protocol				= "tcp"
	  from_port				= 2381
	  to_port					= 2381
	  security_groups	= ["${aws_security_group.hardwired_pools.id}"]
		description			= "controllers-etcd-metrics"
	}

	ingress {
		protocol				= "udp"
	  from_port				= 8472
		to_port					= 8472
		self						= true
	  security_groups	= ["${aws_security_group.hardwired_pools.id}"]
		description			= "controllers-flannel"
	}

	ingress {
		protocol				= "tcp"
	  from_port				= 9100
		to_port					= 9100
	  security_groups	= ["${aws_security_group.hardwired_pools.id}"]
		description			= "controllers-node-exporter"
	}

	ingress {
		protocol				= "tcp"
	  from_port				= 10250
		to_port					= 10250
		self						= true
	  security_groups	= ["${aws_security_group.hardwired_pools.id}"]
		description			= "controllers-kubelet"
	}

	ingress {
		protocol				= "tcp"
		from_port				= 10255
		to_port					= 10255
		self						= true
	  security_groups	= ["${aws_security_group.hardwired_pools.id}"]
		description			= "controllers-kubelet-read"
	}

	ingress {
		protocol				= "tcp"
	  from_port				= 179
	  to_port					= 179
		self						= true
	  security_groups	= ["${aws_security_group.hardwired_pools.id}"]
		description			= "controllers-bgp"
	}

	ingress {
	  protocol				= 4
	  from_port				= 0
		to_port					= 0
		self						=	true
	  security_groups	= ["${aws_security_group.hardwired_pools.id}"]
		description			= "controllers-ipip"
	}

	ingress {
		protocol				= 94
	  from_port				= 0
		to_port					= 0
		self						= true
	  security_groups	= ["${aws_security_group.hardwired_pools.id}"]
		description			= "controllers-ipip-legacy"
	}
}

resource "aws_security_group" "hardwired_pools" {
  name        = "${local.name_prefix}-hardwired-pools"
  description = "${local.name_prefix} hardwired pools security group"

  vpc_id = "${data.aws_vpc.selected.id}"

  tags = "${map("Name", "${local.name_prefix}-hardwired-pools")}"

	ingress {
		protocol		= "icmp"
	  from_port		= 0
		to_port			= 0
	  cidr_blocks	= "${var.authorized_external_cidrs}"
		description	= "pools-icmp"
	}

	ingress {
		protocol    = "tcp"
	  from_port   = 22
		to_port     = 22
		cidr_blocks = "${var.authorized_external_cidrs}"
		description	= "pools-ssh"
	}

	ingress {
		protocol    = "tcp"
	  from_port   = 80
		to_port     = 80
	  cidr_blocks = "${var.authorized_external_cidrs}"
		description	= "pools-http"
	}

	ingress {
		protocol    = "tcp"
	  from_port   = 443
		to_port     = 443
	  cidr_blocks = "${var.authorized_external_cidrs}"
		description	= "pools-https"
	}

	ingress {
		protocol		= "tcp"
	  from_port		= 9100
		to_port			= 9100
	  self				= true
		description	= "pools-node-exporter"
	}

	ingress {
		protocol    = "tcp"
	  from_port   = 10256
		to_port     = 10256
		cidr_blocks	= ["${concat(data.aws_subnet.ingress.*.cidr_block, data.aws_subnet.pools.*.cidr_block)}"]
		self				= true
		description	= "ingress-health-self"
	}

	egress {
		protocol					= "-1"
	  from_port					= 0
		to_port						= 0
	  cidr_blocks				= "${var.authorized_external_cidrs}"
	  ipv6_cidr_blocks	= ["::/0"]
		description				= "pools-egress"
	}
}

resource "aws_security_group" "linked_pools" {
  name        = "${local.name_prefix}-linked-pools"
  description = "${local.name_prefix} linked pools security group"

  vpc_id = "${data.aws_vpc.selected.id}"

  tags = "${map("Name", "${local.name_prefix}-linked-pools")}"

	ingress {
		protocol				= "udp"
	  from_port				= 8472
		to_port					= 8472
		self						= true
	  security_groups	= ["${aws_security_group.hardwired_controllers.id}"]
		description			= "pools-flannel"
	}

	ingress {
		protocol				= "tcp"
	  from_port				= 10250
		to_port					= 10250
		self						= true
	  security_groups	= ["${aws_security_group.hardwired_controllers.id}"]
		description			= "pools-kubelet"
	}

	ingress {
		protocol				= "tcp"
	  from_port				= 10255
		to_port					= 10255
		self						= true
	  security_groups	= ["${aws_security_group.hardwired_controllers.id}"]
		description			= "pools-kubelet-read"
	}

	ingress {
		protocol				= "tcp"
	  from_port				= 179
		to_port					= 179
		self						= true
	  security_groups	= ["${aws_security_group.hardwired_controllers.id}"]
		description			= "pools-bgp"
	}

	ingress {
		protocol				= 4
	  from_port				= 0
		to_port					= 0
		self						= true
	  security_groups	= ["${aws_security_group.hardwired_controllers.id}"]
		description			= "pools-ipip"
	}

	ingress {
		protocol				= 94
	  from_port				= 0
		to_port					= 0
		self						=	true
	  security_groups	= ["${aws_security_group.hardwired_controllers.id}"]
		description			= "pools-ipip-legacy"
	}
}
