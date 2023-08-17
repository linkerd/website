---
author: 'flynn'
date: 2023-06-13T00:00:00Z
title: |-
  Workshop recap: Dynamic Request Routing and Circuit Breaking
url:
  /2023/06/13/dynamic-request-routing-circuit-breaking/
thumbnail: '/uploads/2023/06/dnevozhai-routing-7nrsVjvALnA-unsplash-square.jpg'
featuredImage: '/uploads/2023/06/dnevozhai-routing-7nrsVjvALnA-unsplash-rect.jpg'
tags: [Linkerd, linkerd, gitops, flux, flagger]
featured: false
---

{{< fig
  alt="Dynamic Request Routing"
  title="image credit: [Denys Nevozhai](https://unsplash.com/@dnevozhai?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText)"
  src="/uploads/2023/06/dnevozhai-routing-7nrsVjvALnA-unsplash-rect.jpg" >}}

_This blog post is based on a workshop that I recently delivered at Buoyant’s
[Service Mesh Academy](https://buoyant.io/service-mesh-academy). If this seems
interesting, check out the [full
recording](https://buoyant.io/service-mesh-academy/circuit-breaking-and-dynamic-routing-deep-dive/)!_

Linkerd 2.13 adds two long-requested features to Linkerd: _dynamic request
routing_ and _circuit breaking_.

- Dynamic request routing permits HTTP routing based on headers, HTTP method,
  etc.

- Circuit breaking is a resilience feature that allows Linkerd to stop sending
  requests to endpoints that fail too much.

While Linkerd 2.12 has been able to do some dynamic request routing, Linkerd
2.13 expands quite a bit on the feature. Circuit breaking is completely new in
Linkerd 2.13.

## Dynamic Request Routing

In Linkerd 2.11 and earlier, the only mechanism for any sort of dynamic
routing used the TrafficSplit extension and the `linkerd-smi` extension to
support a coarse-grained routing behavior based on the service name and the
desired percentage of traffic to be split. For example:

- Progressive delivery: 1% of the requests to the `foo` workload are sent to a
  new version (`foo-new`), while the remaining 99% continue to be routed to
  the original version. If all goes well, the percentages are shifted over
  time until all the requests are going to `foo-new`.

- Multi-cluster/failover: All of the requests to the `foo` workload get routed
  to a different cluster via a mirrored `foo-west` Service.

Linkerd 2.12 introduced support for basic header-based routing, using the
HTTPRoute CRD from the Gateway API. This allowed for routing based on the
value of a header, but it didn't support weighted routing at the same time.

Dynamic request routing in Linkerd 2.13 brings these two worlds together using
the HTTPRoute CRD, and expands it further by supporting weighted routing based
on request headers, verbs, or other attributes of the request (though not the
request body). This is much more powerful than what was possible with 2.12 and
earlier. For example:

- Progressive delivery is possible without using the `linkerd-smi` extension
  at all.

- Progressive delivery can be combined with header-based routing, for example
  per-user canaries: use a header to select a particular group of users, then
  canary only that group of users using a new version of a workload. This
  enables early rollout of a new feature only for a specific group of users,
  while most users continue to use the stable version.

- A/B testing anywhere in the call graph: Since dynamic request routing
  permits separating traffic based on headers or verbs, it's possible to split
  users into multiple groups and route each group to a distinct version of a
  workload. This allows for experimentation and comparison of different
  implementations or features.

### Sidebar: Dynamic Request Routing and the Gateway API

The [Gateway API] is a Kubernetes SIG-Networking project started in 2020,
primarily to address the challenges related to the proliferation of
annotations in use on the Ingress resource. In 2022, the Gateway API project
began the GAMMA (Gateway API for Mesh Management and Administration)
initiative to explore how to use the Gateway API for mesh networking. Linkerd
is an active participant in both efforts: the power and flexibility of the
Gateway API makes it easier to expand Linkerd's capabilities while maintaining
its overall best-in-class operational simplicity.

One important caveat, though, is that since the Gateway API was originally
designed to manage ingress traffic - traffic from outside the cluster coming
in - its conformance tests are not yet well-suited to service meshes, so
Linkerd can't yet be fully conformant with the Gateway API. For this reason,
Linkerd uses the HTTPRoute resource in the `policy.linkerd.io` APIGroup,
rather than the official Gateway API APIgroup. There's work actively underway
to improve this situation.

[Gateway API]: https://gateway-api.sigs.k8s.io/

### Dynamic Request Routing Examples

First, a simple canary example. This example does a 50/50 split for requests
to the `color` Service, routing half to the endpoints being the actual `color`
Service and half to those behind the `color2` Service.

```yaml
apiVersion: policy.linkerd.io/v1beta2
kind: HTTPRoute
metadata:
 name: color-canary
 namespace: faces
spec:
 parentRefs:
   - name: color
     kind: Service
     group: core
     port: 80           # Match port numbers with what’s in the Service resource
 rules:
 - backendRefs:
   - name: color
     port: 80
     weight: 50         # Adjust the weights to control balancing
 - backendRefs:
   - name: color2
     port: 80
     weight: 50
```

I'm being careful here about the distinction between a Service and the
endpoints behind the Service, because the HTTPRoute acts on _requests sent to
a particular service_, routing them to _endpoints behind a service_. This is
why having `color` in the `parentRefs` stanza and also in one of the
`backendRefs` stanzas works, without creating a loop.

Here's an example of A/B testing. Here, requests sent to the `smiley` Service
with the header

```text
X-Faces-User: testuser
```

get routed to endpoints behind the `smiley2` Service, while other requests
continue on to endpoints behind the `smiley` Service.

```yaml
apiVersion: policy.linkerd.io/v1beta2
kind: HTTPRoute
metadata:
 name: smiley-a-b
 namespace: faces
spec:
 parentRefs:
   - name: smiley
     kind: Service
     group: core
     port: 80
 rules:
 - matches:
   - headers:
     - name: "x-faces-user"   # X-Faces-User: testuser goes to smiley2
       value: "testuser"
   backendRefs:
     - name: smiley2
       port: 80
 - backendRefs:
   - name: smiley
     port: 80
```

One critical point about the A/B test: Linkerd can do dynamic request routing
anywhere, but of course if you want to route on a header, you need to make
sure that header is present at the place you want to use it for routing! This
may mean that you need to be careful to propagate headers through the various
workloads of your application.

You can find more details about dynamic request routing in its documentation,
at <https://linkerd.io/2/tasks/configuring-dynamic-request-routing/>.

## Circuit Breaking

Circuit breaking is new to Linkerd 2.13, but it's been long requested by
users. It's a mechanism to try to avoid overwhelming a failing workload
endpoint with additional traffic:

- A workload endpoint starts to fail.
- Linkerd detects failures from the endpoint and temporarily stops routing
  requests to that endpoint (_opening_ the breaker).
- After a little while, a test request is sent.
- If the test succeeds, thecircuit breaker is _closed_ again, allowing
  requests to resume being delivered.

In Linkerd 2.13, circuit breaking is a little limited:

- Circuit breakers can only be opened when a certain number of consecutive
  failures occur.
- "Failure" means an HTTP 5xx response; Linkerd doesn't currently support
  response classification for circuit breakers.
- Circuit breakers are configured through annotations on a Service, with all
  the relevant annotations containing the term "failure-accrual" in their
  names (from the internal name for circuit breaking in the code).

Circuit breakers in Linkerd are expected to gain functionality rapidly, so
keep an eye out as new releases happen (and the annotation approach should be
supplanted with Gateway API CRDs).

## Circuit Breaking Example

To break the circuit after four consecutive request failures, apply these
annotations to a Service:

```text
balancer.linkerd.io/failure-accrual: consecutive
balancer.linkerd.io/failure-accrual-consecutive-max-failures: 4
```

The `failure-accrual: consecutive` annotation switches on circuit breaking,
and sets it to the "consecutive failure" mode (which is the only supported
mode in 2.13).

All configuration for the "consecutive failure" mode of circuit breaking uses
annotations that start with `failure-accrual-consecutive-`; the
`failure-accrual-consecutive-max-failures` annotation sets the number of
consecutive failures after which the circuit breaker will open.

Try reenabling traffic after 30 seconds:

```text
balancer.linkerd.io/failure-accrual-consecutive-min-penalty: 30s
```

(This is for the first attempt. After that, the delay grows exponentially.)

Don’t ever wait more than 120 seconds between retries:

```text
balancer.linkerd.io/failure-accrual-consecutive-max-penalty: 120s
```

More information on circuit breaking is available in its documentation, at
<https://linkerd.io/2/tasks/circuit-breakers/>.

## Gotchas

The biggest gotcha of them all is that in Linkerd 2.13, **ServiceProfiles do
not compose with dynamic request routing and circuit breaking**.

Getting specific, this means that when a ServiceProfile defines routes, it
takes precedence over other HTTPRoutes with conflicting routes, and it also
takes precedence over circuit breakers associated with the workloads
referenced in the ServiceProfile. This is expected to be the case for the
foreseeable future, to minimize surprises when upgrading from a version of
Linkerd without the new features.

The challenge here, of course, is that there are still several things that
require ServiceProfiles in Linkerd 2.13 (for example, retries and timeouts).
The Linkerd team is actively working to quickly make all of this better, with
a particular short-term focus on rapidly bringing HTTPRoutes to feature parity
with ServiceProfiles.

### Debugging Dynamic Request Routing and Circuit Breaking

The most typical failure you'll see when trying to use these new features is
to enable a new feature and see that it doesn't seem to be active. There are
some simple rules of thumb for debugging:

- First, *check for ServiceProfiles*. Remember that conflicting
  ServiceProfiles will always disable HTTPRoutes or circuit breakers.

- Second, you may need to restart Pods after removing conflicting
  ServiceProfiles. This is because the Linkerd proxy needs to determine
  whether it is running in 2.12 mode or 2.13 mode, and in some situations it's
  still possible for it not to shift between modes smoothly.

- Finally, there's a new `linkerd diagnostics policy` command, which will dump
  a large amount of internal Linkerd state describing what exactly the control
  plane is doing with routing. It's _extremely_ verbose, but can show you an
  enormous amount of information that can help with debugging problems.

## Dynamic Request Routing and Circuit Breaking

Taken together, dynamic request routing and circuit breaking are two important
new additions to Linkerd 2.13. While still a bit limited in 2.13, keep an eye
out: we have big plans for these features as Linkerd's development continues.

----

_If you want more on this topic, check out the [Circuit Breaking and Dynamic
Request Routing Deep
Dive](https://buoyant.io/service-mesh-academy/circuit-breaking-and-dynamic-routing-deep-dive/)
Service Mesh Academy workshop for hands-on exploration of everything I've
talked about here! And, as always, feedback is always welcome -- you can find
me as `@flynn` on the [Linkerd Slack](https://slack.linkerd.io)._
