+++
title = "Demo: Books"
description = "Try out some of Linkerd's features, such as per-route metrics with a demo application."
+++

This is a Ruby application that helps you manage your bookshelf. It consists of
multiple microservices and uses JSON over HTTP to communicate with the other
services. There are three services:

- [webapp](https://github.com/BuoyantIO/booksapp/blob/master/webapp.rb): the
  frontend

- [authors](https://github.com/BuoyantIO/booksapp/blob/master/authors.rb): an
  API to manage the authors in the system

- [books](https://github.com/BuoyantIO/booksapp/blob/master/books.rb): an API
  to manage the books in the system

For demo purposes, the app comes with a simple traffic generator. The overall
topology looks like this:

{{< fig src="/images/books/topology.png" title="Topology" >}}

## Prerequisites

To complete this guide, you'll need to have installed
Linkerd on your cluster. Follow the [installing](/2/tasks/install/) guide to get
that setup if you've not already.

## Install the app

To get started, let's install the books app onto your cluster. In your local
terminal, run:

```bash
kubectl create ns booksapp && \
  curl -sL https://run.linkerd.io/booksapp.yml \
  | kubectl -n booksapp apply -f -
```

This command creates a namespace for the demo, downloads its Kubernetes
resource manifest and uses `kubectl` to apply it to your cluster. The
app is comprised of Kubernetes deployments and services that run in the
booksapp namespace.

Downloading a bunch of containers for the first time takes a little while.
Kubernetes can tell you when all the services are running and ready for traffic.
Wait for that to happen by running:

```bash
kubectl -n booksapp rollout status deploy webapp
```

You can also take a quick look at all the components that were added to your
cluster by running:

```bash
kubectl -n booksapp get all
```

Once the rollout has completed successfully, you can get access to the app
itself by port-forwarding `webapp` locally:

```bash
kubectl -n booksapp port-forward svc/webapp 7000 &
```

Open [http://localhost:7000/](http://localhost:7000/) in your browser to see the
frontend.

{{< fig src="/images/books/frontend.png" title="Frontend" >}}

As you can imagine, there is an error in the app. If you click "Add Book", it
will fail 50% of the time. This is a classic case of non-obvious, intermittent
failure – the type that drives service owners mad because it is so difficult to
debug. Because Kubernetes is interested in keeping processes running, it will
show you that everything is running. It looks like everything’s fine, but you
know the application is returning errors.

{{< fig src="/images/books/failure.png" title="Failure" >}}

## Add Linkerd

There are a couple of ways to add Linkerd to our service. For demo purposes,
the easiest is to do something like this:

```bash
kubectl get -n booksapp deploy -o yaml \
  | linkerd inject - \
  | kubectl apply -f -
```

This command retrieves the manifest of all deployments in the `booksapp`
namespace, runs the manifest through `linkerd inject`, and then re-applies with
`kubectl apply`. The `inject` command adds two containers to each deployment's
pod spec:

- An `initContainer` that sets up `iptables` to forward all incoming and
  outgoing traffic through Linkerd's proxy.
- A `container` that runs the proxy.

As with `install`, `inject` is a pure text operation. This means that you can
inspect the input and output before you use it. As these are deployments,
Kubernetes will slowly update pods one at a time. There can be live traffic
while Linkerd is added!

If you're interested in a more automatic way to inject deployments, check out
the [automating injection](/2/tasks/automating-injection/) documentation.

## Debugging

Let's use Linkerd to discover the root cause of this app's failures. To check
out the Linkerd dashboard, run:

```bash
linkerd dashboard &
```

{{< fig src="/images/books/dashboard.png" title="Dashboard" >}}

You should see all the services in the `booksapp` namespace show up. There will
be success rate, requests per second, and latency percentiles.

That’s cool, but you’ll notice that the success rate for `webapp` is not 100%.
This is because the traffic generator is submitting new books. You can do the
same thing yourself and push that success rate even lower. Click on `webapp` in
the Linkerd dashboard for a live debugging session.

You should now be looking at the detail view for the `webapp` service. You’ll
see that `webapp` is taking traffic from `traffic` the load generator, and has
two outgoing dependencies: `authors` and `book`. One is the service for pulling
in author information and the other is the service for pulling in book
information.

{{< fig src="/images/books/webapp-detail.png" title="Detail" >}}

A failure in a dependent service may be exactly what’s causing the errors that
`webapp` is returning (and the errors you as a user can see when you click). We
can see that `books` service is also failing. Let’s scroll a little further down
the page, we’ll see a live list of all traffic endpoints that webapp is
receiving. This is interesting:

{{< fig src="/images/books/top.png" title="Top" >}}

Aha! We can see that inbound traffic coming from the `webapp` service going to
the `books` service is failing a significant percentage of the time. That could
explain why `webapp` was throwing intermittent failures. Let’s click on the 🔬
icon to look at the actual request and response stream.

{{< fig src="/images/books/tap.png" title="Tap" >}}

Indeed, many of these requests are returning 500’s.

It was surprisingly easy to diagnose an intermittent issue that affected only a
single route. You now have everything you need to open a detailed bug report
explaining exactly what the root cause is. If the `books` service was your own,
you know exactly where to look in the code.

## Service Profiles

To understand the root cause, we used live traffic. For some issues this is
great, but what happens if the issue is intermittent and happens in the middle of
the night? [Service profiles](/2/features/service-profiles/) provide Linkerd
with some additional information about your services. These define the routes
that you're serving and, among other things, allow for the collection of metrics
on a per route basis. With Prometheus storing these metrics, you'll be able to
sleep soundly and look up intermittent issues in the morning.

One of the easiest ways to get service profiles setup is by using existing
[OpenAPI (Swagger)](https://swagger.io/docs/specification/about/) specs. This
demo has published specs for each of its services. You can create a service
profile for `webapp` by running:

```bash
curl -sL https://run.linkerd.io/booksapp/webapp.swagger \
  | linkerd -n booksapp profile --open-api - webapp \
  | kubectl -n booksapp apply -f -
```

This command will do three things:

1. Fetch the swagger specification for `webapp`.
1. Take the spec and convert it into a service profile by using the `profile`
   command.
1. Apply this configuration to the cluster.

Alongside `install` and `inject`, `profile` is also a pure text operation. Check
out the profile that is generated:

```yaml
apiVersion: linkerd.io/v1alpha1
kind: ServiceProfile
metadata:
  creationTimestamp: null
  name: webapp.booksapp.svc.cluster.local
  namespace: booksapp
spec:
  routes:
  - condition:
      method: GET
      pathRegex: /
    name: GET /
  - condition:
      method: POST
      pathRegex: /authors
    name: POST /authors
  - condition:
      method: GET
      pathRegex: /authors/[^/]*
    name: GET /authors/{id}
  - condition:
      method: POST
      pathRegex: /authors/[^/]*/delete
    name: POST /authors/{id}/delete
  - condition:
      method: POST
      pathRegex: /authors/[^/]*/edit
    name: POST /authors/{id}/edit
  - condition:
      method: POST
      pathRegex: /books
    name: POST /books
  - condition:
      method: GET
      pathRegex: /books/[^/]*
    name: GET /books/{id}
  - condition:
      method: POST
      pathRegex: /books/[^/]*/delete
    name: POST /books/{id}/delete
  - condition:
      method: POST
      pathRegex: /books/[^/]*/edit
    name: POST /books/{id}/edit
```

The `name` refers to the FQDN of your Kubernetes service,
`webapp.booksapp.svc.cluster.local` in this instance. Linkerd uses the `Host`
header of requests to associate service profiles with requests. When the proxy
sees a `Host` header of `webapp.booksapp.svc.cluster.local`, it will use that to
look up the service profile's configuration.

Routes are simple conditions that contain the method (`GET` for example) and a
regex to match the path. This allows you to group REST style resources together
instead of seeing a huge list. The names for routes can be whatever you'd like.
For this demo, the method is appended to the route regex.

To get profiles for `authors` and `books`, you can run:

```bash
curl -sL https://run.linkerd.io/booksapp/authors.swagger \
  | linkerd -n booksapp profile --open-api - authors \
  | kubectl -n booksapp apply -f -
curl -sL https://run.linkerd.io/booksapp/books.swagger \
  | linkerd -n booksapp profile --open-api - books \
  | kubectl -n booksapp apply -f -
```

Verifying that this all works is easy when you use `linkerd tap`. Each live
request will show up with what `:authority` or `Host` header is being seen as
well as the `:path` and `rt_route` being used. Run:

```bash
linkerd -n booksapp tap deploy/webapp -o wide | grep req
```

This will watch all the live requests flowing through `webapp` and look
something like:

```bash
req id=0:1 proxy=in  src=10.1.3.76:57152 dst=10.1.3.74:7000 tls=disabled :method=POST :authority=webapp.default:7000 :path=/books/2878/edit src_res=deploy/traffic src_ns=foobar dst_res=deploy/webapp dst_ns=default rt_route=POST /books/{id}/edit
```

As you can see:

- `:authority` is the correct host
- `:path` correctly matches
- `rt_route` contains the name of the route

These metrics are part of the [`linkerd routes`](/2/reference/cli/routes/)
command instead of [`linkerd stat`](/2/reference/cli/stat/). To see the metrics
that have accumulated so far, run:

```bash
linkerd -n booksapp routes svc/webapp
```

This will output a table of all the routes observed and their golden metrics.
The `[DEFAULT]` route is a catch all for anything that does not match the
service profile.

Profiles can be used to observe *outgoing* requests as well as *incoming*
requests. To do that, run:

```bash
linkerd -n booksapp routes deploy/webapp --to svc/books
```

This will show all requests and routes that originate in the `webapp` deployment
and are destined to the `books` service. Similarly to using `tap` and `top`
views in the [debugging](#debugging) section, the root cause of errors in this
demo is immediately apparent:

```bash
ROUTE                     SERVICE   SUCCESS      RPS   LATENCY_P50   LATENCY_P95   LATENCY_P99
DELETE /books/{id}.json     books   100.00%   0.5rps          18ms          29ms          30ms
GET /books.json             books   100.00%   1.1rps           7ms          12ms          18ms
GET /books/{id}.json        books   100.00%   2.5rps           6ms          10ms          10ms
POST /books.json            books    52.24%   2.2rps          23ms          34ms          39ms
PUT /books/{id}.json        books    41.98%   1.4rps          73ms          97ms          99ms
[DEFAULT]                   books     0.00%   0.0rps           0ms           0ms           0ms
```

## Retries

As it can take awhile to update code and roll out a new version, let's
tell Linkerd that it can retry requests to the failing endpoint. This will
increase request latencies, as requests will be retried multiple times, but not
require rolling out a new version.

In this application, the success rate of requests from the `books` deployment to
the `authors` service is poor. To see these metrics, run:

```bash
linkerd -n booksapp routes deploy/books --to svc/authors
```

The output should look like:

```bash
ROUTE                       SERVICE   SUCCESS      RPS   LATENCY_P50   LATENCY_P95   LATENCY_P99
DELETE /authors/{id}.json   authors     0.00%   0.0rps           0ms           0ms           0ms
GET /authors.json           authors     0.00%   0.0rps           0ms           0ms           0ms
GET /authors/{id}.json      authors     0.00%   0.0rps           0ms           0ms           0ms
HEAD /authors/{id}.json     authors    50.85%   3.9rps           5ms          10ms          17ms
POST /authors.json          authors     0.00%   0.0rps           0ms           0ms           0ms
[DEFAULT]                   authors     0.00%   0.0rps           0ms           0ms           0ms
```

One thing that’s clear is that all requests from books to authors are to the
`HEAD /authors/{id}.json` route and those requests are failing about 50% of the
time.

To correct this, let’s edit the authors service profile and make those
requests retryable by running:

```bash
kubectl -n booksapp edit sp/authors.booksapp.svc.cluster.local
```

You'll want to add `isRetryable` to a specific route. It should look like:

```yaml
spec:
  routes:
  - condition:
      method: HEAD
      pathRegex: /authors/[^/]*\.json
    name: HEAD /authors/{id}.json
    isRetryable: true ### ADD THIS LINE ###
```

After editing the service profile, Linkerd will begin to retry requests to
this route automatically. We see a nearly immediate improvement in success rate
by running:

```bash
linkerd -n booksapp routes deploy/books --to svc/authors -o wide
```

This should look like:

```bash
ROUTE                       SERVICE   EFFECTIVE_SUCCESS   EFFECTIVE_RPS   ACTUAL_SUCCESS   ACTUAL_RPS   LATENCY_P50   LATENCY_P95   LATENCY_P99
DELETE /authors/{id}.json   authors               0.00%          0.0rps            0.00%       0.0rps           0ms           0ms           0ms
GET /authors.json           authors               0.00%          0.0rps            0.00%       0.0rps           0ms           0ms           0ms
GET /authors/{id}.json      authors               0.00%          0.0rps            0.00%       0.0rps           0ms           0ms           0ms
HEAD /authors/{id}.json     authors             100.00%          2.8rps           58.45%       4.7rps           7ms          25ms          37ms
POST /authors.json          authors               0.00%          0.0rps            0.00%       0.0rps           0ms           0ms           0ms
[DEFAULT]                   authors               0.00%          0.0rps            0.00%       0.0rps           0ms           0ms           0ms
```

You'll notice that the `-o wide` flag has added some columns to the `routes`
view. These show the difference between `EFFECTIVE_SUCCESS` and
`ACTUAL_SUCCESS`. The difference between these two show how well retries are
working. `EFFECTIVE_RPS` and `ACTUAL_RPS` show how many requests are being sent
to the destination service and and how many are being received by the client's
Linkerd proxy.

With retries automatically happening now, success rate looks great but the p95
and p99 latencies have increased. This is to be expected because doing retries
takes time.

## Timeouts

Linkerd can limit how long to wait before failing outgoing requests to another
service. These timeouts work by adding another key to a service profile's routes
configuration.

To get started, let's take a look at the current latency for requests from
`webapp` to the `books` service:

```bash
linkerd -n booksapp routes deploy/webapp --to svc/books
```

This should look something like:

```bash
ROUTE                     SERVICE   SUCCESS      RPS   LATENCY_P50   LATENCY_P95   LATENCY_P99
DELETE /books/{id}.json     books   100.00%   0.6rps           9ms          19ms          20ms
GET /books.json             books   100.00%   1.2rps           7ms          10ms          10ms
GET /books/{id}.json        books   100.00%   2.3rps           7ms          10ms          18ms
POST /books.json            books    48.00%   2.5rps          16ms          28ms          30ms
PUT /books/{id}.json        books    53.97%   1.1rps          75ms          98ms         100ms
[DEFAULT]                   books     0.00%   0.0rps           0ms           0ms           0ms
```

For the purposes of this demo, let's set the timeout to 25ms. Your results will
vary depending on the characteristics of your cluster. To edit the `books`
service profile, run:

```bash
kubectl -n booksapp edit sp/authors.default.svc.cluster.local
```

Update the route that we modified in the previous section to have a timeout:

```yaml
spec:
  routes:
  - condition:
      method: HEAD
      pathRegex: /authors/[^/]*\.json
    name: HEAD /authors/{id}.json
    isRetryable: true
    timeout: 25ms ### ADD THIS LINE ###
```

Linkerd will now return errors to the `webapp` REST client when the timeout is
reached. This timeout includes retried requests and is the maximum
amount of time a REST client would wait for a response.

Run `routes` to see what has changed:

```bash
linkerd -n booksapp routes deploy/webapp --to svc/books -o wide
```

With timeouts happening now, the metrics will change:

```bash
ROUTE                     SERVICE   EFFECTIVE_SUCCESS   EFFECTIVE_RPS   ACTUAL_SUCCESS   ACTUAL_RPS   LATENCY_P50   LATENCY_P95   LATENCY_P99
DELETE /books/{id}.json     books             100.00%          0.3rps          100.00%       0.3rps          15ms          20ms          20ms
GET /books.json             books             100.00%          0.6rps          100.00%       0.6rps           8ms          10ms          10ms
GET /books/{id}.json        books              14.78%          4.8rps          100.00%       0.7rps           6ms          10ms          15ms
POST /books.json            books              51.95%          1.3rps           51.95%       1.3rps          17ms          28ms          30ms
PUT /books/{id}.json        books              53.66%          0.7rps           53.66%       0.7rps          75ms          98ms         100ms
[DEFAULT]                   books               0.00%          0.0rps            0.00%       0.0rps           0ms           0ms           0ms
```

Note that the p99 latency appears to be greater than our 25ms timeout due to
histogram bucketing artifacts.
