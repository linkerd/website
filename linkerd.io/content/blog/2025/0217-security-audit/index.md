---
date: 2025-02-17T00:00:00Z
title: |-
  Linkerd 2024 Security Audit
description: |-
  We're happy to announce the results of Linkerd's 2024 security audit,
  courtesy of 7ASecurity, the Open Source Technology Improvement Fund (OSTIF),
  and the Cloud Native Computing Foundation (CNCF).
keywords: [linkerd, security]
params:
  author: william
  showCover: true
images: [cover.jpg]
---

Today we're happy to report that Linkerd has successfully completed its 2024
security audit. This audit, initiated at the tail end of last year and concluded
early this year, was performed by [7ASecurity](https://7asecurity.com/), managed
by the [Open Source Technology Improvement Fund](https://ostif.org/), and funded
by the [Cloud Native Computing Foundation](https://cncf.io/). As part of
Linkerd’s commitment to openness, transparency, and security by design, we’ve
published the unredacted reports in the [Linkerd GitHub
page](https://github.com/linkerd/linkerd2/tree/main/audits).

This was the third such audit that Linkerd has undergone, and included both
pentest and whitebox security audit methods. We were happy to collaborate with
the 7ASecurity team and OSTIF in the performance of this audit, and particular
happy with this excerpt from the audit report:

> The Linkerd team was incredibly responsive and helpful during the engagement
> and quick to resolve the reported issues, with multiple fixes already
> deployed. The audit report makes note of the fact that the Linkerd project
> reflects hard work and dedication to security, both in the code and in their
> practices. The security recommendations for further work are very specific,
> meaning that a lot of basic and even intermediate security steps have already
> been satisfactorily undertaken by the team. This audit reflects well on the
> Graduated status of this project through the CNCF Graduation Program.

As we said in our [2022 audit blog
post](/2022/06/27/announcing-the-completion-of-linkerds-2022-security-audit/),
no software is perfect, even Linkerd, and every architectural decision
necessarily involves tradeoffs. The point of a security audit is not to produce
a report card but to find the weak points and provide opportunities to address
them before they become user-facing vulnerabilities.

The most severe finding in the audit identified an unused, development-time
script used to generate protobuf bindings, which (if run) was vulnerable to
remote code execution. While this script was not part of the modern development
process, we [removed it from the
repo](https://github.com/linkerd/linkerd2/pull/13459).

You can read the [OSTIF blog post](https://ostif.org/linkerd-audit-complete/)
and the [7ASecurity blog post](TBD) about the audit as well.

## Linkerd is for everyone

Linkerd is a graduated project of the
[Cloud Native Computing Foundation](https://cncf.io/). Linkerd is
[committed to open governance.](/2019/10/03/linkerds-commitment-to-open-governance/)
If you have feature requests, questions, or comments, we'd love to have you join
our rapidly-growing community! Linkerd is hosted on
[GitHub](https://github.com/linkerd/), and we have a thriving community on
[Slack](https://slack.linkerd.io/), [Twitter](https://twitter.com/linkerd), and
in [mailing lists](/community/get-involved/). Come and join the fun!

(*Photo by [Caspar
Rae](https://unsplash.com/@raecaspar?utm_content=creditCopyText&utm_medium=referral&utm_source=unsplash)
on [Unsplash](https://unsplash.com/photos/man-in-yellow-jacket-standing-beside-white-car--MBPgdHD_SA?utm_content=creditCopyText&utm_medium=referral&utm_source=unsplash").*)
