---
title: "Enabling Topology Aware Routing"
description: |-
  Enable topology aware routing to allow Linkerd to intelligently choose same-zone endpoints
---

[Topology aware routing](../features/topology-aware-routing/) allows
Linkerd users to specify endpoint selection boundaries when a request is made
against a service, making it possible to limit cross-zone endpoint selection
and lower the associated costs and latency.

{{< note >}}

If you're using a stable distribution of Linkerd, it may have additional
features related to topology-aware routing (for example, [Buoyant Enterprise for
Linkerd](https://buoyant.io/linkerd-enterprise/) and its
[HAZL](https://docs.buoyant.io/buoyant-enterprise-linkerd/latest/features/hazl/)
feature). You can find more information about the different kinds of Linkerd
releases on the [Releases and Versions](/releases/) page.

{{< /note >}}

There are four requirements to successfully enabling topology aware routing
with Linkerd:

1. The `TopologyAwareHints` feature gate MUST be enabled on the Kubernetes
   cluster. (This feature gate is enabled by default in Kubernetes 1.24 and
   later.)

2. Linkerd's `endpointSlice` feature MUST be turned on. (This is the default
   starting with Linkerd stable-2.12).

3. Each Kubernetes node needs to be assigned to a zone, using
   `"topology.kubernetes.io/zone` label.

4. Relevant Kubernetes services will need to be modified with the
   `service.kubernetes.io/topology-aware-hints=auto` annotation.

When Linkerd receives a set of endpoint slices and translates them to an
address set, a copy of the `Hints.forZones` field is made from each endpoint
slice if one is present. This field is only present if it's set by the
endpoint slice controller, and there are several
[safeguards][topology-aware-routing-safeguards] that Kubernetes checks before
setting it. To have the endpoint slice controller set the `forZones` field
users will have to add the `service.kubernetes.io/topology-aware-hints=auto`
annotation to the service.

After the endpoints have been translated into an address set and the endpoint
translator's available endpoints have been updated, filtering is applied to
ensure only the relevant sets of addresses are returned when a request is
made.

For each potential address in the available endpoint set Linkerd returns a set
of addresses whose consumption zone (zones in `forZones` field) matches that
of the node's zone. By doing so Linkerd ensures communication is limited to
endpoints that have been labeled by the endpoint slice controller for the same
node the client is on and limits cross-node and cross-zone communication.

## Constraints

Kubernetes places some [constraints][topology-aware-routing-constraints] on
topology aware routing that you should review before trying to enable topology
aware routing on Linkerd.

The main things to be aware of are:

- Topology aware routing assumes that traffic to a given zone will be roughly
  proportional to the capacity of the nodes in the zone. This can be a concern
  when using horizontal pod autoscaling, as HPA may start nodes in the "wrong"
  zone.

- Services with `internalTrafficPolicy` set to `Local` ignore topology aware
  routing, by design.

- If you have workloads running on Nodes labeled with `control-plane` or
  `master` role, topology aware routing will not route to endpoints on these
  Nodes.

## Configuring Topology Aware Routing

Successful topology aware routing can be confirmed by looking at the Linkerd
proxy logs for the relevant service. The logs should show a stream of messages
similar to the ones below:

```text {class=disable-copy}
time="2021-08-27T14:04:35Z" level=info msg="Establishing watch on endpoint [default/nginx-deploy-svc:80]" addr=":8086" component=endpoints-watcher
time="2021-08-27T14:04:35Z" level=debug msg="Filtering through addresses that should be consumed by zone zone-b" addr=":8086" component=endpoint-translator remote="127.0.0.1:49846" service="nginx-deploy-svc.default.svc.cluster.local:80"
```

[topology-aware-routing-safeguards]: https://kubernetes.io/docs/concepts/services-networking/topology-aware-hints/#safeguards
[topology-aware-routing-constraints]: https://kubernetes.io/docs/concepts/services-networking/topology-aware-hints/#constraints
