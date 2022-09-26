+++
title = "Releases and Versions"
aliases = [ "edge" ]
weight = 18
+++

The full list of Linkerd open source releases can be found on
[GitHub](https://github.com/linkerd/linkerd2/releases).

Linkerd 2.x publishes releases into multiple channels, _stable_ and _edge_.
The guarantees and expectations are different for each channel

## Stable (latest version: {{% latestversion %}})

Stable releases are published periodically and are intented for production use.
See the [Linkerd installation guide](https://linkerd.io/2/tasks/install/) for
how to install a stable release.

For stable releases, Linkerd follows a version numbering scheme of the form
`2.<major>.<minor>`. In other words, "2" is a static prefix, followed by the
major version, then the minor.

Changes in minor versions are intended to be backwards compatible with the
previous version and will typically not introduce major new features. Changes in
major version will typically introduce major new features, and *may* introduce
breaking changes—although we try to avoid that whenever possible.

**Support policy**: in general, we support the latest major stable version: we
will fix bugs by publishing minor version updates. At the maintainer's
discretion, these bugfixes may occasionally be back-ported to the previous major
stable version.

Stable versions earlier than the previous major version will not receive
bugfixes or enhancements.

Commercial providers of Linkerd (e.g. [Buoyant](https://buoyant.io)) may
provide stronger support guarantees.

## Edge (latest version: {{% latestedge %}})

Edge releases are frequent (usually, weekly) and can be used to work with the
latest and greatest features. Edge releases may introduce breaking changes.

For edge releases, Linkerd follows a version numbering scheme of the form
`<two digit year>.<month>.<number within the month>`. For example, `edge-22.9.4`
is the fourth edge release of September 2022.

To install the latest edge release via the CLI, you can run:

```bash
curl --proto '=https' --tlsv1.2 -sSfL https://run.linkerd.io/install-edge | sh
```

**Support policy**: there is no formal support policy for edge releases.
