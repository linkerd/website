+++
title = "Using Extensions"
description = "Add functionality with extensions."
+++

Linkerd extensions are components which can be added to a Linkerd
installation to enable addition functionality.  By default, the following
extensions are available:

* [Viz](/getting-started/): Metrics and visibility features
* [Jaeger](/2.10/tasks/distributed-tracing/): Distributed tracing
* [Multicluster](/2.10/tasks/multicluster/): Cross-cluster routing

A Linkerd extension is made up of two parts: a CLI whose name must begin with
`linkerd-` and a set of Kubernetes resources created by that CLI.  Every
extension must create a Kubernetes namespace with the `linkerd.io/extension`
label.  You can list all extensions installed on your cluster by running:

```bash
kubectl get ns -l linkerd.io/extension
```

## Installing Extensions

Before installing any extensions, make sure that you have already
[installed Linkerd](/2.10/tasks/install/).  Validate your install by running:

```bash
linkerd check
```

The first step to installing an extension is to download the extension's CLI
onto your local machine and put it on your path.  You can skip this step for
the `viz`, `jaeger`, and `multicluster` extensions since
they come bundled with the Linkerd CLI.  

This will allow you to invoke the extension CLI through the Linkerd CLI.  For
example, running `linkerd foo` will execute `linkerd-foo` if it is found on your
path.  To install the extension into your cluster, use the extension's install
command:

```bash
linkerd foo install | kubectl apply -f -
```

Extensions can also be installed by with Helm by installing that extension's
Helm chart.

Once the extension is installed, run `linkerd check` to ensure Linkerd and all
installed extensions are healthy or run `linkerd foo check` to perform health
checks for that extension only.

## Upgrading Extensions

Unless otherwise stated, extensions do not persist any configuration in the
cluster.  To upgrade an extension, run the install again with a newer version
of the extension CLI or with a different set of configuration flags.

## Uninstalling Extensions

All extensions have an `uninstall` command that should be used to gracefully
clean up all resources owned by an extension.  For example, to uninstall the
foo extension run:

```bash
linkerd foo uninstall | k delete -f -
```
