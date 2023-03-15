+++
title = "Adding Your Services to Linkerd"
description = "In order for your services to take advantage of Linkerd, they also need to be *meshed* by injecting Linkerd's data plane proxy into their pods."
aliases = [
  "../adding-your-service/",
  "../automating-injection/"
]
+++

Adding Linkerd's control plane to your cluster doesn't change anything about
your application. In order for your services to take advantage of Linkerd, they
need to be *meshed*, by injecting Linkerd's data plane proxy into their pods.

For most applications, meshing a service is as simple as adding a Kubernetes
annotation. However, services that make network calls immediately on startup
may need to [handle startup race
conditions](#a-note-on-startup-race-conditions), and services that use MySQL,
SMTP, Memcache, and similar protocols may need to [handle server-speaks-first
protocols](#a-note-on-server-speaks-first-protocols).

Read on for more!

## Meshing a service with annotations

Meshing a Kubernetes resource is typically done by annotating the resource, or
its namespace, with the `linkerd.io/inject: enabled` Kubernetes annotation.
This annotation triggers automatic proxy injection when the resources are
created or updated. (See the [proxy injection
page](../../features/proxy-injection/) for more on how this works.)

For convenience, Linkerd provides a [`linkerd
inject`](../../reference/cli/inject/) text transform command will add this
annotation to a given Kubernetes manifest.  Of course, these annotations can be
set by any other mechanism.

{{< note >}}
Simply adding the annotation will not automatically mesh existing pods. After
setting the annotation, you will need to recreate or update any resources (e.g.
with `kubectl rollout restart`) to trigger proxy injection. (Often, a
[rolling
update](https://kubernetes.io/docs/tutorials/kubernetes-basics/update/update-intro/)
can be performed to inject the proxy into a live service without interruption.)
{{< /note >}}

## Example

To add Linkerd's data plane proxies to a service defined in a Kubernetes
manifest, you can use `linkerd inject` to add the annotations before applying
the manifest to Kubernetes:

```bash
cat deployment.yml | linkerd inject - | kubectl apply -f -
```

This example transforms the `deployment.yml` file to add injection annotations
in the correct places, then applies it to the cluster.

## Verifying the data plane pods have been injected

To verify that your services have been added to the mesh, you can query
Kubernetes for the list of containers in the pods and ensure that the proxy is
listed:

```bash
kubectl -n MYNAMESPACE get po -o jsonpath='{.items[0].spec.containers[*].name}'
```

If everything was successful, you'll see `linkerd-proxy` in the output, e.g.:

```bash
MYCONTAINER linkerd-proxy
```

## A note on startup race conditions

While the proxy starts very quickly, Kubernetes doesn't provide any guarantees
about container startup ordering, so the application container may start before
the proxy is ready. This means that any connections made immediately at app
startup time may fail until the proxy is active.

In many cases, this can be ignored: the application will ideally retry the
connection, or Kubernetes will restart the container after it fails, and
eventually the proxy will be ready. Alternatively, you can use
[linkerd-await](https://github.com/linkerd/linkerd-await) to delay the
application container until the proxy is ready, or set a
[`skip-outbound-ports`
annotation](../../features/protocol-detection/#skipping-the-proxy)
to bypass the proxy for these connections.

## A note on server-speaks-first protocols

Linkerd's [protocol
detection](../../features/protocol-detection/) works by
looking at the first few bytes of client data to determine the protocol of the
connection. Some protocols such as MySQL, SMTP, and other server-speaks-first
protocols don't send these bytes. In some cases, this may require additional
configuration to avoid a 10-second delay in establishing the first connection.
See [Configuring protocol
detection](../../features/protocol-detection/#configuring-protocol-detection)
for details.

## More reading

For more information on how the inject command works and all of the parameters
that can be set, see the [`linkerd inject` reference
page](../../reference/cli/inject/).

For details on how autoinjection works, see the [proxy injection
page](../../features/proxy-injection/).
