+++
title = "Releases and Versions"
aliases = [ "edge" ]
weight = 18
+++

Linkerd is developed in the [Linkerd GitHub
repository](https://github.com/linkerd/linkerd2). Releases and packages of
Linkerd are available in several different forms.

## Edge (latest version: {{% latestedge %}})

All Linkerd development happens "on main": all changes, whether in support of
upcoming new features, refactors, bug fixes, or something else, land on the main
branch where they are merged together.

Edge releases contain the latest code in from the main branch at the point in
time when they were cut. This means they have the latest features and fixes, but
it also means they don't have stability guarantees. Upgrading between edge
releases may involve breaking changes, and may involve partial features that are
later modified or backed out.

**Note:** Edge releases may introduce breaking changes.

<!-- markdownlint-disable MD033 -->
Edge releases follow a version numbering scheme of the form `<two digit
year>.<month>.<number within the month>`. For example, `edge-24.1.2` is the
second edge release of January 2024.
<!-- markdownlint-enable MD033 -->

To install the latest edge release via the CLI, you can run:

```bash
curl --proto '=https' --tlsv1.2 -sSfL https://run.linkerd.io/install-edge | sh
```

The full list of edge releases can be found on
[GitHub](https://github.com/linkerd/linkerd2/releases).

## Stable

Stable releases are designed to introduce minimal change to an existing system
and come with documented stability guarantees. In stable releases, we take the
specific bug fix changes (or, occasionally, feature additions) and "back port"
these changes against the code in the previous stable version. This minimizes
the overall delta between releases. We also do any additional work required to
ensure that upgrades and rollbacks between stable releases are seamless and
contain no breaking changes.

As of Linkerd 2.15.0, the open source project no longer publishes stable
releases. Instead, the vendor community around Linkerd is responsible for
supported, stable releases.

Known stable distributions of Linkerd include:

* [Buoyant Enterprise for
  Linkerd](https://docs.buoyant.io/buoyant-enterprise-linkerd) from Buoyant,
  creators of Linkerd.

## Helm Chart Version Matrix

The following version matrices include only the latest versions of the stable
releases along with corresponding app and Helm versions for Linkerd and
extensions. Use these to guide you to the right Helm chart version or to
automate workflows you might have.

* [YAML matrix](./release_matrix.yaml)
* [JSON matrix](./release_matrix.json)

{{< release-data-table />}}
