# Setup with single certificates for Elasticsearch cluster nodes
 
Go to your search-guard-helm folder with pre-installed dependencies and do:
```
$ helm install -f sg-helm/examples/setup_single_elasticsearch_cert/values.yaml sg-elk sg-helm
```

This example supposes you can provide ca signed node certificate with sg.pem and sg.key in `secrets/nodes` folder and ca signed sgadmin certificates `crt.pem` and `key.pem` in you secrets/sgadmin folder.
If you have different node name in your certificate, please, change the `nodes_dn` and `admin_dn` in your setup_single_elasticsearch_cert/values.yaml respectively.
 

To get access to Kibana:
  * Run minikube tunnel in different window
  * Get Kibana external IP by `kubectl get svc|grep LoadBalancer|awk '{print $4}'` and assign it to kibana.example.com in your etc/hosts file
  * Access https://kibana.example.com with default user kibanaro and password extracted by this command `kubectl get secrets sg-elk-sg-helm-passwd-secret -o jsonpath="{.data.SG_KIBANARO_PWD}" | base64 -d`

