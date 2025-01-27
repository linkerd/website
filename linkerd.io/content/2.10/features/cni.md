---
title: CNI Plugin
description: Linkerd can be configured to run a CNI plugin that rewrites each pod's
  iptables rules automatically.
---

Linkerd installs can be configured to run a
[CNI plugin](https://github.com/containernetworking/cni) that rewrites each
pod's iptables rules automatically. Rewriting iptables is required for routing
network traffic through the pod's `linkerd-proxy` container. When the CNI plugin
is enabled, individual pods no longer need to include an init container that
requires the `NET_ADMIN` capability to perform rewriting. This can be useful in
clusters where that capability is restricted by cluster administrators.

## Installation

Usage of the Linkerd CNI plugin requires that the `linkerd-cni` DaemonSet be
successfully installed on your cluster _first_, before installing the Linkerd
control plane.

### Using the CLI

To install the `linkerd-cni` DaemonSet, run:

```bash
linkerd install-cni | kubectl apply -f -
```

Once the DaemonSet is up and running, all subsequent installs that include a
`linkerd-proxy` container (including the Linkerd control plane), no longer need
to include the `linkerd-init` container. Omission of the init container is
controlled by the `--linkerd-cni-enabled` flag at control plane install time.

Install the Linkerd control plane, with:

```bash
linkerd install --linkerd-cni-enabled | kubectl apply -f -
```

This will set a `cniEnabled` flag in the `linkerd-config` ConfigMap. All
subsequent proxy injections will read this field and omit init containers.

### Using Helm

First ensure that your Helm local cache is updated:

```bash
helm repo update

helm search linkerd2-cni
NAME                      CHART VERSION  APP VERSION    DESCRIPTION
linkerd-edge/linkerd2-cni   20.1.1       edge-20.1.1    A helm chart containing the resources needed by the Linke...
linkerd-stable/linkerd2-cni  2.7.0       stable-2.7.0   A helm chart containing the resources needed by the Linke...
```

Run the following commands to install the CNI DaemonSet:

```bash
# install the CNI plugin first
helm install linkerd2-cni linkerd2/linkerd2-cni

# ensure the plugin is installed and ready
linkerd check --pre --linkerd-cni-enabled
```

{{< note >}}
For Helm versions < v3, `--name` flag has to specifically be passed.
In Helm v3, It has been deprecated, and is the first argument as
 specified above.
{{< /note >}}

At that point you are ready to install Linkerd with CNI enabled.
You can follow [Installing Linkerd with Helm](../../tasks/install-helm/) to do so.

## Additional configuration

The `linkerd install-cni` command includes additional flags that you can use to
customize the installation. See `linkerd install-cni --help` for more
information. Note that many of the flags are similar to the flags that can be
used to configure the proxy when running `linkerd inject`. If you change a
default when running `linkerd install-cni`, you will want to ensure that you
make a corresponding change when running `linkerd inject`.

The most important flags are:

1. `--dest-cni-net-dir`: This is the directory on the node where the CNI
   Configuration resides. It defaults to: `/etc/cni/net.d`.
2. `--dest-cni-bin-dir`: This is the directory on the node where the CNI Plugin
   binaries reside. It defaults to: `/opt/cni/bin`.
3. `--cni-log-level`: Setting this to `debug` will allow more verbose logging.
   In order to view the CNI Plugin logs, you must be able to see the `kubelet`
   logs. One way to do this is to log onto the node and use
   `journalctl -t kubelet`. The string `linkerd-cni:` can be used as a search to
   find the plugin log output.

## Upgrading the CNI plugin

Since the CNI plugin is basically stateless, there is no need for a separate
`upgrade` command. If you are using the CLI to upgrade the CNI plugin you can
just do:

```bash
linkerd install-cni   | kubectl apply --prune -l  linkerd.io/cni-resource=true -f -
```

Keep in mind that if you are upgrading the plugin from an experimental version,
you need to uninstall and install it again.
