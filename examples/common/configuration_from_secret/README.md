# Configuration from secret

This usage example [configuration](https://git.floragunn.com/search-guard/search-guard-helm/-/blob/master/examples/common/configuration_from_secret/values.yaml) sets up protected 4-nodes Elasticsearch cluster by providing helm configuration from Kubernetes secret.


This configuration allows storing all or part of the SearchGuard configuration files in Kubernetes secrets.

To use the configuration, you need to create a secret in the Kubernetes cluster using the command:

```
kubectl -n <namespace>  create  secret generic {helm name}-search-guard-flx-{value defined in common.sg_dynamic_configuration_from_secret.secret_name }  --from-file=./<filename>.yml 
``` 

Below is an example command for creating secrets for the `sg_license_key.yml` file and the `sg_authc.yml` file  https://docs.search-guard.com/latest/authentication-authorization-configuration, assuming that the helm chart was installed with the name `sg-elk` and the default secret suffix `sg-dynamic-configuration-secret` was used

```
kubectl -n <namespace>  create  secret generic sg-elk-search-guard-flx-sg-dynamic-configuration-secret  --from-file=./sg_license_key.yml --from-file=./sg_authc.yml
``` 

After creating the secret, it is necessary to change the configuration parameters found in the configuration file [configuration] (https://git.floragunn.com/search-guard/search-guard-helm/-/blob/master/examples/common/configuration_from_secret/values.yaml) 


After completing the installation or update of a helm chart, ``*.yml` files located in the` secret `sg-elk-search-guard-flx-sg-dynamic-configuration-secret` will add, or in the case of these files already existing in the configuration, replace their content.







