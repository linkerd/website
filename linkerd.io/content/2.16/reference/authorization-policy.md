+++
title = "Authorization Policy"
description = "Reference guide to Linkerd's policy resources."
+++

Linkerd's authorization policy allows you to control which types of traffic are
allowed to meshed pods. See the [Authorization Policy feature
description](../../features/server-policy/) for more information on what this
means.

Linkerd's policy is configured using two mechanisms:

1. A set of _default policies_, which can be set at the cluster,
   namespace, and workload level through Kubernetes annotations.
2. A set of CRDs that specify fine-grained policy for specific ports, routes,
   workloads, etc.

## Default policies

During a Linkerd install, the `proxy.defaultInboundPolicy` field is used to
specify the cluster-wide default policy. This field can be one of the following:

- `all-unauthenticated`: allow all traffic. This is the default.
- `all-authenticated`: allow traffic from meshed clients in the same or from
   a different cluster (with multi-cluster).
- `cluster-authenticated`: allow traffic from meshed clients in the same cluster.
- `cluster-unauthenticated`: allow traffic from both meshed and non-meshed clients
  in the same cluster.
- `deny`: all traffic are denied.
- `audit`: Same as `all-unauthenticated` but requests get flagged in logs and
  metrics.

This cluster-wide default can be overridden for specific resources by setting
the annotation `config.linkerd.io/default-inbound-policy` on either a pod spec
or its namespace.

## Dynamic policy resources

For dynamic control of policy, and for finer-grained policy than what the
default polices allow, Linkerd provides a set of CRDs which control traffic
policy in the cluster: [Server], [HTTPRoute], [ServerAuthorization],
[AuthorizationPolicy], [MeshTLSAuthentication], and [NetworkAuthentication].

The general pattern for authorization is:

- A `Server` describes a set of pods, and a single port on those pods.
- Optionally, an `HTTPRoute` references that `Server` and describes a
  subset of HTTP traffic to it.
- A `MeshTLSAuthentication` or `NetworkAuthentication` decribes who
  is allowed access.
- An `AuthorizationPolicy` references the `HTTPRoute` or `Server`
  (the thing to be authorized) and the `MeshTLSAuthentication` or
  `NetworkAuthentication` (the clients that have authorization).

## Server

A `Server` selects a port on a set of pods in the same namespace as the server.
It typically selects a single port on a pod, though it may select multiple ports
when referring to the port by name (e.g. `admin-http`). While the `Server`
resource is similar to a Kubernetes `Service`, it has the added restriction that
multiple `Server` instances must not overlap: they must not select the same
pod/port pairs. Linkerd ships with an admission controller that prevents
overlapping `Server`s from being created.

{{< note >}}
When a Server resource is present, all traffic to the port on its pods will be
denied unless explicitly authorized or audit mode is enabled (with
`accessPolicy:audit`). Thus, Servers are typically paired with e.g. an
AuthorizationPolicy that references the Server, or that reference an HTTPRoute
that in turn references the Server.
{{< /note >}}

### Server Spec

A `Server` spec may contain the following top level fields:

{{< table >}}
| field| value |
|------|-------|
| `accessPolicy`| [accessPolicy](#accesspolicy) declares the policy applied to traffic not matching any associated authorization policies (defaults to `deny`). |
| `podSelector`| A [podSelector](#podselector) selects pods in the same namespace. |
| `port`| A port name or number. Only ports in a pod spec's `ports` are considered. |
| `proxyProtocol`| Configures protocol discovery for inbound connections. Supersedes the `config.linkerd.io/opaque-ports` annotation. Must be one of `unknown`,`HTTP/1`,`HTTP/2`,`gRPC`,`opaque`,`TLS`. Defaults to `unknown` if not set. |
{{< /table >}}

#### accessPolicy

Traffic that doesn't conform to the authorization policies associated to the
Server are denied by default. You can alter that behavior by overriding the
`accessPolicy` field, which accepts the same values as the [default
policies](#default-policies). Of particular interest is the `audit` value, which
enables [audit mode](../../features/server-policy/#audit-mode), that you can use
to test policies before enforcing them.

#### podSelector

This is the [same labelSelector field in Kubernetes](https://kubernetes.io/docs/reference/kubernetes-api/common-definitions/label-selector/#LabelSelector).
All the pods that are part of this selector will be part of the [Server] group.
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

A [Server] that selects over pods with a specific label, with `gRPC` as
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

A [Server] that selects over pods with `matchExpressions`, with `HTTP/2`
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

## HTTPRoute

When attached to a [Server], an `HTTPRoute` resource represents a subset of the
traffic handled by the ports on pods referred in that Server, by declaring a set
of rules which determine which requests match. Matches can be based on path,
headers, query params, and/or verb. [AuthorizationPolicies] may target
`HTTPRoute` resources, thereby authorizing traffic to that `HTTPRoute` only
rather than to the entire [Server]. `HTTPRoutes` may also define filters which
add processing steps that must be completed during the request or response
lifecycle.

{{< note >}}
A given HTTP request can only match one HTTPRoute. If multiple HTTPRoutes
are present that match a request, one will be picked according to the [Gateway
API rules of
precendence](https://gateway-api.sigs.k8s.io/references/spec/#gateway.networking.k8s.io/v1beta1.HTTPRouteSpec).
{{< /note >}}

Please refer to HTTPRoute's full [spec](../httproute/).

{{< note >}}
Two versions of the HTTPRoute resource may be used with Linkerd:

- The upstream version provided by the Gateway API, with the
  `gateway.networking.k8s.io` API group
- A Linkerd-specific CRD provided by Linkerd, with the `policy.linkerd.io` API
  group

The two HTTPRoute resource definitions are similar, but the Linkerd version
implements experimental features not yet available with the upstream Gateway API
resource definition. See [the HTTPRoute reference
documentation](../httproute/#linkerd-and-gateway-api-httproutes)
for details.
{{< /note >}}

## AuthorizationPolicy

An AuthorizationPolicy provides a way to authorize traffic to a [Server] or an
[HTTPRoute]. AuthorizationPolicies are a replacement for [ServerAuthorizations]
which are more flexible because they can target [HTTPRoutes] instead of only
being able to target [Servers].

### AuthorizationPolicy Spec

An `AuthorizationPolicy` spec may contain the following top level fields:

{{< table >}}
| field| value |
|------|-------|
| `targetRef`| A [TargetRef](#targetref) which references a resource to which the authorization policy applies.|
| `requiredAuthenticationRefs`| A list of [TargetRefs](#targetref) representing the required authentications. In the case of multiple entries, _all_ authentications must match.|
{{< /table >}}

#### targetRef

A `TargetRef` identifies an API object to which this AuthorizationPolicy
applies. The API objects supported are:

- A [Server], indicating that the AuthorizationPolicy applies to all traffic to
  the Server.
- An [HTTPRoute], indicating that the AuthorizationPolicy applies to all traffic
  matching the HTTPRoute.
- A namespace (`kind: Namespace`), indicating that the AuthorizationPolicy
  applies to all traffic to all [Servers] and [HTTPRoutes] defined in the
  namespace.

{{< table >}}
| field| value |
|------|-------|
| `group`| Group is the group of the target resource. For namespace kinds, this should be omitted.|
| `kind`| Kind is kind of the target resource.|
| `namespace`| The namespace of the target resource. When unspecified (or empty string), this refers to the local namespace of the policy.|
| `name`| Name is the name of the target resource.|
{{< /table >}}

### AuthorizationPolicy Examples

An `AuthorizationPolicy` which authorizes clients that satisfy the
`authors-get-authn` authentication to send to the `authors-get-route`
[HTTPRoute].

```yaml
apiVersion: policy.linkerd.io/v1alpha1
kind: AuthorizationPolicy
metadata:
  name: authors-get-policy
  namespace: booksapp
spec:
  targetRef:
    group: policy.linkerd.io
    kind: HTTPRoute
    name: authors-get-route
  requiredAuthenticationRefs:
    - name: authors-get-authn
      kind: MeshTLSAuthentication
      group: policy.linkerd.io
```

An `AuthorizationPolicy` which authorizes the `webapp` `ServiceAccount` to send
to the `authors` [Server].

```yaml
apiVersion: policy.linkerd.io/v1alpha1
kind: AuthorizationPolicy
metadata:
  name: authors-policy
  namespace: booksapp
spec:
  targetRef:
    group: policy.linkerd.io
    kind: Server
    name: authors
  requiredAuthenticationRefs:
    - name: webapp
      kind: ServiceAccount
```

An `AuthorizationPolicy` which authorizes the `webapp` `ServiceAccount` to send
to all policy "targets" within the `booksapp` namespace.

```yaml
apiVersion: policy.linkerd.io/v1alpha1
kind: AuthorizationPolicy
metadata:
  name: authors-policy
  namespace: booksapp
spec:
  targetRef:
    kind: Namespace
    name: booksapp
  requiredAuthenticationRefs:
    - name: webapp
      kind: ServiceAccount
```

## MeshTLSAuthentication

A `MeshTLSAuthentication` represents a set of mesh identities. When an
[AuthorizationPolicy] has a `MeshTLSAuthentication` as one of its
`requiredAuthenticationRefs`, this means that clients must be in the mesh and
must have one of the specified identities in order to be authorized to send
to the target.

### MeshTLSAuthentication Spec

A `MeshTLSAuthentication` spec may contain the following top level fields:

{{< table >}}
| field| value |
|------|-------|
| `identities`| A list of mTLS identities to authenticate. The `*` prefix can be used to match all identities in a domain. An identity string of `*` indicates that all meshed clients are authorized.|
| `identityRefs`| A list of [targetRefs](#targetref) to `ServiceAccounts` to authenticate.|
{{< /table >}}

### MeshTLSAuthentication Examples

A `MeshTLSAuthentication` which authenticates the `books` and `webapp` mesh
identities.

```yaml
apiVersion: policy.linkerd.io/v1alpha1
kind: MeshTLSAuthentication
metadata:
  name: authors-get-authn
  namespace: booksapp
spec:
  identities:
    - "books.booksapp.serviceaccount.identity.linkerd.cluster.local"
    - "webapp.booksapp.serviceaccount.identity.linkerd.cluster.local"
```

A `MeshTLSAuthentication` which authenticate thes `books` and `webapp` mesh
identities. This is an alternative way to specify the same thing as the above
example.

```yaml
apiVersion: policy.linkerd.io/v1alpha1
kind: MeshTLSAuthentication
metadata:
  name: authors-get-authn
  namespace: booksapp
spec:
  identityRefs:
    - kind: ServiceAccount
      name: books
    - kind: ServiceAccount
      name: webapp
```

A `MeshTLSAuthentication` which authenticates all meshed identities.

```yaml
apiVersion: policy.linkerd.io/v1alpha1
kind: MeshTLSAuthentication
metadata:
  name: authors-get-authn
  namespace: booksapp
spec:
  identities: ["*"]
```

## NetworkAuthentication

A `NetworkAuthentication` represents a set of IP subnets. When an
[AuthorizationPolicy] has a `NetworkAuthentication` as one of its
`requiredAuthenticationRefs`, this means that clients must be in one of the
specified networks in order to be authorized to send to the target.

### NetworkAuthentication Spec

A `NetworkAuthentication` spec may contain the following top level fields:

{{< table >}}
| field| value |
|------|-------|
| `networks`| A list of [networks](#network) to authenticate.|
{{< /table >}}

#### network

A `network` defines an authenticated IP subnet.

{{< table >}}
| field| value |
|------|-------|
| `cidr`| A subnet in CIDR notation to authenticate.|
| `except`| A list of subnets in CIDR notation to exclude from the authentication.|
{{< /table >}}

### NetworkAuthentication Examples

A `NetworkAuthentication` that authenticates clients which belong to any of
the specified CIDRs.

```yaml
apiVersion: policy.linkerd.io/v1alpha1
kind: NetworkAuthentication
metadata:
  name: cluster-network
  namespace: booksapp
spec:
  networks:
  - cidr: 10.0.0.0/8
  - cidr: 100.64.0.0/10
  - cidr: 172.16.0.0/12
  - cidr: 192.168.0.0/16
```

## ServerAuthorization

A [ServerAuthorization] provides a way to authorize traffic to one or more
[Server]s.

{{< note >}}
[AuthorizationPolicy](#authorizationpolicy) is a more flexible alternative to
`ServerAuthorization` that can target [HTTPRoutes](#httproute) as well as
[Servers](#server). Use of [AuthorizationPolicy](#authorizationpolicy) is
preferred, and `ServerAuthorization` will be deprecated in future releases.
{{< /note >}}

### ServerAuthorization Spec

A ServerAuthorization spec must contain the following top level fields:

{{< table >}}
| field| value |
|------|-------|
| `client`| A [client](#client) describes clients authorized to access a server. |
| `server`| A [serverRef](#serverref) identifies `Servers` in the same namespace for which this authorization applies. |
{{< /table >}}

#### serverRef

A `serverRef` object must contain _exactly one_ of the following fields:

{{< table >}}
| field| value |
|------|-------|
| `name`| References a `Server` instance by name. |
| `selector`| A [selector](#selector) selects servers on which this authorization applies in the same namespace. |
{{< /table >}}

#### selector

This is the [same labelSelector field in Kubernetes](https://kubernetes.io/docs/reference/kubernetes-api/common-definitions/label-selector/#LabelSelector).
All the servers that are part of this selector will have this authorization applied.
A selector object must contain _exactly one_ of the following fields:

{{< table >}}
| field | value |
|-------|-------|
| `matchExpressions` | A list of label selector requirements. The requirements are ANDed. |
| `matchLabels` | A map of {key,value} pairs. |
{{< /table >}}

See [the Kubernetes LabelSelector reference](https://kubernetes.io/docs/reference/kubernetes-api/common-definitions/label-selector/#LabelSelector)
for more details.

#### client

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

#### meshTLS

A `meshTLS` object must contain _exactly one_ of the following fields:

{{< table >}}
| field| value |
|------|-------|
| `unauthenticatedTLS`| A boolean to indicate that no client identity is required for communication. This is mostly important for the identity controller, which must terminate TLS connections from clients that do not yet have a certificate. |
| `identities`| A list of proxy identity strings (as provided via mTLS) that are authorized. The `*` prefix can be used to match all identities in a domain. An identity string of `*` indicates that all authentication clients are authorized. |
| `serviceAccounts`| A list of authorized client [serviceAccount](#serviceAccount)s (as provided via mTLS). |
{{< /table >}}

#### serviceAccount

A serviceAccount field contains the following top level fields:

{{< table >}}
| field| value |
|------|-------|
| `name`| The ServiceAccount's name. |
| `namespace`| The ServiceAccount's namespace. If unset, the authorization's namespace is used. |
{{< /table >}}

### ServerAuthorization Examples

A [ServerAuthorization] that allows meshed clients with
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

A [ServerAuthorization] that allows any unauthenticated
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

A [ServerAuthorization] that allows meshed clients with a
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

[Server]: #server
[Servers]: #server
[HTTPRoute]: #httproute
[HTTPRoutes]: #httproute
[ServerAuthorization]: #serverauthorization
[ServerAuthorizations]: #serverauthorization
[AuthorizationPolicy]: #authorizationpolicy
[AuthorizationPolicies]: #authorizationpolicy
[MeshTLSAuthentication]: #meshtlsauthentication
[NetworkAuthentication]: #networkauthentication
