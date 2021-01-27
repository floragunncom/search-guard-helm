# Setup with custom Elasticsearch cluster nodes certificates

Go to your search-guard-helm folder with pre-installed dependencies and do:
```
helm install -f sg-helm/examples/setup_custom_elasticsearch_certs/values.yaml sg-elk sg-helm
```

Please, note, that you can provide your custom certificates for each Elasticsearch node by adding them to the folder `secrets/nodes` with the predefined node names.
Nodes respective certificate names consist of `<installation-name>-sg-helm-<node-type>-<node-count>.key` and `<installation-name>-sg-helm-<node-type>-<node-count>.pem`.

 To get access to Kibana:
  - Run minikube tunnel in different window
  - Get Kibana external IP by `kubectl get svc|grep LoadBalancer|awk '{print $4}'` and assign it to kibana.example.com in your `etc/hosts` file
  - Access https://kibana.example.com with default user kibanaro and password extracted by this command `kubectl get secrets sg-elk-sg-helm-passwd-secret -o jsonpath="{.data.SG_KIBANARO_PWD}" | base64 -d`

