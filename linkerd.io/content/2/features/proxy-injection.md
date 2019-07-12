+++
title = "Automatic Proxy Injection"
description = "Linkerd will automatically inject the data plane proxy into your pods based annotations."
weight = 5
aliases = [
  "/2/proxy-injection/"
]
+++

Linkerd will automatically inject the data plane proxy into pods when the
`linkerd.io/inject: enabled` annotation is present on a namespace, deployment,
or pod.

For convenience, the [`linkerd inject`](/2/reference/cli/inject/) text
transform command will add this annotation to a given Kubernetes manifest.

## Details

Proxy injection is implemented as a [Kubernetes admission
webhook](https://kubernetes.io/docs/reference/access-authn-authz/extensible-admission-controllers/#admission-webhooks). There are a couple things to note about this feature:

* Simply adding the annotation on a namespace will not automatically update all
  the resources. You will need to update the resources in this namespace (e.g.
  with `kubectl apply`, `kubectl edit`, etc.) for them to be injected. This is because
  Kubernetes will not call the mutating webhook until it sees an update on each
  individual resource.
* The behavior of this feature has changed over Linkerd releases. This document
  describes the behavior as of Linkerd 2.4 and beyond.

For each pod, two containers are injected:

1. `linkerd-init`, a Kubernetes [Init
   Container](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/)
   that configures `iptables` to automatically forward all incoming and
   outgoing TCP traffic through the proxy. (Note that this container is not
   present if the [Linkerd CNI Plugin](/2/features/cni/) has been enabled.)

1. `linkerd-proxy`, the Linkerd data plane proxy.

## Overriding injection

Automatic injection can be disabled for a pod or deployment for which it would
otherwise be enabled, by adding the `linkerd.io/inject: disabled` annotation.

## Example

To add automatic proxy injection for all pods in the `sample-inject-enabled-ns`
namespace, add the `linkerd.io/inject: enabled` annotation to the namespace as
follows:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: sample-inject-enabled-ns
  annotations:
    linkerd.io/inject: enabled
```

After applying that namespace configuration to your cluster, you can test
automatic proxy injection by creating a new deployment in that namespace, by
running:

```bash
kubectl -n sample-inject-enabled-ns run helloworld --image=buoyantio/helloworld
```

Verify that the deployment's pod includes a `linkerd-proxy` container by
running:

```bash
kubectl -n sample-inject-enabled-ns get po -l run=helloworld \
  -o jsonpath='{.items[0].spec.containers[*].name}'
```

If everything was successful, you'll see:

```bash
helloworld linkerd-proxy
```

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
