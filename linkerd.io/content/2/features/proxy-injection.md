+++
title = "Automatic Proxy Injection"
description = "Linkerd will automatically inject the data plane proxy into your pods based annotations."
weight = 5
aliases = [
  "/2/proxy-injection/"
]
+++

Linkerd automatically adds the data plane proxy to pods when the
`linkerd.io/inject: enabled` annotation is present on a namespace, deployment,
or pod. This is known as "proxy injection".

(The behavior of this feature has changed over Linkerd releases. This document
describes the behavior as of Linkerd 2.4 and beyond.)

See [Adding Your Service](/2/tasks/adding-your-service) for a walkthrough of
how to use this feature in practice.

## Details

Proxy injection is implemented as a [Kubernetes admission
webhook](https://kubernetes.io/docs/reference/access-authn-authz/extensible-admission-controllers/#admission-webhooks).
This means that the proxies are added by the Kubernetes cluster itself,
regardless of whether the pods are created by `kubectl`, a CI/CD system, or any
other source.

Note that simply adding the annotation on a namespace will not automatically
update all the resources. You will need to update the resources in this
namespace (e.g.  with `kubectl apply`, `kubectl edit`, etc.) for them to be
injected. This is because Kubernetes will not call the webhook until it sees an
update on each individual resource.


For each pod, two containers are injected:

1. `linkerd-init`, a Kubernetes [Init
   Container](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/)
   that configures `iptables` to automatically forward all incoming and
   outgoing TCP traffic through the proxy. (Note that this container is not
   present if the [Linkerd CNI Plugin](/2/features/cni/) has been enabled.)

1. `linkerd-proxy`, the Linkerd data plane proxy itself.

## Overriding injection

Automatic injection can be disabled for a pod or deployment for which it would
otherwise be enabled, by adding the `linkerd.io/inject: disabled` annotation.

## Manual injection

The [`linkerd inject`](/2/reference/cli/inject/) CLI command is a text
transform that, by default, simply adds the inject annotation to a given
Kubernetes manifest.

Alternatively, this command can also perform the full injection purely on the
client side with the `--manual` flag. This was the default behavior prior to
Linkerd 2.4; however, having injection to the cluster side makes it easier to
ensure that the data plane is always present and configured correctly,
regardless of how pods are deployed.

See the [`linkerd inject` reference](/2/reference/cli/inject/) for more
information.
