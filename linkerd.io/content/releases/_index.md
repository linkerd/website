+++
title = "Releases"
aliases = [ "edge" ]
weight = 18
+++

Releases and packages of Linkerd are available in several different forms.

## Edge releases (latest version: {{% latestedge %}})

All Linkerd development happens "on main": all changes, whether security
patches, new features, refactors, bug fixes, or something else, land on the main
branch.

Edge release artifacts contain the latest code in from the main branch, at the
point in time when they were cut. This means they have the latest features and
fixes, but it also means may involve partial features that are later modified or
backed out. They may involve breaking changes—of course, we do our best to avoid
this.

Using edge release artifacts and reporting bugs is a great way to help Linkerd.

The full list of edge release artifacts can be found on
[the Linkerd GitHub releases page](https://github.com/linkerd/linkerd2/releases).

<!-- markdownlint-disable MD034 -->
Latest version: **{{% latestedge %}}** [[release
notes](https://github.com/linkerd/linkerd2/releases/tag/{{% latestedge %}})].

## Stable releases

As of February 2024, the vendor community around Linkerd is responsible for
supported, stable release artifacts. Known distributions of Linkerd with stable
release artifacts are:

* [Buoyant Enterprise for
  Linkerd](https://docs.buoyant.io/buoyant-enterprise-linkerd) from Buoyant,
  creators of Linkerd. Latest version:
  **enterprise-2.15.2** [[release
  notes](https://docs.buoyant.io/release-notes/buoyant-enterprise-linkerd/enterprise-2.15.2/)].
