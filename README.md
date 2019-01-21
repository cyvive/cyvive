# kubernetes

Enterprise Grade Kubernetes Installer

Cluster Resiliancy is extreemly high as masters auto create and recover

## Minimum Steps to activate Cyvive in AWS

### Initial Design Considerations

Cyvive requires the standard enterprise subnet configuration already established, it **DOES NOT** provision or control any Subnet settings automatically.

Cyvive can be installed exclusively in a private mode, but doing so will prevent any cluster ingress from a public subnet or internet service and Route53 records will be only added to the private zone.

Images for Cyvive are avilable in 3 ways:

1.  Official Publically available AMI's
2.  Private AMI's mounted from the Public AMI's S3 images (your responsible for importing them into your cyvive managed bucket and then into AMI's for your consumption)
3.  Custom AMI's extended from Cyvive's core.

Updates in Cyvive are available in one of two approaches:

- Rolling Upgrades: Every instance type rolling upgrades to the new version one by one. While the safest approch to companies still understanding Cloud Native Architecture its also relatively slow, and due to the way AWS does Rolling Updates has a higher chance of running out of instances in the region.
- Batch per Availability Zone: Executes a total teardown of all instances in the Availability Zone and redeploys on demand based on Kubernetes workload schedulling. If applications are Cloud Native then this is the best approach.

Switching between batch and rolling update modes after the cluster has been deployed requires a total teardown of all pools so its a (Dragons) moment and is strongly suggested to select this up front, choose rolling if unsure about the Cloud Native Architecture in your applications.

### Preparation

**Subnet Settings**:

- Default Subnet is unable to be used for security and resiliancy reasons
- AWS Region must have 3 Availability Zones with Subnets configured in each (Required for ETCD Stability in event of batch AZ update / failure)
- VPC **must** have an Internet Gateway Installed. Airgapped Kubernetes (although possible with Cyvive) should be avoided wherever possible

**Private Subnets**:

- Recommended: minimum /20 CIDR in each Availability Zone. Cyvive is designed to handle hundreds of nodes and thousands of containers, its a good idea to ensure it has the capacity to grow with demand early on.
- _Private_ Subnets tagged with: 'Cyvive = Pools'

**Public Subnets**:

- _Public_ Subnets tagged with: 'Cyvive = Ingress'
- NAT Gateway in each Subnet

**Route53**:

- DNS Zone that the cluster will be installed into i.e. redux.k8s should have a public and private record, unless this cluster will be only privately accessed.

**IAM Role**:

- `permissions/aws.json` contains the current recommended permissions to assign Cyvive

### Process

Cyvive uses _Terraform_ as this is rapidly becomming the industry standard approach to infrastructure and cloud provisioning. An IAM access and secret key will need to be present in the environment variables of the shell running Terraform or _AWS CLI_ used to login and store the access credentials in the home directory for _Terraform_ to discover and use.

Logically Cyvive is split into 3 core components.

- initiate: create the required surrounding cloud infrastructure to support Kubernetes, i.e. Load Balancers, S3 Buckets
- control: Establish and isolate the control plane for stability and upgrades
- pools: Selection of node resources available for consumption and control via Kubernetes

**Initiate**

```
switch to terraform/aws/initiate
edit the sample terraform.tfvars to meet your environment's requirements
terraform init && terraform apply --auto-approve

Process will take ~10 minutes largely due to the speed AWS provisions Load Balancers
```

**Control**

```
identify the created config bucket name:
cat terraform.tfstate | grep -e "bucket\".*cyvive-config"

switch to terraform/aws/control
edit the sample terraform.tfvars using the s3_config_bucket value discovered above
terraform init && terraform apply --auto-approve

Kubernetes control plane will be available and the admin kubectl user published to the s3_config_bucket
```

Note: At this time, Cyvive users have requested that the control plane is **not** available in HA mode as Cyvive users are stress testing different cluster sizes against the stacked ETCD node, as such HA control plane is disabled and will be re-enabled in a future release. Conversion from single to HA **will not** require a cluster re-install as we use autodiscovery and recovery for ETCD services.

**Pools**

```
identify the machine token_id for authorizing nodes to join the cluster
cat terraform.tfstate | grep -e "token_id.:"

switch to terraform/aws/pools
edit the sample terraform.tfvars using the s3_config_bucket & token_id.
terraform init && terraform apply --auto-approve

pools are created, nodes are by default all set to zero until workload is assigned. Change the 'desired' values to reflect the needed nodes of the relevant types
```

Note: Expectation is that Kubernetes will control requests for nodes against the pools as part of the ecosystem. The process for managing the extended ecosystem as immutable or restrictively controlled by Kubernetes is being finalized and will be enabled as soon as this approach is finalized and battle tested.

## Releasing

**Cyvive** uses a slightly modified version of SemVer to manage releases. _Major.Minor.Epoch_ where _Epoch_ aligns with the published images for cloud providers. This format ensures that releases are always sortable and able to be referenced against currently installed architecture. Additionally, due to the nature of **Cyvive** the omission of _Patch_ introduces no additional expectations as **Cyvive's core** only requires _Major_ (breaking changes) & _Minor_ (functionality additions) for cloud provider infrastructure.

### Generating a release

- `microgen ./releases/release.hbs ./releases/$RELEASE_EPOCH.md`
- `npm run changelog` (on develop branch)
- `git checkout master; git merge --ff-only develop`
- `npm run release`
