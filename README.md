# Search Guard Helm Chart for Kubernetes

## Status

This is repo is considered beta status and supports Search Guard for Elasticsearch 6 and 7.

For Elasticsearch/Search Guard 5 please refer to: https://github.com/floragunncom/search-guard-helm/tree/5.x

## Support

Please report issues via GitHub issue tracker or get in [contact with us](https://search-guard.com/contacts/)

## Requirements

* Kubernetes 1.16 or later (Minikube and AWS EKS are tested)
* Helm (tested with Helm v.3.2.4)
* kubectl
* Optional: Docker, if you like to build and push customized images 

If you use Minikube make sure that the VM has enough memory and CPUs assigned.
We recommend at least 8 GB and 4 CPUs. By default, we deploy 5 pods (includes also Kibana).

## Deploy on AWS (optional)

You need to have the aws cli installed and configured

```
./tools/sg_aws_kops.sh -c mytestcluster
```

Delete the cluster when you are finished with testing Search Guard

```
./tools/sg_aws_kops.sh -d mytestcluster
```

## Setup Minikube (optional)

If you do not have any running Kubernetes cluster and you just want to try out our helm chart then
go with [Minikube](https://kubernetes.io/docs/setup/minikube/)

If Minikube is not already configured or running:

### Install Minikube

Please refer to https://kubernetes.io/docs/setup/minikube/ and https://github.com/kubernetes/minikube

#### macOS

```
Install https://www.virtualbox.org/wiki/Downloads
brew install kubectl kubernetes-helm
brew cask install minikube
```

#### Linux

```
Install https://www.virtualbox.org/wiki/Downloads or https://www.linux-kvm.org/page/Main_Page

curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 && chmod +x minikube && sudo cp minikube /usr/local/bin/ && rm minikube

curl -Lo kubectl https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl && chmod +x kubectl && sudo cp kubectl /usr/local/bin/ && rm kubectl
```

```
minikube config set memory 8192
minikube config set cpus 4
minikube delete
minikube start
```

If Minikube is already configured/running make sure it has least 8 GB and 4 CPUs assigned:

```
minikube config view
```

If not then execute the steps above (Warning: `minikube delete` will delete your Minikube VM).

## Deploying with Helm


### Deploy via repository (Not available now)

```
helm repo add sg-helm https://floragunncom.github.io/search-guard-helm
helm search "search guard"
helm dependency update sg-helm/sg-helm
helm install sg-elk sg-helm/sg-helm --version sgh-beta4
```
Please refer to the [Helm Documentation](https://github.com/helm/helm/blob/master/docs/helm/helm_install.md) on how to override the chart default
settings. See `sg-helm/values.yaml` for the documented set of settings you can override.

### Deploy via GitLab

Optionally read the comments in `sg-helm/values.yaml` and customize them to suit your needs.

```
$ git clone git@git.floragunn.com:gh/search-guard-helm.git
$ helm dependency update search-guard-helm/sg-helm
$ helm install sg-elk search-guard-helm/sg-helm
```

## Accessing Kibana

Check `minikube dashboard` and wait until all pods are running and green (can take up to 15 minutes)
Run in separate window:
```
minikube tunnel
```
Get Kibana LoadBalancer IP:
```
kubectl get svc|grep LoadBalancer|awk '{print $4}'
```
Create record in local etc/hosts 
```
<LoadBalancer IP>   kibana.example.com
```
Get Kibana user 'kibanaro' password:
```
kubectl get secrets sg-elk-sg-helm-passwd-secret -o jsonpath="{.data.SG_KIBANARO_PWD}" | base64 -d
```
Access https://kibana.example.com with `kibanaro/<kibana user password>`

## Random passwords and certificates
Passwords for the admin users, the Kibana user, the Kibana server and the Kibana cookie are generated randomly on initial deployment.
They are stored in a secret named `passwd-secret`. All TLS certificates including a Root CA are also generated randomly. You can find
the root ca in a secret named `root-ca-secret`, the admin certificate in `admin-cert-secret` and the node certificates in `nodes-cert-secret`.
Whenever a node pod restarts we create a new certificate and remove the old one from `nodes-cert-secret`.


## Modify the configuration

* The nodes are initially automatically initialized and configured
* To change the configuration 
  * Edit `sg-helm/values.yaml` and run `helm upgrade`. The pods will be reconfigured or restarted if necessary
  * or run `helm upgrade --values` or `helm upgrade --set`. The pods will be reconfigured or restarted if necessary

## Examples

Search Guard helm charts provides six usage scenarios:



##Configuration


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
 | client.storageClass | Storage class for client nodes | standard |
 | common.admin_dn | DN of certificate with admin privileges | CN=sgadmin,OU=Ops,O=Example Com\\, Inc.,DC=example,DC=com |
 | common.ca_certificates_enabled | Feature that enables possibility to upload customer CA and use it to sign cluster certificates | false |
 | common.certificates_directory | Directory with customer certificates that are used in ES cluster | secrets |
 | common.cluster_name | cluster.name parameter in elasticsearch.yml | searchguard |
 | common.config.* | Additional configuration that will be added to elasticsearch.yml | null |
 | common.debug_job_mode | Feature to disable removal process of completed jobs | false |
 | common.do_not_fail_on_forbidden | With this mode enabled Search Guard filters all indices from a query a user does not have access to. Thus not security exception is raised. See https://docs.search-guard.com/latest/kibana-plugin-installation#configuring-elasticsearch-enable-do-not-fail-on-forbidden | false |
 | common.docker_registry.email | Email information for Docker account in docker registry | null |
 | common.docker_registry.enabled | Enable docker login procedure to docker registry before downloading docker images | false |
 | common.docker_registry.password | Password of docker registry account | null |
 | common.docker_registry.server | Docker registry address | null |
 | common.docker_registry.username | Login of docker registry account | null |
 | common.elkversion | Version of Elasticsearch and Kibana in ES cluster | 7.9.1 |
 | common.external_ca_certificates_enabled | Feature that enables possibility to upload customer ca signed certificates for each node in the ES cluster | false |
 | common.external_ca_single_certificate_enabled | Feature that enables possibility to upload single customer ca signed certificate for all nodes in the ES cluster | false |
 | common.images.elasticsearch_base_image | Docker image name with Elasticsearch and Search Guard plugin installed | sg-elasticsearch |
 | common.images.kibana_base_image | Docker image name with Kibana and Search Guard plugin installed | sg-kibana |
 | common.images.provider | Docker registry provider of docker images in the ES cluster | floragunncom |
 | common.images.sgadmin_base_image | Docker image name with Elasticsearch, Search Guard plugin and Search Guard TLS tool installed | sg-sgadmin |
 | common.ingressNginx.enabled | Enabling NGINX Ingress that exposes Elasticsearch and Kibana services outside the ES cluster | true |
 | common.ingressNginx.ingressCertificates | Ingress Certificates types: "self-signed" for auto-generated with TLS tool self-signed certificates, "external" for customer ca signed certificates | self-signed |
 | common.ingressNginx.ingressElasticsearchDomain | Elasticsearch service domain that is exposed outside the ES cluster | elasticsearch.example.com |
 | common.ingressNginx.ingressKibanaDomain | Kibana service domain that is exposed outside the ES cluster | kibana.example.com |
 | common.nodes_dn | Certificate DN of the nodes in the ES cluster | CN=*-esnode,OU=Ops,O=Example Com\\, Inc.,DC=example,DC=com |
 | common.plugins | List of additional Elasticsearch plugins to be installed on the nodes of the ES cluster | null |
 | common.pod_disruption_budget_enable | Enable Pod Disruption budget feature for ES and Kibana pods. | false |
 | common.restart_pods_on_config_change | Feature to restart pods automatically when their configuration was changed | true |
 | common.roles | Additional roles configuration in sg_roles.yml | null |
 | common.rolesmapping | Additional roles mapping configuration in sg_roles_mapping.yml | null |
 | common.serviceType | Type of Elasticsearch services exposing in the ES cluster | ClusterIP |
 | common.sg_enterprise_modules_enabled | Enable or disable Search Guard enterprise modules | false |
 | common.sg_users | List of additional users to configure in the ES cluster | null |
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
 | data.storageClass | Storage type for data nodes | standard |
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
 | kibana.storageClass | Storage class for client nodes | standard |
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
 | master.storageClass | Storage class for master nodes | standard |
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
Copyright 2018 floragunn GmbH

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