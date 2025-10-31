---
title: Upgrading Multi-cluster components
description:
  Upgrade the Linkerd components that manage cross-cluster communication.
---

In this guide, we'll walk you through how to perform upgrades for Linkerd
multi-cluster and migrate to the new GitOps-compatible multi-cluster links
introduced in `edge-25.3.3`.

## Update the Helm values

In your Helm values, update the `controllers` section to list the links you want
to migrate and specify any per-controller configuration. This will deploy a new
controller for each link (named `controller-<link-name>`), while leaving the old
controllers (named `linkerd-service-mirror-<link-name>`) in place. For example:

```yaml
controllers:
  - link:
      ref:
        name: east
```

## Upgrade the Multicluster extension

Next upgrade the multi-cluster extension, providing the `values.yaml` file:

### Upgrading with the CLI

```bash
linkerd multicluster install -f values.yaml | \
  kubectl apply -f -
```

### Upgrading via Helm

```bash
helm upgrade linkerd-multicluster \
  --namespace linkerd-multicluster \
  --values values.yaml \
  linkerd-buoyant/linkerd-enterprise-multicluster
```

## Remove the old controllers

After the multi-cluster extension has been upgraded, the new controllers won’t
take over immediately because the old controllers still hold the Lease object
for each Link. To fully migrate to the new model, you will need to delete the
old controller deployments using the following command:

```bash
linkerd multicluster unlink --cluster-name <link-name> --only-controller | \
  kubectl delete -f -
```

Within a few seconds, the new controllers will reclaim the Lease object and
begin managing their respective links.

{{< note >}}The `linkerd multicluster check` command will warn you about any
controllers that aren’t managed by the extension.{{< /note >}}
