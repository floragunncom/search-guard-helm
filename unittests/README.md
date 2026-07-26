# Template unit tests (helm-unittest)

Fast, cluster-free checks of the chart's template logic, using
[helm-unittest](https://github.com/helm-unittest/helm-unittest). They render
templates in-process (milliseconds) and assert on the produced YAML. They are the
quick complement to the minikube integration tests in `../tests/` — they do **not**
talk to a cluster and cannot tell you the cluster actually comes up.

## Why a separate `unittests/` folder

`helm-unittest` defaults to `./tests/`, which in this repo is the bash integration
suite. To avoid the collision, the unit tests live here and are run with an
explicit glob.

## Install the plugin

```bash
# Helm 4 verifies plugin signatures by default and this plugin ships none,
# so --verify=false is required.
helm plugin install https://github.com/helm-unittest/helm-unittest --version v1.1.2 --verify=false
```

## Run

```bash
helm unittest -f 'unittests/*_test.yaml' .
```

## What is covered so far

| Suite | What it guards |
|---|---|
| `naming_test.yaml` | `searchguard.fullname` = `<release>-<chart>` for the client Service and the data/master StatefulSets (the prefix scripts and examples hardcode). |
| `client_service_test.yaml` | The client Service emits `loadBalancerIP` / `nodePort` / annotations only for the matching `serviceType`. |
| `node_groups_test.yaml` | The "single map **or** list of named groups" idiom for `data`, and the `datacontent.enabled` toggle. |

## Adding tests

Add a `*_test.yaml` suite here (or a test to an existing one) whenever you change
template logic. A few conventions that keep the suite robust:

* Set `release: { name: rel, namespace: default }` so asserted names are stable.
* Select the document by name with `documentSelector` rather than relying on
  `documentIndex` — document order is not something to depend on.
* Do **not** put StatefulSet templates in a suite-level `templates:` list. They
  `include` `sg-static-configuration.yaml`; restricting the template set makes
  that include fail. Select them per test with `template:` instead.
* Prefer asserting specific paths over snapshots for now; snapshots can come later
  for stable, verbose output.
