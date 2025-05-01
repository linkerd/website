---
title: Using A Private Docker Repository
description: Using Linkerd with a Private Docker Repository.
---

In some cases, you will want to use a private docker repository to store the
Linkerd images. This scenario requires knowing the names and locations of the
docker images used by the Linkerd control and data planes so that you can
store them in your private repository.

The easiest way to get those images is to use the
[Linkerd CLI](../getting-started/#step-1-install-the-cli)
to pull the images to an internal host and push them to your private repository.

To get the names of the images used by the control plane, [install]
(../../getting-started/#step-1-install-the-cli)
the Linkerd CLI and run this command:

```bash
linkerd install --ignore-cluster | grep image: | sed -e 's/^ *//' | sort | uniq
```

For the current stable version, the output will be:

```bash
image: gcr.io/linkerd-io/controller:stable-2.6.0
image: gcr.io/linkerd-io/grafana:stable-2.6.0
image: gcr.io/linkerd-io/proxy-init:v1.2.0
image: gcr.io/linkerd-io/proxy:stable-2.6.0
image: gcr.io/linkerd-io/web:stable-2.6.0
image: prom/prometheus:v2.11.1
```

All of the Linkerd images are publicly available in the
[Linkerd Google Container Repository](https://console.cloud.google.com/gcr/docs/images/linkerd-io/GLOBAL/)

Stable images are named using the convention  `stable-<version>` and the edge
images use the convention `edge-<year>.<month>.<release-number>`.

Examples of each are: `stable-2.6.0` and `edge-2019.11.1`.

Once you have identified which images you want to store in your private
repository, use the `docker pull <image-name>` command to pull the images to
a machine on your network, then use the `docker push` command to push the
images to your private repository.

Now that the images are hosted by your private repository, you can update
your deployment configuration to pull from your private docker repository.

For a more advanced configuration, you can clone the [linkerd2 repository
](https://github.com/linkerd/linkerd2) to your CI/CD system and build
specific tags to push to your private repository.
