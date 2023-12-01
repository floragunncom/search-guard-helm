#  Change static configuration for Elasticsearch and/or Kibana

To change the elasticsearch.yml and kibana.yml configuration set the desired values in values.yaml

```
common:
  config:
    <anything here goes into elasticsearch.yml of every node>  
kibana:
  config:
    <anything here goes into kibana.yml of every kibana node>  
```