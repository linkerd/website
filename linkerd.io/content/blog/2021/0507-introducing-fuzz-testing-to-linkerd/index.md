---
title: Introducing fuzz testing for Linkerd
date: 2021-05-07T00:00:00Z
slug: fuzz-testing-for-linkerd
keywords: [linkerd]
params:
  author: william
  showCover: true
---

Over the past few months, the team at [Ada Logics](https://adalogics.com/) has
been hard at work introducing fuzz testing to [Linkerd's Rust
proxy](https://linkerd.io/2020/07/23/under-the-hood-of-linkerds-state-of-the-art-rust-proxy-linkerd2-proxy/).
These fuzz tests now run continuously on Linkerd via Google's
[OSS-Fuzz](https://github.com/google/oss-fuzz) service, providing another layer
of safety for Linkerd users around the globe. In total, fuzzing was integrated
into seven dependencies of the proxy as well as the proxy itself, and five of
these projects are now running continuously on OSS-Fuzz.

These fuzz tests uncovered two minor bugs in the proxy, which have since been
fixed. (By comparison, a similar recent effort on a C-based CNCF project found
(and fixed) over 30 bugs, primarily related to memory safety). In addition, a
few minor issues were found in dependencies, and these have all been
communicated to the maintainers.

You can read the [full report
here](https://github.com/linkerd/linkerd2-proxy/blob/main/docs/reports/linkerd2-proxy-fuzzing-report.pdf).
For details, and how you can get involved in this important safety measure for
Linkerd, read on!

(Background reading: [Under the hood of Linkerd's state-of-the-art Rust proxy,
Linkerd2-proxy](https://linkerd.io/2020/07/23/under-the-hood-of-linkerds-state-of-the-art-rust-proxy-linkerd2-proxy/);
and [Why Linkerd doesn't use
Envoy](https://linkerd.io/2020/12/03/why-linkerd-doesnt-use-envoy/).)

## Why fuzz test the proxy?

Fuzz testing is a type of automated software testing that uses randomized
inputs and coverage-based genetic algorithms to evaluate the behavior of code.
Because the input is randomly generated, fuzz testing is useful in capturing
test cases that humans might miss, especially when it comes to corner cases
around invalid or unexpected inputs.

Linkerd uses [an arsenal of automated
tests](https://github.com/linkerd/linkerd2/actions) to ensure safety and
reliability on every commit. These tests range from code linting and static
analysis, to unit tests, to a comprehensive suite of integration tests. While
these tests play a major part of Linkerd's development process, there are
three reasons why we wanted to augment them with fuzz testing of the proxy in
particular:

1. **Linkerd's proxy handles untrusted input from the network.** The proxy must
take a request from an application or possibly from the open Internet; parse
the data; and "do something" with it—send it to its destination, reject it,
etc. While Rust's memory safety guarantees help us avoid an entire class of
security vulnerabilities that are endemic to C and C++ code, that, of course,
doesn't prevent other types of bugs. And the threshold for resilience in the
proxy is _extremely_ high—it must be able to handle even the worst-case
scenario of malicious input crafted by someone with full source code access.

2. **The data plane proxy is the most critical runtime component of any service
mesh.** While Linkerd is designed so that a temporary failure of control plane
components does not affect running applications, temporary failures at the data
plane level means that pods are unable to process requests. And beyond simple
failures, the worst-case scenario for bugs in the proxy is horrifying: changing
or corrupting a request could be disastrous; not handling mTLS correctly could
expose traffic to attackers; and so on. Thus, it behoves us to have the most
robust set of tests possible, in addition to our existing reliability practices
around code review, etc.

3. **The fuzz testing ecosystem for Rust is simply underdeveloped compared to
that of other languages.** Investing in this critical area meant that not just
Linkerd, but other projects that are built on the state-of-the-art Rust
networking ecosystem (projects like [Tokio](https://tokio.rs/),
[Hyper](https://hyper.rs/), [Rustls](https://github.com/ctz/rustls), and
[Tower](https://github.com/tower-rs/tower)) could all benefit from this work—a
win for everyone.

## What did the fuzz testing find?

The initial fuzz tests found two minor bugs in Linkerd's proxy.[^1] First, the
proxy would panic when a DNS lookup resulted in names exceeding 255 bytes, due
to [a bug in the trust-dns
library](https://github.com/bluejekyll/trust-dns/issues/1447) the proxy uses
for DNS queries. This issue was fixed immediately by the maintainers of that
library and the fix incorporated in recent Linkerd releases.

Second, the proxy would panic when resolving IPv6 addresses with port 80. (Most
Kubernetes providers do not yet support IPv6, but the proxy is future-proofed
for when they do.) This was [a bug in the proxy
itself](https://github.com/linkerd/linkerd2-proxy/pull/976), and was also fixed
immediately with the fix incorporated into recent Linkerd releases.

These bugs demonstrate the value of fuzz testing: they represent logical flaws
in the proxy (and dependent libraries) that involved unexpected edge cases, in
code which had passed several rounds of human review.

While no two projects are alike, as a point of comparison, a recent similar
exercise by Ada Logics on a graduated CNCF project written in C yielded over 30
bugs, including 4 "high severity" and 8 "medium severity" bugs. The majority of
these bugs were buffer overflows, null dereferences, memory leaks, and other
types of memory errors that Linkerd's use of Rust allows us to avoid in the
first place.
([link](https://www.cncf.io/blog/2020/12/15/securing-open-source-fuzzing-integration-vulnerability-analysis-and-bug-fixing-of-fluent-bit/))

## So what's next?

The fact that the fuzz tests found bugs is great! But this is just the
beginning, not the end, of the fuzz testing story. This initial work only
captured a portion of the proxy's surface area, and there's a lot more that
could benefit from fuzz testing.

If you're looking for ways to get involved with Linkerd—and we'd love to have
you—the good news is that this is yet another avenue by which you can help the
project. If you're interested in further building out Linkerd's set of fuzz
tests, please see [the developer docs for proxy fuzzing in
Linkerd](https://github.com/linkerd/linkerd2-proxy/blob/main/docs/FUZZING.md),
hop into `#contributors` on [the Linkerd Slack](https://slack.linkerd.io), and
let's make it happen!

## Thank you

The Linkerd maintainers would like to issue a special thank-you to the Ada
Logics team and David Korczynski in particular for their hard work in
implementing these fuzzers, for wading into the uncharted waters of fuzz
testing for Rust, and for helping us navigate the OSS-Fuzz project. We'd also
like to thank the CNCF, especially Chris Aniszczyk, for sponsoring this work.

## Linkerd is for everyone

Linkerd is a community project and is hosted by the
[Cloud Native Computing Foundation](https://cncf.io/). Linkerd is
[committed to open governance.](https://linkerd.io/2019/10/03/linkerds-commitment-to-open-governance/)
If you have feature requests, questions, or comments, we'd love to have you join
our rapidly-growing community! Linkerd is hosted on
[GitHub](https://github.com/linkerd/), and we have a thriving community on
[Slack](https://slack.linkerd.io/), [Twitter](https://twitter.com/linkerd), and
the [mailing lists](https://linkerd.io/2/get-involved/). Come and join the fun!

(*Photo by [Prince Abid](https://unsplash.com/@princeabid708?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText") on [Unsplash](https://unsplash.com/s/photos/fuzz?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText).*)

## Footnotes

[^1]: The tests are focused on finding situations that cause the proxy to "panic", or intentionally crash—an easily-detectable situation that is the consequence of the proxy finding itself in a situation it can't handle. A fuzz test that causes the proxy to panic in response to strange input is a sure sign of a bug.
