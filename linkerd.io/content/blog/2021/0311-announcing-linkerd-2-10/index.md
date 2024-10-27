---
title: |-
  Announcing Linkerd 2.10: Extensions, Opaque Ports, Multi-cluster TCP, and
  more!
date: 2021-03-11T00:00:00Z
slug: announcing-linkerd-2.10
keywords: [linkerd]
params:
  author: william
  showCover: true
---

We're very happy to announce the release of Linkerd 2.10, the best Linkerd
version yet! This release adds pluggable _extensions_ to Linkerd and
dramatically reduces the default control plane size by moving non-critical
components into opt-in extensions. The 2.10 release also extends Linkerd's
seamless, secure multi-cluster support to all TCP connections, not just HTTP.
Finally, Linkerd 2.10 adds _opaque ports_ as a way of extending Linkerd's
coverage to certain situations that are incompatible with protocol detection.

This release includes a lot of hard work from over 50 contributors. A special
thank you to [Lutz Behnke](https://github.com/cypherfox), [Björn
Wenzel](https://github.com/DaspawnW), [Filip
Petkovski](https://github.com/fpetkovski), [Simon
Weald](https://github.com/glitchcrab),
[GMarkfjard](https://github.com/GMarkfjard), [hodbn](https://github.com/hodbn),
[Hu Shuai](https://github.com/hs0210), [Jimil
Desai](https://github.com/jimil749), [jiraguha](https://github.com/jiraguha),
[Joakim Roubert](https://github.com/joakimr-axis), [Josh
Soref](https://github.com/jsoref), [Kelly
Campbell](https://github.com/kellycampbell), [Matei
David](https://github.com/mateiidavid), [Mayank
Shah](https://github.com/mayankshah1607), [Max
Goltzsche](https://github.com/mgoltzsche), [Mitch
Hulscher](https://github.com/mhulscher), [Eugene
Formanenko](https://github.com/mo4islona), [Nathan J
Mehl](https://github.com/n-oden), [Nicolas
Lamirault](https://github.com/nlamirault), [Oleh
Ozimok](https://github.com/oleh-ozimok), [Piyush
Singariya](https://github.com/piyushsingariya), [Naga Venkata Pradeep
Namburi](https://github.com/pradeepnnv),
[rish-onesignal](https://github.com/rish-onesignal), [Shai
Katz](https://github.com/shaikatz), [Takumi Sue](https://github.com/mikutas),
[Raphael Taylor-Davies](https://github.com/tustvold), and [Yashvardhan
Kukreja](https://github.com/yashvardhan-kukreja) for all your hard work!

## Extensions

In Linkerd 2.10, the Linkerd control plane is now modular and extensible with
the introduction of _extensions_. Extensions are opt-in software components
that run as part of the Linkerd control plane. The default control plane in
2.10 now contains just the bare minimum necessary to run, with Prometheus,
Grafana, dashboard, and other non-critical telemetry components packaged as a
`viz` extension. This change drops the default Linkerd control plane down to
**200mb** at startup, from **~500mb** in Linkerd 2.9!

The 2.10 release ships three extensions by default:

* **viz**, which contains the on-cluster metrics stack: Prometheus, Grafana,
  the dashboard, etc.;
* **multicluster**, which contains the machinery for cross-cluster
  communication; and
* **jaeger**, which contains the Jaeger distributed tracing collector and UI.

The move to extensions serves two purposes: first, it allows Linkerd adopters
to choose exactly which bits and pieces of Linkerd they want to install on
their cluster—a common request, especially for users who already have an
off-cluster metrics pipeline.

Second, extensions allow the Linkerd community to build Linkerd-specific
operators and controllers without having to modify the core Linkerd CLI.
Extensions can come from anywhere, and because these extensions fit into
Linkerd's CLI, they "feel" just like the rest of Linkerd.

Read more in the full [blog post on Linkerd
Extensions](/2021/03/01/linkerd-2.10-and-extensions/).

## Seamless, secure multi-cluster for all TCP connections

Multi-cluster support, [introduced in Linkerd
2.8](/2020/06/09/announcing-linkerd-2.8/), allows Linkerd to connect Kubernetes
services across cluster boundaries in a way that's secure, fully transparent to
the application, and independent of the topology of the underlying network.
However, this functionality was restricted to HTTP connections only—until now.
With Linkerd 2.10, [Linkerd's multi-cluster
feature](/2.10/features/multicluster/) now extends to all TCP
connections, with the same guarantees of security and transparency that Linkerd
provides for pod-to-pod communication.

Want to try it? Just install the `multicluster` extension!

## Opaque ports

The 2.10 release adds a new _opaque ports_ feature that extends Linkerd's
ability to handle certain types of traffic. An opaque port is simply one that
Linkerd will proxy _without_ performing protocol detection. While protocol
detection is key to much of Linkerd's simplicity, certain types of traffic are
incompatible with it, including, most commonly, the use of non-TLS'd MySQL
connections. In Linkerd 2.9 and earlier, these situations were handled by
simply skipping them at the proxy level. In Linkerd 2.10, users can explicitly
mark these connections as opaque ports, and Linkerd will proxy them without
attempting protocol detection. This allows Linkerd to apply features such as
transparent mTLS and instrumentation in situations where it was previously
unable to handle.

Read more in the full blog post on [opaque ports in
Linkerd](/2021/02/23/protocol-detection-and-opaque-ports-in-linkerd/).

## And lots more!

Linkerd 2.10 also has a tremendous list of other improvements, performance
enhancements, and bug fixes, including:

* Updated the proxy to use TLS version 1.3 (support for TLS 1.2 remains enabled
  for compatibility with prior proxy versions)
* Fixed an issue that could cause the inbound proxy to fail meshed HTTP/1
  requests from older proxies (from the stable-2.8.x vintage)
* Added a new /shutdown admin endpoint that may only be accessed over the
  loopback network allowing batch jobs to gracefully terminate the proxy on
  completion
* Added PodDisruptionBudgets to the control plane components so that they
  cannot be all terminated at the same time during disruptions
* Fixed an issue where the proxy-injector, sp-validator, and tap APIServer did
  not refresh their certs automatically when provided externally—like through
  cert-manager
* Introduced the `linkerd identity` command, used to fetch the TLS certificates
  for injected pods
* Added a `linkerd viz list` command to list pods with tap enabled
* Added support for multicluster gateways of types other than LoadBalancer
* Moved Docker image hosting to the `cr.l5d.io` registry
* And lots, lots more.

See the [full release
notes](https://github.com/linkerd/linkerd2/releases/tag/stable-2.10.0) for
details.

## What's next for Linkerd?

The momentum behind Linkerd continues to astound us. Companies like **Elkjøp**
(see the case study---"[How a $4 billion retailer built an enterprise-ready
Kubernetes platform powered by
Linkerd](https://www.cncf.io/blog/2021/02/19/how-a-4-billion-retailer-built-an-enterprise-ready-kubernetes-platform-powered-by-linkerd/)"),
**Giant Swarm**, **PlexTrac**, and **Mythical Games** have joined **HP**,
**H-E-B**, **Microsoft**, **Clover Health**, **Mercedes Benz**, **Subspace**,
and many more as recent adopters of Linkerd. The newly-formed [Linkerd Steering
Committee](/2021/01/28/announcing-the-linkerd-steering-committee/),
comprising production users who operate Linkerd at scale, is actively
delivering feedback and guidance to maintainers. Finally, Linkerd was named
[the Best Open Source DevOps Tool of
2020](https://devops.com/buoyant-wins-tech-ascension-award-recognizing-linkerd-service-mesh-as-best-open-source-devops-tool-of-2020/).

But we're just getting started. In our next stable release, we'll focus on
bringing _policy_ to Linkerd, building on the foundation of mTLS to further
enhance the security posture of Kubernetes applications everywhere.

The service mesh doesn't have to be complex, and security doesn't have to be
high-friction. The future of Linkerd is built around these beliefs, and we hope
they resonate with you as well.

## Try it today!

Ready to try Linkerd? Those of you who have been tracking the 2.x branch via
our [weekly edge releases](/releases/) will already have seen these features
in action. Either way, you can download the stable 2.10 release by running:

``` bash
curl --proto '=https' --tlsv1.2 -sSfL https://run.linkerd.io/install | sh
```

Using Helm? See our [guide to installing Linkerd with
Helm](/2.10/tasks/install-helm/). Upgrading from an earlier release? We've got
you covered: see our [Linkerd upgrade guide](/2.10/tasks/upgrade/) for how to
use the `linkerd upgrade` command.

## Linkerd is for everyone

Linkerd is a community project and is hosted by the [Cloud Native Computing
Foundation](https://cncf.io/). Linkerd is [committed to open
governance.](/2019/10/03/linkerds-commitment-to-open-governance/) If you have
feature requests, questions, or comments, we'd love to have you join our
rapidly-growing community! Linkerd is hosted on
[GitHub](https://github.com/linkerd/), and we have a thriving community on
[Slack](https://slack.linkerd.io/), [Twitter](https://twitter.com/linkerd), and
the [mailing lists](/community/get-involved/). Come and join the fun!
