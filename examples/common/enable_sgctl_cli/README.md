#  Enable sgctl.sh POD in kubernetes cluster

This usage example [configuration](https://git.floragunn.com/search-guard/search-guard-flx-helm-charts/-/blob/main/examples/common/enable_sgctl_cli/values.yaml) sets up protected 4-nodes Elasticsearch cluster with sgctl tool in separate Pod [Configuration variables](https://docs.search-guard.com/latest/sgctl-examples#using-sgctl-to-configure-search-guard)




The sgctl can be used to manage configuration variables, an example of which can be found [here](https://git.floragunn.com/search-guard/search-guard-flx-helm-charts/-/blob/main/examples/common/configuration_variables/values.yaml) 


To activate the POD containing access to sgctl.sh, update the helm charts using the following configuration:

```
common:
  sgctl_cli: true

```


After upgrading helm charts following command can be use to connect to sgctl.sh Pod

```
kubectl -n <namespace> exec  $(kubectl -n <namespace> get pod -l role=sgctl-cli  -o jsonpath='{.items[0].metadata.name}') -it bash
```


Example usage of sgctl.sh:

```
/usr/share/sg/sgctl/sgctl.sh add-var ldap_password secret123 --encrypt   \
  -h $DISCOVERY_SERVICE  \
  --key /sgcerts/key.pem \
  --cert /sgcerts/crt.pem \
  --ca-cert /sgcerts/root-ca.pem 
```




To disable the POD containing access to sgctl.sh, update the helm charts using the following configuration:

```
common:
  sgctl_cli: false
```