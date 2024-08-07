+++
title = "IPv6 Support"
description = "Linkerd is compatible with both IPv6-only and dual-stack clusters."
+++

As of version 2.16 (and edge-24.8.2) Linkerd fully supports Kubernetes clusters
configured for IPv6-only or dual-stack networking.

## Benefits of IPv6

One of the most touted benefits of IPv6 is the larger address space, given the
ongoing exhaustion of public IPv4 addresses. In Kubernetes clusters you usually
make use of private subnets for your pods and services, so that hasn't been
really an issue.

The real benefits of IPv6 in this context deal more with things like increased
security, improved performance and generally a more modern stack that the
cluster network can benefit from.

Dual-stack networking on the other hand allows declaring services backed by both
IPv4 and IPv6 EndpointSlices (note that that the legacy Endpoints resources
don't support dual-stack). This becomes useful when you want to migrate your
services to IPv6 gradually, and thus require a mixed environment during the
transition.

## Kubernetes Providers Support

As of this writing these are the options provided by the major cloud providers
(included k3d and kind for local testing / CI):

{{< table >}}
| Provider | Dual-Stack Supported | IPv6-only Supported |
|----------|----------------------|---------------------|
|    AKS   |  :white_check_mark:  |        :x:          |
|    EKS   |         :x:          | :white_check_mark:  |
|    GKE   |  :white_check_mark:  |        :x:          |
|    Kind  |  :white_check_mark:  | :white_check_mark:  |
|    k3d   |         :x:          |        :x:          |
{{< /table >}} 


## Linkerd IPv6 Configuration

IPv6 support in Linkerd is disabled by default. To enable, just set
`proxy.disableIPv6=false`. This setting is to be applied to the control plane
and the linkerd-cni plugin, if used.

This mode doesn't make any difference in how Linkerd works. Bear in mind however
that when faced with a dual-stack service, the proxy will only forward traffic
to the endpoints in the IPv6 EndpointSlice.
