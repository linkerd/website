---
title: |-
  Workshop recap: Linkerd and Ingress Controllers: Bringing the Outside World In
date: 2023-02-21T00:00:00Z
slug: linkerd-and-ingress
keywords: [linkerd, mtls, tls, ingress, emissary, nginx, envoy gateway]
params:
  author: flynn
  showCover: true
---

_This blog post is based on a workshop I recently delivered at Buoyant’s
[Service Mesh Academy](https://buoyant.io/service-mesh-academy). If this seems
interesting, check out the
[full recording](https://buoyant.io/service-mesh-academy/linkerd-and-ingress-controllers)!_

No matter what you're working on in the cloud-native world, you will always
start by needing to solve the _Ingress Problem_: how do you give users outside
your cluster a way to use (some of) the services inside your cluster? There's a
whole class of tools that exist to solve this problem, collectively called
_ingress controllers_, so let's take a quick look at them -- and at how Linkerd
works with them.

## Ingress Controllers

"Ingress controller" is a broad term for software running in Kubernetes that
mediates access from the outside world coming in to the cluster. There are a lot
of different ingress controllers, with different strengths and weaknesses, but
all of them have to provide certain basic functionality:

- First, they all sit at the very edge of a cluster and are exposed directly to
  the Internet. This implies that they _all_ have to be very careful about
  security.

  - A common model here is that the ingress controller will be associated with a
    Kubernetes Service of type `LoadBalancer`, providing a way for the cluster
    to route traffic from outside the cluster directly to the ingress controller
    while still blocking traffic to other services.

- Second, they all provide a way to control how requests from outside the
  cluster are routed. Typically, they support sophisticated controls at layer 7;
  many of them also support some layer 4 routing as well.

  - An example at layer 7 might be something like "route any HTTP request where
    the `path` starts with `/foo/` to my `foo` service".

  - An example at layer 4 might be something like "route any incoming TCP
    traffic on port 1234 to my `bar` service".

  The way the user configures routing can vary widely between ingress
  controllers.

- Third, ingress controllers typically also have the capability of terminating
  and originating TLS connections. This gives them an important role in bridging
  the security domains outside and inside the cluster.

- Finally, the most popular ingress controllers also offer features like user
  authentication, rate limiting, circuit breaking, etc., and you may hear such
  ingress controllers referred to as _API Gateways_.

## Ingress Controllers and Linkerd

Linkerd generally works well with most ingress controllers – you're free to use
whichever one is the best fit for your users and application. This is because to
Linkerd, the ingress controller is just another meshed workload, and to the
ingress controller, Linkerd is (usually) invisible.

### The Ingress Controller Is Just Another Meshed Workload

A significant difference between Linkerd and some other meshes is that there's
almost nothing special about an ingress controller from Linkerd's perspective:
it's just a workload that's part of the mesh. The fact that it's a workload that
can receive traffic from the outside world is almost irrelevant: you'll still
inject it into the mesh, it will still get automatic mTLS and metrics from
Linkerd, and all the usual Linkerd features will still work.

The one way that it _is_ likely to be different from other workloads is that
you'll probably want to tell Linkerd to skip the inbound ports for the ingress
controller. If you don't do this, the ingress controller won't be able to see
the IP address of incoming connections: every connection will appear to
originate with the Linkerd proxy.

To skip inbound ports, use the `config.linkerd.io/skip-inbound-ports`
annotation. Note that you need to use the port on which the ingress controller
is listening, not the port that the client will see! So, for example, if your
ingress controller is behind a Service like

```yaml
apiVersion: v1
kind: Service
metadata:
  name: myservice
spec:
  type: LoadBalancer
  ports:
    - name: http
      port: 80
      protocol: TCP
      targetPort: 8080
```

then you would need to use `config.linkerd.io/skip-inbound-ports: 8080`  –
trying to skip inbound port 80 wouldn't do anything.

### Linkerd Is (Mostly) Invisible

From the ingress controller's perspective, Linkerd is mostly invisible, with one
very important caveat: the ingress controller should route to _Services_, not
the _endpoints_ of Services. Kubernetes terminology here can be confusing, so
bear with me for a moment.

A Kubernetes Service resource - glossing over a lot of details - associates a
name in the cluster's DNS with a set of Pods. Each Pod has an IP address, and
the Service itself has its own IP, different from that of any of the Pods.
Collectively, the IP addresses of the Pods are called the _endpoints_ of the
Service associated with them.

(To further confuse things, there are Kubernetes resources called Endpoints and
EndpointSlice, but here we're talking about "endpoints" as the set of Pod IP
addresses.)

Linkerd expects that a connection to a given Service will be sent to the
Service's IP address, _not_ directly to one of its endpoints. Your ingress
controller might need to be configured specifically to do this. Some ingress
controllers can _only_ route to endpoints: those will have to be injected with
`linkerd.io/inject: ingress` rather than `linkerd.io/inject: enabled` – if
possible, though, it's much better to configure the ingress controller to route
to the Service instead.

## Some Specific Examples

We'll talk briefly about using three specific ingress controllers with Linkerd:
Emissary-ingress, NGINX, and Envoy Gateway.

### Emissary-ingress

[Emissary-ingress](https://www.getambassador.io/products/api-gateway) is an
open-source, Kubernetes-native, self-service API Gateway. It's a CNCF Incubating
project, configured using its own CRDs (such as the
[`Mapping`](https://www.getambassador.io/docs/emissary/latest/topics/using/intro-mappings)
CRD), and has been widely adopted since its humble beginnings in 2017.

There's honestly not a lot to say about setting up Emissary with Linkerd: it
basically Just Works.
[Install Emissary](https://www.getambassador.io/docs/emissary/latest/tutorials/getting-started),
inject it into the mesh, and... you're done. Since Emissary defaults to routing
to Services, there's nothing special to do there. About the only thing to
consider is that you'll need to be sure to skip Emissary's inbound ports if you
want Emissary to pay attention to client IP addresses.

### NGINX

[NGINX](https://nginx.org) is an open-source API Gateway and Web server that
actually predates Kubernetes, and served as the basis for one of the first
Kubernetes ingress controllers, called
[`ingress-nginx`](https://docs.nginx.com/nginx-ingress-controller/).
`ingress-nginx` is configured using the Kubernetes Ingress resource, and is
still very widely used in the Kubernetes world.

When deploying `ingress-nginx` with Linkerd, the most important thing to realize
is that it will route to _endpoints_ by default, which is not what you want. To
make `ingress-nginx` route to _Services_, you'll need to include an annotation
on the Ingress resource:

```yaml
nginx.ingress.kubernetes.io/service-upstream: "true"
```

After that's done, installing and meshing `ingress-nginx` should be
straightforward. Again, you'll probably want to skip inbound ports, too.

### Envoy Gateway

[Envoy Gateway](https://gateway.envoyproxy.io) is an _extremely_ new ingress
controller. It's part of the [Envoy proxy](https://envoyproxy.io) CNCF project,
which is the core of two distinct CNCF API gateways (Emissary and Contour). In
2021, people from Emissary, Contour, and Envoy got together and agreed that it
would be better for all concerned to pool their efforts into a single extensible
system that could be used as the basis to build on: that single extensible
system is Envoy Gateway, which first shipped in late 2022.

More accurately, Envoy Gateway _will be_ that single extensible system. At the
time of this writing, Envoy Gateway has just hit version 0.3.0, and it still has
a ways to go to be feature-complete with Emissary and Contour. But it's evolving
quickly, and 0.3.0 is definitely complete enough to see how it works with
Linkerd.

Envoy Gateway is configured using
[Gateway API](https://gateway-api.sigs.k8s.io/) CRDs. There's an interesting
implementation detail about Gateway API ingress controllers: rather than the
user directly installing by hand, the Gateway API spec divides installation into
a _control plane_ part installed by the user, and a _data plane_ part created by
the control plane.

In Envoy Gateway's case, the control plane watches for Gateway resources and
creates a data-plane Deployment for each of them. Whenever a Gateway resource
changes, its data-plane Deployment is restarted. These ephemeral Deployments can
be challenging to inject into the Linkerd mesh: the most effective way to do it
is to put the `linker.io/inject` annotation on the `envoy-gateway-system`
Namespace, since that's where the ephemeral Deployments are created. (You can
put the `config.linkerd.io/skip-inbound-ports` annotation there too.)

Once you know about that, Envoy Gateway works just fine with Linkerd.

## Linkerd and Ingress Controllers

As I said at the beginning, you _will_ need to solve the ingress problem when
you work in the cloud-native world. Linkerd's ability to be agnostic about how
exactly you do so leaves you free to choose an ingress controller that works
well for your situation and your application, reducing your operational
complexity and reducing the effort needed to get you application launched.

---

_If you want more on this topic, check out the Service Mesh Academy workshop on
[Linkerd and ingress controllers: Bringing the outside world in](https://buoyant.io/service-mesh-academy/kubernetes-mtls-with-linkerd)
for hands-on exploration of everything I've talked about here! And, as always,
feedback is always welcome -- you can find me as `@flynn` on the
[Linkerd Slack](https://slack.linkerd.io)._
