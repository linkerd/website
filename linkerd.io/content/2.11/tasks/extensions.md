+++
title = "Using extensions"
description = "Add functionality to Linkerd with optional extensions."
+++

Linkerd extensions are components which can be added to a Linkerd installation
to enable additional functionality. By default, the following extensions are
available:

* [viz](../../features/dashboard/): Metrics and visibility features
* [jaeger](../distributed-tracing/): Distributed tracing
* [multicluster](../multicluster/): Cross-cluster routing

But other extensions are also possible. Read on for more!

## Installing extensions

Before installing any extensions, make sure that you have already [installed
Linkerd](../install/) and validated your cluster with `linkerd check`.

Then, you can install the extension with the extension's `install` command. For
example, to install the `viz` extension, you can use:

```bash
linkerd viz install | kubectl apply -f -
```

For built-in extensions, such as `viz`, `jaeger`, and `multicluster`, that's
all you need to do. Of course, these extensions can also be installed by with
Helm by installing that extension's Helm chart.

Once an extension has been installed, it will be included as part of the
standard `linkerd check` command.

## Installing third-party extensions

Third-party extensions require one additional step: you must download the
extension's CLI and put it in your path. This will allow you to invoke the
extension CLI through the Linkerd CLI. (E.g. any call to `linkerd foo` will
automatically call the `linkerd-foo` binary, if it is found on your path.)

## Listing extensions

Every extension creates a Kubernetes namespace with the `linkerd.io/extension`
label. Thus, you can list all extensions installed on your cluster by running:

```bash
kubectl get ns -l linkerd.io/extension
```

## Upgrading extensions

Unless otherwise stated, extensions do not persist any configuration in the
cluster.  To upgrade an extension, run the install again with a newer version
of the extension CLI or with a different set of configuration flags.

## Uninstalling extensions

All extensions have an `uninstall` command that should be used to gracefully
clean up all resources owned by an extension.  For example, to uninstall the
foo extension, run:

```bash
linkerd foo uninstall | kubectl delete -f -
```
