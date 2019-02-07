+++
date = "2018-09-10T12:00:00-07:00"
title = "Upgrade"
[menu.l5d2docs]
  name = "Upgrade Linkerd"
  weight = 5
+++

There are three components that need to be upgraded:

- [CLI](/2/architecture#cli)
- [Control Plane](/2/architecture#control-plane)
- [Data Plane](/2/architecture#data-plane)

In this guide, we'll walk you through how to upgrade all three components
incrementally without taking down any of your services.

## Upgrade notice: stable-2.1.0

As of the stable-2.1.0 release, the Linkerd control plane components have been
renamed to reduce possible naming collisions. If you're upgrading from an older
version, you will need to clean up the old components manually as part of the
upgrade. Perform the upgrade in the following order:

1. If Linkerd is installed with [automatic proxy injection](/2/proxy-injection),
  enabled, then you'll need to start by removing the webhook that was created
  when it was installed, by running:

    ```bash
    kubectl -n linkerd delete \
      mutatingwebhookconfigurations/linkerd-proxy-injector-webhook-config \
      --ignore-not-found
    ```

1. [Upgrade the CLI](#upgrade-the-cli). Note that right after upgrading the CLI, most of its commands will fail. You can only rely on the `linkerd install` command to complete the following steps, and only after doing so will the CLI be fully usable again.

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
Server version: v18.8.1
```

It is expected that the Client and Server versions won't match at this point in
the process. Nothing has been changed on the cluster, only the local CLI has
been updated.

### Notes

- Until you upgrade the control plane, most CLI commands will not work.

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

```txt
namespace "linkerd" configured
serviceaccount "linkerd-controller" unchanged
clusterrole "linkerd-linkerd-controller" configured
clusterrolebinding "linkerd-linkerd-controller" configured
serviceaccount "linkerd-prometheus" unchanged
clusterrole "linkerd-linkerd-prometheus" configured
clusterrolebinding "linkerd-linkerd-prometheus" configured
service "api" configured
service "proxy-api" configured
deployment "controller" configured
service "web" configured
deployment "web" configured
service "prometheus" configured
deployment "prometheus" configured
configmap "prometheus-config" configured
service "grafana" configured
deployment "grafana" configured
configmap "grafana-config" configured
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
  [persistence documentation](/2/observability/prometheus/#exporting-metrics)

## Upgrade the data plane

With a fully up-to-date CLI running locally and Linkerd control plane running on
your Kubernetes cluster, it is time to upgrade the data plane. This will change
the version of the `linkerd-proxy` sidecar container and run a rolling deploy on
your service.

For each of your meshed services, you will want to take your YAML resource
definitions and pass them through `linkerd inject`. This will update the pod
spec to have the latest version of the `linkerd-proxy` sidecar container. By
using `kubectl apply`, Kubernetes will do a rolling deploy of your service and
update the running pods to the latest version.

To do this with the example application, emojivoto, you can run:

```bash
curl https://run.linkerd.io/emojivoto.yml \
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

```txt
linkerd.io/proxy-version: {{% latestversion %}}
linkerd.io/proxy-version: {{% latestversion %}}
```

If there are any older versions listed, you will want to upgrade them as well.
