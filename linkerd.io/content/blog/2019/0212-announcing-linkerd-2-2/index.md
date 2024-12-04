---
date: 2019-02-12T00:00:00Z
slug: announcing-linkerd-2-2
title: Announcing Linkerd 2.2
keywords: [buoyant, linkerd, news]
params:
  author: william
---

Today we're very happy to announce the release of Linkerd 2.2. This major release introduces automatic request retries and timeouts, and graduates auto-inject to be a fully-supported (non-experimental) feature. It adds several new CLI commands (including `logs` and `endpoints`) that provide diagnostic visibility into Linkerd's control plane. Finally, it introduces two exciting experimental features: a cryptographically-secured client identity header, and a CNI plugin that avoids the need for NET_ADMIN kernel capabilities at deploy time.

This release includes contributions from folks at Attest, Buoyant, Mesosphere, Microsoft, Nordstrom, and many more. A special thank you to everyone who filed an issue, submitted a PR, tested a feature, and helped someone else in the [Slack](https://slack.linkerd.io) — the Linkerd community is awesome!

Those of you who have been tracking the 2.x branch via our [weekly edge releases](/releases/) will already have seen these these features in action. Either way, you can download the stable 2.2 release by running:

```bash
curl --proto '=https' --tlsv1.2 -sSfL https://run.linkerd.io/install | sh
```

With that, on to the features!

## Retries and timeouts

Linkerd 2.2 can now automatically retry failed requests, improving the overall success rate of your application in the presence of partial failures. Building on top of the [service profiles](https://linkerd.io/2/features/service-profiles) model introduced in 2.1, Linkerd allows you to configure this behavior on a per-route basis. Here's a [quick screencast](https://asciinema.org/a/227055) of using retries and timeouts to handle a failing endpoint.

In this screencast we can see that the output of `linkerd routes` now includes an ACTUAL_SUCCESS column, measuring success rate of requests on the wire, and an EFFECTIVE_SUCCESS column, measuring success rate from the caller's perspective, i.e. after Linkerd has done its retries.

Of course, controlling _when_ retries can be implemented is a critical component of making retries safe to use. Linkerd 2.2 allows you to mark which routes are idempotent (`isRetryable`), limit the maximum time spent retrying an individual request (`timeout`), and configure the percentage of overall requests that can be retries (`retryBudget`). This parameterization allows you to ensure that retries happen safely and don't escalate issues in an already-failing system.

## Auto-inject (and uninject, and improvements to inject)

Linkerd 2.2 graduates auto-inject to be a fully-supported (non-experimental) feature. Auto-inject is a feature that allows a Kubernetes cluster to automatically add ("inject") Linkerd's data plane proxies to application pods as they're deployed.

Moving proxy injection out of the client and onto the cluster can help ensure that all pods are running the proxy uniformly, regardless of how they're deployed. Linkerd 2.2 also switches auto-inject's behavior to be opt-in rather than opt-out. This means that, once enabled, only namespaces or pods that have the `linkerd.io/inject: enabled` annotation will have auto-inject behavior.

Finally, for client side (non-auto) injection, Linkerd 2.2 improves the `linkerd inject` command to upgrade the proxy versions if they're already specified in the manifest (previous behavior was to skip them entirely), and introduces a `linkerd uninject` command for removing Linked's proxy from given Kubernetes manifest.

## Better NET_ADMIN handling with a CNI plugin

Linkerd 2.2 introduces a new, experimental CNI plugin that does network configuration outside of the security context of the user deploying their application. This makes Linkerd better suited for multi-tenant clusters, where administrators may not want to grant kernel capabilities (specifically, NET_ADMIN) to users.

Background: injecting Linkerd's data plane proxy into a pod requires setting iptables rules so that all TCP traffic to and from a pod automatically goes through its proxy, without any application configuration needed. Typically, this is done via a Kubernetes Init Container that runs as the deployer's service account. In single-tenant clusters this is usually fine, but in multi-tenant clusters this can pose a problem: modifying iptables rules requires the kernel's NET_ADMIN capability, but granting this capability allows tenants to control the network configuration across the host as a whole.

With Linkerd's new CNI plugin, this network configuration is done in at the CNI level, effectively removes the requirement that users have the NET_ADMIN kernel capability. This makes running Linkerd in multi-tenant, security-conscious environments far more practical.

This plugin was contributed by our friends at Nordstrom Engineering and was inspired by [Istio's CNI plugin](https://github.com/istio/cni). A special thank you to [Cody Vandermyn](https://github.com/codeman9) for this feature.

## Client Identity

Linkerd 2.2 introduces a new, secure mechanism for providing _client identity_ on incoming requests. When `--tls=optional` is enabled, Linkerd now adds `l5d-client-id` header to each request. This header can be used by application code to implement authorization, e.g. requiring all requests to be authenticated or restricting access to specific services.

This header is currently marked as experimental, but is a critical first step towards providing comprehensive authentication and authorization mechanisms for Linkerd. In coming weeks, we'll be publishing Linked's roadmap for securely providing both _identity_ and _confidentiality_ of communication within a Kubernetes cluster.

## A new San Francisco Linkerd Meetup

Ok, this isn't technically part of 2.2 but there's a brand new [San Francisco Linkerd Meetup Group](https://www.meetup.com/San-Francisco-Linkerd-Meetup/). Come join us and meet some of the fine folks involved in Linkerd!

## What's next for Linkerd?

Linkerd 2.2 is the culmination of months of work from contributors from around the globe, and we're very excited to be able to unveil it today!

In upcoming releases, you should expect Linkerd 2.x to continue filling out features around reliability, traffic shifting, and security (especially around identity and confidentiality of communication). In the medium term, we'll also be moving to reduce Linkerd's dependence on Kubernetes. Finally, Linkerd 1.x continues under active development, and we remain committed to supporting our 1.x users.

Linkerd is a community project and is hosted by the [Cloud Native Computing Foundation](https://cncf.io). If you have feature requests, questions, or comments, we'd love to have you join our rapidly-growing community! Linkerd is hosted on [GitHub](https://github.com/linkerd/), and we have a thriving community on [Slack](https://slack.linkerd.io), [Twitter](https://twitter.com/linkerd), and the [mailing lists](https://linkerd.io/2/get-involved/). Come and join the fun!
