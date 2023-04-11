---
slug: 'a-service-mesh-for-kubernetes-part-v-dogfood-environments-ingress-and-edge-routing'
title: 'A Service Mesh for Kubernetes, Part V: Dogfood environments, ingress and edge routing'
aliases:
  - /2016/11/18/a-service-mesh-for-kubernetes-part-v-dogfood-environments-ingress-and-edge-routing/
author: 'risha'
date: Fri, 18 Nov 2016 00:10:16 +0000
thumbnail: /uploads/kubernetes5_featured_Twitter_ratio.png
draft: false
featured: false
tags: [Article, Education, Linkerd, linkerd, tutorials]
---

In this post we’ll show you how to use a service mesh of linkerd instances to handle ingress traffic on Kubernetes, distributing traffic across every instance in the mesh. We’ll also walk through an example that showcases linkerd’s advanced routing capabilities by creating a *dogfood* environment that routes certain requests to a newer version of the underlying application, e.g. for internal, pre-release testing.

_Update 2017-04-19_: this post is about using linkerd as an ingress point for traffic to a Kubernetes network. As of [0.9.1](https://github.com/linkerd/linkerd/releases/tag/0.9.1), linkerd supports the Kubernetes Ingress resource directly, which is an alternate, and potentially simpler starting point for some of the use cases in this article. For information on how to use linkerd as a [Kubernetes ingress controller](https://kubernetes.io/docs/concepts/services-networking/ingress/#ingress-controllers), please see Sarah’s blog post, [Linkerd as an ingress controller][part-viii].

This is one article in a series of articles about [linkerd](https://linkerd.io/), [Kubernetes](http://kubernetes.io/), and service meshes. Other installments in this series include:

1. [Top-line service metrics]({{< ref
   "a-service-mesh-for-kubernetes-part-i-top-line-service-metrics" >}})
2. [Pods are great, until they’re not]({{< ref
   "a-service-mesh-for-kubernetes-part-ii-pods-are-great-until-theyre-not" >}})
3. [Encrypting all the things]({{< ref
   "a-service-mesh-for-kubernetes-part-iii-encrypting-all-the-things" >}})
4. [Continuous deployment via traffic shifting]({{< ref "a-service-mesh-for-kubernetes-part-iv-continuous-deployment-via-traffic-shifting" >}})
5. [Dogfood environments, ingress, and edge routing]({{< ref "a-service-mesh-for-kubernetes-part-v-dogfood-environments-ingress-and-edge-routing" >}}) (this article)
6. [Staging microservices without the tears]({{< ref "a-service-mesh-for-kubernetes-part-vi-staging-microservices-without-the-tears" >}})
7. [Distributed tracing made easy]({{< ref
   "a-service-mesh-for-kubernetes-part-vii-distributed-tracing-made-easy" >}})
8. [Linkerd as an ingress controller]({{< ref "a-service-mesh-for-kubernetes-part-viii-linkerd-as-an-ingress-controller" >}})
9. [gRPC for fun and profit]({{< ref
   "a-service-mesh-for-kubernetes-part-ix-grpc-for-fun-and-profit" >}})
10. [The Service Mesh API]({{< ref
    "a-service-mesh-for-kubernetes-part-x-the-service-mesh-api" >}})
11. [Egress]({{< ref "a-service-mesh-for-kubernetes-part-xi-egress" >}})
12. Retry budgets, deadline propagation, and failing gracefully
13. Autoscaling by top-line metrics

In previous installments of this series, we’ve shown you how you can use linkerd to capture [top-line service metrics][part-i], transparently [add TLS][part-iii] across service calls, and [perform blue-green deploys][part-iv]. These posts showed how using linkerd as a service mesh in environments like Kubernetes adds a layer of resilience and performance to internal, service-to-service calls. In this post, we’ll extend this model to ingress routing.

Although the examples in this post are Kubernetes-specific, we won’t use the built-in [Ingress Resource](https://kubernetes.io/docs/concepts/services-networking/ingress/) that Kubernetes provides (for this, see [Sarah’s post][part-viii]). While Ingress Resources are a convenient way of doing basic path and host-based routing, at the time of writing, they are fairly limited. In the examples below, we’ll be reaching far beyond what they provide.

## STEP 1: DEPLOY THE LINKERD SERVICE MESH

Starting with our basic linkerd service mesh Kubernetes config from the previous articles, we’ll make two changes to support ingress: we’ll modify the linkerd config to add an additional logical router, and we’ll tweak the VIP in the Kubernetes Service object around linkerd. (The full config is here: [linkerd-ingress.yml](https://raw.githubusercontent.com/linkerd/linkerd-examples/master/k8s-daemonset/k8s/linkerd-ingress.yml).)

Here’s the new `ingress` logical router on linkerd instances that will handle ingress traffic and route it to the corresponding services:

```yml
routers:
  - protocol: http
    label: ingress
    dtab: |
      /srv                    => /#/io.l5d.k8s/default/http ;
      /domain/world/hello/www => /srv/hello ;
      /domain/world/hello/api => /srv/api ;
      /host                   => /$/io.buoyant.http.domainToPathPfx/domain ;
      /svc                    => /host ;
    interpreter:
      kind: default
      transformers:
        - kind: io.l5d.k8s.daemonset
          namespace: default
          port: incoming
          service: l5d
    servers:
      - port: 4142
        ip: 0.0.0.0
```

In this config, we’re using linkerd’s routing syntax, [dtabs](https://linkerd.io/in-depth/dtabs/), to route requests from domain to service—in this case from “api.hello.world” to the `api` service, and from “www.hello.world” to the `world` service. For simplicity’s sake, we’ve added one rule per domain, but this mapping can easily be generified for more complex setups. (If you’re a linkerd config aficionado, we’re accomplishing this behavior by combining linkerd’s default [header token identifier](https://linkerd.io/config/1.0.0/linkerd/index.html#header-identifier) to route on the Host header, the [`domainToPathPfx` namer](https://linkerd.io/config/1.0.0/linkerd/index.html#domaintopathpfx) to turn dotted hostnames into hierarchical paths, and the [`io.l5d.k8s.daemonset` transformer](https://linkerd.io/config/1.0.0/linkerd/index.html#daemonset-kubernetes) to send requests to the corresponding host-local linkerd.)

We’ve added this ingress router to every linkerd instance—in true service mesh fashion, we’ll fully distribute ingress traffic across these instances so that no instance is a single point of failure.

We also need modify our k8s Service object to replace the `outgoing` VIP with an`ingress` VIP on port 80. This will allow us to send ingress traffic directly to the linkerd service mesh—mainly for debugging purposes, since the this traffic will not be sanitized before hitting linkerd. (In the next step, we’ll fix this.) The Kubernetes change looks like this:

```bash
---
apiVersion: v1
kind: Service
metadata:
  name: l5d
spec:
  selector:
    app: l5d
  type: LoadBalancer
  ports:
  - name: ingress
    port: 80
    targetPort: 4142
  - name: incoming
    port: 4141
  - name: admin
    port: 9990
```

All of the above can be accomplished in one fell swoop by running this command to apply the [full linkerd service mesh plus ingress Kubernetes config](https://raw.githubusercontent.com/linkerd/linkerd-examples/master/k8s-daemonset/k8s/linkerd-ingress.yml):

```bash
kubectl apply -f https://raw.githubusercontent.com/linkerd/linkerd-examples/master/k8s-daemonset/k8s/linkerd-ingress.yml
```

## STEP 2: DEPLOY THE SERVICES

For services in this example, we’ll use the same [hello and world configs](https://raw.githubusercontent.com/linkerd/linkerd-examples/master/k8s-daemonset/k8s/hello-world.yml) from the previous blog posts, and we’ll add two new services: an [api service](https://raw.githubusercontent.com/linkerd/linkerd-examples/master/k8s-daemonset/k8s/api.yml), which calls both `hello` and `world`, and a new version of the world service, `world-v2`, which will return the word “earth” rather than “world”—our growth hacker team has assured us their A/B tests show this change will increase engagement tenfold.

The following commands will deploy the three [hello world services](https://github.com/linkerd/linkerd-examples/tree/master/docker/helloworld) to the default namespace. These apps rely on the nodeName supplied by the [Kubernetes downward API](https://kubernetes.io/docs/tasks/inject-data-application/downward-api-volume-expose-pod-information/) to find Linkerd. To check if your cluster supports nodeName, you can run this test job:

```bash
kubectl apply -f https://raw.githubusercontent.com/linkerd/linkerd-examples/master/k8s-daemonset/k8s/node-name-test.yml
```

And then looks at its logs:

```bash
kubectl logs node-name-test
```

If you see an ip, great! Go ahead and deploy the hello world app using:

```bash
kubectl apply -f https://raw.githubusercontent.com/linkerd/linkerd-examples/master/k8s-daemonset/k8s/hello-world.yml
kubectl apply -f https://raw.githubusercontent.com/linkerd/linkerd-examples/master/k8s-daemonset/k8s/api.yml
kubectl apply -f https://raw.githubusercontent.com/linkerd/linkerd-examples/master/k8s-daemonset/k8s/world-v2.yml
```

If instead you see a “server can’t find …” error, deploy the hello-world legacy version that relies on hostIP instead of nodeName:

```bash
kubectl apply -f https://raw.githubusercontent.com/linkerd/linkerd-examples/master/k8s-daemonset/k8s/hello-world-legacy.yml
kubectl apply -f https://raw.githubusercontent.com/linkerd/linkerd-examples/master/k8s-daemonset/k8s/api-legacy.yml
kubectl apply -f https://raw.githubusercontent.com/linkerd/linkerd-examples/master/k8s-daemonset/k8s/world-v2.yml
```

At this point we should be able to test the setup by sending traffic through the `ingress` Kubernetes VIP. In the absence of futzing with DNS, we’ll set a Host header manually on the request:

<!-- markdownlint-disable MD014 -->
```bash
$ INGRESS_LB=$(kubectl get svc l5d -o jsonpath="{.status.loadBalancer.ingress[0].*}")
$ curl -s -H "Host: www.hello.world" $INGRESS_LB
Hello (10.0.5.7) world (10.0.4.7)!!
$ curl -s -H "Host: api.hello.world" $INGRESS_LB
{"api_result":"api (10.0.3.6) Hello (10.0.5.4) world (10.0.1.5)!!"}
```
<!-- markdownlint-enable MD014 -->

Or if external load balancer support is unavailable for the cluster, use hostIP:

```bash
INGRESS_LB=$(kubectl get po -l app=l5d -o jsonpath="{.items[0].status.hostIP}"):$(kubectl get svc l5d -o 'jsonpath={.spec.ports[0].nodePort}')
```

Success! We’ve set up linkerd as our ingress controller, and we’ve used it to route requests received on different domains to different services. And as you can see, production traffic is hitting the `world-v1` service—we aren’t ready to bring `world-v2`out just yet.

## STEP 3: A LAYER OF NGINX

At this point we have functioning ingress. However, we’re not ready for production just yet. For one thing, our ingress router doesn’t strip headers from requests, which means that external requests may include headers that we do not want to accept. For instance, linkerd allows setting the `l5d-dtab` header to [apply routing rules per-request](https://linkerd.io/features/routing/#per-request-routing). This is a useful feature for ad-hoc staging of new services, but it’s probably not appropriate calls from the outside world!

For example, we can use the `l5d-dtab` header to override the routing logic to use `world-v2` rather than the production `world-v1` service the outside world:

```bash
$ curl -H "Host: www.hello.world" -H "l5d-dtab: /host/world => /srv/world-v2;" $INGRESS_LB
Hello (10.100.4.3) earth (10.100.5.5)!!
```

Note the **earth** in the response, denoting the result of the `world-v2` service. That’s cool, but definitely not the kind of power we want to give just anyone!

We can address this (and other issues, such as serving static files) by adding [nginx](https://nginx.com/) to the mix. If we configure nginx to strip incoming headers before proxying requests to the linkerd ingress route, we’ll get the best of both worlds: an ingress layer that is capable of safely handling external traffic, and linkerd doing dynamic, service-based routing.

Let’s add nginx to the cluster. We’ll configure it using [this nginx.conf](https://raw.githubusercontent.com/linkerd/linkerd-examples/master/k8s-daemonset/k8s/nginx.yml). We’ll use the `proxy_pass` directive under our virtual servers `www.hello.world` and `api.hello.world` to send requests to the linkerd instances, and, for maximum fanciness, we’ll strip [linkerd’s context headers](https://linkerd.io/config/0.8.3/linkerd/index.html#context-headers) using the `more_clear_input_headers` directive (with wildcard matching) provided by the [Headers More](https://github.com/openresty/headers-more-nginx-module) module.

(Alternatively, we could avoid third-party nginx modules by using nginx’s`proxy_set_header` directive to clear headers. We’d need separate entries for each `l5d-ctx-` header as well as the `l5d-dtab` and `l5d-sample` headers.)

Note that as of [linkerd 0.9.0]({{< relref "linkerd-0-9-0-released" >}}), we can clear incoming `l5d-*` headers by setting `clearContext: true` on the ingress router [server](https://linkerd.io/config/1.0.0/linkerd/index.html#server-parameters). However, nginx has many features we can make use of (as you’ll see presently), so it is still valuable to use nginx in conjunction with linkerd.

For those of you following along at home, we’ve published an nginx Docker image with the *Headers More* module installed ([Dockerfile here](https://raw.githubusercontent.com/linkerd/linkerd-examples/master/docker/nginx/Dockerfile)) as [buoyantio/nginx:1.11.5](https://hub.docker.com/r/buoyantio/nginx/). We can deploy this image with our config above using this [Kubernetes config](https://raw.githubusercontent.com/linkerd/linkerd-examples/master/k8s-daemonset/k8s/nginx.yml):

```bash
kubectl apply -f https://raw.githubusercontent.com/linkerd/linkerd-examples/master/k8s-daemonset/k8s/nginx.yml
```

After waiting a bit for the external IP to appear, we can test that nginx is up by hitting the simple test endpoint in the nginx.conf:

```bash
INGRESS_LB=$(kubectl get svc nginx -o jsonpath="{.status.loadBalancer.ingress[0].*}")
curl $INGRESS_LB
```

Or if external load balancer support is unavailable for the cluster, use hostIP:

```bash
INGRESS_LB=$(kubectl get po -l app=nginx -o jsonpath="{.items[0].status.hostIP}"):$(kubectl get svc nginx -o 'jsonpath={.spec.ports[0].nodePort}')
```

We should be able to now send traffic to our services through nginx:

```bash
$ curl -s -H "Host: www.hello.world" $INGRESS_LB
Hello (10.0.5.7) world (10.0.4.7)!!
$ curl -s -H "Host: api.hello.world" $INGRESS_LB
{"api_result":"api (10.0.3.6) Hello (10.0.5.4) world (10.0.1.5)!!"}
```

Finally, let’s try our header trick and attempt to communicate directly with the `world-v2` service:

```bash
$ curl -H "Host: www.hello.world" -H "l5d-dtab: /host/world => /srv/world-v2;" $INGRESS_LB
Hello (10.196.1.8) world (10.196.2.13)!!
```

Great! No more **earth**. Nginx is sanitizing external traffic.

## STEP 4: TIME FOR SOME DELICIOUS DOGFOOD!

Ok, we’re ready for the good part: let’s set up a dogfood environment that uses the`world-v2` service, but only for some traffic!

For simplicity, we’ll target traffic that sets a particular cookie,`special_employee_cookie`. In practice, you probably want something more sophisticated than this—authenticate it, require that it come from the corp network IP range, etc.

With nginx and linkerd installed, accomplishing this is quite simple. We’ll use nginx to check for the presence of that cookie, and set a dtab override header for linkerd to adjust its routing. The relevant nginx config looks like this:

```txt
if ($cookie_special_employee_cookie ~* "dogfood") {
  set $xheader "/host/world => /srv/world-v2;";
}

proxy_set_header 'l5d-dtab' $xheader;
```

If you’ve been following the steps above, the deployed nginx already contains this configuration. We can test it like so:

```bash
$ curl -H "Host: www.hello.world" --cookie "special_employee_cookie=dogfood" $INGRESS_LB
Hello (10.196.1.8) earth (10.196.2.13)!!
```

The system works! When this cookie is set, you’ll be in dogfood mode. Without it, you’ll be in regular, production traffic mode. Most importantly, dogfood mode can involve new versions of services that appear *anywhere* in the service stack, even many layers deep—as long as service code [forwards linkerd context headers](https://linkerd.io/config/1.0.0/linkerd/index.html#context-headers), the linkerd service mesh will take care of the rest.

## Conclusion

In this post, we saw how to use linkerd to provide powerful and flexible ingress to a Kubernetes cluster. We’ve demonstrated how to deploy a nominally production-ready setup that uses linkerd for service routing. And we’ve demonstrated how to use some of the advanced routing features of linkerd to decouple the *traffic-serving* topology from the *deployment topology*, allowing for the creation of dogfood environments without separate clusters or deploy-time complications.

For more about running linkerd in Kubernetes, or if you have any issues configuring ingress in your setup, feel free to stop by our [linkerd community Slack](http://slack.linkerd.io/), ask a question on the [Linkerd Support Forum](https://linkerd.buoyant.io/), or [contact us directly](https://linkerd.io/overview/help/)!

[part-i]: {{< ref "a-service-mesh-for-kubernetes-part-i-top-line-service-metrics" >}} [part-ii]: {{< ref "a-service-mesh-for-kubernetes-part-ii-pods-are-great-until-theyre-not" >}} [part-iii]: {{< ref "a-service-mesh-for-kubernetes-part-iii-encrypting-all-the-things" >}} [part-iv]: {{< ref "a-service-mesh-for-kubernetes-part-iv-continuous-deployment-via-traffic-shifting" >}} [part-v]: {{< ref "a-service-mesh-for-kubernetes-part-v-dogfood-environments-ingress-and-edge-routing" >}} [part-vi]: {{< ref "a-service-mesh-for-kubernetes-part-vi-staging-microservices-without-the-tears" >}} [part-vii]: {{< ref "a-service-mesh-for-kubernetes-part-vii-distributed-tracing-made-easy" >}} [part-viii]: {{< ref "a-service-mesh-for-kubernetes-part-viii-linkerd-as-an-ingress-controller" >}} [part-ix]: {{< ref "a-service-mesh-for-kubernetes-part-ix-grpc-for-fun-and-profit" >}} [part-x]: {{< ref "a-service-mesh-for-kubernetes-part-x-the-service-mesh-api" >}} [part-xi]: {{< ref "a-service-mesh-for-kubernetes-part-xi-egress" >}}
