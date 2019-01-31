resource "aws_launch_configuration" "per_instance" {
	count										=	"${var.enable == "true" ? length(var.instance_types) : 0}"

	image_id								= "${var.image_id}"
  instance_type						= "${var.instance_types[count.index]}"
  key_name								= "${var.ssh_key}"
  security_groups					= ["${var.security_groups}"]

	# TODO @Debug only purge prior to release
  associate_public_ip_address = true

	ebs_block_device {
		device_name						= "/dev/sda2"
		volume_size						= "${var.oci_cache_disk_size}"
		volume_type						=	"${var.oci_cache_disk_type}"
		encrypted							= "true"
	}

	iam_instance_profile		= "${var.iam_instance_profile}"
	user_data_base64				= "${var.user_data_base64}"

	lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "per_instance" {
	count											=	"${var.enable == "true" ? length(var.instance_types) : 0}"

	name											= "${var.cluster_name}-${var.pet_placement}-${var.pool_name}-${replace(var.instance_types[count.index], ".", "-")}"
	max_size									= "${var.pool_maximum_size}"
	min_size									= "0"
	launch_configuration			= "${element(aws_launch_configuration.per_instance.*.name, count.index)}"
	placement_group						= "${var.pet_placement}"
	health_check_grace_period = 120
	health_check_type					= "ELB"
	load_balancers						= ["${var.elb_names}"]
	vpc_zone_identifier				= ["${var.subnet_id}"]
	termination_policies			= [ "OldestLaunchConfiguration", "ClosestToNextInstanceHour" ]

	tags = [
		{
			key										= "cyvive"
			value									= "${var.cluster_name}"
			propagate_at_launch		= true
		}
	]
}
