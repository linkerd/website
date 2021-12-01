+++
title = "Installing Linkerd with Helm"
description = "Install Linkerd onto your own Kubernetes cluster using Helm."
+++

Linkerd can optionally be installed via Helm rather than with the `linkerd
install` command.

## Prerequisite: identity certificates

The identity component of Linkerd requires setting up a trust anchor
certificate, and an issuer certificate with its key. These must use the ECDSA
P-256 algorithm and need to be provided to Helm by the user (unlike when using
the `linkerd install` CLI which can generate these automatically). You can
provide your own, or follow [these instructions](../generate-certificates/)
to generate new ones.

## Adding Linkerd's Helm repository

```bash
# To add the repo for Linkerd stable releases:
helm repo add linkerd https://helm.linkerd.io/stable

# To add the repo for Linkerd edge releases:
helm repo add linkerd-edge https://helm.linkerd.io/edge
```

The following instructions use the `linkerd` repo. For installing an edge
release, just replace with `linkerd-edge`.

## Helm install procedure

You need to install two separate charts in succession: first `linkerd-base` and
then `linkerd-control-plane`.

### linkerd-base

The `linkerd-base` chart sets up all the cluster-level resources, including
CRDs. Therefore it requires cluster-level privileges for setting it up:

```bash
helm install linkerd-base -n linkerd --create-namespace linkerd/linkerd-base
```

{{< note >}}
This will create the `linkerd` namespace. If it already exists or you're
creating it beforehand elsewhere in your pipeline, just omit the
`--create-namespace` flag.
{{< /note >}}

### linkerd-control-plane

The `linkerd-control-plane` chart sets up all the resources inside the `linkerd`
namespace. It only requires namespace-level privileges.

```bash
helm install linkerd-control-plane \
  -n linkerd \
  --set-file identityTrustAnchorsPEM=ca.crt \
  --set-file identity.issuer.tls.crtPEM=issuer.crt \
  --set-file identity.issuer.tls.keyPEM=issuer.key \
  linkerd/linkerd-control-plane
```

{{< note >}}
You can use a different namespace, but it must be the same you referred to when
installing `linkerd-base`.
{{< /note >}}

## Disabling The Proxy Init Container

If installing with CNI, make sure that you add the `--set
cniEnabled=true` flag to your `helm install` command in both charts.

## Setting High-Availability

Both charts contain a file `values-ha.yaml` that overrides some default values as
to set things up under a high-availability scenario, analogous to the `--ha`
option in `linkerd install`. Values such as higher number of replicas, higher
memory/cpu limits and affinities are specified in those files.

You can get ahold of `values-ha.yaml` by fetching the chart files:

```bash
helm fetch --untar linkerd/linkerd-base
helm fetch --untar linkerd/linkerd-control-plane
```

Then use the `-f` flag to provide the override file, for example:

```bash
helm install linkerd-control-plane \
  --set-file identityTrustAnchorsPEM=ca.crt \
  --set-file identity.issuer.tls.crtPEM=issuer.crt \
  --set-file identity.issuer.tls.keyPEM=issuer.key \
  -f linkerd-control-plane/values-ha.yaml \
  linkerd/linkerd-control-plane
```

## Helm upgrade procedure

Make sure your local Helm repos are updated:

```bash
helm repo update

helm search repo linkerd
NAME                          CHART VERSION          APP VERSION            DESCRIPTION
linkerd/linkerd-base          <chart-semver-version> {{% latestversion %}}    Linkerd gives you observability, reliability, and securit...
linkerd/linkerd-control-plane <chart-semver-version> {{% latestversion %}}    Linkerd gives you observability, reliability, and securit...
```

The `helm upgrade` command has a number of flags that allow you to customize
its behaviour. The ones that special attention should be paid to are
`--reuse-values` and `--reset-values` and how they behave when charts change
from version to version and/or overrides are applied through `--set` and
`--set-file`. To summarize these are prominent cases that can be observed:

- `--reuse-values` with no overrides - all values are reused
- `--reuse-values` with overrides - all except the values that are overridden
are reused
- `--reset-values` with no overrides - no values are reused and all changes
from provided release are applied during the upgrade
- `--reset-values` with overrides - no values are reused and changed from
provided release are applied together with the overrides
- no flag and no overrides - `--reuse-values` will be used by default
- no flag and overrides - `--reset-values` will be used by default

Bearing all that in mind, you have to decide whether you want to reuse the
values in the chart or move to the values specified in the newer chart.  The
advised practice is to use a `values.yaml` file that stores all custom overrides
that you have for your chart. Before upgrade, check whether there are breaking
changes to the chart (i.e. renamed or moved keys, etc). You can consult the
[edge](https://artifacthub.io/packages/helm/linkerd2/linkerd-control-plane#values)
or the
[stable](https://artifacthub.io/packages/helm/linkerd2-edge/linkerd-control-plane#values)
chart docs, depending on which one your are upgrading to. If there are, make the
corresponding changes to your `values.yaml` file. Then you can use:

```bash
helm upgrade linkerd-base linkerd/linkerd-base --reset-values -f values.yaml --atomic
helm upgrade linkerd-control-plane linkerd/linkerd-control-plane --reset-values -f values.yaml --atomic
```

The `--atomic` flag will ensure that all changes are rolled back in case the
upgrade operation fails
