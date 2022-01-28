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

## Helm install procedure for stable releases

```bash
# add the repo for stable releases:
helm repo add linkerd https://helm.linkerd.io/stable

helm install linkerd2 \
  --set-file identityTrustAnchorsPEM=ca.crt \
  --set-file identity.issuer.tls.crtPEM=issuer.crt \
  --set-file identity.issuer.tls.keyPEM=issuer.key \
  linkerd/linkerd2
```

The chart values will be picked from the chart's `values.yaml` file.

You can override the values in that file by providing your own `values.yaml`
file passed with a `-f` option, or overriding specific values using the family of
`--set` flags like we did above for certificates.

## Helm install procedure for edge releases

You need to install two separate charts in succession: first `linkerd-crds` and
then `linkerd-control-plane`. This new method will eventually make its way into
the `2.12.0` stable release as well when it comes out.

### linkerd-crds

The `linkerd-crds` chart sets up the CRDs linkerd requires:

```bash
# add the repo for edge releases:
helm repo add linkerd-edge https://helm.linkerd.io/edge

helm install linkerd-crds -n linkerd --create-namespace --devel linkerd-edge/linkerd-crds
```

{{< note >}}
This will create the `linkerd` namespace. If it already exists or you're
creating it beforehand elsewhere in your pipeline, just omit the
`--create-namespace` flag.
{{< /note >}}

### linkerd-control-plane

The `linkerd-control-plane` chart sets up all the control plane components:

```bash
helm install linkerd-control-plane \
  -n linkerd \
  --devel \
  --set-file identityTrustAnchorsPEM=ca.crt \
  --set-file identity.issuer.tls.crtPEM=issuer.crt \
  --set-file identity.issuer.tls.keyPEM=issuer.key \
  linkerd-edge/linkerd-control-plane
```

## Disabling The Proxy Init Container

If installing with CNI, make sure that you add the `--set
cniEnabled=true` flag to your `helm install` command.

## Setting High-Availability

The linkerd2 chart (linkerd-control-plane chart for edge releases) contains a
file `values-ha.yaml` that overrides some default values as to set things up
under a high-availability scenario, analogous to the `--ha` option in `linkerd
install`. Values such as higher number of replicas, higher memory/cpu limits and
affinities are specified in that file.

You can get ahold of `values-ha.yaml` by fetching the chart files:

```bash
# for stable
helm fetch --untar linkerd/linkerd2

# for edge
helm fetch --untar --devel linkerd-edge/linkerd-control-plane
```

Then use the `-f` flag to provide the override file, for example:

```bash
# for stable
helm install linkerd2 \
  --set-file identityTrustAnchorsPEM=ca.crt \
  --set-file identity.issuer.tls.crtPEM=issuer.crt \
  --set-file identity.issuer.tls.keyPEM=issuer.key \
  -f linkerd2/values-ha.yaml \
  linkerd/linkerd2

# for edge
helm install linkerd-control-plane \
  -n linkerd \
  --devel \
  --set-file identityTrustAnchorsPEM=ca.crt \
  --set-file identity.issuer.tls.crtPEM=issuer.crt \
  --set-file identity.issuer.tls.keyPEM=issuer.key \
  -f linkerd-control-plane/values-ha.yaml \
  linkerd-edge/linkerd-control-plane
```

## Customizing the Namespace in the stable release

To install Linkerd to a different namespace than the default `linkerd`,
override the `Namespace` variable.

By default, the chart creates the control plane namespace with the
`config.linkerd.io/admission-webhooks: disabled` label. It is required for the
control plane to work correctly. This means that the chart won't work with the
`--namespace` option.  If you're relying on a separate tool to create the
control plane namespace, make sure that:

1. The namespace is labeled with `config.linkerd.io/admission-webhooks: disabled`
1. The `installNamespace` is set to `false`
1. The `namespace` variable is overridden with the name of your namespace

## Helm upgrade procedure

Make sure your local Helm repos are updated:

```bash
helm repo update

helm search repo linkerd2
NAME                    CHART VERSION          APP VERSION            DESCRIPTION
linkerd/linkerd2        <chart-semver-version> {{% latestversion %}}    Linkerd gives you observability, reliability, and securit...
```

The `helm upgrade` command has a number of flags that allow you to customize
its behaviour. The ones that special attention should be paid to are
`--reuse-values` and `--reset-values` and how they behave when charts change
from version to version and/or overrides are applied through `--set` and
`--set-file`. To summarize there are the following prominent cases that can be
observed:

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
values in the chart or move to the values specified in the newer chart.
The advised practice is to use a `values.yaml` file that stores all custom
overrides that you have for your chart. Before upgrade, check whether there
are breaking changes to the chart (i.e. renamed or moved keys, etc). You can
consult the [edge](https://hub.helm.sh/charts/linkerd2-edge/linkerd2) or the
[stable](https://hub.helm.sh/charts/linkerd2/linkerd2) chart docs, depending on
which one your are upgrading to. If there are, make the corresponding changes to
your `values.yaml` file. Then you can use:

```bash
helm upgrade linkerd2 linkerd/linkerd2 --reset-values -f values.yaml --atomic
```

The `--atomic` flag will ensure that all changes are rolled back in case the
upgrade operation fails
