+++
title = "Installing Linkerd"
description = "Install Linkerd to your own Kubernetes cluster."
aliases = [
  "../upgrading/",
  "../installing/",
  "../rbac/"
]
+++

Before you can use Linkerd, you'll need to install the [control
plane](../../reference/architecture/#control-plane). This page covers how to
accomplish that.

Linkerd can be installed in two ways: with the CLI and with Helm. The CLI is
convenient and easy, but for production use cases we recommend Helm which allows
for repeatability.

(If you're using the CLI, see the [Getting Started
Guide](../../getting-started/) for how to install the CLI onto your local
environment.)

Once you've installed the control plane, you may want to install additional
which add additional features i.e `viz`, `multicluster` and `jaeger`. See
[Extensions](../extensions/) to understand how to install them.

Finally, once the control plane is installed, you'll need to "mesh" any services
you want Linkerd active for. See [Adding Your Services to
Linkerd](../../adding-your-service/) for how to do this.

## Requirements

Linkerd requires a functioning Kubernetes cluster on which to run. This cluster
may be hosted on a cloud provider or may be running locally via Minikube or
Docker for Desktop.

You can validate that this Kubernetes cluster is configured appropriately for
Linkerd by running

```bash
linkerd check --pre
```

{{< note >}}
If installing Linkerd on GKE, there are some extra steps required depending on
how your cluster has been configured. If you are using any of these features,
check out the additional instructions on [GKE private
clusters](../../reference/cluster-configuration/#private-clusters)
{{< /note >}}

## Installing with the CLI

Once you have a cluster ready, generally speaking, installing Linkerd is as
easy as running `linkerd install` to generate a Kubernetes manifest, and
applying that to your cluster, for example, via

```bash
linkerd install | kubectl apply -f -
```

This basic installation should work for most cases, However, there are some
configuration options are provided as flags for `install`. See the [reference
documentation](../../reference/cli/install/) for a complete list of options. To
do configuration that is not part of the `install` command, see how you can
create a [customized install](../customize-install/).

## Installing via Helm

To install Linkerd with Helm (recommended for production installations),
see the [Linkerd Helm Guide](../install-helm/)

## Verification

After installation (whether CLI or Helm) you can validate that Linkerd is in a
good state running:

```bash
linkerd check
```

## Uninstalling

See [Uninstalling Linkerd](../uninstall/).
