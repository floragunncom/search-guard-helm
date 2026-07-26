
# Setup with custom CA certificate

This usage example [configuration](https://git.floragunn.com/search-guard/search-guard-flx-helm-charts/-/blob/main/common/examples/setup_custom_ca/values.yaml) sets up a protected 4-node Elasticsearch cluster by providing a custom CA certificate to the Kubernetes cluster. 

Please note that you are expected to provide your own CA certificate with the `crt.pem` and `key.pem` files in the `secrets/ca` folder.
This CA certificate will be used to generate all Elasticsearch node certificates for transport communication and the certificates for the HTTPS service for Elasticsearch and Kibana.


To install this usage example, go to your `search-guard-helm` folder with pre-installed dependencies and do:
```
$ helm install -f examples/setup_custom_ca/values.yaml sg-elk ./ 
```


 To get access to Kibana:
  * Run minikube tunnel in a different window
  * Get Kibana external IP by `kubectl get svc|grep LoadBalancer|awk '{print $4}'` and assign it to kibana.sg-helm.example.com in your `etc/hosts` file
  * Access https://kibana.sg-helm.example.com with default user `admin` and password extracted by this command `kubectl get secrets sg-elk-search-guard-helm-passwd-secret -o jsonpath="{.data.SG_ADMIN_PWD}" | base64 -d`

To uninstall this usage example, run this command:
```
$ helm uninstall sg-elk  
```