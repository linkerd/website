---
date: 2022-03-09T00:00:00+00:00
title: Announcing automated multi-cluster failover for Kubernetes
keywords: [linkerd]
params:
  author: alejandro
  showCover: true
---

Today we're happy to announce the release of new _automated failover_
functionality for Linkerd. This feature gives Linkerd the ability to
automatically redirect all traffic from a failing or inaccessible service to one
or more replicas of that service—including replicas on other clusters. And, as
you'd expect, any redirected traffic maintains all of Linkerd's guarantees of
security, reliability, and transparency to the application, even across clusters
boundaries separated by the open Internet.

Implemented as a Kubernetes operator that can be added to an existing Linkerd
deployment, the failover strategy can be applied to a single cluster but is
particularly useful for multi-cluster deployments. Linkerd already provides
[powerful cross-cluster communication
capabilities](https://linkerd.io/2/features/multicluster/) that work with any
cluster topology, including multi-cloud and hybrid cloud; are completely
transparent to the application; are zero-trust compatible; and do not introduce
any single points of failure (SPOF) to the system. To this feature set, the new
failover operator now adds _automation_, allowing Kubernetes users to configure
failure conditions under which Linkerd will automatically shift traffic between
one or more services.

In true Linkerd fashion, this new functionality introduces a minimum of new
machinery, instead building on top of existing Kubernetes and service mesh
primitives such as health probes and [Service Mesh
Interface](https://smi-spec.io/) TrafficSplits. This new operator rounds out
Linkerd's existing reliability features, providing a complete solution for
ultra-high-reliability deployments that covers:

* Failure of individual nodes: handled via
  [retries](https://linkerd.io/2/features/retries-and-timeouts/) and [request
  balancing](https://linkerd.io/2/features/load-balancing/)
* Failures due to bad code changes: (handled via [canary
  deployments](https://linkerd.io/2/features/traffic-split/))
* Failures due to service unavailability in general: handled with the failover operator
* Failures due to whole-cluster outages: handed with the failover operator

## Getting started

The operator is available as a standalone project, but requires the latest
[Linkerd edge release](https://linkerd.io/releases/) release to work. The operator
will also work with in the upcoming 2.11.2 point release, expected within the
next few weeks.

Want to give it a try right now? Head over to the [linkerd-failover
repo](https://github.com/linkerd/linkerd-failover) and follow the instructions
there, or install via Helm:

```bash
# Add the linkerd-edge Helm repo if you haven't already
helm repo add linkerd-edge https://helm.linkerd.io/edge
# And the linkerd-smi extension
helm repo add linkerd-smi https://linkerd.github.io/linkerd-smi
helm repo up

# Install linkerd-smi and linkerd-failover
helm install linkerd-smi -n linkerd-smi --create-namespace linkerd-smi/linkerd-smi
helm install linkerd-failover -n linkerd-failover --create-namespace --devel linkerd-edge/linkerd-failover
```

Then, configure service failover by applying the
`failover.linkerd.io/controlled-by: linkerd-failover` label to an existing
TrafficSplit. For example:

```yaml
apiVersion: split.smi-spec.io/v1alpha2
kind: TrafficSplit
metadata:
name: sample-svc
annotations:
  failover.linkerd.io/primary-service: sample-svc
labels:
  failover.linkerd.io/controlled-by: linkerd-failover
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
failure. It's as simple as that!

We'd love your feedback on this exciting new feature for Linkerd. The initial
operator implementation covers the basics, but there's lots more to come. Check
out our [initial roadmap](https://github.com/linkerd/linkerd-failover/issues)
(soon to be moved to the main [linkerd2
repo](https://github.com/linkerd/linkerd2)) and give us your feature requests,
bug reports, and any other feedback!

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
