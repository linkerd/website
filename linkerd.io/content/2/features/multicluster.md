+++
title = "Multicluster"
description = "Linkerd connects applications running in different clusters"
+++

There are many challenges to building an effective multicluster Kubernetes
architecture, including configuration, monitoring, deployment, and traffic
management. Of these challenges, we see a service mesh as able to directly
address three specific areas:

- Observability: a service mesh can provide a unified view of application
  behavior that spans clusters.
- Security: a service mesh can provide guarantees around authentication,
  authorization, and confidentiality to cross-cluster traffic.
- Routing: a service mesh can make it possible and “easy” for applications in
  one cluster to communicate with applications in another cluster.

The same guarantees that a service mesh like Linkerd provides for in-cluster
calls—identity, traffic shifting, etc are also applied to cross-cluster calls.
It does this by "mirroring" service information between clusters. With
multicluster Linkerd in place, the full observability, security and routing
features of Linkerd apply uniformly to both in-cluster and cluster-calls, and
the application does not need to distinguish between those situations.

{{< fig
    alt="Overview"
    title="Overview"
    center="true"
    src="/images/multicluster/feature-overview.svg" >}}

To support this use case, you must install two components on each cluster. The
service mirror controller watches target clusters for updates to services and
mirrors those service updates locally on a source cluster. This provides
visibility into the service names on other, target clusters so that applications
can address them directly.

A gateway is also added to each cluster. This gateway provides a way target
clusters to receive requests from source clusters. Without a gateway, there
would be no way to support
[hierarchical networks](/2020/02/17/architecting-for-multicluster-kubernetes/#requirement-i-support-hierarchical-networks).

After installing these components on each cluster using the handy
`linkerd multicluster install` command, each cluster is linked together.
Kubernetes `ServiceAccount` and RBAC resources are created so that the service
mirror controllers can watch for updates in other clusters.

Once clusters are linked together, `Service` resources can be exported. Exported
services are visible in every cluster that has been linked. The only requirement
is to add annotations to the `Service` being exported that configures which
gateway in the cluster to use for connectivity.

Check out the [getting started guide](/2/tasks/multicluster/) to walk through a
demo and get a better understanding of how all the pieces fit together. If you'd
like to just jump right in, there are
[installation instructions](/2/tasks/installing-multicluster/).

Adding extra Kubernetes clusters to your infrastructure brings a lot of
complexity with it. Make sure to check out the
[requirements](/2020/02/17/architecting-for-multicluster-kubernetes/) used to
design this functionality in Linkerd. It'll hopefully explain why certain design
decisions were made.

After the requirements document, follow up with a deep dive on the
[architecture](/2020/02/25/multicluster-kubernetes-with-service-mirroring/)
itself and how all the pieces fit together. Each step explains exactly what is
happening, both for resource manipulation as well as routing requests between
clusters.
