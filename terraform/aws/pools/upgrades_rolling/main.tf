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

# TODO WaitOnResourceSignals disabled until cfn-signal / ELB integration completed
resource "aws_cloudformation_stack" "per_instance" {
	count			= "${var.enable == "true" ? length(var.instance_types) : 0}"

	name			= "${var.cluster_name}-${var.pet_placement}-${replace(var.pool_name, "_", "-")}-${replace(var.instance_types[count.index], ".", "-")}"
	# on_failure = "DO_NOTHING"
	disable_rollback = "true"
	parameters = "${map(
											"LaunchConfigurationName",	"${element(aws_launch_configuration.per_instance.*.name, count.index)}",
											"LoadBalancerNames",				"${join(",", var.elb_names)}",
											"MaximumCapacity",					"${var.pool_maximum_size}",
											"MinInstancesInService",		"${var.min_alive_instances}",
											"MinimumCapacity",					"0",
											"PlacementGroup",						"${var.pet_placement}",
											"UpdatePauseTime",					"PT5M",
											"VPCZoneIdentifier",				"${var.subnet_id}"
										)}"
	template_body = <<STACK
{
  "Description": "ASG cloud formation template",
  "Parameters": {
    "LaunchConfigurationName": {
      "Type": "String",
      "Description": "The launch configuration name"
    },
		"LoadBalancerNames": {
			"Type": "CommaDelimitedList",
			"Description": "List of ELB's to associate instances against"
		},
    "MaximumCapacity": {
      "Type": "String",
      "Description": "The maximum desired capacity size"
    },
    "MinInstancesInService": {
      "Type": "String",
      "Description": "Minimum Number of Healthly Instances while Rolling Update Occurs"
    },
    "MinimumCapacity": {
      "Type": "String",
      "Description": "The minimum and initial desired capacity size"
    },
    "PlacementGroup": {
      "Type": "String",
      "Description": "Name of PlacementGroup these instances belong to in this AZ"
    },
    "UpdatePauseTime": {
      "Type": "String",
      "Description": "The pause time during rollout for the application"
    },
    "VPCZoneIdentifier": {
      "Type": "List<AWS::EC2::Subnet::Id>",
      "Description": "The VPC subnet IDs"
    }
  },
  "Resources": {
    "ASG": {
      "Type": "AWS::AutoScaling::AutoScalingGroup",
      "Properties": {
				"Cooldown": "0",
				"LoadBalancerNames": { "Ref": "LoadBalancerNames" },
				"PlacementGroup": { "Ref": "PlacementGroup" },
        "HealthCheckGracePeriod": "120",
        "HealthCheckType": "ELB",
        "LaunchConfigurationName": { "Ref": "LaunchConfigurationName" },
        "MaxSize": { "Ref": "MaximumCapacity" },
        "MinSize": { "Ref": "MinimumCapacity" },
        "TerminationPolicies": [ "OldestLaunchConfiguration", "ClosestToNextInstanceHour" ],
        "VPCZoneIdentifier": { "Ref": "VPCZoneIdentifier" },
        "Tags": [ ]
      },
      "UpdatePolicy": {
        "AutoScalingRollingUpdate": {
					"MinInstancesInService": { "Ref": "MinInstancesInService" },
					"WaitOnResourceSignals": "false",
          "MaxBatchSize": "1",
          "PauseTime": { "Ref": "UpdatePauseTime" }
        }
      }
    }
  },
  "Outputs": {
    "AsgName": {
      "Description": "ASG reference ID",
      "Value": { "Ref": "ASG" }
    }
  }
}
STACK
  lifecycle {
    create_before_destroy = true
  }
}

