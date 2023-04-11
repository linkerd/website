---
slug: 'a-service-mesh-for-kubernetes-part-xi-egress'
title: 'A Service Mesh For Kubernetes Part XI: Egress'
aliases:
  - /2017/06/20/a-service-mesh-for-kubernetes-part-xi-egress/
author: 'alex'
date: Tue, 20 Jun 2017 23:36:51 +0000
draft: false
featured: false
thumbnail: /uploads/kubernetes11_featured_Twitter_ratio.png
tags: [Linkerd, linkerd, News, tutorials]
---

In previous posts in this series, we’ve demonstrated how Linkerd can act as an *ingress* to a Kubernetes cluster, handling all requests coming from outside of the cluster and sending them to the appropriate Kubernetes services.

In this post we’ll explore how Linkerd can be used as an *egress* as well, handling requests from services within the cluster to services running outside of the cluster, whether those are legacy non-Kubernetes systems or third-party APIs outside the firewall.

Using the Linkerd service mesh for egress gives you a uniform, consistent model of request handling independent of where those requests are destined. It also lets you apply the benefits of Linkerd, such as adaptive load balancing, observability, circuit breakers, dynamic routing, and TLS, to services which are running outside of Kubernetes.

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
   "a-service-mesh-for-kubernetes-part-ix-grpc-for-fun-and-profit" >}})
10. [The Service Mesh API]({{< ref
    "a-service-mesh-for-kubernetes-part-x-the-service-mesh-api" >}})
11. [Egress]({{< ref "a-service-mesh-for-kubernetes-part-xi-egress" >}}) (this article)
12. Retry budgets, deadline propagation, and failing gracefully
13. Autoscaling by top-line metrics

## EGRESS NAMING WITH DNS

Linkerd provides a uniform naming abstraction that encompasses many different service discovery systems, including Kubernetes, Marathon, Consul, and ZooKeeper, as well as DNS and raw IP address resolution. When a service asks Linkerd to route a request to “foo”, Linkerd can be configured to resolve the name “foo” in a variety of ways, including arbitrary combinations of any of the above options. (For more on this, read about Linkerd’s powerful and sophisticated routing languages called [dtabs](https://linkerd.io/in-depth/dtabs/).)

In Kubernetes terms, most egress names resolve to non-Kubernetes services and must be resolved via DNS. Thus, the most straightforward way to add egress to the Linkerd service mesh is to add DNS lookup as a fallback mechanism. To accomplish this, we’ll start with our standard service mesh configuration, but tweak it with an additional rule: if we get a request for a service that doesn’t exist in Kubernetes, we’ll treat the service name as an external DNS name and send the request to that external address.

In the following sections, we’ll talk about how this actually works in terms of Linkerd’s configuration. If you just want to play with the end result, jump right to the “Trying it out” section at the bottom.

## SPLITTING THE KUBERNETES NAMER

There are a number of changes we need to make to the Linkerd config we’ve been developing in earlier examples to make this happen.

In our basic service mesh config, we attached the DaemonSet transformer to the outgoing router’s interpreter. This was so that all requests from one service would be sent to the Linkerd DaemonSet pod of the destination service (read more about that in [Part II of this series][part-ii]). However, this is not appropriate for external services because they are running outside of Kubernetes and don’t have a corresponding Linkerd DaemonSet pod. Therefore, we must take the DaemonSet transformer off of the interpreter and put it directly on the `io.l5d.k8s namer`. This makes the DaemonSet transformer apply only to Kubernetes names and not to external ones. We must also add a second `io.l5d.k8s` namer without the DaemonSet transformer for the incoming router to use.

```yaml
namers:
# This namer has the daemonset transformer "built-in"
- kind: io.l5d.k8s
    prefix: /io.l5d.k8s.ds # We reference this in the outgoing router's dtab
    transformers:
    - kind: io.l5d.k8s.daemonset
    namespace: default
    port: incoming
    service: l5d
# The "basic" k8s namer.  We reference this in the incoming router's dtab
- kind: io.l5d.k8s
```

## UPDATING THE DTAB

With those namers in place, we can now update the outgoing dtab to use the DaemonSet transformed Kubernetes namer and add dtab fallback rules to treat the service name as a DNS name. We use the io.buoyant.portHostPfx rewriting namer to extract the port number from the hostname (or use 80 by default if unspecified).

```yaml
dtab: |
/ph        => /$/io.buoyant.rinet ; # Lookup the name in DNS
/svc       => /ph/80 ; # Use port 80 if unspecified
/srv       => /$/io.buoyant.porthostPfx/ph ; # Attempt to extract the port from the hostname
/srv       => /#/io.l5d.k8s.ds/default/http ; # Lookup the name in Kubernetes, use the linkerd daemonset pod
/svc       => /srv ;
/svc/world => /srv/world-v1 ;
```

Recall that later dtab entries have higher priority so this will prefer:

1. The linkerd daemonset pod of the Kubernetes service, if it exists
2. An external DNS service on the specified port
3. An external DNS service on port 80 if no port specified

{{< fig
  alt="egress"
  title="Egress"
  src="/uploads/2017/07/buoyant-k8s-egress-dtab.png" >}}

## DON’T FORGET TLS!

Most services running on the open internet don’t allow plain HTTP. We’ll use Linkerd’s fine-grained client configuration to add TLS to all egress requests that use port 443.

```yaml
client:
kind: io.l5d.static
configs:
- prefix: "/$/io.buoyant.rinet/443/{service}"
    tls:
    commonName: "{service}"
```

Putting all that together gives us [this config](https://github.com/linkerd/linkerd-examples/blob/master/k8s-daemonset/k8s/linkerd-egress.yaml). Let’s try it out.

## TRYING IT OUT

Deploy our usual `hello world` microservice and updated Linkerd service mesh using these commands:

```bash
kubectl apply -f https://raw.githubusercontent.com/BuoyantIO/linkerd-examples/master/k8s-daemonset/k8s/hello-world.yml
kubectl apply -f https://raw.githubusercontent.com/BuoyantIO/linkerd-examples/master/k8s-daemonset/k8s/linkerd-egress.yaml
```

Once Kubernetes provisions an external LoadBalancer IP for Linkerd, we can test requests to the `hello` and `world` services as well as external services running outside of Kubernetes.

```bash
L5D_INGRESS_LB=$(kubectl get svc l5d -o jsonpath="{.status.loadBalancer.ingress[0].*}")
```

A request to a Kubernetes service:

```bash
$ curl $L5D_INGRESS_LB:4140 -H "Host: hello"
Hello (10.196.1.242) world (10.196.1.243)!!
```

A request to an external service, using port 80 by default:

```bash
$ curl -sI $L5D_INGRESS_LB:4140/index.html -H "Host: linkerd.io" | head -n 1
HTTP/1.1 301 Moved Permanently
```

A request to an external service using an explicit port and HTTPS:

```bash
$ curl -sI $L5D_INGRESS_LB:4140/index.html -H "Host: linkerd.io:443" | head -n 1
HTTP/1.1 200 OK
```

## CAVEAT

In the above configuration, we assume that the Linkerd DaemonSet pods are able to route to the external services in the first place. If this is not the case, e.g. if you have strict firewall rules that restrict L3/L4 traffic, you could instead set up a dedicated egress cluster of Linkerd instances running on nodes with access to the external services. All egress requests would then need to be sent to the egress cluster.

## CONCLUSION

By using Linkerd for egress, external services are able to share the same benefits that services running inside of Kubernetes get from the Linkerd service mesh. These include adaptive load balancing, circuit breaking, observability, dynamic routing, and TLS initiation. Most importantly, Linkerd gives you a uniform, consistent model of request handling and naming that’s independent of whether those requests are destined for internal services, or for external, third-party APIs.

If you have any questions about using Linkerd for egress, please come ask on the [Linkerd Support Forum](https://linkerd.buoyant.io/) or [Slack](https://slack.linkerd.io/)!

[part-i]: {{< ref "a-service-mesh-for-kubernetes-part-i-top-line-service-metrics" >}} [part-ii]: {{< ref "a-service-mesh-for-kubernetes-part-ii-pods-are-great-until-theyre-not" >}} [part-iii]: {{< ref "a-service-mesh-for-kubernetes-part-iii-encrypting-all-the-things" >}} [part-iv]: {{< ref "a-service-mesh-for-kubernetes-part-iv-continuous-deployment-via-traffic-shifting" >}} [part-v]: {{< ref "a-service-mesh-for-kubernetes-part-v-dogfood-environments-ingress-and-edge-routing" >}} [part-vi]: {{< ref "a-service-mesh-for-kubernetes-part-vi-staging-microservices-without-the-tears" >}} [part-vii]: {{< ref "a-service-mesh-for-kubernetes-part-vii-distributed-tracing-made-easy" >}} [part-viii]: {{< ref "a-service-mesh-for-kubernetes-part-viii-linkerd-as-an-ingress-controller" >}} [part-ix]: {{< ref "a-service-mesh-for-kubernetes-part-ix-grpc-for-fun-and-profit" >}} [part-x]: {{< ref "a-service-mesh-for-kubernetes-part-x-the-service-mesh-api" >}} [part-xi]: {{< ref "a-service-mesh-for-kubernetes-part-xi-egress" >}}
