+++
title = "Installing Linkerd with Helm"
description = "Install Linkerd onto your own Kubernetes cluster using Helm."
+++

Linkerd can optionally be installed via Helm rather than with the `linkerd
install` command.

## Prerequisite: identity certificates

The identity component of Linkerd requires setting up a trust anchor
certificate, and an issuer certificate with its key. These need to be provided
to Helm by the user (unlike when using the `linkerd install` CLI which can
generate these automatically). You can provide your own, or follow [these
instructions](/2/tasks/generate-certificates/) to generate new ones.

## Adding Linkerd's Helm repository

```bash
# To add the repo for Linkerd2 stable releases:
helm repo add linkerd-stable https://helm.linkerd.io/stable

# To add the repo for Linkerd2 edge releases:
helm repo add linkerd-edge https://helm.linkerd.io/edge
```

The following instructions use the `linkerd-stable` repo. For installing an edge
release, just replace with `linkerd-edge`.

## Helm install procedure

```bash
# set expiry date one year from now, in Mac:
exp=$(date -v+8760H +"%Y-%m-%dT%H:%M:%SZ")
# in Linux:
exp=$(date -d '+8760 hour' +"%Y-%m-%dT%H:%M:%SZ")

helm install \
  --set-file Identity.TrustAnchorsPEM=ca.crt \
  --set-file Identity.Issuer.TLS.CrtPEM=issuer.crt \
  --set-file Identity.Issuer.TLS.KeyPEM=issuer.key \
  --set Identity.Issuer.CrtExpiry=$exp \
  linkerd-stable/linkerd2
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
helm fetch --untar linkerd-stable/linkerd2
```

Then use the `-f` flag to provide the override file, for example:

```bash
## see above on how to set $exp
helm install \
  --set-file Identity.TrustAnchorsPEM=ca.crt \
  --set-file Identity.Issuer.TLS.CrtPEM=issuer.crt \
  --set-file Identity.Issuer.TLS.KeyPEM=issuer.key \
  --set Identity.Issuer.CrtExpiry=$exp \
  -f linkerd2/values-ha.yaml
  linkerd-stable/linkerd2
```
