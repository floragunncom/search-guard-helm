# Setup with dedicated data-content  node



The datacontent node is part of the content tier with long data retention. 
Enabling datacontent will create a dedicated StatefulSet in the cluster


To install this usage example, go to your `search-guard-helm` folder with pre-installed dependencies and do:
```
$ helm install -f examples/enable_data_content_node/values.yaml sg-elk ./ 
```