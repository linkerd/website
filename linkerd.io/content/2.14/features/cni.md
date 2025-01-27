---
title: CNI Plugin
description: Linkerd can optionally use a CNI plugin instead of an init-container
  to avoid NET_ADMIN capabilities.
---

Linkerd's data plane works by transparently routing all TCP traffic to and from
every meshed pod to its proxy. (See the
[Architecture](../../reference/architecture/) doc.) This allows Linkerd to act
without the application being aware.

By default, this rewiring is done with an [Init
Container](../../reference/architecture/#linkerd-init-container) that uses
iptables to install routing rules for the pod, at pod startup time. However,
this requires the `CAP_NET_ADMIN` capability; and in some clusters, this
capability is not granted to pods.

To handle this, Linkerd can optionally run these iptables rules in a [CNI
plugin](https://kubernetes.io/docs/concepts/extend-kubernetes/compute-storage-net/network-plugins/)
rather than in an Init Container. This avoids the need for a `CAP_NET_ADMIN`
capability.

{{< note >}}
Linkerd's CNI plugin is designed to run in conjunction with your existing CNI
plugin, using _CNI chaining_. It handles only the Linkerd-specific
configuration and does not replace the need for a CNI plugin.
{{< /note >}}

## Installation

Usage of the Linkerd CNI plugin requires that the `linkerd-cni` DaemonSet be
successfully installed on your cluster _first_, before installing the Linkerd
control plane.

### Using the CLI

To install the `linkerd-cni` DaemonSet, run:

```bash
linkerd install-cni | kubectl apply -f -
```

Once the DaemonSet is up and running, meshed pods should no longer use the
`linkerd-init` Init Container. To accomplish this, use the
`--linkerd-cni-enabled` flag when installing the control plane:

```bash
linkerd install --linkerd-cni-enabled | kubectl apply -f -
```

Using this option will set a `cniEnabled` flag in the `linkerd-config`
ConfigMap. Proxy injections will read this field and omit the `linkerd-init`
Init Container.

### Using Helm

First ensure that your Helm local cache is updated:

```bash
helm repo update
helm search repo linkerd2-cni
```

Install the CNI DaemonSet:

```bash
# install the CNI plugin first
helm install linkerd-cni -n linkerd-cni --create-namespace linkerd/linkerd2-cni

# ensure the plugin is installed and ready
linkerd check --pre --linkerd-cni-enabled
```

At that point you are ready to install Linkerd with CNI enabled.  Follow the
[Installing Linkerd with Helm](../../tasks/install-helm/) instructions.

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

### Allowing initContainer networking

When using the Linkerd CNI plugin the required `iptables` rules are in effect
before the pod is scheduled. Also, the `linkerd-proxy` is not started until
after all `initContainers` have completed. This means no `initContainer` will
have network access because its packets will be caught by `iptables` and the
`linkerd-proxy` will not yet be available.

It is possible to bypass these `iptables` rules by running the `initContainer`
as the UID of the proxy (by default `2102`). Processes run as this UID are
skipped by `iptables` and allow direct network connectivity. These network
connections are not meshed.

The following is a snippet for an `initContainer` configured to allow unmeshed
networking while using the CNI plugin:

```yaml
initContainers:
- name: example
  image: example
  securityContext:
    runAsUser: 2102 # Allows skipping iptables rules
```

## Upgrading the CNI plugin

Since the CNI plugin is basically stateless, there is no need for a separate
`upgrade` command. If you are using the CLI to upgrade the CNI plugin you can
just do:

```bash
linkerd install-cni | kubectl apply --prune -l linkerd.io/cni-resource=true -f -
```
