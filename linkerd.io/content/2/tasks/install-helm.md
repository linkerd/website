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
provide your own, or follow [these instructions](/2/tasks/generate-certificates/)
to generate new ones.

## Adding Linkerd's Helm repository

```bash
# To add the repo for Linkerd2 stable releases:
helm repo add linkerd https://helm.linkerd.io/stable

# To add the repo for Linkerd2 edge releases:
helm repo add linkerd-edge https://helm.linkerd.io/edge
```

The following instructions use the `linkerd` repo. For installing an edge
release, just replace with `linkerd-edge`.

## Helm install procedure

```bash
# set expiry date one year from now, in Mac:
exp=$(date -v+8760H +"%Y-%m-%dT%H:%M:%SZ")
# in Linux:
exp=$(date -d '+8760 hour' +"%Y-%m-%dT%H:%M:%SZ")

helm install \
  --name=linkerd2 \
  --set-file Identity.TrustAnchorsPEM=ca.crt \
  --set-file Identity.Issuer.TLS.CrtPEM=issuer.crt \
  --set-file Identity.Issuer.TLS.KeyPEM=issuer.key \
  --set Identity.Issuer.CrtExpiry=$exp \
  linkerd/linkerd2
```

The chart values will be picked from the chart's `values.yaml` file.

You can override the values in that file by providing your own `values.yaml`
file passed with a `-f` option, or overriding specific values using the family of
`--set` flags like we did above for certificates.

## Setting High-Availability

The chart contains a file `values-ha.yaml` that overrides some
default values as to set things up under a high-availability scenario, analogous
to the `--ha` option in `linkerd install`. Values such as higher number of
replicas, higher memory/cpu limits and affinities are specified in that file.

You can get ahold of `values-ha.yaml` by fetching the chart files:

```bash
helm fetch --untar linkerd/linkerd2
```

Then use the `-f` flag to provide the override file, for example:

```bash
## see above on how to set $exp
helm install \
  --name=linkerd2 \
  --set-file Identity.TrustAnchorsPEM=ca.crt \
  --set-file Identity.Issuer.TLS.CrtPEM=issuer.crt \
  --set-file Identity.Issuer.TLS.KeyPEM=issuer.key \
  --set Identity.Issuer.CrtExpiry=$exp \
  -f linkerd2/values-ha.yaml \
  linkerd/linkerd2
```

## Customizing the Namespace

To install Linkerd to a different namespace than the default `linkerd`,
override the `Namespace` variable.

By default, the chart creates the control plane namespace with the
`config.linkerd.io/admission-webhooks: disabled` label. It is required for the
control plane to work correctly. This means that the chart won't work with
Helm v2's `--namespace` option.  If you're relying on a separate tool to create
the control plane namespace, make sure that:

1. The namespace is labeled with `linkerd.io/admission-webhooks: disabled`
1. The `InstallNamespace` is set to `false`
1. The `Namespace` variable is overridden with the name of your namespace

{{< note >}}
In Helm v3 the `--namespace` option must be used with an existing namespace.
{{< /note >}}

## Helm upgrade procedure

Make sure your local Helm repos are updated:

```bash
helm repo update

helm search linkerd2 -v {{% latestversion %}}
NAME                    CHART VERSION          APP VERSION            DESCRIPTION
linkerd/linkerd2        <chart-semver-version> {{% latestversion %}}    Linkerd gives you observability, reliability, and securit...
```

Use the `helm upgrade` command to upgrade the chart:

```bash
helm upgrade linkerd2 linkerd/linkerd2 --reuse-values
```
