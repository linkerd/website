---
date: 2025-04-23T00:00:00Z
slug: announcing-linkerd-2.18
title: |-
  Announcing Linkerd 2.18: Battlescars, lessons learned, and preliminary Windows support
keywords: [linkerd, '2.18', features]
params:
  author: william
  showCover: true
---

We're happy to announce the release of Linkerd 2.18. The theme of this release
is _battlescars_: we've added features and updated functionality to reduce
operational pain in response to real life, hard-won lessons we've learned from
users who have pushed the limits of what Linkerd (and Kubernetes itself!) can
do. This release also introduces an experimental build of the proxy for Windows
environments, an exciting new area for Linkerd.

Infrastructure software means nothing if it is not reliable. Linkerd has now had
over 9 years of continuous improvement and evolution, and our goal is to build a
service mesh that our users can rely on for 100 years. Linkerd 2.18 is the
second major version since the
[announcement of Linkerd's sustainability last October](https://buoyant.io/blog/linkerd-forever)
and continues our laser focus on _operational simplicity_—delivering the
notoriously complex service mesh feature set in a way that is manageable by
human beings.

## Battlescars

This release includes three significant changes based on our experience helping
users run Linkerd at the boundaries of scale: protocol declarations,
GitOps-compatible multicluster, and changes to Gateway API support.

**Protocol declarations.** Since the very beginnings of Linkerd we have followed
what is essentially the Hippocratic oath: if you add Linkerd to a functioning
Kubernetes application, the application should continue functioning! This
obvious-sounding statement is tremendously difficult to accomplish, but is key
to Linkerd's reputation for simplicity. A foundational feature here has been
_protocol detection_: rather than requiring the user to configure the protocols
used by applications, Linkerd will automatically determine them just by looking
at the data passed through the proxy. This allows you to "drop in" Linkerd
without configuration and have your application continue to work.

In the majority of cases, protocol detection just works. But in extreme
situations, it can make things more complicated. One particularly egregious
issue is that if the cluster is under extreme load, the application may not send
data in time for protocol detection to happen! Linkerd will fall back to
treating the connection as raw TCP data, and HTTP-specific features will
suddenly be disabled for that connection.

To avoid this unpredictable behavior, Linkerd 2.18 will now optionally read the
protocol for a port from the _appProto_ field on Kubernetes Service objects.
When this field is specified, Linkerd will not perform protocol detection and
instead just use the configured protocol. There are some interesting
implementation details under the hood (to improve efficiency, Linkerd
transparently upgrades HTTP/1.1 connections to HTTP/2 ones in between client and
server proxies; and we make use of this to transit protocol information between
proxies) but the net result is that avoiding protocol detection for a Service
is as easy as configuring the appProtocol field:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: myService
spec:
  ports:
    - name: myPort
      port: 8090
      protocol: tcp
      appProtocol: http
      targetPort: 8090
```

We’ve also added a host of metrics to capture Linkerd’s protocol detection
behavior, so as to make diagnosing future issues even easier.

**GitOps-compatible multicluster linking.** Linkerd's multicluster capabilities
allow applications to communicate between Kubernetes clusters in a way that is
secure, even across the open Internet, and fully transparent to the application.
Linkerd first introduced multicluster connectivity with the release of Linkerd
2.8 in 2020, allowing adopters to enable a full range of multicluster options
including multi-cloud and hybrid cloud deployments.

At that point in time, multicluster adoption in the Kubernetes ecosystem was
largely ad-hoc, with small numbers of "pet" clusters. Today, multicluster
adoption is significantly different. Linkerd adopters sometimes run Linkerd on
hundreds or thousands of clusters, and will typically manage their
infrastructure via GitOps.

In Linkerd 2.14, we took a first step to supporting new multicluster patterns by
introducing [pod-to-pod multicluster](/2/tasks/pod-to-pod-multicluster/) for
platforms with flat networks. In Linkerd 2.17, we introduced federated services,
a new model for services that span many clusters. In Linkerd 2.18, we've further
improved multicluster by allowing the creation of all Link resources in a
declarative fashion, making it fully GitOps-compatible.

**Gateway API decoupling.** Since the release of Linkerd 2.12 in 2022, Linkerd
has been leading the charge in using the
[Gateway API](https://gateway-api.sigs.k8s.io/) as a core configuration
mechanism. With the 2.14 release, Linkerd became the first service mesh to
achieve conformance with the Gateway API _mesh_ profile.

Our initial approach here was "batteries included": since most adopters did not
have the Gateway API types, Linkerd would bundle them by default. As the Gateway
API itself matures and as adoption of the Gateway API spreads across more
projects, this approach has started to cause friction as _other_ projects have
started installing, or requiring, specific versions of the Gateway API types.

Linkerd 2.18 will be the last release that installs Gateway API types by
default. In this release, we've bumped the installed versions of these types;
we've added support for Gateway API version 1.2.1, the latest available; and
we've improved our documentation with recommendations for how users should
[manage the Gateway API](/2/features/gateway-api/#managing-the-gateway-api)
across Linkerd and other projects.

### Experimental Windows build

The 2.18 release ships with an experimental build of the proxy for Windows
machines. This is a critical first step in our path to full Windows support. If
you are interested in running Linkerd in Windows environments—please reach out!

### Other fun stuff

The 2.18 release also fixes a smattering of smaller issues. Federated services
now propagate metadata dynamically as the set of underlying services change over
time. Multicluster service labels and annotations can now be filtered, to avoid
sharing cluster-specific metadata (e.g. from tools like ArgoCD). And proxy CPU
usage can now be configured in terms of the number of available cores on the
machine, easing certain types of resource configurations.

### Getting your hands on Linkerd 2.18

See our [releases and versions](/releases/) page for how to get ahold of a
Linkerd 2.18 package. Happy meshing!

## Linkerd is for everyone

Linkerd is a graduated project of the
[Cloud Native Computing Foundation](https://cncf.io/). Linkerd is
[committed to open governance.](/2019/10/03/linkerds-commitment-to-open-governance/)
If you have feature requests, questions, or comments, we’d love to have you join
our rapidly-growing community! Linkerd is hosted on
[GitHub](https://github.com/linkerd/), and we have a thriving community on
[Slack](https://slack.linkerd.io/), [Twitter](https://twitter.com/linkerd), and
the [mailing lists](/community/get-involved/). Come and join the fun!

## Photo credit

Photo by
[Valentin Müller](https://unsplash.com/@wackeltin_meem?utm_content=creditCopyText&utm_medium=referral&utm_source=unsplash)
on
[Unsplash](https://unsplash.com/photos/a-close-up-of-a-chess-board-with-pieces-on-it-vh-5LuWlZ_4?utm_content=creditCopyText&utm_medium=referral&utm_source=unsplash).
