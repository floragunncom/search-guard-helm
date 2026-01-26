# Devops Guide to SG helm charts

## Assumptions

Throughout this document, it is assumed that the user has installed the basic tools and has a basic understanding of how to use them.

## Tools

Tools required:

* minikube -  https://kubernetes.io/docs/tasks/tools/
* kubectl - do.
* helm - https://helm.sh
 

Nice to have:

 * k9s - https://k9scli.io
 
## Preparation
All necessary scripts are located in the `tests` directory of the main repository.

### Minikube cluster
The `prepare_minikube.sh` script prepares the entire Minikube environment required for testing.

**Important notes:**

1. The script starts by cleaning up the existing environment, which includes shutting down all active Minikube instances. Keep this in mind if you are currently using Minikube for other projects.

1. By default, the script allocates minimal resources. If you encounter the `OOMKilled (Exit Code 137)` error during testing, it indicates memory exhaustion. To fix this, increase the `memory` parameter in the script. If your CPU has more cores, you should also increase the `cpus` parameter, which will significantly speed up test execution.

1. By default, the script finishes by launching the Kubernetes Dashboard in your local browser. If launched remotely via SSH, it may attempt to open a text-based browser (such as `links` or `elinks`). These browsers **do not support JavaScript**, which is required by the dashboard, resulting in a blank or dark screen. In such cases, close the text browser (usually by pressing **Q**). The dashboard itself will continue to run in the background.

1. To use the dashboard from a remote machine without opening a browser, run it with the `--url --port <PORT>` parameters. This will display the access URL without launching a browser. **Note:** Without the `--port` parameter, a random port will be assigned each time.

    For security reasons, Minikube binds the dashboard to `127.0.0.1` (localhost), making it inaccessible from external machines by default.

    If you are on the same local network, you can enable a proxy to allow external access:

    ```bash
    kubectl proxy --address='0.0.0.0' --accept-hosts='^*$' &
    ```

    The dashboard will then be accessible via the test machine's IP address at the following URL:
    `http://<MACHINE_IP>:8001/api/v1/namespaces/kubernetes-dashboard/services/http:kubernetes-dashboard:/proxy/`

    If you are working remotely, the easiest and most secure method is to use an SSH tunnel:

    ```bash
    ssh <user>@<machine_ip> -L 8001:localhost:<dashboard_port>
    ```
    
## Modifying the Code

After creating your own branch, you can begin introducing changes to the repository. Work on Helm Chart code should follow a structured and disciplined approach to ensure consistency, predictability, and long‑term maintainability.  

It is strongly recommended to follow the official best practices defined by the Helm maintainers:

- Template best practices: https://helm.sh/docs/chart_best_practices/templates/
- General template guide: https://helm.sh/docs/chart_template_guide/

### Key principles when modifying Helm Chart code

### 1. Preserve the standard Chart directory structure
Each Chart follows a defined layout (`Chart.yaml`, `values.yaml`, the `templates/` directory, and optionally `charts/`).  
Changes should respect this structure — avoid moving files arbitrarily or introducing unconventional layouts that make the Chart harder to understand or maintain.

### 2. Work with values (`values.yaml`)
- All configurable parameters should be defined in `values.yaml` or in dedicated values files if the project uses them.
- Avoid hard‑coding values directly in templates — every parameter should be overridable.
- Provide sensible defaults so the Chart can be deployed without additional configuration.

### 3. Writing templates in the `templates/` directory
- Templates should be small, readable, and modular.
- Prefer Helm functions (`include`, `tpl`, `required`, `default`, `toYaml`, `nindent`) over duplicating logic.
- Keep logic minimal — Helm is not a programming language, and excessive conditionals make templates harder to maintain.

### 4. Use helper templates (`_helpers.tpl`)
- Reusable fragments (resource names, labels, annotations, common blocks) should be extracted into helper templates.
- Helper names should be descriptive and documented with comments.
- Follow common naming conventions, such as `{{ include "chart.fullname" . }}`.

### 5. Validate your changes
Before pushing changes, always perform:

- **Chart linting**  
  ```bash
  helm lint .
  ```

- **Local template rendering**  
  ```bash
  helm template . --values values.yaml
  ```
  
  Or more detailed for one file eg:

    ```bash
    helm template sg .  -s templates/master-statefulset.yaml -f examples/common/custom_secrets/values.yaml --debug | less
    ```

- **Testing with multiple values files**, if the project uses them  

- **Kubernetes compatibility checks**, e.g.:  
  ```bash
  kubectl apply --dry-run=client -f <rendered-manifest>
  ```

### 6. Maintain backward compatibility
If the Chart is used in production, evaluate every change for:

- impact on existing deployments,
- whether version bumps are required (`version` and `appVersion` in `Chart.yaml`),
- semantic versioning rules (breaking changes require a major version bump).

### 7. Document your changes
Significant changes should be reflected in:

- code comments,
- the Chart’s `README.md`,
- a changelog, if the project maintains one.

### 8. Prepare changes for Code Review
- Keep commits small and logically grouped.
- Commit messages should clearly explain what was changed and why.
- Pull Requests should include context, justification, and testing instructions.

## Integration Tests

Whenever a significant change or a new feature is introduced, it must be accompanied by a corresponding set of integration tests. These tests verify that the new functionality remains compatible with the rest of the system and does not introduce regressions.

An integration test suite should include all templates, variables, and configuration files required to validate the change, as well as any necessary pre‑update and post‑update scripts.  
Tests are divided into two general categories:

- **default** — version‑agnostic tests that apply to all system variants  
- **version‑specific** — tests targeting a particular system release, such as `elk_7` or `elk_8`

Integration tests are executed using the scripts located in the `./tests` directory.

### Basic test script

The primary script used for integration testing is `upgrade.sh`.  
Its purpose is to apply changes using Helm’s built‑in `upgrade` mechanism and then verify that the entire cluster starts correctly after the update.

**Note:** This script itself does not perform any specific actions related to the changes, it only checks whether the cluster has started correctly after making the changes.

The script is executed with the following parameters:

- **$1 – namespace**
- **$2 – YAML files folder**  
- **$3 – values file name**  
- **$4 – number of nodes**  
- **$5 – pre‑update script** — performs additional modifications required for the test, such as creating users, secrets, or other resources  
- **$6 – post‑update script** — cleans up any temporary changes introduced before or during the test

Example scripts and the files required to run integration tests can be found in the `./examples` directory.

### Complete Test Execution

To run the full integration test suite automatically, use the `run_tests.sh` script.  
After setting the required environment variables, this script sequentially executes all defined tests by invoking `upgrade.sh` with the appropriate parameters.
