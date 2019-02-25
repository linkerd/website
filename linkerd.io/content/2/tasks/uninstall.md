+++
title = "Uninstalling Linkerd"
description = "Uninstall the Linkerd control plane from your Kubernetes cluster."
+++

If you'd like to uninstall an [existing Linkerd control plane](../install) on [Kubernetes](https://kubernetes.io), you can do so with one command:

```bash
linkerd install | kubectl delete -f -
```

The `linkerd install` command outputs the YAML definitions for all of the Kubernetes resources necessary for the control plane, including namespaces, service accounts, CRDs, and more; `kubectl delete` deletes those resources.

{{< note >}}
This command also uninstalls control planes that have been only partially installed.
{{< /note >}}