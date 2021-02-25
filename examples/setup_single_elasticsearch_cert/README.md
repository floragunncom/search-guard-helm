# Setup with single certificates for Elasticsearch cluster nodes

This usage example [configuration](https://git.floragunn.com/search-guard/search-guard-helm/-/blob/master/examples/setup_single_elasticsearch_cert/values.yaml) 
sets up protected 4-nodes Elasticsearch cluster by providing single custom certificates for transport layer security and using self-signed certificates for exposed Ingress services.

Please, provide your custom certificates `sg.pem` and `sg.key` by adding them to the folder `secrets/nodes` with the predefined node names.
If you have different node name than `sg` in your certificate, please, change the `nodes_dn` and `admin_dn` in your [configuration file](https://git.floragunn.com/search-guard/search-guard-helm/-/blob/master/examples/setup_single_elasticsearch_cert/values.yaml) respectively.

The custom certificates for sgadmin are provided in `crt.pem` and `key.pem` files in `secrets/sgadmin` folder.

To install this usage example, go to your `search-guard-helm` folder with pre-installed dependencies and do:
```
$ helm install -f examples/setup_single_elasticsearch_cert/values.yaml sg-elk ./
```

To get access to Kibana:
  * Run minikube tunnel in different window
  * Get Kibana external IP by `kubectl get svc|grep LoadBalancer|awk '{print $4}'` and assign it to kibana.sg-helm.example.com in your etc/hosts file
  * Access https://kibana.sg-helm.example.com with default user `admin` and password extracted by this command `kubectl get secrets sg-elk-search-guard-helm-passwd-secret -o jsonpath="{.data.SG_ADMIN_PWD}" | base64 -d`

To uninstall this usage example, run this command:
```
$ helm uninstall sg-elk  
```