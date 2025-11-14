---
date: 2021-02-04T00:00:00Z
title: January Linkerd Community Meeting Recap
keywords: [linkerd]
params:
  author: charles
---

Missed our meeting last month? Don't worry, here's a synopsis along with the
recording.

## Linkerd, a year in review

With six major releases and 53 edge releases, 2020 was a busy year for the
Linkerd maintainers! As Oliver Gould pointed out, edge releases are really
important because they allow the community to test features and functionality
before the code goes into a stable release. So keep on updating your clusters
and give us your feedback through
[GitHub](https://github.com/linkerd/linkerd2/issues)!

Here are the highlights of the last three releases of 2020:

**Linkerd 2.7** introduced proxy performance improvements and external
certificate issuer support using tools like cert-manager.

**Linkerd 2.8** added support for multi-cluster deployments and an "add-on"
concept to make Linkerd more modular.

**Linkerd 2.9** added a multi-core proxy runtime (Tokio), ARM support, and
mutual TLS for all TCP traffic.

## Linkerd, a look ahead

There are no plans to slow down in 2021! Oliver shared some features on the
roadmap.

**Linkerd 2.10** will add mutual TLS for all clusters including multi-cluster
and will introduce extensions, which are the next iteration of the "add-on"
concept that we saw in Linkerd 2.8.

**Linkerd 2.11** will focus on policy and enforce traffic between services.

## Celebrating our latest Linkerd Hero

Last, but most certainly not least, we announced our January Linkerd Hero. Once
more we had three amazing candidates:
[Matt Young, Richard Pijnenburg, and Jimil Desai](/2021/01/19/january-2021-linkerd-hero-nomination/)—all
invaluable members of our community.

You voted for Richard who has been particularly active on the Linkerd Slack,
helping his peers and answering their questions. Very knowledgeable and with a
ton of experience with open source, Richard brings his rich expertise to the
Linkerd community. Congratulations, Richard!

{{< youtube "duRrZAGkN90" >}}

## Linkerd is for everyone

Linkerd is a community project and is hosted by the
[Cloud Native Computing Foundation](https://cncf.io/). Linkerd is
[committed to open governance](/2019/10/03/linkerds-commitment-to-open-governance/).
If you have feature requests, questions, or comments, we'd love to have you join
our rapidly-growing community! Linkerd is hosted on
[GitHub](https://github.com/linkerd/), and we have a thriving community on
[Slack](https://slack.linkerd.io/), [Twitter](https://twitter.com/linkerd), and
the [mailing lists](/community/get-involved/). Come and join the fun!
