#  Setup with custom Elasticsearch and Search Guard configuration

This usage example [configuration](https://git.floragunn.com/gh/search-guard-helm/-/blob/prod_ready_ca/sg-helm/examples/setup_custom_sg_config/values.yaml) 
sets up protected 4-nodes Elasticsearch cluster with custom configuration for Elasticsearch and Search Guard Suite plugin.

The configuration difference from basic setup is that additional `config.http` section in `elasticsearch.yml` and additional user `beatsuser` in Search Guard configuration files is provisioned.

You can add additional custom configuration for Elasticsearch to `custom.config` section 
and for Search Guard configuration to `common.users`, `common.roles`, `common.rolesmapping` sections in [the configuration file](https://git.floragunn.com/gh/search-guard-helm/-/blob/prod_ready_ca/sg-helm/examples/setup_custom_sg_config/values.yaml).

The security in the Elasticsearch cluster is provided by self-signed certificates for transport layer communication and for the Ingress services.


To install this usage example, go to your `search-guard-helm` folder with pre-installed dependencies and do:
```
$ helm install -f sg-helm/examples/setup_custom_sg_config/values.yaml sg-elk sg-helm
```
You can check the password of newly created user by running: 
```
kubectl get secrets sg-elk-sg-helm-passwd-secret -o jsonpath="{.data.SG_BEATSUSER_PWD}" | base64 -d
```

To get access to Kibana:
  * Run minikube tunnel in different window
  * Get Kibana external IP by `kubectl get svc|grep LoadBalancer|awk '{print $4}'` and assign it to kibana.sg-helm.example.com in your `etc/hosts` file
  * Access https://kibana.example.com with default user `admin` and password extracted by this command `kubectl get secrets sg-elk-sg-helm-passwd-secret -o jsonpath="{.data.SG_ADMIN_PWD}" | base64 -d`

To uninstall this usage example, run this command:
```
$ helm uninstall sg-elk  
```