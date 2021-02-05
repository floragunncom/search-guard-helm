# Setup with custom domain names for Elasticsearch and Kibana services 

This usage example [configuration](https://git.floragunn.com/gh/search-guard-helm/-/blob/prod_ready_ca/sg-helm/examples/setup_custom_service_certs/values.yaml) 
sets up protected 4-nodes Elasticsearch cluster by providing custom certificates for Ingress services and generating self-signed certificates for cluster security configuration. 

Please, note, you are expected to provide the files `tls.crt` and `tls.key` in `secrets/ingress_certificates/elasticsearch` and `secrets/ingress_certificates/kibana` respectively.
Also you you can substitute default values of `ingressKibanaDomain` and `ingressElasticsearchDomain` and certificates files for these domains with your custom domains according to provided certificates.

Please, provide your single custom certificates by adding the files  to the folder `secrets/nodes` with the predefined node names.



To install this usage example, go to your `search-guard-helm` folder with pre-installed dependencies and do:
```
$ helm install -f sg-helm/examples/setup_custom_service_certs/values.yaml sg-elk sg-helm
```

 To get access to Kibana:
  * Run minikube tunnel in different window
  * Get Kibana external IP by `kubectl get svc|grep LoadBalancer|awk '{print $4}'` and assign it to `ingressKibanaDomain` in your `etc/hosts` file
  * Access https://`ingressKibanaDomain` with default user `admin` and password extracted by this command `kubectl get secrets sg-elk-sg-helm-passwd-secret -o jsonpath="{.data.SG_ADMIN_PWD}" | base64 -d`

To uninstall this usage example, run this command:
```
$ helm uninstall sg-elk  
```