# Initiate Approach

Cluster requires an initial elevated priviledges phase to:

- create additional IAM policies for control plane & workers pools
- establish Load Balancer for HA Control plane
- Generate & Maintain all the cluster certificates while keeping them capable of being auto-rotated by Kubernetes
- Create the initial admin user permissions for KubeCtl

**This is the Infrastrucutre / cloud integration phase**

## Preliminary Requirements

- VPC existing with 3 public and 3 private subnets. /20 for private subnets
- VPC public subnets tagged with: Cyvive	= "Ingress"
- VPC	private subnets tagged with: Cyvive	= "Pools"
- Route53 Private & Public Zones for the dns_zone to install the cluster into

