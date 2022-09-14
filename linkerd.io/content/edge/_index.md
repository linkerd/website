+++
title = "Release Channels"
weight = 18
+++

Linkerd 2.x publishes releases into multiple channels. This provides the option to
choose between stability or getting the latest and greatest functionality. The
latest release for each channel is listed below. The full list of releases can
be found on [GitHub](https://github.com/linkerd/linkerd2/releases).

## Stable (latest version: {{% latestversion %}})

Stable releases are published periodically and are intented for production use.
See the [Linkerd installation guide](../{{% latestversion %}}/tasks/install/)
for how to install a stable release.

For stable releases, Linkerd follows a version numbering scheme of the form
`2.<major>.<minor>`. In other words, "2" is a static prefix, followed by the
major version, then the minor.

Changes in minor versions are intended to be backwards compatible with the
previous version. Changes in major version *may* introduce breaking changes,
although we try to avoid that whenever possible.

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
