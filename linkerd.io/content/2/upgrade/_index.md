+++
date = "2018-09-10T12:00:00-07:00"
title = "Upgrading Linkerd"
[menu.l5d2docs]
  name = "Upgrading Linkerd"
  weight = 8
+++

Linkerd is a fast-moving project and you will often find yourself in a
situation where you want to safely upgrade Linkerd without downtime. Don't worry,
Linkerd is designed to make this as safe as possible.

There are three components that need to be upgraded, and typically, you'll do
them in this order:

1. [CLI](/2/architecture#cli)
1. [Control Plane](/2/architecture#control-plane)
1. [Data Plane](/2/architecture#data-plane)

In this guide, we'll walk you through how to upgrade all three components
incrementally without taking down any of your services.

## Upgrade the CLI

This will upgrade your local CLI to the latest version. You will want to follow
these instructions for anywhere that uses the linkerd CLI.

To upgrade the CLI locally, run:

```bash
curl https://run.linkerd.io/install | sh
```

Alternatively, you can download the CLI directly via the
[Linkerd releases page](https://github.com/linkerd/linkerd2/releases/).

Verify the CLI is installed and running correctly with:

```bash
linkerd version
```

Which should display something like:

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

You can check to make sure everything is healthy by running:

```bash
linkerd check
```

This will run through a set of checks against your control plane and make sure
that it is operating correctly.

To verify the Linkerd control plane version, run:

```bash
linkerd version
```

Which should now display the same versions:

```txt
Client version: {{% latestversion %}}
Server version: {{% latestversion %}}
```

### Notes

- During the upgrade, you will lose the historical data from Prometheus.
  Linkerd's Prometheus installation is not intended as a persistent store.
  Please see the [Prometheus export
  documentation](/2/observability/prometheus/#exporting-metrics) for more.

## Upgrade the data plane

Finally, with a fully up-to-date CLI running locally and Linkerd control plane
running on your Kubernetes cluster, it is time to upgrade the data plane. This
will change the version of the `linkerd-proxy` sidecar container and run a
rolling deploy on your service.

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

Congratulations! You have a fresh new Linkerd installation.

