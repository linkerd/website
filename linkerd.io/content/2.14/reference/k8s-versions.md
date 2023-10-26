+++
title = "Supported Kubernetes Versions"
description = "Reference documentation for which Linkerd version supports which Kubernetes version"
+++

Linkerd supports all versions of Kubernetes that were supported at the time
that a given Linkerd version ships. For example, at the time that Linkerd
stable-2.14.0 shipped, Kubernetes versions 1.26, 1.27, and 1.28 were
supported, so Linkerd stable-2.14.0 supports all of those Kubernetes versions.
(In many cases, as you'll see below, Linkerd versions will also support older
Kubernetes versions.)

Obviously, Linkerd stable-2.14.0 has no knowledge of what changes will come
_after_ Kubernetes 1.28. In some cases, later versions of Kubernetes end up
making changes that cause older versions of Linkerd to not work: we will
update the chart below as these situations arise.

| Linkerd Version | Minimum Kubernetes Version | Maximum Kubernetes Version |
|-----------------|----------------------------|----------------------------|
| `stable-2.10`   | `1.21`                     | `1.25`                     |
| `stable-2.11`   | `1.21`                     | `1.25`                     |
| `stable-2.12`   | `1.21`                     | `1.25`                     |
| `stable-2.13`   | `1.21`                     | `1.28`                     |
| `stable-2.14`   | `1.21`                     | `1.28`                     |

(Linkerd will never change the supported Kubernetes version in a minor
release, which is why the table above only lists major versions.)
