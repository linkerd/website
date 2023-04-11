---
slug: 'a-service-mesh-for-kubernetes-part-iii-encrypting-all-the-things'
title: 'A Service Mesh for Kubernetes, Part III: Encrypting all the things'
author: 'alex'
date: Mon, 24 Oct 2016 23:00:15 +0000
draft: false
featured: false
thumbnail: /uploads/kubernetes3_featured_Twitter_ratio.png
tags: [Article, Education, Linkerd, linkerd, tutorials]
---

In this article, we’ll show you how to use linkerd as a service mesh to add TLS to all service-to-service HTTP calls, without modifying any application code.

Note: This is one article in a series of articles about [linkerd](https://linkerd.io/), [Kubernetes](http://kubernetes.io/), and service meshes. Other installments in this series include:

1. [Top-line service metrics]({{< ref
   "a-service-mesh-for-kubernetes-part-i-top-line-service-metrics" >}})
2. [Pods are great, until they’re not]({{< ref
   "a-service-mesh-for-kubernetes-part-ii-pods-are-great-until-theyre-not" >}})
3. [Encrypting all the things]({{< ref
   "a-service-mesh-for-kubernetes-part-iii-encrypting-all-the-things" >}}) (this article)
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
11. [Egress]({{< ref "a-service-mesh-for-kubernetes-part-xi-egress" >}})
12. Retry budgets, deadline propagation, and failing gracefully
13. Autoscaling by top-line metrics

In the first installment in this series, we showed you how you can [easily monitor top-line service metrics][part-i] \(success rates, latencies, and request rates\) when linkerd is installed as a service mesh. In this article, we’ll show you another benefit of the service mesh approach: it allows you to decouple the application’s protocol from the protocol used on the wire. In other words, the application can speak one protocol, but the bytes that actually go out on the wire are in another.

In the case where no data transformation is required, linkerd can use this decoupling to automatically do protocol upgrades. Examples of the sorts of protocol upgrades that linkerd can do include HTTP/1.x to HTTP/2, thrift to [thrift-mux](http://twitter.github.io/finagle/guide/Protocols.html#mux), and, the topic of this article, HTTP to HTTPS.

## A Service Mesh for Kubernetes

When linkerd is deployed as a service mesh on Kubernetes, we [place a linkerd instance on every host using DaemonSets][part-ii]. For HTTP services, pods can send HTTP traffic to their host-local linkerd by using the `http_proxy` environment variable. (For non-HTTP traffic the integration is slightly more complex.)

In our blog post from a few months ago, we showed you the basic pattern of [using linkerd to “wrap” HTTP calls in TLS]({{< relref "transparent-tls-with-linkerd" >}}) by proxying at both ends of the connection, both originating and terminating TLS. However, now that we have the service mesh deployment in place, things are significantly simpler. Encrypting all cross-host communication is largely a matter of providing a TLS certificate to the service mesh.

Let’s walk through an example. The first two steps will be identical to what we did in [Part I of this series][part-i]—we’ll install linkerd as a service mesh and install a simple microservice “hello world” application. If you have already done this, you can skip straight to [step 3][part-iii].

## STEP 1: INSTALL LINKERD

We can install linkerd as a service mesh on our Kubernetes cluster by using [this Kubernetes config](https://raw.githubusercontent.com/linkerd/linkerd-examples/master/k8s-daemonset/k8s/linkerd.yml). This will install linkerd as a DaemonSet (i.e., one instance per host) in the default Kubernetes namespace:

```bash
kubectl apply -f https://raw.githubusercontent.com/linkerd/linkerd-examples/master/k8s-daemonset/k8s/linkerd.yml
```

You can confirm that installation was successful by viewing linkerd’s admin page (note that it may take a few minutes for the ingress IP to become available):

```bash
INGRESS_LB=$(kubectl get svc l5d -o jsonpath="{.status.loadBalancer.ingress[0].*}")
open http://$INGRESS_LB:9990 # on OS X
```

Or if external load balancer support is unavailable for the cluster, use hostIP:

```bash
HOST_IP=$(kubectl get po -l app=l5d -o jsonpath="{.items[0].status.hostIP}")
open http://$HOST_IP:$(kubectl get svc l5d -o 'jsonpath={.spec.ports[2].nodePort}') # on OS X
```

## STEP 2: INSTALL THE SAMPLE APPS

Install two services, “hello” and “world”, in the default namespace. These apps rely on the nodeName supplied by the [Kubernetes downward API](https://kubernetes.io/docs/tasks/inject-data-application/downward-api-volume-expose-pod-information/) to find Linkerd. To check if your cluster supports nodeName, you can run this test job:

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
```

If instead you see a “server can’t find …” error, deploy the hello-world legacy version that relies on hostIP instead of nodeName:

```bash
kubectl apply -f https://raw.githubusercontent.com/linkerd/linkerd-examples/master/k8s-daemonset/k8s/hello-world-legacy.yml
```

These two services function together to make a highly scalable, “hello world” microservice (where the hello service, naturally, must call the world service to complete its request).

At this point, we actually have a functioning service mesh and an application that makes use of it. You can see the entire setup in action by sending traffic through linkerd’s external IP:

```bash
http_proxy=$INGRESS_LB:4140
curl -s http://hello
```

Or to use hostIP directly:

```bash
http_proxy=$HOST_IP:$(kubectl get svc l5d -o 'jsonpath={.spec.ports[0].nodePort}')
curl -s http://hello
```

If everything’s working, you should see the string “Hello world”.

## STEP 3: CONFIGURE LINKERD TO USE TLS

Now that linkerd is installed, let’s use it to encrypt traffic. We’ll place TLS certificates on each of the hosts, and configure linkerd to use those certificates for TLS.

We’ll use a global certificate (the mesh certificate) that we generate ourselves. Since this certificate is not tied to a public DNS name, we don’t need to use a service like [Let’s Encrypt](https://letsencrypt.org/). We can instead generate our own CA certificate and use that to sign our mesh certificate (“self-signing”). We’ll distribute three things to each Kubernetes host: the CA certificate, the mesh key, and the mesh certificate.

The following scripts use sample certificates that we’ve generated. *Please don’t use these certificates in production*. For instructions on how to generate your own self-signed certificates, see our previous post, where we have [instructions on how to generate your own certificates]({{<
relref "transparent-tls-with-linkerd" >}}#generating-certificates)).

## STEP 4: DEPLOY CERTIFICATES AND CONFIG CHANGES TO KUBERNETES

We’re ready to update linkerd to encrypt traffic. We will distribute the [sample certificates](https://raw.githubusercontent.com/linkerd/linkerd-examples/master/k8s-daemonset/k8s/certificates.yml) as Kubernetes [secrets](https://kubernetes.io/docs/concepts/configuration/secret/).

```bash
kubectl apply -f https://raw.githubusercontent.com/linkerd/linkerd-examples/master/k8s-daemonset/k8s/certificates.yml
```

Now we will configure linkerd to use these certificates by giving it [this configuration](https://raw.githubusercontent.com/linkerd/linkerd-examples/master/k8s-daemonset/k8s/linkerd-tls.yml) and restarting it:

```bash
kubectl delete ds/l5d configmap/l5d-config
kubectl apply -f https://raw.githubusercontent.com/linkerd/linkerd-examples/master/k8s-daemonset/k8s/linkerd-tls.yml
```

## STEP 5: SUCCESS!

At this point, linkerd should be transparently wrapping all communication between these services in TLS. Let’s verify this by running the same command as before:

```bash
http_proxy=$INGRESS_LB:4140
curl -s http://hello
```

Or using hostIP:

```bash
http_proxy=$HOST_IP:$(kubectl get svc l5d -o 'jsonpath={.spec.ports[0].nodePort}')
curl -s http://hello
```

If all is well, you should still see the string “Hello world”—but under the hood, communication between the hello and world services is being encrypted. We can verify this by making an HTTPS request directly to port 4141, where linkerd is listening for requests from other linkerd instances:

```bash
curl -skH 'l5d-dtab: /svc=>/#/io.l5d.k8s/default/admin/l5d;' https://$INGRESS_LB:4141/admin/ping
```

Or using hostIP:

```bash
curl -skH 'l5d-dtab: /svc=>/#/io.l5d.k8s/default/admin/l5d;'
https://$HOST_IP:$(kubectl get svc l5d -o 'jsonpath={.spec.ports[1].nodePort}')/admin/ping
```

Here we’re asking curl to make an HTTPS call, and telling it to skip TLS validation (since curl is expecting a website, not linkerd). We’re also adding a [dtab override](https://linkerd.io/features/routing/#per-request-routing) to route the request to the linkerd instance’s own admin interface. If all is well, you should again see a successful “pong” response. Congratulations! You’ve encrypted your cross-service traffic.

## Conclusion

In this post, we’ve shown how a service mesh like linkerd can be used to to transparently encrypt all cross-node communication in a Kubernetes cluster. We’re also using TLS to ensure that linkerd instances can verify that they’re talking to other linkerd instances, preventing man-in-the-middle attacks (and misconfiguration!). Of course, the application remains blissfully unaware of any of these changes.

TLS is a complex topic and we’ve glossed over some important security considerations for the purposes of making the demo easy and quick. Please make sure you spend time to fully understand the steps involved before you try this on your production cluster.

Finally, adding TLS to the communications substrate is just one of many things that can be accomplished with a service mesh. Be sure to check out the rest of the articles in this series for more!

For help with this or anything else about linkerd, feel free to stop by our [linkerd community Slack](http://slack.linkerd.io/), post a topic on the [Linkerd Support Forum](https://linkerd.buoyant.io/), or [contact us directly](https://linkerd.io/overview/help/)!

[part-i]: {{< ref "a-service-mesh-for-kubernetes-part-i-top-line-service-metrics" >}} [part-ii]: {{< ref "a-service-mesh-for-kubernetes-part-ii-pods-are-great-until-theyre-not" >}} [part-iii]: {{< ref "a-service-mesh-for-kubernetes-part-iii-encrypting-all-the-things" >}} [part-iv]: {{< ref "a-service-mesh-for-kubernetes-part-iv-continuous-deployment-via-traffic-shifting" >}} [part-v]: {{< ref "a-service-mesh-for-kubernetes-part-v-dogfood-environments-ingress-and-edge-routing" >}} [part-vi]: {{< ref "a-service-mesh-for-kubernetes-part-vi-staging-microservices-without-the-tears" >}} [part-vii]: {{< ref "a-service-mesh-for-kubernetes-part-vii-distributed-tracing-made-easy" >}} [part-viii]: {{< ref "a-service-mesh-for-kubernetes-part-viii-linkerd-as-an-ingress-controller" >}} [part-ix]: {{< ref "a-service-mesh-for-kubernetes-part-ix-grpc-for-fun-and-profit" >}} [part-x]: {{< ref "a-service-mesh-for-kubernetes-part-x-the-service-mesh-api" >}} [part-xi]: {{< ref "a-service-mesh-for-kubernetes-part-xi-egress" >}}
