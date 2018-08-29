# NOTE WaitOnResourceSignals disabled until cfn-signal / ELB integration completed
resource "aws_cloudformation_stack" "rolling_update_asg" {
	count			= "${var.subnet_size}"
	name			= "${var.pet_placement[count.index]}-${var.pool_name}-${replace(var.instance_type, ".", "-")}"
	# on_failure = "DO_NOTHING"
	disable_rollback = "true"
	parameters = "${map("PlacementGroup",						"${var.pet_placement[count.index]}",
											"VPCZoneIdentifier",				"${var.subnet_ids[count.index]}",
											"UpdatePauseTime",					"PT5M",
											"MinimumCapacity",					"0",
											"MaximumCapacity",					"${var.pool_maximum_size}",
											"LaunchConfigurationName",	"${var.launch_configuration}",
											"LoadBalancerNames",				"${join(",", var.elb_names)}",
											"TargetGroupARNs",					"${join(",", var.lb_target_group_arn)}",
											"MinInstancesInService",		"${var.min_alive_instances}")}"
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
    "VPCZoneIdentifier": {
      "Type": "List<AWS::EC2::Subnet::Id>",
      "Description": "The VPC subnet IDs"
    },
    "MaximumCapacity": {
      "Type": "String",
      "Description": "The maximum desired capacity size"
    },
    "MinimumCapacity": {
      "Type": "String",
      "Description": "The minimum and initial desired capacity size"
    },
    "MinInstancesInService": {
      "Type": "String",
      "Description": "Minimum Number of Healthly Instances while Rolling Update Occurs"
    },
    "PlacementGroup": {
      "Type": "String",
      "Description": "Name of PlacementGroup these instances belong to in this AZ"
    },
    "UpdatePauseTime": {
      "Type": "String",
      "Description": "The pause time during rollout for the application"
    },
		"TargetGroupARNs": {
			"Type": "CommaDelimitedList",
			"Description": "List of TargetGroups to attach Instances to"
		}
  },
  "Resources": {
    "ASG": {
      "Type": "AWS::AutoScaling::AutoScalingGroup",
      "Properties": {
				"Cooldown": "0",
        "LaunchConfigurationName": { "Ref": "LaunchConfigurationName" },
				"LoadBalancerNames": { "Ref": "LoadBalancerNames" },
        "MaxSize": { "Ref": "MaximumCapacity" },
        "MinSize": { "Ref": "MinimumCapacity" },
				"PlacementGroup": { "Ref": "PlacementGroup" },
        "VPCZoneIdentifier": { "Ref": "VPCZoneIdentifier" },
        "TerminationPolicies": [ "OldestLaunchConfiguration", "OldestInstance" ],
        "HealthCheckType": "ELB",
        "HealthCheckGracePeriod": "120",
        "Tags": [ ],
				"TargetGroupARNs": { "Ref": "TargetGroupARNs" }
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

