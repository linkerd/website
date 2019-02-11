+++
date = "2018-07-31T12:00:00-07:00"
title = "Experimental: CNI Plugin"
aliases = [
  "/2/cni-plugin/"
]
[menu.l5d2docs]
  name = "Experimental: CNI Plugin"
  parent = "Features"
+++

Linkerd installs can be configured to run a
[CNI plugin](https://github.com/containernetworking/cni) that rewrites each
pod's iptables rules automatically. Rewriting iptables is required for routing
network traffic through the pod's `linkerd-proxy` container. When the CNI plugin
is enabled, individual pods no longer need to include an init container that
requires the `NET_ADMIN` capability to perform rewriting. This can be useful in
clusters where that capability is restricted by cluster administrators.

This feature is currently **experimental**, as it has not been tested on most
major cloud providers. Follow
[this issue](https://github.com/linkerd/linkerd2/issues/2174) for status
updates.

## Installation

Usage of the Linkerd CNI plugin requires that the `linkerd-cni` DaemonSet be
successfully installed on your cluster _first_, before installing the Linkerd
control plane.

To install the `linkerd-cni` DaemonSet, run:

```bash
linkerd install-cni | kubectl apply -f -
```

Once the DaemonSet is up and running, all subsequent installs that include a
`linkerd-proxy` container (including the Linkerd control plane), no longer need
to include the `linkerd-init` container. Omission of the init container is
controlled by the `--linkerd-cni-enabled` flag.

Install the Linkerd control plane, with:

```bash
linkerd install --linkerd-cni-enabled | kubectl apply -f -
```

After the control plane is ready, inject the Linkerd data plane into additional
deployments, with:

```bash
linkerd inject --linkerd-cni-enabled deployment.yaml | kubectl apply -f -
```

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
