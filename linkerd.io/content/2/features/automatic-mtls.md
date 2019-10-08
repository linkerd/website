+++
title = "Automatic mTLS"
description = "Linkerd automatically enables mutual Transport Layer Security (TLS) for all communication between meshed applications."
weight = 4
aliases = [
  "/2/features/automatic-tls"
]
+++

By default, Linkerd automatically enables mutual Transport Layer Security
(mTLS) for most HTTP-based communication between meshed pods, by establishing
and authenticating secure, private TLS connections between Linkerd proxies.
Because the Linkerd control plane also runs on the data plane, this means that
communication between control plane components are also automatically secured
via mTLS.

(See "Caveats and future work" below for details on which traffic cannot be
automatically encrypted.)

{{< note >}}
Linkerd uses Kubernetes *Service Accounts* to define service identity. This
requires that the `automountServiceAccountToken` feature (on by default) is
enabled. See the [Kubernetes service account
documentation](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/)
for more.
{{< /note >}}

Once your service has been added, you can validate that mTLS is enabled by
following the [guide to securing your services with
Linkerd](/2/tasks/securing-your-service/).

## How does it work?

On install, a trust root, certificate and private key are generated. The trust
root is stored as a [Kubernetes
ConfigMap](https://unofficial-kubernetes.readthedocs.io/en/latest/tasks/configure-pod-container/configmap/).
This is used to verify the identity of any proxy. (Alternatively, Linkerd can
use a trust root of your choosing; see the [`linkerd install` reference
documentation](/2/reference/cli/install/).) Both certificate and private key
are placed into a [Kubernetes
Secret](https://kubernetes.io/docs/concepts/configuration/secret/). It is
important that this secret stays private and other service accounts in the
cluster do not have access. By default, the Secret is placed in the `linkerd`
namespace and can only be read by the service account used by the [Linkerd
control plane](/2/reference/architecture/)'s `identity` component.

On startup, the proxy generates a private key for itself. This key is stored in
a tmpfs
[emptyDir](https://kubernetes.io/docs/concepts/storage/volumes/#emptydir) which
never leaves the pod and stays in memory. After the key has been generated, the
proxy connects to the control plane's `identity` component. This component is a
TLS [certificate authority
(CA)](https://en.wikipedia.org/wiki/Certificate_authority) and is used to sign
certificates with the correct identity. Proxies validate the connection to
`identity` by using the trust root, which is part of the proxy container's
specification as an environment variable.

Identity in Linkerd is tied to the [Kubernetes Service
Account](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/)
that is being used by the pod. Once the proxy has connected to the `identity`
control plane component, it issues a [certificate signing request
(CSR)](https://en.wikipedia.org/wiki/Certificate_signing_request). The CSR
contains an initial certificate with the pod's identity set to its service
account and the actual service acount token so that `identity` can validate
that the CSR is valid. Once all validation has succeeded, the signed trust
bundle is returned to the proxy and it can use that when it acts as both a
client and server.

These certificates are scoped to 24 hours and will be dynamically refreshed
using the same mechanism when required.

## Caveats and future work

There are several known gaps in Linkerd's ability to automatically encrypt and
authenticate all communication in the cluster. These gaps will be fixed in
future releases:

* Non-HTTP traffic is not currently automatically TLS'd. This will be
  addressed in a future Linkerd release.

* HTTP requests where the `Host` header is an IP address, rather than a name,
  are currently not automatically TLS'd. For example, the connections that
  Linkerd's Prometheus control plane component uses to scrape proxy metrics are
  not currently automatically TLS'd. This will be addressed in a future Linkerd
  release.

* Linkerd does not currently *enforce* mTLS. Any unencrypted requests inside
  the mesh will be opportunistically upgraded to mTLS. Any requests originating
  from inside or outside the mesh will not be automatically mTLS'd by Linkerd.
  This will be addressed in a future Linkerd release, likely as an opt-in
  behavior as it may break some existing applications.

* Ideally, the Service Account token that Linkerd uses would not be shared with
  other potential uses of that token. In future Kubernetes releases, Kubernetes
  will support audience/time-bound Service Account tokens, and Linkerd will use
  those instead.
