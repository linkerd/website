+++
title = "Authorization Policy"
description = "Details on the specification and what is possible with policy resources."
+++

[Server](#server) and [ServerAuthorization](#serverauthorization) are the two types
of policy resources in Linkerd, used to control inbound access to your meshed
applications.

During the linkerd install, the `policyController.defaultAllowPolicy` field is used
to specify the default policy when no [Server](#server) selects a pod.
This field can be one of the following:

- `all-unauthenticated`: allow all requests. This is the default.
- `all-authenticated`: allow requests from meshed clients in the same or from
   a different cluster (with multi-cluster).
- `cluster-authenticated`: allow requests from meshed clients in the same cluster.
- `cluster-unauthenticated`: allow requests from both meshed and non-meshed clients
  in the same cluster.
- `deny`: all requests are denied. (Policy resources should then be created to
  allow specific communications between services).

This default can be overridden by setting the annotation `config.linkerd.io/default-
inbound-policy` on either a pod spec or its namespace.

Once a [Server](#server) is configured for a pod & port, its default behavior
is to _deny_ traffic and [ServerAuthorization](#serverauthorization) resources
must be created to allow traffic on a `Server`.

## Server

A `Server` selects a port on a set of pods in the same namespace as the server.
It typically selects a single port on a pod, though it may select multiple
ports when referring to the port by name (e.g. `admin-http`). While the
`Server` resource is similar to a Kubernetes `Service`, it has the added
restriction that multiple `Server` instances must not overlap: they must not
select the same pod/port pairs. Linkerd ships with an admission controller that
tries to prevent overlapping servers from being created.

When a Server selects a port, traffic is denied by default and [`ServerAuthorizations`](#serverauthorization)
must be used to authorize traffic on ports selected by the Server.

### Spec

A `Server` spec may contain the following top level fields:

{{< table >}}
| field| value |
|------|-------|
| `podSelector`| A [podSelector](#podselector) selects pods in the same namespace. |
| `port`| A port name or number. Only ports in a pod spec's `ports` are considered. |
| `proxyProtocol`| Configures protocol discovery for inbound connections. Supersedes the `config.linkerd.io/opaque-ports` annotation. Must be one of `unknown`,`HTTP/1`,`HTTP/2`,`gRPC`,`opaque`,`TLS`. Defaults to `unknown` if not set. |
{{< /table >}}

### podSelector

This is the [same labelSelector field in Kubernetes](https://kubernetes.io/docs/reference/kubernetes-api/common-definitions/label-selector/#LabelSelector).
All the pods that are part of this selector will be part of the `Server` group.
A podSelector object must contain _exactly one_ of the following fields:

{{< table >}}
| field | value |
|-------|-------|
| `matchExpressions` | matchExpressions is a list of label selector requirements. The requirements are ANDed. |
| `matchLabels` | matchLabels is a map of {key,value} pairs. |
{{< /table >}}

See [the Kubernetes LabelSelector reference](https://kubernetes.io/docs/reference/kubernetes-api/common-definitions/label-selector/#LabelSelector)
for more details.

### Server Examples

A [Server](#server) that selects over pods with a specific label, with `gRPC` as
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

A [Server](#server) that selects over pods with `matchExpressions`, with `HTTP/2`
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

A [ServerAuthorization](#serverauthorization) provides a way to authorize
traffic to one or more [`Server`](#server)s.

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
| `name`| References a `Server` instance by name. |
| `selector`| A [selector](#selector) selects servers on which this authorization applies in the same namespace. |
{{< /table >}}

### selector

This is the [same labelSelector field in Kubernetes](https://kubernetes.io/docs/reference/kubernetes-api/common-definitions/label-selector/#LabelSelector).
All the servers that are part of this selector will have this authorization applied.
A selector object must contain _exactly one_ of the following fields:

{{< table >}}
| field | value |
|-------|-------|
| `matchExpressions` | matchExpressions is a list of label selector requirements. The requirements are ANDed. |
| `matchLabels` | matchLabels is a map of {key,value} pairs. |
{{< /table >}}

See [the Kubernetes LabelSelector reference](https://kubernetes.io/docs/reference/kubernetes-api/common-definitions/label-selector/#LabelSelector)
for more details.

### client

A `client` object must contain _exactly one_ of the following fields:

{{< table >}}
| field| value |
|------|-------|
| `meshTLS`| A [meshTLS](#meshtls) is used to authorize meshed clients to access a server. |
| `unauthenticated`| A boolean value that authorizes unauthenticated clients to access a server. |
{{< /table >}}

Optionally, it can also contain the `networks` field:

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
| `unauthenticatedTLS`| A boolean to indicate that no client identity is required for communication.This is mostly important for the identity controller, which must terminate TLS connections from clients that do not yet have a certificate. |
| `identities`| A list of proxy identity strings (as provided via MTLS) that are authorized. The `*` prefix can be used to match all identities in a domain. An identity string of `*` indicates that all authentication clients are authorized. |
| `serviceAccounts`| A list of authorized client [serviceAccount](#serviceAccount)s (as provided via MTLS). |
{{< /table >}}

### serviceAccount

A serviceAccount field contains the following top level fields:

{{< table >}}
| field| value |
|------|-------|
| `name`| The ServiceAccount's name. |
| `namespace`| The ServiceAccount's namespace. If unset, the authorization's namespace is used. |
{{< /table >}}

### ServerAuthorization Examples

A [ServerAuthorization](#serverauthorization) that allows meshed clients with
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

A [ServerAuthorization](#serverauthorization) that allows any unauthenticated
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

A [ServerAuthorization](#serverauthorization) that allows meshed clients with a
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
