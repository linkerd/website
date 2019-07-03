+++
title = "Troubleshooting"
description = "Troubleshoot issues with your Linkerd installation."
+++

This section provides resolution steps for common problems reported with the
`linkerd check` command.

## The "pre-kubernetes-cluster-setup" checks {#pre-k8s-cluster}

These checks only run when the `--pre` flag is set. This flag is intended for
use prior to running `linkerd install`, to verify your cluster is prepared for
installation.

### √ control plane namespace does not already exist {#pre-ns}

Example failure:

```bash
× control plane namespace does not already exist
    The "linkerd" namespace already exists
```

By default `linkerd install` will create a `linkerd` namespace. Prior to
installation, that namespace should not exist. To check with a different
namespace, run:

```bash
linkerd check --pre --linkerd-namespace linkerd-test
```

### √ can create Kubernetes resources {#pre-k8s-cluster-k8s}

The subsequent checks in this section validate whether you have permission to
create the Kubernetes resources required for Linkerd installation, specifically:

```bash
√ can create Namespaces
√ can create ClusterRoles
√ can create ClusterRoleBindings
√ can create CustomResourceDefinitions
```

## The "pre-kubernetes-setup" checks {#pre-k8s}

These checks only run when the `--pre` flag is set This flag is intended for
use prior to running `linkerd install`, to verify you have the correct RBAC
permissions to install Linkerd.

```bash
√ can create Namespaces
√ can create ClusterRoles
√ can create ClusterRoleBindings
√ can create CustomResourceDefinitions
√ can create PodSecurityPolicies
√ can create ServiceAccounts
√ can create Services
√ can create Deployments
√ can create ConfigMaps
```

### √ no clock skew detected {#pre-k8s-clock-skew}

This check verifies whether there is clock skew between the system running
the `linkerd install` command and the Kubernetes node(s), causing
potential issues.

## The "pre-kubernetes-capability" checks {#pre-k8s-capability}

These checks only run when the `--pre` flag is set. This flag is intended for
use prior to running `linkerd install`, to verify you have the correct
Kubernetes capability permissions to install Linkerd.

### √ has NET_ADMIN capability {#pre-k8s-cluster-net-admin}

Example failure:

```bash
× has NET_ADMIN capability
    found 3 PodSecurityPolicies, but none provide NET_ADMIN
    see https://linkerd.io/checks/#pre-k8s-cluster-net-admin for hints
```

Linkerd installation requires the `NET_ADMIN` Kubernetes capability, to allow
for modification of iptables.

For more information, see the Kubernetes documentation on
[Pod Security Policies](https://kubernetes.io/docs/concepts/policy/pod-security-policy/),
[Security Contexts](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/),
and the [man page on Linux Capabilities](http://man7.org/linux/man-pages/man7/capabilities.7.html).

## The "pre-linkerd-global-resources" checks {#pre-l5d-existence}

These checks only run when the `--pre` flag is set. This flag is intended for
use prior to running `linkerd install`, to verify you have not already installed
the Linkerd control plane.

```bash
√ no ClusterRoles exist
√ no ClusterRoleBindings exist
√ no CustomResourceDefinitions exist
√ no MutatingWebhookConfigurations exist
√ no ValidatingWebhookConfigurations exist
√ no PodSecurityPolicies exist
```

## The "pre-kubernetes-single-namespace-setup" checks {#pre-single}

If you do not expect to have the permission for a full cluster install, try the
`--single-namespace` flag, which validates if Linkerd can be installed in a
single namespace, with limited cluster access:

```bash
linkerd check --pre --single-namespace
```

### √ control plane namespace exists {#pre-single-ns}

```bash
× control plane namespace exists
    The "linkerd" namespace does not exist
```

In `--single-namespace` mode, `linkerd check` assumes that the installer does
not have permission to create a namespace, so the installation namespace must
already exist.

By default the `linkerd` namespace is used. To use a different namespace run:

```bash
linkerd check --pre --single-namespace --linkerd-namespace linkerd-test
```

### √ can create Kubernetes resources {#pre-single-k8s}

The subsequent checks in this section validate whether you have permission to
create the Kubernetes resources required for Linkerd `--single-namespace`
installation, specifically:

```bash
√ can create Roles
√ can create RoleBindings
```

For more information on cluster access, see the
[GKE Setup](/2/tasks/install/#gke) section above.

## The "kubernetes-api" checks {#k8s-api}

Example failures:

```bash
× can initialize the client
    error configuring Kubernetes API client: stat badconfig: no such file or directory
× can query the Kubernetes API
    Get https://8.8.8.8/version: dial tcp 8.8.8.8:443: i/o timeout
```

Ensure that your system is configured to connect to a Kubernetes cluster.
Validate that the `KUBECONFIG` environment variable is set properly, and/or
`~/.kube/config` points to a valid cluster.

For more information see these pages in the Kubernetes Documentation:

- [Accessing Clusters](https://kubernetes.io/docs/tasks/access-application-cluster/access-cluster/)
- [Configure Access to Multiple Clusters](https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/)

Also verify that these command works:

```bash
kubectl config view
kubectl cluster-info
kubectl version
```

Another example failure:

```bash
✘ can query the Kubernetes API
    Get REDACTED/version: x509: certificate signed by unknown authority
```

As an (unsafe) workaround to this, you may try:

```bash
kubectl config set-cluster ${KUBE_CONTEXT} --insecure-skip-tls-verify=true \
    --server=${KUBE_CONTEXT}
```

## The "kubernetes-version" checks {#k8s-version}

### √ is running the minimum Kubernetes API version {#k8s-version-api}

Example failure:

```bash
× is running the minimum Kubernetes API version
    Kubernetes is on version [1.7.16], but version [1.12.0] or more recent is required
```

Linkerd requires at least version `1.12.0`. Verify your cluster version with:

```bash
kubectl version
```

### √ is running the minimum kubectl version {#kubectl-version}

Example failure:

```bash
× is running the minimum kubectl version
    kubectl is on version [1.9.1], but version [1.12.0] or more recent is required
    see https://linkerd.io/checks/#kubectl-version for hints
```

Linkerd requires at least version `1.12.0`. Verify your kubectl version with:

```bash
kubectl version --client --short
```

To fix please update kubectl version.

For more information on upgrading Kubernetes, see the page in the Kubernetes
Documentation on
[Upgrading a cluster](https://kubernetes.io/docs/tasks/administer-cluster/cluster-management/#upgrading-a-cluster)

## The "linkerd-config" checks {#l5d-config}

This category of checks validates that Linkerd's cluster-wide RBAC and related
resources have been installed. These checks run via a default `linkerd check`,
and also in the context of a multi-stage setup, for example:

```bash
# install cluster-wide resources (first stage)
linkerd install config | kubectl apply -f -

# validate successful cluster-wide resources installation
linkerd check config

# install Linkerd control plane
linkerd install control-plane | kubectl apply -f -

# validate successful control-plane installation
linkerd check
```

### √ control plane Namespace exists {#l5d-existence-ns}

Example failure:

```bash
× control plane Namespace exists
    The "foo" namespace does not exist
    see https://linkerd.io/checks/#l5d-existence-ns for hints
```

Ensure the Linkerd control plane namespace exists:

```bash
kubectl get ns
```

The default control plane namespace is `linkerd`. If you installed Linkerd into
a different namespace, specify that in your check command:

```bash
linkerd check --linkerd-namespace linkerdtest
```

### √ control plane ClusterRoles exist {#l5d-existence-cr}

Example failure:

```bash
× control plane ClusterRoles exist
    missing ClusterRoles: linkerd-linkerd-controller
    see https://linkerd.io/checks/#l5d-existence-cr for hints
```

Ensure the Linkerd ClusterRoles exist:

```bash
$ kubectl get clusterroles | grep linkerd
linkerd-linkerd-controller                                             9d
linkerd-linkerd-identity                                               9d
linkerd-linkerd-prometheus                                             9d
linkerd-linkerd-proxy-injector                                         20d
linkerd-linkerd-sp-validator                                           9d
```

Also ensure you have permission to create ClusterRoles:

```bash
$ kubectl auth can-i create clusterroles
yes
```

### √ control plane ClusterRoleBindings exist {#l5d-existence-crb}

Example failure:

```bash
× control plane ClusterRoleBindings exist
    missing ClusterRoleBindings: linkerd-linkerd-controller
    see https://linkerd.io/checks/#l5d-existence-crb for hints
```

Ensure the Linkerd ClusterRoleBindings exist:

```bash
$ kubectl get clusterrolebindings | grep linkerd
linkerd-linkerd-controller                             9d
linkerd-linkerd-identity                               9d
linkerd-linkerd-prometheus                             9d
linkerd-linkerd-proxy-injector                         20d
linkerd-linkerd-sp-validator                           9d
```

Also ensure you have permission to create ClusterRoleBindings:

```bash
$ kubectl auth can-i create clusterrolebindings
yes
```

### √ control plane ServiceAccounts exist {#l5d-existence-sa}

Example failure:

```bash
× control plane ServiceAccounts exist
    missing ServiceAccounts: linkerd-controller
    see https://linkerd.io/checks/#l5d-existence-sa for hints
```

Ensure the Linkerd ServiceAccounts exist:

```bash
$ kubectl -n linkerd get serviceaccounts
NAME                     SECRETS   AGE
default                  1         23m
linkerd-controller       1         23m
linkerd-grafana          1         23m
linkerd-identity         1         23m
linkerd-prometheus       1         23m
linkerd-proxy-injector   1         7m
linkerd-sp-validator     1         23m
linkerd-web              1         23m
```

Also ensure you have permission to create ServiceAccounts in the Linkerd
namespace:

```bash
$ kubectl -n linkerd auth can-i create serviceaccounts
yes
```

### √ control plane CustomResourceDefinitions exist {#l5d-existence-crd}

Example failure:

```bash
× control plane CustomResourceDefinitions exist
    missing CustomResourceDefinitions: serviceprofiles.linkerd.io
    see https://linkerd.io/checks/#l5d-existence-crd for hints
```

Ensure the Linkerd CRD exists:

```bash
$ kubectl get customresourcedefinitions
NAME                         CREATED AT
serviceprofiles.linkerd.io   2019-04-25T21:47:31Z
```

Also ensure you have permission to create CRDs:

```bash
$ kubectl auth can-i create customresourcedefinitions
yes
```

### √ control plane MutatingWebhookConfigurations exist {#l5d-existence-mwc}

Example failure:

```bash
× control plane MutatingWebhookConfigurations exist
    missing MutatingWebhookConfigurations: linkerd-proxy-injector-webhook-config
    see https://linkerd.io/checks/#l5d-existence-mwc for hints
```

Ensure the Linkerd MutatingWebhookConfigurations exists:

```bash
$ kubectl get mutatingwebhookconfigurations | grep linkerd
linkerd-proxy-injector-webhook-config   2019-07-01T13:13:26Z
```

Also ensure you have permission to create MutatingWebhookConfigurations:

```bash
$ kubectl auth can-i create mutatingwebhookconfigurations
yes
```

### √ control plane ValidatingWebhookConfigurations exist {#l5d-existence-vwc}

Example failure:

```bash
× control plane ValidatingWebhookConfigurations exist
    missing ValidatingWebhookConfigurations: linkerd-sp-validator-webhook-config
    see https://linkerd.io/checks/#l5d-existence-vwc for hints
```

Ensure the Linkerd ValidatingWebhookConfiguration exists:

```bash
$ kubectl get validatingwebhookconfigurations | grep linkerd
linkerd-sp-validator-webhook-config   2019-07-01T13:13:26Z
```

Also ensure you have permission to create ValidatingWebhookConfigurations:

```bash
$ kubectl auth can-i create validatingwebhookconfigurations
yes
```

### √ control plane PodSecurityPolicies exist {#l5d-existence-psp}

Example failure:

```bash
× control plane PodSecurityPolicies exist
    missing PodSecurityPolicies: linkerd-linkerd-control-plane
    see https://linkerd.io/checks/#l5d-existence-psp for hints
```

Ensure the Linkerd PodSecurityPolicy exists:

```bash
$ kubectl get podsecuritypolicies | grep linkerd
linkerd-linkerd-control-plane   false   NET_ADMIN,NET_RAW   RunAsAny   RunAsAny    MustRunAs   MustRunAs   true             configMap,emptyDir,secret,projected,downwardAPI,persistentVolumeClaim
```

Also ensure you have permission to create PodSecurityPolicies:

```bash
$ kubectl auth can-i create podsecuritypolicies
yes
```

## The "linkerd-existence" checks {#l5d-existence}

### √ 'linkerd-config' config map exists {#l5d-existence-linkerd-config}

Example failure:

```bash
× 'linkerd-config' config map exists
    missing ConfigMaps: linkerd-config
    see https://linkerd.io/checks/#l5d-existence-linkerd-config for hints
```

Ensure the Linkerd ConfigMap exists:

```bash
$ kubectl -n linkerd get configmap/linkerd-config
NAME             DATA   AGE
linkerd-config   3      61m
```

Also ensure you have permission to create ConfigMaps:

```bash
$ kubectl -n linkerd auth can-i create configmap
yes
```

### √ control plane replica sets are ready {#l5d-existence-replicasets}

This failure occurs when one of Linkerd's ReplicaSets fails to schedule a pod.

For more information, see the Kubernetes documentation on
[Failed Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#failed-deployment).

### √ no unschedulable pods {#l5d-existence-unschedulable-pods}

Example failure:

```bash
× no unschedulable pods
    linkerd-prometheus-6b668f774d-j8ncr: 0/1 nodes are available: 1 Insufficient cpu.
    see https://linkerd.io/checks/#l5d-existence-unschedulable-pods for hints
```

For more information, see the Kubernetes documentation on the
[Unschedulable Pod Condition](https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#pod-conditions).

### √ controller pod is running {#l5d-existence-controller}

Example failure:

```bash
× controller pod is running
    No running pods for "linkerd-controller"
```

Note, it takes a little bit for pods to be scheduled, images to be pulled and
everything to start up. If this is a permanent error, you'll want to validate
the state of the controller pod with:

```bash
$ kubectl -n linkerd get po --selector linkerd.io/control-plane-component=controller
NAME                                  READY     STATUS    RESTARTS   AGE
linkerd-controller-7bb8ff5967-zg265   4/4       Running   0          40m
```

Check the controller's logs with:

```bash
linkerd logs --control-plane-component controller
```

### √ can initialize the client {#l5d-existence-client}

Example failure:

```bash
× can initialize the client
    parse http:// bad/: invalid character " " in host name
```

Verify that a well-formed `--api-addr` parameter was specified, if any:

```bash
linkerd check --api-addr " bad"
```

### √ can query the control plane API {#l5d-existence-api}

Example failure:

```bash
× can query the control plane API
    Post http://8.8.8.8/api/v1/Version: context deadline exceeded
```

This check indicates a connectivity failure between the cli and the Linkerd
control plane. To verify connectivity, manually connect to the controller pod:

```bash
kubectl -n linkerd port-forward \
    $(kubectl -n linkerd get po \
        --selector=linkerd.io/control-plane-component=controller \
        -o jsonpath='{.items[*].metadata.name}') \
9995:9995
```

...and then curl the `/metrics` endpoint:

```bash
curl localhost:9995/metrics
```

## The "linkerd-api" checks {#l5d-api}

### √ control plane pods are ready {#l5d-api-control-ready}

Example failure:

```bash
× control plane pods are ready
    No running pods for "linkerd-web"
```

Verify the state of the control plane pods with:

```bash
$ kubectl -n linkerd get po
NAME                                      READY     STATUS    RESTARTS   AGE
pod/linkerd-controller-b8c4c48c8-pflc9    4/4       Running   0          45m
pod/linkerd-grafana-776cf777b6-lg2dd      2/2       Running   0          1h
pod/linkerd-prometheus-74d66f86f6-6t6dh   2/2       Running   0          1h
pod/linkerd-web-5f6c45d6d9-9hd9j          2/2       Running   0          3m
```

### √ control plane self-check {#l5d-api-control-api}

Example failure:

```bash
× control plane self-check
    Post https://localhost:6443/api/v1/namespaces/linkerd/services/linkerd-controller-api:http/proxy/api/v1/SelfCheck: context deadline exceeded
```

Check the logs on the control-plane's public API:

```bash
linkerd logs --control-plane-component controller --container public-api
```

### √ [kubernetes] control plane can talk to Kubernetes {#l5d-api-k8s}

Example failure:

```bash
× [kubernetes] control plane can talk to Kubernetes
    Error calling the Kubernetes API: FAIL
```

Check the logs on the control-plane's public API:

```bash
linkerd logs --control-plane-component controller --container public-api
```

### √ [prometheus] control plane can talk to Prometheus {#l5d-api-prom}

Example failure:

```bash
× [prometheus] control plane can talk to Prometheus
    Error calling Prometheus from the control plane: FAIL
```

{{< note >}}
This will fail if you have changed your default cluster domain from
`cluster.local`, see the
[associated issue](https://github.com/linkerd/linkerd2/issues/1720) for more
information and potential workarounds.
{{< /note >}}

Validate that the Prometheus instance is up and running:

```bash
kubectl -n linkerd get all | grep prometheus
```

Check the Prometheus logs:

```bash
linkerd logs --control-plane-component prometheus
```

Check the logs on the control-plane's public API:

```bash
linkerd logs --control-plane-component controller --container public-api
```

## The "linkerd-service-profile" checks {#l5d-sp}

Example failure:

```bash
‼ no invalid service profiles
    ServiceProfile "bad" has invalid name (must be "<service>.<namespace>.svc.cluster.local")
```

Validate the structure of your service profiles:

```bash
$ kubectl -n linkerd get sp
NAME                                               AGE
bad                                                51s
linkerd-controller-api.linkerd.svc.cluster.local   1m
```

## The "linkerd-version" checks {#l5d-version}

### √ can determine the latest version {#l5d-version-latest}

Example failure:

```bash
× can determine the latest version
    Get https://versioncheck.linkerd.io/version.json?version=edge-19.1.2&uuid=test-uuid&source=cli: context deadline exceeded
```

Ensure you can connect to the Linkerd version check endpoint from the
environment the `linkerd` cli is running:

```bash
$ curl "https://versioncheck.linkerd.io/version.json?version=edge-19.1.2&uuid=test-uuid&source=cli"
{"stable":"stable-2.1.0","edge":"edge-19.1.2"}
```

### √ cli is up-to-date {#l5d-version-cli}

Example failure:

```bash
‼ cli is up-to-date
    is running version 19.1.1 but the latest edge version is 19.1.2
```

See the page on [Upgrading Linkerd](/2/upgrade/).

## The "control-plane-version" checks {#l5d-version-control}

Example failures:

```bash
‼ control plane is up-to-date
    is running version 19.1.1 but the latest edge version is 19.1.2
‼ control plane and cli versions match
    mismatched channels: running stable-2.1.0 but retrieved edge-19.1.2
```

See the page on [Upgrading Linkerd](/2/upgrade/).

## The "linkerd-data-plane" checks {#l5d-data-plane}

These checks only run when the `--proxy` flag is set. This flag is intended for
use after running `linkerd inject`, to verify the injected proxies are operating
normally.

### √ data plane namespace exists {#l5d-data-plane-exists}

Example failure:

```bash
$ linkerd check --proxy --namespace foo
...
× data plane namespace exists
    The "foo" namespace does not exist
```

Ensure the `--namespace` specified exists, or, omit the parameter to check all
namespaces.

### √ data plane proxies are ready {#l5d-data-plane-ready}

Example failure:

```bash
× data plane proxies are ready
    No "linkerd-proxy" containers found
```

Ensure you have injected the Linkerd proxy into your application via the
`linkerd inject` command.

For more information on `linkerd inject`, see
[Step 5: Install the demo app](/2/getting-started/#step-5-install-the-demo-app)
in our [Getting Started](/2/getting-started/) guide.

### √ data plane proxy metrics are present in Prometheus {#l5d-data-plane-prom}

Example failure:

```bash
× data plane proxy metrics are present in Prometheus
    Data plane metrics not found for linkerd/linkerd-controller-b8c4c48c8-pflc9.
```

Ensure Prometheus can connect to each `linkerd-proxy` via the Prometheus
dashboard:

```bash
kubectl -n linkerd port-forward svc/linkerd-prometheus 9090
```

...and then browse to
[http://localhost:9090/targets](http://localhost:9090/targets), validate the
`linkerd-proxy` section.

You should see all your pods here. If they are not:

- Prometheus might be experiencing connectivity issues with the k8s api server.
  Check out the logs and delete the pod to flush any possible transient errors.

### √ data plane is up-to-date {#l5d-data-plane-version}

Example failure:

```bash
‼ data plane is up-to-date
    linkerd/linkerd-prometheus-74d66f86f6-6t6dh: is running version 19.1.2 but the latest edge version is 19.1.3
```

See the page on [Upgrading Linkerd](/2/upgrade/).

### √ data plane and cli versions match {#l5d-data-plane-cli-version}

```bash
‼ data plane and cli versions match
    linkerd/linkerd-web-5f6c45d6d9-9hd9j: is running version 19.1.2 but the latest edge version is 19.1.3
```

See the page on [Upgrading Linkerd](/2/upgrade/).
