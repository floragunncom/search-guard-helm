# Setup with custom Elasticsearch cluster nodes certificates

This usage example [configuration](https://git.floragunn.com/gh/search-guard-helm/-/blob/prod_ready_ca/sg-helm/examples/setup_custom_elasticsearch_certs/values.yaml) 
sets up protected 4-nodes Elasticsearch cluster by providing custom certificates for each node in the Elasticsearch cluster and for the Ingress services.

Please, note, that you can provide your custom certificates for each Elasticsearch node by adding them to the folder `secrets/nodes` with the predefined node names.

Nodes respective certificate names consist of `<installation-name>-sg-helm-<node-type>-<node-count>.key` and `<installation-name>-sg-helm-<node-type>-<node-count>.pem`.

The custom certificate for Ingress services are provided by the files `tls.crt` and `tls.key` in `secrets/ingress_certificates/elasticsearch` and `secrets/ingress_certificates/kibana` respectively.

The custom certificates for sgadmin are provided in `crt.pem` and `key.pem` in `secrets/sgadmin` folder.

To install this usage example, go to your `search-guard-helm` folder with pre-installed dependencies and do:
```
helm install -f sg-helm/examples/setup_custom_elasticsearch_certs/values.yaml sg-elk sg-helm
```


 To get access to Kibana:
  - Run minikube tunnel in different window
  - Get Kibana external IP by `kubectl get svc|grep LoadBalancer|awk '{print $4}'` and assign it to kibana.sg-helm.example.com in your `etc/hosts` file
  - Access https://kibana.sg-helm.example.com with default user admin and password extracted by this command `kubectl get secrets sg-elk-sg-helm-passwd-secret -o jsonpath="{.data.SG_ADMIN_PWD}" | base64 -d`

To uninstall this usage example, run this command:
```
$ helm uninstall sg-elk  
```