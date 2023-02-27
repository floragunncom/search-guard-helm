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

This is repo is considered GA status and supports Search Guard FLX for Elasticsearch 7.

## Support

Please report issues via our [Gitlab issue tracker](https://git.floragunn.com/search-guard/search-guard-flx-helm-charts/-/issues), go to our [forum](https://forum.search-guard.com) or directly get in [contact with us][]

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
helm repo add search-guard https://helm.search-guard.com
helm repo update
helm search "search guard"
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
Optionally read the comments in `values.yaml` and customize them to suit your needs.

```
$ git clone git@git.floragunn.com:search-guard/search-guard-flx.git
$ helm dependency update search-guard-flx
$ helm install sg-elk search-guard-flx
```

Please refer to the [Helm Documentation][] on how to override the chart default
settings. See `values.yaml` for the documented set of settings you can override.

Please note that if you are using any other Kubernetes distribution except Minikube,
check if [Storage type][] "standard" is available in the distribution. 
If not, please, specify available [Storage type][] for `data.storageClass` and `master.storageClass` in [values.yaml][]
or by providing them in helm installation command.

Example usage for AWS EBS:
```
helm install --set data.storageClass=gp2 --set master.storageClass=gp2 sg-elk search-guard-flx
```


### Deploy on AWS (optional)

This option provides possibility to set up Kubernetes cluster on AWS while having the `awscli` installed and configured and install Search Guard Helm charts in the cluster.
This script is provided for demo purposes. Please, consider the required AWS resources and Helm chart configuration in the [./tools/sg_aws_kops.sh][].

Setup the Kubernetes AWS cluster with installed Search Guard Helm charts:
```
./tools/sg_aws_kops.sh -c mytestcluster
```

Delete the cluster when you finished with testing Search Guard

```
./tools/sg_aws_kops.sh -d mytestcluster
```

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

 | Parameter | Description | Default value |
 |------|------|------|
 | client.annotation |  Metadata to attach to client nodes | null |
 | client.antiAffinity | Affinity policy for master nodes: 'hard' for pods scheduling only on the different nodes, 'soft' pods scheduling on the same node possible  | soft |
 | client.heapSize | HeapSize limit for client nodes | 1g |
 | client.labels | Metadata to attach to client nodes | null |
 | client.processors | Elasticsearch processors configuration on client nodes | 1|
 | client.replicas | Stable number of client replica Pods running at any given time  | 1 |
 | client.resources.limits.cpu | CPU limits for client nodes | 500m |
 | client.resources.limits.memory | Memory limits for client nodes | 1500Mi |
 | client.resources.requests.cpu | CPU resources requested on cluster start | 100m |
 | client.resources.requests.memory | Memory resources requested on cluster start | 1500Mi |
 | client.storage | Storage size for client nodes | 2Gi |
 | client.storageClass | Storage class for client nodes if you use non-default storage class | default |
 | common.admin_dn | DN of certificate with admin privileges | CN=sgadmin,OU=Ops,O=Example Com\\, Inc.,DC=example,DC=com |
 | common.ca_certificates_enabled | Feature that enables possibility to upload customer CA and use it to sign cluster certificates | false |
 | common.certificates_directory | Directory with customer certificates that are used in ES cluster | secrets |
 | common.cluster_name | cluster.name parameter in elasticsearch.yml | searchguard |
 | common.config.* | Additional configuration that will be added to elasticsearch.yml | null |
 | common.debug_job_mode | Feature to disable removal process of completed jobs | false |
 | common.do_not_fail_on_forbidden | With this mode enabled Search Guard filters all indices from a query a user does not have access to. Thus not security exception is raised. See https://docs.search-guard.com/latest/kibana-plugin-installation#configuring-elasticsearch-enable-do-not-fail-on-forbidden | false |
 | common.docker_registry.email | Email information for Docker account in docker registry | null |
 | common.docker_registry.enabled | Enable docker login procedure to docker registry before downloading docker images | false |
 | common.docker_registry.imagePullSecret | The existing secret name with all required data to authenticate to docker registry | null |
 | common.docker_registry.password | Password of docker registry account | null |
 | common.docker_registry.server | Docker registry address | null |
 | common.docker_registry.username | Login of docker registry account | null |
 | common.elkversion | Version of Elasticsearch and Kibana in ES cluster | 7.9.1 |
 | common.images.elasticsearch_base_image | Docker image name with Elasticsearch and Search Guard plugin installed | sg-elasticsearch |
 | common.images.kibana_base_image | Docker image name with Kibana and Search Guard plugin installed | sg-kibana |
 | common.images.repository | Docker registry repository for docker images in the ES cluster | docker.io |
 | common.images.provider | Docker registry provider of docker images in the ES cluster | floragunncom |
 | common.images.sgadmin_base_image | Docker image name with Elasticsearch, Search Guard plugin and Search Guard TLS tool installed | sg-sgadmin |
 | common.images.sg_specific | The option to specify if custom docker image source to be used  only for SG images or for third party images as well | true |
 | common.nodes_dn | Certificate DN of the nodes in the ES cluster | CN=*-esnode,OU=Ops,O=Example Com\\, Inc.,DC=example,DC=com |
 | common.pod_disruption_budget_enable | Enable Pod Disruption budget feature for ES and Kibana pods. | false |
 | common.restart_pods_on_config_change | Feature to restart pods automatically when their configuration was changed | true |
 | common.roles | Additional roles configuration in sg_roles.yml | null |
 | common.rolesmapping | Additional roles mapping configuration in sg_roles_mapping.yml | null |
 | common.serviceType | Type of Elasticsearch services exposing in the ES cluster | ClusterIP |
 | common.sg_enterprise_modules_enabled | Enable or disable Search Guard enterprise modules | false |
 | common.sgadmin_certificates_enabled | Feature to use self-signed certificates generated by Search Guard TLS tool in the cluster | true |
 | common.sgkibanaversion | Search Guard Kibana plugin version to use in the cluster | 45.0.0 |
 | common.sgversion |  Search Guard Kibana plugin version to use in the cluster | 45.0.0 |
 | common.update_sgconfig_on_change | Run automatically sgadmin whenever neccessary  | true |
 | common.users | Additional users configuration in sg_internal_users.yml | null |
 | common.xpack_basic | Enable/Disable X-Pack in the ES cluster | false |
 | data.annotations | Metadata to attach to data nodes | null |
 | data.antiAffinity | Affinity policy for master nodes: 'hard' for pods scheduling only on the different nodes, 'soft' pods scheduling on the same node possible | soft |
 | data.heapSize | HeapSize limit for data nodes | 1g |
 | data.labels | Metadata to attach to data nodes | null |
 | data.processors | Elasticsearch processors configuration on data nodes | null |
 | data.replicas |  Stable number of data replica Pods running at any given time  | 1 | 
 | data.resources.limits.cpu | CPU limits for data nodes | 1 |
 | data.resources.limits.memory |  Memory limits for data nodes | 2Gi |
 | data.resources.requests.cpu | CPU resources requested on cluster start for kibana nodes | 1 |
 | data.resources.requests.memory | Memory resources requested on cluster start for kibana nodes | 1500Mi |
 | data.storage | Storage size for data nodes | 4Gi |
 | data.storageClass | Storage type for data nodes if you use non-default storage class | default |
 | kibana.annotations | Metadata to attach to kibana nodes | null |
 | kibana.antiAffinity | Affinity policy for master nodes: 'hard' for pods scheduling only on the different nodes, 'soft' pods scheduling on the same node possible | soft |
 | kibana.heapSize | HeapSize limit for kibana nodes | 1g |
 | kibana.httpPort | Port to be exposed by Kibana service in the cluster | 5601 |
 | kibana.labels | Metadata to attach to kibana nodes | null |
 | kibana.processors | Kibana processors configuration on Kibana nodes | 1 |
 | kibana.replicas | Stable number of kibana replica Pods running at any given time | 1 |
 | kibana.resources.limits.cpu | CPU limits for kibana nodes | 500m |
 | kibana.resources.limits.memory | Memory limits for kibana nodes | 1500Mi |
 | kibana.resources.requests.cpu | CPU resources requested on cluster start for kibana nodes | 100m |
 | kibana.resources.requests.memory | Memory resources requested on cluster start for kibana nodes | 2500Mi |
 | kibana.serviceType | Type of Kibana service exposing in the ES cluster | ClusterIP |
 | kibana.storage | Storage size for client nodes | 2Gi |
 | kibana.storageClass | Storage class for client nodes if you use non-default storage class | default |
 | master.annotations | Metadata to attach to master nodes | null |
 | master.antiAffinity | Affinity policy for master nodes: 'hard' for pods scheduling only on the different nodes, 'soft' pods scheduling on the same node possible | soft |
 | master.heapSize | HeapSize limit for master nodes | 1g |
 | master.labels |  Metadata to attach to master nodes | null |
 | master.processors | Elasticsearch processors configuration for master nodes | null |
 | master.replicas | Stable number of master replica Pods running at any given time | 1 |
 | master.resources.limits.cpu | CPU limits for master nodes | 500m |
 | master.resources.limits.memory | Memory limits for data nodes | 1500Mi |
 | master.resources.requests.cpu | CPU resources requested on cluster start for kibana nodes | 100m |
 | master.resources.requests.memory | Memory resources requested on cluster start for kibana nodes | 2500Mi |
 | master.storage | Storage size for master nodes | 2Gi |
 | master.storageClass | Storage class for master nodes if you use non-default storage class | default |
 | pullPolicy | Kubernetes image pull policy | IfNotPresent |
 | rbac.create | Feature to create Kubernetes entities for Role-based access control in the Kubernetes cluster | true |
 | service.httpPort | Port to be exposed by Elasticsearch service in the cluster | 9200 |
 | service.transportPort | Port to be exposed by Elasticsearch service for transport communication in the cluster | 9300 |



## Credits

* https://github.com/lalamove/helm-elasticsearch
* https://github.com/pires/kubernetes-elasticsearch-cluster
* https://github.com/kubernetes/charts/tree/master/incubator/elasticsearch
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
[docker folder]: https://git.floragunn.com/search-guard/search-guard-flx/-/tree/master/docker
[example with custom configuration]: https://git.floragunn.com/search-guard/search-guard-flx/-/tree/master/examples/setup_custom_sg_config
[example with custom domains]: https://git.floragunn.com/search-guard/search-guard-flx/-/tree/master/examples/setup_custom_service_certs
[Helm Documentation]: https://helm.sh/docs/intro/using_helm/
[Helm installation steps]: https://helm.sh/docs/intro/install/
[kubectl installation guide]: https://kubernetes.io/docs/tasks/tools/install-kubectl/
[Minikube installation steps]: https://minikube.sigs.k8s.io/docs/start/
[setup with custom CA certificate]: https://git.floragunn.com/search-guard/search-guard-flx/-/tree/master/examples/setup_custom_ca
[setup with custom Elasticsearch cluster nodes certificates]: https://git.floragunn.com/search-guard/search-guard-flx/-/tree/master/examples/setup_custom_elasticsearch_certs
[setup with single certificates for Elasticsearch cluster nodes]: https://git.floragunn.com/search-guard/search-guard-flx/-/tree/master/examples/setup_single_elasticsearch_cert
[Storage type]: https://kubernetes.io/docs/concepts/storage/storage-classes/
[values.yaml]: https://git.floragunn.com/search-guard/search-guard-flx/-/blob/master/values.yaml
[./tools/sg_aws_kops.sh]: https://git.floragunn.com/search-guard/search-guard-flx/-/blob/master/tools/sg_aws_kops.sh
