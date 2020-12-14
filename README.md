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


### Deploy via repository

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

```
export POD_NAME=$(kubectl get pods --namespace default -l "component=sg-elk-sg-helm,role=kibana" -o jsonpath="{.items[0].metadata.name}")
echo "Visit https://127.0.0.1:5601 and login with admin/admin to use Kibana"
kubectl port-forward --namespace default $POD_NAME 5601:5601
```

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
* Alternatively you can exec into the sgadmin pod and run low-level sgadmin commands (experts only):

  WARNING(!): You currently can not update sg_internal_users.yml because of the random passwords. If you do this anyhow you may lock you out of the cluster.

  ```
  $ kubectl exec -it sg-elk-sg-helm-sgadmin-555b5f7df-9sqrm bash
  [root@sg-elk-sg-helm-sgadmin-555b5f7df-9sqrm ~]# /root/sgadmin/tools/sgadmin.sh -h $DISCOVERY_SERVICE -si -icl -key /root/sgcerts/key.pem -cert /root/sgcerts/crt.pem -cacert /root/sgcerts/root-ca.pem
  ```

  In that case, refer to the documentation of `update_sgconfig_on_change` in `sg-helm/values.yaml` so that your changes will not be overridden accidentally.

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