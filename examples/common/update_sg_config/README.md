# Change dynamic Search Guard configuration
## How to manage Search Guard dynamic configuration

The Search Guard dynamic configuration can be managed either via Helm or externally.

### Manage via Helm (this is the default)

Change any dynamic configuration in `values.yaml` and run `helm upgrade`. Please be aware that the whole
configuration stored in the cluster is overwritten (which is intentional here). This means that every change made
by the REST API or Search Guard Kibana UI will be lost.

### Manage externally

To manage the configuration externally via the REST API or by using the Search Guard Kibana UI please be aware of

1. Set `common.update_sgconfig_on_change` to `false` when you install the Helm chart
2. When you set `common.update_sgconfig_on_change` back to `true` (on purpose or by accident) your configuration will be overwritten

