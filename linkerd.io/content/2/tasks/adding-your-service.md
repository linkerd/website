+++
title = "Adding Your Service"
description = "Add your service to the mesh by marking it for data plane proxy injection."
aliases = [
  "/2/adding-your-service/"
]
+++

In order for your services to take advantage of Linkerd, they need to have
Linkerd's data plane proxy added to their pods. This is typically done by
annotating the namespace, deployment, or pod with the `linkerd/inject: true`
Kubernetes annotation, which will trigger *automatic proxy injection* when the
resources are created. (See the [proxy injection
page](/2/features/proxy-injection.md) for more on how this works.)

For convenience, Linkerd provides a [`linkerd
inject`](/2/reference/cli/inject/) text transform command will add this
annotation to a given Kubernetes manifest. Of course, these annotations can be
set by other mechanisms.

(Note that simply adding the annotation will not automatically inject the data
plane proxy into pods that are already running. You will need to update the
pods to trigger injection. With a [rolling
update](https://kubernetes.io/docs/tutorials/kubernetes-basics/update/update-intro/),
the proxy often can be added to a live service without interruption.)

## Example

To add the data plane proxies to a service defined in a Kubernetes manifest,
you can use `linkerd inject` to add the annotations before applying the manifest
to Kubernetes:

```bash
cat deployment.yml | linkerd inject - | kubectl apply -f -
```

This example transforms the `deployment.yml` file to add injection annotations
in the correct places, then applies it to the cluster.

## Verifying the data plane pods have been injected

Once your services have been added to the mesh, you will be able to query
Linkerd for traffic metrics about them, e.g. by using [`linkerd
stat`](/2/reference/cli/stat/):

```bash
linkerd stat deployments -n MYNAMESPACE
```

Note that it may take several seconds for these metrics to appear once the data
plane proxies have been injected.

Alternatively, you can query Kubernetes for the list of containers in the pods,
and ensure that the proxy is listed:

```bash
kubectl -n MYNAMESPACE get po -o jsonpath='{.items[0].spec.containers[*].name}'
```

If everything was successful, you'll see `linkerd-proxy` in the output, e.g.:

```bash
MYCONTAINER linkerd-proxy
```

Finally, you can verify that everything is working by verifying that the
corresponding resources are reported to be meshed in the "Meshed" column of the
[Linkerd dashboard](/2/features/dashboard).

{{< fig src="/images/getting-started/stat.png" title="Dashboard" >}}

## More reading

For more information on how the inject command works and all of the parameters
that can be set, see the [`linkerd inject` reference
page](/2/reference/cli/inject/).

For details on how autoinjection works, see the the [proxy injection
page](/2/features/proxy-injection.md).

