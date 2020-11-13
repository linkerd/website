+++
title = "Service Topology"
description = "Linkerd routes traffic using Kubernetes ServiceTopology resources."
aliases = [
  "/2/service-topology/"
]
+++

[Service Topology](https://kubernetes.io/docs/concepts/services-networking/service-topology/)
is a feature in Kubernetes that enables you to route traffic to pods running on
specific nodes within a cluster, based on the node topology. Starting with
version 2.9, Linkerd supports this feature by routing traffic based on the
`topologyKeys` configuration in a Service resource definition.

The Service Topology feature in Kubernetes is enabled by the
[EndpointSlices](https://kubernetes.io/docs/concepts/services-networking/endpoint-slices/)
which
is also supported in Linkerd 2.9 and higher.

{{< note >}} Service Topolgy is a feature gate that is _disabled_, by default,
starting in Kubernetes 1.17. Be sure to check the [Feature Gates](https://kubernetes.io/docs/reference/command-line-tools-reference/feature-gates/)
docs to find the latest information about this feature in order to use it in
your cluster.

Currently the `topologyKeys` configuration supports three node labels that can
be specified separately or together to create a set of rules for routing
traffic:

* kubernetes.io/hostname
* topology.kubernetes.io/region
* topology.kubernetes.io/zone

In addtion, `topologyKeys` accepts the fallback entry `"*"` to indicate that
nodes with _any_ values for the labels above are a match. This fallback
configuration ensures that the request is handled, regardless of the node
topology. For example, in the configuration below, Linkerd will attempt to route
traffic to a node with the same value for the `topology.kubernetes.io/region`
and if there is no match, it will still be handled by a pod on any node in the
cluster:

```yaml
apiVersion: v1
kind: Service
metadata:
  ...
  name: ServiceA
spec:
  ports:
  ...
  topologyKeys:
   - topology.kubernetes.io/region
   - "*"
```

Let's take a look at Service Topology using an example of a cluster with three
nodes. In the diagram below, the node labels are broken down as follows:

* `kubernetes.io/hostname` is unique for all nodes
* `topology.kubernetes.io/region` is set to `west` for nodes 1 and 2
* `topology.kubernetes.io/zone` is set to `eu` for nodes 2 and 3

{{< fig src="/images/service-topology/labels-example.png"
title="Service Topology Labels">}}

Now, assume that you have `ServiceA` and `ServiceB` Service resource
definitions with this `topologyKeys` configuration:

```yaml
apiVersion: v1
kind: Service
metadata:
  ...
  name: ServiceA # Or ServiceB
spec:
  ports:
  ...
  topologyKeys:
   - topology.kubernetes.io/region
```

When the Linkerd proxy handles a request from `ServiceA` to `ServiceB`, it uses
the service discovery information that it received from the [Linkerd destination](/2/reference/architecture/#destination)
control plane component to route traffic to a node that has the same value for
the `topology.kubernetes.io/region` label. As you recall from the diagram
above, nodes 1 and 2 have the value `west`, while node 3 is labeled with `east`.

Given the `topologyKeys` configuration, any `ServiceA` Pod on Node 1 or 2 for
which the Linkerd proxy handles the request will send that request to an
instance of `ServiceB` on Node 1 or 2, because the `topology.kubernetes.io/region`
value is the same for these nodes. On the other hand, `ServiceA` pods on Node 3
can only route requests to `ServiceB` pods which are _also_ on Node 3. If there
are no `ServiceB` pods on Node3, the request will not be routed, even if there
are `ServiceB` pods on Nodes 1 and/or 2.

## Further reading

* [Service Topology Documentation](https://kubernetes.io/docs/concepts/services-networking/service-topology/).
* [EndpointSlice Documentation](https://kubernetes.io/docs/concepts/services-networking/endpoint-slices/).
* [Getting Started with Service Topologies](/2/tasks/service-topologies/).
