---
date: 2025-10-31T00:00:00Z
slug: announcing-linkerd-2.19
title: |-
  Announcing Linkerd 2.19: Post-quantum cryptography
keywords: [linkerd, "2.19", features]
params:
  author: william
  showCover: true
---

Today we're happy to announce Linkerd 2.19! This release introduces a
significant state-of-the-art security improvement for Linkerd: a modernized TLS
stack that uses post-quantum key exchange algorithms by default.

Linkerd has now seen almost a decade of continuous improvement and evolution.
Our goal is to build a service mesh that our users can rely on for 100 years. To
do this, we
[partner with users like Grammarly to ensure that Linkerd can accelerate the full scale and scope of modern software environments](https://www.grammarly.com/blog/engineering/the-great-linkerd-mystery/)—and
then we feed those lessons directly back into the product. Linkerd 2.19 release
is the third major version since the
[announcement of Buoyant's profitability and Linkerd project sustainability a year ago](https://buoyant.io/blog/linkerd-forever),
and continues our laser focus on operational simplicity—delivering the
notoriously complex service mesh feature set in a way that is manageable,
scalable, and performant.

## Related announcements

- [Announcing Buoyant Enterprise for Linkerd 2.19: Windows service mesh, post-quantum cryptography, supply chain security, FIPS 140-3, and a new on-cluster dashboard](http://buoyant.io/blog/linkerd-enterprise-2-19-windows-service-mesh-post-quantum-cryptography-supply-chain-security-fips-140-3-and-a-new-on-cluster-dashboard)

## Post-quantum TLS

Linkerd's internal TLS infrastructure received an overhaul in Linkerd 2.19,
preparing it for a potential post-quantum future. We've updated the core
cryptographic module in the proxy from `ring` to `aws-lc`, and added support for
the AES_256_GCM ciphersuite and the post-quantum ML-KEM-768 key exchange
algorithm, which are used by default for all communication between meshed pods.
Additionally, the TLS cipher, key exchange, and signature algorithms are now
exported as part of the standard metrics suite.

## Other fun stuff

Linkerd 2.19 officially promotes its support of native sidecars from alpha to
beta. Native sidecars were first supported by Linkerd 2.15, and moved to
graduated status in Kubernetes this April. This feature
[fixes some of the long-standing annoyances of using sidecar containers in Kubernetes](https://buoyant.io/blog/kubernetes-1-28-revenge-of-the-sidecars),
especially around support for Jobs and race conditions around container startup.
Native sidecars can now be enabled by setting the
`config.beta.linkerd.io/proxy-enable-native-sidecar` annotation.

The 2.19 release also fixes a smattering of smaller issues. Linkerd will now
block connections to ports of a clusterIP Service which are not defined in the
Service spec, matching the behavior of kube-proxy. We fixed discovery staleness
when targeting the linkerd-admin port in native-sidecar mode; a potential panic
in the control plane when processing discovery requests with invalid hostnames;
and an issue where invalid podSelectors in Server resources could prevent all
Server resources from being processed.

## Getting your hands on Linkerd 2.19

See our [releases and versions](/releases/) page for how to get ahold of a
Linkerd 2.19 package. Happy meshing!

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
[A Chosen Soul](https://unsplash.com/@a_chosensoul?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText)
on
[Unsplash](https://unsplash.com/photos/a-computer-generated-image-of-a-complex-structure-tGGuWW28-5M?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText).
