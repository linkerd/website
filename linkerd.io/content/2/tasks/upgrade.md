+++
date = "2018-09-10T12:00:00-07:00"
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

# Upgrade notice: stable-2.2.0

## Breaking changes

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

Auto-inject support for application updates is tracked at:
https://github.com/linkerd/linkerd2/issues/2260

# Upgrade notice: stable-2.1.0

As of the `stable-2.1.0` release, the Linkerd control plane components have been
renamed to reduce possible naming collisions. If you're upgrading from an older
version, you will need to clean up the old components manually as part of the
upgrade. Perform the upgrade in the following order:

1. If Linkerd is installed with
  [automatic proxy injection](/2/features/proxy-injection/),
  enabled, then you'll need to start by removing the webhook that was created
  when it was installed, by running:

    ```bash
    kubectl -n linkerd delete \
      mutatingwebhookconfigurations/linkerd-proxy-injector-webhook-config \
      --ignore-not-found
    ```

1. [Upgrade the CLI](#upgrade-the-cli). Note that right after upgrading the CLI,
   most of its commands will fail. You can only rely on the `linkerd install`
   command to complete the following steps, and only after doing so will the
   CLI be fully usable again.

1. [Upgrade the control plane](#upgrade-the-control-plane)

1. Remove the old control plane deployments and configmaps, by running:

    ```bash
    kubectl -n linkerd delete \
      deploy/ca \
      deploy/controller \
      deploy/grafana \
      deploy/prometheus \
      deploy/proxy-injector \
      deploy/web \
      cm/grafana-config \
      cm/prometheus-config \
      cm/proxy-injector-sidecar-config \
      --ignore-not-found
    ```

1. [Upgrade the data plane](#upgrade-the-data-plane)

1. Remove the old control plane services, by running:

    ```bash
    kubectl -n linkerd delete \
      svc/api \
      svc/grafana \
      svc/prometheus \
      svc/proxy-api \
      svc/proxy-injector \
      svc/web \
      --ignore-not-found
    ```

# Step-by-step instructions

## Upgrade the CLI

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

### Notes

- Until you upgrade the control plane, some new CLI commands may not work.

## Upgrade the control plane

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
namespace "linkerd" configured
serviceaccount "linkerd-controller" unchanged
clusterrole.rbac.authorization.k8s.io "linkerd-linkerd-controller" configured
clusterrolebinding.rbac.authorization.k8s.io "linkerd-linkerd-controller" configured
serviceaccount "linkerd-prometheus" unchanged
clusterrole.rbac.authorization.k8s.io "linkerd-linkerd-prometheus" configured
clusterrolebinding.rbac.authorization.k8s.io "linkerd-linkerd-prometheus" configured
service "linkerd-controller-api" configured
service "linkerd-proxy-api" configured
deployment.extensions "linkerd-controller" configured
customresourcedefinition.apiextensions.k8s.io "serviceprofiles.linkerd.io" configured
serviceaccount "linkerd-web" created
service "linkerd-web" configured
deployment.extensions "linkerd-web" configured
service "linkerd-prometheus" configured
deployment.extensions "linkerd-prometheus" configured
configmap "linkerd-prometheus-config" configured
serviceaccount "linkerd-grafana" created
service "linkerd-grafana" configured
deployment.extensions "linkerd-grafana" configured
configmap "linkerd-grafana-config" configured
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

### Notes

- You will lose the historical data from Prometheus. If you would like to have
  that data persisted through an upgrade, take a look at the
  [persistence documentation](/2/observability/exporting-metrics/)

## Upgrade the data plane

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
