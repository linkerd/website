---
date: 2022-06-27T00:00:00+00:00
title: Announcing the completion of Linkerd's 2022 Security Audit
keywords: [linkerd]
params:
  author: william
  showCover: true
---

Today we're happy to announce the completion of Linkerd's annual security audit,
conducted by [Trail of Bits](https://www.trailofbits.com/) and funded by the
[Cloud Native Computing Foundation](https://cncf.io). As part of Linkerd's
commitment to openness, transparency, and security by design, we've published
the unredacted reports
[in Linkerd's GitHub repository](https://github.com/linkerd/linkerd2/tree/main/audits/2022).

This year's audit comprised two parts: a security assessment of the codebase and
supporting documentation, and a _threat model_ that assessed potential threats
against Linkerd once deployed in a cluster, including against the security
guarantees that Linkerd provides for application traffic. The Linkerd
maintainers collaborated extensively with the Trail of Bits team during the
course of the audit to ensure that they were able to ramp up quickly and to
focus their efforts on the most security-critical areas of the project.

No software is perfect, even Linkerd, and every architectural decision
necessarily involves tradeoffs. The point of a security audit is not to produce
a report card but to find the weak points and provide opportunities to address
them before they become user-facing vulnerabilities. Nevertheless, we are happy
to report that _the assessment "did not uncover any significant flaws or defects
that could impact system confidentiality, integrity, or availability"_ in
Linkerd.

The audit did uncover some code quality issues that changed the way we lint
Linkerd's Go code; suggested better documentation for the security implications
of Linkerd's design; and further supported the changes in the upcoming 2.12
release that will allow for route-based policies.

Read on for more!

## Linkerd's security philosophy

The report comes at an interesting time for the service mesh space with
increased scrutiny on projects across the board. The popular Istio project has
come under fire this year with the disclosure this year of several high-profile
vulnerabilities, including
[the silent bypassing of authorization policy](https://nvd.nist.gov/vuln/detail/CVE-2022-21679)
and the
[ability for anyone on the Internet to crash Istio control planes](https://nvd.nist.gov/vuln/detail/CVE-2022-23635).

These vulnerabilities serve to reinforce our commitment to our core security
philosophy: that complexity and cost are the enemy of security. For a system to
be secure it _must_ be simple, and for security to be useful it _must_ be cheap.
Every aspect of Linkerd's design is centered around this idea, and that has led
to many of the decisions that make Linkerd unique, from
[the choice of Rust](/2020/07/23/under-the-hood-of-linkerds-state-of-the-art-rust-proxy-linkerd2-proxy/),
the decision [not to adopt Envoy](/2020/12/03/why-linkerd-doesnt-use-envoy/),
and the focus, even early in the project, on providing zero-configuration mutual
TLS.

Features like mutual TLS, traffic policy, and workload identity are all critical
parts of a modern, zero-trust approach to Kubernetes security, and the security
_in practice_ of a Linkerd deployment is a paramount concern.

## Audit findings and remediations

The security assessment uncovered several issues pertaining to code quality in
the Go portions of Linkerd's codebase, ranging in severity from "low" to
"informational" to "undetermined". These issues included things like unhandled
errors and incorrect use of certain library functions. We've fixed these issues
in the 2.11.2 release and we've enabled more linting in our Go code to prevent
similar things from occurring in the future.

The threat model evaluated several possible attack vectors to Linkerd
deployments. Here it captured issues ranging in severity from "medium" to "low"
to "informational". Of these, the three highest-severity (medium) issues
discussed were:

1. The Linkerd CLI allows resources to be specified with `http` as well as
   `https` URLs, allowing potential scenarios where operators inadvertently send
   unencrypted YAML manifests over the open Internet, or load resources that
   have been corrupted by man-in-the-middle attacks. To remediate this, as of
   Linkerd 2.11.2, the Linkerd CLI only accepts HTTPS URLs.
2. Linkerd's admin port serves both informational (metrics) as well as control
   (shutdown) endpoints and is exposed to other components in the same pod,
   allowing potential scenarios where attackers with access to the cluster could
   shut down the proxy. To remediate this, in the upcoming Linkerd 2.12 release
   these requests will be authenticated independently by making use of Linkerd's
   new route-based policies.
3. Linkerd's identity and destination controllers are shared across all pods in
   the clusters, allowing potential scenarios where attachers pollute records
   and cause a denial-of-service attack. This is an explicit design decision by
   Linkerd (alternatives, such as per-namespace / per-tenant separation of these
   components, introduce significantly more complexity). To remediate this, we
   are improving Linkerd’s documentation to make these tradeoff decisions more
   explicit.

For more details, you can find the full report and unredacted report
[in Linkerd's GitHub repository](https://github.com/linkerd/linkerd2/tree/main/audits/2022).

## Linkerd is designed for security from the ground up

Regular third-party audits are just one part of Linkerd's comprehensive focus on
world-class security. Linkerd's security controls also include:

- All code and docs developed fully in the open;
- All code and docs reviewed by maintainers before merge;
- A formal
  [security policy](https://github.com/linkerd/linkerd2/blob/main/SECURITY.md)
  for reporting vulnerabilities.
- All code and docs go through a comprehensive set of checks, including static
  analysis, dependency analysis, and
  [fuzz testing](/2021/05/07/fuzz-testing-for-linkerd/), before being packaged
  as a release.

Linkerd is trusted by users around the world not just to be secure but to
_increase_ the security of their systems. We hold that trust sacred and strive
our best to live up to it with every line of code.

## Linkerd is for everyone

Linkerd is a [graduated project](/2021/07/28/announcing-cncf-graduation/) of the
[Cloud Native Computing Foundation](https://cncf.io/). Linkerd is
[committed to open governance.](/2019/10/03/linkerds-commitment-to-open-governance/)
If you have feature requests, questions, or comments, we'd love to have you join
our rapidly-growing community! Linkerd is hosted on
[GitHub](https://github.com/linkerd/), and we have a thriving community on
[Slack](https://slack.linkerd.io/), [Twitter](https://twitter.com/linkerd), and
the [mailing lists](/community/get-involved/). Come and join the fun!

(_Photo by
[Etienne Girardet](https://unsplash.com/@etiennegirardet?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText)
on
[Unsplash](https://unsplash.com/?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText)._)
