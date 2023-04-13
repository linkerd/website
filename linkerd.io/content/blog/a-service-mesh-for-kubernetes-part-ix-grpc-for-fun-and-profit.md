---
slug: 'a-service-mesh-for-kubernetes-part-ix-grpc-for-fun-and-profit'
title: 'A Service Mesh For Kubernetes Part IX: gRPC for fun and profit'
aliases:
  - /2017/04/19/a-service-mesh-for-kubernetes-part-ix-grpc-for-fun-and-profit/
author: 'risha'
date: Wed, 19 Apr 2017 23:34:57 +0000
thumbnail: /uploads/kubernetes9_featured_Twitter_ratio.png
draft: false
featured: false
tags: [Linkerd, linkerd, News, tutorials]
---

As of Linkerd 0.8.5, released earlier this year, [Linkerd supports gRPC and HTTP/2]({{< ref "http2-grpc-and-linkerd" >}})! These powerful protocols can provide significant benefits to applications that make use of them. In this post, we’ll demonstrate how to use Linkerd with gRPC, allowing applications that speak gRPC to take full advantage of Linkerd’s load balancing, service discovery, circuit breaking, and distributed tracing logic.

This article is one of a series of articles about [Linkerd](https://linkerd.io/), [Kubernetes](https://kubernetes.io/), and service meshes. Other installments in this series include:

1. [Top-line service metrics]({{< ref
   "a-service-mesh-for-kubernetes-part-i-top-line-service-metrics" >}})
2. [Pods are great, until they’re not]({{< ref
   "a-service-mesh-for-kubernetes-part-ii-pods-are-great-until-theyre-not" >}})
3. [Encrypting all the things]({{< ref
   "a-service-mesh-for-kubernetes-part-iii-encrypting-all-the-things" >}})
4. [Continuous deployment via traffic shifting]({{< ref "a-service-mesh-for-kubernetes-part-iv-continuous-deployment-via-traffic-shifting" >}})
5. [Dogfood environments, ingress, and edge routing]({{< ref "a-service-mesh-for-kubernetes-part-v-dogfood-environments-ingress-and-edge-routing" >}})
6. [Staging microservices without the tears]({{< ref "a-service-mesh-for-kubernetes-part-vi-staging-microservices-without-the-tears" >}})
7. [Distributed tracing made easy]({{< ref
   "a-service-mesh-for-kubernetes-part-vii-distributed-tracing-made-easy" >}})
8. [Linkerd as an ingress controller]({{< ref "a-service-mesh-for-kubernetes-part-viii-linkerd-as-an-ingress-controller" >}})
9. [gRPC for fun and profit]({{< ref
   "a-service-mesh-for-kubernetes-part-ix-grpc-for-fun-and-profit" >}}) (this article)
10. [The Service Mesh API]({{< ref
    "a-service-mesh-for-kubernetes-part-x-the-service-mesh-api" >}})
11. [Egress]({{< ref "a-service-mesh-for-kubernetes-part-xi-egress" >}})
12. Retry budgets, deadline propagation, and failing gracefully
13. Autoscaling by top-line metrics

For this post we’ll use our familiar `hello world` microservice app and configs, which can be found in the `linkerd-examples` repo ([k8s configs here](https://github.com/BuoyantIO/linkerd-examples/tree/master/k8s-daemonset) and [`hello world` code here](https://github.com/BuoyantIO/linkerd-examples/tree/master/docker/helloworld)).

The `hello world` application consists of two components—a `hello` service which calls a `world` service to complete a request. `hello` and `world` use gRPC to talk to each other. We’ll deploy Linkerd as a DaemonSet (so one Linkerd instance per host), and a request from `hello` to `world` will look like this:

{{> fig
  alt="DaemonSet deployment model: one Linkerd per host"
  title="DaemonSet deployment model: one Linkerd per host"
  src="/uploads/2017/07/buoyant-grpc-daemonset-1024x617.png" >}}

As shown above, when the `hello` service wants to call `world`, the request goes through the *outgoing* router of its host-local Linkerd, which does not send the request directly to the destination `world` service, but to a Linkerd instance running on the same host as `world` (on its *incoming* router). That Linkerd instance then sends the request to the `world` service on its host. This three-hop model allows Linkerd to decouple the application’s protocol from the transport protocol—for example, [by wrapping cross-node connections in TLS][part-iii]. (For more on this deployment topology, see Part II of this series, [Pods are great until they’re not][part-ii].)

## TRYING THIS AT HOME

Let’s see this setup in action! Deploy the `hello` and `world` to the default k8s namespace. These apps rely on the nodeName supplied by the [Kubernetes downward API](https://kubernetes.io/docs/tasks/inject-data-application/downward-api-volume-expose-pod-information/) to find Linkerd. To check if your cluster supports nodeName, you can run this test job:

```bash
kubectl apply -f https://raw.githubusercontent.com/linkerd/linkerd-examples/master/k8s-daemonset/k8s/node-name-test.yml
```

And then looks at its logs:

```bash
kubectl logs node-name-test
```

If you see an ip, great! Go ahead and deploy the hello world app using:

```bash
kubectl apply -f https://raw.githubusercontent.com/linkerd/linkerd-examples/master/k8s-daemonset/k8s/hello-world-grpc.yml
```

If instead you see a “server can’t find …” error, deploy the hello-world legacy version that relies on hostIP instead of nodeName:

```bash
kubectl apply -f https://raw.githubusercontent.com/linkerd/linkerd-examples/master/k8s-daemonset/k8s/hello-world-grpc-legacy.yml
```

Also deploy Linkerd:

```bash
kubectl apply -f https://raw.githubusercontent.com/BuoyantIO/linkerd-examples/master/k8s-daemonset/k8s/linkerd-grpc.yml
```

Once Kubernetes provisions an external LoadBalancer IP for Linkerd, we can do some test requests! Note that the examples in these blog posts assume k8s is running on GKE (e.g. external loadbalancer IPs are available, no CNI plugins are being used). Slight modifications may be needed for other environments, for example Minikube or CNI configurations with Calico/Weave.

We’ll use the helloworld-client provided by the `hello world` [docker image](https://hub.docker.com/r/buoyantio/helloworld/)in order to send test gRPC requests to our `hello world` service:

<!-- markdownlint-disable MD014 -->
```bash
$ L5D_INGRESS_LB=$(kubectl get svc l5d -o jsonpath="{.status.loadBalancer.ingress[0].*}")
$ docker run --rm --entrypoint=helloworld-client buoyantio/helloworld:0.1.3 $L5D_INGRESS_LB:4140
Hello (10.196.1.242) world (10.196.1.243)!!
```
<!-- markdownlint-enable MD014 -->

Or if external load balancer support is unavailable for the cluster, use hostIP:

```bash
$ L5D_INGRESS_LB=$( \
  kubectl get po -l app=l5d \
  -o jsonpath="{.items[0].status.hostIP}")
$ docker run --rm --entrypoint=helloworld-client buoyantio/helloworld:0.1.3 \
  $L5D_INGRESS_LB:$(kubectl get svc l5d -o 'jsonpath={.spec.ports[0].nodePort}')
Hello (10.196.1.242) world (10.196.1.243)!!
```

It works! We can check out the Linkerd admin dashboard by doing:

```bash
open http://$L5D_INGRESS_LB:9990 # on OSX
```

Or using hostIP:

```bash
open http://$L5D_INGRESS_LB:$(kubectl get svc l5d -o 'jsonpath={.spec.ports[2].nodePort}') # on OSX
```

And that’s it! We now have gRPC services talking to each other, with their HTTP/2 requests being routed through Linkerd. Now we can use all of [Linkerd’s awesome features](https://linkerd.io/features/), including per-request routing, load balancing, circuit-breaking, retries, TLS, distributed tracing, service discovery integration and more, in our gRPC microservice applications!

## HOW DID WE CONFIGURE LINKERD FOR GRPC OVER HTTP/2?

Let’s take a step back and examine our config. What’s different about using gRPC rather than HTTP/1.1? Actually, not very much! If you compare our [Linkerd config for routing gRPC](https://raw.githubusercontent.com/BuoyantIO/linkerd-examples/master/k8s-daemonset/k8s/linkerd-grpc.yml) with the [config for plain old HTTP/1.1](https://raw.githubusercontent.com/BuoyantIO/linkerd-examples/master/k8s-daemonset/k8s/linkerd.yml), they’re quite similar (full documentation on configuring an HTTP/2 router can be found [here](https://linkerd.io/config/0.9.1/linkerd/index.html#http-2-protocol)).

The changes you’ll notice are:

### PROTOCOL

We’ve changed the router `protocol` from `http` to `h2` (naturally!) and set the`experimental` flag to `true` to opt in to experimental HTTP/2 support.

```yaml
routers:
- protocol: h2
    experimental: true
```

### IDENTIFIER

We use the [header path identifier](https://linkerd.io/config/1.0.0/linkerd/index.html#http-2-header-path-identifier) to assign a logical name based on the gRPC request. gRPC clients set HTTP/2’s `:path` pseudo-header to `/package.Service/Method`. The header path identifier uses this pseudo-header to assign a logical name to the request (such as `/svc/helloworld.Hello/Greeting`). Setting `segments` to 1 means we only take the first segment of the path, in other words, dropping the gRPC `Method`. The resulting name can then be transformed via a [dtab](https://linkerd.io/in-depth/dtabs/) where we extract the gRPC service name, and route the request to a Kubernetes service of the same name. For more on how Linkerd routes requests, see our [routing](https://linkerd.io/in-depth/routing/) docs.

```yaml
identifier:
  kind: io.l5d.header.path
  segments: 1
```

### DTAB

We’ve adjusted the dtab slightly, now that we’re routing on the `/serviceName` prefix from the header path identifier. The dtab below transforms the logical name assigned by the path identifier (`/svc/helloworld.Hello`) to a name that tells the [io.l5d.k8s namer](https://linkerd.io/config/1.0.0/linkerd/index.html#kubernetes-service-discovery) to query the API for the `grpc` port of the `hello` Service in the default namespace (`/#/io.l5d.k8s/default/grpc/Hello`).

The [domainToPathPfx namer](https://linkerd.io/config/1.0.0/linkerd/index.html#domaintopathpfx) is used to extract the service name from the package-qualified gRPC service name, as seen in the dentry `/svc => /$/io.buoyant.http.domainToPathPfx/grpc`.

Delegation to `world` is similar, however we’ve decided to version the `world` service, so we’ve added the additional rule `/grpc/World => /srv/world-v1` to send requests to world-v1. Our full dtab is now:

```txt
/srv        => /#/io.l5d.k8s/default/grpc;
/grpc       => /srv;
/grpc/World => /srv/world-v1;
/svc        => /$/io.buoyant.http.domainToPathPfx/grpc;
```

## CONCLUSION

In this article, we’ve seen how to use Linkerd as a service mesh for gRPC requests, adding latency-aware load balancing, circuit breaking, and request-level routing to gRPC apps. Linkerd and gRPC are a great combination, especially as gRPC’s HTTP/2 underpinnings provide it with powerful mechanisms like multiplexed streaming, back pressure, and cancellation, which Linkerd can take full advantage of. Because gRPC includes routing information in the request, it’s a natural fit for Linkerd, and makes it very easy to set up Linkerd to route gRPC requests. For more on Linkerd’s roadmap around gRPC, see [Oliver’s blog post on the topic]({{< ref "http2-grpc-and-linkerd" >}}).

Finally, for a more advanced example of configuring gRPC services, take a look at our [Gob microservice app](https://github.com/BuoyantIO/linkerd-examples/tree/master/gob). In that example, we additionally deploy [Namerd](https://github.com/linkerd/linkerd/tree/master/namerd), which we use to manage our routing rules centrally, and update routing rules without redeploying Linkerd. This lets us to do things like canarying and blue green deploys between different versions of a service.

For more information on Linkerd, gRPC, and HTTP/2 head to the [Linkerd gRPC documentation](https://linkerd.io/features/grpc/) as well as our [config documentation for HTTP/2](https://linkerd.io/config/1.0.0/linkerd/index.html#http-2-protocol).

[part-i]: {{< ref "a-service-mesh-for-kubernetes-part-i-top-line-service-metrics" >}} [part-ii]: {{< ref "a-service-mesh-for-kubernetes-part-ii-pods-are-great-until-theyre-not" >}} [part-iii]: {{< ref "a-service-mesh-for-kubernetes-part-iii-encrypting-all-the-things" >}} [part-iv]: {{< ref "a-service-mesh-for-kubernetes-part-iv-continuous-deployment-via-traffic-shifting" >}} [part-v]: {{< ref "a-service-mesh-for-kubernetes-part-v-dogfood-environments-ingress-and-edge-routing" >}} [part-vi]: {{< ref "a-service-mesh-for-kubernetes-part-vi-staging-microservices-without-the-tears" >}} [part-vii]: {{< ref "a-service-mesh-for-kubernetes-part-vii-distributed-tracing-made-easy" >}} [part-viii]: {{< ref "a-service-mesh-for-kubernetes-part-viii-linkerd-as-an-ingress-controller" >}} [part-ix]: {{< ref "a-service-mesh-for-kubernetes-part-ix-grpc-for-fun-and-profit" >}} [part-x]: {{< ref "a-service-mesh-for-kubernetes-part-x-the-service-mesh-api" >}} [part-xi]: {{< ref "a-service-mesh-for-kubernetes-part-xi-egress" >}}
