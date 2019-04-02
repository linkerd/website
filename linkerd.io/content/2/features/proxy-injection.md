+++
title = "Automatic Proxy Injection"
description = "Linkerd can be configured to automatically inject the data plane proxy into your service."
weight = 4
aliases = [
  "/2/proxy-injection/"
]
+++

Linkerd can be configured to automatically inject the data plane proxy into your
service. This is an alternative to needing to run the
[`linkerd inject`](/2/reference/cli/inject/) command. Moving injection to the
cluster side, rather than relying on client side behavior, can help ensure that
the data plane is always present and configured correctly, regardless of how
pods are deployed.

Automatic injection works alongside Kubernetes package managers such as
[Helm](https://helm.sh/) to remove the possibility for things to go wrong. You
can set it up for yourself by following the guide:

- [Automating Injection](/2/tasks/automating-injection/)
- [Proxy Configuration](/1/features/proxy-configuration/)
