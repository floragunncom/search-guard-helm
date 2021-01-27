
# Setup with custom CA certificate

Go to your search-guard-helm folder with pre-installed dependencies and do:
```
$ helm install -f sg-helm/examples/setup_custom_ca/values.yaml sg-elk sg-helm
```

Please, note, you provide your own CA certificate with the `crt.pem` and `key.pem` files in `secrets/ca` folder.
This CA certificate will be used to generate all Elasticsearch nodes certificates for transport communication and certificates for HTTPS service for Elasticsearch and Kibana.

 To get access to Kibana:
  * Run minikube tunnel in different window
  * Get Kibana external IP by `kubectl get svc|grep LoadBalancer|awk '{print $4}'` and assign it to kibana.example.com in your `etc/hosts` file
  * Access https://kibana.example.com with default user `kibanaro` and password extracted by this command `kubectl get secrets sg-elk-sg-helm-passwd-secret -o jsonpath="{.data.SG_KIBANARO_PWD}" | base64 -d`
