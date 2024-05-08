+++
title = "Installing Linkerd with Helm"
description = "Install Linkerd onto your Kubernetes cluster using Helm."
+++

Linkerd can be installed via Helm rather than with the `linkerd install`
command. This is recommended for production, since it allows for repeatability.

{{< releases >}}

## Prerequisite: generate mTLS certificates

To do [automatic mutual TLS](../../features/automatic-mtls/), Linkerd requires
trust anchor certificate and an issuer certificate and key pair. When you're
using `linkerd install`, we can generate these for you. However, for Helm, you
will need to generate these yourself.

Please follow the instructions in
[Generating your own mTLS root certificates](../generate-certificates/) to
generate these.

## Helm install procedure

```bash
# Add the Helm repo for Linkerd edge releases:
helm repo add linkerd-edge https://helm.linkerd.io/edge
```

You need to install two separate charts in succession: first `linkerd-crds` and
then `linkerd-control-plane`.

{{< note >}} If installing Linkerd in a cluster that uses Cilium in kube-proxy
replacement mode, additional steps may be needed to ensure service discovery
works as intended. Instrunctions are on the
[Cilium cluster configuration](../../reference/cluster-configuration/#cilium)
page. {{< /note >}}

### linkerd-crds

The `linkerd-crds` chart sets up the CRDs linkerd requires:

```bash
helm install linkerd-crds linkerd/linkerd-crds \
  -n linkerd --create-namespace
```

{{< note >}} This will create the `linkerd` namespace. If it already exists or
you're creating it beforehand elsewhere in your pipeline, just omit the
`--create-namespace` flag. {{< /note >}}

{{< note >}} If you are using [Linkerd's CNI plugin](../../features/cni/), you
must also add the `--set cniEnabled=true` flag to your `helm install` command.
{{< /note >}}

### linkerd-control-plane

The `linkerd-control-plane` chart sets up all the control plane components:

```bash
helm install linkerd-control-plane \
  -n linkerd \
  --set-file identityTrustAnchorsPEM=ca.crt \
  --set-file identity.issuer.tls.crtPEM=issuer.crt \
  --set-file identity.issuer.tls.keyPEM=issuer.key \
  linkerd/linkerd-control-plane
```

{{< note >}} If you are using [Linkerd's CNI plugin](../../features/cni/), you
must also add the `--set cniEnabled=true` flag to your `helm install` command.
{{< /note >}}

## Enabling high availability mode

The `linkerd-control-plane` chart contains a file `values-ha.yaml` that
overrides some default values to set things up under a high-availability
scenario, analogous to the `--ha` option in `linkerd install`. Values such as
higher number of replicas, higher memory/cpu limits, and affinities are
specified in those files.

You can get `values-ha.yaml` by fetching the chart file:

```bash
helm fetch --untar linkerd/linkerd-control-plane
```

Then use the `-f` flag to provide this override file. For example:

```bash
helm install linkerd-control-plane \
  -n linkerd \
  --set-file identityTrustAnchorsPEM=ca.crt \
  --set-file identity.issuer.tls.crtPEM=issuer.crt \
  --set-file identity.issuer.tls.keyPEM=issuer.key \
  -f linkerd-control-plane/values-ha.yaml \
  linkerd/linkerd-control-plane
```

## Upgrading with Helm

First, make sure your local Helm repos are updated:

```bash
helm repo update

helm search repo linkerd
NAME                          CHART VERSION          APP VERSION              DESCRIPTION
linkerd/linkerd-crds          <chart-semver-version>                          Linkerd gives you observability, reliability, and securit...
linkerd/linkerd-control-plane <chart-semver-version> {{% latestedge %}}       Linkerd gives you observability, reliability, and securit...
```

During an upgrade, you must choose whether you want to reuse the values in the
chart or move to the values specified in the newer chart. Our advice is to use a
`values.yaml` file that stores all custom overrides that you have for your
chart.

The `helm upgrade` command has a number of flags that allow you to customize its
behavior. Special attention should be paid to `--reuse-values` and
`--reset-values` and how they behave when charts change from version to version
and/or overrides are applied through `--set` and `--set-file`. For example:

- `--reuse-values` with no overrides - all values are reused
- `--reuse-values` with overrides - all except the values that are overridden
  are reused
- `--reset-values` with no overrides - no values are reused and all changes from
  provided release are applied during the upgrade
- `--reset-values` with overrides - no values are reused and changed from
  provided release are applied together with the overrides
- no flag and no overrides - `--reuse-values` will be used by default
- no flag and overrides - `--reset-values` will be used by default

Finally, before upgrading, you can consult the
[edge chart](https://artifacthub.io/packages/helm/linkerd2-edge/linkerd-control-plane#values)
docs to check whether there are breaking changes to the chart (i.e.
renamed or moved keys, etc). If there are, make the corresponding changes to
your `values.yaml` file. Then you can use:

```bash
# the linkerd-crds chart currently doesn't have a values.yaml file
helm upgrade linkerd-crds linkerd/linkerd-crds

# whereas linkerd-control-plane does
helm upgrade linkerd-control-plane linkerd/linkerd-control-plane --reset-values -f values.yaml --atomic
```

The `--atomic` flag will ensure that all changes are rolled back in case the
upgrade operation fails.
