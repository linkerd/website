---
title: EgressNetwork
---

Linkerd's [egress functionality]({{< relref "../features/egress">}}) allows
you to monitor and control traffic that leaves the cluster. This behavior is
controller by an `EgressNetwork` resource which is used Linkerd to describe
the properties of traffic that leaves a cluster and apply policies to it, using
Gateway API primitives.

## EgressNetwork semantics

An `EgressNetwork` is essentially a description for a set of traffic
destinations that reside outside the cluster. In that sense, it is comparable
to a Service, with the main difference being that a Service encompasses a single
logical destination while an `EgressNetwork` can encompass a set of
destinations. This set can vary in size - from a single ip address to the entire
network space that is not within the boundaries of the cluster.

An `EgressNetwork` resource by default has several namespace semantics that are
worth outlining. Egress networks are namespace local, which means that they
affect only clients within the namespace that they reside in. The only exception
is egress networks created in the global egress namespace. These resources
affect clients in all namespaces. The namespace-local resources take priority.
By default the global egress namespace is set to `linkerd-egress`, but can be
configured by setting the `Values.egress.globalEgressNetworkNamespace` Helm
value.

## EgressNetwork Spec

An `EgressNetwork` spec may contain the following top level fields:

{{< keyval >}}

| field| value |
|------|-------|
| `networks`| A set of [Network](#networks) that describe the address space that this `EgressNetwork` captures|
| `trafficPolicy`| the default [TrafficPolicy](#trafficpolicy) policy for this resource.|
{{< /keyval >}}

### networks

This field is used to concretely describe the set of outside networks that this
network captures. All traffic to these destinations will be considered as
flowing to this `EgressNetwork` and the respective policies will be applied.
In case an `EgressNetwork` does not this field, the default that is used if a
single network that captures the entire ip address space bu excludes all
in-cluster networks as specified by `Values.clusterNetworks`.

{{< keyval >}}

| field| value |
|------|-------|
| `cidr`| A subnet in CIDR notation.|
| `except`| A list of subnets in CIDR notation to exclude.|
{{< /keyval >}}

### trafficPolicy

This field is required and could be either `Allow` or `Deny`. In the case of an
`Allow` all traffic will be let through even if there is no explicit Gateway
API Route that describes it. If the policy is set to `Deny` all traffic that is
captured by the `EgressNetwork` needs to be explicitly matched by a route
resource.

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
