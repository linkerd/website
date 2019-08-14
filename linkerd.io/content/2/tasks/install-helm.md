+++
title = "Installing Linkerd with Helm"
description = "Install Linkerd to your own Kubernetes cluster using Helm."
+++

Linkerd comes with its own Helm chart that allows you to tweak many more options
than what the `linkerd install` CLI command offers.

## Prerequisite: identity certificates

The identity component of Linkerd requires setting up a trust anchor
certificate, and an issuer certificate with its key. These need to be provided
to Helm by the user (unlike when using the `linkerd install` CLI which can
generate these automatically). You can provide your own, or follow [these
instructions](/2/tasks/generate-certificates) to generate new ones.

## Helm install procedure

1. Get ahold of Linkerd's source code from github:
```bash
git clone --branch {{% latestedge %}} git@github.com:linkerd/linkerd2.git
```
1. Set up the chart dependencies:
```bash
helm dependency update charts/linkerd2
```
1. Install!
```bash
helm install --set-file Identity.TrustAnchorsPEM=ca.crt --set-file Identity.Issuer.TLS.CrtPEM=issuer.crt --set-file Identity.Issuer.TLS.KeyPEM=issuer.key --set Identity.Issuer.CrtExpiry=2020-10-02T10:00:00Z charts/linkerd2
```

The chart values will be picked from the default `values.yaml` file located
under `charts/linkerd2`.

You can customize the chart by overriding the values in that file by providing
your own `values.yaml` file passed with a -f option, or overriding specific
values using the family of `--set` flags like we did above for certificates.

## Setting High-Availability

Also under `charts/linkerd2` there's a file `values-ha.yaml` that overrides some
default values as to set things up under a high-availability scenario. Values
such as higher number of replicas, higher memory/cpu limits and affinities are
specified in that file.

As usual the `-f` flag to provide the override file:

```bash
helm install --set-file Identity.TrustAnchorsPEM=ca.crt --set-file Identity.Issuer.TLS.CrtPEM=issuer.crt --set-file Identity.Issuer.TLS.KeyPEM=issuer.key --set Identity.Issuer.CrtExpiry=2020-10-02T10:00:00Z -f charts/linkerd2/values-ha.yaml charts/linkerd2
```