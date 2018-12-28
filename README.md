# Search Guard Helm Chart for Kubernetes

## Status

This is repo is considered beta status.

## Support

Please report issues via github issue tracker or get in [contact with us](https://search-guard.com/contacts/)

## Requirements

* Kubernetes 1.10 or later (Minikube and AWS EKS are tested)
* Helm (tested with Helm v2.11.0)
* Optional: Docker, if you like to build and push customized images 

If you use minikube make sure that the VM has enough memory and CPUs assigned.
We recommend at least 8 GB and 4 CPUs. By default we deploy 5 pods (includes also Kibana).

## Deploying with Helm

Read the comments in values.yaml and customize them to suit your needs.

```
$ git clone https://github.com/floragunncom/search-guard-helm.git
$ helm install search-guard-helm/sg-helm
```

If the Helm tiller service is not already installed on your cluster then execute

```
$ search-guard-helm/init_helm.sh
```

## Run sgadmin

* The nodes are automatically configured with the values from the "sg-elasticsearch-searchguard-config" config map.
* But only if not already previously configured
* To update the config change the "sg-elasticsearch-searchguard-config" config map and locate the "sg-elasticsearch-sgadmin" pod and open a shell (for example with kubectl exec).
* Then run:

```
$ kubectl exec -it exiled-moose-sg-elasticsearch-sgadmin-5969d44949-q6dt2 bash
To use sgadmin run: /root/sgadmin/tools/sgadmin.sh <OPTIONS>
On K8s/Helm run: /root/sgadmin/tools/sgadmin.sh -h exiled-moose-sg-elasticsearch-discovery.default.svc -cd /root/sgconfig -icl -key /root/sgcerts/admin_cert_key.pem -cert /root/sgcerts/admin_cert.pem -cacert /root/sgcerts/ca_cert.pem -nhnv
  or run /root/sgadmin_update.sh
  or run /root/sgadmin_generic.sh <OPTIONS>
```

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