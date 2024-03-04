+++
description = 'Linkerd can be easily removed from a Kubernetes cluster.'
title = 'Uninstalling Linkerd'

[runme]
id = '01HR52AEA7B6TMBGTJDA4ZRJ5G'
version = 'v3'
+++

Removing Linkerd from a Kubernetes cluster requires a few steps: removing any
data plane proxies, removing all the extensions and then removing the core
control plane.

## Removing Linkerd data plane proxies

To remove the Linkerd data plane proxies, you should remove any [Linkerd proxy
injection annotations](../../features/proxy-injection/) and roll the deployments.
When Kubernetes recreates the pods, they will not have the Linkerd data plane
attached.

## Removing extensions

To remove any extension, call its `uninstall` subcommand and pipe it to `kubectl
delete -f -`. For the bundled extensions that means:

```bash {"id":"01HR52AEA7B6TMBGTJCZHG3KSV","name":"uninstall-viz"}
# To remove Linkerd Viz
linkerd viz uninstall | kubectl delete -f -

# To remove Linkerd Jaeger
linkerd jaeger uninstall | kubectl delete -f -

# To remove Linkerd Multicluster
linkerd multicluster uninstall | kubectl delete -f -
```

## Removing the control plane

{{< note >}}
Uninstallating the control plane requires cluster-wide permissions.
{{< /note >}}

To remove the [control plane](../../reference/architecture/#control-plane), run:

```bash {"id":"01HR52AEA7B6TMBGTJD21WAX0B","name":"kubectl-get"}
kubectl get -n emojivoto deploy -o yaml \
  | linkerd uninject - \
  | kubectl apply -f -
```

```bash {"id":"01HR52AEA7B6TMBGTJD5NMQX4J"}
curl --proto https --tlsv1.2 -sSfL https://run.linkerd.io/emojivoto.yml \
  | kubectl delete -f -
```

```bash {"id":"01HR52AEA7B6TMBGTJD98NE3H3"}
linkerd uninstall | kubectl delete -f -
```

The `linkerd uninstall` command outputs the manifest for all of the Kubernetes
resources necessary for the control plane, including namespaces, service
accounts, CRDs, and more; `kubectl delete` then deletes those resources.

This command can also be used to remove control planes that have been partially
installed. Note that `kubectl delete` will complain about any resources that it
was asked to delete that hadn't been created, but these errors can be safely
ignored.
