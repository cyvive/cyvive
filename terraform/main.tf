provider "aws" {
  region = "ap-southeast-2"
}

data "template_file" "policy" {
  template = "${file("files/policy.tpl")}"
  vars {
    bucket = "${aws_s3_bucket.disk_image_bucket.id}"
  }
}

################## S3 ###################

resource "aws_s3_bucket" "disk_image_bucket" {
  bucket = "vmimport.randomness"
}

################## IAM ##################

resource "aws_iam_role" "vmimport" {
  name               = "vmimport"
  assume_role_policy = "${file("files/assume-role-policy.json")}"
}


resource "aws_iam_role_policy" "import_disk_image" {
  name   = "import_disk_image"
  role   = "${aws_iam_role.vmimport.name}"
  policy = "${data.template_file.policy.rendered}"
}

resource "aws_key_pair" "ssh" {
  key_name   = "ssh"
  public_key = "${file("~/.ssh/id_rsa.pub")}"
}

resource "aws_security_group" "linuxkit" {
  name        = "linuxkit"
}

resource "aws_security_group_rule" "ssh" {
  type              = "ingress"
  security_group_id = "${aws_security_group.linuxkit.id}"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

/*
resource "aws_instance" "linuxkit" {
  count = 1
  ami          = "ami-1944e27b"
  instance_type     = "t2.micro"
  key_name          = "${aws_key_pair.ssh.key_name}"
  security_groups             = ["${aws_security_group.linuxkit.name}"]
  associate_public_ip_address = true
}
*/

# AutoScaling / Rollout Approach
data "aws_ami" "most_recent_cyvive_controller" {
  most_recent = true
  owners = ["self"]
	name_regex = "cyvive-controller"
}
/*
data "aws_ami" "most_recent_cyvive_pool" {
  most_recent = true
  owners = ["self"]
	name_regex = "cyvive-pool"
}
*/

resource "aws_launch_configuration" "sample_lc" {
  image_id = "${data.aws_ami.most_recent_cyvive_controller.id}"
  instance_type = "c5.large"
  lifecycle {
    create_before_destroy = true
  }
}

# variable needs to be set initially to ensure that instance search returns truthy
variable "rolling_update_asg" {
	default = "0"
}

variable "aws_instances" {
	type = "list"
	default = [""]
}

/* Due both sides of conditional logic being checked in < v0.12 this must be pushed in externally
data "aws_instances" "rolling_update_asg" {
	count = "${var.rolling_update_asg != "0" ? 1 : 0}"
	instance_tags {
		cyvive = "cyvive"
	}
}
*/

variable "aws_cloudformation_stack" {
	type = "map"
	default = {
		VPCZoneIdentifier = "subnet-099a536c,subnet-4e29de39"
		MaximumCapacity = "2"
		MinimumCapacity = "0"
		UpdatePauseTime = "PT5M"
	}
}

locals {
	aws_cloudformation_stack = {
		enabled = {
			LaunchConfigurationName = "${aws_launch_configuration.sample_lc.name}"
			MinInstancesInService = "${var.aws_cloudformation_stack["MaximumCapacity"] - 1}"
		}
		disabled = {
			LaunchConfigurationName = "${aws_launch_configuration.sample_lc.name}"
			MinInstancesInService = "${length(var.aws_instances) - 1}"
			#MinInstancesInService = "${length(concat(data.aws_instances.*.ids, list(""))) - 1}"
		}
	}
}

variable "reset_placement_groups" {
	default = "0"
}

resource "random_pet" "placement_cluster" {
	count = "${length(data.aws_subnet_ids.selected.ids)}"
	keepers = {
		placement = "${var.reset_placement_groups}"
	}
	prefix = "cyvive-${substr(data.aws_subnet.selected.*.availability_zone[count.index], -2, -1)}"
}

variable "vpc_id" {}

data "aws_vpc" "selected" {
	id = "${var.vpc_id}"
}

data "aws_subnet_ids" "selected" {
	vpc_id						= "${data.aws_vpc.selected.id}"
}

data "aws_subnet" "selected" {
	count = "${length(data.aws_subnet_ids.selected.ids)}"
	id		= "${data.aws_subnet_ids.selected.ids[count.index]}"
}

variable "availability_zones" {
	default = {
		"0" = "a"
		"1" = "b"
		"2" = "c"
	}
}
# Find AZ from Subnet information

resource "aws_placement_group" "cluster" {
	count			= "${length(data.aws_subnet_ids.selected.ids)}"
	name			= "${random_pet.placement_cluster.*.id[count.index]}"
	strategy	= "cluster"
}

resource "aws_cloudformation_stack" "rolling_update_asg" {
	count			= "${length(data.aws_subnet_ids.selected.ids)}"
	name			= "${random_pet.placement_cluster.*.id[count.index]}-asg-rolling-update"
	parameters = "${merge("${var.aws_cloudformation_stack}",
									"${local.aws_cloudformation_stack["${var.rolling_update_asg == "0" ? "enabled" : "disabled" }"]}",
									map("PlacementGroup", "${aws_placement_group.cluster.*.id[count.index]}",
											"AvailabilityZones", "${data.aws_subnet.selected.*.availability_zone[count.index]}",
											"VPCZoneIdentifier", "${data.aws_subnet.selected.*.id[count.index]}"))}"
  template_body = <<STACK
{
  "Description": "ASG cloud formation template",
  "Parameters": {
    "AvailabilityZones": {
      "Type": "CommaDelimitedList",
      "Description": "The availability zones to be used for the app"
    },
    "LaunchConfigurationName": {
      "Type": "String",
      "Description": "The launch configuration name"
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
    }
  },
  "Resources": {
    "ASG": {
      "Type": "AWS::AutoScaling::AutoScalingGroup",
      "Properties": {
        "AvailabilityZones": { "Ref": "AvailabilityZones" },
				"Cooldown": "0",
        "LaunchConfigurationName": { "Ref": "LaunchConfigurationName" },
        "MaxSize": { "Ref": "MaximumCapacity" },
        "MinSize": { "Ref": "MinimumCapacity" },
				"PlacementGroup": { "Ref": "PlacementGroup" },
        "VPCZoneIdentifier": { "Ref": "VPCZoneIdentifier" },
        "TerminationPolicies": [ "OldestLaunchConfiguration", "OldestInstance" ],
        "HealthCheckType": "EC2",
        "HealthCheckGracePeriod": "30",
        "Tags": [ ]
      },
      "UpdatePolicy": {
        "AutoScalingRollingUpdate": {
					"MinInstancesInService": { "Ref": "MinInstancesInService" },
					"WaitOnResourceSignals": "true",
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
}
