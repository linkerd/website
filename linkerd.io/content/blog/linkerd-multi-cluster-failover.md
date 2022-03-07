---
title: "Announcing automated multi-cluster failover for Kubernetes"
author: 'alejandro'
date: 2022-03-09T00:00:00+00:00
thumbnail: /images/ray-harrington-IUGT3FxXF5k-unsplash.jpg
featured: false
tags: [Linkerd]
---

![Two wing walkers performing on two biplanes flying in the sky](/images/ray-harrington-IUGT3FxXF5k-unsplash.jpg)

Today we're happy to announce the release of a new failover operator for
Linkerd. With this operator, Kubernetes users can now automatically redirect all
traffic to a service to different clusters in the event of service failure,
while still maintaining Linkerd's guarantees of security, reliability, and
transparency to the application.

Multi-cluster deployments are increasingly common in Kubernetes, for reasons of
high availability, multi-tenancy, disaster recovery, or simply isolation of
failure domains. Unfortunately, Kubernetes itself provides very little in the
way of help for multi-cluster deployments. Fortunately, Linkerd fills that gap,
providing cross-cluster communication capabilities that:

* Work with any cluster topology including multi-cloud and hybrid cloud;
* Are completely transparent to the application;
* Are zero-trust compatible and built on mutual TLS and workload identity;
* Introduce no Single Point of Failure (SPOF) to the system.

Linkerd's new failover operator now adds _automation_ to this feature set,
allowing Kubernetes users to configure failure conditions under which Linkerd
will automatically shift traffic between one or more services, including, of
course, services on different clusters.

In true Linkerd fashion, this new functionality is composable and builds on top
of existing Kubernetes and service mesh primitives such as health probes and
Service Mesh Interface (SMI) TrafficSplits. This gives us a flexible framework
that allows you to tackle a variety of situations, including automatically
rerouting traffic to a replica of a service in another cluster in the event of a
service failure; automatically rerouting cross-cluster traffic to a different
cluster in the event of cluster failure; or even automating service failover
within a single cluster.

This new operator rounds out Linkerd's existing reliability features, providing
a comprehensive solution for ultra-high-reliability deployments that covers:

* Failure of individual nodes (handled via retries and request balancing)
* Failures due to bad code changes (handled via canary deployments)
* Failures due to service unavailability (handled with the failover operator)
* Failures due to whole-cluster outages (handed via the failover operator—_roadmap_)

## Getting started

The operator is available in the latest [Linkerd edge
release](https://linkerd.io/edge/) and will be included in the upcoming 2.11.2
stable release.

Want to give it a try right now? Head over to the [linkerd-failover
repo](https://github.com/linkerd/linkerd-failover) and follow the instructions
there, or install via Helm:

```bash
# add the linkerd-smi extension
helm repo add linkerd-smi https://linkerd.github.io/linkerd-smi
helm install linkerd-smi -n linkerd-smi --create-namespace linkerd-smi/linkerd-smi

# add the linkerd-edge Helm repo
helm repo add linkerd-edge [https://helm.linkerd.io/edge](https://helm.linkerd.io/edge)
helm install linkerd-failover -n linkerd-failover --create-namespace --devel linkerd-edge/linkerd-failover
```

You can now configure service failover by applying the
`app.kubernetes.io/managed-by: linkerd-failover` label to an existing
TrafficSplit. For example:

```yaml
apiVersion: split.smi-spec.io/v1alpha2
kind: TrafficSplit
metadata:
name: sample-svc
annotations:
  failover.linkerd.io/primary-service: sample-svc
labels:
  app.kubernetes.io/managed-by: linkerd-failover
spec:
service: sample-svc
backends:
  - service: sample-svc
    weight: 1
  - service: sample-svc-remote
    weight: 0
```

In this example, traffic to `sample-svc` service will automatically failover
from the local cluster to the replica in the event of total health check
failure.

The initial operator implementation covers the basics, but there's a [long and
exciting roadmap](https://github.com/linkerd/linkerd-failover/issues) of
upcoming features. We'd love your feedback on this exciting new feature for
Linkerd. Let us know what you think!

## Linkerd is for everyone

Linkerd is a [graduated project](/2021/07/28/announcing-cncf-graduation/) of the
[Cloud Native Computing Foundation](https://cncf.io/). Linkerd is [committed to
open
governance.](https://linkerd.io/2019/10/03/linkerds-commitment-to-open-governance/)
If you have feature requests, questions, or comments, we'd love to have you join
our rapidly-growing community! Linkerd is hosted on
[GitHub](https://github.com/linkerd/), and we have a thriving community on
[Slack](https://slack.linkerd.io/), [Twitter](https://twitter.com/linkerd), and
the [mailing lists](https://linkerd.io/2/get-involved/). Come and join the fun!

(*Photo by [Ray Harrington](https://unsplash.com/@raymondo600?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText)
on
[Unsplash](https://unsplash.com/?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText).*)
