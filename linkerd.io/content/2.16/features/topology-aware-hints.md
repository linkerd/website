+++
title = "Topology Aware Hints"
description = "Linkerd's implementation of Kubernetes topology aware hints enables endpoint consumption based on a node's zone label."
aliases = [
  "../topology-aware-hints/"
]
+++

Kubernetes clusters are increasingly deployed in multi-zone environments with
network traffic often relying on obscure endpoint matching and routing for a
given service. Linkerd's implementation of Kubernetes ([Topology Aware
Hints][topology aware hints]) provides users with a mechanism for asserting
more control over endpoint selection and routing within a cluster that spans
multiple zones. Users can now implement routing constraints and prefer
endpoints in a specific zone in order to limit cross-zone networking costs or
improve performance through lowered cross-zone latency and bandwidth
constraints.

The goal of topology aware hints is to to provide a simpler way for users to
prefer endpoints by basing decisions solely off the node's
`topology.kubernetes.io/zone` label. If a client is in `zone-a`, then it
should prefer endpoints marked for use by clients in `zone-a`. When the
feature is enabled and the label set, Linkerd's destination controller will
attempt to find endpoints whose `Hints.ForZones` field matches the client's
zone.

{{< note >}}

If you're using a [stable distribution](/releases/#stable) of Linkerd, it may
have additional features related to topology-aware routing (for example, <a
href="https://buoyant.io/linkerd-enterprise/">Buoyant Enterprise for
Linkerd</a> and its <a
href="https://docs.buoyant.io/buoyant-enterprise-linkerd/latest/features/hazl/">HAZL</a>
feature). You can find more information about the different kinds of Linkerd
releases on the [Releases and Versions](/releases/) page.

{{< /note >}}

To get started with topology aware hints take a look at the [enabling topology
aware hints](../../tasks/enabling-topology-aware-hints/) task documentation.

[topology aware hints]: https://kubernetes.io/docs/concepts/services-networking/topology-aware-hints/

{{< note >}}

Topology aware hints require that the cluster have the `TopologyAwareHints`
feature gate enabled, and that Linkerd's `endpointSlice` feature be turned on
(this is the default starting with Linkerd stable-2.12).

{{< /note >}}
