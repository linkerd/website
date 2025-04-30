---
title: Upgrading Linkerd
description: Perform zero-downtime upgrades for Linkerd.
---

In this guide, we'll walk you through how to perform zero-downtime upgrades for
Linkerd.

Read through this guide carefully. Additionally, before starting a specific
upgrade, please read through the version-specific upgrade notices below, which
may contain important information about your version.

- [Upgrade notice: stable-2.11.0](#upgrade-notice-stable-2-11-0)
- [Upgrade notice: stable-2.10.0](#upgrade-notice-stable-2-10-0)
- [Upgrade notice: stable-2.9.4](#upgrade-notice-stable-2-9-4)
- [Upgrade notice: stable-2.9.3](#upgrade-notice-stable-2-9-3)
- [Upgrade notice: stable-2.9.0](#upgrade-notice-stable-2-9-0)

## Version numbering

Linkerd follows a version numbering scheme of the form `2.<major>.<minor>`. In
other words, "2" is a static prefix, followed by the major version, then the
minor.

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
skip intermediate intermediate minor versions, i.e. it is still safe even if *z
> y + 1*.

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

### With the Linkerd CLI

For users who have installed Linkerd via the CLI, the `linkerd upgrade` command
will upgrade the control plane. This command ensures that all of the control
plane's existing configuration and TLS secrets are retained. Notice that we use
the `--prune` flag to remove any Linkerd resources from the previous version
which no longer exist in the new version.

```bash
linkerd upgrade | kubectl apply --prune -l linkerd.io/control-plane-ns=linkerd -f -
```

Next, run this command again with some `--prune-whitelist` flags added. This is
necessary to make sure that certain cluster-scoped resources are correctly
pruned.

```bash
linkerd upgrade | kubectl apply --prune -l linkerd.io/control-plane-ns=linkerd \
  --prune-whitelist=rbac.authorization.k8s.io/v1/clusterrole \
  --prune-whitelist=rbac.authorization.k8s.io/v1/clusterrolebinding \
  --prune-whitelist=apiregistration.k8s.io/v1/apiservice -f -
```

### With Helm

For Helm control plane installations, please follow the instructions at [Helm
upgrade procedure](install-helm/#helm-upgrade-procedure).

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

[Linkerd's extensions](extensions/) provide additional functionality to
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

### Upgrading Multicluster

Upgrading the multicluster extension doesn't cause downtime in the traffic going
through the mirrored services, unless otherwise noted in the version-specific
notes below. Note however that for the service mirror _deployments_ (which
control the creation of the mirrored services) to be updated, you need to
re-link your clusters through `linkerd multicluster link`.

## Upgrade notices

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
ingress](using-ingress/) with Linkerd.

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
guide](../features/protocol-detection/) for the repercussions.

Second, we've introduced [extensions](extensions/) and moved the
default visualization components into a Linkerd-Viz extension. Read on for what
this means for you.

#### Visualization components moved to Linkerd-Viz extension

With the introduction of [extensions](extensions/), all of the
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
  --prune-whitelist=rbac.authorization.k8s.io/v1/clusterrole \
  --prune-whitelist=rbac.authorization.k8s.io/v1/clusterrolebinding \
  --prune-whitelist=apiregistration.k8s.io/v1/apiservice -f -
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

### Upgrade notice: stable-2.9.4

See upgrade notes for 2.9.3 below.

### Upgrade notice: stable-2.9.3

#### Linkerd Repair

Due to a known issue in versions stable-2.9.0, stable-2.9.1, and stable-2.9.2,
users who upgraded to one of those versions with the --prune flag (as described
above) will have deleted the `secret/linkerd-config-overrides` resource which is
necessary for performing any subsequent upgrades. Linkerd stable-2.9.3 includes
a new `linkerd repair` command which restores this deleted resource. If you see
unexpected error messages during upgrade such as "failed to read CA: not
PEM-encoded", please upgrade your CLI to stable-2.9.3 and run:

```bash
linkerd repair | kubectl apply -f -
```

This will restore the `secret/linkerd-config-overrides` resource and allow you
to proceed with upgrading your control plane.

### Upgrade notice: stable-2.9.0

#### Images are now hosted on ghcr.io

As of this version images are now hosted under `ghcr.io` instead of `gcr.io`. If
you're pulling images into a private repo please make the necessary changes.

#### Upgrading multicluster environments

Linkerd 2.9 changes the way that some of the multicluster components work and
are installed compared to Linkerd 2.8.x. Users installing the multicluster
components for the first time with Linkerd 2.9 can ignore these instructions and
instead refer directly to the [installing
multicluster instructions](installing-multicluster/).

Users who installed the multicluster component in Linkerd 2.8.x and wish to
upgrade to Linkerd 2.9 should follow the [upgrade multicluster
instructions](upgrade-multicluster/).

#### Ingress behavior changes

In previous versions when you injected your ingress controller (Nginx, Traefik,
Ambassador, etc), then the ingress' balancing/routing choices would be
overridden with Linkerd's (using service profiles, traffic splits, etc.).

As of 2.9 the ingress's choices are honored instead, which allows preserving
things like session-stickiness. Note however that this means per-route metrics
are not collected, traffic splits will not be honored and retries/timeouts are
not applied.

If you want to revert to the previous behavior, inject the proxy into the
ingress controller using the annotation `linkerd.io/inject: ingress`, as
explained in [using ingress](using-ingress/)

#### Breaking changes in Helm charts

Some entries like `controllerLogLevel` and all the Prometheus config have
changed their position in the settings hierarchy. To get a precise view of what
has changed you can compare the
[stable-2.8.1](https://github.com/linkerd/linkerd2/blob/stable-2.8.1/charts/linkerd2/values.yaml)
and
[stable-2.9.0](https://github.com/linkerd/linkerd2/blob/stable-2.9.0/charts/linkerd2/values.yaml)
`values.yaml` files.

#### Post-upgrade cleanup

In order to better support cert-manager, the secrets
`linkerd-proxy-injector-tls`, `linkerd-sp-validator-tls` and `linkerd-tap-tls`
have been replaced by the secrets `linkerd-proxy-injector-k8s-tls`,
`linkerd-sp-validator-k8s-tls` and `linkerd-tap-k8s-tls` respectively. If you
upgraded through the CLI, please delete the old ones (if you upgraded through
Helm the cleanup was automated).
