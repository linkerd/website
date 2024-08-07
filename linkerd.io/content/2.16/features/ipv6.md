+++
title = "IPv6 Support"
description = "Linkerd is compatible with both IPv6-only and dual-stack clusters."
+++

As of version 2.16 (and edge-24.8.2) Linkerd fully supports Kubernetes clusters
configured for IPv6-only or dual-stack networking.

This is disabled by default; to enable just set `proxy.disableIPv6=false` when
installing the control plane and, if you use it, the linkerd-cni plugin.

Enabling IPv6 support does not generally change how Linkerd operates, except in
one way: when enabled on a dual-stack cluster, Linkerd will only use the IPv6
endpoints of destinations and will not use the IPv4 endpoints.
