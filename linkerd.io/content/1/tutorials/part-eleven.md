+++
date = "2017-06-20T13:43:54-07:00"
title = "Part XI: Egress"
description = "explore how Linkerd can be used as an egress as well, handling requests from services within the cluster to services running outside of the #cluster, whether those are legacy non-Kubernetes systems or third-party APIs outside the firewall."
weight = 12
draft = true
aliases = [
  "/tutorials_staging/part-eleven"
]
[menu.docs]
  parent = "tutorials"
+++

Author: Alex Leong

In previous posts in this series, we’ve demonstrated how Linkerd can act as an _ingress_ to a Kubernetes cluster, handling all requests coming from outside of the cluster and sending them to the appropriate Kubernetes services.

In this post we’ll explore how Linkerd can be used as an egress as well, handling requests from services within the cluster to services running outside of the cluster, whether those are legacy non-Kubernetes systems or third-party APIs outside the firewall.

Using the Linkerd service mesh for egress gives you a uniform, consistent model of request handling independent of where those requests are destined. It also lets you apply the benefits of Linkerd, such as adaptive load balancing, observability, circuit breakers, dynamic routing, and TLS, to services which are running outside of Kubernetes.

---

## Egress naming with dns
Linkerd provides a uniform naming abstraction that encompasses many different service discovery systems, including Kubernetes, Marathon, Consul, and ZooKeeper, as well as DNS and raw IP address resolution. When a service asks Linkerd to route a request to “foo”, Linkerd can be configured to resolve the name “foo” in a variety of ways, including arbitrary combinations of any of the above options. (For more on this, read about Linkerd’s powerful and sophisticated routing languages called [dtabs](https://linkerd.io/in-depth/dtabs/).)

In Kubernetes terms, most egress names resolve to non-Kubernetes services and must be resolved via DNS. Thus, the most straightforward way to add egress to the Linkerd service mesh is to add DNS lookup as a fallback mechanism. To accomplish this, we’ll start with our standard service mesh configuration, but tweak it with an additional rule: if we get a request for a service that doesn’t exist in Kubernetes, we’ll treat the service name as an external DNS name and send the request to that external address.

In the following sections, we’ll talk about how this actually works in terms of Linkerd’s configuration. If you just want to play with the end result, jump right to the “Trying it out” section at the bottom.

---

## Splitting the Kubernetes namer
There are a number of changes we need to make to the Linkerd config we’ve been developing in earlier examples to make this happen.

In our basic service mesh config, we attached the DaemonSet transformer to the outgoing router’s interpreter. This was so that all requests from one service would be sent to the Linkerd DaemonSet pod of the destination service (read more about that in [Part II](/tutorials/part-two) of this series). However, this is not appropriate for external services because they are running outside of Kubernetes and don’t have a corresponding Linkerd DaemonSet pod. Therefore, we must take the DaemonSet transformer off of the interpreter and put it directly on the `io.l5d.k8s namer`. This makes the DaemonSet transformer apply only to Kubernetes names and not to external ones. We must also add a second `io.l5d.k8s` namer without the DaemonSet transformer for the incoming router to use.

```
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

---

## Updating the dtab
With those namers in place, we can now update the outgoing dtab to use the DaemonSet transformed Kubernetes namer and add dtab fallback rules to treat the service name as a DNS name. We use the io.buoyant.portHostPfx rewriting namer to extract the port number from the hostname (or use 80 by default if unspecified).

```
dtab: |
  /ph        => /$/io.buoyant.rinet ; # Lookup the name in DNS
  /svc       => /ph/80 ; # Use port 80 if unspecified
  /srv       => /$/io.buoyant.porthostPfx/ph ; # Attempt to extract the port from the hostname
  /srv       => /#/io.l5d.k8s.ds/default/http ; # Lookup the name in Kubernetes, use the linkerd daemonset pod
  /svc       => /srv ;
  /svc/world => /srv/world-v1 ;
```

Recall that later dtab entries have higher priority so this will prefer:

- The linkerd daemonset pod of the Kubernetes service, if it exists
- An external DNS service on the specified port
- An external DNS service on port 80 if no port specified

{{< fig src="/images/tutorials/buoyant-k8s-egress-dtab.png" >}}

---

## Don't forget TLS!
Most services running on the open internet don’t allow plain HTTP. We’ll use Linkerd’s fine-grained client configuration to add TLS to all egress requests that use port 443.

```
client:
  kind: io.l5d.static
  configs:
  - prefix: "/$/io.buoyant.rinet/443/{service}"
    tls:
      commonName: "{service}"
```

Putting all that together gives us this config. Let’s try it out.

---

#Trying it out
Deploy our usual `hello world` microservice and updated Linkerd service mesh using these commands:

```
kubectl apply -f https://raw.githubusercontent.com/BuoyantIO/linkerd-examples/master/k8s-daemonset/k8s/hello-world.yml
kubectl apply -f https://raw.githubusercontent.com/BuoyantIO/linkerd-examples/master/k8s-daemonset/k8s/linkerd-egress.yaml
```

Once Kubernetes provisions an external LoadBalancer IP for Linkerd, we can test requests to the `hello` and `world` services as well as external services running outside of Kubernetes.

(Note that the examples in these blog posts assume k8s is running on GKE (e.g. external loadbalancer IPs are available, no CNI plugins are being used). Slight modifications may be needed for other environments—see our [Flavors of Kubernetes help page](https://discourse.linkerd.io/t/flavors-of-kubernetes/53) for environments like Minikube or CNI configurations with Calico/Weave.)

```
$ L5D_INGRESS_LB=$(kubectl get svc l5d -o jsonpath="{.status.loadBalancer.ingress[0].*}")
```
A request to a Kubernetes service:

```
$ curl $L5D_INGRESS_LB:4140 -H "Host: hello"
Hello (10.196.1.242) world (10.196.1.243)!!
```

A request to an external service, using port 80 by default:
```
$ curl -sI $L5D_INGRESS_LB:4140/index.html -H "Host: linkerd.io" | head -n 1
HTTP/1.1 301 Moved Permanently
```

A request to an external service using an explicit port and HTTPS:
```
$ curl -sI $L5D_INGRESS_LB:4140/index.html -H "Host: linkerd.io:443" | head -n 1
HTTP/1.1 200 OK
```

## Caveat
In the above configuration, we assume that the Linkerd DaemonSet pods are able to route to the external services in the first place. If this is not the case, e.g. if you have strict firewall rules that restrict L3/L4 traffic, you could instead set up a dedicated egress cluster of Linkerd instances running on nodes with access to the external services. All egress requests would then need to be sent to the egress cluster.

## Conclusion
By using Linkerd for egress, external services are able to share the same benefits that services running inside of Kubernetes get from the Linkerd service mesh. These include adaptive load balancing, circuit breaking, observability, dynamic routing, and TLS initiation. Most importantly, Linkerd gives you a uniform, consistent model of request handling and naming that’s independent of whether those requests are destined for internal services, or for external, third-party APIs.

If you have any questions about using Linkerd for egress, please come ask on [Discourse](https://discourse.linkerd.io/) or [Slack](https://slack.linkerd.io/)!
