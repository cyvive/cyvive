################## IAM ROLES ##################

resource "aws_iam_role" "controller" {
	name								= "${local.name_prefix}-controller"
	assume_role_policy	= "${data.aws_iam_policy_document.controller_assume_role.json}"
}

resource "aws_iam_role_policy" "controller" {
	name	= "${local.name_prefix}-controller"
	role	= "${aws_iam_role.controller.id}"

	policy	= "${data.aws_iam_policy_document.controller.json}"
}

data "aws_iam_policy_document" "controller_assume_role" {
	statement {
		actions = ["sts:AssumeRole"]

		principals {
			type				= "Service"
			identifiers	= ["ec2.amazonaws.com"]
		}
	}
}

resource "aws_iam_instance_profile" "controller" {
	name	= "${local.name_prefix}-controller"
	role	= "${aws_iam_role.controller.name}"
}

data "aws_iam_policy_document" "controller" {
	statement {
		sid				= "LoadBalancer"
		effect		= "Allow"
		actions		= [
				"iam:GetServerCertificate",
				"iam:UploadServerCertificate",
				"elasticloadbalancing:*"
		]
		resources = ["*"]
	}

	statement {
		sid				= "S3ConfigBucket"
		effect		= "Allow"
		actions		= [
			"s3:ListBucket",
			"s3:ListBucketByTags",
			"s3:GetBucketTagging",
			"s3:PutBucketTagging"
		]
		resources	= ["${aws_s3_bucket.cluster_config.arn}"]
	}

	statement {
		sid				= "S3ConfigObject"
		effect		= "Allow"
		actions		= [
			"s3:PutObject",
			"s3:GetObject",
			"s3:DeleteObject",
			"s3:PutObjectTagging",
			"s3:GetObjectTagging",
			"s3:DeleteObjectTagging"
		]
		resources	= ["${aws_s3_bucket.cluster_config.arn}/*"]
	}
}


