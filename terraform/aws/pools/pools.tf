################## ROLLING UPGRADES ##################

# TODO enable ena
module "rolling_a" {
	source	= "upgrades_rolling"

	enable  = "${local.is_upgrade_rolling}"
	# TODO move launch_configuration into the module
	# TODO pass list of instances to use into the module
	elb_names								= [ "${data.aws_elb.healthz.name}" ]
	image_id								= "${data.aws_ami.most_recent_cyvive_generic.id}"
	pet_placement						=	"${aws_placement_group.cluster.0.name}"
	pool_name								= "rolling_a"
	subnet_id								= "${data.aws_subnet.pools.0.id}"
	ssh_key									= "${local.ssh_key}"
  security_groups					= [	"${data.aws_security_group.hardwired_pools.id}",
															"${data.aws_security_group.linked_pools.id}"]
	iam_instance_profile		= "${data.aws_iam_instance_profile.pool.name}"
	user_data_base64				= "${base64encode(jsonencode(local.init_pool))}"

	# TODO tags into CF templates
  #tags										= "${map("Name", "${local.name_prefix}-hardwired-controllers")}"

	# Direct Map from Vars
	cluster_name						= "${var.cluster_name}"
	instance_types					=	"${var.instance_types}"
	pool_maximum_size				= "${var.pool_maximum_size}"
	oci_cache_disk_size			= "${var.oci_cache_disk_size}"
	oci_cache_disk_type			= "${var.oci_cache_disk_type}"

}

################## BATCH UPGRADES ##################

module "batch_a" {
	source	= "upgrades_batch"

	enable  = "${local.is_upgrade_batch}"
	# TODO move launch_configuration into the module
	# TODO pass list of instances to use into the module
	elb_names								= [ "${data.aws_elb.healthz.name}" ]
	image_id								= "${data.aws_ami.most_recent_cyvive_generic.id}"
	pet_placement						=	"${aws_placement_group.cluster.0.name}"
	pool_name								= "rolling_a"
	subnet_id								= "${data.aws_subnet.pools.0.id}"
	ssh_key									= "${local.ssh_key}"
  security_groups					= [	"${data.aws_security_group.hardwired_pools.id}",
															"${data.aws_security_group.linked_pools.id}"]
	iam_instance_profile		= "${data.aws_iam_instance_profile.pool.name}"
	user_data_base64				= "${base64encode(jsonencode(local.init_pool))}"

	# TODO tags into CF templates
  #tags										= "${map("Name", "${local.name_prefix}-hardwired-controllers")}"

	# Direct Map from Vars
	cluster_name						= "${var.cluster_name}"
	instance_types					=	"${var.instance_types}"
	pool_maximum_size				= "${var.pool_maximum_size}"
	oci_cache_disk_size			= "${var.oci_cache_disk_size}"
	oci_cache_disk_type			= "${var.oci_cache_disk_type}"

}
/*
module "batch_a" {
	count		= "${local.is_upgrade_rolling}"
	source	= "upgrades_batch"

	# TODO move launch_configuration into the module
	# TODO pass list of instances to use into the module
	pool_maximum_size				= "${var.pool_maximum_size}"
	vpc_id									= "${data.aws_vpc.selected.id}"
	pet_placement						=	"${aws_placement_group.spread.*.name}"
	subnet_size							= "1"
	#subnet_size							= "${length(data.aws_subnet_ids.pools.ids)}"
	subnet_ids							= "${data.aws_subnet.pools.*.id}"
	subnet_azs							=	"${data.aws_subnet.pools.*.availability_zone}"
	launch_configuration		= "${aws_launch_configuration.cyvive_pool.name}"
	elb_names								= [	"${data.aws_elb.control_plane_private.name}",
															"${data.aws_elb.healthz.name}"]
	pool_name								= "pool"
	instance_type						=	"${var.pool_type}" # Inherited, don't override
	cluster_name						= "${var.cluster_name}"
	lb_target_group_arn			= ["${data.aws_lb_target_group.pools_public.arn}"]
}

resource "aws_instance" "control" {
	ami													= "${data.aws_ami.most_recent_cyvive_generic.id}"
  instance_type								= "m4.large"
  key_name										= "${local.ssh_key}"
	vpc_security_group_ids			= ["sg-8514c9e0"]
	#vpc_security_group_ids			= ["${data.aws_security_group.hardwired_pools.id}", "${data.aws_security_group.linked_pools.id}"]
	#subnet_id = "subnet-099a536c"
  associate_public_ip_address = true
	ebs_block_device {
		device_name								= "/dev/sdb"
		volume_size								= "10"
		delete_on_termination			= true
	}
	iam_instance_profile				= "${data.aws_iam_instance_profile.pool.name}"
	tags = {
		Name	= "${local.name_prefix}-control"
	}
	user_data_base64 = "${base64encode(jsonencode(local.init_pool))}"
}

resource "aws_elb_attachment" "healthz" {
	elb				= "${data.aws_elb.healthz.id}"
	instance	= "${aws_instance.control.id}"
}
*/
