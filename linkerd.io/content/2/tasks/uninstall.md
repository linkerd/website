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

## Removing the control plane

{{< note >}}
Uninstallating the control plane requires cluster-wide permissions.
{{< /note >}}

To remove the [control plane](/2/reference/architecture/#control-plane), run:

```bash
linkerd uninstall | kubectl delete -f -
```

The `linkerd uninstall` command outputs the manifest for all of the Kubernetes
resources necessary for the control plane, including namespaces, service
accounts, CRDs, and more; `kubectl delete` then deletes those resources.

This command can also be used to remove control planes that have been partially
installed. Note that `kubectl delete` will complain about any resources that it
was asked to delete that hadn't been created, but these errors can be safely
ignored.
