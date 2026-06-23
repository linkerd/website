---
title: Customizing Linkerd's Configuration with Kustomize
description:
  Use Kustomize to modify Linkerd's configuration in a programmatic way.
---

Instead of forking the Linkerd install and upgrade process,
[Kustomize](https://kustomize.io/) can be used to patch the output of
`linkerd install` in a consistent way. This allows customization of the install
to add functionality specific to installations.

{{< docs/production-note >}}

To get started, save the output of `linkerd install` to a YAML file. This will
be the base resource that Kustomize uses to patch and generate what is added to
your cluster.

```bash
linkerd install > linkerd.yaml
```

{{< note >}}

When upgrading, make sure you populate this file with the content from
`linkerd upgrade`. Using the latest `kustomize` releases, it would be possible
to automate this with an
[exec plugin](https://github.com/kubernetes-sigs/kustomize/tree/master/docs/plugins#exec-plugins).

{{< /note >}}

Next, create a `kustomization.yaml` file. This file will contain the
instructions for Kustomize listing the base resources and the transformations to
do on those resources. Right now, this looks pretty empty:

```yaml
resources:
  - linkerd.yaml
```

Now, let's look at how to do some example customizations.

{{< note >}}

Kustomize allows as many patches, transforms and generators as you'd like. These
examples show modifications one at a time but it is possible to do as many as
required in a single `kustomization.yaml` file.

{{< /note >}}

## Add PriorityClass

There are a couple components in the control plane that can benefit from being
associated with a critical `PriorityClass`. While this configuration isn't
currently supported as a flag to `linkerd install`, it is not hard to add by
using Kustomize.

First, create a file named `priority-class.yaml` that will create define a
`PriorityClass` resource.

```yaml
apiVersion: scheduling.k8s.io/v1
description:
  Used for critical linkerd pods that must run in the cluster, but can be moved
  to another node if necessary.
kind: PriorityClass
metadata:
  name: linkerd-critical
value: 1000000000
```

{{< note >}}

`1000000000` is the max. allowed user-defined priority, adjust accordingly.

{{< /note >}}

Next, create a file named `patch-priority-class.yaml` that will contain the
overlay. This overlay will explain what needs to be modified.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: linkerd-identity
  namespace: linkerd
spec:
  template:
    spec:
      priorityClassName: linkerd-critical
```

Then, add this as a strategic merge option to `kustomization.yaml`:

```yaml
resources:
  - priority-class.yaml
  - linkerd.yaml
patchesStrategicMerge:
  - patch-priority-class.yaml
```

Applying this to your cluster requires taking the output of `kustomize` and
piping it to `kubectl apply`. For example, you can run:

```bash
# install the Linkerd CRDs
linkerd install --crds | kubectl apply -f -

# install the Linkerd control plane manifests using Kustomize
kubectl kustomize . | kubectl apply -f -
```
