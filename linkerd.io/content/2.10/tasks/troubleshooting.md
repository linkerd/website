---
title: Troubleshooting
description: Troubleshoot issues with your Linkerd installation.
---

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
    see https://linkerd.io/2/checks/#pre-k8s-cluster-net-admin for hints
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
    see https://linkerd.io/2/checks/#pre-k8s-cluster-net-raw for hints
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
    see https://linkerd.io/2/checks/#kubectl-version for hints
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
    see https://linkerd.io/2/checks/#l5d-existence-ns for hints
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
    missing ClusterRoles: linkerd-linkerd-identity
    see https://linkerd.io/2/checks/#l5d-existence-cr for hints
```

Ensure the Linkerd ClusterRoles exist:

```bash
$ kubectl get clusterroles | grep linkerd
linkerd-linkerd-destination                                            9d
linkerd-linkerd-identity                                               9d
linkerd-linkerd-proxy-injector                                         9d
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
    missing ClusterRoleBindings: linkerd-linkerd-identity
    see https://linkerd.io/2/checks/#l5d-existence-crb for hints
```

Ensure the Linkerd ClusterRoleBindings exist:

```bash
$ kubectl get clusterrolebindings | grep linkerd
linkerd-linkerd-destination                            9d
linkerd-linkerd-identity                               9d
linkerd-linkerd-proxy-injector                         9d
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
    missing ServiceAccounts: linkerd-identity
    see https://linkerd.io/2/checks/#l5d-existence-sa for hints
```

Ensure the Linkerd ServiceAccounts exist:

```bash
$ kubectl -n linkerd get serviceaccounts
NAME                     SECRETS   AGE
default                  1         14m
linkerd-destination      1         14m
linkerd-heartbeat        1         14m
linkerd-identity         1         14m
linkerd-proxy-injector   1         14m
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
    see https://linkerd.io/2/checks/#l5d-existence-crd for hints
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
    see https://linkerd.io/2/checks/#l5d-existence-mwc for hints
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
    see https://linkerd.io/2/checks/#l5d-existence-vwc for hints
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
    see https://linkerd.io/2/checks/#l5d-existence-psp for hints
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
    see https://linkerd.io/2/checks/#l5d-existence-linkerd-config for hints
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
    see https://linkerd.io/2/checks/#l5d-existence-unschedulable-pods for hints
```

For more information, see the Kubernetes documentation on the
[Unschedulable Pod Condition](https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#pod-conditions).

## The "linkerd-identity" checks {#l5d-identity}

### √ certificate config is valid {#l5d-identity-cert-config-valid}

Example failures:

```bash
× certificate config is valid
    key ca.crt containing the trust anchors needs to exist in secret linkerd-identity-issuer if --identity-external-issuer=true
    see https://linkerd.io/2/checks/#l5d-identity-cert-config-valid
```

```bash
× certificate config is valid
    key crt.pem containing the issuer certificate needs to exist in secret linkerd-identity-issuer if --identity-external-issuer=false
    see https://linkerd.io/2/checks/#l5d-identity-cert-config-valid
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
    see https://linkerd.io/2/checks/#l5d-identity-trustAnchors-use-supported-crypto
```

You need to ensure that all of your roots use ECDSA P-256 for their public key
algorithm.

### √ trust roots are within their validity period {#l5d-identity-trustAnchors-are-time-valid}

Example failure:

```bash
× trust roots are within their validity period
    Invalid roots:
        * 199607941798581518463476688845828639279 identity.linkerd.cluster.local not valid anymore. Expired on 2019-12-19T13:08:18Z
    see https://linkerd.io/2/checks/#l5d-identity-trustAnchors-are-time-valid for hints
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
    see https://linkerd.io/2/checks/#l5d-identity-trustAnchors-not-expiring-soon for hints
```

This warning indicates that the expiry of some of your roots is approaching. In
order to address this problem without incurring downtime, you can follow the
process outlined in
[Rotating your identity certificates](../manually-rotating-control-plane-tls-credentials/).

### √ issuer cert is using supported crypto algorithm {#l5d-identity-issuer-cert-uses-supported-crypto}

Example failure:

```bash
× issuer cert is using supported crypto algorithm
    issuer certificate must use P-256 curve for public key, instead P-521 was used
    see https://linkerd.io/2/checks/#5d-identity-issuer-cert-uses-supported-crypto for hints
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
    see https://linkerd.io/2/checks/#l5d-identity-issuer-cert-is-time-valid
```

This failure indicates that your issuer certificate has expired. In order to
bring your cluster back to a valid state, follow the process outlined in
[Replacing Expired Certificates](../replacing_expired_certificates/).

### √ issuer cert is valid for at least 60 days {#l5d-identity-issuer-cert-not-expiring-soon}

Example warning:

```bash
‼ issuer cert is valid for at least 60 days
    issuer certificate will expire on 2019-12-19T13:35:49Z
    see https://linkerd.io/2/checks/#l5d-identity-issuer-cert-not-expiring-soon for hints
```

This warning means that your issuer certificate is expiring soon. If you do not
rely on external certificate management solution such as `cert-manager`, you can
follow the process outlined in
[Rotating your identity certificates](../manually-rotating-control-plane-tls-credentials/)

### √ issuer cert is issued by the trust root {#l5d-identity-issuer-cert-issued-by-trust-anchor}

Example error:

```bash
× issuer cert is issued by the trust root
    x509: certificate signed by unknown authority (possibly because of "x509: ECDSA verification failure" while trying to verify candidate authority certificate "identity.linkerd.cluster.local")
    see https://linkerd.io/2/checks/#l5d-identity-issuer-cert-issued-by-trust-anchor for hints
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

### √ proxy-injector webhook has valid cert {#l5d-proxy-injector-webhook-cert-valid}

Example failure:

```bash
× proxy-injector webhook has valid cert
    secrets "linkerd-proxy-injector-tls" not found
    see https://linkerd.io/2/checks/#l5d-proxy-injector-webhook-cert-valid for hints
```

Ensure that the `linkerd-proxy-injector-k8s-tls` secret exists and contains the
appropriate `tls.crt` and `tls.key` data entries. For versions before 2.9, the
secret is named `linkerd-proxy-injector-tls` and it should contain the `crt.pem`
and `key.pem` data entries.

```bash
× proxy-injector webhook has valid cert
    cert is not issued by the trust anchor: x509: certificate is valid for xxxxxx, not linkerd-proxy-injector.linkerd.svc
    see https://linkerd.io/2/checks/#l5d-proxy-injector-webhook-cert-valid for hints
```

Here you need to make sure the certificate was issued specifically for
`linkerd-proxy-injector.linkerd.svc`.

### √ proxy-injector cert is valid for at least 60 days {#l5d-proxy-injector-webhook-cert-not-expiring-soon}

Example failure:

```bash
‼ proxy-injector cert is valid for at least 60 days
    certificate will expire on 2020-11-07T17:00:07Z
    see https://linkerd.io/2/checks/#l5d-webhook-cert-not-expiring-soon for hints
```

This warning indicates that the expiry of proxy-injnector webhook
cert is approaching. In order to address this
problem without incurring downtime, you can follow the process outlined in
[Automatically Rotating your webhook TLS Credentials](../automatically-rotating-webhook-tls-credentials/).

### √ sp-validator webhook has valid cert {#l5d-sp-validator-webhook-cert-valid}

Example failure:

```bash
× sp-validator webhook has valid cert
    secrets "linkerd-sp-validator-tls" not found
    see https://linkerd.io/2/checks/#l5d-sp-validator-webhook-cert-valid for hints
```

Ensure that the `linkerd-sp-validator-k8s-tls` secret exists and contains the
appropriate `tls.crt` and `tls.key` data entries. For versions before 2.9, the
secret is named `linkerd-sp-validator-tls` and it should contain the `crt.pem`
and `key.pem` data entries.

```bash
× sp-validator webhook has valid cert
    cert is not issued by the trust anchor: x509: certificate is valid for xxxxxx, not linkerd-sp-validator.linkerd.svc
    see https://linkerd.io/2/checks/#l5d-sp-validator-webhook-cert-valid for hints
```

Here you need to make sure the certificate was issued specifically for
`linkerd-sp-validator.linkerd.svc`.

### √ sp-validator cert is valid for at least 60 days {#l5d-sp-validator-webhook-cert-not-expiring-soon}

Example failure:

```bash
‼ sp-validator cert is valid for at least 60 days
    certificate will expire on 2020-11-07T17:00:07Z
    see https://linkerd.io/2/checks/#l5d-webhook-cert-not-expiring-soon for hints
```

This warning indicates that the expiry of sp-validator webhook
cert is approaching. In order to address this
problem without incurring downtime, you can follow the process outlined in
[Automatically Rotating your webhook TLS Credentials](../automatically-rotating-webhook-tls-credentials/).

## The "linkerd-identity-data-plane" checks {#l5d-identity-data-plane}

### √ data plane proxies certificate match CA {#l5d-identity-data-plane-proxies-certs-match-ca}

Example warning:

```bash
‼ data plane proxies certificate match CA
    Some pods do not have the current trust bundle and must be restarted:
        * emojivoto/emoji-d8d7d9c6b-8qwfx
        * emojivoto/vote-bot-588499c9f6-zpwz6
        * emojivoto/voting-8599548fdc-6v64k
    see https://linkerd.io/2/checks/{#l5d-identity-data-plane-proxies-certs-match-ca for hints
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
        * linkerd-viz/tap-68d8bbf64-mpzgb
        * linkerd-viz/web-849f74b7c6-qlhwc
    see https://linkerd.io/2/checks/{#l5d-identity-data-plane-proxies-certs-match-ca for hints
```

If that is the case, simply wait for the `upgrade` operation to complete. The
stale pods should terminate and be replaced by new ones, configured with the
correct certificates.

## The "linkerd-api" checks {#l5d-api}

### √ control plane pods are ready {#l5d-api-control-ready}

Example failure:

```bash
× control plane pods are ready
    No running pods for "linkerd-sp-validator"
```

Verify the state of the control plane pods with:

```bash
$ kubectl -n linkerd get po
NAME                                      READY   STATUS    RESTARTS   AGE
linkerd-destination-5fd7b5d466-szgqm      2/2     Running   1          12m
linkerd-identity-54df78c479-hbh5m         2/2     Running   0          12m
linkerd-proxy-injector-67f8cf65f7-4tvt5   2/2     Running   1          12m
```

### √ can initialize the client {#l5d-api-control-client}

Example failure:

```bash
× can initialize the client
    parse http:// bad/: invalid character " " in host name
```

Verify that a well-formed `--api-addr` parameter was specified, if any:

```bash
linkerd check --api-addr " bad"
```

### √ can query the control plane API {#l5d-api-control-api}

Example failure:

```bash
× can query the control plane API
    Post http://8.8.8.8/api/v1/Version: context deadline exceeded
```

This check indicates a connectivity failure between the cli and the Linkerd
control plane. To verify connectivity, manually connect to a control plane pod:

```bash
kubectl -n linkerd port-forward \
    $(kubectl -n linkerd get po \
        --selector=linkerd.io/control-plane-component=identity \
        -o jsonpath='{.items[*].metadata.name}') \
9995:9995
```

...and then curl the `/metrics` endpoint:

```bash
curl localhost:9995/metrics
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

See the page on [Upgrading Linkerd](../upgrade/).

## The "control-plane-version" checks {#l5d-version-control}

Example failures:

```bash
‼ control plane is up-to-date
    is running version 19.1.1 but the latest edge version is 19.1.2
‼ control plane and cli versions match
    mismatched channels: running stable-2.1.0 but retrieved edge-19.1.2
```

See the page on [Upgrading Linkerd](../upgrade/).

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
    Data plane metrics not found for linkerd/linkerd-identity-b8c4c48c8-pflc9.
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

See the page on [Upgrading Linkerd](../upgrade/).

### √ data plane and cli versions match {#l5d-data-plane-cli-version}

```bash
‼ data plane and cli versions match
    linkerd/linkerd-identity-5f6c45d6d9-9hd9j: is running version 19.1.2 but the latest edge version is 19.1.3
```

See the page on [Upgrading Linkerd](../upgrade/).

### √ data plane pod labels are configured correctly {#l5d-data-plane-pod-labels}

Example failure:

```bash
‼ data plane pod labels are configured correctly
    Some labels on data plane pods should be annotations:
    * emojivoto/voting-ff4c54b8d-tv9pp
        linkerd.io/inject
```

`linkerd.io/inject`, `config.linkerd.io/*` or `config.alpha.linkerd.io/*` should
be annotations in order to take effect.

### √ data plane service labels are configured correctly {#l5d-data-plane-services-labels}

Example failure:

```bash
‼ data plane service labels and annotations are configured correctly
    Some labels on data plane services should be annotations:
    * emojivoto/emoji-svc
        config.linkerd.io/control-port
```

`config.linkerd.io/*` or `config.alpha.linkerd.io/*` should
be annotations in order to take effect.

### √ data plane service annotations are configured correctly {#l5d-data-plane-services-annotations}

Example failure:

```bash
‼ data plane service annotations are configured correctly
    Some annotations on data plane services should be labels:
    * emojivoto/emoji-svc
        mirror.linkerd.io/exported
```

`mirror.linkerd.io/exported` should
be a label in order to take effect.

## The "linkerd-ha-checks" checks {#l5d-ha}

These checks are ran if Linkerd has been installed in HA mode.

### √ pod injection disabled on kube-system {#l5d-injection-disabled}

Example warning:

```bash
‼ pod injection disabled on kube-system
    kube-system namespace needs to have the label config.linkerd.io/admission-webhooks: disabled if HA mode is enabled
    see https://linkerd.io/2/checks/#l5d-injection-disabled for hints
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
    not enough replicas available for [linkerd-identity]
    see https://linkerd.io/2/checks/#l5d-control-plane-replicas for hints
```

This happens when one of the control plane pods doesn't have at least two
replicas running. This is likely caused by insufficient node resources.

### The "extensions" checks {#extensions}

When any [Extensions](../extensions/) are installed, The Linkerd binary
tries to invoke `check --output json` on the extension binaries.
It is important that the extension binaries implement it.
For more information, See [Extension
developer docs](https://github.com/linkerd/linkerd2/blob/main/EXTENSIONS.md)

Example error:

```bash
invalid extension check output from \"jaeger\" (JSON object expected)
```

Make sure that the extension binary implements `check --output json`
which returns the healthchecks in the [expected json format](https://github.com/linkerd/linkerd2/blob/main/EXTENSIONS.md#linkerd-name-check).

Example error:

```bash
× Linkerd command jaeger exists
```

Make sure that relevant binary exists in `$PATH`.

For more information about Linkerd extensions. See
[Extension developer docs](https://github.com/linkerd/linkerd2/blob/main/EXTENSIONS.md)

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
    see https://linkerd.io/2/checks/#cni-plugin-cm-exists for hints
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
    see https://linkerd.io/2/checks/#cni-plugin-psp-exists for hint
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
    see https://linkerd.io/2/checks/#cni-plugin-cr-exists for hints
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
    see https://linkerd.io/2/checks/#cni-plugin-crb-exists for hints
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
    see https://linkerd.io/2/checks/#cni-plugin-r-exists for hints
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
    see https://linkerd.io/2/checks/#cni-plugin-rb-exists for hints
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
    see https://linkerd.io/2/checks/#cni-plugin-sa-exists for hints
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
    see https://linkerd.io/2/checks/#cni-plugin-ds-exists for hints
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
    see https://linkerd.io/2/checks/#cni-plugin-ready
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
Additionally they can be ran with `linkerd multicluster check`.
Most of these checks verify that the service mirroring controllers are working
correctly along with remote gateways. Furthermore the checks ensure that
end to end TLS is possible between paired clusters.

### √ Link CRD exists {#l5d-multicluster-link-crd-exists}

Example error:

```bash
× Link CRD exists
    multicluster.linkerd.io/Link CRD is missing
    see https://linkerd.io/2/checks/#l5d-multicluster-link-crd-exists for hints
```

Make sure multicluster extension is correctly installed and that the
`links.multicluster.linkerd.io` CRD is present.

```bash
$ kubectll get crds | grep multicluster
NAME                              CREATED AT
links.multicluster.linkerd.io     2021-03-10T09:58:10Z
```

### √ Link resources are valid {#l5d-multicluster-links-are-valid}

Example error:

```bash
× Link resources are valid
    failed to parse Link east
    see https://linkerd.io/2/checks/#l5d-multicluster-links-are-valid for hints
```

Make sure all the link objects are specified in the expected format.

### √ remote cluster access credentials are valid {#l5d-smc-target-clusters-access}

Example error:

```bash
× remote cluster access credentials are valid
    * secret [east/east-config]: could not find east-config secret
    see https://linkerd.io/2/checks/#l5d-smc-target-clusters-access for hints
```

Make sure the relevant Kube-config with relevant permissions.
for the specific target cluster is present as a secret correctly

### √ clusters share trust anchors {#l5d-multicluster-clusters-share-anchors}

Example errors:

```bash
× clusters share trust anchors
    Problematic clusters:
        * remote
    see https://linkerd.io/2/checks/#l5d-multicluster-clusters-share-anchors for hints
```

The error above indicates that your trust anchors are not compatible. In order
to fix that you need to ensure that both your anchors contain identical sets of
certificates.

```bash
× clusters share trust anchors
    Problematic clusters:
        * remote: cannot parse trust anchors
    see https://linkerd.io/2/checks/#l5d-multicluster-clusters-share-anchors for hints
```

Such an error indicates that there is a problem with your anchors on the cluster
named `remote` You need to make sure the identity config aspect of your Linkerd
installation on the `remote` cluster is ok. You can run `check` against the
remote cluster to verify that:

```bash
linkerd --context=remote check
```

### √ service mirror controller has required permissions {#l5d-multicluster-source-rbac-correct}

Example error:

```bash
× service mirror controller has required permissions
    missing Service mirror ClusterRole linkerd-service-mirror-access-local-resources: unexpected verbs expected create,delete,get,list,update,watch, got create,delete,get,update,watch
    see https://linkerd.io/2/checks/#l5d-multicluster-source-rbac-correct for hints
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

### √ service mirror controllers are running {#l5d-multicluster-service-mirror-running}

Example error:

```bash
× service mirror controllers are running
    Service mirror controller is not present
    see https://linkerd.io/2/checks/#l5d-multicluster-service-mirror-running for hints
```

Note, it takes a little bit for pods to be scheduled, images to be pulled and
everything to start up. If this is a permanent error, you'll want to validate
the state of the controller pod with:

```bash
$ kubectl --all-namespaces get po --selector linkerd.io/control-plane-component=linkerd-service-mirror
NAME                                  READY     STATUS    RESTARTS   AGE
linkerd-service-mirror-7bb8ff5967-zg265   2/2       Running   0          50m
```

### √ all gateway mirrors are healthy {#l5d-multicluster-gateways-endpoints}

Example errors:

```bash
‼ all gateway mirrors are healthy
    Some gateway mirrors do not have endpoints:
  linkerd-gateway-gke.linkerd-multicluster mirrored from cluster [gke]
    see https://linkerd.io/2/checks/#l5d-multicluster-gateways-endpoints for hints
```

The error above indicates that some gateway mirror services in the source
cluster do not have associated endpoints resources. These endpoints are created
by the Linkerd service mirror controller on the source cluster whenever a link
is established with a target cluster.

Such an error indicates that there could be a problem with the creation of the
resources by the service mirror controller or the external IP of the gateway
service in target cluster.

### √ all mirror services have endpoints {#l5d-multicluster-services-endpoints}

Example errors:

```bash
‼ all mirror services have endpoints
    Some mirror services do not have endpoints:
  voting-svc-gke.emojivoto mirrored from cluster [gke] (gateway: [linkerd-multicluster/linkerd-gateway])
    see https://linkerd.io/2/checks/#l5d-multicluster-services-endpoints for hints
```

The error above indicates that some mirror services in the source cluster do not
have associated endpoints resources. These endpoints are created by the Linkerd
service mirror controller when creating a mirror service with endpoints values
as the remote gateway's external IP.

Such an error indicates that there could be a problem with the creation of the
mirror resources by the service mirror controller or the mirror gateway service
in the source cluster or the external IP of the gateway service in target
cluster.

### √ all mirror services are part of a Link {#l5d-multicluster-orphaned-services}

Example errors:

```bash
‼  all mirror services are part of a Link
    mirror service voting-east.emojivoto is not part of any Link
    see https://linkerd.io/2/checks/#l5d-multicluster-orphaned-services for hints
```

The error above indicates that some mirror services in the source cluster do not
have associated link. These mirror services are created by the Linkerd
service mirror controller when a remote service is marked to be
mirrored.

Make sure services are marked to be mirrored correctly at remote, and delete
if there are any unnecessary ones.

## The "linkerd-viz" checks {#l5d-viz}

These checks only run when the `linkerd-viz` extension is installed.
This check is intended to verify the installation of linkerd-viz
extension which comprises of `tap`, `web`,
`metrics-api` and optional `grafana` and `prometheus` instances
along with `tap-injector` which injects the specific
tap configuration to the proxies.

### √ linkerd-viz Namespace exists {#l5d-viz-ns-exists}

This is the basic check used to verify if the linkerd-viz extension
namespace is installed or not. The extension can be installed by running
the following command:

```bash
linkerd viz install | kubectl apply -f -
```

The installation can be configured by using the
`--set`, `--values`, `--set-string` and `--set-file` flags.
See [Linkerd Viz Readme](https://www.github.com/linkerd/linkerd2/tree/main/viz/charts/linkerd-viz/README.md)
for a full list of configurable fields.

### √ linkerd-viz ClusterRoles exist {#l5d-viz-cr-exists}

Example failure:

```bash
× linkerd-viz ClusterRoles exist
    missing ClusterRoles: linkerd-linkerd-viz-metrics-api
    see https://linkerd.io/2/checks/#l5d-viz-cr-exists for hints
```

Ensure the linkerd-viz extension ClusterRoles exist:

```bash
$ kubectl get clusterroles | grep linkerd-viz
linkerd-linkerd-viz-metrics-api                                        2021-01-26T18:02:17Z
linkerd-linkerd-viz-prometheus                                         2021-01-26T18:02:17Z
linkerd-linkerd-viz-tap                                                2021-01-26T18:02:17Z
linkerd-linkerd-viz-tap-admin                                          2021-01-26T18:02:17Z
linkerd-linkerd-viz-web-check                                          2021-01-26T18:02:18Z
```

Also ensure you have permission to create ClusterRoles:

```bash
$ kubectl auth can-i create clusterroles
yes
```

### √ linkerd-viz ClusterRoleBindings exist {#l5d-viz-crb-exists}

Example failure:

```bash
× linkerd-viz ClusterRoleBindings exist
    missing ClusterRoleBindings: linkerd-linkerd-viz-metrics-api
    see https://linkerd.io/2/checks/#l5d-viz-crb-exists for hints
```

Ensure the linkerd-viz extension ClusterRoleBindings exist:

```bash
$ kubectl get clusterrolebindings | grep linkerd-viz
linkerd-linkerd-viz-metrics-api                        ClusterRole/linkerd-linkerd-viz-metrics-api                                        18h
linkerd-linkerd-viz-prometheus                         ClusterRole/linkerd-linkerd-viz-prometheus                                         18h
linkerd-linkerd-viz-tap                                ClusterRole/linkerd-linkerd-viz-tap                                                18h
linkerd-linkerd-viz-tap-auth-delegator                 ClusterRole/system:auth-delegator                                                  18h
linkerd-linkerd-viz-web-admin                          ClusterRole/linkerd-linkerd-viz-tap-admin                                          18h
linkerd-linkerd-viz-web-check                          ClusterRole/linkerd-linkerd-viz-web-check                                          18h
```

Also ensure you have permission to create ClusterRoleBindings:

```bash
$ kubectl auth can-i create clusterrolebindings
yes
```

### √ tap API server has valid cert {#l5d-tap-cert-valid}

Example failure:

```bash
× tap API server has valid cert
    secrets "tap-k8s-tls" not found
    see https://linkerd.io/2/checks/#l5d-tap-cert-valid for hints
```

Ensure that the `tap-k8s-tls` secret exists and contains the appropriate
`tls.crt` and `tls.key` data entries. For versions before 2.9, the secret is
named `linkerd-tap-tls` and it should contain the `crt.pem` and `key.pem` data
entries.

```bash
× tap API server has valid cert
    cert is not issued by the trust anchor: x509: certificate is valid for xxxxxx, not tap.linkerd-viz.svc
    see https://linkerd.io/2/checks/#l5d-tap-cert-valid for hints
```

Here you need to make sure the certificate was issued specifically for
`tap.linkerd-viz.svc`.

### √ tap API server cert is valid for at least 60 days {#l5d-tap-cert-not-expiring-soon}

Example failure:

```bash
‼ tap API server cert is valid for at least 60 days
    certificate will expire on 2020-11-07T17:00:07Z
    see https://linkerd.io/2/checks/#l5d-webhook-cert-not-expiring-soon for hints
```

This warning indicates that the expiry of the tap API Server webhook
cert is approaching. In order to address this
problem without incurring downtime, you can follow the process outlined in
[Automatically Rotating your webhook TLS Credentials](../automatically-rotating-webhook-tls-credentials/).

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

### √ linkerd-viz pods are injected {#l5d-viz-pods-injection}

```bash
× linkerd-viz extension pods are injected
    could not find proxy container for tap-59f5595fc7-ttndp pod
    see https://linkerd.io/2/checks/#l5d-viz-pods-injection for hints
```

Ensure all the linkerd-viz pods are injected

```bash
$ kubectl -n linkerd-viz get pods
NAME                                   READY   STATUS    RESTARTS   AGE
grafana-68cddd7cc8-nrv4h       2/2     Running   3          18h
metrics-api-77f684f7c7-hnw8r   2/2     Running   2          18h
prometheus-5f6898ff8b-s6rjc    2/2     Running   2          18h
tap-59f5595fc7-ttndp           2/2     Running   2          18h
web-78d6588d4-pn299            2/2     Running   2          18h
tap-injector-566f7ff8df-vpcwc          2/2     Running   2          18h
```

Make sure that the `proxy-injector` is working correctly by running
`linkerd check`

### √ viz extension pods are running {#l5d-viz-pods-running}

```bash
× viz extension pods are running
    container linkerd-proxy in pod tap-59f5595fc7-ttndp is not ready
    see https://linkerd.io/2/checks/#l5d-viz-pods-running for hints
```

Ensure all the linkerd-viz pods are running with 2/2

```bash
$ kubectl -n linkerd-viz get pods
NAME                                   READY   STATUS    RESTARTS   AGE
grafana-68cddd7cc8-nrv4h               2/2     Running   3          18h
metrics-api-77f684f7c7-hnw8r           2/2     Running   2          18h
prometheus-5f6898ff8b-s6rjc            2/2     Running   2          18h
tap-59f5595fc7-ttndp                   2/2     Running   2          18h
web-78d6588d4-pn299                    2/2     Running   2          18h
tap-injector-566f7ff8df-vpcwc          2/2     Running   2          18h
```

Make sure that the `proxy-injector` is working correctly by running
`linkerd check`

### √ prometheus is installed and configured correctly {#l5d-viz-prometheus}

```bash
× prometheus is installed and configured correctly
    missing ClusterRoles: linkerd-linkerd-viz-prometheus
    see https://linkerd.io/2/checks/#l5d-viz-cr-exists for hints
```

Ensure all the prometheus related resources are present and running
correctly.

```bash
❯ kubectl -n linkerd-viz get deploy,cm | grep prometheus
deployment.apps/prometheus     1/1     1            1           3m18s
configmap/prometheus-config   1      3m18s
❯ kubectl get clusterRoleBindings | grep prometheus
linkerd-linkerd-viz-prometheus                         ClusterRole/linkerd-linkerd-viz-prometheus                         3m37s
❯ kubectl get clusterRoles | grep prometheus
linkerd-linkerd-viz-prometheus                                         2021-02-26T06:03:11Zh
```

### √ can initialize the client {#l5d-viz-existence-client}

Example failure:

```bash
× can initialize the client
    Failed to get deploy for pod metrics-api-77f684f7c7-hnw8r: not running
```

Verify that the metrics API pod is running correctly

```bash
❯ kubectl -n linkerd-viz get pods
NAME                           READY   STATUS    RESTARTS   AGE
metrics-api-7bb8cb8489-cbq4m   2/2     Running   0          4m58s
tap-injector-6b9bc6fc4-cgbr4   2/2     Running   0          4m56s
tap-5f6ddcc684-k2fd6           2/2     Running   0          4m57s
web-cbb846484-d987n            2/2     Running   0          4m56s
grafana-76fd8765f4-9rg8q       2/2     Running   0          4m58s
prometheus-7c5c48c466-jc27g    2/2     Running   0          4m58s
```

### √ viz extension self-check {#l5d-viz-metrics-api}

Example failure:

```bash
× viz extension self-check
    No results returned
```

Check the logs on the viz extensions's metrics API:

```bash
kubectl -n linkerd-viz logs deploy/metrics-api metrics-api
```

## The "linkerd-jaeger" checks {#l5d-jaeger}

These checks only run when the `linkerd-jaeger` extension is installed.
This check is intended to verify the installation of linkerd-jaeger
extension which comprises of open-census collector and jaeger
components along with `jaeger-injector` which injects the specific
trace configuration to the proxies.

### √ linkerd-jaeger extension Namespace exists {#l5d-jaeger-ns-exists}

This is the basic check used to verify if the linkerd-jaeger extension
namespace is installed or not. The extension can be installed by running
the following command

```bash
linkerd jaeger install | kubectl apply -f -
```

The installation can be configured by using the
`--set`, `--values`, `--set-string` and `--set-file` flags.
See [Linkerd Jaeger Readme](https://www.github.com/linkerd/linkerd2/tree/main/jaeger/charts/linkerd-jaeger/README.md)
for a full list of configurable fields.

### √ collector and jaeger service account exists {#l5d-jaeger-sc-exists}

Example failure:

```bash
× collector and jaeger service account exists
    missing ServiceAccounts: collector
    see https://linkerd.io/2/checks/#l5d-jaeger-sc-exists for hints
```

Ensure the linkerd-jaeger ServiceAccounts exist:

```bash
$ kubectl -n linkerd-jaeger get serviceaccounts
NAME               SECRETS   AGE
collector          1         23m
jaeger             1         23m
```

Also ensure you have permission to create ServiceAccounts in the linkerd-jaeger
namespace:

```bash
$ kubectl -n linkerd-jaeger auth can-i create serviceaccounts
yes
```

### √ collector config map exists {#l5d-jaeger-oc-cm-exists}

Example failure:

```bash
× collector config map exists
    missing ConfigMaps: collector-config
    see https://linkerd.io/2/checks/#l5d-jaeger-oc-cm-exists for hints
```

Ensure the Linkerd ConfigMap exists:

```bash
$ kubectl -n linkerd-jaeger get configmap/collector-config
NAME             DATA   AGE
collector-config   1      61m
```

Also ensure you have permission to create ConfigMaps:

```bash
$ kubectl -n linkerd-jaeger auth can-i create configmap
yes
```

### √ jaeger extension pods are injected {#l5d-jaeger-pods-injection}

```bash
× jaeger extension pods are injected
    could not find proxy container for jaeger-6f98d5c979-scqlq pod
    see https://linkerd.io/2/checks/#l5d-jaeger-pods-injections for hints
```

Ensure all the jaeger pods are injected

```bash
$ kubectl -n linkerd-jaeger get pods
NAME                               READY   STATUS      RESTARTS   AGE
collector-69cc44dfbc-rhpfg         2/2     Running     0          11s
jaeger-6f98d5c979-scqlq            2/2     Running     0          11s
jaeger-injector-6c594f5577-cz75h   2/2     Running     0          10s
```

Make sure that the `proxy-injector` is working correctly by running
`linkerd check`

### √ jaeger extension pods are running {#l5d-jaeger-pods-running}

```bash
× jaeger extension pods are running
    container linkerd-proxy in pod jaeger-59f5595fc7-ttndp is not ready
    see https://linkerd.io/2/checks/#l5d-jaeger-pods-running for hints
```

Ensure all the linkerd-jaeger pods are running with 2/2

```bash
$ kubectl -n linkerd-jaeger get pods
NAME                               READY   STATUS   RESTARTS   AGE
jaeger-injector-548684d74b-bcq5h   2/2     Running   0          5s
collector-69cc44dfbc-wqf6s         2/2     Running   0          5s
jaeger-6f98d5c979-vs622            2/2     Running   0          5sh
```

Make sure that the `proxy-injector` is working correctly by running
`linkerd check`

## The "linkerd-buoyant" checks {#l5d-buoyant}

These checks only run when the `linkerd-buoyant` extension is installed.
This check is intended to verify the installation of linkerd-buoyant
extension which comprises `linkerd-buoyant` CLI, the `buoyant-cloud-agent`
Deployment, and the `buoyant-cloud-metrics` DaemonSet.

### √ Linkerd extension command linkerd-buoyant exists

```bash
‼ Linkerd extension command linkerd-buoyant exists
    exec: "linkerd-buoyant": executable file not found in $PATH
    see https://linkerd.io/2/checks/#extensions for hints
```

Ensure you have the `linkerd-buoyant` cli installed:

```bash
linkerd-buoyant check
```

To install the CLI:

```bash
curl --proto '=https' --tlsv1.2 -sSfL https://buoyant.cloud/install | sh
```

### √ linkerd-buoyant can determine the latest version

```bash
‼ linkerd-buoyant can determine the latest version
    Get "https://buoyant.cloud/version.json": dial tcp: lookup buoyant.cloud: no such host
    see https://linkerd.io/checks#l5d-buoyant for hints
```

Ensure you can connect to the Linkerd Buoyant version check endpoint from the
environment the `linkerd` cli is running:

```bash
$ curl --proto '=https' --tlsv1.2 -sSfL https://buoyant.cloud/version.json
{"linkerd-buoyant":"v0.4.4"}
```

### √ linkerd-buoyant cli is up-to-date

```bash
‼ linkerd-buoyant cli is up-to-date
    CLI version is v0.4.3 but the latest is v0.4.4
    see https://linkerd.io/checks#l5d-buoyant for hints
```

To update to the latest version of the `linkerd-buoyant` CLI:

```bash
curl --proto '=https' --tlsv1.2 -sSfL https://buoyant.cloud/install | sh
```

### √ buoyant-cloud Namespace exists

```bash
× buoyant-cloud Namespace exists
    namespaces "buoyant-cloud" not found
    see https://linkerd.io/checks#l5d-buoyant for hints
```

Ensure the `buoyant-cloud` namespace exists:

```bash
kubectl get ns/buoyant-cloud
```

If the namespace does not exist, the `linkerd-buoyant` installation may be
missing or incomplete. To install the extension:

```bash
linkerd-buoyant install | kubectl apply -f -
```

### √ buoyant-cloud Namespace has correct labels

```bash
× buoyant-cloud Namespace has correct labels
    missing app.kubernetes.io/part-of label
    see https://linkerd.io/checks#l5d-buoyant for hints
```

The `linkerd-buoyant` installation may be missing or incomplete. To install the
extension:

```bash
linkerd-buoyant install | kubectl apply -f -
```

### √ buoyant-cloud-agent ClusterRole exists

```bash
× buoyant-cloud-agent ClusterRole exists
    missing ClusterRole: buoyant-cloud-agent
    see https://linkerd.io/checks#l5d-buoyant for hints
```

Ensure that the cluster role exists:

```bash
$ kubectl get clusterrole buoyant-cloud-agent
NAME                  CREATED AT
buoyant-cloud-agent   2020-11-13T00:59:50Z
```

Also ensure you have permission to create ClusterRoles:

```bash
$ kubectl auth can-i create ClusterRoles
yes
```

### √ buoyant-cloud-agent ClusterRoleBinding exists

```bash
× buoyant-cloud-agent ClusterRoleBinding exists
    missing ClusterRoleBinding: buoyant-cloud-agent
    see https://linkerd.io/checks#l5d-buoyant for hints
```

Ensure that the cluster role binding exists:

```bash
$ kubectl get clusterrolebinding buoyant-cloud-agent
NAME                  ROLE                              AGE
buoyant-cloud-agent   ClusterRole/buoyant-cloud-agent   301d
```

Also ensure you have permission to create ClusterRoleBindings:

```bash
$ kubectl auth can-i create ClusterRoleBindings
yes
```

### √ buoyant-cloud-agent ServiceAccount exists

```bash
× buoyant-cloud-agent ServiceAccount exists
    missing ServiceAccount: buoyant-cloud-agent
    see https://linkerd.io/checks#l5d-buoyant for hints
```

Ensure that the service account exists:

```bash
$ kubectl -n buoyant-cloud get serviceaccount buoyant-cloud-agent
NAME                  SECRETS   AGE
buoyant-cloud-agent   1         301d
```

Also ensure you have permission to create ServiceAccounts:

```bash
$ kubectl -n buoyant-cloud auth can-i create ServiceAccount
yes
```

### √ buoyant-cloud-id Secret exists

```bash
× buoyant-cloud-id Secret exists
    missing Secret: buoyant-cloud-id
    see https://linkerd.io/checks#l5d-buoyant for hints
```

Ensure that the secret exists:

```bash
$ kubectl -n buoyant-cloud get secret buoyant-cloud-id
NAME               TYPE     DATA   AGE
buoyant-cloud-id   Opaque   4      301d
```

Also ensure you have permission to create ServiceAccounts:

```bash
$ kubectl -n buoyant-cloud auth can-i create ServiceAccount
yes
```

### √ buoyant-cloud-agent Deployment exists

```bash
× buoyant-cloud-agent Deployment exists
    deployments.apps "buoyant-cloud-agent" not found
    see https://linkerd.io/checks#l5d-buoyant for hints
```

Ensure the `buoyant-cloud-agent` Deployment exists:

```bash
kubectl -n buoyant-cloud get deploy/buoyant-cloud-agent
```

If the Deployment does not exist, the `linkerd-buoyant` installation may be
missing or incomplete. To reinstall the extension:

```bash
linkerd-buoyant install | kubectl apply -f -
```

### √ buoyant-cloud-agent Deployment is running

```bash
× buoyant-cloud-agent Deployment is running
    no running pods for buoyant-cloud-agent Deployment
    see https://linkerd.io/checks#l5d-buoyant for hints
```

Note, it takes a little bit for pods to be scheduled, images to be pulled and
everything to start up. If this is a permanent error, you'll want to validate
the state of the `buoyant-cloud-agent` Deployment with:

```bash
$ kubectl -n buoyant-cloud get po --selector app=buoyant-cloud-agent
NAME                                   READY   STATUS    RESTARTS   AGE
buoyant-cloud-agent-6b8c6888d7-htr7d   2/2     Running   0          156m
```

Check the agent's logs with:

```bash
kubectl logs -n buoyant-cloud buoyant-cloud-agent-6b8c6888d7-htr7d buoyant-cloud-agent
```

### √ buoyant-cloud-agent Deployment is injected

```bash
× buoyant-cloud-agent Deployment is injected
    could not find proxy container for buoyant-cloud-agent-6b8c6888d7-htr7d pod
    see https://linkerd.io/checks#l5d-buoyant for hints
```

Ensure the `buoyant-cloud-agent` pod is injected, the `READY` column should show
`2/2`:

```bash
$ kubectl -n buoyant-cloud get pods --selector app=buoyant-cloud-agent
NAME                                   READY   STATUS    RESTARTS   AGE
buoyant-cloud-agent-6b8c6888d7-htr7d   2/2     Running   0          161m
```

Make sure that the `proxy-injector` is working correctly by running
`linkerd check`.

### √ buoyant-cloud-agent Deployment is up-to-date

```bash
‼ buoyant-cloud-agent Deployment is up-to-date
    incorrect app.kubernetes.io/version label: v0.4.3, expected: v0.4.4
    see https://linkerd.io/checks#l5d-buoyant for hints
```

Check the version with:

```bash
$ linkerd-buoyant version
CLI version:   v0.4.4
Agent version: v0.4.4
```

To update to the latest version:

```bash
linkerd-buoyant install | kubectl apply -f -
```

### √ buoyant-cloud-agent Deployment is running a single pod

```bash
× buoyant-cloud-agent Deployment is running a single pod
    expected 1 buoyant-cloud-agent pod, found 2
    see https://linkerd.io/checks#l5d-buoyant for hints
```

`buoyant-cloud-agent` should run as a singleton. Check for other pods:

```bash
kubectl get po -A --selector app=buoyant-cloud-agent
```

### √ buoyant-cloud-metrics DaemonSet exists

```bash
× buoyant-cloud-metrics DaemonSet exists
    deployments.apps "buoyant-cloud-metrics" not found
    see https://linkerd.io/checks#l5d-buoyant for hints
```

Ensure the `buoyant-cloud-metrics` DaemonSet exists:

```bash
kubectl -n buoyant-cloud get daemonset/buoyant-cloud-metrics
```

If the DaemonSet does not exist, the `linkerd-buoyant` installation may be
missing or incomplete. To reinstall the extension:

```bash
linkerd-buoyant install | kubectl apply -f -
```

### √ buoyant-cloud-metrics DaemonSet is running

```bash
× buoyant-cloud-metrics DaemonSet is running
    no running pods for buoyant-cloud-metrics DaemonSet
    see https://linkerd.io/checks#l5d-buoyant for hints
```

Note, it takes a little bit for pods to be scheduled, images to be pulled and
everything to start up. If this is a permanent error, you'll want to validate
the state of the `buoyant-cloud-metrics` DaemonSet with:

```bash
$ kubectl -n buoyant-cloud get po --selector app=buoyant-cloud-metrics
NAME                          READY   STATUS    RESTARTS   AGE
buoyant-cloud-metrics-kt9mv   2/2     Running   0          163m
buoyant-cloud-metrics-q8jhj   2/2     Running   0          163m
buoyant-cloud-metrics-qtflh   2/2     Running   0          164m
buoyant-cloud-metrics-wqs4k   2/2     Running   0          163m
```

Check the agent's logs with:

```bash
kubectl logs -n buoyant-cloud buoyant-cloud-metrics-kt9mv buoyant-cloud-metrics
```

### √ buoyant-cloud-metrics DaemonSet is injected

```bash
× buoyant-cloud-metrics DaemonSet is injected
    could not find proxy container for buoyant-cloud-agent-6b8c6888d7-htr7d pod
    see https://linkerd.io/checks#l5d-buoyant for hints
```

Ensure the `buoyant-cloud-metrics` pods are injected, the `READY` column should
show `2/2`:

```bash
$ kubectl -n buoyant-cloud get pods --selector app=buoyant-cloud-metrics
NAME                          READY   STATUS    RESTARTS   AGE
buoyant-cloud-metrics-kt9mv   2/2     Running   0          166m
buoyant-cloud-metrics-q8jhj   2/2     Running   0          166m
buoyant-cloud-metrics-qtflh   2/2     Running   0          166m
buoyant-cloud-metrics-wqs4k   2/2     Running   0          166m
```

Make sure that the `proxy-injector` is working correctly by running
`linkerd check`.

### √ buoyant-cloud-metrics DaemonSet is up-to-date

```bash
‼ buoyant-cloud-metrics DaemonSet is up-to-date
    incorrect app.kubernetes.io/version label: v0.4.3, expected: v0.4.4
    see https://linkerd.io/checks#l5d-buoyant for hints
```

Check the version with:

```bash
$ kubectl -n buoyant-cloud get daemonset/buoyant-cloud-metrics -o jsonpath='{.metadata.labels}'
{"app.kubernetes.io/name":"metrics","app.kubernetes.io/part-of":"buoyant-cloud","app.kubernetes.io/version":"v0.4.4"}
```

To update to the latest version:

```bash
linkerd-buoyant install | kubectl apply -f -
```
