+++
title = "Topology Aware Hints"
description = "Linkerd's implementation of Kubernetes topology aware hints enables endpoint consumption based on a node's zone label."
aliases = [
  "../topology-aware-hints/"
]
+++

Kuberentes clusters are increasingly deployed in multi-zone environments with network traffic often relying on obscured endpoint matching and routing for a given service. Linkerd's implementation of Kubernetes ([Topology Aware Hints][topology aware hints]) provides users with a mechanism for asserting more control over endpoint selection and routing within a distributed cluster. Users can now implement routing constraints and prefer endpoints in a specific zone in order to limit cross-zone networking costs or improve performance through lowered cross-zone latency and bandwidth constraints. 

The goal of topology aware hints is to to provide a simpler way for users to prefer endpoints by basing decisions soely off the node's `topology.kubernetes.io/zone` label. If a node is in zone-a, then it should prefer endpoints that should be consumed by clients in zone-a. When the feature is enabled and the label set, Linkerd's destination controller will serve endpoints that match the endpoint's `Hints.ForZones` field with the zone value that matches that of the requesting client.

{{< note >}}

Topology aware hints require Linkerd `endpointSlice` feature to be turned on (enabled by default starting with Linkerd stable-2.12.x) along with the `TopologyAwareHints` feature gate which MUST be enabled in the Kubernetes cluster.

{{< /note >}}

To get started with topology aware hints take a look at the [enabling topology aware hints](../tasks/enabling-topology-aware-hints/) task documentation.

[topology aware hints]: https://kubernetes.io/docs/concepts/services-networking/topology-aware-hints/