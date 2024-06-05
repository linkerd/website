+++
title = "Releases and Versions"
aliases = [ "edge" ]
weight = 18
+++

Releases of Linkerd are available in several different forms.

## Stable releases

Stable release artifacts of Linkerd follow semantic versioning, whereby changes
in major version denote large feature additions and possible breaking changes
and changes in minor versions denote safe upgrades without breaking changes.

As of February 2024, Linkerd no longer provides stable release artifacts in the
open source project itself. Instead, the vendor community around Linkerd is
responsible for creating stable release artifacts. Known distributions of
Linkerd with stable release artifacts include:

- [Buoyant Enterprise for Linkerd](https://docs.buoyant.io/buoyant-enterprise-linkerd)
  from Buoyant, creators of Linkerd.
  Latest version: **enterprise-2.15.3**
  [[release notes](https://docs.buoyant.io/release-notes/buoyant-enterprise-linkerd/enterprise-2.15.3/)].

## Edge releases

Edge release artifacts are published on a weekly or near-weekly basis as part of
the open source project. The full list of edge release artifacts can be found on
[the Linkerd GitHub releases
page](https://github.com/linkerd/linkerd2/releases).

Edge release artifacts contain the code in from the _main_ branch at the point
in time when they were cut. This means they always have the latest features and
fixes, and have undergone automated testing as well as maintianer code review.
Edge releases may involve partial features that are later modified or backed
out. They may also involve breaking changes—of course, we do our best to avoid
this.

Edge release versioning follows the form `edge-y.m.n`, where `y` is the last two
digits of the year, `m` is the numeric month, and `n` is numeric edge release
count for that month. For example:

- `edge-23.9.1`: the first edge release shipped in September 2023
- `edge-24.1.3`: the third edge release shipped in January 2024

Using edge release artifacts and reporting bugs helps us ensure a rapid pace of
development and is a great way to help Linkerd. We publish edge release guidance
as part of the release notes and strive to always provide production-ready
artifacts.

<!-- markdownlint-disable MD034 -->

## Versions

Like many projects, Linkerd publishes and announces major *versions* that
correspond to specific project milestones and sets of new features.

### Linkerd 2.15

The latest major version is Linkerd 2.15.

- Release date: February 21, 2024.
- Announcement post: [Announcing Linkerd 2.15 with mesh expansion, native
sidecars, and SPIFFE](/2024/02/21/announcing-linkerd-2.15/).
- Code tag:
[version-2.15](https://github.com/linkerd/linkerd2/releases/tag/version-2.15).
- Edge releases:
[edge-24.2.4](https://github.com/linkerd/linkerd2/releases/tag/edge-24.2.4)
through [{{% latestedge
%}}](https://github.com/linkerd/linkerd2/releases/tag/{{% latestedge %}}).
