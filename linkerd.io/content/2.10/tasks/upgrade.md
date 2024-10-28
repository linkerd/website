---
title: Upgrading Linkerd
description: Upgrade Linkerd to the latest version.
---

In this guide, we'll walk you through how to upgrade Linkerd.

Before starting, read through the version-specific upgrade notices below, which
may contain important information you need to be aware of before commencing
with the upgrade process:

- [Upgrade notice: stable-2.10.0](#upgrade-notice-stable-2-10-0)
- [Upgrade notice: stable-2.9.4](#upgrade-notice-stable-2-9-4)
- [Upgrade notice: stable-2.9.3](#upgrade-notice-stable-2-9-3)
- [Upgrade notice: stable-2.9.0](#upgrade-notice-stable-2-9-0)
- [Upgrade notice: stable-2.8.0](#upgrade-notice-stable-2-8-0)
- [Upgrade notice: stable-2.7.0](#upgrade-notice-stable-2-7-0)
- [Upgrade notice: stable-2.6.0](#upgrade-notice-stable-2-6-0)
- [Upgrade notice: stable-2.5.0](#upgrade-notice-stable-2-5-0)
- [Upgrade notice: stable-2.4.0](#upgrade-notice-stable-2-4-0)
- [Upgrade notice: stable-2.3.0](#upgrade-notice-stable-2-3-0)
- [Upgrade notice: stable-2.2.0](#upgrade-notice-stable-2-2-0)

## Steps to upgrade

There are three components that need to be upgraded, in turn:

- [CLI](#upgrade-the-cli)
- [Control Plane](#upgrade-the-control-plane)
- [Data Plane](#upgrade-the-data-plane)

## Upgrade the CLI

This will upgrade your local CLI to the latest version. You will want to follow
these instructions for anywhere that uses the Linkerd CLI. For Helm users feel
free to skip to the [Helm section](#with-helm).

To upgrade the CLI locally, run:

```bash
curl --proto '=https' --tlsv1.2 -sSfL https://run.linkerd.io/install | sh
```

Alternatively, you can download the CLI directly via the
[Linkerd releases page](https://github.com/linkerd/linkerd2/releases/).

Verify the CLI is installed and running correctly with:

```bash
linkerd version --client
```

Which should display:

```bash
Client version: {{< latest-stable-version >}}
```

{{< note >}}
Until you upgrade the control plane, some new CLI commands may not work.
{{< /note >}}

You are now ready to [upgrade your control plane](#upgrade-the-control-plane).

## Upgrade the Control Plane

Now that you have upgraded the CLI, it is time to upgrade the Linkerd control
plane on your Kubernetes cluster. Don't worry, the existing data plane will
continue to operate with a newer version of the control plane and your meshed
services will not go down.

{{< note >}}
You will lose the historical data from Prometheus. If you would like to have
that data persisted through an upgrade, take a look at the
[persistence documentation](../exporting-metrics/)
{{< /note >}}

### With Linkerd CLI

Use the `linkerd upgrade` command to upgrade the control plane. This command
ensures that all of the control plane's existing configuration and mTLS secrets
are retained. Notice that we use the `--prune` flag to remove any Linkerd
resources from the previous version which no longer exist in the new version.

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

For upgrading a multi-stage installation setup, follow the instructions at
[Upgrading a multi-stage install](#upgrading-a-multi-stage-install).

Users who have previously saved the Linkerd control plane's configuration to
files can follow the instructions at
[Upgrading via manifests](#upgrading-via-manifests)
to ensure those configuration are retained by the `linkerd upgrade` command.

### With Helm

For a Helm workflow, check out the instructions at
[Helm upgrade procedure](../install-helm/#helm-upgrade-procedure).

### Verify the control plane upgrade

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

Which should display:

```txt
Client version: {{< latest-stable-version >}}
Server version: {{< latest-stable-version >}}
```

Next, we will [upgrade your data plane](#upgrade-the-data-plane).

## Upgrade the Data Plane

With a fully up-to-date CLI running locally and Linkerd control plane running on
your Kubernetes cluster, it is time to upgrade the data plane. The easiest
way to do this is to run a rolling deploy on your services, allowing the
proxy-injector to inject the latest version of the proxy as they come up.

With `kubectl` 1.15+, this can be as simple as using the `kubectl rollout
restart` command to restart all your meshed services. For example,

```bash
kubectl -n <namespace> rollout restart deploy
```

{{< note >}}
Unless otherwise documented in the release notes, stable release control planes
should be compatible with the data plane from the previous stable release.
Thus, data plane upgrades can be done at any point after the control plane has
been upgraded, including as part of the application's natural deploy cycle.  A
gap of more than one stable version between control plane and data plane is not
recommended.
{{< /note >}}

Workloads that were previously injected using the `linkerd inject --manual`
command can be upgraded by re-injecting the applications in-place. For example,

```bash
kubectl -n emojivoto get deploy -l linkerd.io/control-plane-ns=linkerd -oyaml \
  | linkerd inject --manual - \
  | kubectl apply -f -
```

### Verify the data plane upgrade

Check to make sure everything is healthy by running:

```bash
linkerd check --proxy
```

This will run through a set of checks to verify that the data plane is
operating correctly, and will list any pods that are still running older
versions of the proxy.

Congratulation! You have successfully upgraded your Linkerd to the newer
version. If you have any questions, feel free to raise them at the #linkerd2
channel in the [Linkerd slack](https://slack.linkerd.io/).

## Upgrade notice: stable-2.10.0

If you are currently running Linkerd 2.9.0, 2.9.1, 2.9.2, or 2.9.3 (but *not*
2.9.4), and you *upgraded* to that release using the `--prune` flag (as opposed
to installing it fresh), you will need to use the `linkerd repair` command as
outlined in the [Linkerd 2.9.3 upgrade notes](#upgrade-notice-stable-2-9-3)
before you can upgrade to Linkerd 2.10.

Additionally, there are two changes in the 2.10.0 release that may affect you.
First, the handling of certain ports and protocols has changed. Please read
through our [ports and protocols in 2.10 upgrade
guide](../../features/protocol-detection/) for the repercussions.

Second, we've introduced [extensions](../extensions/) and moved the
default visualization components into a Linkerd-Viz extension. Read on for what
this means for you.

### Visualization components moved to Linkerd-Viz extension

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

## Upgrade notice: stable-2.9.4

See upgrade notes for 2.9.3 below.

## Upgrade notice: stable-2.9.3

### Linkerd Repair

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

## Upgrade notice: stable-2.9.0

### Images are now hosted on ghcr.io

As of this version images are now hosted under `ghcr.io` instead of `gcr.io`. If
you're pulling images into a private repo please make the necessary changes.

### Upgrading multicluster environments

Linkerd 2.9 changes the way that some of the multicluster components work and
are installed compared to Linkerd 2.8.x. Users installing the multicluster
components for the first time with Linkerd 2.9 can ignore these instructions and
instead refer directly to the [installing
multicluster instructions](../installing-multicluster/).

Users who installed the multicluster component in Linkerd 2.8.x and wish to
upgrade to Linkerd 2.9 should follow the [upgrade multicluster
instructions](../upgrade-multicluster/).

### Ingress behavior changes

In previous versions when you injected your ingress controller (Nginx, Traefik,
Ambassador, etc), then the ingress' balancing/routing choices would be
overridden with Linkerd's (using service profiles, traffic splits, etc.).

As of 2.9 the ingress's choices are honored instead, which allows preserving
things like session-stickiness. Note however that this means per-route metrics
are not collected, traffic splits will not be honored and retries/timeouts are
not applied.

If you want to revert to the previous behavior, inject the proxy into the
ingress controller using the annotation `linkerd.io/inject: ingress`, as
explained in [using ingress](../using-ingress/)

### Breaking changes in Helm charts

Some entries like `controllerLogLevel` and all the Prometheus config have
changed their position in the settings hierarchy. To get a precise view of what
has changed you can compare the
[stable-2.8.1](https://github.com/linkerd/linkerd2/blob/stable-2.8.1/charts/linkerd2/values.yaml)
and
[stable-2.9.0](https://github.com/linkerd/linkerd2/blob/stable-2.9.0/charts/linkerd2/values.yaml)
`values.yaml` files.

### Post-upgrade cleanup

In order to better support cert-manager, the secrets
`linkerd-proxy-injector-tls`, `linkerd-sp-validator-tls` and `linkerd-tap-tls`
have been replaced by the secrets `linkerd-proxy-injector-k8s-tls`,
`linkerd-sp-validator-k8s-tls` and `linkerd-tap-k8s-tls` respectively. If you
upgraded through the CLI, please delete the old ones (if you upgraded through
Helm the cleanup was automated).

## Upgrade notice: stable-2.8.0

There are no version-specific notes for upgrading to this release. The upgrade
process detailed above ([upgrade the CLI](#upgrade-the-cli),
[upgrade the control plane](#upgrade-the-control-plane), then
[upgrade the data plane](#upgrade-the-data-plane)) should
work.

## Upgrade notice: stable-2.7.0

### Checking whether any of your TLS certificates are approaching expiry

This version introduces a set of CLI flags and checks that help you rotate
your TLS certificates. The new CLI checks will warn you if any of your
certificates are expiring in the next 60 days. If you however want to check
the expiration date of your certificates and determine for yourself whether
you should be rotating them, you can execute the following commands. Note that
this will require [step 0.13.3](https://smallstep.com/cli/) and
[jq 1.6](https://stedolan.github.io/jq/).

Check your trust roots:

```bash
kubectl -n linkerd get cm linkerd-config -o=jsonpath="{.data}" |  \
jq -r .identityContext.trustAnchorsPem | \
step certificate inspect --short -

X.509v3 Root CA Certificate (ECDSA P-256) [Serial: 1]
  Subject:     identity.linkerd.cluster.local
  Issuer:      identity.linkerd.cluster.local
  Valid from:  2020-01-14T13:23:32Z
          to:  2021-01-13T13:23:52Z
```

Check your issuer certificate:

```bash
kubectl -n linkerd get secret linkerd-identity-issuer -o=jsonpath="{.data['crt\.pem']}" |  \
base64 --decode | \
step certificate inspect --short -

X.509v3 Root CA Certificate (ECDSA P-256) [Serial: 1]
  Subject:     identity.linkerd.cluster.local
  Issuer:      identity.linkerd.cluster.local
  Valid from:  2020-01-14T13:23:32Z
          to:  2021-01-13T13:23:52Z
```

If you determine that you wish to rotate your certificates you can follow
the process outlined in
[Rotating your identity certificates](../manually-rotating-control-plane-tls-credentials/).
Note that this process uses functionality available in stable-2.7.0. So before
you start your cert rotation, make sure to upgrade.

When ready, you can begin the upgrade process by
[installing the new CLI](#upgrade-the-cli).

### Breaking changes in Helm charts

As part of an effort to follow Helm's best practices the Linkerd Helm
chart has been restructured. As a result most of the keys have been changed.
In order to ensure trouble-free upgrade of your Helm installation, please take
a look at [Helm upgrade procedure](../install-helm/). To get a precise
view of what has changed you can compare that
[stable-2.6.0](https://github.com/linkerd/linkerd2/blob/stable-2.6.0/charts/linkerd2/values.yaml)
and [stable-2.7.0](https://github.com/linkerd/linkerd2/blob/stable-2.7.0/charts/linkerd2/values.yaml)
`values.yaml` files.

## Upgrade notice: stable-2.6.0

{{< note >}}
Upgrading to this release from edge-19.9.3, edge-19.9.4, edge-19.9.5 and
edge-19.10.1 will incur data plane downtime, due to a recent change introduced
to ensure zero downtime upgrade for previous stable releases.
{{< /note >}}

The `destination` container is now deployed as its own `Deployment` workload.
When you are planning the upgrade from one of the edge versions listed above,
be sure to allocate time to restart the data plane once the control plane is
successfully upgraded. This restart can be done at your convenience with the
recommendation that it be done over the course of time appropriate for your
application.

If you are upgrading from a previous stable version, restarting the data-plane
is __recommended__ as a best practice, although not necessary.

If you have previously labelled any of your namespaces with the
`linkerd.io/is-control-plane` label so that their pod creation events are
ignored by the HA proxy injector, you will need to update these namespaces
to use the new `config.linkerd.io/admission-webhooks: disabled` label.

When ready, you can begin the upgrade process by
[installing the new CLI](#upgrade-the-cli).

## Upgrade notice: stable-2.5.0

This release supports Kubernetes 1.12+.

{{< note >}}
Linkerd 2.5.0 introduced [Helm support](../install-helm/). If Linkerd was
installed via `linkerd install`, it must be upgraded via `linkerd upgrade`. If
Linkerd was installed via Helm, it must be upgraded via Helm. Mixing these two
installation procedures is not supported.
{{< /note >}}

### Upgrading from stable-2.4.x

{{< note >}}
These instructions also apply to upgrading from edge-19.7.4, edge-19.7.5,
edge-19.8.1, edge-19.8.2, edge-19.8.3, edge-19.8.4, and edge-19.8.5.
{{< /note >}}

Use the `linkerd upgrade` command to upgrade the control plane. This command
ensures that all of the control plane's existing configuration and mTLS secrets
are retained.

```bash
# get the latest stable CLI
curl --proto '=https' --tlsv1.2 -sSfL https://run.linkerd.io/install | sh
```

{{< note >}} The linkerd cli installer installs the CLI binary into a
versioned file (e.g. `linkerd-stable-2.5.0`) under the `$INSTALLROOT` (default:
`$HOME/.linkerd`) directory and provides a convenience symlink at
`$INSTALLROOT/bin/linkerd`.

If you need to have multiple versions of the linkerd cli installed
alongside each other (for example if you are running an edge release on
your test cluster but a stable release on your production cluster) you
can refer to them by their full paths, e.g. `$INSTALLROOT/bin/linkerd-stable-2.5.0`
and `$INSTALLROOT/bin/linkerd-edge-19.8.8`.
{{< /note >}}

```bash
linkerd upgrade | kubectl apply --prune -l linkerd.io/control-plane-ns=linkerd -f -
```

The options `--prune -l linkerd.io/control-plane-ns=linkerd` above make sure
that any resources that are removed from the `linkerd upgrade` output, are
effectively removed from the system.

For upgrading a multi-stage installation setup, follow the instructions at
[Upgrading a multi-stage install](#upgrading-a-multi-stage-install).

Users who have previously saved the Linkerd control plane's configuration to
files can follow the instructions at
[Upgrading via manifests](#upgrading-via-manifests)
to ensure those configuration are retained by the `linkerd upgrade` command.

Once the `upgrade` command completes, use the `linkerd check` command to confirm
the control plane is ready.

{{< note >}}
The `stable-2.5` `linkerd check` command will return an error when run against
an older control plane. This error is benign and will resolve itself once the
control plane is upgraded to `stable-2.5`:

```bash
linkerd-config
--------------
√ control plane Namespace exists
√ control plane ClusterRoles exist
√ control plane ClusterRoleBindings exist
× control plane ServiceAccounts exist
    missing ServiceAccounts: linkerd-heartbeat
    see https://linkerd.io/2/checks/#l5d-existence-sa for hints
```

{{< /note >}}

When ready, proceed to upgrading the data plane by following the instructions at
[Upgrade the data plane](#upgrade-the-data-plane).

## Upgrade notice: stable-2.4.0

This release supports Kubernetes 1.12+.

### Upgrading from stable-2.3.x, edge-19.4.5, edge-19.5.x, edge-19.6.x, edge-19.7.x

Use the `linkerd upgrade` command to upgrade the control plane. This command
ensures that all of the control plane's existing configuration and mTLS secrets
are retained.

```bash
# get the latest stable CLI
curl --proto '=https' --tlsv1.2 -sSfL https://run.linkerd.io/install | sh
```

For Kubernetes 1.12+:

```bash
linkerd upgrade | kubectl apply --prune -l linkerd.io/control-plane-ns=linkerd -f -
```

For Kubernetes pre-1.12 where the mutating and validating webhook
configurations' `sideEffects` fields aren't supported:

```bash
linkerd upgrade --omit-webhook-side-effects | kubectl apply --prune -l linkerd.io/control-plane-ns=linkerd -f -
```

The `sideEffects` field is added to the Linkerd webhook configurations to
indicate that the webhooks have no side effects on other resources.

For HA setup, the `linkerd upgrade` command will also retain all previous HA
configuration. Note that the mutating and validating webhook configurations are
updated to set their `failurePolicy` fields to `fail` to ensure that un-injected
workloads (as a result of unexpected errors) are rejected during the admission
process. The HA mode has also been updated to schedule multiple replicas of the
`linkerd-proxy-injector` and `linkerd-sp-validator` deployments.

For users upgrading from the `edge-19.5.3` release, note that the upgrade
process will fail with the following error message, due to a naming bug:

```bash
The ClusterRoleBinding "linkerd-linkerd-tap" is invalid: roleRef: Invalid value:
rbac.RoleRef{APIGroup:"rbac.authorization.k8s.io", Kind:"ClusterRole",
Name:"linkerd-linkerd-tap"}: cannot change roleRef
```

This can be resolved by simply deleting the `linkerd-linkerd-tap` cluster role
binding resource, and re-running the `linkerd upgrade` command:

```bash
kubectl delete clusterrole/linkerd-linkerd-tap
```

For upgrading a multi-stage installation setup, follow the instructions at
[Upgrading a multi-stage install](#upgrading-a-multi-stage-install).

Users who have previously saved the Linkerd control plane's configuration to
files can follow the instructions at
[Upgrading via manifests](#upgrading-via-manifests)
to ensure those configuration are retained by the `linkerd upgrade` command.

Once the `upgrade` command completes, use the `linkerd check` command to confirm
the control plane is ready.

{{< note >}}
The `stable-2.4` `linkerd check` command will return an error when run against
an older control plane. This error is benign and will resolve itself once the
control plane is upgraded to `stable-2.4`:

```bash
linkerd-config
--------------
√ control plane Namespace exists
× control plane ClusterRoles exist
    missing ClusterRoles: linkerd-linkerd-controller, linkerd-linkerd-identity, linkerd-linkerd-prometheus, linkerd-linkerd-proxy-injector, linkerd-linkerd-sp-validator, linkerd-linkerd-tap
    see https://linkerd.io/2/checks/#l5d-existence-cr for hints
```

{{< /note >}}

When ready, proceed to upgrading the data plane by following the instructions at
[Upgrade the data plane](#upgrade-the-data-plane).

### Upgrading from stable-2.2.x

Follow the [stable-2.3.0 upgrade instructions](#upgrading-from-stable-22x-1)
to upgrade the control plane to the stable-2.3.2 release first. Then follow
[these instructions](#upgrading-from-stable-23x-edge-1945-edge-195x-edge-196x-edge-197x)
to upgrade the stable-2.3.2 control plane to `stable-2.4.0`.

## Upgrade notice: stable-2.3.0

`stable-2.3.0` introduces a new `upgrade` command. This command only works for
the `edge-19.4.x` and newer releases. When using the `upgrade` command from
`edge-19.2.x` or `edge-19.3.x`, all the installation flags previously provided
to the `install` command must also be added.

### Upgrading from stable-2.2.x

To upgrade from the `stable-2.2.x` release, follow the
[Step-by-step instructions](#step-by-step-instructions-stable-22x).

Note that if you had previously installed Linkerd with `--tls=optional`, delete
the `linkerd-ca` deployment after successful Linkerd control plane upgrade:

```bash
kubectl -n linkerd delete deploy/linkerd-ca
```

### Upgrading from edge-19.4.x

```bash
# get the latest stable
curl --proto '=https' --tlsv1.2 -sSfL https://run.linkerd.io/install | sh

# upgrade the control plane
linkerd upgrade | kubectl apply --prune -l linkerd.io/control-plane-ns=linkerd -f -
```

Follow instructions for
[upgrading the data plane](#upgrade-the-data-plane).

#### Upgrading a multi-stage install

`edge-19.4.5` introduced a
[Multi-stage install](../install/#multi-stage-install) feature. If you
previously installed Linkerd via a multi-stage install process, you can upgrade
each stage, analogous to the original multi-stage installation process.

Stage 1, for the cluster owner:

```bash
linkerd upgrade config | kubectl apply -f -
```

Stage 2, for the service owner:

```bash
linkerd upgrade control-plane | kubectl apply -f -
```

{{< note >}}
Passing the `--prune` flag to `kubectl` does not work well with multi-stage
upgrades. It is recommended to manually prune old resources after completing
the above steps.
{{< /note >}}

#### Upgrading via manifests

By default, the `linkerd upgrade` command reuses the existing `linkerd-config`
config map and the `linkerd-identity-issuer` secret, by fetching them via the
the Kubernetes API. `edge-19.4.5` introduced a new `--from-manifests` flag to
allow the upgrade command to read the `linkerd-config` config map and the
`linkerd-identity-issuer` secret from a static YAML file. This option is
relevant to CI/CD workflows where the Linkerd configuration is managed by a
configuration repository.

For release after `edge-20.10.1`/`stable-2.9.0`, you need to add `secret/linkerd-config-overrides`
to the `linkerd-manifest.yaml` by running command:

```bash
kubectl -n linkerd get \
  secret/linkerd-identity-issuer \
  configmap/linkerd-config \
  secret/linkerd-config-overrides \
  -oyaml > linkerd-manifests.yaml

linkerd upgrade --from-manifests linkerd-manifests.yaml | kubectl apply --prune -l linkerd.io/control-plane-ns=linkerd -f -
```

For release after `stable-2.6.0` and prior to `edge-20.10.1`/`stable-2.9.0`,
you can use this command:

```bash
kubectl -n linkerd get \
  secret/linkerd-identity-issuer \
  configmap/linkerd-config \
  -oyaml > linkerd-manifests.yaml

linkerd upgrade --from-manifests linkerd-manifests.yaml | kubectl apply --prune -l linkerd.io/control-plane-ns=linkerd -f -
```

For releases prior to `edge-19.8.1`/`stable-2.5.0`, and after `stable-2.6.0`,
you may pipe a full `linkerd install` manifest into the upgrade command:

```bash
linkerd install > linkerd-install.yaml

# deploy Linkerd
cat linkerd-install.yaml | kubectl apply -f -

# upgrade Linkerd via manifests
cat linkerd-install.yaml | linkerd upgrade --from-manifests -
```

{{< note >}}
`secret/linkerd-identity-issuer` contains the trust root of Linkerd's Identity
system, in the form of a private key. Care should be taken if storing this
information on disk, such as using tools like
[git-secret](https://git-secret.io/).
{{< /note >}}

### Upgrading from edge-19.2.x or edge-19.3.x

```bash
# get the latest stable
curl --proto '=https' --tlsv1.2 -sSfL https://run.linkerd.io/install | sh

# Install stable control plane, using flags previously supplied during
# installation.
# For example, if the previous installation was:
# linkerd install --proxy-log-level=warn --proxy-auto-inject | kubectl apply -f -
# The upgrade command would be:
linkerd upgrade --proxy-log-level=warn --proxy-auto-inject | kubectl apply --prune -l linkerd.io/control-plane-ns=linkerd -f -
```

Follow instructions for
[upgrading the data plane](#upgrade-the-data-plane).

## Upgrade notice: stable-2.2.0

There are two breaking changes in `stable-2.2.0`. One relates to
[Service Profiles](../../features/service-profiles/), the other relates to
[Automatic Proxy Injection](../../features/proxy-injection/). If you are not using
either of these features, you may [skip directly](#step-by-step-instructions-stable-22x)
to the full upgrade instructions.

### Service Profile namespace location

[Service Profiles](../../features/service-profiles/), previously defined in the
control plane namespace in `stable-2.1.0`, are now defined in their respective
client and server namespaces. Service Profiles defined in the client namespace
take priority over ones defined in the server namespace.

### Automatic Proxy Injection opt-in

The `linkerd.io/inject` annotation, previously opt-out in `stable-2.1.0`, is now
opt-in.

To enable automation proxy injection for a namespace, you must enable the
`linkerd.io/inject` annotation on either the namespace or the pod spec. For more
details, see the [Automatic Proxy Injection](../../features/proxy-injection/) doc.

#### A note about application updates

Also note that auto-injection only works during resource creation, not update.
To update the data plane proxies of a deployment that was auto-injected, do one
of the following:

- Manually re-inject the application via `linkerd inject` (more info below under
  [Upgrade the data plane](#upgrade-the-data-plane))
- Delete and redeploy the application

Auto-inject support for application updates is tracked on
[github](https://github.com/linkerd/linkerd2/issues/2260)

## Step-by-step instructions (stable-2.2.x)

### Upgrade the 2.2.x CLI

This will upgrade your local CLI to the latest version. You will want to follow
these instructions for anywhere that uses the linkerd CLI.

To upgrade the CLI locally, run:

```bash
curl --proto '=https' --tlsv1.2 -sSfL https://run.linkerd.io/install | sh
```

Alternatively, you can download the CLI directly via the
[Linkerd releases page](https://github.com/linkerd/linkerd2/releases/).

Verify the CLI is installed and running correctly with:

```bash
linkerd version
```

Which should display:

```bash
Client version: {{< latest-stable-version >}}
Server version: stable-2.1.0
```

It is expected that the Client and Server versions won't match at this point in
the process. Nothing has been changed on the cluster, only the local CLI has
been updated.

{{< note >}}
Until you upgrade the control plane, some new CLI commands may not work.
{{< /note >}}

### Upgrade the 2.2.x control plane

Now that you have upgraded the CLI running locally, it is time to upgrade the
Linkerd control plane on your Kubernetes cluster. Don't worry, the existing data
plane will continue to operate with a newer version of the control plane and
your meshed services will not go down.

To upgrade the control plane in your environment, run the following command.
This will cause a rolling deploy of the control plane components that have
changed.

```bash
linkerd install | kubectl apply -f -
```

The output will be:

```bash
namespace/linkerd configured
configmap/linkerd-config created
serviceaccount/linkerd-identity created
clusterrole.rbac.authorization.k8s.io/linkerd-linkerd-identity configured
clusterrolebinding.rbac.authorization.k8s.io/linkerd-linkerd-identity configured
service/linkerd-identity created
secret/linkerd-identity-issuer created
deployment.extensions/linkerd-identity created
serviceaccount/linkerd-controller unchanged
clusterrole.rbac.authorization.k8s.io/linkerd-linkerd-controller configured
clusterrolebinding.rbac.authorization.k8s.io/linkerd-linkerd-controller configured
service/linkerd-controller-api configured
service/linkerd-destination created
deployment.extensions/linkerd-controller configured
customresourcedefinition.apiextensions.k8s.io/serviceprofiles.linkerd.io configured
serviceaccount/linkerd-web unchanged
service/linkerd-web configured
deployment.extensions/linkerd-web configured
serviceaccount/linkerd-prometheus unchanged
clusterrole.rbac.authorization.k8s.io/linkerd-linkerd-prometheus configured
clusterrolebinding.rbac.authorization.k8s.io/linkerd-linkerd-prometheus configured
service/linkerd-prometheus configured
deployment.extensions/linkerd-prometheus configured
configmap/linkerd-prometheus-config configured
serviceaccount/linkerd-grafana unchanged
service/linkerd-grafana configured
deployment.extensions/linkerd-grafana configured
configmap/linkerd-grafana-config configured
serviceaccount/linkerd-sp-validator created
clusterrole.rbac.authorization.k8s.io/linkerd-linkerd-sp-validator configured
clusterrolebinding.rbac.authorization.k8s.io/linkerd-linkerd-sp-validator configured
service/linkerd-sp-validator created
deployment.extensions/linkerd-sp-validator created
```

Check to make sure everything is healthy by running:

```bash
linkerd check
```

This will run through a set of checks against your control plane and make sure
that it is operating correctly.

To verify the Linkerd control plane version, run:

```bash
linkerd version
```

Which should display:

```txt
Client version: {{< latest-stable-version >}}
Server version: {{< latest-stable-version >}}
```

{{< note >}}
You will lose the historical data from Prometheus. If you would like to have
that data persisted through an upgrade, take a look at the
[persistence documentation](../exporting-metrics/)
{{< /note >}}

### Upgrade the 2.2.x data plane

With a fully up-to-date CLI running locally and Linkerd control plane running on
your Kubernetes cluster, it is time to upgrade the data plane. This will change
the version of the `linkerd-proxy` sidecar container and run a rolling deploy on
your service.

For `stable-2.3.0`+, if your workloads are annotated with the auto-inject
`linkerd.io/inject: enabled` annotation, then you can just restart your pods
using your Kubernetes cluster management tools (`helm`, `kubectl` etc.).

{{< note >}}
With `kubectl` 1.15+, you can use the `kubectl rollout restart` command to
restart all your meshed services. For example,

```bash
kubectl -n <namespace> rollout restart deploy
```

{{< /note >}}

As the pods are being re-created, the proxy injector will auto-inject the new
version of the proxy into the pods.

If auto-injection is not part of your workflow, you can still manually upgrade
your meshed services by re-injecting your applications in-place.

Begin by retrieving your YAML resources via `kubectl`, and pass them through the
`linkerd inject` command. This will update the pod spec with the
`linkerd.io/inject: enabled` annotation. This annotation will be picked up by
Linkerd's proxy injector during the admission phase where the Linkerd proxy will
be injected into the workload. By using `kubectl apply`, Kubernetes will do a
rolling deploy of your service and update the running pods to the latest
version.

Example command to upgrade an application in the `emojivoto` namespace, composed
of deployments:

```bash
kubectl -n emojivoto get deploy -l linkerd.io/control-plane-ns=linkerd -oyaml \
  | linkerd inject - \
  | kubectl apply -f -
```

Check to make sure everything is healthy by running:

```bash
linkerd check --proxy
```

This will run through a set of checks against both your control plane and data
plane to verify that it is operating correctly.

You can make sure that you've fully upgraded all the data plane by running:

```bash
kubectl get po --all-namespaces -o yaml \
  | grep linkerd.io/proxy-version
```

The output will look something like:

```bash
linkerd.io/proxy-version: {{< latest-stable-version >}}
linkerd.io/proxy-version: {{< latest-stable-version >}}
```

If there are any older versions listed, you will want to upgrade them as well.
