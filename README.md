# Search Guard Helm Chart for Kubernetes

## Status

This is repo is considered experimental and not officially supported. Use at your own risk.

## Requirements

* Kubernetes 1.10 or later 

## Deploying with Helm

Read the comments in values.yaml and customise them to suit your needs.

```
$ git clone https://github.com/floragunncom/search-guard-helm.git
$ helm install search-guard-helm/sg-helm
```

If the Helm tiller service is not already installed in you cluster then execute

```
$ search-guard-helm/init_helm.sh
```

## Run sgadmin

Change the "sg-elasticsearch-searchguard-config" config map and locate the "sgadmin" pod and open a shell.
Then run:

```
kubectl exec -it exiled-moose-sg-elasticsearch-sgadmin-5969d44949-q6dt2 bash
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

ASLv2
