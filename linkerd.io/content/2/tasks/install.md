+++
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

### GKE

If installing Linkerd on GKE, there are some extra steps required depending on
how your cluster has been configured. If you are using any of these features,
check out the additional instructions.

- [Private clusters](/2/reference/cluster-configuration/#private-clusters)

## Installing

Once you have a cluster ready, generally speaking, installing Linkerd is as
easy as running `linkerd install` to generate a Kubernetes manifest, and
applying that to your cluster, for example, via

```bash
linkerd install | kubectl apply -f -
```

See [Getting Started](/2/getting-started/) for an example.

## Verification

After installation, you can validate that the installation was successful by
running:

```bash
linkerd check
```

## Uninstalling

See [Uninstalling Linkerd](/2/tasks/uninstall/).
