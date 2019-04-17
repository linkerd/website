+++
title = "Automatic TLS"
description = "Linkerd can be configured to automatically negotiate Transport Layer Security (TLS) for application communication."
weight = 4
+++

Linkerd by default automatically negotiates Transport Layer Security (TLS) for
application communication.

Linkerd establishes and authenticates secure, private connections between
Linkerd proxies. This is done without breaking unencrypted communication with
endpoints that are not configured with TLS-enabled Linkerd proxies.

## Getting started with TLS

To enable TLS, simply install the Linkerd control plane:

```bash
linkerd install | kubectl apply -f -
```

The Linkerd control plane includes a TLS Identity system. Proxies generate
ephemeral private keys into a tmpfs directory and dynamically refresh
certificates, authenticated by Kubernetes ServiceAccount tokens, via the
Identity controller.

Once you've deployed the Linkerd control plane, enabling TLS for each
application happens automatically when you inject the Linkerd proxy:

```bash
linkerd inject app.yml | kubectl apply -f -
```

Then, tools like `linkerd tap` and Grafana will indicate the TLS status of
traffic:

```bash
linkerd tap deploy -n emojivoto
```

As an example, the output might be:

```bash
req id=0:1 proxy=out src=10.1.17.29:33500 dst=10.1.17.28:80 tls=true :method=GET :authority=web-svc.emojivoto:80 :path=/api/list
req id=0:1 proxy=in  src=10.1.17.29:45960 dst=10.1.17.28:80 tls=true :method=GET :authority=web-svc.emojivoto:80 :path=/api/list
req id=0:2 proxy=out src=10.1.17.28:59272 dst=10.1.17.27:8080 tls=true :method=POST :authority=emoji-svc.emojivoto:8080 :path=/emojivoto.v1.EmojiService/ListAll
req id=0:1 proxy=in  src=10.1.17.28:59344 dst=10.1.17.27:8080 tls=true :method=POST :authority=emoji-svc.emojivoto:8080 :path=/emojivoto.v1.EmojiService/ListAll
```

## Known issues

As this feature is recently enabled by default, we'd **LOVE** your feedback, so
please don't hesitate to [file an issue][new-issue] if you run into any problems
using automatic TLS.

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
[Original Linkerd Issue][l5d-issue].

[tls-issues]: https://github.com/linkerd/linkerd2/issues?q=is%3Aissue+is%3Aopen+label%3Aarea%2Ftls
[new-issue]: https://github.com/linkerd/linkerd2/issues/new/choose
[k8s-docs]: https://kubernetes.io/docs/tasks/access-application-cluster/create-external-load-balancer/
[l5d-issue]: https://github.com/linkerd/linkerd2/issues/1880
