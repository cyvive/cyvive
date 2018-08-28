# Initiate Approach

Cluster requires an initial elevated priviledges phase to:

- create additional IAM policies for control plane & workers pools
- establish Load Balancer for HA Control plane
- Generate & Maintain all the cluster certificates while keeping them capable of being auto-rotated by Kubernetes
- Create the initial admin user permissions for KubeCtl
