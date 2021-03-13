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

These checks only run when the `--pre` flag is set This flag is intended for use
prior to running `linkerd install`, to verify you have the correct RBAC
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

This check detects any differences between the system running the
`linkerd install` command and the Kubernetes nodes (known as clock skew). Having
a substantial clock skew can cause TLS validation problems because a node may
determine that a TLS certificate is expired when it should not be, or vice
versa.

Linkerd version edge-20.3.4 and later check for a difference of at most 5
minutes and older versions of Linkerd (including stable-2.7) check for a
difference of at most 1 minute. If your Kubernetes node heartbeat interval is
longer than this difference, you may experience false positives of this check.
The default node heartbeat interval was increased to 5 minutes in Kubernetes
1.17 meaning that users running Linkerd versions prior to edge-20.3.4 on
Kubernetes 1.17 or later are likely to experience these false positives. If this
is the case, you can upgrade to Linkerd edge-20.3.4 or later. If you choose to
ignore this error, we strongly recommend that you verify that your system clocks
are consistent.

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
and the
[man page on Linux Capabilities](https://www.man7.org/linux/man-pages/man7/capabilities.7.html).

### √ has NET_RAW capability {#pre-k8s-cluster-net-raw}

Example failure:

```bash
× has NET_RAW capability
    found 3 PodSecurityPolicies, but none provide NET_RAW
    see https://linkerd.io/checks/#pre-k8s-cluster-net-raw for hints
```

Linkerd installation requires the `NET_RAW` Kubernetes capability, to allow for
modification of iptables.

For more information, see the Kubernetes documentation on
[Pod Security Policies](https://kubernetes.io/docs/concepts/policy/pod-security-policy/),
[Security Contexts](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/),
and the
[man page on Linux Capabilities](https://www.man7.org/linux/man-pages/man7/capabilities.7.html).

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
[GKE Setup](../install/#gke) section above.

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
    Kubernetes is on version [1.7.16], but version [1.13.0] or more recent is required
```

Linkerd requires at least version `1.13.0`. Verify your cluster version with:

```bash
kubectl version
```

### √ is running the minimum kubectl version {#kubectl-version}

Example failure:

```bash
× is running the minimum kubectl version
    kubectl is on version [1.9.1], but version [1.13.0] or more recent is required
    see https://linkerd.io/checks/#kubectl-version for hints
```

Linkerd requires at least version `1.13.0`. Verify your kubectl version with:

```bash
kubectl version --client --short
```

To fix please update kubectl version.

For more information on upgrading Kubernetes, see the page in the Kubernetes
Documentation.

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
kubectl logs -n linkerd linkerd-controller-7bb8ff5967-zg265 public-api
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

## The "linkerd-identity" checks {#l5d-identity}

### √ certificate config is valid {#l5d-identity-cert-config-valid}

Example failures:

```bash
× certificate config is valid
    key ca.crt containing the trust anchors needs to exist in secret linkerd-identity-issuer if --identity-external-issuer=true
    see https://linkerd.io/checks/#l5d-identity-cert-config-valid
```

```bash
× certificate config is valid
    key crt.pem containing the issuer certificate needs to exist in secret linkerd-identity-issuer if --identity-external-issuer=false
    see https://linkerd.io/checks/#l5d-identity-cert-config-valid
```

Ensure that your `linkerd-identity-issuer` secret contains the correct keys for
the `scheme` that Linkerd is configured with. If the scheme is
`kubernetes.io/tls` your secret should contain the `tls.crt`, `tls.key` and
`ca.crt` keys. Alternatively if your scheme is `linkerd.io/tls`, the required
keys are `crt.pem` and `key.pem`.

### √ trust roots are using supported crypto algorithm {#l5d-identity-trustAnchors-use-supported-crypto}

Example failure:

```bash
× trust roots are using supported crypto algorithm
    Invalid roots:
        * 165223702412626077778653586125774349756 identity.linkerd.cluster.local must use P-256 curve for public key, instead P-521 was used
    see https://linkerd.io/checks/#l5d-identity-trustAnchors-use-supported-crypto
```

You need to ensure that all of your roots use ECDSA P-256 for their public key
algorithm.

### √ trust roots are within their validity period {#l5d-identity-trustAnchors-are-time-valid}

Example failure:

```bash
× trust roots are within their validity period
    Invalid roots:
        * 199607941798581518463476688845828639279 identity.linkerd.cluster.local not valid anymore. Expired on 2019-12-19T13:08:18Z
    see https://linkerd.io/checks/#l5d-identity-trustAnchors-are-time-valid for hints
```

Failures of such nature indicate that your roots have expired. If that is the
case you will have to update both the root and issuer certificates at once. You
can follow the process outlined in
[Replacing Expired Certificates](../replacing_expired_certificates/) to
get your cluster back to a stable state.

### √ trust roots are valid for at least 60 days {#l5d-identity-trustAnchors-not-expiring-soon}

Example warnings:

```bash
‼ trust roots are valid for at least 60 days
    Roots expiring soon:
        * 66509928892441932260491975092256847205 identity.linkerd.cluster.local will expire on 2019-12-19T13:30:57Z
    see https://linkerd.io/checks/#l5d-identity-trustAnchors-not-expiring-soon for hints
```

This warning indicates that the expiry of some of your roots is approaching. In
order to address this problem without incurring downtime, you can follow the
process outlined in
[Rotating your identity certificates](../rotating_identity_certificates/).

### √ issuer cert is using supported crypto algorithm {#l5d-identity-issuer-cert-uses-supported-crypto}

Example failure:

```bash
× issuer cert is using supported crypto algorithm
    issuer certificate must use P-256 curve for public key, instead P-521 was used
    see https://linkerd.io/checks/#5d-identity-issuer-cert-uses-supported-crypto for hints
```

You need to ensure that your issuer certificate uses ECDSA P-256 for its public
key algorithm. You can refer to
[Generating your own mTLS root certificates](../generate-certificates/#generating-the-certificates-with-step)
to see how you can generate certificates that will work with Linkerd.

### √ issuer cert is within its validity period {#l5d-identity-issuer-cert-is-time-valid}

Example failure:

```bash
× issuer cert is within its validity period
    issuer certificate is not valid anymore. Expired on 2019-12-19T13:35:49Z
    see https://linkerd.io/checks/#l5d-identity-issuer-cert-is-time-valid
```

This failure indicates that your issuer certificate has expired. In order to
bring your cluster back to a valid state, follow the process outlined in
[Replacing Expired Certificates](../replacing_expired_certificates/).

### √ issuer cert is valid for at least 60 days {#l5d-identity-issuer-cert-not-expiring-soon}

Example warning:

```bash
‼ issuer cert is valid for at least 60 days
    issuer certificate will expire on 2019-12-19T13:35:49Z
    see https://linkerd.io/checks/#l5d-identity-issuer-cert-not-expiring-soon for hints
```

This warning means that your issuer certificate is expiring soon. If you do not
rely on external certificate management solution such as `cert-manager`, you can
follow the process outlined in
[Rotating your identity certificates](../rotating_identity_certificates/)

### √ issuer cert is issued by the trust root {#l5d-identity-issuer-cert-issued-by-trust-anchor}

Example error:

```bash
× issuer cert is issued by the trust root
    x509: certificate signed by unknown authority (possibly because of "x509: ECDSA verification failure" while trying to verify candidate authority certificate "identity.linkerd.cluster.local")
    see https://linkerd.io/checks/#l5d-identity-issuer-cert-issued-by-trust-anchor for hints
```

This error indicates that the issuer certificate that is in the
`linkerd-identity-issuer` secret cannot be verified with any of the roots that
Linkerd has been configured with. Using the CLI install process, this should
never happen. If Helm was used for installation or the issuer certificates are
managed by a malfunctioning certificate management solution, it is possible for
the cluster to end up in such an invalid state. At that point the best to do is
to use the upgrade command to update your certificates:

```bash
linkerd upgrade \
    --identity-issuer-certificate-file=./your-new-issuer.crt \
    --identity-issuer-key-file=./your-new-issuer.key \
    --identity-trust-anchors-file=./your-new-roots.crt \
    --force | kubectl apply -f -
```

Once the upgrade process is over, the output of `linkerd check --proxy` should
be:

```bash
linkerd-identity
----------------
√ certificate config is valid
√ trust roots are using supported crypto algorithm
√ trust roots are within their validity period
√ trust roots are valid for at least 60 days
√ issuer cert is using supported crypto algorithm
√ issuer cert is within its validity period
√ issuer cert is valid for at least 60 days
√ issuer cert is issued by the trust root

linkerd-identity-data-plane
---------------------------
√ data plane proxies certificate match CA
```

## The "linkerd-webhooks-and-apisvc-tls" checks {#l5d-webhook}

### √ tap API server has valid cert {#l5d-tap-cert-valid}

Example failure:

```bash
× tap API server has valid cert
    secrets "linkerd-tap-tls" not found
    see https://linkerd.io/checks/#l5d-tap-cert-valid for hints
```

Ensure that the `linkerd-tap-k8s-tls` secret exists and contains the appropriate
`tls.crt` and `tls.key` data entries. For versions before 2.9, the secret is
named `linkerd-tap-tls` and it should contain the `crt.pem` and `key.pem` data
entries.

```bash
× tap API server has valid cert
    cert is not issued by the trust anchor: x509: certificate is valid for xxxxxx, not linkerd-tap.linkerd.svc
    see https://linkerd.io/checks/#l5d-tap-cert-valid for hints
```

Here you need to make sure the certificate was issued specifically for
`linkerd-tap.linkerd.svc`.

### √ webhook cert is valid for at least 60 days {#l5d-webhook-cert-not-expiring-soon}

Example failure:

```bash
‼ tap API server cert is valid for at least 60 days
    certificate will expire on 2020-11-07T17:00:07Z
    see https://linkerd.io/checks/#l5d-webhook-cert-not-expiring-soon for hints
```

This warning indicates that the expiry of one of your webhooks (tap API server,
proxy-injector or sp-validator) cert is approaching. In order to address this
problem without incurring downtime, you can follow the process outlined in
[Automatically Rotating your webhook TLS Credentials](../automatically-rotating-webhook-tls-credentials/).

### √ proxy-injector webhook has valid cert {#l5d-proxy-injector-webhook-cert-valid}

Example failure:

```bash
× proxy-injector webhook has valid cert
    secrets "linkerd-proxy-injector-tls" not found
    see https://linkerd.io/checks/#l5d-proxy-injector-webhook-cert-valid for hints
```

Ensure that the `linkerd-proxy-injector-k8s-tls` secret exists and contains the
appropriate `tls.crt` and `tls.key` data entries. For versions before 2.9, the
secret is named `linkerd-proxy-injector-tls` and it should contain the `crt.pem`
and `key.pem` data entries.

```bash
× proxy-injector webhook has valid cert
    cert is not issued by the trust anchor: x509: certificate is valid for xxxxxx, not linkerd-proxy-injector.linkerd.svc
    see https://linkerd.io/checks/#l5d-proxy-injector-webhook-cert-valid for hints
```

Here you need to make sure the certificate was issued specifically for
`linkerd-proxy-injector.linkerd.svc`.

### √ sp-validator webhook has valid cert {#l5d-sp-validator-webhook-cert-valid}

Example failure:

```bash
× sp-validator webhook has valid cert
    secrets "linkerd-sp-validator-tls" not found
    see https://linkerd.io/checks/#l5d-sp-validator-webhook-cert-valid for hints
```

Ensure that the `linkerd-sp-validator-k8s-tls` secret exists and contains the
appropriate `tls.crt` and `tls.key` data entries. For versions before 2.9, the
secret is named `linkerd-sp-validator-tls` and it should contain the `crt.pem`
and `key.pem` data entries.

```bash
× sp-validator webhook has valid cert
    cert is not issued by the trust anchor: x509: certificate is valid for xxxxxx, not linkerd-sp-validator.linkerd.svc
    see https://linkerd.io/checks/#l5d-sp-validator-webhook-cert-valid for hints
```

Here you need to make sure the certificate was issued specifically for
`linkerd-sp-validator.linkerd.svc`.

## The "linkerd-identity-data-plane" checks {#l5d-identity-data-plane}

### √ data plane proxies certificate match CA {#l5d-identity-data-plane-proxies-certs-match-ca}

Example warning:

```bash
‼ data plane proxies certificate match CA
    Some pods do not have the current trust bundle and must be restarted:
        * emojivoto/emoji-d8d7d9c6b-8qwfx
        * emojivoto/vote-bot-588499c9f6-zpwz6
        * emojivoto/voting-8599548fdc-6v64k
    see https://linkerd.io/checks/{#l5d-identity-data-plane-proxies-certs-match-ca for hints
```

Observing this warning indicates that some of your meshed pods have proxies that
have stale certificates. This is most likely to happen during `upgrade`
operations that deal with cert rotation. In order to solve the problem you can
use `rollout restart` to restart the pods in question. That should cause them to
pick the correct certs from the `linkerd-config` configmap. When `upgrade` is
performed using the `--identity-trust-anchors-file` flag to modify the roots,
the Linkerd components are restarted. While this operation is in progress the
`check --proxy` command may output a warning, pertaining to the Linkerd
components:

```bash
‼ data plane proxies certificate match CA
    Some pods do not have the current trust bundle and must be restarted:
        * linkerd/linkerd-sp-validator-75f9d96dc-rch4x
        * linkerd/linkerd-tap-68d8bbf64-mpzgb
        * linkerd/linkerd-web-849f74b7c6-qlhwc
    see https://linkerd.io/checks/{#l5d-identity-data-plane-proxies-certs-match-ca for hints
```

If that is the case, simply wait for the `upgrade` operation to complete. The
stale pods should terminate and be replaced by new ones, configured with the
correct certificates.

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
kubectl logs -n linkerd linkerd-controller-b8c4c48c8-pflc9 public-api
```

### √ [kubernetes] control plane can talk to Kubernetes {#l5d-api-k8s}

Example failure:

```bash
× [kubernetes] control plane can talk to Kubernetes
    Error calling the Kubernetes API: FAIL
```

Check the logs on the control-plane's public API:

```bash
kubectl logs -n linkerd linkerd-controller-b8c4c48c8-pflc9 public-api
```

### √ [prometheus] control plane can talk to Prometheus {#l5d-api-prom}

Example failure:

```bash
× [prometheus] control plane can talk to Prometheus
    Error calling Prometheus from the control plane: FAIL
```

{{< note >}} This will fail if you have changed your default cluster domain from
`cluster.local`, see the
[associated issue](https://github.com/linkerd/linkerd2/issues/1720) for more
information and potential workarounds. {{< /note >}}

Validate that the Prometheus instance is up and running:

```bash
kubectl -n linkerd get all | grep prometheus
```

Check the Prometheus logs:

```bash
kubectl logs -n linkerd linkerd-prometheus-74d66f86f6-6t6dh prometheus
```

Check the logs on the control-plane's public API:

```bash
kubectl logs -n linkerd linkerd-controller-b8c4c48c8-pflc9 public-api
```

### √ tap api service is running {#l5d-tap-api}

Example failure:

```bash
× FailedDiscoveryCheck: no response from https://10.233.31.133:443: Get https://10.233.31.133:443: net/http: request canceled while waiting for connection (Client.Timeout exceeded while awaiting headers)
```

tap uses the
[kubernetes Aggregated Api-Server model](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/apiserver-aggregation/)
to allow users to have k8s RBAC on top. This model has the following specific
requirements in the cluster:

- tap Server must be
  [reachable from kube-apiserver](https://kubernetes.io/docs/concepts/architecture/master-node-communication/#master-to-cluster)
- The kube-apiserver must be correctly configured to
  [enable an aggregation layer](https://kubernetes.io/docs/tasks/access-kubernetes-api/configure-aggregation-layer/)

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

Example failure:

```bash
‼ no invalid service profiles
    the server could not find the requested resource (get serviceprofiles.linkerd.io)
```

Validate that the Service Profile CRD is installed on your cluster and that its
`linkerd.io/created-by` annotation matches your `linkerd version` client
version:

```bash
kubectl get crd/serviceprofiles.linkerd.io -o yaml | grep linkerd.io/created-by
```

If the CRD is missing or out-of-date you can update it:

```bash
linkerd upgrade | kubectl apply -f -
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

See the page on [Upgrading Linkerd](../../upgrade/).

## The "control-plane-version" checks {#l5d-version-control}

Example failures:

```bash
‼ control plane is up-to-date
    is running version 19.1.1 but the latest edge version is 19.1.2
‼ control plane and cli versions match
    mismatched channels: running stable-2.1.0 but retrieved edge-19.1.2
```

See the page on [Upgrading Linkerd](../../upgrade/).

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
[Step 5: Install the demo app](../../getting-started/#step-5-install-the-demo-app)
in our [Getting Started](../../getting-started/) guide.

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

See the page on [Upgrading Linkerd](../../upgrade/).

### √ data plane and cli versions match {#l5d-data-plane-cli-version}

```bash
‼ data plane and cli versions match
    linkerd/linkerd-web-5f6c45d6d9-9hd9j: is running version 19.1.2 but the latest edge version is 19.1.3
```

See the page on [Upgrading Linkerd](../../upgrade/).

## The "linkerd-ha-checks" checks {#l5d-ha}

These checks are ran if Linkerd has been installed in HA mode.

### √ pod injection disabled on kube-system {#l5d-injection-disabled}

Example warning:

```bash
‼ pod injection disabled on kube-system
    kube-system namespace needs to have the label config.linkerd.io/admission-webhooks: disabled if HA mode is enabled
    see https://linkerd.io/checks/#l5d-injection-disabled for hints
```

Ensure the kube-system namespace has the
`config.linkerd.io/admission-webhooks:disabled` label:

```bash
$ kubectl get namespace kube-system -oyaml
kind: Namespace
apiVersion: v1
metadata:
  name: kube-system
  annotations:
    linkerd.io/inject: disabled
  labels:
    config.linkerd.io/admission-webhooks: disabled
```

### √ multiple replicas of control plane pods {#l5d-control-plane-replicas}

Example warning:

```bash
‼ multiple replicas of control plane pods
    not enough replicas available for [linkerd-controller]
    see https://linkerd.io/checks/#l5d-control-plane-replicas for hints
```

This happens when one of the control plane pods doesn't have at least two
replicas running. This is likely caused by insufficient node resources.

## The "linkerd-cni-plugin" checks {#l5d-cni}

These checks run if Linkerd has been installed with the `--linkerd-cni-enabled`
flag. Alternatively they can be run as part of the pre-checks by providing the
`--linkerd-cni-enabled` flag. Most of these checks verify that the required
resources are in place. If any of them are missing, you can use
`linkerd install-cni | kubectl apply -f -` to re-install them.

### √ cni plugin ConfigMap exists {#cni-plugin-cm-exists}

Example error:

```bash
× cni plugin ConfigMap exists
    configmaps "linkerd-cni-config" not found
    see https://linkerd.io/checks/#cni-plugin-cm-exists for hints
```

Ensure that the linkerd-cni-config ConfigMap exists in the CNI namespace:

```bash
$ kubectl get cm linkerd-cni-config -n linkerd-cni
NAME                      PRIV    CAPS   SELINUX    RUNASUSER   FSGROUP    SUPGROUP   READONLYROOTFS   VOLUMES
linkerd-linkerd-cni-cni   false          RunAsAny   RunAsAny    RunAsAny   RunAsAny   false            hostPath,secret
```

Also ensure you have permission to create ConfigMaps:

```bash
$ kubectl auth can-i create ConfigMaps
yes
```

### √ cni plugin PodSecurityPolicy exists {#cni-plugin-psp-exists}

Example error:

```bash
× cni plugin PodSecurityPolicy exists
    missing PodSecurityPolicy: linkerd-linkerd-cni-cni
    see https://linkerd.io/checks/#cni-plugin-psp-exists for hint
```

Ensure that the pod security policy exists:

```bash
$ kubectl get psp linkerd-linkerd-cni-cni
NAME                      PRIV    CAPS   SELINUX    RUNASUSER   FSGROUP    SUPGROUP   READONLYROOTFS   VOLUMES
linkerd-linkerd-cni-cni   false          RunAsAny   RunAsAny    RunAsAny   RunAsAny   false            hostPath,secret
```

Also ensure you have permission to create PodSecurityPolicies:

```bash
$ kubectl auth can-i create PodSecurityPolicies
yes
```

### √ cni plugin ClusterRole exist {#cni-plugin-cr-exists}

Example error:

```bash
× cni plugin ClusterRole exists
    missing ClusterRole: linkerd-cni
    see https://linkerd.io/checks/#cni-plugin-cr-exists for hints
```

Ensure that the cluster role exists:

```bash
$ kubectl get clusterrole linkerd-cni
NAME          AGE
linkerd-cni   54m
```

Also ensure you have permission to create ClusterRoles:

```bash
$ kubectl auth can-i create ClusterRoles
yes
```

### √ cni plugin ClusterRoleBinding exist {#cni-plugin-crb-exists}

Example error:

```bash
× cni plugin ClusterRoleBinding exists
    missing ClusterRoleBinding: linkerd-cni
    see https://linkerd.io/checks/#cni-plugin-crb-exists for hints
```

Ensure that the cluster role binding exists:

```bash
$ kubectl get clusterrolebinding linkerd-cni
NAME          AGE
linkerd-cni   54m
```

Also ensure you have permission to create ClusterRoleBindings:

```bash
$ kubectl auth can-i create ClusterRoleBindings
yes
```

### √ cni plugin Role exists {#cni-plugin-r-exists}

Example error:

```bash
× cni plugin Role exists
    missing Role: linkerd-cni
    see https://linkerd.io/checks/#cni-plugin-r-exists for hints
```

Ensure that the role exists in the CNI namespace:

```bash
$ kubectl get role linkerd-cni -n linkerd-cni
NAME          AGE
linkerd-cni   52m
```

Also ensure you have permission to create Roles:

```bash
$ kubectl auth can-i create Roles -n linkerd-cni
yes
```

### √ cni plugin RoleBinding exists {#cni-plugin-rb-exists}

Example error:

```bash
× cni plugin RoleBinding exists
    missing RoleBinding: linkerd-cni
    see https://linkerd.io/checks/#cni-plugin-rb-exists for hints
```

Ensure that the role binding exists in the CNI namespace:

```bash
$ kubectl get rolebinding linkerd-cni -n linkerd-cni
NAME          AGE
linkerd-cni   49m
```

Also ensure you have permission to create RoleBindings:

```bash
$ kubectl auth can-i create RoleBindings -n linkerd-cni
yes
```

### √ cni plugin ServiceAccount exists {#cni-plugin-sa-exists}

Example error:

```bash
× cni plugin ServiceAccount exists
    missing ServiceAccount: linkerd-cni
    see https://linkerd.io/checks/#cni-plugin-sa-exists for hints
```

Ensure that the CNI service account exists in the CNI namespace:

```bash
$ kubectl get ServiceAccount linkerd-cni -n linkerd-cni
NAME          SECRETS   AGE
linkerd-cni   1         45m
```

Also ensure you have permission to create ServiceAccount:

```bash
$ kubectl auth can-i create ServiceAccounts -n linkerd-cni
yes
```

### √ cni plugin DaemonSet exists {#cni-plugin-ds-exists}

Example error:

```bash
× cni plugin DaemonSet exists
    missing DaemonSet: linkerd-cni
    see https://linkerd.io/checks/#cni-plugin-ds-exists for hints
```

Ensure that the CNI daemonset exists in the CNI namespace:

```bash
$ kubectl get ds -n linkerd-cni
NAME          DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR                 AGE
linkerd-cni   1         1         1       1            1           beta.kubernetes.io/os=linux   14m
```

Also ensure you have permission to create DaemonSets:

```bash
$ kubectl auth can-i create DaemonSets -n linkerd-cni
yes
```

### √ cni plugin pod is running on all nodes {#cni-plugin-ready}

Example failure:

```bash
‼ cni plugin pod is running on all nodes
    number ready: 2, number scheduled: 3
    see https://linkerd.io/checks/#cni-plugin-ready
```

Ensure that all the CNI pods are running:

```bash
$ kubectl get po -n linkerd-cn
NAME                READY   STATUS    RESTARTS   AGE
linkerd-cni-rzp2q   1/1     Running   0          9m20s
linkerd-cni-mf564   1/1     Running   0          9m22s
linkerd-cni-p5670   1/1     Running   0          9m25s
```

Ensure that all pods have finished the deployment of the CNI config and binary:

```bash
$ kubectl logs linkerd-cni-rzp2q -n linkerd-cni
Wrote linkerd CNI binaries to /host/opt/cni/bin
Created CNI config /host/etc/cni/net.d/10-kindnet.conflist
Done configuring CNI. Sleep=true
```

## The "linkerd-multicluster checks {#l5d-multicluster}

These checks run if the service mirroring controller has been installed.
Additionally they can be ran if `--multicluster` flag is specified explicitly.
Most of these checks verify that the service mirroring controller is working
correctly. Furthermore the checks ensure that end to end TLS is possible between
paired clusters.

### √ service mirror controller is running {#l5d-multicluster-service-mirror-running}

Example error:

```bash
× service mirror controller is running
    Service mirror controller is not present
    see https://linkerd.io/checks/#l5d-multicluster-service-mirror-running for hints
```

Note, it takes a little bit for pods to be scheduled, images to be pulled and
everything to start up. If this is a permanent error, you'll want to validate
the state of the controller pod with:

```bash
$ kubectl --all-namespaces get po --selector linkerd.io/control-plane-component=linkerd-service-mirror
NAME                                  READY     STATUS    RESTARTS   AGE
linkerd-service-mirror-7bb8ff5967-zg265   2/2       Running   0          50m
```

### √ service mirror controller ClusterRoles exists {#l5d-multicluster-cluster-role-exists}

Example error:

```bash
× service mirror controller ClusterRoles exists
    missing ClusterRoles: linkerd-service-mirror-access-local-resources
    see https://linkerd.io/checks/#l5d-multicluster-cluster-role-exists for hints
```

Ensure that the cluster role exists:

```bash
$ kubectl get clusterrole linkerd-service-mirror-access-local-resources
NAME                                            AGE
linkerd-service-mirror-access-local-resources   54m
```

Also ensure you have permission to create ClusterRoles:

```bash
$ kubectl auth can-i create ClusterRoles
yes
```

### √ service mirror controller ClusterRoleBindings exist {#l5d-multicluster-cluster-role-binding-exist}

Example error:

```bash
× service mirror controller ClusterRoleBindings exist
    missing ClusterRoleBindings: linkerd-service-mirror-access-local-resources
    see https://linkerd.io/checks/#l5d-multicluster-cluster-role-binding-exist for hints
```

Ensure that the cluster role bindings exists:

```bash
$ kubectl get clusterrolebindings linkerd-service-mirror-access-local-resources
NAME                                            AGE
linkerd-service-mirror-access-local-resources   54m
```

Also ensure you have permission to create ClusterRoleBindings:

```bash
$ kubectl auth can-i create ClusterRoleBindings
yes
```

### √ service mirror controller Roles exist {#l5d-multicluster-role-exist}

Example error:

```bash
× service mirror controller Roles exist
    missing Roles: linkerd-service-mirror-read-remote-creds
    see https://linkerd.io/checks/#l5d-multicluster-role-exist for hints
```

Ensure that the role exists in the service mirror controller namespace:

```bash
$ kubectl get role linkerd-service-mirror-read-remote-creds -n linkerd-multicluster
NAME                                       AGE
linkerd-service-mirror-read-remote-creds   12m
```

Also ensure you have permission to create Roles:

```bash
$ kubectl auth can-i create Roles -n linkerd-multicluster
yes
```

### √ service mirror controller RoleBindings exist {#l5d-multicluster-role-binding-exist}

Example error:

```bash
× service mirror controller RoleBindings exist
    missing RoleBindings: linkerd-service-mirror-read-remote-creds
    see https://linkerd.io/checks/#l5d-multicluster-role-binding-exist for hints
```

Ensure that the role binding exists in service mirror controller namespace:

```bash
$ kubectl get rolebinding linkerd-service-mirror-read-remote-creds -n linkerd-multicluster
NAME                                       AGE
linkerd-service-mirror-read-remote-creds   19m
```

Also ensure you have permission to create RoleBindings:

```bash
$ kubectl auth can-i create RoleBindings -n linkerd-multicluster
yes
```

### √ service mirror controller ServiceAccounts exist {#l5d-multicluster-service-account-exist}

Example error:

```bash
× service mirror controller ServiceAccounts exist
    missing ServiceAccounts: linkerd-service-mirror
    see https://linkerd.io/checks/#l5d-multicluster-service-account-exist for hints
```

Ensure that the linkerd-service-mirror service account exists:

```bash
$ kubectl get ServiceAccount linkerd-service-mirror -n linkerd-multicluster
NAME                     SECRETS   AGE
linkerd-service-mirror   1         45m
```

Also ensure you have permission to create ServiceAccount:

```bash
$ kubectl auth can-i create ServiceAccounts -n linkerd-multicluster
yes
```

### √ service mirror controller has required permissions {#l5d-multicluster-local-rbac-correct}

Example error:

```bash
× service mirror controller has required permissions
    missing Service mirror ClusterRole linkerd-service-mirror-access-local-resources: unexpected verbs expected create,delete,get,list,update,watch, got create,delete,get,update,watch
    see https://linkerd.io/checks/#l5d-multicluster-local-rbac-correct for hints
```

This error indicates that the local RBAC permissions of the service mirror
service account are not correct. In order to ensure that you have the correct
verbs and resources you can inspect your ClusterRole and Role object and look at
the rules section.

Expected rules for `linkerd-service-mirror-access-local-resources` cluster role:

```bash
$ kubectl  --context=local get clusterrole linkerd-service-mirror-access-local-resources -o yaml
kind: ClusterRole
metadata:
  labels:
    linkerd.io/control-plane-component: linkerd-service-mirror
  name: linkerd-service-mirror-access-local-resources
rules:
- apiGroups:
  - ""
  resources:
  - endpoints
  - services
  verbs:
  - list
  - get
  - watch
  - create
  - delete
  - update
- apiGroups:
  - ""
  resources:
  - namespaces
  verbs:
  - create
  - list
  - get
  - watch
```

Expected rules for `linkerd-service-mirror-read-remote-creds` role:

```bash
$ kubectl  --context=local get role linkerd-service-mirror-read-remote-creds -n linkerd-multicluster  -o yaml
kind: Role
metadata:
  labels:
    linkerd.io/control-plane-component: linkerd-service-mirror
  name: linkerd-service-mirror-read-remote-creds
  namespace: linkerd-multicluster
  rules:
- apiGroups:
  - ""
  resources:
  - secrets
  verbs:
  - list
  - get
  - watch
```

### √ service mirror controller can access remote clusters {#l5d-smc-remote-remote-clusters-access}

Example error:

```bash
× service mirror controller can access remote clusters
    Problematic clusters:
        * cluster: [remote]: Insufficient Service permissions: expected get,list,watch, got list,watch
    see https://linkerd.io/checks/#l5d-smc-remote-remote-clusters-access for hints
```

In case you get an error of that nature you need to ensure that the ClusterRole
in the remote cluster has sufficient permissions for the service mirroring
controller to work correctly:

```bash
$ kubectl --context=remote get  clusterrole linkerd-service-mirror-remote-access  -n linkerd-multicluster -o yaml
kind: ClusterRole
metadata:
  name: linkerd-service-mirror-remote-access
rules:
- apiGroups:
  - ""
  resources:
  - services
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - ""
  resourceNames:
  - linkerd-config
  resources:
  - configmaps
  verbs:
  - get

```

### √ all remote cluster gateways are alive {#l5d-multicluster-remote-gateways-alive}

Example error:

```bash
× all remote cluster gateways are alive
    Some gateways are not alive:
        * cluster: [remote], gateway: [linkerd-multicluster/linkerd-gateway]
    see https://linkerd.io/checks/#l5d-multicluster-remote-gateways-alive
```

If you get such an error, you might want to check the logs of your cluster
gateway on the `remote` cluster by running:

```bash
kubectl --context=remote  logs <linkerd-gatewa-pod>  nginx  -n linkerd-multicluster  -f
```

Additionally it is worth checking the logs of the proxy for any errors:

```bash
kubectl --context=remote  logs <linkerd-gatewa-pod>  proxy  -n linkerd-multicluster  -f
```

### √ clusters share trust anchors {#l5d-multicluster-clusters-share-anchors}

Example errors:

```bash
× clusters share trust anchors
    Problematic clusters:
        * remote
    see https://linkerd.io/checks/#l5d-multicluster-clusters-share-anchors for hints
```

The error above indicates that your trust anchors are not compatible. In order
to fix that you need to ensure that both your anchors contain identical sets of
certificates.

```bash
× clusters share trust anchors
    Problematic clusters:
        * remote: cannot parse trust anchors
    see https://linkerd.io/checks/#l5d-multicluster-clusters-share-anchors for hints
```

Such an error indicates that there is a problem with your anchors on the cluster
named `remote` You need to make sure the identity config aspect of your Linkerd
installation on the `remote` cluster is ok. You can run `check` against the
remote cluster to verify that:

```bash
linkerd --context=remote check
```

### √ multicluster daisy chaining is avoided {#l5d-multicluster-daisy-chaining}

Example errors:

```bash
‼ multicluster daisy chaining is avoided
    * mirror service backend-one-svc-remote.multicluster-test is exported
    see https://linkerd.io/checks/#l5d-multicluster-daisy-chaining for hints
```

This error indicates that a mirror service has been exported, causing a "daisy
chain" where requests can come in to the cluster through the local gateway and
be immediately sent out of the cluster to a target gateway. If the target
gateway is in the source cluster, this can create an infinite loop.

Similarly, if an exported service routes to a mirror service by a traffic split,
the same daisy chain effect occurs.

### √ all mirror services have endpoints {#l5d-multicluster-services-endpoints}

Example errors:

```bash
‼ all mirror services have endpoints
    Some mirror services do not have endpoints:
  voting-svc-gke.emojivoto mirrored from cluster [gke] (gateway: [linkerd-multicluster/linkerd-gateway])
    see https://linkerd.io/checks/#l5d-multicluster-services-endpoints for hints
```

The error above indicates that some mirror services in the source cluster do not
have associated endpoints resources. These endpoints are created by the Linkerd
service mirror controller when creating a mirror service with endpoints values
as the remote gateway's external IP.

Such an error indicates that there could be a problem with the creation of the
mirror resources by the service mirror controller or the mirror gateway service
in the source cluster or the external IP of the gateway service in target
cluster.

### √ all gateway mirrors have endpoints {#l5d-multicluster-gateways-endpoints}

Example errors:

```bash
‼ all gateway mirrors have endpoints
    Some gateway mirrors do not have endpoints:
  linkerd-gateway-gke.linkerd-multicluster mirrored from cluster [gke]
    see https://linkerd.io/checks/#l5d-multicluster-gateways-endpoints for hints
```

The error above indicates that some gateway mirror services in the source
cluster do not have associated endpoints resources. These endpoints are created
by the Linkerd service mirror controller on the source cluster whenever a link
is established with a target cluster.

Such an error indicates that there could be a problem with the creation of the
resources by the service mirror controller or the external IP of the gateway
service in target cluster.

### √ all referenced/cluster gateways are valid {#l5d-multicluster-gateways-exist}

This check is used to validate gateways. These are performed perform both at the
source cluster using the kube-configs of the linked remote clusters, and also at
the target cluster directly(if there are any exported services present).

Example errors:

```bash
‼ remote: all referenced gateways are valid
    * southeastasia: remote cluster has invalid gateways:
      Exported service web-svc.emojivoto references a gateway with no external IP: linkerd-gateway.linkerd-multicluster
      Exported service web-svc.emojivoto references a gateway that is missing port mc-gateway: linkerd-gateway.linkerd-multicluster
    * gke-two: remote cluster has invalid gateways:
      Exported service voting-svc.emojivoto references a gateway that does not exist: linkerd-gateway.linkerd-multicluster
    see https://linkerd.io/checks/#l5d-multicluster-gateways-exist for hints
```

A gateway is considered valid if it exists, has a external IP, and does not have
any mis-configured ports.

A Linkerd gateway service should have the following ports exposed i.e
`mc-gateway` and `mc-probe`, which are used to pass requests and check health
respectively.

```bash
‼ all cluster gateways are valid
    Some gateway services do not have endpoints:
    linkerd-gateway.linkerd-multicluster
    see https://linkerd.io/checks/#l5d-multicluster-gateways-exist for hints
```

If the check is performed on the target cluster, It also reports if the relevant
endpoints resource for the gateway service is absent.
