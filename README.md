# Search Guard Helm Charts for Kubernetes

- [Status](#status)
- [Support](#support)
- [Requirements](#requirements)
- [Deploying with Helm](#deploying-with-helm)
    - [Deploy via repository](#deploy-via-repository)
    - [Deploy via GitLab](#deploy-via-gitlab)
- [Examples](#examples)
- [Usage Tips](#usage-tips)
    - [Accessing Kibana and Elasticsearch](#accessing-kibana-and-elasticsearch)
    - [Random passwords and certificates](#random-passwords-and-certificates)
    - [Use a private docker registry](#use-a-private-docker-registry)
    - [Custom configuration for Search Guard, Elasticsearch and Kibana](#custom-configuration-for-search-guard-elasticsearch-and-kibana)
    - [Custom domains for Elasticsearch and Kibana services](#custom-domains-for-elasticsearch-and-kibana-services)
    - [Security configuration](#security-configuration)
- [Modify the configuration](#modify-the-configuration)
- [Configuration parameters](#configuration-parameters)
- [Releasing](#releasing)
- [Credits](#credits)
- [License](#license)
    




## Status

This repo is considered GA status and supports Search Guard FLX for Elasticsearch 7, 8 and 9.

## Support

Please report issues via our [Gitlab issue tracker](https://git.floragunn.com/search-guard/search-guard-flx-helm-charts/-/issues), go to our [forum](https://forum.search-guard.com) or directly get in [contact with us][]

## Changes in version 4.0.0:

Starting from chart version `4.0.0`, the way Docker images are built and the Docker repositories to which the images are published have changed.

`sg-elasticsearch-h4` has been replaced by `search-guard-flx-elasticsearch`

`sg-kibana-h4` has been replaced by `search-guard-flx-kibana`

In these repositories, tags are published in the following format: `sgversion-es-esversion`, e.g. `4.0.0-es-9.1.6`

`sg-sgctl-h4` has been replaced by `search-guard-flx-sgctl`

`sg-kubectl-h4` has been replaced by `search-guard-flx-cluster-config`

For the last repository listed above, a change was introduced that removes the need to build a new image for every Kubernetes patch version. This means that for Kubernetes `1.31`, you no longer need to build images for `1.31.0, 1.31.1, 1.31.2` building only the `1.31` version is enough.

Additionally, the `-flx` suffix has been removed from the docker tags. This should be taken into account when setting `common.sgversion` and `common.sgkibanaversion` in `values.yaml`.

## Change in Versioning Method for Helm Charts

With the release of Search Guard plugin version 2.0.0, the versioning of the Helm charts was updated by adding the suffix `-flx` to the chart version number. This change ensures compatibility between the Helm chart versions and the versions published by the Search Guard plugin.

## Important Notes for Search Guard FLX 2.x or higher release

Search Guard 2.x is not backwards compatible with previous versions. If you want to upgrade from version 1.x.x to 2.x or higher, you need to follow some additional steps described [here](docs/sg-2x-upgrade.md).


## Important Notes for Search Guard FLX 1.5.0 release

Due to technical constraints, multi tenancy is not available in this version of Search Guard. We are working on this issue and will reintroduce multi tenancy in the next release of Search Guard. <br>
If you use the Helm charts for this version, the value:
 ```
 searchguard.multitenancy.enabled: false
 ``` 
will be set in the Kibana configuration file, and the `sg_frontend_multi_tenancy.yml` file will be disabled. More details about this change can be found at https://docs.search-guard.com/latest/changelog-searchguard-flx-1_5_0


## Requirements

* Kubernetes 1.32 or later (Minikube and kops managed AWS Kubernetes cluster are tested).
  The supported range is declared as `kubeVersion` in `Chart.yaml`.
* Helm (v.3.8 or later). Please follow [Helm installation steps][] for your OS.
* kubectl. Please check [kubectl installation guide][]
* Optional: Minikube. Please follow [Minikube installation steps][].

If you use Minikube, make sure that the VM has enough memory and CPUs assigned.
We recommend at least 8 GB and 4 CPUs. By default, we deploy 8 pods (3 master, 2 data, 2 client and 1 Kibana).

To change Minikube resource configuration: 
```
minikube config set memory 8192
minikube config set cpus 4
minikube delete
minikube start
```

If Minikube is already configured and running, make sure it has at least 8 GB and 4 CPUs assigned:

```
minikube config view
```

If not, execute the steps above (Warning: `minikube delete` will delete your Minikube VM).

## Deploying with Helm

By default, you get an Elasticsearch cluster with self-signed certificates for transport and HTTP communication.
The default cluster consists of 3 master nodes, 2 data nodes, 2 client (ingest) nodes and 1 Kibana node.
Elasticsearch and Kibana are exposed as `ClusterIP` services; Ingress is disabled by default and can be
enabled via `common.ingress` in [values.yaml][].
Please be aware that such an Elasticsearch cluster configuration should be used for testing purposes only.

### Deploy via repository

```
helm repo add search-guard https://git.floragunn.com/api/v4/projects/261/packages/helm/stable 
helm repo update
helm search repo "search-guard"
helm install sg-elk search-guard/search-guard-flx
```

Please refer to the [Helm Documentation][] on how to override the chart default
settings. See `values.yaml` for the documented set of settings you can override.

Please note that if you are using a Kubernetes distribution other than Minikube,
check whether the [Storage type][] "standard" is available in that distribution. 
If not, please specify an available [Storage type][] for `data.storageClass` and `master.storageClass` in [values.yaml][]
or pass them on the helm installation command line.

Example usage for AWS EBS:
```
helm install --set data.storageClass=gp2 --set master.storageClass=gp2  sg-elk search-guard/search-guard-flx
```


### Deploy via GitLab

To deploy from the Git repository, clone the project and install the chart from the local directory.
Optionally read the comments in `values.yaml` and customize them to suit your needs. To deploy
Elasticsearch 7, apply `values-flx-7.yaml` on top: it is a complete example of the chart values set
up for an Elasticsearch 7 cluster. 

```
$ git clone https://git.floragunn.com/search-guard/search-guard-flx-helm-charts.git
$ cd search-guard-flx-helm-charts
```

To install Elasticsearch 8 or 9
```
$ helm install sg-elk .
```
To install Elasticsearch 7
```
$ helm install sg-elk . -f values-flx-7.yaml
```

The same overrides as above apply, for example for AWS EBS:
```
helm install --set data.storageClass=gp2 --set master.storageClass=gp2 sg-elk .
```

## Examples

The repository contains various examples of different configurations. They are located in the `examples` directory, in the following subdirectories:
- `common` - configurations that work for ELK 7, 8 and 9
- `elk_7` - configurations that work only for ELK 7
- `elk_8` - configurations that work only for ELK 8 and higher

Each example directory contains a README.md file with a detailed description and a values.yaml file that can be used when installing or upgrading the chart.




## Usage Tips

### Accessing Kibana and Elasticsearch


Check that all pods are running and green.

Get the admin user (`admin`) password:
```
kubectl get secrets sg-elk-search-guard-flx-passwd-secret -o jsonpath="{.data.SG_ADMIN_PWD}" | base64 -d
```

#### Via port-forward

Since the services are of type `ClusterIP` by default, the quickest way to reach the cluster is a port-forward:
```
kubectl port-forward service/sg-elk-search-guard-flx-clients 9200:9200
kubectl port-forward service/sg-elk-search-guard-flx 5601:5601
```
Access Kibana at `https://localhost:5601` with `admin/<admin user password>` and Elasticsearch at
`https://localhost:9200/_searchguard/health`.

#### Via Ingress

Ingress is disabled by default. Enable it by setting `common.ingress.enabled: true` and configuring
`common.ingress.hosts` in [values.yaml][]. Use the `serviceNamePostfix` of a host path to select the
backend service: `clients` for Elasticsearch, an empty string for Kibana.

If you use Minikube, run in a separate window:
```
minikube tunnel
```

Get the Ingress address:
```
kubectl get ing --namespace default sg-elk-search-guard-flx-ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}{.status.loadBalancer.ingress[0].ip}'
```
Create records in your local `/etc/hosts` for the hostnames you configured, for example:
```
<Ingress address IP>   kibana.local
<Ingress address IP>   clients.local
```
Access Kibana at `https://kibana.local` with `admin/<admin user password>` and Elasticsearch at
`https://clients.local/_searchguard/health`.


### Random passwords and certificates

Passwords for the admin user (`admin`), the Kibana user (`kibanaro`), the Kibana server user (`kibanaserver`) and any custom users specified in [values.yaml][] are generated randomly on the initial deployment.
They are stored in a secret named `<installation-name>-search-guard-flx-passwd-secret`. 

To get a user-related password:
`kubectl get secrets sg-elk-search-guard-flx-passwd-secret -o jsonpath="{.data.SG_<USERNAME_UPPERCASE>_PWD}" | base64 -d`


You can find the root CA in a secret named `<installation-name>-search-guard-flx-root-ca-secret`, the admin certificate in `<installation-name>-search-guard-flx-admin-cert-secret` and the node certificates in `<installation-name>-search-guard-flx-nodes-cert-secret`.
Whenever a node pod restarts, we create a new certificate and remove the old one from `<installation-name>-search-guard-flx-nodes-cert-secret`.


### Use a private docker registry

Building your own images is not supported. The chart uses the official Search Guard images published
by floragunn.

If your cluster cannot pull from Docker Hub, mirror the official images into your own registry and
point the chart at it via `common.images.repository` and `common.images.provider` in [values.yaml][].
Use `common.docker_registry` to configure the credentials for a registry that requires
authentication, or reference an existing pull secret via `common.docker_registry.imagePullSecret`.

### Custom configuration for Search Guard, Elasticsearch and Kibana
You can modify the default configuration of Elasticsearch, Kibana and the Search Guard plugin by
making the necessary changes in [values.yaml][].
Please check this [example with custom configuration][] for more details.

### Custom domains for Elasticsearch and Kibana services
No domain names are exposed by default, because Ingress is disabled. To expose the cluster under your
own domain names, set `common.ingress.enabled: true` and configure `common.ingress.hosts` and
`common.ingress.tls` in [values.yaml][].

### Security configuration

We provide different PKI approaches for security configuration in the Elasticsearch cluster,
including self-signed and CA-signed solutions:

 * `common.sgctl_certificates_enabled` (default) - all certificates are generated in the cluster and
   signed by a self-signed root CA.
 * `common.ca_certificates_enabled` - you provide your own CA certificate and key, and the cluster
   uses it to sign the node and admin certificates. Please refer to the
   [setup with custom CA certificate][] for more details.


## Modify the configuration

* The nodes are initially automatically initialized and configured
* To change the configuration of SG

  * Edit `values.yaml` and run `helm upgrade`. The job with the sgctl image will be restarted and the new Search Guard configuration will be applied to the cluster.
  Please be aware that with the parameter `debug_job_mode` disabled, the job will be removed within 5 minutes after completion. 
  
* To change the configuration of Kibana and Elasticsearch:
  * Edit `values.yaml` and run `helm upgrade` or run `helm upgrade --values` or `helm upgrade --set`. The pods will be reconfigured or restarted if necessary. 
  If you want to disable sharding during the Elasticsearch cluster restart, please use `helm upgrade --set common.disable_sharding=true`
  
* To upgrade the version of Elasticsearch, Kibana or the Search Guard plugins:
  * Edit `values.yaml` and run `helm upgrade` or run `helm upgrade --values` or `helm upgrade --set` with the new version of the products. 
  To meet the requirements of the Elasticsearch rolling upgrade procedure, please add these parameters to the upgrade command: `helm upgrade --set common.es_upgrade_order=true --set common.disable_sharding=true`.
  We recommend specifying a custom timeout for the upgrade command `helm upgrade --timeout 1h` to provide enough time for Helm to upgrade all cluster nodes.  

NB! Do not use ``common.es_upgrade_order=true`` when your master.replicas=1, because in this case the master node and non-master node dependency conditions block each other
and the upgrade fails.

## Configuration parameters

The table lists the most commonly used parameters. [values.yaml][] is the authoritative and fully
commented reference. The defaults below are the ones from [values.yaml][]; [values-flx-7.yaml][] is a
complete example of the same values set up for an Elasticsearch 7 deployment, so its defaults differ.

| Parameter | Description | Default value |
|------|------|------|
| client.annotations | Metadata to attach to client nodes | null |
| client.antiAffinity | Affinity policy for client nodes: 'hard' for pods scheduling only on different nodes, 'soft' pods scheduling on the same node possible | soft |
| client.heapSize | Heap size limit for client nodes | 1g |
| client.labels | Metadata to attach to client nodes | null |
| client.processors | Elasticsearch processors configuration on client nodes. **Elasticsearch 7 only**, ignored on 8 and higher | 1 |
| client.replicas | Stable number of client replica Pods running at any given time | 2 |
| client.resources.limits.cpu | CPU limits for client nodes | 1 |
| client.resources.limits.memory | Memory limits for client nodes | 2000Mi |
| client.resources.requests.cpu | CPU resources requested on cluster start for client nodes | 800m |
| client.resources.requests.memory | Memory resources requested on cluster start for client nodes | 2000Mi |
| client.roles | Elasticsearch node roles for client nodes | transform, remote_cluster_client, ingest |
| client.storage | Storage size for client nodes | 2Gi |
| client.storageClass | Storage class for client nodes if you use a non-default storage class | default |
| common.action_groups | Additional action groups configuration in sg_action_groups.yml | null |
| common.admin_dn | DN of the certificate with admin privileges | CN=admin,OU=Ops,O=Example Com\\, Inc.,DC=example,DC=com |
| common.authc | Authentication configuration in sg_authc.yml | basic/internal_users_db |
| common.authz | Authorization configuration in sg_authz.yml | ignore_unauthorized_indices enabled |
| common.ca_certificates_enabled | Upload your own CA and use it to sign the cluster certificates | false |
| common.certificates_directory | Directory with the customer certificates that are used in the ES cluster | secrets |
| common.cluster_name | cluster.name parameter in elasticsearch.yml | searchguard |
| common.config.* | Additional configuration that will be added to elasticsearch.yml | see values.yaml |
| common.custom_elasticsearch_keystore.enabled | Enable/disable a custom Elasticsearch keystore | false |
| common.custom_elasticsearch_keystore.extraEnvs | Extra environment variables for the Elasticsearch keystore | null |
| common.custom_elasticsearch_keystore.script | Custom script to generate the Elasticsearch keystore | null |
| common.debug_job_mode | Keep completed jobs instead of removing them, for debugging | false |
| common.docker_registry.email | Email information for the Docker account in the docker registry | null |
| common.docker_registry.enabled | Enable docker login to the docker registry before downloading docker images | false |
| common.docker_registry.imagePullSecret | The existing secret name with all required data to authenticate to the docker registry | null |
| common.docker_registry.password | Password of the docker registry account | null |
| common.docker_registry.server | Docker registry address | null |
| common.docker_registry.username | Login of the docker registry account | null |
| common.elkversion | Version of Elasticsearch and Kibana in the ES cluster | 9.4.2 |
| common.frontend_authc | Kibana frontend authentication configuration in sg_frontend_authc.yml | basic |
| common.frontend_multi_tenancy_enabled | Enable Kibana multi tenancy | false |
| common.images.cluster_config_base_image | Docker image name with kubectl installed, used by the helper jobs and init containers | search-guard-flx-cluster-config |
| common.images.elasticsearch_base_image | Docker image name with Elasticsearch and the Search Guard plugin installed | search-guard-flx-elasticsearch |
| common.images.kibana_base_image | Docker image name with Kibana and the Search Guard Kibana plugin installed | search-guard-flx-kibana |
| common.images.provider | Docker registry provider of the docker images in the ES cluster | floragunncom |
| common.images.repository | Docker registry repository for the docker images in the ES cluster | docker.io |
| common.images.sgctl_base_image | Docker image name with the sgctl tool installed | search-guard-flx-sgctl |
| common.ingress.annotations | Annotations to attach to the Ingress resource | nginx.ingress.kubernetes.io/backend-protocol: HTTPS |
| common.ingress.className | Ingress class name | "" |
| common.ingress.enabled | Expose Elasticsearch and Kibana via an Ingress resource | false |
| common.ingress.hosts | Host and path rules for the Ingress resource | null |
| common.ingress.tls | TLS configuration for the Ingress resource | [] |
| common.init_sysctl | Run an init container that sets vm.max_map_count on the node | true |
| common.license | Search Guard license key, or "none" | none |
| common.nodes_dn | Certificate DN of the nodes in the ES cluster | CN=*-esnode,OU=Ops,O=Example Com\\, Inc.,DC=example,DC=com |
| common.pod_disruption_budget_enable | Enable the Pod Disruption Budget feature for ES and Kibana pods | true |
| common.pullPolicy | Kubernetes image pull policy | IfNotPresent |
| common.remove_initial_master_nodes_after_install | Remove cluster.initial_master_nodes from the configuration after a successful install | true |
| common.restart_pods_on_config_change | Restart pods automatically when their configuration was changed | true |
| common.roles | Additional roles configuration in sg_roles.yml | null |
| common.rolesmapping | Additional roles mapping configuration in sg_roles_mapping.yml | null |
| common.serviceType | Type of the Elasticsearch services exposed in the ES cluster | ClusterIP |
| common.sg_dynamic_configuration_from_secret.enabled | Read the Search Guard configuration from a Kubernetes secret. The YML configuration files stored in the secret overwrite the configmap search-guard-flx-sg-dynamic-configuration. | false |
| common.sg_dynamic_configuration_from_secret.secret_name | The suffix used in the name of the secret when sg_dynamic_configuration_from_secret is enabled | sg-dynamic-configuration-secret |
| common.sg_enterprise_modules_enabled | Enable or disable the Search Guard enterprise modules | true |
| common.sgctl_certificates_enabled | Use self-signed certificates generated by the Search Guard TLS tool in the cluster | true |
| common.sgctl_cli | Create a Pod with the sgctl.sh tool installed | false |
| common.sgctl_version | Version of the sgctl tool image | 4.1.2 |
| common.sgkibanaversion | Search Guard Kibana plugin version to use in the cluster | 4.1.2 |
| common.sgversion | Search Guard plugin version to use in the cluster | 4.1.2 |
| common.tenants | Additional tenants configuration in sg_tenants.yml | null |
| common.tls.keysize | Key size of the generated certificates | 2048 |
| common.tls.validity_days | Validity of the generated certificates in days | 365 |
| common.update_sgconfig_on_change | Run sgctl automatically whenever necessary | true |
| common.users | Additional users configuration in sg_internal_users.yml | null |
| common.xpack_basic | Install the free and basic X-Pack features. If false, only the "oss" version of Elasticsearch and Kibana is installed | true |
| data.annotations | Metadata to attach to data nodes | null |
| data.antiAffinity | Affinity policy for data nodes: 'hard' for pods scheduling only on different nodes, 'soft' pods scheduling on the same node possible | soft |
| data.heapSize | Heap size limit for data nodes | 1g |
| data.labels | Metadata to attach to data nodes | null |
| data.processors | Elasticsearch processors configuration on data nodes. **Elasticsearch 7 only**, ignored on 8 and higher | 1 |
| data.replicas | Stable number of data replica Pods running at any given time | 2 |
| data.resources.limits.cpu | CPU limits for data nodes | 1 |
| data.resources.limits.memory | Memory limits for data nodes | 2000Mi |
| data.resources.requests.cpu | CPU resources requested on cluster start for data nodes | 800m |
| data.resources.requests.memory | Memory resources requested on cluster start for data nodes | 2000Mi |
| data.roles | Elasticsearch node roles for data nodes | data, remote_cluster_client |
| data.storage | Storage size for data nodes | 4Gi |
| data.storageClass | Storage class for data nodes if you use a non-default storage class | default |
| datacontent.annotations | Metadata to attach to data_content nodes | null |
| datacontent.antiAffinity | Affinity policy for data_content nodes: 'hard' for pods scheduling only on different nodes, 'soft' pods scheduling on the same node possible | soft |
| datacontent.enabled | Enable dedicated data_content nodes. **Elasticsearch 8 and higher only**; the other `datacontent.*` parameters only take effect when this is true | false |
| datacontent.heapSize | Heap size limit for data_content nodes | 1g |
| datacontent.labels | Metadata to attach to data_content nodes | null |
| datacontent.replicas | Stable number of data_content replica Pods running at any given time | 2 |
| datacontent.resources.limits.cpu | CPU limits for data_content nodes | 1 |
| datacontent.resources.limits.memory | Memory limits for data_content nodes | 2000Mi |
| datacontent.resources.requests.cpu | CPU resources requested on cluster start for data_content nodes | 800m |
| datacontent.resources.requests.memory | Memory resources requested on cluster start for data_content nodes | 2000Mi |
| datacontent.storage | Storage size for data_content nodes | 2Gi |
| datacontent.storageClass | Storage class for data_content nodes if you use a non-default storage class | default |
| kibana.annotations | Metadata to attach to kibana nodes | null |
| kibana.antiAffinity | Affinity policy for kibana nodes: 'hard' for pods scheduling only on different nodes, 'soft' pods scheduling on the same node possible | soft |
| kibana.config | Additional configuration that will be added to kibana.yml | see values.yaml |
| kibana.httpPort | Port to be exposed by the Kibana service in the cluster | 5601 |
| kibana.labels | Metadata to attach to kibana nodes | null |
| kibana.replicas | Stable number of kibana replica Pods running at any given time. Set to 0 to deploy without Kibana | 1 |
| kibana.resources.limits.cpu | CPU limits for kibana nodes | 1 |
| kibana.resources.limits.memory | Memory limits for kibana nodes | 2500Mi |
| kibana.resources.requests.cpu | CPU resources requested on cluster start for kibana nodes | 800m |
| kibana.resources.requests.memory | Memory resources requested on cluster start for kibana nodes | 2500Mi |
| kibana.serviceType | Type of the Kibana service exposed in the ES cluster | ClusterIP |
| kibana.storage | Storage size for kibana nodes | 2Gi |
| kibana.storageClass | Storage class for kibana nodes if you use a non-default storage class | default |
| master.annotations | Metadata to attach to master nodes | null |
| master.antiAffinity | Affinity policy for master nodes: 'hard' for pods scheduling only on different nodes, 'soft' pods scheduling on the same node possible | soft |
| master.heapSize | Heap size limit for master nodes | 1g |
| master.labels | Metadata to attach to master nodes | null |
| master.processors | Elasticsearch processors configuration for master nodes. **Elasticsearch 7 only**, ignored on 8 and higher | 1 |
| master.replicas | Stable number of master replica Pods running at any given time. Must be an odd number | 3 |
| master.resources.limits.cpu | CPU limits for master nodes | 1 |
| master.resources.limits.memory | Memory limits for master nodes | 2000Mi |
| master.resources.requests.cpu | CPU resources requested on cluster start for master nodes | 800m |
| master.resources.requests.memory | Memory resources requested on cluster start for master nodes | 2000Mi |
| master.roles | Elasticsearch node roles for master nodes | master, remote_cluster_client |
| master.storage | Storage size for master nodes | 2Gi |
| master.storageClass | Storage class for master nodes if you use a non-default storage class | default |
| rbac.create | Create the Kubernetes entities for Role-based access control in the Kubernetes cluster | true |
| service.httpPort | Port to be exposed by the Elasticsearch service in the cluster | 9200 |
| service.transportPort | Port to be exposed by the Elasticsearch service for transport communication in the cluster | 9300 |


## Releasing

Releases are cut by **pushing a tag**. The tag is the single source of truth for the
released version: CI extracts the version from it, writes it into `Chart.yaml`,
commits that back to `main` and publishes the chart. You do not bump the version in
`Chart.yaml` by hand.

Pushes to `main` and merge requests never publish. They only run the validation and
test jobs.

### Release a new version

Tag the commit you want to release with `<major>.<minor>.<patch>-flx`:

```
git tag 4.1.3-flx
git push origin 4.1.3-flx
```

The tag pipeline then:

1. renders the chart with its defaults and with every example (`validate_helm`)
2. checks that the tag is well-formed and that the version is not already published
   (`validate_release`)
3. sets `version: 4.1.3` in `Chart.yaml`, packages the chart, pushes it to the Helm
   repository and commits the version change to `main` (`publish_helm`)

If the tag is malformed or the version already exists in the Helm repository, the
pipeline fails before anything is published.

### Test a release without publishing

Append `-test` to the tag to rehearse a release:

```
git tag 4.1.3-flx-test
git push origin 4.1.3-flx-test
```

This runs the same validation, version stamping and packaging as a real release, but:

* nothing is pushed to the Helm repository
* the version change is committed to the `test` branch instead of `main`
* the packaged chart is kept as a job artifact, so you can inspect exactly what would
  have been published

The `test` branch is scratch space: every test run resets it to the tagged commit and
force-pushes, discarding whatever was there. Do not base any work on it.

### Notes

* The tag points at the commit *before* the version bump, because the bump is created
  by the pipeline that the tag triggers.
* The target branches are configurable through the `RELEASE_BRANCH` and `TEST_BRANCH`
  variables of the `publish_helm` job.

## Credits

* https://github.com/lalamove/helm-elasticsearch
* https://github.com/pires/kubernetes-elasticsearch-cluster
* https://github.com/kubernetes/charts/tree/main/incubator/elasticsearch
* https://github.com/clockworksoul/helm-elasticsearch

## License

```
Copyright 2021-2026 floragunn GmbH

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```

[contact with us]: https://search-guard.com/contacts/
[example with custom configuration]: https://git.floragunn.com/search-guard/search-guard-flx-helm-charts/-/tree/main/examples/common/setup_custom_sg_config
[Helm Documentation]: https://helm.sh/docs/intro/using_helm/
[Helm installation steps]: https://helm.sh/docs/intro/install/
[kubectl installation guide]: https://kubernetes.io/docs/tasks/tools/install-kubectl/
[Minikube installation steps]: https://minikube.sigs.k8s.io/docs/start/
[setup with custom CA certificate]: https://git.floragunn.com/search-guard/search-guard-flx-helm-charts/-/tree/main/examples/common/setup_custom_ca
[Storage type]: https://kubernetes.io/docs/concepts/storage/storage-classes/
[values.yaml]: https://git.floragunn.com/search-guard/search-guard-flx-helm-charts/-/blob/main/values.yaml
[values-flx-7.yaml]: https://git.floragunn.com/search-guard/search-guard-flx-helm-charts/-/blob/main/values-flx-7.yaml