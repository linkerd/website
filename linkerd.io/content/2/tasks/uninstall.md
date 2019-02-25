+++
title = "Uninstalling Linkerd"
description = "Uninstall Linkerd from your own Kubernetes cluster."
+++

If you'd like to remove Linkerd from your cluster, you'll first want to remove
any of your services from the
[data plane](/2/reference/architecture/#data-plane). This can be done by running:

```bash
kubectl get --all-namespaces daemonset,deploy,job,statefulset \
    -l "linkerd.io/control-plane-ns" -o yaml \
  | linkerd uninject - \
  | kubectl apply -f -
```

This will fetch everything that has the Linkerd proxy sidecar, remove the
sidecar and re-apply to your cluster.

Then, to remove the [control plane](/2/reference/architecture/#control-plane),
run:

```bash
linkerd install | kubectl delete -f -
```

The `linkerd install` command outputs the YAML definitions for all of the
Kubernetes resources necessary for the control plane, including namespaces,
service accounts, CRDs, and more; `kubectl delete` then deletes those resources.

{{< note >}}
This command also removes control planes that have been only partially
installed.
{{< /note >}}
