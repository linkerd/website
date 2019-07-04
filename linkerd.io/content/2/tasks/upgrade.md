+++
title = "Upgrading Linkerd"
description = "Upgrade Linkerd to the latest version."
aliases = [
  "/2/upgrade/",
  "/2/update/"
]
+++

There are three components that need to be upgraded:

- [CLI](/2/reference/architecture/#cli)
- [Control Plane](/2/reference/architecture/#control-plane)
- [Data Plane](/2/reference/architecture/#data-plane)

In this guide, we'll walk you through how to upgrade all three components
incrementally without taking down any of your services.

## Upgrade notice: stable-2.4.0

This release supports Kubernetes 1.12+.

### Upgrading from stable-2.3.x, edge-19.4.5, edge-19.5.x, edge-19.6.x, edge-19.7.1

Use the `linkerd upgrade` command to upgrade the control plane. This command
ensures that all existing control plane's configuration and mTLS secrets are
retained.

```bash
# get the latest stable CLI
curl -sL https://run.linkerd.io/install | sh
```

For Kubernetes 1.12+:

```bash
linkerd upgrade | kubectl apply -f -
```

For Kubernetes pre-1.12 where the mutating and validating webhook
configurations' `sideEffects` fields aren't supported:

```bash
linkerd upgrade --omit-webhook-side-effects | kubectl apply -f -
```

The `sideEffects` field is added to the Linkerd webhook configurations to
indicate that the webhooks have no side effects on other resources.

For HA setup, the `linkerd upgrade` command will also retain all previous HA
configuration. Note that the mutating and validating webhook configuration are
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
[Upgrading a multi-stage install](/2/tasks/upgrade/#upgading-a-multi-stage-install).

Users who have previously saved the Linkerd control plane's configuration to
files can follow the instructions at
[Upgrading via manifests](/2/tasks/upgrade/#upgrading-via-manifests)
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
    see https://linkerd.io/checks/#l5d-existence-cr for hints
```

{{< /note >}}

When ready, proceed to upgrading the data plane by following the instructions at
[Upgrade the data plane](#upgrade-the-data-plane).

### Upgrading from stable-2.2.x

Follow the [stable-2.3.0 upgrade instructions](/2/tasks/upgrade/#upgrading-from-stable-2-2-x-1)
to upgrade the control plane to the stable-2.3.2 release first. Then follow
[these instructions](/2/tasks/upgrade/#upgrading-from-stable-2-3-x-edge-19-4-5-edge-19-5-x-edge-19-6-x-edge-19-7-1)
to upgrade the stable-2.3.2 control plane to `stable-2.4.0`.

## Upgrade notice: stable-2.3.0

`stable-2.3.0` introduces a new `upgrade` command. This command only works for
the `edge-19.4.x` and newer releases. When using the `upgrade` command from
`edge-19.2.x` or `edge-19.3.x`, all the installation flags previously provided
to the `install` command must also be added.

### Upgrading from stable-2.2.x

To upgrade from the `stable-2.2.x` release, follow the
[Step-by-step instructions](#step-by-step-instructions).

Note that if you had previously installed Linkerd with `--tls=optional`, delete
the `linkerd-ca` deployment after successful Linkerd control plane upgrade:

```bash
kubectl -n linkerd delete deploy/linkerd-ca
```

### Upgrading from edge-19.4.x

```bash
# get the latest stable
curl -sL https://run.linkerd.io/install | sh

# upgrade the control plane
linkerd upgrade | kubectl apply -f -
```

Follow instructions for
[upgrading the data plane](#upgrade-the-data-plane).

#### Upgading a multi-stage install

`edge-19.4.5` introduced a
[Multi-stage install](/2/tasks/install/#multi-stage-install) feature. If you
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

#### Upgrading via manifests

`edge-19.4.5` introduced a new `--from-manifests` flag to `linkerd upgrade`
allowing manually feeding a previously saved output of `linkerd install` into
the command, instead of requiring a connection to the cluster to fetch the
config:

```bash
# save Linkerd installation manifest
linkerd install > linkerd-install.yaml

# deploy Linkerd
cat linkerd-install.yaml | kubectl apply -f -

# upgrade Linkerd via manifests
cat linkerd-install.yaml | linkerd upgrade --from-manifests -
```

Alternatively, if you have already installed Linkerd without saving a manifest,
you may save the relevant Linkerd resources from your existing installation for
use in upgrading later.

```bash
kubectl -n linkerd get \
  secret/linkerd-identity-issuer \
  configmap/linkerd-config \
  -oyaml > linkerd-manifests.yaml

cat linkerd-manifests.yaml | linkerd upgrade --from-manifests -
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
curl -sL https://run.linkerd.io/install | sh

# Install stable control plane, using flags previously supplied during
# installation.
# For example, if the previous installation was:
# linkerd install --proxy-log-level=warn --proxy-auto-inject | kubectl apply -f -
# The upgrade command would be:
linkerd upgrade --proxy-log-level=warn --proxy-auto-inject | kubectl apply -f -
```

Follow instructions for
[upgrading the data plane](#upgrade-the-data-plane).

## Upgrade notice: stable-2.2.0

There are two breaking changes in `stable-2.2.0`. One relates to
[Service Profiles](/2/features/service-profiles/), the other relates to
[Automatic Proxy Injection](/2/features/proxy-injection/). If you are not using
either of these features, you may [skip directly](#step-by-step-instructions) to
the full upgrade instructions.

### Service Profile namespace location

[Service Profiles](/2/features/service-profiles/), previously defined in the
control plane namespace in `stable-2.1.0`, are now defined in their respective
client and server namespaces. Service Profiles defined in the client namespace
take priority over ones defined in the server namespace.

### Automatic Proxy Injection opt-in

The `linkerd.io/inject` annotation, previously opt-out in `stable-2.1.0`, is now
opt-in.

To enable automation proxy injection for a namespace, you must enable the
`linkerd.io/inject` annotation on either the namespace or the pod spec. For more
details, see the [Automatic Proxy Injection](/2/features/proxy-injection/) doc.

#### A note about application updates

Also note that auto-injection only works during resource creation, not update.
To update the data plane proxies of a deployment that was auto-injected, do one
of the following:

- Manually re-inject the application via `linkerd inject` (more info below under
  [Upgrade the data plane](#upgrade-the-data-plane))
- Delete and redeploy the application

Auto-inject support for application updates is tracked on
[github](https://github.com/linkerd/linkerd2/issues/2260)

## Step-by-step instructions

### Upgrade the CLI

This will upgrade your local CLI to the latest version. You will want to follow
these instructions for anywhere that uses the linkerd CLI.

To upgrade the CLI locally, run:

```bash
curl -sL https://run.linkerd.io/install | sh
```

Alternatively, you can download the CLI directly via the
[Linkerd releases page](https://github.com/linkerd/linkerd2/releases/).

Verify the CLI is installed and running correctly with:

```bash
linkerd version
```

Which should display:

```bash
Client version: {{% latestversion %}}
Server version: stable-2.1.0
```

It is expected that the Client and Server versions won't match at this point in
the process. Nothing has been changed on the cluster, only the local CLI has
been updated.

{{< note >}}
Until you upgrade the control plane, some new CLI commands may not work.
{{< /note >}}

### Upgrade the control plane

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
Client version: {{% latestversion %}}
Server version: {{% latestversion %}}
```

{{< note >}}
You will lose the historical data from Prometheus. If you would like to have
that data persisted through an upgrade, take a look at the
[persistence documentation](/2/observability/exporting-metrics/)
{{< /note >}}

### Upgrade the data plane

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

If the auto-injection is not part of your workflow, you can still manually
upgrade your meshed services by re-injecting your applications in-place.

Begin by retrieving your YAML resources via `kubectl`, and pass them through the
`linkerd inject` command. This will update the pod spec with the
`linkerd.io/inject: enabled` annotation. This annotation will be picked up by
the Linkerd's proxy injector during the admission phase where the Linkerd proxy
will be injected into the workload. By using `kubectl apply`, Kubernetes will do
a rolling deploy of your service and update the running pods to the latest
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
linkerd.io/proxy-version: {{% latestversion %}}
linkerd.io/proxy-version: {{% latestversion %}}
```

If there are any older versions listed, you will want to upgrade them as well.
