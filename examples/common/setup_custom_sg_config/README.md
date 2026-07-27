# Setup with Custom Elasticsearch and Search Guard Configuration

This example sets up a cluster with **custom Elasticsearch configuration** (additional `elasticsearch.yml` settings) and **custom Search Guard configuration** (an additional user, a role, and a role mapping). It shows the two configuration surfaces the chart exposes: `common.config` for Elasticsearch and `common.users` / `common.roles` / `common.rolesmapping` for Search Guard.

## 1\. The `values.yaml` Structure

### The `common.config` Section (Elasticsearch)

Anything under `common.config` is added to `elasticsearch.yml` on every node.

```yaml
common:
  config:
    http:
      compression: false
      cors:
        enabled: false
        allow-origin: "*"
    index.codec: best_compression
```

### The Search Guard Sections (`users`, `rolesmapping`, `roles`)

These define an additional internal user, a role, and the mapping between them.

```yaml
common:
  # Additional users, maps to sg_internal_users.yml
  users:
    demouser:
      hash: ${envbc.SG_BEATSUSER_PWD}
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

> **Note:** The `hash` value is a `${envbc.SG_..._PWD}` placeholder, not a real hash. Search Guard resolves it at load time from a randomly generated password that is stored in the `-passwd-secret` Secret.

## 2\. Install

To install this usage example, go to your `search-guard-flx-helm-charts` folder and run:

```
helm install -f examples/common/setup_custom_sg_config/values.yaml sg-elk ./
```

## 3\. Get the Password of the Created User

```
kubectl get secrets sg-elk-search-guard-flx-passwd-secret -o jsonpath="{.data.SG_BEATSUSER_PWD}" | base64 -d
```

To uninstall this usage example, run:

```
helm uninstall sg-elk
```
