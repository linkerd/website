---
date: 2019-04-16T00:00:00Z
slug: announcing-linkerd-2.3
title: |-
  Announcing Linkerd 2.3: Towards Zero-Touch Zero-Trust Networking for
  Kubernetes
keywords: [linkerd]
params:
  author: william
  showCover: true
---

Today we're very happy to announce the release of
[Linkerd 2.3](https://github.com/linkerd/linkerd2/releases/tag/stable-2.3.0).
This release graduates mTLS out of experimental to a fully supported feature,
and introduces several important security primitives. Most importantly, Linkerd
2.3 turns authenticated, confidential communication between meshed services _on
by default_.

This is the first step towards answering a challenge we posed ourselves over a
year ago: **Can we make secure communication _easier_ than insecure
communication for Kubernetes?**

This isn't just a theoretical question. In a world where
[the majority of web browsers and web sites use strong encryption and authentication](https://transparencyreport.google.com/https/overview?hl=en)
with zero effort on the part of the user, it's increasingly strange for
Kubernetes services to communicate without authentication and over plain text.
Why should surfing for
[cat pictures on Reddit](https://www.reddit.com/r/dogpics) have more security
guarantees than the internals of our own applications?

Securing the communication between Kubernetes services is an important step
towards adopting _zero-trust networking_. In the zero-trust approach, we discard
assumptions about a datacenter security perimeter, and instead push requirements
around authentication, authorization, and confidentiality "down" to individual
units. In Kubernetes terms, this means that services running on the cluster
validate, authorize, and encrypt their own communication.

But security that imposes a burden on the user---especially complex setup and
configuration---is security that doesn't get used. If zero trust is the
foundation of the future of Kubernetes network security, then the _cost_ of
adopting zero trust must be as close to zero as possible. In Linkerd 2.3, we
tackle this challenge head-on:

- The control plane ships with a certificate authority (called simply
  "identity").
- The data plane proxies receive TLS certificates from this identity service,
  tied to the Kubernetes
  [Service Account](https://kubernetes.io/docs/reference/access-authn-authz/service-accounts-admin/)
  that the proxy belongs to, rotated every 24 hours.
- The data plane proxies automatically upgrade all communication between meshed
  services to authenticated, encrypted TLS connections using these certificates.
- Since the control plane also runs on the data plane, communication between
  control plane components is secured in the same way.

All of this is enabled by default and requires no configuration. This means that
as of the 2.3 release, Linkerd now gives you encrypted, authenticated
communication between all your meshed services with no effort on your part. That
may not be all you need for zero trust networking in Kubernetes, but it's a
significant start.

This release represents a major step forward in Linkerd's security roadmap. In
an upcoming blog post, Linkerd creator Oliver Gould will be detailing the design
tradeoffs in this approach, as well as covering Linkerd's upcoming roadmap
around certificate chaining, TLS enforcement, identity beyond service accounts,
and authorization. We'll also be discussing these topics (and all the other fun
features in 2.3) in our
[upcoming Linkerd Online Community Meeting](https://www.meetup.com/Linkerd-Online-Community-Meetup/events/260356731/)
on Wednesday, April 24, 2019 at 10am PT.

Ready to try it? Those of you who have been tracking the 2.x branch via our
[weekly edge releases](/2-edge/) will already have seen these features in
action. Either way, you can download the stable 2.3 release by running:

```bash
curl --proto '=https' --tlsv1.2 -sSfL https://run.linkerd.io/install | sh
```

Finally, we'd be remiss if we didn't point out that this approach has been
deeply inspired by our friends at [Smallstep](https://smallstep.com/),
[Cloudflare](https://www.cloudflare.com/),
[Let's Encrypt](https://letsencrypt.org/), [Mozilla](https://www.mozilla.org/),
and other amazing organizations that strive to make the Internet secure by
default.

Linkerd is a community project and is hosted by the
[Cloud Native Computing Foundation](https://cncf.io). If you have feature
requests, questions, or comments, we'd love to have you join our rapidly-growing
community! Linkerd is hosted on [GitHub](https://github.com/linkerd/), and we
have a thriving community on [Slack](https://slack.linkerd.io),
[Twitter](https://twitter.com/linkerd), and the
[mailing lists](/community/get-involved/). Come and join the fun!

_Image credit: [Robert McGoldrick](https://www.flickr.com/photos/bobsfever/)_
