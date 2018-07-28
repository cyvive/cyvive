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
data "aws_ami" "most_recent_cyvive" {

  most_recent = true

  owners = ["self"] # Canonical
}

resource "aws_launch_configuration" "sample_lc" {

  image_id = "${data.aws_ami.most_recent_cyvive.id}"
  instance_type = "t2.micro"

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

/*
variable "rolling_update_asg_size" {
	default = "${lookup(data.aws_instances.rolling_update_asg.outputs, "ids", "5")}"
}
*/

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
		AvailabilityZones = "ap-southeast-2a,ap-southeast-2b"
		VPCZoneIdentifier = "subnet-099a536c,subnet-4e29de39"
		MaximumCapacity = "10"
		MinimumCapacity = "2"
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

resource "aws_cloudformation_stack" "rolling_update_asg" {

	name = "asg-rolling-update"
	parameters = "${merge("${var.aws_cloudformation_stack}", "${local.aws_cloudformation_stack["${var.rolling_update_asg == "0" ? "enabled" : "disabled" }"]}")}"
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
        "LaunchConfigurationName": { "Ref": "LaunchConfigurationName" },
        "MaxSize": { "Ref": "MaximumCapacity" },
        "MinSize": { "Ref": "MinimumCapacity" },
        "DesiredCapacity": { "Ref": "MinimumCapacity" },
        "VPCZoneIdentifier": { "Ref": "VPCZoneIdentifier" },
        "TerminationPolicies": [ "OldestLaunchConfiguration", "OldestInstance" ],
        "HealthCheckType": "ELB",
        "MetricsCollection": [
          {
            "Granularity": "1Minute",
            "Metrics": [ ]
          }
        ],
        "HealthCheckGracePeriod": "300",
        "Tags": [ ]
      },
      "UpdatePolicy": {
        "AutoScalingRollingUpdate": {
          "MinInstancesInService": "2",
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
