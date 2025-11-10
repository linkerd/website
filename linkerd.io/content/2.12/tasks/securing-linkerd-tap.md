---
title: Securing Linkerd Tap
description: Best practices for securing Linkerd's tap feature.
---

Linkerd provides a powerful tool called `tap` which allows users to introspect
live traffic in real time. While powerful, this feature can expose sensitive
data such as request and response headers. Access to `tap` is controlled using
[role-based access control (RBAC)](https://kubernetes.io/docs/reference/access-authn-authz/rbac/).
This page illustrates best practices to enable this introspection in a secure
way.

## Tap

Linkerd's Viz extension includes Tap support. This feature is available via the
following commands:

- [`linkerd viz tap`](../reference/cli/viz/#tap)
- [`linkerd viz top`](../reference/cli/viz/#top)
- [`linkerd viz profile --tap`](../reference/cli/viz/#profile)
- [`linkerd viz dashboard`](../reference/cli/viz/#dashboard)

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

To determine if a specific user can watch deployments in the emojivoto
namespace:

```bash
kubectl auth can-i watch deployments.tap.linkerd.io -n emojivoto --as $(whoami)
```

You can also use the Linkerd CLI's `--as` flag to confirm:

```bash
$ linkerd viz tap -n linkerd deploy/linkerd-controller --as $(whoami)
Cannot connect to Linkerd Viz: namespaces is forbidden: User "XXXX" cannot list resource "namespaces" in API group "" at the cluster scope
Validate the install with: linkerd viz check
...
```

### Enabling Tap access

If the above commands indicate you need additional access, you can enable access
with as much granularity as you choose.

#### Granular Tap access

To enable tap access to all resources in all namespaces, you may bind your user
to the `linkerd-linkerd-tap-admin` ClusterRole, installed by default:

```bash
$ kubectl describe clusterroles/linkerd-linkerd-viz-tap-admin
Name:         linkerd-linkerd-viz-tap-admin
Labels:       component=tap
              linkerd.io/extension=viz
Annotations:  kubectl.kubernetes.io/last-applied-configuration:
                {"apiVersion":"rbac.authorization.k8s.io/v1","kind":"ClusterRole","metadata":{"annotations":{},"labels":{"component=tap...
PolicyRule:
  Resources         Non-Resource URLs  Resource Names  Verbs
  ---------         -----------------  --------------  -----
  *.tap.linkerd.io  []                 []              [watch]
```

{{< note >}}

This ClusterRole name includes the Linkerd Viz namespace, so it may vary if you
installed Viz into a non-default namespace:
`linkerd-[LINKERD_VIZ_NAMESPACE]-tap-admin`

{{< /note >}}

To bind the `linkerd-linkerd-viz-tap-admin` ClusterRole to a particular user:

```bash
kubectl create clusterrolebinding \
  $(whoami)-tap-admin \
  --clusterrole=linkerd-linkerd-viz-tap-admin \
  --user=$(whoami)
```

You can verify you now have tap access with:

```bash
$ linkerd viz tap -n linkerd deploy/linkerd-controller --as $(whoami)
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
  --clusterrole=linkerd-linkerd-viz-tap-admin \
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

By default, the [Linkerd dashboard](../features/dashboard/) has the RBAC
privileges necessary to tap resources.

To confirm:

```bash
$ kubectl auth can-i watch pods.tap.linkerd.io --all-namespaces --as system:serviceaccount:linkerd-viz:web
yes
```

This access is enabled via a `linkerd-linkerd-viz-web-admin` ClusterRoleBinding:

```bash
$ kubectl describe clusterrolebindings/linkerd-linkerd-viz-web-admin
Name:         linkerd-linkerd-viz-web-admin
Labels:       component=web
              linkerd.io/extensions=viz
Annotations:  kubectl.kubernetes.io/last-applied-configuration:
                {"apiVersion":"rbac.authorization.k8s.io/v1","kind":"ClusterRoleBinding","metadata":{"annotations":{},"labels":{"component=web...
Role:
  Kind:  ClusterRole
  Name:  linkerd-linkerd-viz-tap-admin
Subjects:
  Kind            Name         Namespace
  ----            ----         ---------
  ServiceAccount  web          linkerd-viz
```

If you would like to restrict the Linkerd dashboard's tap access. You may
install Linkerd viz with the `--set dashboard.restrictPrivileges` flag:

```bash
linkerd viz install --set dashboard.restrictPrivileges
```

This will omit the `linkerd-linkerd-web-admin` ClusterRoleBinding. If you have
already installed Linkerd, you may simply delete the ClusterRoleBinding
manually:

```bash
kubectl delete clusterrolebindings/linkerd-linkerd-viz-web-admin
```

To confirm:

```bash
$ kubectl auth can-i watch pods.tap.linkerd.io --all-namespaces --as system:serviceaccount:linkerd-viz:web
no
```
