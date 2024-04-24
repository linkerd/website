+++
title = "Upgrading Linkerd"
description = "Perform zero-downtime upgrades for Linkerd."
aliases = [
  "../upgrade/",
  "../update/"
]
+++

In this guide, we'll walk you through how to perform zero-downtime upgrades for
Linkerd.

{{< note >}}
This page contains instructions for the latest edge release of Linkerd. If
you have installed a [stable distribution](/releases/#stable) of Linkerd, the
vendor may have additional guidance on how to upgrade.
{{< /note >}}

Read through this guide carefully. Additionally, before starting a specific
upgrade, please read through the version-specific upgrade notices below, which
may contain important information about your version.

- [Upgrade notice: 2.15 and beyond](#upgrade-notice-stable-215-and-beyond)
- [Upgrade notice: stable-2.14.0](#upgrade-notice-stable-2140)
- [Upgrade notice: stable-2.13.0](#upgrade-notice-stable-2130)
- [Upgrade notice: stable-2.12.0](#upgrade-notice-stable-2120)
- [Upgrade notice: stable-2.11.0](#upgrade-notice-stable-2110)
- [Upgrade notice: stable-2.10.0](#upgrade-notice-stable-2100)

## Version numbering

For stable releases, Linkerd follows a version numbering scheme of the form
`2.<major>.<minor>`. In other words, "2" is a static prefix, followed by the
major version, then the minor.

Changes in minor versions are intended to be backwards compatible with the
previous version. Changes in major version *may* introduce breaking changes,
although we try to avoid that whenever possible.

## Upgrade paths

The following upgrade paths are generally safe. However, before starting a
deploy, it is important to check the upgrade notes before
proceeding—occasionally, specific minor releases may have additional
restrictions.

**Within the same major version**. It is usually safe to upgrade to the latest
minor version within the same major version. In other words, if you are
currently running version *2.x.y*, upgrading to *2.x.z*, where *z* is the latest
minor version for major version *x*, is safe. This is true even if you would
skip intermediate intermediate minor versions, i.e. it is still safe even if
*z* > *y + 1*.

**To the next major version**. It is usually safe to upgrade to the latest minor
version of the *next* major version. In other words, if you are currently
running version *2.x.y*, upgrading to *2.x + 1.w* will be safe, where *w* is the
latest minor version available for major version *x + 1*.

**To later major versions**. Upgrades that skip one or more major versions
are not supported. Instead, you should upgrade major versions incrementally.

Again, please check the upgrade notes for the specific version you are upgrading
*to* for any version-specific caveats.

## Data plane vs control plane version skew

It is usually safe to run Linkerd's control plane with the data plane from one
major version earlier. (This skew is a natural consequence of upgrading.) This
is independent of minor version, i.e. a *2.x.y* data plane and a *2.x + 1.z*
control plane will work regardless of *y* and *z*.

Please check the version-specific upgrade notes before proceeding.

Note that new features introduced by the release may not be available for
workloads with older data planes.

## Overall upgrade process

There are four components that need to be upgraded:

- [The CLI](#upgrade-the-cli)
- [The control plane](#upgrade-the-control-plane)
- [The control plane extensions](#upgrade-extensions)
- [The data plane](#upgrade-the-data-plane)

These steps should be performed in sequence.

## Before upgrading

Before you commence an upgrade, you should ensure that the current state
of Linkerd is healthy, e.g. by using `linkerd check`. For major version
upgrades, you should also ensure that your data plane is up-to-date, e.g.
with `linkerd check --proxy`, to avoid unintentional version skew.

Make sure that your Linkerd version and Kubernetes version are compatible by
checking Linkerd's [supported Kubernetes
versions](../../reference/k8s-versions/).

## Upgrading the CLI

The CLI can be used to validate whether Linkerd was installed correctly.

To upgrade the CLI, run:

```bash
curl --proto '=https' --tlsv1.2 -sSfL https://run.linkerd.io/install | sh
```

Alternatively, you can download the CLI directly via the [Linkerd releases
page](https://github.com/linkerd/linkerd2/releases/).

Verify the CLI is installed and running the expected version with:

```bash
linkerd version --client
```

## Upgrading the control plane

### Upgrading the control plane with the CLI

For users who have installed Linkerd via the CLI, the `linkerd upgrade` command
will upgrade the control plane. This command ensures that all of the control
plane's existing configuration and TLS secrets are retained.  Linkerd's CRDs
should be upgraded first, using the `--crds` flag, followed by upgrading the
control plane.

```bash
linkerd upgrade --crds | kubectl apply -f -
linkerd upgrade | kubectl apply -f -
```

Next, we use the `linkerd prune` command to remove any resources that were
present in the previous version but should not be present in this one.

```bash
linkerd prune | kubectl delete -f -
```

### Upgrading the control plane with Helm

For Helm control plane installations, please follow the instructions at [Helm
upgrade procedure](../install-helm/#helm-upgrade-procedure).

### Verifying the control plane upgrade

Once the upgrade process completes, check to make sure everything is healthy
by running:

```bash
linkerd check
```

This will run through a set of checks against your control plane and make sure
that it is operating correctly.

To verify the Linkerd control plane version, run:

```bash
linkerd version
```

Which should display the latest versions for both client and server.

## Upgrading extensions

[Linkerd's extensions](../extensions/) provide additional functionality to
Linkerd in a modular way. Generally speaking, extensions are versioned
separately from Linkerd releases and follow their own schedule; however, some
extensions are updated alongside Linkerd releases and you may wish to update
them as part of the same process.

Each extension can be upgraded independently. If using Helm, the procedure is
similar to the control plane upgrade, using the respective charts. For the CLI,
the extension CLI commands don't provide `upgrade` subcommands, but using
`install` again is fine. For example:

```bash
linkerd viz install | kubectl apply -f -
linkerd multicluster install | kubectl apply -f -
linkerd jaeger install | kubectl apply -f -
```

Most extensions also include a `prune` command for removing resources which
were present in the previous version but should not be present in the current
version. For example:

```bash
linkerd viz prune | kubectl delete -f -
```

### Upgrading the multicluster extension

Upgrading the multicluster extension doesn't cause downtime in the traffic going
through the mirrored services, unless otherwise noted in the version-specific
notes below. Note however that for the service mirror *deployments* (which
control the creation of the mirrored services) to be updated, you need to
re-link your clusters through `linkerd multicluster link`.

## Upgrading the data plane

Upgrading the data plane requires updating the proxy added to each meshed
workload. Since pods are immutable in Kubernetes, Linkerd is unable to simply
update the proxies in place. Thus, the standard option is to restart each
workload, allowing the proxy injector to inject the latest version of the proxy
as they come up.

For example, you can use the `kubectl rollout restart` command to restart a
meshed deployment:

```bash
kubectl -n <namespace> rollout restart deploy
```

As described earlier, a skew of one major version between data plane and control
plane is always supported. Thus, for some systems it is possible to do this data
plane upgrade "lazily", and simply allow workloads to pick up the newest proxy
as they are restarted for other reasons (e.g. for new code rollouts). However,
newer features may only be available on workloads with the latest proxy.

A skew of more than one major version between data plane and control plane is
not supported.

### Verify the data plane upgrade

Check to make sure everything is healthy by running:

```bash
linkerd check --proxy
```

This will run through a set of checks to verify that the data plane is
operating correctly, and will list any pods that are still running older
versions of the proxy.

Congratulation! You have successfully upgraded your Linkerd to the newer
version.

## Upgrade notices

This section contains release-specific information about upgrading.

### Upgrade notice: stable-2.15 and beyond

As of February 2024, the Linkerd project is no longer producing open source
stable release artifacts. Please read the [2.15
announcement](/2024/02/21/announcing-linkerd-2.15/#a-new-model-for-stable-releases)
for details.

See [the full list of Linkerd releases](/releases/) for ways to get Linkerd.

### Upgrade notice: stable-2.14.0

For this release, if you're using the multicluster extension, you should re-link
your clusters after upgrading to stable-2.14.0, as explained
[above](#upgrading-the-multicluster-extension). Not doing so immediately won't
cause any downtime in cross-cluster connections, but `linkerd multicluster
check` will not succeed until the clusters are re-linked.

There are no other extra steps for upgrading to 2.14.0.

### Upgrade notice: stable-2.13.0

Please be sure to read the [Linkerd 2.13.0 release
notes](https://github.com/linkerd/linkerd2/releases/tag/stable-2.13.0).

There are no other extra steps for upgrading to 2.13.0.

### Upgrade notice: stable-2.12.0

Please be sure to read the [Linkerd 2.12.0 release
notes](https://github.com/linkerd/linkerd2/releases/tag/stable-2.12.0).

There are a couple important changes that affect the upgrade process for 2.12.0:

- The minimum Kubernetes version supported is `v1.21.0`.
- The TrafficSplit CRD has been moved to the Linkerd SMI extension.
- Support for Helm v2 has been removed.
- The viz extension no longer installs Grafana due to licensing concerns.
- The linkerd2 Helm chart has been split into two charts: linkerd-crds and
  linkerd-control-plane.
- The viz, multicluster, jaeger, and linkerd2-cni Helm charts now rely on a
  post-install hook required metadata into their namespaces.

Read on for how to handle these changes as part of the upgrade process.

#### Upgrading to 2.12.0 using the CLI

If you installed Linkerd `2.11.x` with the CLI _and_ are using the
`TrafficSplit` CRD, you need to take an extra stop to avoid losing your
`TrafficSplit` CRs. (If you're not using `TrafficSplit` then you can
perform the usual CLI upgrade as [described above](#with-linkerd-cli).)

The `TrafficSplit` CRD has been moved to the SMI extension. But before
installing that extension, you need to add the following annotations and label
to the CRD so that the `linkerd-smi` chart can adopt it:

```bash
kubectl annotate --overwrite crd/trafficsplits.split.smi-spec.io \
  meta.helm.sh/release-name=linkerd-smi \
  meta.helm.sh/release-namespace=linkerd-smi
kubectl label crd/trafficsplits.split.smi-spec.io \
  app.kubernetes.io/managed-by=Helm
```

Now you can install the SMI extension. E.g. via Helm:

```bash
helm repo add l5d-smi https://linkerd.github.io/linkerd-smi
helm install linkerd-smi -n linkerd-smi --create-namespace l5d-smi/linkerd-smi
```

And finally you can proceed with the usual [CLI upgrade
instructions](#with-linkerd-cli), but avoid using the `--prune` flag when
applying the output of `linkerd upgrade --crds` to avoid removing the
`TrafficSplit` CRD.

#### Upgrading to 2.12.0 using Helm

Note that support for Helm v2 has been dropped in the Linkerd 2.12.0 release.

This section provides instructions on how to perform a migration from Linkerd
`2.11.x` to `2.12.0` without control plane downtime, when your existing Linkerd
instance was installed via Helm. There were several changes to the Linkerd Helm
charts as part of this release, so this upgrade process is a little more
involved than usual.

##### Retrieving existing customization and PKI setup

The `linkerd2` chart has been replaced by two charts: `linkerd-crds` and
`linkerd-control-plane` (and optionally `linkerd-smi` if you're using
`TrafficSplit`). To migrate to this new setup, we need to ensure your
customization values, including TLS certificates and keys, are migrated
to the new charts.

Find the release name you used for the `linkerd2` chart, and the namespace where
this release stored its config:

```bash
$ helm ls -A
NAME    NAMESPACE       REVISION        UPDATED                                 STATUS          CHART           APP VERSION
linkerd default         1               2021-11-22 17:14:50.751436374 -0500 -05 deployed        linkerd2-2.11.1 stable-2.11.1
```

(The example output above matches the default case.) Note that even if Linkerd is
installed in the `linkerd` namespace, the Helm config should have been installed
in the `default` namespace, unless you specified something different in the
`namespace` value when you installed. Take note of this release name (linkerd)
and namespace (default) to use in the commands that follow.

Next, retrieve all your chart values customizations, especially your trust
root and issuer keys (`identityTrustAnchorsPEM`, `identity.issuer.tls.crtPEM`
and `identity.issuer.tls.keyPEM`). These values will need to be fed again into
the `helm install` command below for the `linkerd-control-plane` chart. These
values can be retrieved with the following command:

```bash
helm get -n default values linkerd
```

##### Migrate resources to the new charts

Next, we need to prepare these values for use with the new charts. Note that the
examples below use the [yq](https://github.com/mikefarah/yq) utility.

The following snippets will change the `meta.helm.sh/release-name` and
`meta.helm.sh/release-namespace` annotations for each resource in the `linkerd`
release (use your own name as explained above), so that they can be adopted by
the `linkerd-crds`, `linkerd-control-plane` and `linkerd-smi` charts:

```bash
# First migrate the CRDs
$ helm -n default get manifest linkerd | \
  yq 'select(.kind == "CustomResourceDefinition") | .metadata.name' | \
  grep -v '\-\-\-' | \
  xargs -n1 sh -c \
  'kubectl annotate --overwrite crd/$0 meta.helm.sh/release-name=linkerd-crds meta.helm.sh/release-namespace=linkerd'

# Special case for TrafficSplit (only use if you have TrafficSplit CRs)
$ kubectl annotate --overwrite crd/trafficsplits.split.smi-spec.io \
  meta.helm.sh/release-name=linkerd-smi meta.helm.sh/release-namespace=linkerd-smi

# Now migrate all the other resources
$ helm -n default get manifest linkerd | \
  yq 'select(.kind != "CustomResourceDefinition")' | \
  yq '.kind, .metadata.name, .metadata.namespace' | \
  grep -v '\-\-\-' |
  xargs -n3 sh -c 'kubectl annotate --overwrite -n $2 $0/$1 meta.helm.sh/release-name=linkerd-control-plane meta.helm.sh/release-namespace=linkerd'
```

##### Installing the new charts

Next, we need to install the new charts using our customization values
prepared above.

```bash
# First make sure you update the helm repo
$ helm repo up

# Install the linkerd-crds chart
$ helm install linkerd-crds -n linkerd --create-namespace linkerd/linkerd-crds

# Install the linkerd-control-plane chart
# (remember to add any customizations you retrieved above)
$ helm install linkerd-control-plane \
  -n linkerd \
  --set-file identityTrustAnchorsPEM=ca.crt \
  --set-file identity.issuer.tls.crtPEM=issuer.crt \
  --set-file identity.issuer.tls.keyPEM=issuer.key \
  linkerd/linkerd-control-plane

# Optional: if using TrafficSplit CRs
$ helm repo add l5d-smi https://linkerd.github.io/linkerd-smi
$ helm install linkerd-smi -n linkerd-smi --create-namespace l5d-smi/linkerd-smi
```

##### Cleaning up the old linkerd2 Helm release

After installing the new charts, we need to clean up the old Helm chart. The
`helm delete` command would delete all the linkerd resources, so instead we just
remove the Helm release config for the old `linkerd2` chart (assuming you used
the "Secret" storage backend, which is the default):

```bash
$ kubectl -n default delete secret \
  --field-selector type=helm.sh/release.v1 \
  -l name=linkerd,owner=helm
```

##### Upgrading extension Helm charts

Finally, we need to upgrade our extensions. In Linkerd 2.12.0 the viz,
multicluster, jaeger, and linkerd2-cni extensions no longer install their
namespaces, instead leaving that to the `helm` command (or to a previous step in
your CD pipeline) and relying on an post-install hook to add the required
metadata into that namespace. Therefore the Helm upgrade path for these
extensions is to delete and reinstall them.

For example, for the viz extension:

```bash
# update the helm repo
helm repo up

# delete your current instance
# (assuming you didn't use the -n flag when installing)
helm delete linkerd-viz

# install the new chart version
helm install linkerd-viz -n linkerd-viz --create-namespace linkerd/linkerd-viz
```

##### Upgrading the multicluster extension with Helm

Note that reinstalling the multicluster extension via Helm as explained above
will result in the recreation of the `linkerd-multicluster` namespace, thus
deleting all the `Link` resources that associate the source cluster with any
target clusters. The mirrored services, which live on their respective
namespaces, won't be deleted so there won't be any downtime. So after finishing
the upgrade, make sure you re-link your clusters again with `linkerd
multicluster link`. This will also bring the latest versions of the service
mirror deployments.

##### Adding Grafana

The viz extension no longer installs a Grafana instance due to licensing
concerns. Instead we recommend you install it directly from the [Grafana
official Helm
chart](https://github.com/grafana/helm-charts/tree/main/charts/grafana) or the
[Grafana Operator](https://github.com/grafana-operator/grafana-operator).
Linkerd's Grafana dashboards have been published in
<https://grafana.com/orgs/linkerd/dashboards>, and the new [Grafana
docs](../grafana/) provide detailed instructions on how to load them.

### Upgrade notice: stable-2.11.0

The minimum Kubernetes version supported is now `v1.17.0`.

There are two breaking changes in the 2.11.0 release: pods in `ingress` no
longer support non-HTTP traffic to meshed workloads; and the proxy no longer
forwards traffic to ports that are bound only to localhost.

Users of the multi-cluster extension will need to re-link their cluster after
upgrading.

The Linkerd proxy container is now the *first* container in the pod. This may
affect tooling that assumed the application was the first container in the pod.

#### Control plane changes

The `controller` pod has been removed from the control plane. All configuration
options that previously applied to it are no longer valid (e.g
`publicAPIResources` and all of its nested fields). Additionally, the
destination pod has a new `policy` container that runs the policy controller.

#### Data plane changes

In order to fix a class of startup race conditions, the container ordering
within meshed pods has changed so that the Linkerd proxy container is now the
*first* container in the pod, the application container now waits to start until
the proxy is ready. This may affect tooling that assumed the application
container was the first container in the pod.

Using [linkerd-await](https://github.com/linkerd/linkerd-await) to enforce
container startup ordering is thus longer necessary. (However, using
`linkerd-await -S` to ensure proxy shutdown in Jobs and Cronjobs is still
valid.)

#### Routing breaking changes

There are two breaking changes to be aware of when it comes to how traffic is
routed.

First, when the proxy runs in ingress mode (`config.linkerd.io/inject:
ingress`), non-HTTP traffic to meshed pods is no longer supported. To get
around this, you will need to use the `config.linkerd.io/skip-outbound-ports`
annotation on your ingress controller pod. In many cases, ingress mode is no
longer necessary. Before upgrading, it may be worth revisiting [how to use
ingress](../using-ingress/) with Linkerd.

Second, the proxy will no longer forward traffic to ports only bound on
localhost, such as `127.0.0.1:8080`. Services that want to receive traffic from
other pods should now be bound to a public interface (e.g `0.0.0.0:8080`). This
change prevents ports from being accidentally exposed outside of the pod.

#### Multicluster

The gateway component has been changed to use a `pause` container instead of
`nginx`. This change should reduce the footprint of the extension; the proxy
routes traffic internally and does not need to rely on `nginx` to receive or
forward traffic. While this will not cause any downtime when upgrading
multicluster, it does affect probing. `linkerd multicluster gateways` will
falsely advertise the target cluster gateway as being down until the clusters
are re-linked.

Multicluster now supports `NodePort` type services for the gateway. To support
this change, the configuration options in the Helm values file are now grouped
under the `gateway` field. If you have installed the extension with other
options than the provided defaults, you will need to update your `values.yaml`
file to reflect this change in field grouping.

#### Other changes

Besides the breaking changes described above, there are other minor changes to
be aware of when upgrading from `stable-2.10.x`:

- `PodSecurityPolicy` (PSP) resources are no longer installed by default as a
 result of their deprecation in Kubernetes v1.21 and above. The control plane
 and core extensions will now be shipped without PSPs; they can be enabled
 through a new install option `enablePSP: true`.
- The `tcp_connection_duration_ms` metric has been removed.
- Opaque ports changes: `443` is no longer included in the default opaque ports
 list. Ports `4444`, `6379` and `9300` corresponding to Galera, Redis and
 ElasticSearch respectively (all server speak first protocols) have been added
 to the default opaque ports list. The default ignore inbound ports list has
 also been changed to include ports `4567` and `4568`.

### Upgrade notice: stable-2.10.0

If you are currently running Linkerd 2.9.0, 2.9.1, 2.9.2, or 2.9.3 (but *not*
2.9.4), and you *upgraded* to that release using the `--prune` flag (as opposed
to installing it fresh), you will need to use the `linkerd repair` command as
outlined in the [Linkerd 2.9.3 upgrade notes](#upgrade-notice-stable-2-9-3)
before you can upgrade to Linkerd 2.10.

Additionally, there are two changes in the 2.10.0 release that may affect you.
First, the handling of certain ports and protocols has changed. Please read
through our [ports and protocols in 2.10 upgrade
guide](../upgrading-2.10-ports-and-protocols/) for the repercussions.

Second, we've introduced [extensions](../extensions/) and moved the
default visualization components into a Linkerd-Viz extension. Read on for what
this means for you.

#### Visualization components moved to Linkerd-Viz extension

With the introduction of [extensions](../extensions/), all of the
Linkerd control plane components related to visibility (including Prometheus,
Grafana, Web, and Tap) have been removed from the main Linkerd control plane
and moved into the Linkerd-Viz extension. This means that when you upgrade to
stable-2.10.0, these components will be removed from your cluster and you will
not be able to run commands such as `linkerd stat` or
`linkerd dashboard`. To restore this functionality, you must install the
Linkerd-Viz extension by running `linkerd viz install | kubectl apply -f -`
and then invoke those commands through `linkerd viz stat`,
`linkerd viz dashboard`, etc.

```bash
# Upgrade the control plane (this will remove viz components).
linkerd upgrade | kubectl apply --prune -l linkerd.io/control-plane-ns=linkerd -f -
# Prune cluster-scoped resources
linkerd upgrade | kubectl apply --prune -l linkerd.io/control-plane-ns=linkerd \
  --prune-allowlist=rbac.authorization.k8s.io/v1/clusterrole \
  --prune-allowlist=rbac.authorization.k8s.io/v1/clusterrolebinding \
  --prune-allowlist=apiregistration.k8s.io/v1/apiservice -f -
# Install the Linkerd-Viz extension to restore viz functionality.
linkerd viz install | kubectl apply -f -
```

Helm users should note that configuration values related to these visibility
components have moved to the Linkerd-Viz chart. Please update any values
overrides you have and use these updated overrides when upgrading the Linkerd
chart or installing the Linkerd-Viz chart. See below for a complete list of
values which have moved.

```bash
helm repo update
# Upgrade the control plane (this will remove viz components).
helm upgrade linkerd2 linkerd/linkerd2 --reset-values -f values.yaml --atomic
# Install the Linkerd-Viz extension to restore viz functionality.
helm install linkerd2-viz linkerd/linkerd2-viz -f viz-values.yaml
```

The following values were removed from the Linkerd2 chart. Most of the removed
values have been moved to the Linkerd-Viz chart or the Linkerd-Jaeger chart.

- `dashboard.replicas` moved to Linkerd-Viz as `dashboard.replicas`
- `tap` moved to Linkerd-Viz as `tap`
- `tapResources` moved to Linkerd-Viz as `tap.resources`
- `tapProxyResources` moved to Linkerd-Viz as `tap.proxy.resources`
- `webImage` moved to Linkerd-Viz as `dashboard.image`
- `webResources` moved to Linkerd-Viz as `dashboard.resources`
- `webProxyResources` moved to Linkerd-Viz as `dashboard.proxy.resources`
- `grafana` moved to Linkerd-Viz as `grafana`
- `grafana.proxy` moved to Linkerd-Viz as `grafana.proxy`
- `prometheus` moved to Linkerd-Viz as `prometheus`
- `prometheus.proxy` moved to Linkerd-Viz as `prometheus.proxy`
- `global.proxy.trace.collectorSvcAddr` moved to Linkerd-Jaeger as `webhook.collectorSvcAddr`
- `global.proxy.trace.collectorSvcAccount` moved to Linkerd-Jaeger as `webhook.collectorSvcAccount`
- `tracing.enabled` removed
- `tracing.collector` moved to Linkerd-Jaeger as `collector`
- `tracing.jaeger` moved to Linkerd-Jaeger as `jaeger`

Also please note the global scope from the Linkerd2 chart values has been
dropped, moving the config values underneath it into the root scope. Any values
you had customized there will need to be migrated; in particular
`identityTrustAnchorsPEM` in order to conserve the value you set during
install."
