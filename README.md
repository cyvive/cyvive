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
