# Change the Dynamic Search Guard Configuration

This example shows how to manage the **Search Guard dynamic configuration** (users, roles, role mappings, and so on) through the Helm chart, and explains how the chart applies those changes to the running cluster.

## ⚠️ WARNING: Helm Overwrites the Whole Configuration

When `common.update_sgconfig_on_change` is `true` (the default), running `helm upgrade` overwrites the **entire** Search Guard configuration stored in the cluster. This is intentional, but it means every change made through the REST API or the Search Guard Kibana UI is lost on the next upgrade.

## 1\. The `values.yaml` Structure

The dynamic configuration is defined under `common`. This example adds an internal user, a role, and a role mapping.

```yaml
common:
  # Additional users, maps to sg_internal_users.yml
  users:
    demouser:
      hash: $2a$12$wtusE0WRlhmRhqQQccjaw.NuM7aWyhc29gM8LobXAU/XqOhYFa4x.
      backend_roles:
        - beatsreader
  # Additional role mappings, maps to sg_roles_mapping.yml
  rolesmapping:
    sg_read_beats:
      backend_roles:
        - beatsreader
  # Additional roles, maps to sg_roles.yml
  roles:
    sg_read_beats:
      cluster_permissions:
        - SGS_CLUSTER_COMPOSITE_OPS_RO
      index_permissions:
        - index_patterns:
            - "*beat*"
          allowed_actions:
            - SGS_READ
```

## 2\. Managing the Configuration

### Manage via Helm (the default)

Change any dynamic configuration in `values.yaml` and run `helm upgrade`. The whole configuration stored in the cluster is overwritten, as noted in the warning above.

### Manage externally

To manage the configuration externally, via the REST API or the Search Guard Kibana UI:

1. Set `common.update_sgconfig_on_change` to `false` when you install the Helm chart.
2. Be aware that setting `common.update_sgconfig_on_change` back to `true` (on purpose or by accident) will overwrite your externally managed configuration.

## 3\. Apply

```
helm upgrade -f examples/common/update_sg_config/values.yaml sg-elk ./
```
