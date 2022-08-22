+++
title = "Configuring Per-Route Policy"
description = "Fine-grained authorization policies can be configured for individual HTTP routes."
aliases = []
+++

In addition to [enforcing authorization policies at the service
level](restricting-access), finer-grained authorization policies can also be
configured for individual HTTP routes. In this example, we'll use the Books demo
app to demonstrate how to control which clients can access particular routes on
a service.

This is an advanced example that demonstrates more complex policy configuration.
For a basic introduction to Linkerd authorization policy, start with the
[Restricting Access to Services](restricting-access) example. For more
comprehensive documentation of the policy resources, see the
[Policy reference docs](../../reference/authorization-policy/).

## Setup

Ensure that you have Linkerd version stable-2.12.0 or later installed, and that
it is healthy:

```bash
$ linkerd install | kubectl apply -f -
...
$ linkerd check -o short
...
```


In order to observe what's going on, we'll also install the Viz extension:

```bash
$ linkerd viz install | kubectl apply -f -
...
$ linkerd viz check
...
```

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

{{< fig src="/images/books/frontend.png" title="Frontend" >}}

## Creating per-route policy resources

Both the `books` service and the `webapp` service in the demo application are
clients of the `authors` service. 

However, these services send different requests to the `authors` service. The
`books` service should only send `GET`
requests to the `/authors/:id.json` route, to get the author associated with a particular book. Meanwhile, the `webapp` service may also send `DELETE` and
`PUT` requests to `/authors`, and `POST` requests to `/authors.json`, as it
allows the user to create and delete authors.

Since the `books` service should never need to create or delete authors, we will
create separate authorization policies for the `webapp` and `books` services,
restricting which services can access individual routes of the `authors` service.