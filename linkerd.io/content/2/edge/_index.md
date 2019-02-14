+++
date = "2018-07-31T12:00:00-07:00"
title = "Release Channels"
[menu.l5d2docs]
  name = "Release Channels"
  weight = 18
+++

Linkerd 2.x publishes releases into multiple channels. This provides the option to
choose between stability or getting the latest and greatest functionality. The
latest release for each channel is listed below. The full list of releases can
be found on [GitHub](https://github.com/linkerd/linkerd2/releases).

# Stable (latest version: {{% latestversion %}})

Stable releases are periodic, and focus on stability. To install a stable
release, you can run:

```bash
curl -sL https://run.linkerd.io/install | sh
```

# Edge (latest version: {{% latestedge %}})

Edge releases are frequent (usually, weekly) and can be used to work with the
latest and greatest features. These releases are intended to be stable, but are
more focused on adding new functionality. To install an edge release, you can
run:

```bash
curl -sL https://run.linkerd.io/install-edge | sh
```
