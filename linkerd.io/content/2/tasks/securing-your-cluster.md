+++
title = "Securing Your Cluster"
description = "Best practices for securing your Linkerd installation."
+++

Linkerd provides powerful introspection into your Kubernetes cluster and
services. Linkerd installations are secure by default. This page illustrates
best practices to enable this introspection in a secure way.

## Tap

The default Linkerd installation includes Tap support. This feature is available
via the following commands:

- [`linkerd tap`](../../reference/cli/tap/)
- [`linkerd top`](../../reference/cli/top/)
- [`linkerd profile --tap`](../../reference/cli/profile/)
- [`linkerd dashboard`](../../reference/cli/dashboard/)

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

You can also use the Linkerd CLI's `--as` flag to confirm:

```bash
$ linkerd tap -n linkerd deploy/linkerd-controller --as $(whoami)
Error: HTTP error, status Code [403] (deployments.tap.linkerd.io "linkerd-controller" is forbidden: User "siggy" cannot watch resource "deployments/tap" in API group "tap.linkerd.io" in the namespace "linkerd")
...
```

### Enabling Tap access

If the above commands indicate you need additional access, you can enable access
with as much granularity as you choose.

#### Granular Tap access

To enable tap access to all resources in all namespaces, you may bind your user
to the `linkerd-linkerd-tap-admin` ClusterRole, installed by default:

```bash
$ kubectl describe clusterroles/linkerd-linkerd-tap-admin
Name:         linkerd-linkerd-tap-admin
Labels:       linkerd.io/control-plane-component=tap
              linkerd.io/control-plane-ns=linkerd
Annotations:  kubectl.kubernetes.io/last-applied-configuration:
                {"apiVersion":"rbac.authorization.k8s.io/v1","kind":"ClusterRole","metadata":{"annotations":{},"labels":{"linkerd.io/control-plane-compone...
PolicyRule:
  Resources         Non-Resource URLs  Resource Names  Verbs
  ---------         -----------------  --------------  -----
  *.tap.linkerd.io  []                 []              [watch]
```

{{< note >}}
This ClusterRole name includes the Linkerd namespace, so it may vary if you
installed Linkerd into a non-default namespace:
`linkerd-[LINKERD_NAMESPACE]-tap-admin`
{{< /note >}}

To bind the `linkerd-linkerd-tap-admin` ClusterRole to a particular user:

```bash
kubectl create clusterrolebinding \
  $(whoami)-tap-admin \
  --clusterrole=linkerd-linkerd-tap-admin \
  --user=$(whoami)
```

You can verify you now have tap access with:

```bash
$ linkerd tap -n linkerd deploy/linkerd-controller --as $(whoami)
req id=3:0 proxy=in  src=10.244.0.1:37392 dst=10.244.0.13:9996 tls=not_provided_by_remote :method=GET :authority=10.244.0.13:9996 :path=/ping
...
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
kubectl create clusterrolebinding \
  $(whoami)-tap-admin \
  --clusterrole=linkerd-linkerd-tap-admin \
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

### Linkerd Dashboard tap access

By default, the [Linkerd dashboard](../../features/dashboard/) has the RBAC
privileges necessary to tap resources.

To confirm:

```bash
$ kubectl auth can-i watch pods.tap.linkerd.io --all-namespaces --as system:serviceaccount:linkerd:linkerd-web
yes
```

This access is enabled via a `linkerd-linkerd-web-admin` ClusterRoleBinding:

```bash
$ kubectl describe clusterrolebindings/linkerd-linkerd-web-admin
Name:         linkerd-linkerd-web-admin
Labels:       linkerd.io/control-plane-component=web
              linkerd.io/control-plane-ns=linkerd
Annotations:  kubectl.kubernetes.io/last-applied-configuration:
                {"apiVersion":"rbac.authorization.k8s.io/v1","kind":"ClusterRoleBinding","metadata":{"annotations":{},"labels":{"linkerd.io/control-plane-...
Role:
  Kind:  ClusterRole
  Name:  linkerd-linkerd-tap-admin
Subjects:
  Kind            Name         Namespace
  ----            ----         ---------
  ServiceAccount  linkerd-web  linkerd
```

If you would like to restrict the Linkerd dashboard's tap access. You may
install Linkerd with the `--restrict-dashboard-privileges` flag:

```bash
linkerd install --restrict-dashboard-privileges
```

This will omit the `linkerd-linkerd-web-admin` ClusterRoleBinding. If you have
already installed Linkerd, you may simply delete the ClusterRoleBinding
manually:

```bash
kubectl delete clusterrolebindings/linkerd-linkerd-web-admin
```

To confirm:

```bash
$ kubectl auth can-i watch pods.tap.linkerd.io --all-namespaces --as system:serviceaccount:linkerd:linkerd-web
no
```
