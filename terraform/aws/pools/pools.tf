################## ROLLING UPGRADES ##################

# TODO enable ena
module "rolling_a" {
	source	= "upgrades_rolling"

	enable  = "${local.is_upgrade_rolling}"
	# TODO move launch_configuration into the module
	# TODO pass list of instances to use into the module
	elb_names								= [ "${data.aws_elb.healthz.name}" ]
	image_id								= "${local.ami_image_a}"
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
	image_id								= "${local.ami_image_a}"
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
