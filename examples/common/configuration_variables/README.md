# Using Configuration variables in helm charts

This usage example [configuration](https://git.floragunn.com/search-guard/search-guard-flx-helm-charts/-/blob/main/examples/common/configuration_variables/values.yaml) sets up protected 4-nodes Elasticsearch cluster by providing helm configuration using [Configuration variables](https://docs.search-guard.com/latest/configuration-password-handling)

The following example describes how to use [Configuration variables](https://docs.search-guard.com/latest/configuration-password-handling) for storing sensitive SearchGuard configuration data in a secure index.

This example configuration allows for the storage of licenses and JWT configuration [SearchGuard JWT Documentation] https://docs.search-guard.com/latest/json-web-tokens using SearchGuard Configuration variables.


To apply this configuration, the following steps must be taken:

* Activate the configuration SearchGuard Helm Configuration [values.yml](https://git.floragunn.com/search-guard/search-guard-flx-helm-charts/-/blob/main/examples/common/enable_sgctl_cli/values.yaml), which will enable access to the sgctl tool. After applying this configuration, a new POD will be created, providing access to the sgctl.sh tool.

* Add the license and configuration, perform the following steps:

* Copy the `keys.json` configuration file to the POD with sgctl (for production environments, change the data in the file and store it in a secure place):

```
kubectl -n <namespace> cp ./keys.json  $(kubectl -n <namespace> get pod -l role=sgctl-cli  -o jsonpath='{.items[0].metadata.name}'):/tmp/keys.json
```

* Connect to the sgctl POD using the following command:

```
kubectl -n <namespace> exec  $(kubectl -n <namespace> get pod -l role=sgctl-cli  -o jsonpath='{.items[0].metadata.name}') -it bash
```

* Using sgctl.sh, create a jwks variable containing the configuration found in keys.json:

```
/usr/share/sg/sgctl/sgctl.sh add-var jwks --encrypt  \
  -h $DISCOVERY_SERVICE  \
  --key /sgcerts/key.pem \
  --cert /sgcerts/crt.pem \
  --ca-cert /sgcerts/root-ca.pem \
  --input-file /tmp/keys.json
```

If the jwks variable is added correctly, the sgctl tool will return the following message:


```
Successfully connected to cluster searchguard (sg-elk-search-guard-flx-discovery.integtests.svc) as user CN=admin,OU=Ops,O=Example Com\, Inc.,DC=example,DC=com
Created
```

* Create a license configuration variable to store the license:

```
/usr/share/sg/sgctl/sgctl.sh add-var license replace_with_the_valid_base64_endcoded_SearchGuard_license --encrypt  \
  -h $DISCOVERY_SERVICE  \
  --key /sgcerts/key.pem \
  --cert /sgcerts/crt.pem \
  --ca-cert /sgcerts/root-ca.pem 
```


If the license variable is added correctly, the sgctl tool will return the following message:

```
Successfully connected to cluster searchguard (sg-elk-search-guard-flx-discovery.integtests.svc) as user CN=admin,OU=Ops,O=Example Com\, Inc.,DC=example,DC=com
Created
```

* Update the helm charts using the configuration [ configuration ](https://git.floragunn.com/search-guard/search-guard-flx-helm-charts/-/blob/main/examples/common/configuration_variables/values.yaml)


* To disable the POD containing access to sgctl.sh, update the helm charts using the following configuration:

```
common:
  sgctl_cli: false
```


