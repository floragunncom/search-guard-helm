# Using Configuration variables from external files in helm charts



kubectl -n <namespace>  create  secret generic {helm name}-search-guard-flx-{value defined in common.sg_dynamic_configuration_from_secret.secret_name }  --from-file=./<filename>.yml 



kubectl -n <namespace>  create  secret generic sg-config-external-files --from-file=./jwks-secret --from-file=./license-secret