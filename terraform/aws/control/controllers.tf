################## ETCD DNS ENTRIES ##################

resource "aws_route53_record" "etcda" {
  zone_id										= "${data.aws_route53_zone.private.id}"

	name											= "etcda-${local.cluster_fqdn}"
  type											= "CNAME"
	records	= ["${aws_instance.controller_a.private_dns}"]
	ttl			= 10
}

################## BOOTSTRAP ##################
data "template_file" "kubeadm" {
  template										= "${file("templates/kubeadm.yaml")}"
  vars {
    token_id									= "${local.token_id}"
		cluster_domain						= "${var.cluster_domain_suffix}"
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
		target_group_arn					= "${aws_lb_target_group.controllers_private.arn}"
  }
}
*/

resource "aws_instance" "controller_a" {
	ami													= "${data.aws_ami.most_recent_cyvive_generic.id}"
  instance_type								= "m4.large"
  key_name										= "${local.ssh_key}"
	vpc_security_group_ids			= ["sg-8514c9e0"]
	#vpc_security_group_ids			= ["${aws_security_group.hardwired_controllers.id}", "${aws_security_group.linked_controllers.id}"]
	#subnet_id = "subnet-099a536c"
  associate_public_ip_address = true
	ebs_block_device {
		device_name								= "/dev/sdb"
		volume_size								= "10"
		delete_on_termination			= true
	}
	iam_instance_profile				= "${data.aws_iam_instance_profile.controller.name}"
	tags = {
		Name	= "${local.name_prefix}-control-a"
	}
	user_data_base64 = "${base64encode(jsonencode(local.init_controller))}"
}

# Attach controller instances to apiserver NLB
resource "aws_lb_target_group_attachment" "controller_a_public" {
	count							= "${local.is_public_cluster}"
  target_group_arn	= "${data.aws_lb_target_group.controllers_public.arn}"
  target_id					= "${aws_instance.controller_a.id}"
}

resource "aws_elb_attachment" "controller_a_private" {
	elb				= "${data.aws_elb.control_plane_private.id}"
	instance	= "${aws_instance.controller_a.id}"
}

resource "aws_elb_attachment" "controller_a_healthz" {
	elb				= "${data.aws_elb.healthz.id}"
	instance	= "${aws_instance.controller_a.id}"
}

