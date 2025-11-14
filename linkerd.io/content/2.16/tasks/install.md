---
title: Installing Linkerd
description: Install Linkerd onto your Kubernetes cluster.
---

Before you can use Linkerd, you'll need to install the
[control plane](../reference/architecture/#control-plane). This page covers how
to accomplish that.

{{< note >}}

The Linkerd project itself only produces [edge release](/releases/) artifacts.
(For more information about the different kinds of Linkerd releases, see the
[Releases and Versions](/releases/) page.)

As such, this page contains instructions for installing the latest edge release
of Linkerd. If you are using a [stable distribution](/releases/#recent-versions)
of Linkerd, the vendor should provide additional guidance on installing Linkerd.

{{< /note >}}

Linkerd's control plane can be installed in two ways: with the CLI and with
Helm. The CLI is convenient and easy, but for production use cases we recommend
Helm which allows for repeatability.

In either case, we recommend installing the CLI itself so that you can validate
the success of the installation. See the
[Getting Started Guide](../getting-started/) for how to install the CLI if you
haven't done this already.

## Requirements

Linkerd requires a Kubernetes cluster on which to run. Where this cluster lives
is not important: it might be hosted on a cloud provider, may be running on your
local machine, or even somewhere else.

Make sure that your Linkerd version and Kubernetes version are compatible by
checking Linkerd's [supported Kubernetes versions](../reference/k8s-versions/).

Before installing the control plane, validate that this Kubernetes cluster is
configured appropriately for Linkerd by running:

```bash
linkerd check --pre
```

Be sure to address any issues that the checks identify before proceeding.

{{< note >}}

If installing Linkerd on GKE, there are some extra steps required depending on
how your cluster has been configured. If you are using any of these features,
check out the additional instructions on
[GKE private clusters](../reference/cluster-configuration/#private-clusters)

{{< /note >}}

{{< note >}}

If installing Linkerd in a cluster that uses Cilium in kube-proxy replacement
mode, additional steps may be needed to ensure service discovery works as
intended. Instrunctions are on the
[Cilium cluster configuration](../reference/cluster-configuration/#cilium) page.

{{< /note >}}

## Installing with the CLI

Once you have a cluster ready, installing Linkerd is as easy as running
`linkerd install --crds`, which installs the Linkerd CRDs, followed by
`linkerd install`, which installs the Linkerd control plane. Both of these
commands generate Kubernetes manifests, which can be applied to your cluster to
install Linkerd.

For example:

```bash
# install the CRDs first
linkerd install --crds | kubectl apply -f -

# install the Linkerd control plane once the CRDs have been installed
linkerd install | kubectl apply -f -
```

This basic installation should work for most cases. However, there are some
configuration options are provided as flags for `install`. See the
[CLI reference documentation](../reference/cli/install/) for a complete list of
options. You can also use [tools like Kustomize](customize-install/) to
programmatically alter this manifest.

## Installing via Helm

To install Linkerd with Helm (recommended for production installations), see the
[Installing Linkerd with Helm](install-helm/).

## Verification

After installation (whether CLI or Helm) you can validate that Linkerd is in a
good state running:

```bash
linkerd check
```

## Next steps

Once you've installed the control plane, you may want to install some
extensions, such as `viz`, `multicluster` and `jaeger`. See
[Using extensions](extensions/) for how to install them.

Finally, once the control plane is installed, you'll need to "mesh" any services
you want Linkerd active for. See
[Adding your services to Linkerd](adding-your-service/) for how to do this.

## Uninstalling the control plane

See [Uninstalling Linkerd](uninstall/).
