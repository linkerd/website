+++
date = "2018-09-17T08:00:00-07:00"
title = "Installing Linkerd"
description = "Install Linkerd to your own Kubernetes cluster."
aliases = [
  "/2/upgrading/",
  "/2/installing/",
  "/2/rbac/"
]
+++

Before you can use Linkerd, you'll need to install the
[control plane](/2/reference/architecture/#control-plane). This page
covers how to accomplish that, as well as common problems that you may
encounter.

Note that the control plane is typically installed by using Linkerd's CLI. See
[Getting Started](/2/getting-started/) for how to install the CLI onto your local
environment.

Note also that, once the control plane is installed, you'll need to "mesh" any
services you want Linkerd active for. See
[Adding Your Service](/2/adding-your-service/) for how to add Linkerd's data
plane to your services.

## Requirements

Linkerd 2.x requires a functioning Kubernetes cluster on which to run. This
cluster may be hosted on a cloud provider or may be running locally via
Minikube or Docker for Desktop.

You can validate that this Kubernetes cluster is configured appropriately for
Linkerd by running

```bash
linkerd check --pre
```

Once you have a cluster ready, generally speaking, installing Linkerd is as
easy as running `linkerd install` to generate a Kubernetes manifest, and
applying that to your cluster, for example, via

```bash
linkerd install | kubectl apply -f -
```

See [Getting Started](/2/getting-started/) for an example.

Finally, after control plane installation, the `linkerd check` command (without
`--pre`) may be used to validate that the installation was successful.

Below we go through some common issues that may prevent successful
installation.

## Google Kubernetes Engine (GKE) clusters with RBAC enabled {#gke}

If you are using GKE with RBAC enabled, you first need to grant a `ClusterRole`
of `cluster-admin` to your Google Cloud account first. This will provide your
current user all the permissions required to install the control plane. To bind
this `ClusterRole` to your user, you can run:

```bash
kubectl create clusterrolebinding cluster-admin-binding-$USER \
    --clusterrole=cluster-admin --user=$(gcloud config get-value account)
```

## Uninstalling

See [Uninstalling Linkerd](/2/tasks/uninstall/).
