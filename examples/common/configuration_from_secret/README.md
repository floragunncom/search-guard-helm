# Configuration from a Secret

This example stores all or part of the **Search Guard dynamic configuration** in a **Kubernetes Secret** instead of (or in addition to) the ConfigMap that is rendered from `values.yaml`. When the feature is enabled, the `*.yml` files stored in the Secret are combined with the ConfigMap through a projected volume; a file present in the Secret **overrides** the same file coming from the ConfigMap.

## ⚠️ WARNING: Pre-existing Secret Required

The chart does not create the Secret that holds the Search Guard configuration files. You must create it in the target namespace **before** installing or upgrading the chart. If the Secret is missing, the projected volume cannot be mounted and the pods will not start.

## 1\. The `values.yaml` Structure

Enable the feature and, optionally, override the default Secret name suffix.

```yaml
common:
  sg_dynamic_configuration_from_secret:
    enabled: true
    secret_name: "sg-dynamic-configuration-secret"
```

The full Secret name follows the pattern `<release>-search-guard-flx-<secret_name>`. With the release name `sg-elk` and the default suffix above, the Secret must be named `sg-elk-search-guard-flx-sg-dynamic-configuration-secret`.

## 2\. Create the Secret

Create the Secret from your Search Guard configuration files. This example folder ships two sample files, `sg_authc.yml` and `sg_license_key.yml`, that you can use:

```
kubectl -n <namespace> create secret generic sg-elk-search-guard-flx-sg-dynamic-configuration-secret \
  --from-file=./sg_license_key.yml --from-file=./sg_authc.yml
```

You can include any subset of the Search Guard configuration files (see the [authentication and authorization documentation](https://docs.search-guard.com/latest/authentication-authorization-configuration)); only the files you add to the Secret are overridden.

## 3\. Install or Upgrade

```
helm upgrade -f examples/common/configuration_from_secret/values.yaml sg-elk ./
```

After the install or upgrade completes, the `*.yml` files stored in the Secret are added to the configuration or, if a file already exists in the ConfigMap, their content is replaced.

To revert to a chart-managed configuration, see the [`disable_sgctl_cli_configuration_from_secret`](../disable_sgctl_cli_configuration_from_secret) example.
