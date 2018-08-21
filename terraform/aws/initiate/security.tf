################## RANDOM TOKEN GENERATION ##################

resource "random_string" "tokenA" {
	length				= 6
	special				= false
	upper					= false
	keepers	= {
		pool_token	= "${var.pool_token}"
	}
}

resource "random_string" "tokenB" {
	length				= 16
	special				= false
	upper					= false
	keepers = {
		pool_token	= "${var.pool_token}"
	}
}

################## SECURITY GROUPS ##################
/*
resource "aws_security_group" "linuxkit" {
  name    = "linuxkit"
	vpc_id	= "${var.vpc_id}"
}

resource "aws_security_group_rule" "ssh" {
  type              = "ingress"
  security_group_id = "${aws_security_group.linuxkit.id}"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = "${var.authorized_external_cidrs}"
}
*/

# Security Groups (instance firewalls)

# Controller security group

resource "aws_security_group" "controllers" {
  name        = "${local.name_prefix}-controllers"
  description = "${local.name_prefix} controllers security group"

  vpc_id = "${data.aws_vpc.selected.id}"

  tags = "${map("Name", "${local.name_prefix}-controllers")}"
}

resource "aws_security_group_rule" "controllers-icmp" {
  security_group_id = "${aws_security_group.controllers.id}"

  type        = "ingress"
  protocol    = "icmp"
  from_port   = 0
  to_port     = 0
  cidr_blocks = "${var.authorized_external_cidrs}"
}

resource "aws_security_group_rule" "controllers-ssh" {
  security_group_id = "${aws_security_group.controllers.id}"

  type        = "ingress"
  protocol    = "tcp"
  from_port   = 22
  to_port     = 22
  cidr_blocks = "${var.authorized_external_cidrs}"
}

resource "aws_security_group_rule" "controllers-apiserver" {
  security_group_id = "${aws_security_group.controllers.id}"

  type        = "ingress"
  protocol    = "tcp"
  from_port   = 6443
  to_port     = 6443
  cidr_blocks = "${var.authorized_external_cidrs}"
}

resource "aws_security_group_rule" "controllers-etcd-clients" {
  security_group_id = "${aws_security_group.controllers.id}"

  type      = "ingress"
  protocol  = "tcp"
  from_port = 2379
  to_port   = 2379
  self      = true
}

resource "aws_security_group_rule" "controllers-etcd-peers" {
  security_group_id = "${aws_security_group.controllers.id}"

  type      = "ingress"
  protocol  = "tcp"
  from_port = 2380
  to_port   = 2380
  self      = true
}

resource "aws_security_group_rule" "controllers-etcd-metrics" {
  security_group_id = "${aws_security_group.controllers.id}"

  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 2381
  to_port                  = 2381
  source_security_group_id = "${aws_security_group.pools.id}"
}

resource "aws_security_group_rule" "controllers-flannel" {
  security_group_id = "${aws_security_group.controllers.id}"

  type                     = "ingress"
  protocol                 = "udp"
  from_port                = 8472
  to_port                  = 8472
  source_security_group_id = "${aws_security_group.pools.id}"
}

resource "aws_security_group_rule" "controllers-flannel-self" {
  security_group_id = "${aws_security_group.controllers.id}"

  type      = "ingress"
  protocol  = "udp"
  from_port = 8472
  to_port   = 8472
  self      = true
}

resource "aws_security_group_rule" "controllers-node-exporter" {
  security_group_id = "${aws_security_group.controllers.id}"

  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 9100
  to_port                  = 9100
  source_security_group_id = "${aws_security_group.pools.id}"
}

resource "aws_security_group_rule" "controllers-kubelet" {
  security_group_id = "${aws_security_group.controllers.id}"

  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 10250
  to_port                  = 10250
  source_security_group_id = "${aws_security_group.pools.id}"
}

resource "aws_security_group_rule" "controllers-kubelet-self" {
  security_group_id = "${aws_security_group.controllers.id}"

  type      = "ingress"
  protocol  = "tcp"
  from_port = 10250
  to_port   = 10250
  self      = true
}

resource "aws_security_group_rule" "controllers-kubelet-read" {
  security_group_id = "${aws_security_group.controllers.id}"

  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 10255
  to_port                  = 10255
  source_security_group_id = "${aws_security_group.pools.id}"
}

resource "aws_security_group_rule" "controllers-kubelet-read-self" {
  security_group_id = "${aws_security_group.controllers.id}"

  type      = "ingress"
  protocol  = "tcp"
  from_port = 10255
  to_port   = 10255
  self      = true
}

resource "aws_security_group_rule" "controllers-bgp" {
  security_group_id = "${aws_security_group.controllers.id}"

  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 179
  to_port                  = 179
  source_security_group_id = "${aws_security_group.pools.id}"
}

resource "aws_security_group_rule" "controllers-bgp-self" {
  security_group_id = "${aws_security_group.controllers.id}"

  type      = "ingress"
  protocol  = "tcp"
  from_port = 179
  to_port   = 179
  self      = true
}

resource "aws_security_group_rule" "controllers-ipip" {
  security_group_id = "${aws_security_group.controllers.id}"

  type                     = "ingress"
  protocol                 = 4
  from_port                = 0
  to_port                  = 0
  source_security_group_id = "${aws_security_group.pools.id}"
}

resource "aws_security_group_rule" "controllers-ipip-self" {
  security_group_id = "${aws_security_group.controllers.id}"

  type      = "ingress"
  protocol  = 4
  from_port = 0
  to_port   = 0
  self      = true
}

resource "aws_security_group_rule" "controllers-ipip-legacy" {
  security_group_id = "${aws_security_group.controllers.id}"

  type                     = "ingress"
  protocol                 = 94
  from_port                = 0
  to_port                  = 0
  source_security_group_id = "${aws_security_group.pools.id}"
}

resource "aws_security_group_rule" "controllers-ipip-legacy-self" {
  security_group_id = "${aws_security_group.controllers.id}"

  type      = "ingress"
  protocol  = 94
  from_port = 0
  to_port   = 0
  self      = true
}

resource "aws_security_group_rule" "controllers-egress" {
  security_group_id = "${aws_security_group.controllers.id}"

  type             = "egress"
  protocol         = "-1"
  from_port        = 0
  to_port          = 0
  cidr_blocks      = "${var.authorized_external_cidrs}"
  ipv6_cidr_blocks = ["::/0"]
}

# Worker security group

resource "aws_security_group" "pools" {
  name        = "${local.name_prefix}-pools"
  description = "${local.name_prefix} pools security group"

  vpc_id = "${data.aws_vpc.selected.id}"

  tags = "${map("Name", "${local.name_prefix}-pools")}"
}

resource "aws_security_group_rule" "pools-icmp" {
  security_group_id = "${aws_security_group.pools.id}"

  type        = "ingress"
  protocol    = "icmp"
  from_port   = 0
  to_port     = 0
  cidr_blocks = "${var.authorized_external_cidrs}"
}

resource "aws_security_group_rule" "pools-ssh" {
  security_group_id = "${aws_security_group.pools.id}"

  type        = "ingress"
  protocol    = "tcp"
  from_port   = 22
  to_port     = 22
  cidr_blocks = "${var.authorized_external_cidrs}"
}

resource "aws_security_group_rule" "pools-http" {
  security_group_id = "${aws_security_group.pools.id}"

  type        = "ingress"
  protocol    = "tcp"
  from_port   = 80
  to_port     = 80
  cidr_blocks = "${var.authorized_external_cidrs}"
}

resource "aws_security_group_rule" "pools-https" {
  security_group_id = "${aws_security_group.pools.id}"

  type        = "ingress"
  protocol    = "tcp"
  from_port   = 443
  to_port     = 443
  cidr_blocks = "${var.authorized_external_cidrs}"
}

resource "aws_security_group_rule" "pools-flannel" {
  security_group_id = "${aws_security_group.pools.id}"

  type                     = "ingress"
  protocol                 = "udp"
  from_port                = 8472
  to_port                  = 8472
  source_security_group_id = "${aws_security_group.controllers.id}"
}

resource "aws_security_group_rule" "pools-flannel-self" {
  security_group_id = "${aws_security_group.pools.id}"

  type      = "ingress"
  protocol  = "udp"
  from_port = 8472
  to_port   = 8472
  self      = true
}

resource "aws_security_group_rule" "pools-node-exporter" {
  security_group_id = "${aws_security_group.pools.id}"

  type      = "ingress"
  protocol  = "tcp"
  from_port = 9100
  to_port   = 9100
  self      = true
}

resource "aws_security_group_rule" "ingress-health" {
  security_group_id = "${aws_security_group.pools.id}"

  type        = "ingress"
  protocol    = "tcp"
  from_port   = 10254
  to_port     = 10254
  cidr_blocks = "${var.authorized_external_cidrs}"
}

resource "aws_security_group_rule" "pools-kubelet" {
  security_group_id = "${aws_security_group.pools.id}"

  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 10250
  to_port                  = 10250
  source_security_group_id = "${aws_security_group.controllers.id}"
}

resource "aws_security_group_rule" "pools-kubelet-self" {
  security_group_id = "${aws_security_group.pools.id}"

  type      = "ingress"
  protocol  = "tcp"
  from_port = 10250
  to_port   = 10250
  self      = true
}

resource "aws_security_group_rule" "pools-kubelet-read" {
  security_group_id = "${aws_security_group.pools.id}"

  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 10255
  to_port                  = 10255
  source_security_group_id = "${aws_security_group.controllers.id}"
}

resource "aws_security_group_rule" "pools-kubelet-read-self" {
  security_group_id = "${aws_security_group.pools.id}"

  type      = "ingress"
  protocol  = "tcp"
  from_port = 10255
  to_port   = 10255
  self      = true
}

resource "aws_security_group_rule" "pools-bgp" {
  security_group_id = "${aws_security_group.pools.id}"

  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 179
  to_port                  = 179
  source_security_group_id = "${aws_security_group.controllers.id}"
}

resource "aws_security_group_rule" "pools-bgp-self" {
  security_group_id = "${aws_security_group.pools.id}"

  type      = "ingress"
  protocol  = "tcp"
  from_port = 179
  to_port   = 179
  self      = true
}

resource "aws_security_group_rule" "pools-ipip" {
  security_group_id = "${aws_security_group.pools.id}"

  type                     = "ingress"
  protocol                 = 4
  from_port                = 0
  to_port                  = 0
  source_security_group_id = "${aws_security_group.controllers.id}"
}

resource "aws_security_group_rule" "pools-ipip-self" {
  security_group_id = "${aws_security_group.pools.id}"

  type      = "ingress"
  protocol  = 4
  from_port = 0
  to_port   = 0
  self      = true
}

resource "aws_security_group_rule" "pools-ipip-legacy" {
  security_group_id = "${aws_security_group.pools.id}"

  type                     = "ingress"
  protocol                 = 94
  from_port                = 0
  to_port                  = 0
  source_security_group_id = "${aws_security_group.controllers.id}"
}

resource "aws_security_group_rule" "pools-ipip-legacy-self" {
  security_group_id = "${aws_security_group.pools.id}"

  type      = "ingress"
  protocol  = 94
  from_port = 0
  to_port   = 0
  self      = true
}

resource "aws_security_group_rule" "pools-egress" {
  security_group_id = "${aws_security_group.pools.id}"

  type             = "egress"
  protocol         = "-1"
  from_port        = 0
  to_port          = 0
  cidr_blocks      = "${var.authorized_external_cidrs}"
  ipv6_cidr_blocks = ["::/0"]
}
