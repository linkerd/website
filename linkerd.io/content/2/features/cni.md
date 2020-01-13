+++
title = "Experimental: CNI Plugin"
description = "Linkerd can be configured to run a CNI plugin that rewrites each pod's iptables rules automatically."
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

### Using che CLI

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

This will set a `cniEnabled` flag in the global `linkerd-config` ConfigMap. All
subsequent proxy injections will read this field and omit init containers.

### Using Helm

Before you begin, you need to have TLS certificates. You can
provide your own, or follow [these instructions](/2/tasks/generate-certificates/)
to generate new ones.

```bash
# install the CNI plugin first
helm install --name=linkerd2-cni linkerd2/linkerd2-cni
# ensure the plugin is installed and ready
linkerd check --pre --linkerd-cni-enabled
```

At that point you are ready to install Linkerd with CNI enabled:

```bash
# set expiry date one year from now, on Mac:
exp=$(date -v+8760H +"%Y-%m-%dT%H:%M:%SZ")
# on Linux:
exp=$(date -d '+8760 hour' +"%Y-%m-%dT%H:%M:%SZ")

helm install \
  --name=linkerd2 \
  --set-file global.identityTrustAnchorsPEM=ca.crt \
  --set-file identity.issuer.tls.crtPEM=issuer.crt \
  --set-file identity.issuer.tls.keyPEM=issuer.key \
  --set identity.issuer.crtExpiry=$exp \
  --set global.noInitContainer=true \
  --set installNamespace=false \
  linkerd/linkerd2
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
