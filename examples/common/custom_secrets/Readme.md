# Example of Managing Environment Variables from Kubernetes Secrets

This Helm code snippet is used to **dynamically inject** environment variables into Kubernetes containers by retrieving their values from existing **Secret** objects.

## ⚠️ WARNING: Pre-existing Secrets Required
The Helm templates defined here do not create the Kubernetes Secret objects themselves. They only instruct the Deployment/StatefulSet to reference the secrets defined in values.yaml.

Before deploying the chart, you must ensure that all Secret objects referenced by the secretName fields (e.g., common-custom-secret, kibana-custom-secret) already exist in the target namespace.

Failure to create the secrets beforehand will result in:

Containers failing to start (entering CrashLoopBackOff state).

The Pods reporting errors such as key not found or secret not found in their events.

## 1\. The `values.yaml` Structure

In the `values.yaml` file, you define lists of secrets for different components.

### The `common` Section

This section contains a list of environment variables that are **common** to all (or many) components in your chart.

```yaml
common:
  env_secrets:
    - envName: COMMON_CUSTOM_SECRET # The name of the environment variable in the container
      secretName: common-custom-secret # The name of the Kubernetes Secret object
      secretKey: secret # The key in the Secret object whose value should be used
    - envName: COMMON_CUSTOM_PASSWORD
      secretName: common-custom-secret
      secretKey: password
```

### Local Sections (e.g., `kibana`)

Each component (like `kibana` in this example) can have its own section with a list of **local** environment variables.

```yaml
kibana:
  env_secrets:
    - envName: KIBANA_CUSTOM_SECRET
      secretName: kibana-custom-secret
      secretKey: secret
    - envName: KIBANA_CUSTOM_PASSWORD
      secretName: kibana-custom-secret
      secretKey: password
```

-----

## 2\. The Templates (Helpers)

Two templates are defined in the helper file (`_helpers.tpl`) to generate Kubernetes configuration snippets (typically used in the `env` section of a Deployment, StatefulSet, etc.).

### `searchguard.common-secrets`

This template injects **common** environment variables using the list defined in the `$.Values.common.env_secrets` path.

  * **Use Case:** Use this when you need to inject variables shared across the entire chart.
  * **Required Context:** Requires the main context (`$`, i.e., `$.Values`) to be passed.
  * **Example Call (in a `.yaml` template file):**
    ```yaml
    env:
      {{- include "searchguard.common-secrets" . | nindent 6 }}
    ```

### `searchguard.local-secrets`

This template injects **local** environment variables using the `env_secrets` list from the **currently passed context**.

  * **Use Case:** Use this to add component-specific environment variables.
  * **Required Context:** Expects the context (`.`) to be the path to an object containing the `env_secrets` field (e.g., `.Values.kibana`).
  * **Example Call (in a `.yaml` template file):**
    ```yaml
    env:
      {{- include "searchguard.local-secrets" . | nindent 6 }}
    ```

-----

## 3\. Combining the Templates

To inject *all* variables (common and local) for a component, you must combine the calls to both templates within the component's `env` section.

### Example Usage in a Deployment Template (e.g., `kibana-deployment.yaml`)

```yaml
spec:
  containers:
  - name: {{ include "mychart.fullname" . }}-kibana
    image: "..."
    env:
      # 1. Common Variables from global context
      {{- include "searchguard.common-secrets" $ | nindent 6 }}
      # 2. Kibana-specific Variables from local kibana-values context
      {{- include "searchguard.local-secrets" . | nindent 6 }}
```

**Result (Generated Kubernetes Code):**
This will generate a list of environment variables fetched from Secrets, e.g.:

```yaml
    env:
      - name: COMMON_CUSTOM_SECRET
        valueFrom:
          secretKeyRef:
            name: common-custom-secret
            key: secret
      - name: COMMON_CUSTOM_PASSWORD
        valueFrom:
          secretKeyRef:
            name: common-custom-secret
            key: password
      - name: KIBANA_CUSTOM_SECRET
        valueFrom:
          secretKeyRef:
            name: kibana-custom-secret
            key: secret
      - name: KIBANA_CUSTOM_PASSWORD
        valueFrom:
          secretKeyRef:
            name: kibana-custom-secret
            key: password
```
