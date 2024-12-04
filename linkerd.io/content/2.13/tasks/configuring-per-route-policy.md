---
title: Configuring Fine-grained Authorization Policy
description: Fine-grained authorization policies can be configured for individual
  HTTP routes.
---

<!-- markdownlint-disable-file MD014 -->

In addition to [enforcing authorization at the service
level](../restricting-access/), finer-grained authorization policies can also be
configured for individual HTTP routes. In this example, we'll use the Books demo
app to demonstrate how to control which clients can access particular routes on
a service.

This is an advanced example that demonstrates more complex policy configuration.
For a basic introduction to Linkerd authorization policy, start with the
[Restricting Access to Services](../restricting-access/) example. For more
comprehensive documentation of the policy resources, see the
[Authorization policy reference](../../reference/authorization-policy/).

## Prerequisites

To use this guide, you'll need to have Linkerd installed on your cluster, along
with its Viz extension. Follow the [Installing Linkerd Guide](../install/)
if you haven't already done this.

## Install the Books demo application

Inject and install the Books demo application:

```bash
$ kubectl create ns booksapp && \
  curl --proto '=https' --tlsv1.2 -sSfL https://run.linkerd.io/booksapp.yml \
  | linkerd inject - \
  | kubectl -n booksapp apply -f -
```

This command creates a namespace for the demo, downloads its Kubernetes
resource manifest, injects Linkerd into the application, and uses `kubectl` to
apply it to your cluster. The app comprises the Kubernetes deployments and
services that run in the `booksapp` namespace.

Confirm that the Linkerd data plane was injected successfully:

```bash
$ linkerd check -n booksapp --proxy -o short
```

You can take a quick look at all the components that were added to your
cluster by running:

```bash
$ kubectl -n booksapp get all
```

Once the rollout has completed successfully, you can access the app itself by
port-forwarding `webapp` locally:

```bash
$ kubectl -n booksapp port-forward svc/webapp 7000 &
```

Open [http://localhost:7000/](http://localhost:7000/) in your browser to see the
frontend.

![Frontend](/docs/images/books/frontend.png "Frontend")

## Creating a Server resource

Both the `books` service and the `webapp` service in the demo application are
clients of the `authors` service.

However, these services send different requests to the `authors` service. The
`books` service should only send `GET`
requests to the `/authors/:id.json` route, to get the author associated with a
particular book. Meanwhile, the `webapp` service may also send `DELETE` and
`PUT` requests to `/authors`, and `POST` requests to `/authors.json`, as it
allows the user to create and delete authors.

Since the `books` service should never need to create or delete authors, we will
create separate authorization policies for the `webapp` and `books` services,
restricting which services can access individual routes of the `authors`
service.

First, let's run the `linkerd viz authz` command to list the authorization
resources that currently exist for the `authors` deployment:

```bash
$ linkerd viz authz -n booksapp deploy/authors
ROUTE    SERVER                       AUTHORIZATION                UNAUTHORIZED  SUCCESS     RPS  LATENCY_P50  LATENCY_P95  LATENCY_P99
default  default:all-unauthenticated  default/all-unauthenticated        0.0rps   70.31%  8.1rps          1ms         43ms         49ms
probe    default:all-unauthenticated  default/probe                      0.0rps  100.00%  0.3rps          1ms          1ms          1ms
```

By default, the `authors` deployment uses the cluster's default authorization
policy, "all-unauthenticated". In addition, a separate authorization is
generated to allow liveness and readiness probes from the kubelet.

First, we'll create a [`Server`] resource for the `authors` deployment's service
port. For details on [`Server`] resources, see
[here](../restricting-access/#creating-a-server-resource).

```bash
kubectl apply -f - <<EOF

---
apiVersion: policy.linkerd.io/v1beta1
kind: Server
metadata:
  name: authors-server
  namespace: booksapp
spec:
  podSelector:
    matchLabels:
      app: authors
      project: booksapp
  port: service
EOF
```

Now that we've defined a [`Server`] for the authors `Deployment`, we can run the
`linkerd viz authz` command again, and see that all traffic to `authors` is
currently unauthorized:

```bash
$ linkerd viz authz -n booksapp deploy/authors
ROUTE    SERVER                       AUTHORIZATION                UNAUTHORIZED  SUCCESS     RPS  LATENCY_P50  LATENCY_P95  LATENCY_P99
default  authors-server                                                  9.5rps    0.00%  0.0rps          0ms          0ms          0ms
probe    authors-server               default/probe                      0.0rps  100.00%  0.1rps          1ms          1ms          1ms
default  default:all-unauthenticated  default/all-unauthenticated        0.0rps  100.00%  0.1rps          1ms          1ms          1ms
probe    default:all-unauthenticated  default/probe                      0.0rps  100.00%  0.2rps          1ms          1ms          1ms
```

Next, we'll create per-route policy resources to authorize traffic to the
`authors` deployment.

## Creating per-route policy resources

The [`HTTPRoute`] resource is used to configure policy for individual HTTP routes,
by defining how to match a request for a given route. We will now create
[`HTTPRoute`] resources for the `authors` service.

{{< note >}}
Routes configured in service profiles are different from [`HTTPRoute`] resources.
Service profile routes allow you to collect per-route metrics and configure
client-side behavior such as retries and timeouts. [`HTTPRoute`] resources, on the
other hand, can be the target of [`AuthorizationPolicies`] and allow you to specify
per-route authorization.

[`HTTPRoute`]: ../../reference/authorization-policy/#httproute
[`AuthorizationPolicies`]:
    ../../reference/authorization-policy/#authorizationpolicy
{{< /note >}}

First, let's create an [`HTTPRoute`] that matches `GET` requests to the `authors`
service's API:

```bash
kubectl apply -f - <<EOF

---
apiVersion: policy.linkerd.io/v1beta1
kind: HTTPRoute
metadata:
  name: authors-get-route
  namespace: booksapp
spec:
  parentRefs:
    - name: authors-server
      kind: Server
      group: policy.linkerd.io
  rules:
    - matches:
      - path:
          value: "/authors.json"
        method: GET
      - path:
          value: "/authors/"
          type: "PathPrefix"
        method: GET
EOF
```

This will create an [`HTTPRoute`] targeting the `authors-server` [`Server`] resource
we defined previously. The `rules` section defines a list of matches, which
determine which requests match the [`HTTPRoute`]. Here, we 've defined a match
rule that matches `GET` requests to the path `/authors.json`, and a second match
rule that matches `GET` requests to paths starting with the path segment
`/authors`.

Now that we've created a route, we can associate policy with that route. We'll
create an [`AuthorizationPolicy`] resource that defines policy for our
[`HTTPRoute`]:

```bash
kubectl apply -f - <<EOF

---
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
---
apiVersion: policy.linkerd.io/v1alpha1
kind: MeshTLSAuthentication
metadata:
  name: authors-get-authn
  namespace: booksapp
spec:
  identities:
    - "books.booksapp.serviceaccount.identity.linkerd.cluster.local"
    - "webapp.booksapp.serviceaccount.identity.linkerd.cluster.local"
EOF
```

This command creates an [`AuthorizationPolicy`] whose `targetRef` selects the
`authors-get-route` [`HTTPRoute`] resource we just created. An
[`AuthorizationPolicy`] resource can require a a variety of forms of
authentication. In this case, we we've defined a [`MeshTLSAuthentication`]
resource, named `authors-get-authn`, that requires the TLS identity of the
client to match the `ServiceAccount` of either the `books` service or the
`webapp` service.

Additionally, because we have created an [`HTTPRoute`] referencing the `authors`
service, the default route for liveness and readiness probes will no longer be
used, and the `authors` service will become unready.

Therefore, we must also create a [`HTTPRoute`] and [`AuthorizationPolicy`] so
that probes from the Kubelet are still authorized:

```bash
kubectl apply -f - <<EOF

---
apiVersion: policy.linkerd.io/v1beta1
kind: HTTPRoute
metadata:
  name: authors-probe-route
  namespace: booksapp
spec:
  parentRefs:
    - name: authors-server
      kind: Server
      group: policy.linkerd.io
  rules:
    - matches:
      - path:
          value: "/ping"
        method: GET
---
apiVersion: policy.linkerd.io/v1alpha1
kind: NetworkAuthentication
metadata:
  name: authors-probe-authn
  namespace: booksapp
spec:
  networks:
  - cidr: 0.0.0.0/0
  - cidr: ::/0
---
apiVersion: policy.linkerd.io/v1alpha1
kind: AuthorizationPolicy
metadata:
  name: authors-probe-policy
  namespace: booksapp
spec:
  targetRef:
    group: policy.linkerd.io
    kind: HTTPRoute
    name: authors-probe-route
  requiredAuthenticationRefs:
    - name: authors-probe-authn
      kind: NetworkAuthentication
      group: policy.linkerd.io
EOF
```

Here, we use the [`NetworkAuthentication`] resource (rather than
[`MeshTLSAuthentication`]) to authenticate only probes
coming from the local network (0.0.0.0).

Running `linkerd viz authz` again, we can now see that our new policies exist:

```bash
$ linkerd viz authz -n booksapp deploy/authors
ROUTE                SERVER                       AUTHORIZATION                             UNAUTHORIZED  SUCCESS     RPS  LATENCY_P50  LATENCY_P95  LATENCY_P99
authors-get-route    authors-server               authorizationpolicy/authors-get-policy          0.0rps  100.00%  0.1rps          2ms          2ms          2ms
authors-probe-route  authors-server               authorizationpolicy/authors-probe-policy        0.0rps  100.00%  0.1rps          1ms          1ms          1ms
default              default:all-unauthenticated  default/all-unauthenticated                     0.0rps  100.00%  0.1rps          2ms          2ms          2ms
probe                default:all-unauthenticated  default/probe                                   0.0rps  100.00%  0.2rps          1ms          1ms          1ms
```

And, if we open [http://localhost:7000/](http://localhost:7000/) and interact
with the frontend, the lists of authors and books are still displayed correctly.

## Authorizing additional routes

However, if we try to create a new author or delete an existing author in the
web UI, we may notice that something is amiss.

Attempting to delete an author results in a "not found" error in the web UI:

![Not found](/docs/images/books/delete-404.png "Not found")

and similarly, adding a new author takes us to an error page.

This is because creating or deleting an author will send a `PUT` or `DELETE`
request, respectively, from `webapp` to `authors`. The route we created to
authorize `GET` requests does not match `PUT` or `DELETE` requests, so the
`authors` proxy rejects those requests with a 404 error.

To resolve this, we'll create an additional [`HTTPRoute`] resource that matches
`PUT`, `POST`, and `DELETE` requests:

```bash
kubectl apply -f - <<EOF

---
apiVersion: policy.linkerd.io/v1beta1
kind: HTTPRoute
metadata:
  name: authors-modify-route
  namespace: booksapp
spec:
  parentRefs:
    - name: authors-server
      kind: Server
      group: policy.linkerd.io
  rules:
    - matches:
      - path:
          value: "/authors/"
          type: "PathPrefix"
        method: DELETE
      - path:
          value: "/authors/"
          type: "PathPrefix"
        method: PUT
      - path:
          value: "/authors.json"
        method: POST
EOF
```

What happens if we try to delete an author _now_? We still see a failure, but a
different one:

![Internal server error](/docs/images/books/delete-503.png "Internal server error")

This is because we have created a _route_ matching `DELETE`, `PUT`, and `POST`
requests, but we haven't _authorized_ requests to that route. Running the
`linkerd viz authz` command again confirms this &mdash; note the unauthorized
requests to `authors-modify-route`:

```bash
$ linkerd viz authz -n booksapp deploy/authors
ROUTE                 SERVER                       AUTHORIZATION                             UNAUTHORIZED  SUCCESS     RPS  LATENCY_P50  LATENCY_P95  LATENCY_P99
authors-get-route     authors-server               authorizationpolicy/authors-get-policy               -        -       -            -            -            -
authors-modify-route  authors-server                                                               9.7rps    0.00%  0.0rps          0ms          0ms          0ms
authors-probe-route   authors-server               authorizationpolicy/authors-probe-policy        0.0rps  100.00%  0.1rps          1ms          1ms          1ms
default               default:all-unauthenticated  default/all-unauthenticated                     0.0rps  100.00%  0.1rps          1ms          1ms          1ms
probe                 default:all-unauthenticated  default/probe                                   0.0rps  100.00%  0.2rps          1ms          1ms          1ms
```

Now, let's create authorization and authentication policy resources to authorize
this route:

```bash
kubectl apply -f - <<EOF

---
apiVersion: policy.linkerd.io/v1alpha1
kind: AuthorizationPolicy
metadata:
  name: authors-modify-policy
  namespace: booksapp
spec:
  targetRef:
    group: policy.linkerd.io
    kind: HTTPRoute
    name: authors-modify-route
  requiredAuthenticationRefs:
    - name: authors-modify-authn
      kind: MeshTLSAuthentication
      group: policy.linkerd.io
---
apiVersion: policy.linkerd.io/v1alpha1
kind: MeshTLSAuthentication
metadata:
  name: authors-modify-authn
  namespace: booksapp
spec:
  identities:
    - "webapp.booksapp.serviceaccount.identity.linkerd.cluster.local"
EOF
```

These configurations are very similar to the [`AuthorizationPolicy`] and
[`MeshTLSAuthentication`] resources we created in the previous section. However,
in this case, we only authenticate the `webapp` deployment's `ServiceAccount`
(and _not_ the `books` deployment) to access this route.

Now, if we attempt to delete an author in the frontend once again, we can:

![Author deleted](/docs/images/books/delete-ok.png "Author deleted")

Similarly, we can now create a new author successfully, as well:

![Author created](/docs/images/books/create-ok.png "Author created")

Running the `linkerd viz authz` command one last time, we now see that all
traffic is authorized:

```bash
$ linkerd viz authz -n booksapp deploy/authors
ROUTE                 SERVER                       AUTHORIZATION                              UNAUTHORIZED  SUCCESS     RPS  LATENCY_P50  LATENCY_P95  LATENCY_P99
authors-get-route     authors-server               authorizationpolicy/authors-get-policy           0.0rps  100.00%  0.1rps          0ms          0ms          0ms
authors-modify-route  authors-server               authorizationpolicy/authors-modify-policy        0.0rps  100.00%  0.0rps          0ms          0ms          0ms
authors-probe-route   authors-server               authorizationpolicy/authors-probe-policy         0.0rps  100.00%  0.1rps          1ms          1ms          1ms
default               default:all-unauthenticated  default/all-unauthenticated                      0.0rps  100.00%  0.1rps          1ms          1ms          1ms
probe                 default:all-unauthenticated  default/probe                                    0.0rps  100.00%  0.2rps          1ms          1ms          1ms
```

## Next Steps

We've now covered the basics of configuring per-route authorization policies
with Linkerd. For more practice, try creating additional policies to restrict
access to the `books` service as well. Or, to learn more about Linkerd
authorization policy in general, and the various configurations that are
available, see the [Policy reference
docs](../../reference/authorization-policy/).

[`Server`]: ../../reference/authorization-policy/#server
[`HTTPRoute`]: ../../reference/authorization-policy/#httproute
[`AuthorizationPolicy`]:
    ../../reference/authorization-policy/#authorizationpolicy
[`MeshTLSAuthentication`]:
    ../../reference/authorization-policy/#meshtlsauthentication
[`NetworkAuthentication`]:
    ../../reference/authorization-policy/#networkauthentication
