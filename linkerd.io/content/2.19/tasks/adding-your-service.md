---
title: Adding your services to Linkerd
description: In order for your services to take advantage of Linkerd, they also need
  to be meshed by injecting Linkerd's data plane proxy into their pods.
---

Adding Linkerd's control plane to your cluster doesn't change anything about
your application. In order for your services to take advantage of Linkerd, they
need to be *meshed*, by injecting Linkerd's data plane proxy into their pods.

For most applications, meshing a service is as simple as adding a Kubernetes
annotation and restarting the service. However, services that communicate using
certain non-HTTP protocols (including MySQL, SMTP, Memcache, and others) may
need a little configuration.

Read on for more!

## Meshing a service with annotations

Meshing a Kubernetes resource is typically done by annotating the resource (or
its namespace) with the `linkerd.io/inject: enabled` Kubernetes annotation.
This annotation triggers automatic proxy injection when the resources are
created or updated. (See the [proxy injection
page](../features/proxy-injection/) for more on how this works.)

For convenience, Linkerd provides a [`linkerd
inject`](../reference/cli/inject/) text transform command will add this
annotation to a given Kubernetes manifest.  Of course, these annotations can be
set by any other mechanism.

{{< note >}}
Adding the annotation to existing pods does not automatically mesh them. For
existing pods, after adding the annotation you will also need to recreate or
update the resource (e.g. by using `kubectl rollout restart` to perform a
[rolling
update](https://kubernetes.io/docs/tutorials/kubernetes-basics/update/update-intro/))
to trigger proxy injection.
{{< /note >}}

## Examples

To add Linkerd's data plane proxies to a service defined in a Kubernetes
manifest, you can use `linkerd inject` to add the annotations before applying
the manifest to Kubernetes.

You can transform an existing `deployment.yml` file to add annotations
in the correct places and apply it to the cluster:

```bash
cat deployment.yml | linkerd inject - | kubectl apply -f -
```

You can mesh every deployment in a namespace by combining this
with `kubectl get`:

```bash
kubectl get -n NAMESPACE deploy -o yaml | linkerd inject - | kubectl apply -f -
```

## Verifying the data plane pods have been injected

To verify that your services have been added to the mesh, you can query
Kubernetes for the list of containers in the pods and ensure that the proxy is
listed:

```bash
kubectl -n NAMESPACE get po -o jsonpath='{.items[0].spec.containers[*].name}'
```

If everything was successful, you'll see `linkerd-proxy` in the output, e.g.:

```bash
linkerd-proxy CONTAINER
```

## Handling MySQL, SMTP, and other non-HTTP protocols

Linkerd's [protocol detection](../features/protocol-detection/) works by
looking at the first few bytes of client data to determine the protocol of the
connection. Some protocols, such as MySQL and SMTP, don't send these bytes.  If
your application uses these protocols without TLSing them, you may require
additional configuration to avoid a 10-second delay when establishing
connections.

See [Configuring protocol
detection](../features/protocol-detection/#configuring-protocol-detection)
for details.

## More reading

For more information on how the inject command works and all of the parameters
that can be set, see the [`linkerd inject` reference
page](../reference/cli/inject/).

For details on how autoinjection works, see the [proxy injection
page](../features/proxy-injection/).
