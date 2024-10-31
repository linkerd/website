---
date: 2020-11-09T00:00:00Z
slug: announcing-linkerd-2.9
title: |-
  Announcing Linkerd 2.9: mTLS for all, ARM support, and more!
keywords: [linkerd]
params:
  author: william
  showCover: true
---

We're very happy to announce the release of Linkerd 2.9, the best Linkerd
version yet! This release extends Linkerd's zero-config mutual TLS (mTLS)
support to all TCP connections, allowing Linkerd to transparently encrypt and
authenticate all TCP connections in the cluster the moment it's installed. The
2.9 release also adds ARM support, introduces a new multi-core proxy runtime for
higher throughput, adds support for Kubernetes service topologies, and lots,
lots more.

This release includes a lot of hard work from over 50 contributors. A special
thank you to [Abereham G Wodajie](https://github.com/Abrishges),
[Alexander Berger](https://github.com/alex-berger),
[Ali Ariff](https://github.com/aliariff),
[Arthur Silva Sens](https://github.com/ArthurSens),
[Chris Campbell](https://github.com/campbel),
[Daniel Lang](https://github.com/mavrick),
[David Tyler](https://github.com/DaveTCode),
[Desmond Ho](https://github.com/DesmondH0),
[Dominik Münch](https://github.com/muenchdo),
[George Garces](https://github.com/jgarces21),
[Herrmann Hinz](https://github.com/HerrmannHinz),
[Hu Shuai](https://github.com/hs0210),
[Jeffrey N. Davis](https://github.com/penland365),
[Joakim Roubert](https://github.com/joakimr-axis),
[Josh Soref](https://github.com/jsoref),
[Lutz Behnke](https://github.com/cypherfox),
[MaT1g3R](https://github.com/MaT1g3R), [Marcus Vaal](https://github.com/mvaal),
[Markus](https://github.com/mbettsteller),
[Matei David](https://github.com/mateiidavid),
[Matt Miller](https://github.com/mmiller1),
[Mayank Shah](https://github.com/mayankshah1607),
[Naseem](https://github.com/naseemkullah), [Nil](https://github.com/c-n-c),
[OlivierB](https://github.com/olivierboudet),
[Olukayode Bankole](https://github.com/rbankole),
[Paul Balogh](https://github.com/javaducky),
[Rajat Jindal](https://github.com/rajatjindal),
[Raphael Taylor-Davies](https://github.com/tustvold),
[Simon Weald](https://github.com/glitchcrab),
[Steve Gray](https://github.com/steve-gray),
[Suraj Deshmukh](https://github.com/surajssd),
[Tharun Rajendran](https://github.com/tharun208),
[Wei Lun](https://github.com/WLun001), [Zhou Hao](https://github.com/zhouhao3),
[ZouYu](https://github.com/Hellcatlk), [aimbot31](https://github.com/aimbot31),
[iohenkies](https://github.com/iohenkies), [memory](https://github.com/memory),
and [tbsoares](https://github.com/tbsoares) for all your hard work!

## Zero trust with zero-config, on-by-default mutual TLS

Linkerd has featured transparent, on-by-default mutual TLS for several
releases—but only for HTTP traffic. In this release, we've removed that caveat.
Now, Linkerd will automatically encrypt and validate all TCP connections between
meshed endpoints, including automatically rotating the pod certificates every 24
hours and automatically tying TLS identity to the pod's Kubernetes
ServiceAccount. As always, this is 100% transparent to the application and
requires no code changes or even developer awareness.

This automatic mTLS is a massive step towards zero trust security for Kubernetes
users. By performing encryption and authentication to the pod boundary (the
smallest unit of execution in Kubernetes), Linkerd provides "encryption in
transit" in a modern, zero-trust form. In upcoming releases, we'll extend this
security-first featureset to include policy and enforcement, based on the strong
cryptographic guarantees of identity and confidentiality provided by mTLS.

## New multi-core proxy runtime

Linkerd's blazing speed and ultra-low memory footprint compared to other service
meshes like Istio are primarily due to its underlying Rust "micro-proxy",
Linkerd2-proxy
([learn more about Linkerd2-proxy in Eliza Weisman's "under the hood "post](https://linkerd.io/2020/07/23/under-the-hood-of-linkerds-state-of-the-art-rust-proxy-linkerd2-proxy/)).
This speed has made it possible to get by with a single-core runtime—but
ultimately, a single core can only take you so far. In Linkerd 2.9 we've
upgraded the proxy to a multi-core runtime, which allows for greater throughput
and concurrency for individual pods.

This change has resulted in further performance improvements over Linkerd's
already lightning-fast latency profile. Over the next few weeks we'll publish
some benchmarks showing just how much you can expect from Linkerd 2.9.

## ARM support

Linkerd 2.9 also introduces the oft-requested support for ARM! Whether you're
focused on cost reduction with ARM-based compute such as
[AWS Graviton](https://aws.amazon.com/ec2/graviton/) or simply want to run
Linkerd on your Raspberry Pi cluster, now you can! A huge thanks to GSoC student
[Ali Ariff](https://github.com/aliariff) for this feature.

## Support for Kubernetes service topologies

Linkerd 2.9 introduces support for Kubernetes's new
[service topology feature](https://kubernetes.io/docs/concepts/services-networking/service-topology/)!
This means that you can now introduce routing preferences such as "requests
should stay in this node" or "requests should stay in this region". This can
provide significant performance improvements and cost savings, especially for
larger applications. A huge thanks thanks to CommunityBridge participant
[Matei David](https://github.com/mateiidavid) for this feature.

## And lots more!

Linkerd 2.9 also has a tremendous list of other improvements, performance
enhancements, and bug fixes, including:

- A new bring-your-own-Prometheus option, for users who want to skip Linkerd's
  Prometheus cluster and use their own directly.
- New support for Kubernetes 1.19
- New support for authenticated Docker registries
- New support for Ingress-level load balancing decisions, e.g. session
  stickiness
- New fish shell completions for the CLI
- New Spanish translations for the dashboard (please help us translate into your
  language!)
- And lots, lots more.

See the
[full release notes](https://github.com/linkerd/linkerd2/releases/tag/stable-2.9.0)
for details.

## What's next for Linkerd?

The momentum behind Linkerd continues to astound us. Companies like **HP**,
**H-E-B**, **Microsoft**, **Clover Health**, **Mercedes Benz**, **Purdue
University Global**, **PriceKinetics**, and many more have recently adopted
Linkerd to power their mission-critical infrastructure. And we're just getting
started. Over the next few releases we'll continue to double down on what many
of these engineers have told us are Linkerd's two biggest value props:
**security** and **simplicity**.

- **Security**: Our many security-conscious users tell us that Linkerd's
  zero-config, on-by-default mTLS is the most powerful tool in their Kubernetes
  toolbox for zero-trust security. Over the next few releases we'll continue to
  extend Linkerd's capabilities here, especially in the realms of authorization
  and policy.
- **Simplicity**: We hear time and time again that users arrive at Linkerd after
  navigating a mind-boggling service mesh landscape riddled with overly complex,
  checklist-driven projects. Over the next few releases, we'll strive to make
  Linkerd even smaller and even simpler by improving control plane modularity
  and reducing the set of mandatory components.

In short: the service mesh doesn't have to be complex, and security doesn't have
to be hard. The future of Linkerd is built around these beliefs, and we hope
they resonate with you as well.

## Try it today!

Ready to try Linkerd? Those of you who have been tracking the 2.x branch via our
[weekly edge releases](https://linkerd.io/2/edge) will already have seen these
features in action. Either way, you can download the stable 2.9 release by
running:

```bash
curl --proto '=https' --tlsv1.2 -sSfL https://run.linkerd.io/install | sh
```

Using Helm? See our
[guide to installing Linkerd with Helm](https://linkerd.io/2/tasks/install-helm/).
Upgrading from a previous release? We've got you covered: see our
[Linkerd upgrade guide](https://linkerd.io/2/tasks/upgrade/) for how to use the
linkerd upgrade command.

## Linkerd is for everyone

Linkerd is a community project and is hosted by the
[Cloud Native Computing Foundation](https://cncf.io/). Linkerd is
[committed to open governance.](https://linkerd.io/2019/10/03/linkerds-commitment-to-open-governance/)
If you have feature requests, questions, or comments, we'd love to have you join
our rapidly-growing community! Linkerd is hosted on
[GitHub](https://github.com/linkerd/), and we have a thriving community on
[Slack](https://slack.linkerd.io/), [Twitter](https://twitter.com/linkerd), and
the [mailing lists](https://linkerd.io/2/get-involved/). Come and join the fun!
