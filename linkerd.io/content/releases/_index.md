---
title: Releases and Versions
type: docs
---

<!-- markdownlint-disable MD013 -->

Linkerd publishes and announces _versions_ that correspond to specific project
milestones and sets of new features. These versions are available in different
types of _release artifacts_.

## Recent versions

{{< card "Linkerd 2.18" >}}

Linkerd 2.18 was announced on April 23, 2025.

- **Announcement**:
  [Announcing Linkerd 2.18: Battlescars, lessons learned, and preliminary Windows support](/2025/04/23/announcing-linkerd-2.18/)
- **Code tag**:
  [version-2.18](https://github.com/linkerd/linkerd2/releases/tag/version-2.18)
- **Corresponding edge release**:
  [edge-25.4.4](https://github.com/linkerd/linkerd2/releases/tag/edge-25.4.4)

Known distributions of Linkerd 2.18:

- [Buoyant Enterprise for Linkerd 2.18](https://docs.buoyant.io/buoyant-enterprise-linkerd/2.18/)
  from Buoyant, creators of Linkerd

{{< /card >}}

{{< card "Linkerd 2.17" >}}

Linkerd 2.17 was announced on December 5, 2024.

- **Announcement**:
  [Announcing Linkerd 2.17: Egress, Rate Limiting, and Federated Services](/2024/12/05/announcing-linkerd-2.17/)
- **Code tag**:
  [version-2.17](https://github.com/linkerd/linkerd2/releases/tag/version-2.17)
- **Corresponding edge release**:
  [edge-24.11.8](https://github.com/linkerd/linkerd2/releases/tag/edge-24.11.8)

Known distributions of Linkerd 2.17:

- [Buoyant Enterprise for Linkerd 2.17](https://docs.buoyant.io/buoyant-enterprise-linkerd/2.17/)
  from Buoyant, creators of Linkerd

{{< /card >}}

{{< card "Linkerd 2.16" >}}

Linkerd 2.16 was announced on August 13, 2024.

- **Announcement**:
  [Announcing Linkerd 2.16! Metrics, retries, and timeouts for HTTP and gRPC routes; IPv6 support; policy audit mode; VM workload automation; and lots more](/2024/08/13/announcing-linkerd-2.16/)
- **Code tag**:
  [version-2.16](https://github.com/linkerd/linkerd2/releases/tag/version-2.16)
- **Corresponding edge release**:
  [edge-24.8.2](https://github.com/linkerd/linkerd2/releases/tag/edge-24.8.2)

Known distributions of Linkerd 2.16:

- [Buoyant Enterprise for Linkerd 2.16](https://docs.buoyant.io/buoyant-enterprise-linkerd/2.16/)
  from Buoyant, creators of Linkerd

{{< /card >}}

{{< card "Linkerd 2.15" >}}

Linkerd 2.15 was announced on February 21, 2024.

- **Announcement**:
  [Announcing Linkerd 2.15 with mesh expansion, native sidecars, and SPIFFE](/2024/02/21/announcing-linkerd-2.15/)
- **Code tag**:
  [version-2.15](https://github.com/linkerd/linkerd2/releases/tag/version-2.15)
- **Corresponding edge release**:
  [edge-24.2.4](https://github.com/linkerd/linkerd2/releases/tag/edge-24.2.4)

Known distributions of Linkerd 2.15:

- [Buoyant Enterprise for Linkerd 2.15](https://docs.buoyant.io/buoyant-enterprise-linkerd/2.15/)
  from Buoyant, creators of Linkerd

{{< /card >}}

## Types of release artifacts

### Edge releases

<!-- markdownlint-disable MD034 -->

Edge release artifacts are published on a weekly or near-weekly basis as part of
the open source project. The latest edge release is [{{< latest-edge-version
>}}](https://github.com/linkerd/linkerd2/releases/tag/{{<
latest-edge-version >}}). and the full list of edge release artifacts can be
found on
[the Linkerd GitHub releases page](https://github.com/linkerd/linkerd2/releases).

Edge release artifacts contain the code in from the _main_ branch at the point
in time when they were cut. This means they always have the latest features and
fixes, and have undergone automated testing as well as maintainer code review.
Edge releases may involve partial features that are later modified or backed
out. They may also involve breaking changes—of course, we do our best to avoid
this.

Edge releases are generally considered _production ready_, and the project will
mark specific releases as "not recommended" if bugs are discovered after
release.

Edge release versioning follows the form `edge-y.m.n`, where `y` is the last two
digits of the year, `m` is the numeric month, and `n` is numeric edge release
count for that month. For example, `edge-24.1.3` is the third edge release
shipped in January 2024.

Each major version has a corresponding edge release, indicated by `version-2.X`
tags: for example, there is a
[`version-2.18`](https://github.com/linkerd/linkerd2/releases/tag/version-2.18)
tag that corresponds to `edge-25.4.4`. Of course, you may choose to run later
edge releases, which will include further bugfixes and enhancements.

Using edge release artifacts and reporting bugs helps us ensure a rapid pace of
development and is a great way to help Linkerd. We publish edge release guidance
as part of the release notes and strive to always provide production-ready
artifacts.

### Stable releases

Stable release artifacts of Linkerd follow semantic versioning, whereby changes
in major version denote large feature additions and possible breaking changes
and changes in minor versions denote safe upgrades without breaking changes.

As of February 2024, the Linkerd open source project itself no longer provides
stable release artifacts. Instead, the vendor community around Linkerd is
responsible for creating stable release artifacts.
