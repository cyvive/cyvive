<a name="0.3.1547560800"></a>
## [0.3.1547560800](https://github.com/cyvive/cyvive/compare/v0.2.0...v0.3.1547560800) (2019-01-21)


### Features

* **nix:** simpler management of development and production environments ([5c723ca](https://github.com/cyvive/cyvive/commit/5c723ca))
* automatic release generation & publishing ([c1f028f](https://github.com/cyvive/cyvive/commit/c1f028f))
* select specific ami for control plane ([b9ad0d3](https://github.com/cyvive/cyvive/commit/b9ad0d3))
* support Kubernetes 1.12.x ([2f7ebfb](https://github.com/cyvive/cyvive/commit/2f7ebfb))



<a name="0.2.0"></a>
# [0.2.0](https://github.com/cyvive/cyvive/compare/v0.1.0...v0.2.0) (2018-09-19)


### Features

* aligning image discovery with release model ([e2d1260](https://github.com/cyvive/cyvive/commit/e2d1260))



<a name="0.1.0"></a>
# [0.1.0](https://github.com/cyvive/cyvive/compare/f1863e2...v0.1.0) (2018-08-31)


### Bug Fixes

* cluster only naming (no prefix) for S3 Buckets ([5dbebc3](https://github.com/cyvive/cyvive/commit/5dbebc3))
* migrate token to autogenerate for first control ([34098c7](https://github.com/cyvive/cyvive/commit/34098c7))
* public ami scanning ([dd2ce06](https://github.com/cyvive/cyvive/commit/dd2ce06))
* public ami scanning (everywhere) ([c2d0d35](https://github.com/cyvive/cyvive/commit/c2d0d35))
* subnet bound ([37fa789](https://github.com/cyvive/cyvive/commit/37fa789))


### Features

* Ability to specify AMI Image per AZ ([afafa40](https://github.com/cyvive/cyvive/commit/afafa40))
* ALB enablement for control plane API ([d3a6e5f](https://github.com/cyvive/cyvive/commit/d3a6e5f))
* Bootstrap auto navigation of external LB ([fd07465](https://github.com/cyvive/cyvive/commit/fd07465))
* debug mode option including 443 debug route ([402dab1](https://github.com/cyvive/cyvive/commit/402dab1))
* ELB Healthz integrated for CF script ([4b0c361](https://github.com/cyvive/cyvive/commit/4b0c361))
* enforce binding of subnet to az ([4fc2aca](https://github.com/cyvive/cyvive/commit/4fc2aca))
* expand pools to all 3 AZ's ([13bee81](https://github.com/cyvive/cyvive/commit/13bee81))
* extact cloudformation asg to module ([fd05f8e](https://github.com/cyvive/cyvive/commit/fd05f8e))
* initial terraform in aws ([f1863e2](https://github.com/cyvive/cyvive/commit/f1863e2))
* **init:** raw bootstrap node creation ([dc72422](https://github.com/cyvive/cyvive/commit/dc72422))
* major rewrite to allow kubelets to register against master ([567614b](https://github.com/cyvive/cyvive/commit/567614b))
* placement groups for instances for ena networking ([0365d58](https://github.com/cyvive/cyvive/commit/0365d58))
* prototype pools syncing with private etcd ([1bce651](https://github.com/cyvive/cyvive/commit/1bce651))
* refactor for multi-cloud structure (in future) ([39e7989](https://github.com/cyvive/cyvive/commit/39e7989))
* remove the need for a BootStrap Node ([07dbc55](https://github.com/cyvive/cyvive/commit/07dbc55))
* Rolling & Blanket Pools per AZ ([45579f0](https://github.com/cyvive/cyvive/commit/45579f0))
* rolling updates to nodes ([ca292e4](https://github.com/cyvive/cyvive/commit/ca292e4))
* s3sync for unified control plane permissions ([05e61cc](https://github.com/cyvive/cyvive/commit/05e61cc))
* secondary disks for kubernetes bootup ([1a0f296](https://github.com/cyvive/cyvive/commit/1a0f296))



