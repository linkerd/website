+++
title = "Upgrading Multicluster in Linkerd 2.9"
description = "Upgrading Multicluster to Linkerd 2.9."
+++

Linkerd 2.9 changes the way that some of the multicluster components work and
are installed compared to Linkerd 2.8.x. Users installing the multicluster
components for the first time with Linkerd 2.9 can ignore these instructions
and instead refer directly to the [installing multicluster](../installing-multicluster/).

Users who installed the multicluster component in Linkerd 2.8.x and wish to
upgrade to Linkerd 2.9 should follow these instructions.

## Overview

The main differences between multicluster in 2.8 and 2.9 is that in 2.9 we
create a service mirror controller for each target cluster that a source
cluster is linked to. The service mirror controller is created as part of the
`linkerd multicluster link` command instead of the `linkerd multicluster install`
command. There is also a new CRD type called `Link` which is used to configure
the service mirror controller and allows you to be able to specify the label
selector used to determine which services to mirror.

## Ordering of Cluster Upgrades

Clusters may be upgraded in any order regardless of if each cluster is source
cluster, target cluster, or both.

## Target Clusters

A cluster which receives multicluster traffic but does not send multicluster
traffic requires no special upgrade treatment. It can safely be upgraded by
just upgrading the main Linkerd controller plane:

```bash
linkerd upgrade | kubectl apply -f -
```

## Source Clusters

A cluster which sends multicluster traffic must be upgraded carefully to ensure
that mirror services remain up during the upgrade so as to avoid downtime.

### Control Plane

Begin by upgrading the Linkerd control plane and multicluster resources to
version 2.9 by running

```bash
linkerd upgrade | kubectl apply -f -
linkerd --context=source multicluster install | kubectl --context=source apply -f -
linkerd --context=target multicluster install | kubectl --context=target apply -f -
```

### Label Exported Services

Next must apply a label to each exported service in the target cluster. This
label is how the 2.9 service mirror controller will know to mirror those
services. The label can be anything you want, but by default we will use
`mirror.linkerd.io/exported=true`. For each exported service in the target
cluster, run:

```bash
kubectl --context=target label svc/<SERVICE NAME> mirror.linkerd.io=true
```

Any services not labeled in this way will no longer be mirrored after the
upgrade is complete.

### Upgrade Link

Next we re-establish the link. This will create a 2.9 version of the service
mirror controller. Note that this is the same command that you used to establish
the link while running Linkerd 2.8 but here we are running it with version 2.9
of the Linkerd CLI:

```bash
linkerd --context=target multicluster link --cluster-name=<CLUSTER NAME> \
    | kubectl --context=source apply -f -
```

If you used a label other than `mirror.linkerd.io/exported=true` when labeling
your exported services, you must specify that in the `--selector` flag:

```bash
linkerd --context=target multicluster link --cluster-name=<CLUSTER NAME> \
    --selector my.cool.label=true | kubectl --context=source apply -f -
```

There should now be two service mirror deployments running: one from version
2.8 called `linkerd-service-mirror` and one from version 2.9 called
`linkerd-service-mirror-<CLUSTER NAME>`. All mirror services should remain
active and healthy.

### Cleanup

The 2.8 version of the service mirror controller can now be safely deleted:

```bash
kubectl --context=source -n linkerd-multicluster delete deploy/linkerd-service-mirror
```

Ensure that your cluster is still in a healthy state by running:

```bash
linkerd --context=source multicluster check
```

Congratulations, your upgrade is complete!
