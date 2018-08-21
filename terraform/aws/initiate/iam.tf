################## IAM ROLES ##################

resource "aws_iam_role" "bootstrap" {
	name								= "${local.name_prefix}-bootstrap"
	assume_role_policy	= "${data.aws_iam_policy_document.bootstrap.json}"
}

resource "aws_iam_role_policy" "bootstrap" {
	name	= "${local.name_prefix}-bootstrap"
	role	= "${aws_iam_role.bootstrap.id}"

	policy	= <<EOF
{
	"Version": "2012-10-17",
	"Statement": [
		{
			"Sid": "VisualEditor0",
			"Effect": "Allow",
			"Action": [
				"iam:GetServerCertificate",
				"iam:UploadServerCertificate",
				"elasticloadbalancing:*"
			],
			"Resource": "*"
		}
	]
}
EOF
}

data "aws_iam_policy_document" "bootstrap" {
	statement {
		actions = ["sts:AssumeRole"]

		principals {
			type				= "Service"
			identifiers	= ["ec2.amazonaws.com"]
		}
	}
}

resource "aws_iam_instance_profile" "bootstrap" {
	name	= "${local.name_prefix}-bootstrap"
	role	= "${aws_iam_role.bootstrap.name}"
}
