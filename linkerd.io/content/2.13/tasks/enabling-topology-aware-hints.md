+++
title = "Enabling Topology Aware Hints"
description = "Enable topology aware hints to allow Linkerd to intelligently choose same-zone endpoints"
+++

[Topology aware hints](../features/topology-aware-hints/) allow Linkerd users to specify endpoint selection boundaries when a request is made against a service, making it possible to limit cross-zone endpoint selection and lower the associated costs and latency. 

There are three requirements to successfully enabling topology aware hints with Linkerd:

1. `TopologyAwareHints` feature gate MUST be enabled on the Kubernetes cluster.
2. Each Kubernetes node should be labeled with the `"topology.kubernetes.io/zone` label.
3. Relevant Kubernetes services will need to be modified with the `service.kubernetes.io/topology-aware-hints=auto` annotation.

When Linkerd receives a set of endpoint slices and translates them to an address set, a copy of the `Hints.forZones` field is made from each endpoint slice if one is present. This field is only present if it's set by the endpoint slice controller and comes with several ([safeguards][topology-aware-hints-safeguards]). To have the endpoint slice controller set the `forZones` field users will have to add the `service.kubernetes.io/topology-aware-hints=auto` annotation to the service.

After the endpoints have been translated into an address set and the endpoint translator's available endpoints have been updated, filtering is applied to ensure only the relevant sets of addresses are returned when a request is made.

For each potential address in the available endpoint set Linkerd returns a set of addresses whose consumption zone (zones in `forZones` field) matches that of the node's zone. By doing so Linkerd ensures communication is limited to endpoints that have been labeled by the endpoint slice controller for the same node the client is on and limits cross-node and cross-zone communication.


# Constraints

There are a few ([contraints][topology-aware-hints-constraints]) that should be considered and reviewed before enabling topology aware hints on Linkerd.    


The main things to be aware of are:

- Linkerd assumes that traffic to a given zone will be roughly proportional to the capacity of the nodes in the zone (which can be a concern when using horizontal pod autoscaling, as the HPA may start nodes in the "wrong" zone); and
- The Kubernetes endpoint slice controller does not take...

# Configuring Topology Aware Routing

Successful topology aware routing can be confirmed by looking at the Linkerd proxy logs for the relevant service. The logs should show a stream of messages similar to the ones below:

```
time="2021-08-27T14:04:35Z" level=info msg="Establishing watch on endpoint [default/nginx-deploy-svc:80]" addr=":8086" component=endpoints-watcher
time="2021-08-27T14:04:35Z" level=debug msg="Filtering through addresses that should be consumed by zone zone-b" addr=":8086" component=endpoint-translator remote="127.0.0.1:49846" service="nginx-deploy-svc.default.svc.cluster.local:80"
```


[topology-aware-hints-safeguards]: https://kubernetes.io/docs/concepts/services-networking/topology-aware-hints/#safeguards
[topology-aware-hints-constraints]: https://kubernetes.io/docs/concepts/services-networking/topology-aware-hints/#constraints