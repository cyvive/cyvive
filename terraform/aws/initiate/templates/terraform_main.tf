variable "lb_arn" {
  type = "string"
  description = "arn of the ALB created by init"
}

variable "target_group_arn" {
  type = "string"
  description = "arn of the Target Group for Control Plane"
}

resource "aws_iam_server_certificate" "apiserver_https" {
  name = "cyvive-apiserver"
  certificate_body = "$${file("/etc/kubernetes/pki/apiserver.crt")}"
  private_key = "$${file("/etc/kubernetes/pki/apiserver.key")}"
}

resource "aws_lb_listener" "apiserver-https" {
  load_balancer_arn  = "$${var.lb_arn}"
  protocol           = "HTTPS"
  port               = "6443"
    ssl_policy = "ELBSecurityPolicy-2016-08"
    certificate_arn  = "$${aws_iam_server_certificate.apiserver_https.arn}"

  default_action {
    type             = "forward"
    target_group_arn = "$${var.target_group_arn}"
  }
}

provider "aws" {
  region = "ap-southeast-2"
  version = "~> 1.29"
}


