# Setup with a Custom CA Certificate

This example provides your **own CA certificate** (a `crt.pem` / `key.pem` pair) that the cluster uses to sign all Elasticsearch node certificates for transport communication as well as the certificates for the HTTPS services of Elasticsearch and Kibana. This replaces the default behaviour, where a self-signed CA is generated in the cluster by the SG TLS tool.

## ⚠️ WARNING: Pre-existing CA Files Required

You must provide your own CA certificate and key as `crt.pem` and `key.pem` in the `ca` subfolder of the directory configured through `common.certificates_directory`. In this example that is `examples/common/setup_custom_ca/secrets/ca`. If these files are missing, certificate generation fails.

## 1\. The `values.yaml` Structure

```yaml
common:
  # Do not use the self-signed CA generated in the cluster
  sgctl_certificates_enabled: false
  # Sign all certificates with your own CA instead
  ca_certificates_enabled: true
  # Password of the CA private key (key.pem); omit if the key is not encrypted
  ca_password: passca222
  # Directory (relative to the chart root) that contains the "ca" subfolder with crt.pem and key.pem
  certificates_directory: "examples/common/setup_custom_ca/secrets"
```

### Explanation

  * **`sgctl_certificates_enabled` / `ca_certificates_enabled`** — these two PKI modes are mutually exclusive. Turning off the first and turning on the second switches from the in-cluster self-signed CA to your own CA.
  * **`ca_password`** — the password protecting the CA private key. Leave it empty if `key.pem` is not encrypted.
  * **`certificates_directory`** — the directory whose `ca` subfolder holds `crt.pem` and `key.pem`.

## 2\. Provide the CA Files

Place your CA certificate and key into the `ca` subfolder:

```
examples/common/setup_custom_ca/secrets/ca/crt.pem
examples/common/setup_custom_ca/secrets/ca/key.pem
```

## 3\. Install

To install this usage example, go to your `search-guard-flx-helm-charts` folder and run:

```
helm install -f examples/common/setup_custom_ca/values.yaml sg-elk ./
```

Get the `admin` user password to access the cluster:

```
kubectl get secrets sg-elk-search-guard-flx-passwd-secret -o jsonpath="{.data.SG_ADMIN_PWD}" | base64 -d
```

To uninstall this usage example, run:

```
helm uninstall sg-elk
```
