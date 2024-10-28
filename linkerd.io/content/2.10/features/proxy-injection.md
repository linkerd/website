---
title: Automatic Proxy Injection
description: Linkerd will automatically inject the data plane proxy into your pods
  based annotations.
---

Linkerd automatically adds the data plane proxy to pods when the
`linkerd.io/inject: enabled` annotation is present on a namespace or any
workloads, such as deployments or pods. This is known as "proxy injection".

See [Adding Your Service](../../tasks/adding-your-service/) for a walkthrough of
how to use this feature in practice.

{{< note >}}
Proxy injection is also where proxy *configuration* happens. While it's rarely
necessary, you can configure proxy settings by setting additional Kubernetes
annotations at the resource level prior to injection. See the [full list of
proxy configuration options](../../reference/proxy-configuration/).
{{< /note >}}

## Details

Proxy injection is implemented as a [Kubernetes admission
webhook](https://kubernetes.io/docs/reference/access-authn-authz/extensible-admission-controllers/#admission-webhooks).
This means that the proxies are added to pods within the Kubernetes cluster
itself, regardless of whether the pods are created by `kubectl`, a CI/CD
system, or any other system.

For each pod, two containers are injected:

1. `linkerd-init`, a Kubernetes [Init
   Container](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/)
   that configures `iptables` to automatically forward all incoming and
   outgoing TCP traffic through the proxy. (Note that this container is not
   present if the [Linkerd CNI Plugin](../cni/) has been enabled.)
1. `linkerd-proxy`, the Linkerd data plane proxy itself.

Note that simply adding the annotation to a resource with pre-existing pods
will not automatically inject those pods. You will need to update the pods
(e.g. with `kubectl rollout restart` etc.) for them to be injected. This is
because Kubernetes does not call the webhook until it needs to update the
underlying resources.

## Overriding injection

Automatic injection can be disabled for a pod or deployment for which it would
otherwise be enabled, by adding the `linkerd.io/inject: disabled` annotation.

## Manual injection

The [`linkerd inject`](../../reference/cli/inject/) CLI command is a text
transform that, by default, simply adds the inject annotation to a given
Kubernetes manifest.

Alternatively, this command can also perform the full injection purely on the
client side with the `--manual` flag. This was the default behavior prior to
Linkerd 2.4; however, having injection to the cluster side makes it easier to
ensure that the data plane is always present and configured correctly,
regardless of how pods are deployed.

See the [`linkerd inject` reference](../../reference/cli/inject/) for more
information.
