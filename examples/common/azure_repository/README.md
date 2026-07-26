# Example of an Azure Snapshot Repository

This example configures Elasticsearch to use **Azure Blob Storage** as a [snapshot repository](https://www.elastic.co/guide/en/elasticsearch/reference/current/repository-azure.html). The `azure.client` settings are added to `elasticsearch.yml`, while the Azure storage account name and key are injected into the **Elasticsearch keystore** from an existing Kubernetes **Secret**, so the credentials never appear in `values.yaml`.

## ⚠️ WARNING: Pre-existing Secret Required

The chart does not create the Kubernetes Secret with the Azure credentials. Before deploying, you must ensure that a Secret named `azure-client-secret` with the keys `azureclientdefaultaccount` and `azureclientdefaultkey` already exists in the target namespace.

Failure to create the Secret beforehand will result in the Elasticsearch Pods failing to start.

## 1. The `values.yaml` Structure

### The `common.config` Section

This section adds the Azure client settings to `elasticsearch.yml`.

```yaml
common:
  config:
    azure.client:
      default:
        timeout: 10s
        max_retries: 7
        endpoint_suffix: core.windows.net
```

### The `common.custom_elasticsearch_keystore` Section

This section enables the custom Elasticsearch keystore, reads the account name and key from the Secret via `extraEnvs`, and adds them to the keystore with a small script.

```yaml
common:
  custom_elasticsearch_keystore:
    enabled: true
    extraEnvs:
      - name: AZURE_CLIENT_DEFAULT_ACCOUNT
        valueFrom:
          secretKeyRef:
            name: azure-client-secret
            key: azureclientdefaultaccount
      - name: AZURE_CLIENT_DEFAULT_KEY
        valueFrom:
          secretKeyRef:
            name: azure-client-secret
            key: azureclientdefaultkey
    script: |
      echo $AZURE_CLIENT_DEFAULT_ACCOUNT | $ELASTICSEARCH_KEYSTORE add --stdin azure.client.default.account
      echo $AZURE_CLIENT_DEFAULT_KEY | $ELASTICSEARCH_KEYSTORE add --stdin azure.client.default.key
```

## 2. Create the Secret

Create the Secret with your Azure storage account name and key before installing the chart:

```
kubectl -n <namespace> create secret generic azure-client-secret \
  --from-literal=azureclientdefaultaccount=<storage-account-name> \
  --from-literal=azureclientdefaultkey=<storage-account-key>
```

## 3. Install

To install this usage example, go to your `search-guard-flx-helm-charts` folder and run:

```
helm install -f examples/common/azure_repository/values.yaml sg-elk ./
```

## 4. Register the Repository

Once the cluster is running, register the Azure repository (replace the container name with your own):

```
PUT _snapshot/my_azure_repository
{
  "type": "azure",
  "settings": {
    "client": "default",
    "container": "my-container"
  }
}
```
