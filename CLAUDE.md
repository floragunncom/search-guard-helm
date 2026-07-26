# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A single Helm chart (`search-guard-flx`) that deploys a Search Guard FLX protected Elasticsearch +
Kibana cluster. There are no subcharts and no `dependencies:` in `Chart.yaml` — `helm dependency
update` (mentioned in the README) is a no-op. Alongside the chart: `docker/` (image build scripts),
`examples/` (values overlays, also used as test fixtures), `tests/` (bash integration tests against
minikube), `values.yaml` (ES 8/9) and `values-flx-7.yaml` (ES 7).

## Commands

### Render / validate

```bash
helm template .                                  # default values
helm template . -f examples/common/scale_cluster/values.yaml
```

CI (`validate_helm`) renders the defaults plus every `examples/**/values.yaml`, so a new example
must render cleanly. Reproduce it locally:

```bash
for v in $(find examples -name values.yaml); do helm template . -f "$v" > /dev/null || echo "FAIL $v"; done
```

All example overlays use the `values.yaml` extension, so they are all covered by that loop.

### Integration tests (minikube)

```bash
./tests/prepare_minikube.sh [v1.36.1]   # deletes and recreates the "multinode" 3-node profile
./tests/run_tests.sh                    # ELK 8/9 scenario chain
./tests/run_tests_elk_7.sh              # ELK 7 scenario chain
```

`run_tests.sh` is an install followed by a sequence of `helm upgrade`s, one per example directory.
To run a **single** scenario against an already-installed cluster, call `upgrade.sh` directly:

```bash
# args: <namespace> <values-folder> <values-file|""> <expected node count> [pre-script] [post-script]
./tests/upgrade.sh integtests examples/common/update_sg_config "" 7
./tests/upgrade.sh integtests examples/common/configuration_variables "" 7 tests/pre_upgrade.sh tests/post_upgrade.sh
```

The pre/post scripts are paths *relative to the values folder* (`examples/<x>/tests/*.sh`); they
receive `$1=namespace $2=values-folder` and are where assertions live (curl against a port-forward,
`sgctl.sh` calls in the `role=sgctl-cli` pod).

Other entry points: `tests/install.sh` (fresh install, deletes the previous release first),
`tests/run_default_install.sh` (defaults, namespace `defaultinstall`),
`tests/delete_releases.sh`, `tests/test_different_k8s_versions.sh <min> <max>` (loops k8s minors).

Scripts hardcode release name `sg-elk` and namespace `integtests`, so all resources are named
`sg-elk-search-guard-flx-*`. `install.sh` picks its override values file from the **current kubectl
context**: `multinode` or `kind-kind` → `initial_values_minikube.yaml`, anything else → assumed AWS
(`initial_values_aws.yaml`, not in the repo). Pass `nocontext` as `$4` to skip the override.

### Docker images

Edit the `versions` / `sgctl_versions` / `cluster_config_versions` arrays in
`docker/build_multiarch.sh`, set `DOCKER_PASSWORD` in `docker/docker_setup.sh`, then:

```bash
./docker/build_multiarch.sh <docker-user> <docker-repo>
```

Tags: `<sgversion>-es-<esversion>` for elasticsearch/kibana; cluster-config is tagged **major.minor
only** (a new kubectl patch release does not need a new image).

### Release

Bump `version:` in `Chart.yaml`. On `main`, CI packages, `cm-push`es to the GitLab helm repo and
pushes a git tag `<version>-flx`. `validate_release` fails the pipeline if that version already
exists as a tag or in the repo, so the bump must land in the same commit range as the change.

## Architecture

### Node groups → StatefulSets

Each Elasticsearch role gets its own StatefulSet template: `master`, `data`, `client`
(ingest/transform/remote_cluster_client), optional `datacontent` (`datacontent.enabled`), optional
`signals`, plus `kibana`.

Every node-group values block may be **either a single map or a list of named groups**. Templates
normalize this at the top of the file:

```gotemplate
{{- $dataValues := .Values.data }}
{{- if not (kindIs "slice" .Values.data) }}
{{- $dataValues = list (merge (dict "name" "data") .Values.data) }}
{{- end }}
{{- range $dataValues }}
```

Inside such a `range`, the root context is `$`, not `.`. Any new node-group template — and any job
that counts replicas (`cluster-upgrade.yaml`, `cluster-post-install-setup.yaml`) — must follow this
idiom or multi-group configurations break.

### Pod restarts are driven by a Job, not by Kubernetes

All ES StatefulSets use `updateStrategy: OnDelete` with `podManagementPolicy: Parallel`. Changing a
values field does **not** roll the pods. Instead:

1. `common.restart_pods_on_config_change` puts a `checksum/config` pod annotation on each
   StatefulSet, hashed from `sg-static-configuration.yaml` (ES nodes), `kibana-configmap.yaml` or
   `signals-configmap.yaml`. A config change bumps `updateRevision`.
2. The `post-upgrade` Job `cluster-upgrade` (hook-weight `-1`) waits for cluster health, then calls
   the `searchguard.sgctl.updateIfRequired` helper per StatefulSet in a fixed order —
   client → signals → data → data-content → master → kibana — deleting pods and waiting for
   `currentRevision == updateRevision` before moving on.

So debugging "my change didn't take effect" usually means looking at the cluster-upgrade Job logs,
not at the StatefulSet.

### Helm hook ordering

| Phase | Resource | Weight |
|---|---|---|
| pre-install, pre-upgrade | `sg-role`, `serviceaccount` | -6 |
| pre-install | `rolebinding`, `empty-nodes-cert-secret` | -5 |
| pre-install | `upload-certificates` (Secret) | -4 |
| post-install | `sgctl-initialize-cluster` | 0 |
| post-install | `cluster-post-install-setup`, `signals-configure` | 10 |
| post-upgrade | `cluster-upgrade` | -1 |
| post-upgrade | `sgctl-update-cluster` | 0 |
| post-delete | `remove-secrets-on-delete-job` | -1 |

`sgctl-generate-certs.yaml` (the `-sgctl-preinstall` Job) is *not* a hook — it is guarded by
`{{ if .Release.IsInstall }}` and runs as an ordinary manifest.

### Certificates, secrets and passwords

Three mutually exclusive PKI modes, selected in `common`: `sgctl_certificates_enabled` (self-signed,
generated in-cluster — the default), `ca_certificates_enabled` (bring your own CA into
`common.certificates_directory`), or pre-provisioned certs. The sgctl image generates per-node certs
in an init container and `kubectl patch`es them into `<fullname>-nodes-cert-secret`; a container
`preStop` lifecycle hook removes that node's entry again
(`searchguard.lifecycle-cleanup-certs` / `patch-node-certificates` in `_helpers.tpl`).

Generated secrets: `-passwd-secret`, `-root-ca-secret`, `-admin-cert-secret`, `-nodes-cert-secret`.
Passwords for `admin`, `kibanaserver`, `kibanaro` and any `common.users` are random on first
install; the SG config references them as `${envbc.SG_<USER>_PWD}` placeholders that Search Guard
resolves at load time — the hashes in `sg-dynamic-configuration.yaml` are never real hashes.

### Configuration flow

* **elasticsearch.yml** — the `searchguard.configmap` helper in `_helpers.tpl` plus arbitrary
  `common.config` keys, rendered into `sg-static-configuration.yaml`.
* **SG dynamic config** (`sg_authc.yml`, `sg_authz.yml`, `sg_roles.yml`, `sg_internal_users.yml`, …)
  — rendered into the `-sg-dynamic-configuration` ConfigMap from `common.authc`, `common.authz`,
  `common.roles`, `common.rolesmapping`, `common.users`, `common.tenants`,
  `common.fieldAnonymization`, etc. With `common.sg_dynamic_configuration_from_secret.enabled` the
  ConfigMap and a Secret are combined via a projected volume. Applied to the running cluster by the
  sgctl jobs when `common.update_sgconfig_on_change` is set.
* **kubectl inside containers** — the `cluster-config` image is used as an init container that copies
  the `kubectl` binary into an emptyDir shared with the main container
  (`searchguard.kubectl-init-container`). ES/sgctl containers rely on it for the secret patching above.

### Version branching

`searchguard.elk-version` and `searchguard.sg-major-version` take `substr 0 1` of
`common.elkversion` / `common.sgversion`, so templates branch on the major version string
(e.g. `processors:` is only emitted for ES 7). ES 7 users get `values-flx-7.yaml`; a version bump
touches `common.elkversion`, `sgversion`, `sgkibanaversion` and `sgctl_version` in **both** values
files.

`Chart.yaml` carries a `kubeVersion` range; widening supported Kubernetes versions means editing
that range *and* adding a `cluster_config_versions` entry in `docker/build_multiarch.sh`.

## Gotchas

* **Completed jobs disappear.** `cleanup-cronjob.yaml` runs every 5 minutes and deletes *every*
  succeeded Job in the release namespace. Set `common.debug_job_mode: true` to make it skip the
  deletion so failed/succeeded sgctl jobs stay around for log inspection.
* **Stale port-forwards.** `install.sh` / `upgrade.sh` run
  `kill -9 $(pgrep -f "kubectl port-forward")` before starting their own forward on 9200 — a manual
  port-forward running in another shell will be killed.
* **`common.es_upgrade_order=true` deadlocks with `master.replicas=1`** — master and non-master
  dependency conditions block each other.
* Resource names are all `{{ template "searchguard.fullname" }}` = `<release>-<chart-name>`, and the
  scripts, examples and pre/post-upgrade assertions hardcode the `sg-elk` prefix.
