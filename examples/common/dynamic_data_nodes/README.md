# Example of Multiple Data Node Groups (Data Tiers)

This example configures **several independent data node groups** in a single cluster by providing the `data` value as a **list of named groups** instead of a single map. Each entry in the list becomes its own StatefulSet, which makes it possible to model the Elasticsearch [data tiers](https://www.elastic.co/guide/en/elasticsearch/reference/current/data-tiers.html) (`data_hot`, `data_warm`, `data_cold`, `data_content`) with different sizing per tier.

## ⚠️ WARNING: Changing the Topology Requires Deleting StatefulSets

The Elasticsearch StatefulSets use `updateStrategy: OnDelete`, so adding, removing, or renaming a group does **not** automatically reconcile the running StatefulSets. In particular, a **removed or renamed** group leaves its old StatefulSet (and its Pods) behind.

A helper script is provided in `scripts/` to delete the data StatefulSets so they can be recreated from the updated list.

Note that deleting a StatefulSet does **not** delete its PersistentVolumeClaims, so the data on a group that keeps the same name is retained. Data on a **renamed or removed** group is no longer attached to any StatefulSet and must be migrated beforehand (for example with shard allocation filtering) if it needs to be preserved.

## 1. The `values.yaml` Structure

The `data` key is defined as a list. Every element must have a unique `name` (which is used to name the StatefulSet) and can set its own `replicas`, `roles`, `storage`, `resources`, and so on.

```yaml
data:
  - name: "data"
    replicas: 3
    storage: 3Gi
    storageClass: local-path
    roles:
      - data
      - remote_cluster_client
  - name: "hot"
    replicas: 1
    storage: 3Gi
    storageClass: local-path
    roles:
      - data_hot
      - remote_cluster_client
  - name: "warm"
    replicas: 1
    roles:
      - data_warm
      - remote_cluster_client
  - name: "cold"
    replicas: 1
    roles:
      - data_cold
      - remote_cluster_client
  - name: "content"
    replicas: 2
    roles:
      - data_content
      - remote_cluster_client
```

Each named group results in a StatefulSet named `sg-elk-search-guard-flx-<name>` with the labels `role=data` (and `role=data-content` for the content tier).

## 2. The Helper Script

`scripts/remove_data_sts.sh` deletes the data StatefulSets and waits for their Pods to be removed, so the chart can recreate them from the new list on the next `helm upgrade`:

```bash
./scripts/remove_data_sts.sh <namespace>
```

It runs the following, using the `role` labels described above:

```bash
kubectl -n <namespace> delete sts -l role=data
kubectl -n <namespace> wait --for=delete pod -l role=data --timeout=300s
kubectl -n <namespace> delete sts -l role=data-content
kubectl -n <namespace> wait --for=delete pod -l role=data-content --timeout=300s
```

## 3. Install or Upgrade

To install this usage example, go to your `search-guard-flx-helm-charts` folder and run:

```
helm install -f examples/common/dynamic_data_nodes/values.yaml sg-elk ./
```

When you change the number or the names of the groups, apply the new values and then run the helper script so the StatefulSets are recreated:

```
helm upgrade -f examples/common/dynamic_data_nodes/values.yaml sg-elk ./
./examples/common/dynamic_data_nodes/scripts/remove_data_sts.sh <namespace>
```
