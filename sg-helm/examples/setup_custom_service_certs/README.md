# Setup with custom Elasticsearch and Kibana services 

Go to your search-guard-helm folder with pre-installed dependencies and do:
```
$ helm install -f sg-helm/examples/setup_custom_service_certs/values.yaml sg-elk sg-helm
```
This example shows how to specify your own Elasticsearch and Kibana domain names as `ingressKibanaDomain` and `ingressElasticsearchDomain` and provide custom ca signed certificates for them. 
Please, note, you can substitute default values of `ingressKibanaDomain` and `ingressElasticsearchDomain` and certificates files for these domains with your own items.

 To get access to Kibana:
  * Run minikube tunnel in different window
  * Get Kibana external IP by `kubectl get svc|grep LoadBalancer|awk '{print $4}'` and assign it to `ingressKibanaDomain` in your `etc/hosts` file
  * Access https://`ingressKibanaDomain` with default user `kibanaro` and password extracted by this command `kubectl get secrets sg-elk-sg-helm-passwd-secret -o jsonpath="{.data.SG_KIBANARO_PWD}" | base64 -d`
