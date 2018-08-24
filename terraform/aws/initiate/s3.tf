################## S3 AMI's ###################

resource "random_pet" "is_private_amis" {
	count								= "${local.is_private_amis}"
	keepers = {
		bucket						= "${var.cluster_name}"
	}
	prefix							= "cyvive-ami-${local.name_prefix}"
}

data "template_file" "s3_amis_policy" {
	count								= "${local.is_private_amis}"
  template						= "${file("templates/s3_amis_policy.tpl")}"
  vars {
    bucket						= "${aws_s3_bucket.is_private_amis.id}"
  }
}

resource "aws_s3_bucket" "is_private_amis" {
	count								= "${local.is_private_amis}"
	bucket							= "${random_pet.is_private_amis.id}"
}

resource "aws_iam_role" "vmimport" {
	count								= "${local.is_private_amis}"
  name								= "vmimport"
	description					= "Ability to import AMI's from the private S3 AMI Bucket"
  assume_role_policy	= "${file("templates/vmimport-policy.json")}"
}


resource "aws_iam_role_policy" "import_disk_image" {
	count								= "${local.is_private_amis}"
  name								= "import_disk_image"
  role								= "${aws_iam_role.vmimport.name}"
  policy							= "${data.template_file.s3_amis_policy.rendered}"
}

################## S3 CLUSTER CONFIG ###################

resource "random_pet" "cluster_config_bucket" {
	keepers = {
		bucket						= "${var.cluster_name}"
	}
	prefix							= "cyvive-config-${local.name_prefix}"
}

resource "aws_s3_bucket" "cluster_config" {
	bucket							= "${random_pet.cluster_config_bucket.id}"
}

