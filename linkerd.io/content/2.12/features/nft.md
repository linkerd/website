---
title: Proxy Init Iptables Modes
description: Linkerd's init container can run in two separate modes, nft or legacy.
---

To transparently route TCP traffic through the proxy, without any awareness
from the application, Linkerd will configure a set of [firewall
rules](../../reference/iptables/) in each injected pod. Configuration can be
done either through an [init
container](../../reference/architecture/#linkerd-init-container) or through a
[CNI plugin](../cni/)

Linkerd's init container can be run in two separate modes: `legacy` or `nft`.
The difference between the two modes is what variant of `iptables` they will use
to configure firewall rules.

## Details

Modes for the init container can be changed either at upgrade time, or during
installation. Once configured, all injected workloads (including the control
plane) will use the same mode in the init container. Both modes will use the
`iptables` utility to configure firewall rules; the main difference between the
two, is which binary they will call into:

1. `legacy` mode will call into [`iptables-legacy`] for firewall configuration.
   This is the default mode that `linkerd-init` runs in, and is supported by
   most operating systems and distributions.
2. `nft` mode will call into `iptables-nft`, which uses the newer `nf_tables`
   kernel API. The [`nftables`] utilities are used by newer operating systems to
   configure firewalls by default.

[`iptables-legacy`]: https://manpages.debian.org/bullseye/iptables/iptables-legacy.8.en.html
Conceptually, `iptables-nft` is a bridge between the legacy and the newer
`nftables` utilities. Under the hood, it uses a different backend, where rules
additions and deletions are atomic. The nft version of iptables uses the same
packet matching syntax (xtables) as its legacy counterpart.

Because both utilities use the same syntax, it is recommended to run in
whatever mode your Kubernetes hosts support best. Certain operating systems
(e.g Google Container Optimized OS) do not offer support out-of-the-box for
`nftables` modules. Others (e.g RHEL family of operating systems) do not
support the legacy version of iptables. Linkerd's init container should be run
in `nft` mode only if the nodes support it and contain the relevant nftables
modules.

{{< note >}}
Linkerd supports a `-w` (wait) option for its init container. Because
operations are atomic, and rulesets are not reloaded when modified (only
appended),this option is a no-op when running `linkerd-init` in nft mode.
{{< /note >}}

## Installation

The mode for `linkerd-init` can be overridden through the configuration option
`proxyInit.iptablesMode=iptables|nft`. The configuration option can be used for
both Helm and CLI installations (or upgrades). For example, the following line
will install Linkerd and set the init container mode to `nft`:

```bash
linkerd install --set "proxyInit.iptablesMode=nft" | kubectl apply -f -
```
