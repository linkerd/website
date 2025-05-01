---
date: 2019-08-20T00:00:00Z
slug: announcing-linkerd-2.5
title: |-
  Announcing Linkerd 2.5: Helm support and RBAC-aware tap
keywords: [linkerd]
params:
  author: william
  showCover: true
---

Today we're happy to announce the release of Linkerd 2.5! This release adds
support for installation via [Helm](https://helm.sh/), hardens Linkerd's `tap`
command to obey Kubernetes RBAC rules, improves Linkerd's CLI to report metrics
during traffic splits, allows logging levels to be set dynamically, and much,
much more.

Linkerd's [new Helm support](https://linkerd.io/2/tasks/install-helm/) offers an
alternative to `linkerd install` for installation. If you're a Helm 2 or Helm 3
user, you can use this install Linkerd with your existing deployment flow. Even
if you're not, this method may provide a better mechanism for environments that
require lots of customization at install time, which would otherwise require a
complicated set of arguments to `linkerd install`. (And getting a Linkerd 2.x
Helm chart into the Helm stable repo itself is
[in progress](https://github.com/linkerd/linkerd2/pull/3292).)

Linkerd's `tap` command provides "tcpdump for microservices" functionality that
allows users to view a sample of live request/response calls for meshed
deployments. (Particularly useful since as of 2.3, Linkerd
[encrypts all meshed HTTP traffic by default](0416-announcing-linkerd-2-3),
rendering `tcpdump` itself less than useful!) In Linkerd 2.5, `tap` now uses
Kubernetes RBAC to provide granular access to results. This means that
applications which process sensitive data can now control who has access that
data in transit by using the RBAC rules of the underlying Kubernetes cluster.

Linkerd 2.5 also includes a tremendous list of other improvements, performance
enhancements, and bug fixes, including:

- Dynamically configurable proxy logging levels.
- A new `linkerd stat trafficsplits` command to show metrics during traffic
  split operations (e.g.
  [a canary release](https://linkerd.io/2/tasks/flagger/)).
- A new Kubernetes cluster monitoring Grafana dashboard.
- Handy new CLI flags like `--as` and `--all-namespaces`.
- New pod anti-affinity rules in high availability (HA) mode.
- Namespace-level configuration for auto-injection behavior.

See the
[full release notes](https://github.com/linkerd/linkerd2/releases/tag/stable-2.5.0)
for details.

If you've been watching the clock, this 2.5 release hits at just under 6 weeks
since Linkerd 2.4. This high velocity release cycle is only possible thanks to
the rapidly-growing Linkerd community of contributors, testers, and adopters. A
special thanks especially to
[Jonathan Juares Beber](https://github.com/jonathanbeber),
[Cody Vandermyn](https://github.com/codeman9),
[Alena Varkockova](https://github.com/alenkacz),
[Tarun Pothulapati](https://github.com/Pothulapati) and Guangming Wang.

📣 We want your feedback! Next week, we'll be discussing all the new features,
plus upcoming plans for Linkerd 2.6, Linkerd's integrations with
[OPA Gatekeeper](https://github.com/open-policy-agent/gatekeeper) and
[OpenFaaS](https://github.com/openfaas/faas) in our monthly
[online Linkerd Community Meetup](https://www.meetup.com/Linkerd-Online-Community-Meetup/).
Be sure to join us hear more about Linkerd 2.5 straight from the horses' mouths.

Ready to try Linkerd? Those of you who have been tracking the 2.x branch via our
[weekly edge releases](https://linkerd.io/2/edge) will already have seen these
features in action. Either way, you can download the stable 2.5 release by
running:

```bash
curl --proto '=https' --tlsv1.2 -sSfL https://run.linkerd.io/install | sh
```

Upgrading from a previous release? See our handy
[Linkerd upgrade guide](https://linkerd.io/2/tasks/upgrade/) for how to use the
`linkerd upgrade` command.

Linkerd is a community project and is hosted by the
[Cloud Native Computing Foundation](https://cncf.io/). If you have feature
requests, questions, or comments, we'd love to have you join our rapidly-growing
community! Linkerd is hosted on [GitHub](https://github.com/linkerd/), and we
have a thriving community on [Slack](https://slack.linkerd.io/),
[Twitter](https://twitter.com/linkerd), and the
[mailing lists](https://linkerd.io/2/get-involved/). Come and join the fun!

(_Image credit: [Plaisanter](https://www.flickr.com/photos/plaisanter/)_)
