# Kubernetes Componenets Used in the Installer

Minimum Supported Version: Kubernetes 1.10 due to HA requirements in KubeADM

## Infrastructure Provisioning

[Terraform](https://www.terraform.io/docs/index.html)

## Kubernetes Installation & Management

[KubeADM](https://github.com/kubernetes/kubeadm/blob/master/docs/design/design_v1.10.md)

## CNI Network Layer

[Multus](https://github.com/intel/multus-cni) as a meta-wrapper for multiple eth providers in the containers
[Cilium](https://cilium.io/blog/2018/04/24/cilium-security-for-age-of-microservices/) excellent foundation for K8's networking integrations to build on
[Istio](https://cilium.readthedocs.io/en/latest/gettingstarted/istio/) for pod routing security and meshing
	
### Network Policy

[Cilium](https://cilium.readthedocs.io/en/latest/kubernetes/policy/)

