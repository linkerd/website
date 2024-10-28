---
title: Architecting for Multicluster Kubernetes
date: 2020-02-17T00:00:00Z
keywords: [linkerd, multicluster]
params:
  author: thomas
---

{{< note >}} Linkerd 2.8 has been released and implements these requirements.
Check out the [release blog post](/2020/06/09/announcing-linkerd-2.8/) and get
started on your own clusters! {{< /note >}}

Recently, the Linkerd community has been spending time tackling the challenge of
multicluster Kubernetes. How can we apply features like Linkerd's zero-config
automatic mTLS, or traffic splitting, across multiple Kubernetes clusters? What
should the service mesh do, and more importantly: what should the service mesh
not do?

Like any good engineering project, the best way to start is by getting clear on
the requirements. In this blog post, we outline the minimal requirements of a
multi-cluster solution that makes cross-cluster traffic more reliable, secure
and observable. In subsequent blog posts, we'll address some of the
implementation choices.

## From whence dost thou multi-cluster, sirrah?

Kubernetes clusters are like Pringles - you can't just have one! In fact, some
organizations such as
[Zalando](https://srcco.de/posts/how-zalando-manages-140-kubernetes-clusters.html)
have around 100 of them. By running multiple clusters, it becomes possible to
keep the concerns of each cluster separate. Instead of having to solve the
constraints of every application and solution, the problem space shrinks. This
ends up being a fantastic tool to allow for architecting solutions in a more
flexible, simple way.

Unfortunately, each new cluster adds extra complexity to the system. There's
more to manage, keep up to date and something needs to handle connectivity
between all the applications running on the clusters. Can Linkerd help us here?
To understand the solution, let's first list a set of requirements.

## Requirement I: Support Hierarchical Networks

Kubernetes is an interesting beast. One of the implications of having a single
IP address per pod is that by default each cluster ends up being its own
network. Overlay networks are only routable and discoverable inside the cluster
itself. It is possible to architect around this by using tools such as
[Submariner](https://github.com/submariner-io/submariner) or
[Project Calico](https://www.projectcalico.org/). These solutions are awesome if
you have a hard requirement for maintaining a flat network, with each pod
communicating directly to pods in other clusters. They, however, introduce new
points of failure and add complexity that needs to be managed.

In an effort to keep complexity down and not require other tools, it is
important that any multicluster implementation work with the current state of
Kubernetes. If we can't rely on a flat network, the implication is that there
needs to be some kind of gateway that manages traffic coming into clusters and
routes to the correct backend service.

## Requirement II: Maintain Independent State

In a world where there is a totally flat, routable network between every pod in
every cluster, it _still_ doesn't make sense to allow direct communication. For
each pod to talk directly to another pod, it needs to discover that remote pod
somehow. This introduces a requirement for global state between each cluster.
The fault zone for each cluster has now been smashed together! Let's describe a
failure scenario here to understand why this has happened and what it could
mean.

Communication between pods in Kubernetes is managed by the `Service` resource.
By default, this resource creates a virtual IP address: the ClusterIP. When a
pod decides it wants to talk to another service, DNS returns the cluster IP of
this service. As the pod tries to connect to the cluster IP, iptables on the
local node has been configured to pick a destination pod IP address randomly.
`kube-proxy` is in charge of configuring iptables on each node in the cluster
and does this whenever a service is changed, a pod starts or stops. These
changes happen on every node and because of iptables implementation details are
extremely expensive.

By requiring global visibility, state changes in some clusters will impact all
clusters. This moves potentially disparate clusters into the same fault zone and
immediately reduces the max possible scale. No longer is it possible for each
cluster to scale independently, instead the max scale is defined by the size of
every cluster. Any misconfigurations in one cluster, such as launching a
significant number of pods has the ability to DoS every other cluster. This
seems to do the exact opposite of what multiple clusters were supposed to do!

Keeping state independent and managing updates via replication allows
implementations to filter updates to exactly the data required. Issues external
to the local cluster become isolated and ensure that separate components cannot
take each other down.

## Requirement III: Have an Independent Control Plane

It is tempting to introduce a shared control plane. This effectively centralizes
the state, reduces the management overhead of disparate components and has the
potential of making globally optimized decisions. Outside of sharing many of the
same arguments as globally replicated state, this introduces a couple other
downsides.

For starters, connectivity issues are a real thing. When clusters sit at two
different sides of a network, any issues in the middle can introduce failures.
These can manifest as anything from increased latency all the way to a complete
loss of connectivity. In the situation where there is a complete loss of
connectivity, any clusters that cannot talk to the central control plane will
either be completely broken or start to experience odd errors as the state
differs from local caches and the shared control plane. Once again, potentially
separate fault zones have been merged and the entire system fails when its
weakest link experiences issues.

Even in a perfect world where networks never experience failures, the
shared control plane introduces a critical downside. As clusters get provisioned
further away from the shared control plane, operations like discovery updates or
policy checks get slower. This is simply because the latency between processes
will increase and any operation requiring communication with the central cluster
will become slower and slower.

Keeping control planes (and data planes for that matter) separate provides
freedom to each cluster. This freedom lets the cluster operators manage
versions, connectivity and functionality as it is best for them. The loose
coupling makes more resilient systems and actually reduces the complexity
required overall.

## Onwards to solutioneering

With these three constraints —supporting hierarchical networks, maintaining
independent state, and having an independent control plane— we have the necessary
framework to implement a solution that takes the low complexity model Linkerd uses
and expands it to multiple clusters.

In a future post, we'll be outlining the solutions we've arrived on. In the
meantime, we’d love to hear your feedback on this set of requirements! Please
comment on the
[requirements document](https://docs.google.com/document/d/1uzD90l1BAX06za_yie8VroGcoCB8F2wCzN0SUeA3ucw/edit#heading=h.79x1g3qlth40)
or jump into our [Slack channel](https://slack.linkerd.io) and ask some
questions!

---

Linkerd is a community project and is hosted by the
[Cloud Native Computing Foundation](https://cncf.io). If you have feature
requests, questions, or comments, we'd love to have you join our rapidly-growing
community! Linkerd is hosted on [GitHub](https://github.com/linkerd/), and we
have a thriving community on [Slack](https://slack.linkerd.io),
[Twitter](https://twitter.com/linkerd), and the
[mailing lists](https://linkerd.io/2/get-involved/). Come and join the fun!
