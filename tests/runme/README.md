# Getting Started with Linkerd using Runme

[![](https://badgen.net/badge/Open%20with/Runme/5B3ADF?icon=https://runme.dev/img/logo.svg)](https://www.runme.dev/api/runme?repository=https%3A%2F%2Fgithub.com%2Fstateful%2Flinkerd-website.git&fileToOpen=tests/runme/README.md)

This is an example README file powered by [Runme](https://runme.dev/).

Use the VS Code extension or the CLI to run the commands explained in this file.

## Installing your Kubernetes cluster

For this example, we will use the [Google Cloud Kubernetes  Engine (GKE)](https://cloud.google.com/kubernetes-engine). You can try the service for free.

If you are on Mac, you can install the required tools using brew.

```sh
brew install google-cloud-sdk linkerd
```

Alternatively, you can install the tool using curl

```sh
curl --proto '=https' --tlsv1.2 -sSfL https://run.linkerd.io/install | sh
```

Once you have the Google Cloud command line tool installed, use it to install **gke-gcloud-auth-plugin**, a Kubectl plugin that manages authentication between the client and GKE.

```sh
gcloud components install gke-gcloud-auth-plugin
```

Once the credential plugin is installed, you can authorize gcloud to access the Cloud Platform with your Google user credentials, triggering a web-based authorization flow.

```sh
gcloud auth login
```

### Non-interactive authorization

Authorizing without using a web browser is known as a non-interactive mode. You must create a service account with the appropriate scopes via the Google Cloud Console. [Learn more how to configure non-interactive mode](https://cloud.google.com/sdk/gcloud/reference/auth/login)

## Configuring your project

Explaining how to configure your cluster is out of scope of this guide, [Learn how to create your GKE cluster](https://cloud.google.com/kubernetes-engine/docs/how-to/private-clusters)

A Kubernetes cluster is created under a Google Cloud project. Let's ensure you have a project name where your Kubernetes cluster is deployed.

```sh { interactive=false }
export PROJECT_NAME=<YOUR PROJECT NAME>
```

Specify the project where your cluster was created

```sh
gcloud config set project $PROJECT_NAME
```

Set the project credentials of your Kubernetes cluster

Specify the compute zone for the cluster

```sh { interactive=false }
export CLUSTER_ZONE="us-central1-c"
```

```sh
$ export CLUSTER_NAME=<Name of your cluster>
$ gcloud container clusters get-credentials $CLUSTER_NAME --zone $CLUSTER_ZONE --project $PROJECT_NAME
```

## (Optional)

To monitor the created pods via Linkerd, you can use a tool like [watch](https://formulae.brew.sh/formula/watch) to see the output from the get pods command.

```sh
brew install watch
```

Monitor the created Kubernetes Cluster Pods.

```sh { background=true interactive=true terminalRows=25 }
watch -n 1 kubectl get pods -A
```

## Run the docs tests

One of the most interesting features of using Runme, is that you can test your README files by using it.

In this example, we will use [bats](https://github.com/bats-core/bats-core), a TAP-compliant automated testing system for bash.

You can install bats using Node.js or [Git Submodules](https://bats-core.readthedocs.io/en/stable/tutorial.html#quick-installation)

In this example, we use Node.js

The test file uses the following bats helpers:

- [Detik](https://github.com/bats-core/bats-detik) A set of utilities to execute end-to-end tests in Kubernetes clusters, it provides a set of assertions in a natural language, hiding complexities from advanced bash commands.
- [Bats support](https://github.com/bats-core/bats-support.git) A set of test helpers written for Bats.
- [bats-assert](https://github.com/bats-core/bats-assert.git) A helper library with common assertions for Bats.

Bats utilities work using git submodules. We have defined the above utilities in the **.gitmodules** file located at the root level of this project.

```sh
git submodule update --init
```

Now you have bats properly installed, let's run the [Linkerd getting started guide](../../linkerd.io//content/2.12/getting-started/_index.md) tests we have defined at [getting-started.bats](./getting-started.bats). Before do that, let's monitor the kube cluster's namespaces.

```sh { name=watch-linkerd background=true closeTerminalOnSuccess=true interactive=true terminalRows=25 }
kubectl get pods -A -w
```

```sh { name= closeTerminalOnSuccess=true interactive=true }
npx bats getting-started.bats
```
