---
runme:
  id: 01HMEDQ5EDVTJ86JY71BM9TW6N
  version: v2.2
---

# Running Linkerd Getting Started Guide in CI

[![](https://badgen.net/badge/Open%20with/Runme/5B3ADF?icon=https://runme.dev/img/logo.svg)](https://www.runme.dev/api/runme?repository=git%40github.com%3Astateful%2Flinkerd-website.git&fileToOpen=tests/runme/README.md)

For a better experience reading this file, we recommend opening it with [Runme](https://runme.dev/).

The following guide explains how to run tests from the Linkerd getting started guide using [Runme CLI](https://runme.dev/) on GKE.
**Runme** is a powerful tool that makes Markdown files runnable.
The CLI will run as part of a GitHub Action.

## Configuring Google Cloud Kubernetes cluster

This guide assumes you already have a [Google Cloud Kubernetes Engine (GKE)](https://cloud.google.com/kubernetes-engine) cluster configured.

### Authenticate to Google Cloud

The recommended approach is to use [Workload Identity Federation](https://cloud.google.com/iam/docs/workload-identity-federation)
This approach is more secure than using **Service Account Key JSON** since you don't have to think about secret management and the inherited risks (e.g. leaked credentials), having this mechanism disabled is a standard security best practice across organizations.

Learn more about [Keyless authentication from GitHub Actions](https://cloud.google.com/blog/products/identity-security/enabling-keyless-authentication-from-github-actions)

Ensure you have correctly configured a Workload Identity Federation by creating a Workload Identity Pool and Workload Identity Provider.

Before running the following commands, check that IAM API is enabled for [creating service accounts](https://console.cloud.google.com/flows/enableapi?apiid=iam.googleapis.com&redirect=https://console.cloud.google.com).

Set your project

```sh {"id":"01HMEFXZ3GB4QXDQX9B04EVZBY"}
export PROJECT_ID=<Your Project Id>
export POOL_DISPLAY_NAME=<Your pool display name>
export POOL_NAME=<Your pool name>
export PROVIDER_NAME=<Your provider name>
export PROVIDER_DISPLAY_NAME=<Your provider display name>
```

Create a Workload Identity Pool

```sh {"id":"01HMEFXZ3GB4QXDQX9B211B8ZR"}
gcloud iam workload-identity-pools create "my-pool" \
  --project="${PROJECT_ID}" \
  --location="global" \
  --display-name="${POOL_DISPLAY_NAME}"
```

Create a Workload Identity Provider

```sh {"id":"01HMEFXZ3GB4QXDQX9B5R584Y2"}
gcloud iam workload-identity-pools providers create-oidc "${PROVIDER_NAME}" \
  --project="${PROJECT_ID}" \
  --location="global" \
  --workload-identity-pool="${POOL_NAME}" \
  --display-name="${PROVIDER_DISPLAY_NAME}" \
  --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.aud=assertion.aud" \
  --issuer-uri="https://token.actions.githubusercontent.com"
```

Allow authentications from the Workload Identity Provider to impersonate the desired Service Account:

```sh {"id":"01HMEFXZ3GB4QXDQX9B637F9X0"}
gcloud iam service-accounts add-iam-policy-binding "my-service-account@${PROJECT_ID}.iam.gserviceaccount.com" \
  --project="${PROJECT_ID}" \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/projects/1234567890/locations/global/workloadIdentityPools/my-pool/attribute.repository/my-org/my-repo"
```

Check the created identity pools by running the following command:

```sh {"id":"01HMEFXZ3GB4QXDQX9BA08Q324"}
gcloud iam workload-identity-pools list --location="global"
```

Now you have your cluster configured properly, configure the following GitHub Action Environment Variables (they are not secrets):

```text {"id":"01HMEFXZ3GB4QXDQX9BCRYAGBM","mimeType":"text/plain"}
- GCLOUD_WORKLOAD_IDENTITY_PROVIDER: "projects/<project-id>/locations/global/workloadIdentityPools/<pool-name>/providers/<provider-name>"
- GCLOUD_SERVICE_ACCOUNT: "<name>@<project-name>.iam.gserviceaccount.com"
- CLUSTER_LOCATION: "<cluster-location>" e.g us-central1-c
- CLUSTER_NAME: "<YOUR CLUSTER NAME>"
- RUNME_ADDRESS: localhost:7863
```

## Authenticate in Google Cloud GitHub Action

Use [google-github-actions/auth@v1](https://github.com/google-github-actions/auth) for authenticating in Google Cloud from your GitHub Action.

```yaml {"id":"01HMEFXZ3GB4QXDQX9BDFQDFZ8","mimeType":"text/x-yaml"}
- id: 'gcloud-auth'
 name: 'Authenticate to Google Cloud'
 uses: 'google-github-actions/auth@v1'
 with:
   workload_identity_provider: ${{ vars.GCLOUD_WORKLOAD_IDENTITY_PROVIDER }}
   service_account: ${{ vars.GCLOUD_SERVICE_ACCOUNT }}
```

### Allow the CI to interact with the Kubernetes Cluster

Use [google-github-actions/get-gke-credentials@v1](https://github.com/google-github-actions/get-gke-credentials)

```yaml {"id":"01HMEFXZ3HKTAES5RXW7DA0GFF","mimeType":"text/x-yaml"}
- id: 'get-credentials'
 uses: 'google-github-actions/get-gke-credentials@v1'
 with:
    cluster_name: ${{ vars.CLUSTER_NAME }}
    location: ${{ vars.CLUSTER_LOCATION }}
```

### Setup kubectl

Linkerd requires [kubectl](https://kubernetes.io/docs/tasks/tools/), the Kubernetes command line tool. Microsoft provides a GitHub Action for installing it via [azure/setup-kubectl@v3](https://github.com/Azure/setup-kubectl)

```yaml {"id":"01HMEFXZ3HKTAES5RXWAAS2YT5","mimeType":"text/x-yaml"}
- uses: azure/setup-kubectl@v3
 with:
 version: 'latest'
```

If you want to ensure Kubectl is correctly installed in your GitHub Action, you can add the following step:

```yaml {"id":"01HMEFXZ3HKTAES5RXWB12PQS4","mimeType":"text/x-yaml"}
- name: Check kubectl version
  run: |
    kubectl version --short
```

### Install Linkerd

You can install Linkerd via CURL, and add it to the PATH, so the binary is available for other steps.

```yaml {"id":"01HMEFXZ3HKTAES5RXWBEXGBFJ","mimeType":"text/x-yaml"}
- name: Install Linkerd
  run: |
     curl --proto '=https' --tlsv1.2 -sSfL https://run.linkerd.io/install | sh
- name: Add Linkerd to PATH
  run: |
    echo "$PATH:/home/runner/.linkerd2/bin" >> $GITHUB_PATH

- name: Validate Linkerd install
  run: linkerd version
```

### Install Runme

The Runme CLI can be installed via **go install**

```yaml {"id":"01HMEFXZ3HKTAES5RXWCX8MF7Y","mimeType":"text/x-yaml"}
- uses: actions/setup-go@v3
  with:
   go-version: '>=1.17.0'
   - run: go version          
   - name: Install runme
     run: |
        go install github.com/stateful/runme@latest
```

You can check the Runme version and is installed adequately via the following action:

```yaml {"id":"01HMEFXZ3HKTAES5RXWGQ97NEY","mimeType":"text/x-yaml"}
- name: Check runme
  run: |
    runme --version
```

### Start Runme Server

```yaml {"id":"01HMEFXZ3HKTAES5RXWGW1G2YP","mimeType":"text/x-yaml"}
- name: Start Runme Server
  run: |
    runme server --address ${{ vars.RUNME_ADDRESS }} --runner &
```

### Run Tests

Linkerd getting started guide tests are run via Bats. Its Usage is well explained in our [testing guide](./README.md)

```yaml {"id":"01HMEFXZ3HKTAES5RXWHXFD2G2","mimeType":"text/x-yaml"}
- name: 'Initialize Git submodules'
    run: |
      git submodule update --init
                
- name: 'Run bats tests'
    env:
     NO_COLOR: true
     FROM_CI: true
     RUNME_SERVER_ADDR: ${{ vars.RUNME_ADDRESS }}
     run: |
        npx bats $GITHUB_WORKSPACE/tests/runme/getting-started.bats
```

The test file requires the following environment variables:

- __NO_COLOR: true__ Prevent side effects from the test assertions by disabling ANSI Colors in the terminal output
- __FROM_CI: true__ Used to indicate the tests are being run from the GitHub Action
- __RUNME_SERVER_ADDR__: The Runme server address, usually localhost:7863

In the previous example, we're using Node.js to install Bats, if that's your case too, ensure your action installs it too:

```yaml {"id":"01HMEFXZ3HKTAES5RXWJR1D95P","mimeType":"text/x-yaml"}
- uses: actions/setup-node@v3
    with:
      node-version: 18
```
