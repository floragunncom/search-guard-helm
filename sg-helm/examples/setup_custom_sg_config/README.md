#  Setup with custom Elasticsearch and Search Guard configuration

Go to your search-guard-helm folder with pre-installed dependencies and do:
```
$ helm install -f sg-helm/examples/setup_custom_sg_config/values.yaml sg-elk sg-helm
```
In this case, you get Elasticsearch cluster from basic setup with additional `config.http` configuration in `elasticsearch.yml` and additional user `beatsuser`.
Get the password of newly created user running `kubectl get secrets sg-elk-sg-helm-passwd-secret -o jsonpath="{.data.SG_BEATSUSER_PWD}" | base64 -d`.

 To get access to Kibana:
  * Run minikube tunnel in different window
  * Get Kibana external IP by `kubectl get svc|grep LoadBalancer|awk '{print $4}'` and assign it to kibana.sg-helm.example.com in your `etc/hosts` file
  * Access https://kibana.example.com with default user `kibanaro` and password extracted by this command `kubectl get secrets sg-elk-sg-helm-passwd-secret -o jsonpath="{.data.SG_KIBANARO_PWD}" | base64 -d`
