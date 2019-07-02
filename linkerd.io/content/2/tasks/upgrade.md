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

For each of your meshed services, you can re-inject your applications in-place.
Retrieve your YAML resources via `kubectl`, and pass them through
`linkerd inject`. This will update the pod spec to have the latest version of
the `linkerd-proxy` sidecar container. By using `kubectl apply`, Kubernetes will
do a rolling deploy of your service and update the running pods to the latest
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
