---
title: Topology Aware Routing
description: |-
  Linkerd's implementation of Kubernetes topology aware routing enables endpoint consumption based on a node's zone label.
---

Kubernetes clusters are increasingly deployed in multi-zone environments with
network traffic often relying on obscure endpoint matching and routing for a
given service. Linkerd's implementation of Kubernetes ([Topology Aware
Routing][topology aware routing]) provides users with a mechanism for
asserting more control over endpoint selection and routing within a cluster
that spans multiple zones. Users can now implement routing constraints and
prefer endpoints in a specific zone in order to limit cross-zone networking
costs or improve performance through lowered cross-zone latency and bandwidth
constraints.

The goal of topology aware routing is to to provide a simpler way for users to
prefer endpoints by basing decisions solely off the node's
`topology.kubernetes.io/zone` label. If a client is in `zone-a`, then it
should prefer endpoints marked for use by clients in `zone-a`. When the
feature is enabled and the label set, Linkerd's destination controller will
attempt to find endpoints whose `routing.ForZones` field matches the client's
zone.

(Topology aware routing is distinct from the `trafficDistribution` feature
that appears in Kubernetes 1.31. `trafficDistribution` is not yet supported by
Linkerd.)

{{< note >}}

If you're using a stable distribution of Linkerd, it may have additional
features related to topology-aware routing (for example, <a
href="https://buoyant.io/linkerd-enterprise/">Buoyant Enterprise for
Linkerd</a> and its <a
href="https://docs.buoyant.io/buoyant-enterprise-linkerd/latest/features/hazl/">HAZL</a>
feature). You can find more information about the different kinds of Linkerd
releases on the [Releases and Versions](/releases/) page.

{{< /note >}}

To get started with topology aware routing take a look at the [enabling
topology aware routing](../../tasks/enabling-topology-aware-routing/) task
documentation.

[topology aware routing]:
    https://kubernetes.io/docs/concepts/services-networking/topology-aware-routing/
