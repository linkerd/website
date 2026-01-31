---
title: Uninstalling Multicluster
description: Unlink and uninstall Linkerd multicluster.
---

The Linkerd multicluster components allow for sending traffic from one cluster
to another. For more information on how to set this up, see
[installing multicluster](installing-multicluster/).

## Unlinking

Unlinking a cluster will delete all resources associated with that link
including:

- the service mirror controller
- the Link resource
- the credentials secret
- mirror services

It is recommended that you use the `unlink` command rather than deleting any of
these resources individually to help ensure that all mirror services get cleaned
up correctly and are not left orphaned.

To unlink, run the `linkerd multicluster unlink` command and pipe the output to
`kubectl delete`:

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

Attempting to uninstall while at least one link remains will result in an error.
