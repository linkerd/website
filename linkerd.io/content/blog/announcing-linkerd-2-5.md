---
title: 'Announcing Linkerd 2.5: Helm charts and RBAC-aware tap'
author: 'william'
date: 2019-08-19T00:00:00+00:00
thumbnail: /uploads/diving-helmet.jpg
draft: false
slug: announcing-linkerd-2.5
tags: [Linkerd]
---

![A helm to end all helms](/uploads/diving-helmet.jpg)

Today we're happy to announce the release of Linkerd 2.5! This release adds
[Helm](https://helm.sh/) support, hardens Linkerd's `tap` functionality to
obey Kubernetes RBAC rules, improves Linkerd's CLI to report metrics during
traffic splits, allows logging levels to be set dynamically, and much, much
more.

Linkerd's [new Helm 2 chart](...) provides an alternative to the `linkerd
install` command for users who have existing Helm deployment pipelines. Even
if you're not using Helm, this method provides a better installation
framework than `linkerd install` for complex environments that require lots
of customization.

Linkerd's `tap` command provides a "tcpdump for microservices" that allows
users to view a sample of live request/response calls for meshed deployments.
(This is particularly useful since, as of 2.3, Linkerd [encrypts all meshed
HTTP traffic by
default](https://linkerd.io/2019/04/16/announcing-linkerd-2.3/)!) In Linkerd
2.5, `tap` now uses Kubernetes RBAC to provide granular access to results.
This means that, for applications which process sensitive data, who has
access to tap that data in transit is now controllable through the RBAC rules
of the underlying Kubernetes cluster.

Linkerd 2.5 also includes a tremendous list of other improvements,
performance enhancements, and bug fixes, including:

* Dynamically configurable proxy logging levels.
* A new `linkerd stat trafficsplits` command to show metrics during traffic
  split operations.
* A new Kubernetes cluster monitoring Grafana dashboard.
* Handy new CLI flags like `--as` and `--all-namespaces`.
* New pod anti-affinity rules in high availability (HA) mode.
* Namespace-level configuration for autoinjection behavior.

See the [full release notes](https://github.com/linkerd/linkerd2/releases/tag/stable-2.5.0) for details.

If you've been watching the clock, this 2.5 release hits at just under 6
weeks since Linkerd 2.4. This high velocity release cycle is only possible
thanks to the rapidly-growing Linkerd community of contributors, testers, and
adopters. A special thanks especially to
[Jonathan Juares Beber](https://github.com/jonathanbeber),
[Cody Vandermyn](https://github.com/codeman9),
[Alena Varkockova](https://github.com/alenkacz),
[Tarun Pothulapati](https://github.com/Pothulapati)
and
[Guangming Wang](https://github.com/ethan-daocloud).

We want your feedback! Next week, we'll be discussing Linkerd 2.5, the plans
for Linkerd 2.6, and Linkerd's integrations with [OPA
Gatekeeper](https://github.com/open-policy-agent/gatekeeper) and
[OpenFaaS](https://github.com/openfaas/faas) in our monthly  [online Linkerd
Community Meetup](https://www.meetup.com/Linkerd-Online-Community-Meetup/).
Be sure to join us there to hear more about Linkerd 2.5 straight from the
horses' mouths.

Ready to try Linkerd? Those of you who have been tracking the 2.x branch via
our [weekly edge releases](https://linkerd.io/2/edge) will already have seen
these features in action. Either way, you can download the stable 2.4 release
by running:

```bash
curl https://run.linkerd.io/install | sh
```

Upgrading from a previous release? See our handy [Linkerd upgrade
guide](https://linkerd.io/2/tasks/upgrade/) for how to use the `linkerd
upgrade` command.

Linkerd is a community project and is hosted by the [Cloud Native Computing
Foundation](https://cncf.io/). If you have feature requests, questions, or
comments, we'd love to have you join our rapidly-growing community! Linkerd
is hosted on [GitHub](https://github.com/linkerd/), and we have a thriving
community on [Slack](https://slack.linkerd.io/),
[Twitter](https://twitter.com/linkerd), and the [mailing
lists](https://linkerd.io/2/get-involved/). Come and join the fun!

(*Image credit: [Plaisanter](https://www.flickr.com/photos/plaisanter/)*)

