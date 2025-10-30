---
title: Uninstalling Multicluster
description: Unlink and uninstall Linkerd multicluster.
---

The Linkerd multicluster components allow for sending traffic from one cluster
to another. For more information on how to set this up, see [installing multicluster](installing-multicluster/).

## Unlinking

In order to unlink a cluster you need to:

1) Remove the `mirror.linkerd.io/exported=true` labels from the mirrored
services in the target clusters, for the controllers to delete the mirror
services in the local cluster.
2) Update the linkerd-multicluster chart, removing the matching entry from the
`controllers` array within the chart's values. This will remove from the cluster
the controllers and their associated resources.
3) Delete the Link CR.
4) Delete the kubeconfig secrets `cluster-credentials-<target>` in both the
`linkerd` and `linkerd-multicluster` namespaces.

### Unlinking in Earlier Versions of Linkerd (pre-`v2.18`)

Before version `v2.18`, the multicluster controllers were not directly managed
by the multicluster extension and needed to be created using the `linkerd
multicluster link` command. To correctly unlink a cluster in this scenario,
execute the `linkerd multicluster unlink` command and pipe its output to `kubectl
delete`:

```bash
linkerd multicluster unlink --cluster-name=target | kubectl delete -f -
```

## Uninstalling

Uninstalling the multicluster components will remove all components associated
with Linkerd's multicluster functionality including the gateway and service
account. Before you can uninstall, you must remove all existing links as
described above. Once all links have been removed, run:

```bash
linkerd multicluster uninstall | kubectl delete -f -
```

Attempting to uninstall while at least one Link CR remains will result in an
error.
