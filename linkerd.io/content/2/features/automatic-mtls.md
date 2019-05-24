+++
title = "Automatic mTLS"
description = "Linkerd automatically enables mutual Transport Layer Security (TLS) for all communication between meshed applications."
weight = 4
aliases = [
  "/2/features/automatic-tls"
]
+++

By default, Linkerd automatically enables mutual Transport Layer Security
(mTLS) for all communication between meshed pods, by establishing and
authenticating secure, private TLS connections between Linkerd proxies.

Linkerd does not break unencrypted communication with endpoints that do not use
Linkerd. In other words, Linkerd does not currently *enforce* TLS to
non-Linkerd endpoints.

mTLS identity is provisioned based on the Kubernetes [Service Accounts](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/).

Since the Linkerd control plane runs on the data plane, this means that
communication between control plane components is also automatically secured
via mTLS.

## Getting started with mTLS

Since mTLS is enabled by default, simply [install the Linkerd control
plane](https://linkerd.io/2/tasks/install/) and [add your
services](https://linkerd.io/2/tasks/adding-your-service/) to Linkerd to enable
mTLS for those services.

To validate that TLS is working, you can examine the [Grafana
dashboards](https://linkerd.io/2/features/dashboard/), or use a took like
[`linkerd tap`](https://linkerd.io/2/reference/cli/tap/) to inspect Linkerd's
metadata about requests. For example:

```bash
linkerd tap deploy -n emojivoto
```

Which might give an output like:

```bash
req id=0:1 proxy=out src=10.1.17.29:33500 dst=10.1.17.28:80 tls=true :method=GET :authority=web-svc.emojivoto:80 :path=/api/list
req id=0:1 proxy=in  src=10.1.17.29:45960 dst=10.1.17.28:80 tls=true :method=GET :authority=web-svc.emojivoto:80 :path=/api/list
req id=0:2 proxy=out src=10.1.17.28:59272 dst=10.1.17.27:8080 tls=true :method=POST :authority=emoji-svc.emojivoto:8080 :path=/emojivoto.v1.EmojiService/ListAll
req id=0:1 proxy=in  src=10.1.17.28:59344 dst=10.1.17.27:8080 tls=true :method=POST :authority=emoji-svc.emojivoto:8080 :path=/emojivoto.v1.EmojiService/ListAll
```

Note the `tls=true` output, indicating that the request went over a mTLS'd connection.

## How does it work?

The [Linkerd control plane](https://linkerd.io/2/reference/architecture/)
includes a TLS certificate authority (CA), called simply "identity".

The signing certs used by Linkerd's identity service are stored in a
[Kubernetes Secret](https://kubernetes.io/docs/concepts/configuration/secret/).
This Secret is only mounted by Linkerd's identity, which has its own service
account.

At proxy injection time, the proxies get their trust root as an environment
variable set by the proxy-injector webhook. Proxies validate the identity
service with that trust root, pass along their service account token over that
one-way-TLS connnection, and receive a TLS certificate in return. Proxies store
their ephemeral private keys into a tmpfs directory. Thus, pod credentials are
never leave the pod.

Currently, certificates are scoped to 24 hours, and proxies will dynamically
refresh them using the same mechanism.

## Known issues

* The connections that Prometheus uses to scrape proxy metrics are not
  currently TLS'd.
* Ideally, the Service Account token that Linkerd uses would not be shared with
  other potential uses of that token. Once Kubernetes support for
  audience/time-bound Service Account tokens is stable, Linkerd will use those
  instead.

### Setting `externalTrafficPolicy` on an External Load Balancer

Given a Kubernetes Service of type `LoadBalancer`, if pods referenced by that
Service are injected with a Linkerd proxy, requests will experience a 2-3
second delay between Client Hello and Server Hello. This is due to the way a
`LoadBalancer` obscures the client source IP via the default
`externalTrafficPolicy: Cluster`. You may workaround this by setting
`externalTrafficPolicy: Local`:

```yaml
kind: Service
apiVersion: v1
metadata:
  name: example-service
spec:
  type: LoadBalancer
  externalTrafficPolicy: Local
```

For more information, see the [Kubernetes Documentation][k8s-docs] and the
[original GitHub issue][l5d-issue].

[tls-issues]: https://github.com/linkerd/linkerd2/issues?q=is%3Aissue+is%3Aopen+label%3Aarea%2Ftls
[new-issue]: https://github.com/linkerd/linkerd2/issues/new/choose
[k8s-docs]: https://kubernetes.io/docs/tasks/access-application-cluster/create-external-load-balancer/
[l5d-issue]: https://github.com/linkerd/linkerd2/issues/1880
