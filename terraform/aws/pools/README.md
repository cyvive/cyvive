# Control Plane

Logically Segregated from Pools following the best practices of GKE enabling a control plane upgrade / rollback approach & logic independent of the bulk rollout of pools.

## Required BootStrap Terraform Imports

- aws_placement_group.spread
