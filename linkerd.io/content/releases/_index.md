+++
title = "Releases"
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

The full list of edge releases can be found on
[GitHub](https://github.com/linkerd/linkerd2/releases).

## Stable

As of Linkerd 2.15.0, the open source project no longer publishes stable
releases. Instead, the vendor community around Linkerd is responsible for
supported, stable releases.

Known stable distributions of Linkerd include:

* [Buoyant Enterprise for
  Linkerd](https://docs.buoyant.io/buoyant-enterprise-linkerd) from Buoyant,
  creators of Linkerd.
