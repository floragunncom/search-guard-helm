# Disable sgctl CLI and Configuration from a Secret

This example **reverts** the setup shown in the [`configuration_from_secret`](../configuration_from_secret) and [`enable_sgctl_cli`](../enable_sgctl_cli) examples. It **disables** the sgctl CLI Pod and the "configuration from a Secret" feature, and **restores the default** `authc` configuration, so the Search Guard dynamic configuration is managed again from the ConfigMap rendered from `values.yaml`.

## 1\. The `values.yaml` Structure

```yaml
common:
  sgctl_cli: false
  sg_dynamic_configuration_from_secret:
    enabled: false
  authc:
    debug: false
    auth_domains:
    - type: basic/internal_users_db
```

### Explanation

  * **`sgctl_cli: false`** — removes the `sgctl-cli` Pod that provides interactive access to the `sgctl.sh` tool.
  * **`sg_dynamic_configuration_from_secret.enabled: false`** — stops reading the Search Guard configuration from the Kubernetes Secret; the configuration is taken from the ConfigMap rendered from `values.yaml`.
  * **`authc`** — restores the default authentication domain (`basic/internal_users_db`).

## 2\. Apply

```
helm upgrade -f examples/common/disable_sgctl_cli_configuration_from_secret/values.yaml sg-elk ./
```

> **Note:** Disabling the feature does not delete the Secret that was created for the `configuration_from_secret` example. Remove it manually with `kubectl delete secret <name>` if it is no longer needed.
