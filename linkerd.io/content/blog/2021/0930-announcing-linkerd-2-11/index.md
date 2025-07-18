---
date: 2021-09-30T00:00:00Z
slug: announcing-linkerd-2.11
title: |-
  Announcing Linkerd 2.11: Policy, gRPC retries, performance improvements, and
  more!
keywords: [linkerd]
params:
  author: william
  showCover: true
---

Today we're very happy to announce the release of Linkerd 2.11. This release
marks a major step forward for Linkerd by introducing _policy_, a long-awaited
feature that allows users to control which services are allowed to connect and
send requests to each other. This release also introduces a host of
improvements and performance enhancements, including retries for gRPC calls, a
general fix for container startup ordering issues, an even smaller proxy, an
even smaller control plane, and lots more.

If you're running Linkerd today and are curious about the upgrade process,
Buoyant will be hosting a [free _Upgrading to Linkerd 2.11_
workshop](https://buoyant.io/register/upgrading-to-linkerd-2-11-workshop) on
Thursday, Oct 23rd, 9am PT.

This release includes a lot of hard work from over 30 contributors. A special
thank you to [Gustavo Fernandes de Carvalho](https://github.com/gusfcarvalho),
[Oleg Vorobev](https://github.com/olegy2008), [Bart
Peeters](https://github.com/bartpeeters), [Stepan
Rabotkin](https://github.com/EpicStep),
[LiuDui](https://github.com/xichengliudui), [Andrew
Hemming](https://github.com/drewhemm), [Ujjwal
Goyal](https://github.com/importhuman), [Knut
Götz](https://github.com/knutgoetz), [Sanni
Michael](https://github.com/sannimichaelse), [Brandon
Sorgdrager](https://github.com/bsord), [Gerald
Pape](https://github.com/ubergesundheit), [Alexey
Kostin](https://github.com/rumanzo), [rdileep13](https://github.com/rdileep13),
[Takumi Sue](https://github.com/mikutas), [Akshit
Grover](https://github.com/akshitgrover), [Sanskar
Jaiswal](https://github.com/aryan9600), [Aleksandr
Tarasov](https://github.com/aatarasoff), [Taylor](https://github.com/skinn),
[Miguel Ángel Pastor Olivar](https://github.com/migue),
[wangchenglong01](https://github.com/wangchenglong01), [Josh
Soref](https://github.com/jsoref), [Carol Chen](https://github.com/kipply),
[Peter Smit](https://github.com/psmit), [Tarvi
Pillessaar](https://github.com/tarvip), [James
Roper](https://github.com/jroper), [Dominik
Münch](https://github.com/muenchdo), [Szymon
Gibała](https://github.com/Szymongib), and [Mitch
Hulscher](https://github.com/mhulscher) for all your hard work!

## Authorization policy

Linkerd's new server authorization policy feature gives you fine-grained
control of which services are allowed to communicate with each other. These
policies are built directly on the secure service identities provided by
Linkerd's [automatic mTLS](/2.11/features/automatic-mtls/) feature. In keeping
with Linkerd's design principles, authorization policies are expressed in a
composable, Kubernetes-native way that requires a minimum of configuration but
that can express a wide range of behaviors.

To accomplish this, Linkerd 2.11 introduces a set of default authorization
policies that can be applied at the cluster, namespace, or pod level simply by
setting a Kubernetes annotation, including:

* `all-authenticated` (only allow requests from mTLS-validated services);
* `all-unauthenticated` (allow all requests)
* `deny` (deny all requests)
* ... and more.

Linkerd 2.11 additionally introduces two new CRDs, `Server` and
`ServerAuthorization`, which together allow fine-grained policies to be applied
across arbitrary sets of pods. For example, a Server can select across all
admin ports on all pods in a namespace, and a ServerAuthorization can allow
health check connection from kubelet, or
[mTLS](https://buoyant.io/mtls-guide/) connections for metrics
collection.

Together, these annotations and CRDs allow you to easily specify a wide range
of policies for your cluster, from "all traffic is allowed" to "port 8080 on
service Foo can only receive
[mTLS](/2.10/features/automatic-mtls/)
traffic from services using the Bar service
account", to lots more. (See the [full policy docs
&raquo;](/2.11/features/server-policy/))

![Linkerd policy, as seen from Buoyant Cloud](buoyant-cloud-policy-mtls.png "Linkerd policy, as seen by [Buoyant Cloud](https://buoyant.io/cloud)")

## Retries for HTTP requests with bodies

Retrying failed requests is a critical part of Linkerd's ability to improve the
reliability of Kubernetes applications. Until now, for reasons of performance,
Linkerd has only allowed retries for body-less requests, e.g. HTTP GETs. In
2.11, Linkerd can also retry failed requests with bodies, including gRPC
requests, with a maximum body size of 64KB.

## Container startup ordering workaround

Linkerd 2.11 now ensures, by default, that the `linkerd2-proxy` container is
ready before any other containers in the pod are initialized. This is a
workaround for Kubernetes's much-lamented lack of control over container
startup ordering, and addresses a large class of tricky race conditions where
application containers attempt to connect before the proxy is ready.

## Even smaller, faster, and lighter

As usual, Linkerd 2.11 continues our goal of keeping Linkerd the [lightest,
fastest possible service mesh for
Kubernetes](/2021/05/27/linkerd-vs-istio-benchmarks/).
Relevant changes in 2.11 include:

* The control plane is down to just 3 deployments.
* Linkerd's data plane "micro-proxy" is even smaller and faster thanks to the
  highly active Rust networking ecosystem.
* SMI features have been mostly removed from the core control plane, and moved
  to an extension.
* Linkerd images now use minimal "distroless" base images.

## And lots more!

Linkerd 2.11 also has a tremendous list of other improvements, performance
enhancements, and bug fixes, including:

* New CLI tab completion for Kubernetes resources.
* All `config.linkerd.io` annotations can now be set on `Namespace` resources
  and they will serve as defaults for pods created in that namespace.
* A new `linkerd check -o short` command with, you know, short output.
* A new _Extensions_ page in the dashboard
* [Fuzz testing](/2021/05/07/fuzz-testing-for-linkerd/) for
  the proxy!
* The proxy now sets informational `l5d-client-id` and `l5d-proxy-error`
  headers
* Lots of improvements to Helm configurability and to `linkerd check`
* Experimental support for `StatefulSets` with `linkerd-multicluster`
* And lots more!

See the [full release
notes](https://github.com/linkerd/linkerd2/releases/tag/stable-2.11.0) for
details.

## What's next for Linkerd?

2021 has been a incredible year for Linkerd. Recently, [Linkerd became the only
CNCF graduated service
mesh](/2021/07/28/announcing-cncf-graduation/), joining
projects like Kubernetes, Prometheus, and Envoy at the foundation's highest
level of maturity.  Linkerd's benchmarks continue to show that it is
[dramatically faster and lighter than other service
meshes](/2021/05/27/linkerd-vs-istio-benchmarks/). The
Linkerd community also recently introduced the [Linkerd Ambassador
program](/2021/08/05/announcing-the-linkerd-ambassador-program/),
recognizing those community members who demonstrate passion, engagement, and a
commitment to sharing Linkerd with the border community, and organizations
around the world are adopting Linkerd, often while [coming
from](https://nais.io/blog/posts/2021/05/changing-service-mesh.html) [other
meshes](https://blog.polymatic.systems/service-mesh-wars-goodbye-istio-b047d9e533c7).

In the next few Linkerd releases, we'll be working on additional types of
policy, including client-side policy, including circuit breaking), mesh
expansion to allow the data plane to run outside of Kubernetes, and for the
rest of the [Linkerd
roadmap](https://github.com/linkerd/linkerd2/blob/main/ROADMAP.md). If you have
feature requests, of course, we'd love to hear them!

## Linkerd is for everyone

Linkerd is a graduated project of the [Cloud Native Computing
Foundation](https://cncf.io/). Linkerd is [committed to open
governance.](/2019/10/03/linkerds-commitment-to-open-governance/) If you have
feature requests, questions, or comments, we'd love to have you join our
rapidly-growing community! Linkerd is hosted on
[GitHub](https://github.com/linkerd/), and we have a thriving community on
[Slack](https://slack.linkerd.io/), [Twitter](https://twitter.com/linkerd), and
the [mailing lists](/community/get-involved/). Come and join the fun!

## Photo credit

Photo by [Tim
Evans](https://unsplash.com/@tjevans?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText)
on
[Unsplash](https://unsplash.com/s/photos/bank-vault?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText)
