variable "cluster_name" {
  type        = "string"
  description = "Unique cluster name (prepended to dns_zone)"
}

variable "cluster_public" {
	type				= "string"
	default			= "true"
	description	= "Cluster Control Plane / API's should be exposed publically"
}

# DNS

variable "dns_zone" {
  type        = "string"
  description = "AWS Route53 DNS Zone the cluster should build into (e.g. aws.example.com)"
}

/*
variable "dns_zone_public_id" {
  type        = "string"
  description = "AWS Route53 Public DNS Zone ID (e.g. Z3PAABBCFAKEC0)"
}

variable "dns_zone_private_id" {
  type        = "string"
  description = "AWS Route53 Private DNS Zone ID (e.g. Z3PAABBCFAKEC0)"
}
*/

variable "cluster_domain_suffix" {
  description = "Queries for domains with the suffix will be answered by coredns. Default is cluster.local (e.g. foo.default.svc.cluster.local) "
  type        = "string"
  default     = "cluster.local"
}

# instances

variable "controller_type" {
  type        = "string"
  default     = "m5d.large"
  description = "EC2 instance type for controllers"
}

# Storage
variable "s3_private_amis_bucket" {
	type				= "string"
	description	= "Name of private S3 bucket for in-house built AMI's be used instead of Cyvive's standard one (not necessary for most installs)"
	default			= ""
}

variable "oci_cache_disk_size" {
  type        = "string"
  default     = "72"
  description = "Size of the EBS volume in GB, defaults to 72 (Minimum for 50 node cluster)"
}

variable "oci_cache_disk_type" {
	type        = "string"
	default     = "io1"
  description = "Type of the EBS volume (e.g. standard, gp2, io1)"
}

variable "oci_cache_disk_iops" {
	type        = "string"
	default     = "3600"
  description = "(Optional) Number of IOPS required"
}

variable "pool_price" {
  type        = "string"
  default     = ""
  description = "Spot price in USD for autoscaling group spot instances. Leave as default empty string for autoscaling group to use on-demand instances. Note, switching in-place from spot to on-demand is not possible: https://github.com/terraform-providers/terraform-provider-aws/issues/4320"
}

# configuration
variable "ssh_enabled" {
	type				= "string"
	default			= "0"
	description	= "SSH Access is disabled by default on all instances as its unecessary due to Cyvive's architecture. Strongly suggested not to enable this functionality"
}

variable "ssh_authorized_key" {
  type        = "string"
	default			=	""
  description = "SSH Key Name for instance access (disabled by default)"
}

/*
variable "asset_dir" {
  description = "Path to a directory where generated assets should be placed (contains secrets)"
  type        = "string"
}

# Networking

variable "host_cidr" {
  description = "CIDR IPv4 range to assign to EC2 nodes"
  type        = "string"
  default     = "10.0.0.0/16"
}

variable "pod_cidr" {
  description = "CIDR IPv4 range to assign Kubernetes pods"
  type        = "string"
  default     = "10.2.0.0/16"
}

variable "service_cidr" {
  description = <<EOD
CIDR IPv4 range to assign Kubernetes services.
The 1st IP will be reserved for kube_apiserver, the 10th IP will be reserved for coredns.
EOD

  type    = "string"
  default = "10.3.0.0/16"
}
*/
variable "vpc_id" {
	description = "Configured VPC ID (e.g. vpc-ce867bab)"
	type				= "string"
}

# Recreate Triggers
variable "ami_image" {
	description = "AMI Image to use, if not specified then latest AMI compatible AMI will be used automatically"
	type				= "string"
	default			= ""
}

# CLI (Advanced)
variable "rename_placement_groups" {
	description = "(Dragons) Value keys a random renaming of placement groups"
	type				= "string"
	default			= "0"
}

variable "min_alive_instances" {
	description = "(Computed) Minimum number of instances that must be kept alive during rolling update"
	default			=	"1"
}

variable "pool_token" {
	description = "Persistent machine token used for nodes in ASG's to auto register with cluster. Must be of the form '[a-z0-9]{6}.[a-z0-9]{16}'"
	default			= ""
	type				= "string"
}

variable "s3_config_bucket" {
	type				= "string"
	description	= "Name of S3 bucket for Cyvive's terraform & control plane storage"
}

variable "debug" {
	description = "(Dragons) enables debug functionality - api.{cluster_name}.{dns_zone}:443"
	type				= "string"
	default			= "false"
}
