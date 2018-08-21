# kubernetes

Enterprise Grade Kubernetes Installer

Cluster Resiliancy is extreemly high as masters auto create and recover

Kubernetes v1.12 will futher simplify the installation process, but until then the additional startup node is needed

## Process

1. Create a single master to bootstrap a cluster from (executes a script to power-off when 4 etcd nodes are present)
2. Every other node is a 'pool' type, including running masters
2. Upload relevant certificates and settings to kubernetes where possible, s3 for the rest
3. Enable the control plane ASG and join with the respective nodes registering as additonal masters (workers can also be added at this time)
4. Tear-down and remove initial bootstap node
5.

NestedStacks are perfectly safe when only rolling etcd or kube-api as a block ami, not minute changes

# Subnets
- Don't use the default subnet in the VPC
- Minimum /22 for node CDIR range
- Tag the 'private' subnets with 'Cyvive = Deployable'
- NAT Gateways should be in the public subnets
- 3 AZ's are expected for VPC for ETCD n+1
- NAT gateways should be in the Public Subnets and all Cyvive compute will be in the private subnets
- Public Subnets only contain ALB / NLB / ELB for traffic into the cluster
- Tags
	(Public)
	- Cyvive "Public"
	(Private)
	- Cyvive = "Private"


# BootStrap Notes

- Node creates all the necessary CA certificates, these are watched and synced to the ALB as part of the boot process via Terraform
- Folder level policies are created for the 3 terraform agents to do their work
