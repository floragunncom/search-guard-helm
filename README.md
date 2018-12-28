# Search Guard Helm Chart for Kubernetes

## Status

This is repo is considered beta status. See also the WARNING below regarding Internet-facing or production deployments.

## Support

Please report issues via GitHub issue tracker or get in [contact with us](https://search-guard.com/contacts/)

## Requirements

* Kubernetes 1.10 or later (Minikube and AWS EKS are tested)
* Helm (tested with Helm v2.11.0)
* Optional: Docker, if you like to build and push customized images 

If you use Minikube make sure that the VM has enough memory and CPUs assigned.
We recommend at least 8 GB and 4 CPUs. By default, we deploy 5 pods (includes also Kibana).

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

If the Helm tiller pod is not already running on your cluster

```
kubectl create serviceaccount --namespace kube-system tiller
kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
helm init --service-account tiller --upgrade
```

### Deploy via repository

```
helm repo add sg-helm https://floragunncom.github.io/search-guard-helm
helm search "search guard"
helm install --name sg-elk sg-helm/sg-helm --version 6.5.4-24.0-17.0-beta1
```
Please refer to the [Helm Documentation](https://github.com/helm/helm/blob/master/docs/helm/helm_install.md) on how to override the chart default
settings. See `sg-helm/values.yaml` for the documented set of settings you can override.

### Deploy via GitHub

Optionally read the comments in `sg-helm/values.yaml` and customize them to suit your needs.

```
$ git clone https://github.com/floragunncom/search-guard-helm.git
$ helm install search-guard-helm/sg-helm
```

## Accessing Kibana

Check `minikube dashboard` and wait until all pods are running and green (can take up to 15 minutes)

```
export POD_NAME=$(kubectl get pods --namespace default -l "component=sg-elk-sg-helm,role=kibana" -o jsonpath="{.items[0].metadata.name}")
echo "Visit https://127.0.0.1:5601 and login with admin/admin to use Kibana"
kubectl port-forward --namespace default $POD_NAME 5601:5601
```

## Modify the configuration

* The nodes are initially automatically initialized and configured
* To change the configuration 
  * Edit `sg-helm/values.yaml` and run `helm upgrade`. The pods will be reconfigured or restarted if necceessary
  * or run `helm upgrade --values` or `helm upgrade --set`. The pods will be reconfigured or restarted if necceessary
* Alternatively you can exec into the sgadmin pod and run low-level sgadmin commands:

  ```
  $ kubectl exec -it exiled-moose-sg-elasticsearch-sgadmin-5969d44949-q6dt2 bash
  To use sgadmin run: /root/sgadmin/tools/sgadmin.sh <OPTIONS>
  On K8s/Helm run: /root/sgadmin/tools/sgadmin.sh -h exiled-moose-sg-elasticsearch-discovery.default.svc -cd /root/sgconfig -icl -key /root/sgcerts/admin_cert_key.pem -cert /root/sgcerts/admin_cert.pem -cacert /root/sgcerts/ca_cert.pem -nhnv
    or run /root/sgadmin_update.sh
    or run /root/sgadmin_generic.sh <OPTIONS>
  ```

  In that case, refer to the documentation of `update_sgconfig_on_change` in `sg-helm/values.yaml` so that your changes will not be overriden accidentally.

## WARNING: Internet-facing or production deployments

If this chart is deployed internet-facing or in a production environment make sure that you remove every file in the `secrets/` folder. Normally the files in this folder are not checked in into source control. You keep them local or in an [other safe store](https://kubernetes.io/docs/concepts/configuration/secret/).

Create you own certificates and keys using the [Offline TLS Tool](https://docs.search-guard.com/latest/offline-tls-tool#tls-tool) and also change
the Kibana cookie and the Kibana server password.

IMPORTANT: Set `allow_democertificates` to `false` in `sg-helm/values.yaml`

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