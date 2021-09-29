+++
title = "Server and ServerAuthorization"
description = "Details on the specification and what is possible with policy resources."
+++

[Server](#Server) and [ServerAuthorization](#ServerAuthorization) are the two types
of policy resources in Linkerd, used to control inbound access to your meshed
applications.

## Server

[Server](#Server) provides a way to group your application pods.

### Spec

A `Server` spec must contain the following top level fields:

{{< table >}}
| field| value |
|------|-------|
| `podSelector`| A [podSelector](#podSelector) selects pods in the same namespace. |
| `port`| a port name or number. Must exist in a pod spec. |
| `proxyProtocol`| Configures protocol discovery for inbound connections. Supersedes the `config.linkerd.io/opaque-ports` annotation. Must be one of `unknown`,`HTTP/1`,`HTTP/2`,`gRPC`,`opaque`,`TLS`. Defaults to `unknown` if not set. |
{{< /table >}}

### podSelector

This is the [same labelSelector field in Kubernetes](https://kubernetes.io/docs/reference/kubernetes-api/common-definitions/label-selector/#LabelSelector).
All the pods that are part of this selector will be part of the `Server` group.
A podSelector object must contain _exactly one_ of the following fields:

{{< table >}}
| field | value |
|-------|-------|
| `matchExpressions` | matchExpressions is a list of label selector requirements. The requirements are ANDed. See [the Kubernetes LabelSelector reference](https://kubernetes.io/docs/reference/kubernetes-api/common-definitions/label-selector/#LabelSelector) for more details. |
| `matchLabels` | matchLabels is a map of {key,value} pairs |
{{< /table >}}

### Server Examples

A [Server](#Server) that selects over pods with a specific label, with `gRPC` as
the `proxyProtocol`.

```yaml
apiVersion: policy.linkerd.io/v1beta1
kind: Server
metadata:
  namespace: emojivoto
  name: emoji-grpc
spec:
  podSelector:
    matchLabels:
      app: emoji-svc
  port: grpc
  proxyProtocol: gRPC
```

A [Server](#Server) that selects over pods with `matchExpressions`, with `HTTP/2`
as the `proxyProtocol`, on port `8080`.

```yaml
apiVersion: policy.linkerd.io/v1beta1
kind: Server
metadata:
  namespace: emojivoto
  name: backend-services
spec:
  podSelector:
    matchExpressions:
    - {key: app, operator: In, values: [voting-svc, emoji-svc]}
    - {key: environment, operator: NotIn, values: [dev]}
  port: 8080
  proxyProtocol: "HTTP/2"
```

## ServerAuthorization

A [ServerAuthorization](#ServerAuthorization) provides a way to set client
restrictions on one or more [`Server`](#Server)s.

### Spec

A ServerAuthorization spec must contain the following top level fields:

{{< table >}}
| field| value |
|------|-------|
| `client`| A [client](#client) describes clients authorized to access a server. |
| `server`| A [server](#server) identifies `Servers` in the same namespace for which this authorization applies. |
{{< /table >}}

### Server

A `Server` object must contain _exactly one_ of the following fields:

{{< table >}}
| field| value |
|------|-------|
| `name`| References a `Server` instance by name |
| `selector`| a [selector](#selector) selects servers on which this authorization applies in the same namespace. |
{{< /table >}}

### selector

This is the [same labelSelector field in Kuberentes](https://kubernetes.io/docs/reference/kubernetes-api/common-definitions/label-selector/#LabelSelector).
All the servers that are part of this selector will have this authorization applied.
A selector object must contain _exactly one_ of the following fields:

{{< table >}}
| field | value |
|-------|-------|
| `matchExpressions` | matchExpressions is a list of label selector requirements. The requirements are ANDed. See [kubernetes reference](https://kubernetes.io/docs/reference/kubernetes-api/common-definitions/label-selector/#LabelSelector) for more details |
| `matchLabels` | matchLabels is a map of {key,value} pairs |
{{< /table >}}

### client

A `client` object must contain _exactly one_ of the following fields:

{{< table >}}
| field| value |
|------|-------|
| `meshTLS`| a [meshTls](#meshTLS) is used to authorize meshed clients to access a server. Must be one of [unauthenticatedTLS](#unauthenticatedTLS),[identities](#identities),[serviceAccounts](#serviceAccounts) |
| `unauthenticated`| a boolean value that authorizes unauthenticated clients to access a server. |
{{< /table >}}

Optionally, It can also contain the `networks` field:

{{< table >}}
| field| value |
|------|-------|
| `networks`| Limits the client IP addresses to which this authorization applies. If unset, the server chooses a default (typically, all IPs or the cluster's pod network). |
{{< /table >}}

### meshTLS

A `meshTLS` object must contain _exactly one_ of the following fields:

{{< table >}}
| field| value |
|------|-------|
| `unauthenticatedTLS`| a boolean to indicate that no client identity is required for communication.This is mostly important for the identity controller, which must terminate TLS connections from clients that do not yet have a certificate. |
| `identities`| a list of proxy identity strings (as provided via MTLS) that are authorized. The `*` prefix can be used to match all identities in a domain. An identity string of `*` indicates that all authentication clients are authorized. |
| `serviceAccounts`| a [serviceAccount](#serviceAccount) authorizes clients with provided proxy identity service accounts (as provided via MTLS) |
{{< /table >}}

### serviceAccount

A serviceAccount field must contain the following top level fields:

{{< table >}}
| field| value |
|------|-------|
| `name`| the ServiceAccount's name. |
| `namespace`| The ServiceAccount's namespace. If unset, the authorization's namespace is used. |
{{< /table >}}

### ServerAuthorization Examples

A [ServerAuthorization](#ServerAuthorization) that allows meshed clients with
`*.emojivoto.serviceaccount.identity.linkerd.cluster.local` proxy identity i.e. all
service accounts in the `emojivoto` namespace.

```yaml
apiVersion: policy.linkerd.io/v1beta1
kind: ServerAuthorization
metadata:
  namespace: emojivoto
  name: emoji-grpc
spec:
  # Allow all authenticated clients to access the (read-only) emoji service.
  server:
    selector:
      matchLabels:
        app: emoji-svc
  client:
    meshTLS:
      identities:
        - "*.emojivoto.serviceaccount.identity.linkerd.cluster.local"
```

A [ServerAuthorization](#ServerAuthorization) that allows any unauthenticated
clients.

```yaml
apiVersion: policy.linkerd.io/v1beta1
kind: ServerAuthorization
metadata:
  namespace: emojivoto
  name: web-public
spec:
  server:
    name: web-http
  # Allow all clients to access the web HTTP port without regard for
  # authentication. If unauthenticated connections are permitted, there is no
  # need to describe authenticated clients.
  client:
    unauthenticated: true
    networks:
      - cidr: 0.0.0.0/0
      - cidr: ::/0
```

A [ServerAuthorization](#ServerAuthorization) that allows meshed clients with a
specific service account.

```yaml
apiVersion: policy.linkerd.io/v1beta1
kind: ServerAuthorization
metadata:
  namespace: emojivoto
  name: prom-prometheus
spec:
  server:
    name: prom
  client:
    meshTLS:
      serviceAccounts:
        - namespace: linkerd-viz
          name: prometheus
```
