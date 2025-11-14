---
title: Migrating Gateway API Ownership
description:
  Instructions for migrating from a Linkerd-managed Gateway API to an externally
  managed Gateway API, ensuring no loss of dependent CRs during the transition.
---

As outlined in [Gateway API support](../features/gateway-api/), Linkerd uses the
Gateway API as a key configuration mechanism. Although Linkerd can install the
Gateway API CRDs independently, the Gateway API is an official Kubernetes
project maintained separately from Linkerd. For this reason, we recommend
following the official
[Gateway API installation guide](https://gateway-api.sigs.k8s.io/guides/#installing-gateway-api)
and managing these CRDs externally rather than relying on Linkerd to handle
them.

Not only is this approach recommended today, but starting with Linkerd 2.19,
installing Gateway API CRDs will no longer be the default behavior (when
installing with Helm).

To migrate from a Linkerd-managed Gateway API to an externally managed one—while
preserving any CRs dependent on these APIs—follow the steps below based on your
installation method.

## If Linkerd was installed with the CLI

Starting with version 2.18, the `linkerd upgrade --crds` command checks the
cluster for existing Gateway API CRDs before proceeding and avoids overwriting
them. To transition ownership of these CRDs to an external source, install the
externally provided CRDs _before_ upgrading Linkerd:

```bash
kubectl apply -f \
    https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.1.1/experimental-install.yaml
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

Next, overwrite Linkerd’s CRDs with the externally managed ones:

```bash
kubectl apply -f \
    https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.1.1/experimental-install.yaml
```

For all subsequent configuration updates or chart upgrades, use
`--set installGatewayAPI=false` to ensure the Gateway API CRDs remain externally
managed. Starting in version 2.19, this will become the default. The
`helm.sh/resource-policy: keep` annotation ensures the CRDs persist regardless
of this setting.
