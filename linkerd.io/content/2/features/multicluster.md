+++
title = "Multicluster"
description = "Linkerd connects applications running in different clusters"
+++

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
between all the applications running on the clusters.

To get started, check out the
[getting started with multicluster](/2/tasks/multicluster/) guide. If you're
interested in how everything fits together, keep reading!

Linkerd's solution is based on three requirements:

1. Support hierarchical networks
1. Maintain independent state
1. Have an independent control plane

If you'd like to see the reasoning behind these requirements, check out our blog
post on
[architecting for multicluster Kubernetes](/2020/02/17/architecting-for-multicluster-kubernetes/).

To satisfy these requirements, Linkerd implements service mirroring. This
effectively takes services in one cluster and mirrors them in as many clusters
as required. Each mirrored service automatically gets all the benefits the mesh
usually provides, such as mTLS, observability and reliability. Once everything
has been setup, the request path goes from a pod on one cluster, through a
gateway to the destination pod on a completely separate cluster!

{{< fig
    alt="step-3"
    title="Gateway"
    center="true"
    src="/images/multicluster/step-3.svg" >}}

For a step by step understanding of what's happening under the covers, check out
the
[service mirroring](/2020/02/25/multicluster-kubernetes-with-service-mirroring/)
blog post.
