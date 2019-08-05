+++
title = "Securing Your Cluster"
description = "RBAC best practices for your Linkerd installation."
+++

Linkerd provides powerful introspection into your Kubernetes cluster and
services. Linkerd installations are secure by default. This page illustrates
best practices to enable this introspection in a secure way.

## Tap

{{< note >}}
This section is only relevant to users of edge-19.8.1 and later.
{{< /note >}}

The default Linkerd installation includes Tap support. This feature is available
via the following commands:

- [`linkerd tap`](/2/reference/cli/tap/)
- [`linkerd top`](/2/reference/cli/top/)
- [`linkerd profile --tap`](/2/reference/cli/profile/)
- [`linkerd dashboard`](/2/reference/cli/dashboard/)

Depending on your RBAC setup, you may need to perform additional steps to enable
your user(s) to perform Tap actions.

{{< note >}}
If you are on GKE, skip to the [GKE section below](#gke).
{{< /note >}}

### Check for Tap access

Use `kubectl` to determine whether your user is authorized to perform tap
actions. For more information, see the
[Kubernetes docs on authorization](https://kubernetes.io/docs/reference/access-authn-authz/authorization/#checking-api-access).

To determine if you can watch pods in all namespaces:

```bash
kubectl auth can-i watch pods.tap.linkerd.io --all-namespaces
```

To determine if you can watch deployments in the emojivoto namespace:

```bash
kubectl auth can-i watch deployments.tap.linkerd.io -n emojivoto
```

To determine if a specific user can watch deployments in the emojivoto namespace:

```bash
kubectl auth can-i watch deployments.tap.linkerd.io -n emojivoto --as $(whoami)
```

### Enabling Tap access

If the above commands indicate you need additional access, you can enable access
with as much granularity as you choose.

#### Granular Tap access

To enable tap access to all resources in all namespaces, first create a
ClusterRole enabling that access. In this example we create a `tap-admin`
ClusterRole:

```bash
kubectl create clusterrole tap-admin --verb watch --resource=*.tap.linkerd.io
```

Then bind that `tap-admin` ClusterRole to a particular user:

```bash
kubectl create clusterrolebinding \
  $(whoami)-tap-admin \
  --clusterrole=tap-admin \
  --user=$(whoami)
```

#### Cluster admin access

To simply give your user cluster-admin access:

```bash
kubectl create clusterrolebinding \
  $(whoami)-cluster-admin \
  --clusterrole=cluster-admin \
  --user=$(whoami)
```

{{< note >}}
Not recommended for production, only do this for testing/development.
{{< /note >}}

### GKE

Google Kubernetes Engine (GKE) provides access to your Kubernetes cluster via
Google Cloud IAM. See the
[GKE IAM Docs](https://cloud.google.com/kubernetes-engine/docs/how-to/iam) for
more information.

Because GCloud provides this additional level of access, there are cases where
`kubectl auth can-i` will report you have Tap access when your RBAC user may
not. To validate this, check whether your GCloud user has Tap access:

```bash
$ kubectl auth can-i watch pods.tap.linkerd.io --all-namespaces
yes
```

And then validate whether your RBAC user has Tap access:

```bash
$ kubectl auth can-i watch pods.tap.linkerd.io --all-namespaces --as $(gcloud config get-value account)
no - no RBAC policy matched
```

If the second command reported you do not have access, you may enable access
with:

```bash
kubectl create clusterrole tap-admin --verb watch --resource=*.tap.linkerd.io
kubectl create clusterrolebinding \
  $(whoami)-tap-admin \
  --clusterrole=tap-admin \
  --user=$(gcloud config get-value account)
```

To simply give your user cluster-admin access:

```bash
kubectl create clusterrolebinding \
  $(whoami)-cluster-admin \
  --clusterrole=cluster-admin \
  --user=$(gcloud config get-value account)
```

{{< note >}}
Not recommended for production, only do this for testing/development.
{{< /note >}}
