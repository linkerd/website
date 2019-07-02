+++
title = "Automatic mTLS"
description = "Linkerd automatically enables mutual Transport Layer Security (TLS) for all communication between meshed applications."
weight = 4
aliases = [
  "/2/features/automatic-tls"
]
+++

By default, Linkerd automatically enables mutual Transport Layer Security (mTLS)
for all communication between meshed pods, by establishing and authenticating
secure, private TLS connections between Linkerd proxies. In fact, because the
Linkerd control plane runs on the data plane, this means that communication
between control plane components are also automatically secured via mTLS.

{{< note >}}
Linkerd does not currently *enforce* mTLS. Any unencrypted requests inside the
mesh will be opportunistically upgraded to mTLS. Any requests originating from
inside or outside the mesh cannot be upgraded and must rely on traditional TLS
schemes.
{{< /note >}}

While mTLS happens automatically, check out how to
[verify](/2/tasks/securing-your-service/) that it is working.

## How does it work?

On install, a trust root, certificate and private key are generated. The trust
root is stored as a
[ConfigMap](https://unofficial-kubernetes.readthedocs.io/en/latest/tasks/configure-pod-container/configmap/).
This is used to verify the identity of any proxy and can replaced with your own
trust root as part of install. Both certificate and private key are placed into
a [Secret](https://kubernetes.io/docs/concepts/configuration/secret/). It is
important that this secret stays private and other service accounts in the
cluster do not have access. By default, this goes into the `linkerd` namespace
and can only be read by the service account used by `identity`.

On startup, the proxy generates a private key for itself. This key is stored in
a tmpfs
[emptyDir](https://kubernetes.io/docs/concepts/storage/volumes/#emptydir) which
never leaves the pod and stays in memory. After the key has been generated, the
proxy connects to a [control plane](/2/reference/architecture/) component named
`identity`. This component is a TLS [certificate authority
(CA)](https://en.wikipedia.org/wiki/Certificate_authority) and is used to sign
certificates with the correct identity. Proxies validate the connection to
`identity` by using the trust root which is part of the proxy container's
specification as an environment variable.

Identity in Linkerd is tied to the [service
account](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/)
that is being used by the pod. Once the proxy has connected to `identity`, it
issues a [certificate signing request
(CSR)](https://en.wikipedia.org/wiki/Certificate_signing_request). The CSR
contains an initial certificate with the pod's identity set to its service
account and the actual service acount token so that `identity` can validate that
the CSR is valid. Once all validation has succeeded, the signed trust bundle is
returned to the proxy and it can use that when it acts as both a client and
server.

These certificates are scoped to 24 hours and will be dynamically refreshed
using the same mechanism when required.

## Known issues

* Discovery happens on FQDNs associated with pods
  (`foo.default.svc.cluster.local` for example). Requests without a `Host`
  header containing this information such as IP addresses are proxied directly
  and are treated as if they're not in the mesh. This means that the connections
  Prometheus uses to scrape proxy metrics are not currently TLS'd.

* Only HTTP based traffic is TLS'd.

* Ideally, the Service Account token that Linkerd uses would not be shared with
  other potential uses of that token. Once Kubernetes support for
  audience/time-bound Service Account tokens is stable, Linkerd will use those
  instead.
