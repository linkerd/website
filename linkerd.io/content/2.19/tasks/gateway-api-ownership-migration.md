---
title: Migrating Gateway API Ownership in Linkerd 2.18
description: Migrating from a Linkerd-managed Gateway API to an externally managed one as part of upgrading to Linkerd 2.18
---

Linkerd [uses the Gateway API as a key configuration
mechanism](../features/gateway-api/). Prior to Linkerd 2.18, Linkerd would
optionally install the Gateway API types on your cluster and manage them for
you--it optionally "owned" the types. From Linkerd 2.19 onwards, Linkerd will
longer own the Gateway API types on your behalf. Thus, Linkerd 2.18 itself is a
_transition_ release, where you need to remove the ownership of any
Linkerd-installed Gateway API resources.

All Linkerd users upgrading to 2.18 who have Linkerd-managed Gateway API CRDs
will need to transition this ownership away from Linkerd, by following the steps
below.

To migrate from a Linkerd-managed Gateway API to an externally managed one—while
preserving any CRs dependent on these APIs—follow the steps below based on your
installation method.

## Determining whether Linkerd currently owns the Gateway API CRDs

To determine whether Linkerd owns the Gateway API CRDs, run:

```bash
kubectl get crds/httproutes.gateway.networking.k8s.io -ojsonpath='{.metadata.annotations.linkerd\.io/created-by}'
```

If this command returns a NotFound error, the CRDs are not installed. If this
command returns an _empty result_, the CRDs are not managed by Linkerd. If this
command returns a string including "linkerd", the CRDs _are_ managed by Linkerd.

## If Linkerd was installed with the CLI

Starting with Linkerd 2.18, the `linkerd upgrade --crds` command checks the
cluster for existing Gateway API CRDs before proceeding and avoids overwriting
them. To transition ownership of these CRDs to an external source, install the
externally provided CRDs _before_ upgrading to Linkerd 2.18:

```bash
kubectl apply -f \
    https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.1/standard-install.yaml
```

Next, run the usual upgrade command:

```bash
linkerd upgrade --crds | kubectl apply -f -
```

This process ensures that the externally provided Gateway API CRDs remain
untouched while still applying updates to Linkerd’s other non-Gateway API CRDs.

## If Linkerd was installed with Helm

Unlike the CLI, Helm’s upgrade process cannot dynamically check the cluster’s
Gateway API state, so the migration steps differ slightly. Begin by upgrading
the linkerd-crds chart as you normally would (modify according to the helm
release name and repo name you used):

```bash
# Don't include --set installGatewayAPI=false here! See the warning below.
helm upgrade -n linkerd linkerd-crds linkerd/linkerd-crds
```

{{< warning >}}
Do not include `--set installGatewayAPI=false` at this stage, as it would delete
the Gateway API CRDs and their associated CRs, disrupting any defined policies
and routes.
{{< /warning >}}

With version 2.18, this upgrade annotates the Linkerd-provided Gateway API CRDs
with `helm.sh/resource-policy: keep`. This annotation prevents the linkerd-crds
chart from removing the CRDs and their CRs in future updates.

Next, overwrite
Linkerd’s CRDs with the externally managed ones:

```bash
kubectl apply -f \
    https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.1/standard-install.yaml
```

For all subsequent configuration updates or chart upgrades, use `--set
installGatewayAPI=false` to ensure the Gateway API CRDs remain externally
managed. Starting in version 2.19, this will become the default. The
`helm.sh/resource-policy: keep` annotation ensures the CRDs persist regardless
of this setting.
