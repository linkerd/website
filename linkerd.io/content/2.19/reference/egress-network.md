---
title: EgressNetwork
description: Reference guide to the EgressNetwork resource.
---

Linkerd's [egress functionality](../features/egress) allows you to monitor and
control traffic that leaves the cluster. This behavior is controlled by creating
`EgressNetwork` resources, which describe the properties of traffic that leaves
a cluster and provide a way to apply policies to it, using Gateway API
primitives.

{{< warning >}}

No service mesh can provide a strong security guarantee about egress traffic by
itself; for example, a malicious actor could bypass the Linkerd sidecar - and
thus Linkerd's egress controls - entirely. Fully restricting egress traffic in
the presence of arbitrary applications thus typically requires a more
comprehensive approach.

{{< /warning >}}

## EgressNetwork semantics

An `EgressNetwork` is essentially a description for a set of traffic
destinations that reside outside the cluster. In that sense, it is comparable to
a Service, with the main difference being that a Service encompasses a single
logical destination while an `EgressNetwork` can encompass a set of
destinations. This set can vary in size - from a single IP address to the entire
network space that is not within the boundaries of the cluster.

An `EgressNetwork` resource by default has several namespace semantics that are
worth outlining. EgressNetworks are namespaced resources, which means that they
affect only clients within the namespace that they reside in. The only exception
is EgressNetworks created in the global egress namespace: these EgressNetworks
affect clients in all namespaces. The namespace-local resources take priority.
By default the global egress namespace is set to `linkerd-egress`, but can be
configured by setting the `egress.globalEgressNetworkNamespace` Helm value.

## EgressNetwork Spec

An `EgressNetwork` spec may contain the following top level fields:

{{< keyval >}}

| field           | value                                                                                                           |
| --------------- | --------------------------------------------------------------------------------------------------------------- |
| `networks`      | A set of [network specifications](#networks) that describe the address space that this `EgressNetwork` captures |
| `trafficPolicy` | the default [traffic policy](#trafficpolicy) for this resource.                                                 |

{{< /keyval >}}

### networks

This field is used to concretely describe the set of outside networks that this
network captures. All traffic to these destinations will be considered as
flowing to this `EgressNetwork` and subject to its traffic policy. If an
`EgressNetwork` does not specify any `networks`, the `EgressNetwork` captures
the entire IP address space except for the in-cluster networks specified by the
`clusterNetworks` value provided when Linkerd was installed.

{{< keyval >}}

| field    | value                                          |
| -------- | ---------------------------------------------- |
| `cidr`   | A subnet in CIDR notation.                     |
| `except` | A list of subnets in CIDR notation to exclude. |

{{< /keyval >}}

### trafficPolicy

This field is required and must be either `Allow` or `Deny`. If `trafficPolicy`
is set to `Allow`, all traffic through this EgressNetwork will be let through
even if there is no explicit Gateway API Route that describes it. If
`trafficPolicy` is set to `Deny`, traffic through this `EgressNetwork` that is
not explicitly matched by a Route will be refused.

## Example

Below is an example of an `EgressNetwork` resource that will block all external
traffic except HTTPS traffic to httpbin.org on port 443. The later is done via
an explicit TLSRoute.

```yaml
apiVersion: policy.linkerd.io/v1alpha1
kind: EgressNetwork
metadata:
  namespace: linkerd-egress
  name: all-egress-traffic
spec:
  trafficPolicy: Deny
---
apiVersion: gateway.networking.k8s.io/v1alpha2
kind: TLSRoute
metadata:
  name: tls-egress
  namespace: linkerd-egress
spec:
  hostnames:
    - httpbin.org
  parentRefs:
    - name: all-egress-traffic
      kind: EgressNetwork
      group: policy.linkerd.io
      namespace: linkerd-egress
      port: 443
  rules:
    - backendRefs:
        - kind: EgressNetwork
          group: policy.linkerd.io
          name: all-egress-traffic
```
