+++
title = "Uninstalling Linkerd"
description = "Linkerd can be easily removed from a Kubernetes cluster."
+++

Removing Linkerd from a Kubernetes cluster requires two steps: removing any
data plane proxies, and then removing the control plane.

## Removing Linkerd data plane proxies

To remove the Linkerd data plane proxies, you should remove any [Linkerd proxy
injection annotations](/2/features/proxy-injection/) and roll the deployments.
When Kubernetes recreates the pods, they will not have the Linkerd data plane
attached.

One way to do this is to use the `linkerd uninject` command to rewrite a
Kubernetes manifest. For example, to do this across all namespaces in one fell
swoop:

```bash
kubectl get --all-namespaces daemonset,deploy,job,statefulset \
    -l "linkerd.io/control-plane-ns" -o yaml \
  | linkerd uninject - \
  | kubectl apply -f -
```

This will fetch everything that has the Linkerd proxy sidecar, remove the
sidecar and re-apply to your cluster.

## Removing the control plane

{{< note >}}
Uninstallating the control plane will require cluster-wide permissions.
{{< /note >}}

To remove the [control plane](/2/reference/architecture/#control-plane), run:

```bash
linkerd install --ignore-cluster | kubectl delete -f -
```

The `linkerd install` command outputs the manifest for all of the Kubernetes
resources necessary for the control plane, including namespaces, service
accounts, CRDs, and more; `kubectl delete` then deletes those resources.

This command can also be used to remove control planes that have been partially
installed. `kubectl delete` will complain, but these errors can be ignored.
