# Search Guard Helm Charts for Kubernetes

- [Status](#status)
- [Support](#support)
- [Requirements](#requirements)
- [Deploying with Helm](#deploying-with-helm)
    - [Deploy via repository](#deploy-via-repository-not-available-now)
    - [Deploy via GitLab](#deploy-via-gitlab)
    - [Deploy on AWS](#deploy-on-aws-optional)
- [Usage Tips](#usage-tips)
    - [Accessing Kibana and Elasticsearch](#accessing-kibana-and-elasticsearch)
    - [Random passwords and certificates](#random-passwords-and-certificates)
    - [Use custom images](#use-custom-images)
    - [Install plugins](#install-plugins)
    - [Custom configuration for Search Guard, Elasticsearch and Kibana](#custom-configuration-for-search-guard-elasticsearch-and-kibana)
    - [Custom domains for Elasticsearch and Kibana services](#custom-domains-for-elasticsearch-and-kibana-services)
    - [Security configuration](#security-configuration)
- [Modify the configuration](#modify-the-configuration)
- [Configuration parameters](#configuration-parameters)
- [Credits](#credits)
- [License](#license)
    




## Status

This is repo is considered GA status and supports Search Guard FLX for Elasticsearch 7 and Elasticsearch 8.

## Support

Please report issues via our [Gitlab issue tracker](https://git.floragunn.com/search-guard/search-guard-flx-helm-charts/-/issues), go to our [forum](https://forum.search-guard.com) or directly get in [contact with us][]

## Change in Versioning Method for Helm Charts

With the release of Search Guard Plugin version 2.0.0, the versioning for Helm charts has been updated by adding the suffix `-flx` to the version number of the Helm charts. This change ensures compatibility between the Helm chart versions and the versions published by Search Guard Plugin.

## Important Notes for Search Guard FLX 2.x or higher release

Search Guard 2.x is not backwards compatible with previous versions. If you want to upgrade from version 1.x.x to 2.x or higher , you will need to follow some additional steps described [here](docs/sg-2x-upgrade.md)


## Important Notes for Search Guard FLX 1.5.0 release

Due to technical constraints, Multi Tenancy is not available in this version of Search Guard. We are working on this issue and will reintroduce Multi Tenancy in the next release of Search Guard. <br>
In case of using Helm charts for this version, the value:
 ```
 searchguard.multitenancy.enabled: false
 ``` 
will be set in the Kibana configuration file, and the `sg_frontend_multi_tenancy.yml` file will be disabled. More details about this change can be found at https://docs.search-guard.com/latest/changelog-searchguard-flx-1_5_0


## Requirements

* Kubernetes 1.23 or later (Minikube and kops managed AWS Kubernetes cluster  are tested)
* Helm (v.3.8 or later). Please, follow [Helm installation steps][] for your OS.
* kubectl. Please, check [kubectl installation guide][]
* Optional: Minikube. Please, follow [Minikube installation steps][].
* Optional: [Docker][], if you like to build and push customized images

If you use Minikube make sure that the VM has enough memory and CPUs assigned.
We recommend at least 8 GB and 4 CPUs. By default, we deploy 5 pods (includes also Kibana).

To change Minikube resource configuration: 
```
minikube config set memory 8192
minikube config set cpus 4
minikube delete
minikube start
```

If Minikube is already configured/running make sure it has at least 8 GB and 4 CPUs assigned:

```
minikube config view
```

If not then execute the steps above (Warning: `minikube delete` will delete your Minikube VM).

## Deploying with Helm

By default, you get Elasticsearch cluster with self-signed certificates for transport communication and Elasticsearch and Kibana service access via Ingress Nginx.
Default Elasticsearch cluster has 4-nodes Elasticsearch cluster including master, ingest, data and kibana nodes. 
Please, be aware that such Elasticsearch cluster configuration could be used only for testing purposes.

### Deploy via repository

```
helm repo add search-guard https://git.floragunn.com/api/v4/projects/261/packages/helm/stable 
helm repo update
helm search repo "search-guard"
helm install sg-elk search-guard/search-guard-flx
```

Please refer to the [Helm Documentation][] on how to override the chart default
settings. See `values.yaml` for the documented set of settings you can override.

Please note that if you are using any other Kubernetes distribution except Minikube,
check if [Storage type][] "standard" is available in the distribution. 
If not, please, specify available [Storage type][] for `data.storageClass` and `master.storageClass` in [values.yaml][]
or by providing them in helm installation command.

Example usage for AWS EBS:
```
helm install --set data.storageClass=gp2 --set master.storageClass=gp2  sg-elk search-guard/search-guard-flx
```


### Deploy via GitLab

To deploy from Git repository, you should clone the project, update helm dependencies and install it in your cluster.
Optionally read the comments in `values.yaml` (for Elasticsearch 8) or `values-flx-7.yaml` (for Elasticsearch 7) and customize them to suit your needs. 

To install Elasticsearch 8
```
$ git clone git@git.floragunn.com:search-guard/search-guard-flx.git
$ helm dependency update search-guard-flx
$ helm install sg-elk search-guard-flx
```
To install Elasticsearch 7
```
$ git clone git@git.floragunn.com:search-guard/search-guard-flx.git
$ helm dependency update search-guard-flx
$ helm install sg-elk search-guard-flx -f values-flx-7.yaml
```


Please refer to the [Helm Documentation][] on how to override the chart default
settings. See `values.yaml` for the documented set of settings you can override for Elasticsearch 8 or `values-flx-7.yaml` for Elasticsearch 7 .

Please note that if you are using any other Kubernetes distribution except Minikube,
check if [Storage type][] "standard" is available in the distribution. 
If not, please, specify available [Storage type][] for `data.storageClass` and `master.storageClass` in [values.yaml][]
or by providing them in helm installation command.

Example usage for AWS EBS:
```
helm install --set data.storageClass=gp2 --set master.storageClass=gp2 sg-elk search-guard-flx
```

## Examples

The repository contains various examples of different configurations that can be utilized. The configurations are located in the `examples` directory and the following subdirectories:
- `common` - examples of configurations that work for both ELK7 and ELK8
- `elk_7` - examples of configurations that work only for ELK7
- `elk_8` - examples of configurations that work only for ELK8

In each of the subdirectories, there is a README.md file that provides a detailed description of the configurations, and a values.yaml file that can be used during the installation of helm charts or their updates.




## Usage Tips

### Accessing Kibana and Elasticsearch


Check that all pods are running and green.

If you use Minikube, run in separate window:
```
minikube tunnel
```

Get Ingress address:
```
kubectl get ing --namespace default sg-elk-search-guard-flx-ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].hostname}{.status.loadBalancer.ingress[0].ip}'
```
Create records in local etc/hosts 
```
<Ingress address IP>   kibana.sg-helm.example.com
<Ingress address IP>   es.sg-helm.example.com
```
Get Admin user 'admin' password:
```
kubectl get secrets sg-elk-search-guard-flx-passwd-secret -o jsonpath="{.data.SG_ADMIN_PWD}" | base64 -d
```
Access Kibana `https://kibana.sg-helm.example.com` with `admin/<admin user password>`
Access Elasticsearch  `https://es.sg-helm.example.com/_searchguard/health`


### Random passwords and certificates

Passwords for admin user (`admin`), kibana user (`kibanaro`), kibana server (`kibanaserver`) and custom users specified in [values.yaml][] are generated randomly on initial deployment.
They are stored in a secret named `<installation-name>-search-guard-flx-passwd-secret`. 

To get user related password:
`kubectl get secrets sg-elk-search-guard-flx-passwd-secret -o jsonpath="{.data.SG_<USERNAME_UPPERCASE>_PWD}" | base64 -d`


You can find the root ca in a secret named `<installation-name>-search-guard-flx-root-ca-secret`, the SG Admin certificate in `<installation-name>-search-guard-flx-admin-cert-secret` and the node certificates in `<installation-name>-search-guard-flx-nodes-cert-secret`.
Whenever a node pod restarts we create a new certificate and remove the old one from `<installation-name>-search-guard-flx-nodes-cert-secret`.


### Use custom images
We provide our Dockerfiles and build script in [docker folder][]
that we use to create Docker images.
By default, the script can upload OSS version of Elasticsearch with Search Guard plugin installed, 
Kibana with Search Guard Kibana plugin installed and Search Guard Admin image to you Docker hub account:

```./build.sh push <your-dockerhub-account>```

Please, make sure you have exported your `$DOCKER_PASSWORD` in your environment beforehand.

When you are ready with custom Docker images, please refer to `common.images` and `common.docker_registry` in [values.yaml][]
to point to your custom docker images location.

### Install plugins
These need to be baked into the docker image


### Custom configuration for Search Guard, Elasticsearch and Kibana
You can modify default configuration of Elasticsearch, Kibana and Search Guard Suite plugin
by providing necessary changes in [values.yaml][]
Please check this [example with custom configuration][]
for more details.

### Custom domains for Elasticsearch and Kibana services
Default service domain names exposed by the cluster are: `es.sg-helm.example.com` and `kibana.sg-helm.example.com`.
You can change this by providing custom domain names and corresponding certificates.
Please, follow the [example with custom domains][] for more details.

### Security configuration

We provide different PKI approaches for security configuration in Elasticsearch cluster
including self-signed and CA signed solutions. Please, refer to following examples for more details:
 * [setup with custom CA certificate][]
 * [setup with custom Elasticsearch cluster nodes certificates][]
 * [setup with single certificates for Elasticsearch cluster nodes][]


## Modify the configuration

* The nodes are initially automatically initialized and configured
* To change the configuration of SG

  * Edit `values.yaml` and run `helm upgrade`. The job with SG Admin image will be restarted and new Search Guard configuraiton will be applied to the cluster.
  Please, be aware that with disabled parameter `debug_job_mode`, the job will be removed in 5 minutes after completion. 
  
* To change the configuration of Kibana and Elasticsearch:
  pods will be reconfigured or restarted if necessary
  * Edit `values.yaml` and run `helm upgrade` or run `helm upgrade --values` or `helm upgrade --set`. The pods will be reconfigured or restarted if necessary. 
  If you want to disable sharding during Elasticsearch cluster restart, please, use `helm upgrade --set common.disable_sharding=true`
  
* To upgrade the version of Elasticseacrh, Kibana, Search Guard plugins:
  * Edit `values.yaml` and run `helm upgrade` or run `helm upgrade --values` or `helm upgrade --set` with new version of the products. 
  To meet the requirements of Elasticsearch rolling upgrade procedure, please, add these parameters to the upgrade command: `helm upgrade --set common.es_upgrade_order=true --set common.disable_sharding=true`.
  We recommend to specify custom timeout for upgrade command `helm upgrade --timeout 1h` to provide enough time for Helm to upgrade all cluster nodes.  

NB! Do not use ``common.es_upgrade_order=true`` when your master.replicas=1 because in this case master node and non-master node dependency conditions block each over
and upgrade fails.

## Configuration parameters

 | Parameter | Description | Default value | ELK Version
 |------|------|------|------|
 | client.annotation |  Metadata to attach to client nodes | null | >=7 |
 | client.antiAffinity | Affinity policy for master nodes: 'hard' for pods scheduling only on the different nodes, 'soft' pods scheduling on the same node possible  | soft | >=7 |
 | client.heapSize | HeapSize limit for client nodes | 1g | >=7 |
 | client.labels | Metadata to attach to client nodes | null | >=7 |
 | client.processors | Elasticsearch processors configuration on client nodes | 1| >=7 |
 | client.replicas | Stable number of client replica Pods running at any given time  | 1 | >=7 |
 | client.resources.limits.cpu | CPU limits for client nodes | 500m | >=7 |
 | client.resources.limits.memory | Memory limits for client nodes | 1500Mi | >=7 |
 | client.resources.requests.cpu | CPU resources requested on cluster start | 100m | >=7 |
 | client.resources.requests.memory | Memory resources requested on cluster start | 1500Mi | >=7 |
 | client.storage | Storage size for client nodes | 2Gi | >=7 |
 | client.storageClass | Storage class for client nodes if you use non-default storage class | default | >=7 |
 | common.admin_dn | DN of certificate with admin privileges | CN=sgadmin,OU=Ops,O=Example Com\\, Inc.,DC=example,DC=com | >=7 |
 | common.ca_certificates_enabled | Feature that enables possibility to upload customer CA and use it to sign cluster certificates | false | >=7 |
 | common.certificates_directory | Directory with customer certificates that are used in ES cluster | secrets | >=7 |
 | common.cluster_name | cluster.name parameter in elasticsearch.yml | searchguard | >=7 |
 | common.config.* | Additional configuration that will be added to elasticsearch.yml | null | >=7 |
 | common.debug_job_mode | Feature to disable removal process of completed jobs | false | >=7 |
 | common.docker_registry.email | Email information for Docker account in docker registry | null | >=7 |
 | common.docker_registry.enabled | Enable docker login procedure to docker registry before downloading docker images | false | >=7 |
 | common.docker_registry.imagePullSecret | The existing secret name with all required data to authenticate to docker registry | null | >=7 |
 | common.docker_registry.password | Password of docker registry account | null | >=7 |
 | common.docker_registry.server | Docker registry address | null | >=7 |
 | common.docker_registry.username | Login of docker registry account | null | >=7 |
 | common.elkversion | Version of Elasticsearch and Kibana in ES cluster | 7.9.1 | >=7 |
 | common.images.elasticsearch_base_image | Docker image name with Elasticsearch and Search Guard plugin installed | sg-elasticsearch | >=7 |
 | common.images.kibana_base_image | Docker image name with Kibana and Search Guard plugin installed | sg-kibana | >=7 |
 | common.images.repository | Docker registry repository for docker images in the ES cluster | docker.io | >=7 |
 | common.images.provider | Docker registry provider of docker images in the ES cluster | floragunncom | >=7 |
 | common.images.sgadmin_base_image | Docker image name with Elasticsearch, Search Guard plugin and Search Guard TLS tool installed | sg-sgadmin | >=7 |
 | common.images.sg_specific | The option to specify if custom docker image source to be used  only for SG images or for third party images as well | true | >=7 |
 | common.nodes_dn | Certificate DN of the nodes in the ES cluster | CN=*-esnode,OU=Ops,O=Example Com\\, Inc.,DC=example,DC=com |
 | common.pod_disruption_budget_enable | Enable Pod Disruption budget feature for ES and Kibana pods. | false | >=7 |
 | common.restart_pods_on_config_change | Feature to restart pods automatically when their configuration was changed | true | >=7 |
 | common.roles | Additional roles configuration in sg_roles.yml | null | >=7 |
 | common.rolesmapping | Additional roles mapping configuration in sg_roles_mapping.yml | null | >=7 |
 | common.serviceType | Type of Elasticsearch services exposing in the ES cluster | ClusterIP | >=7 |
 | common.sg_dynamic_configuration_from_secret.enabled | Activate the option to read Search Guard configuration from Kubernetes secret. In this case, the YML configuration files stored in the secret overwrite the configmap search-guard-flx-sg-dynamic-configuration. | false | >=7 |
 | common.sg_dynamic_configuration_from_secret.secret_name | The suffix that will be used in the name of the secret in the event of activating the sg_dynamic_configuration_from_secret option. | sg-dynamic-configuration-secre  | >=7 |
 | common.sg_enterprise_modules_enabled | Enable or disable Search Guard enterprise modules | false | >=7 |
 | common.sgadmin_certificates_enabled | Feature to use self-signed certificates generated by Search Guard TLS tool in the cluster | true | >=7 |
 | common.sgctl_cli | Activate Pod with installed sgctl.sh tool | false | >=7 |
 | common.sgkibanaversion | Search Guard Kibana plugin version to use in the cluster | 45.0.0 | >=7 |
 | common.sgversion |  Search Guard Kibana plugin version to use in the cluster | 45.0.0 | >=7 |
 | common.update_sgconfig_on_change | Run automatically sgadmin whenever neccessary  | true | >=7 |
 | common.users | Additional users configuration in sg_internal_users.yml | null | >=7 |
 | common.xpack_basic | Enable/Disable X-Pack in the ES cluster | false | 7 |
 | common.custom_elasticsearch_keystore.enabled | Enable/Disable custom elasticsearch keystore  | false | >=7 |
 | common.custom_elasticsearch_keystore.extraEnvs | Use extra environment variables for elasticsearch keystore   | null | >=7 |
 | common.custom_elasticsearch_keystore.script | Use custom script to generate for elasticsearch keystore   | null | >=7 |
 | data.annotations | Metadata to attach to data nodes | null | >=7 |
 | data.antiAffinity | Affinity policy for master nodes: 'hard' for pods scheduling only on the different nodes, 'soft' pods scheduling on the same node possible | soft | >=7 |
 | data.heapSize | HeapSize limit for data nodes | 1g | >=7 |
 | data.labels | Metadata to attach to data nodes | null |
 | data.processors | Elasticsearch processors configuration on data nodes | null | >=7 |
 | data.replicas |  Stable number of data replica Pods running at any given time  | 1 | >=7 |
 | data.resources.limits.cpu | CPU limits for data nodes | 1 | >=7 |
 | data.resources.limits.memory |  Memory limits for data nodes | 2Gi | >=7 |
 | data.resources.requests.cpu | CPU resources requested on cluster start for kibana nodes | 1 | >=7 |
 | data.resources.requests.memory | Memory resources requested on cluster start for kibana nodes | 1500Mi | >=7 |
 | data.storage | Storage size for data nodes | 4Gi | >=7 |
 | data.storageClass | Storage type for data nodes if you use non-default storage class | default | >=7 |
 | datacontent.annotations | Metadata to attach to data_content nodes | null | >=8 |
 | datacontent.antiAffinity | Affinity policy for data_content nodes: 'hard' for pods scheduling only on the different nodes, 'soft' pods scheduling on the same node possible | soft | >=8 |
 | datacontent.antiAffinity | Affinity policy for datacontent nodes: 'hard' for pods scheduling only on the different nodes, 'soft' pods scheduling on the same node possible | soft | >=8 |
 | datacontent.enabled | Enable data_content node  | false | >=8 |
 | datacontent.labels |  Metadata to attach to data_content nodes | null | >=8 |
 | datacontent.replicas | Stable number of data_content replica Pods running at any given time | 2 | >=8 | 
 | datacontent.resources.limits.cpu | CPU limits for data_content nodes | 500m | >=8 |
 | datacontent.resources.limits.memory | Memory limits for data_content nodes | 1500Mi | >=8 |
 | datacontent.resources.requests.cpu | CPU resources requested on cluster start for data_content nodes | 100m | >=8 |
 | datacontent.resources.requests.memory | Memory resources requested on cluster start for data_content nodes | 2500Mi | >=8 |
 | datacontent.storage | Storage size for data_content nodes | 2Gi | >=8 |
 | datacontent.storageClass | Storage class for data_content nodes if you use non-default storage class | default | >=8 |
 | datacontent.storageClass | Storage type for data_content nodes if you use non-default storage class | default | >=8 | 
 | kibana.annotations | Metadata to attach to kibana nodes | null | >=8 |
 | kibana.antiAffinity | Affinity policy for kibana nodes: 'hard' for pods scheduling only on the different nodes, 'soft' pods scheduling on the same node possible | soft | >=8 |
 | kibana.heapSize | HeapSize limit for kibana nodes | 1g | >=7 |
 | kibana.httpPort | Port to be exposed by Kibana service in the cluster | 5601 | >=7 |
 | kibana.labels | Metadata to attach to kibana nodes | null | >=7 |
 | kibana.processors | Kibana processors configuration on Kibana nodes | 1 | >=7 |
 | kibana.replicas | Stable number of kibana replica Pods running at any given time | 1 | >=7 |
 | kibana.resources.limits.cpu | CPU limits for kibana nodes | 500m | >=7 |
 | kibana.resources.limits.memory | Memory limits for kibana nodes | 1500Mi | >=7 |
 | kibana.resources.requests.cpu | CPU resources requested on cluster start for kibana nodes | 100m | >=7 |
 | kibana.resources.requests.memory | Memory resources requested on cluster start for kibana nodes | 2500Mi | >=7 |
 | kibana.serviceType | Type of Kibana service exposing in the ES cluster | ClusterIP | >=7 |
 | kibana.storage | Storage size for client nodes | 2Gi | >=7 |
 | kibana.storageClass | Storage class for client nodes if you use non-default storage class | default | >=7 |
 | master.annotations | Metadata to attach to master nodes | null | >=7 |
 | master.antiAffinity | Affinity policy for master nodes: 'hard' for pods scheduling only on the different nodes, 'soft' pods scheduling on the same node possible | soft | >=7 |
 | master.heapSize | HeapSize limit for master nodes | 1g | >=7 |
 | master.labels |  Metadata to attach to master nodes | null | >=7 |
 | master.processors | Elasticsearch processors configuration for master nodes | null | >=7 |
 | master.replicas | Stable number of master replica Pods running at any given time | 1 | >=7 |
 | master.resources.limits.cpu | CPU limits for master nodes | 500m | >=7 |
 | master.resources.limits.memory | Memory limits for data nodes | 1500Mi | >=7 |
 | master.resources.requests.cpu | CPU resources requested on cluster start for kibana nodes | 100m | >=7 |
 | master.resources.requests.memory | Memory resources requested on cluster start for kibana nodes | 2500Mi | >=7 |
 | master.storage | Storage size for master nodes | 2Gi | >=7 |
 | master.storageClass | Storage class for master nodes if you use non-default storage class | default | >=7 |
 | pullPolicy | Kubernetes image pull policy | IfNotPresent | >=7 |
 | rbac.create | Feature to create Kubernetes entities for Role-based access control in the Kubernetes cluster | true | >=7 |
 | service.httpPort | Port to be exposed by Elasticsearch service in the cluster | 9200 | >=7 |
 | service.transportPort | Port to be exposed by Elasticsearch service for transport communication in the cluster | 9300 | >=7 |



## Credits

* https://github.com/lalamove/helm-elasticsearch
* https://github.com/pires/kubernetes-elasticsearch-cluster
* https://github.com/kubernetes/charts/tree/main/incubator/elasticsearch
* https://github.com/clockworksoul/helm-elasticsearch

## License

```
Copyright 2021-2023 floragunn GmbH

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
[Docker]: https://docs.docker.com/engine/install/
[docker folder]: https://git.floragunn.com/search-guard/search-guard-flx/-/tree/main/docker
[example with custom configuration]: https://git.floragunn.com/search-guard/search-guard-flx/-/tree/main/examples/common/setup_custom_sg_config
[example with custom domains]: https://git.floragunn.com/search-guard/search-guard-flx/-/tree/main/examples/common/setup_custom_service_certs
[Helm Documentation]: https://helm.sh/docs/intro/using_helm/
[Helm installation steps]: https://helm.sh/docs/intro/install/
[kubectl installation guide]: https://kubernetes.io/docs/tasks/tools/install-kubectl/
[Minikube installation steps]: https://minikube.sigs.k8s.io/docs/start/
[setup with custom CA certificate]: https://git.floragunn.com/search-guard/search-guard-flx/-/tree/main/examples/common/setup_custom_ca
[setup with custom Elasticsearch cluster nodes certificates]: https://git.floragunn.com/search-guard/search-guard-flx/-/tree/main/examples/common/setup_custom_elasticsearch_certs
[setup with single certificates for Elasticsearch cluster nodes]: https://git.floragunn.com/search-guard/search-guard-flx/-/tree/main/examples/common/setup_single_elasticsearch_cert
[Storage type]: https://kubernetes.io/docs/concepts/storage/storage-classes/
[values.yaml]: https://git.floragunn.com/search-guard/search-guard-flx/-/blob/main/values.yaml
[values-flx-7.yaml]: https://git.floragunn.com/search-guard/search-guard-flx/-/blob/main/values-flx-7.yaml