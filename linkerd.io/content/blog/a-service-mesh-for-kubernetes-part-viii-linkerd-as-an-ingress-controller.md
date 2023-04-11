---
slug: 'a-service-mesh-for-kubernetes-part-viii-linkerd-as-an-ingress-controller'
title: 'A Service Mesh for Kubernetes, Part VIII: Linkerd as an ingress controller'
aliases:
  - /2017/04/06/a-service-mesh-for-kubernetes-part-viii-linkerd-as-an-ingress-controller/
author: 'sarah'
thumbnail: /uploads/kubernetes8_featured_Twitter_ratio.png
date: Thu, 06 Apr 2017 23:34:10 +0000
draft: false
featured: false
tags: [Linkerd, linkerd, News, tutorials]
---

Linkerd is designed to make service-to-service communication internal to an application safe, fast and reliable. However, those same goals are also applicable at the edge. In this post, we’ll demonstrate a new feature of Linkerd which allows it to act as a Kubernetes ingress controller, and show how it can handle ingress traffic both with and without TLS.

This is one article in a series of articles about Linkerd, Kubernetes, and service meshes. Other installments in this series include:

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
8. [Linkerd as an ingress controller]({{< ref "a-service-mesh-for-kubernetes-part-viii-linkerd-as-an-ingress-controller" >}}) (this article)
9. [gRPC for fun and profit]({{< ref
   "a-service-mesh-for-kubernetes-part-ix-grpc-for-fun-and-profit" >}})
10. [The Service Mesh API]({{< ref
    "a-service-mesh-for-kubernetes-part-x-the-service-mesh-api" >}})
11. [Egress]({{< ref "a-service-mesh-for-kubernetes-part-xi-egress" >}})
12. Retry budgets, deadline propagation, and failing gracefully
13. Autoscaling by top-line metrics

In a [previous installment][part-v] of this series, we explored how to receive external requests by deploying Linkerd as a Kubernetes DaemonSet and routing traffic through the corresponding Service VIP. In this post, we’ll simplify this setup by using Linkerd as a [Kubernetes ingress controller](https://kubernetes.io/docs/concepts/services-networking/ingress/#ingress-controllers), taking advantage of features introduced in [Linkerd 0.9.1](https://github.com/linkerd/linkerd/releases/tag/0.9.1).

This approach has the benefits of simplicity and a tight integration with the Kubernetes API. However, for more complex requirements like on-demand TLS cert generation, SNI, or routing based on cookie values (e.g. the employee dogfooding approach discussed in [Part V of this series][part-v]), combining Linkerd with a dedicated edge layer such as NGINX is still necessary.

What is a Kubernetes ingress controller? An ingress controller is an edge router that accepts traffic from the outside world and forwards it to services in your Kubernetes cluster. The ingress controller uses HTTP host and path routing rules defined in Kubernetes’ [ingress resources](https://kubernetes.io/docs/concepts/services-networking/ingress/).

## INGRESS HELLO WORLD

Using a [Kubernetes config](https://raw.githubusercontent.com/linkerd/linkerd-examples/master/k8s-daemonset/k8s/linkerd-ingress-controller.yml) from the [linkerd-examples](https://github.com/linkerd/linkerd-examples) repo, we can launch Linkerd as a dedicated ingress controller. The config follows the same pattern as our [previous posts on k8s daemonsets][part-ii]: it deploys an `l5d-config` ConfigMap, an `l5d` DaemonSet, and an `l5d` Service.

{{< fig
  alt="diagram"
  title="diagram"
  src="/uploads/2017/07/buoyant-k8s-hello-world-ingress-controller-1.png" >}}

### STEP 1: DEPLOY LINKERD

First let’s deploy Linkerd. You can of course deploy into the default namespace, but here we’ve put Linkerd in its own namespace for better separation of concerns:

```bash
kubectl create ns l5d-system
kubectl apply -f https://raw.githubusercontent.com/linkerd/linkerd-examples/master/k8s-daemonset/k8s/linkerd-ingress-controller.yml -n l5d-system
```

You can verify that the Linkerd pods are up by running:

```bash
$ kubectl get po -n l5d-system
NAME        READY     STATUS    RESTARTS   AGE
l5d-0w0f4   2/2       Running   0          5s
l5d-3cmfp   2/2       Running   0          5s
l5d-dj1sm   2/2       Running   0          5s
```

And take a look at the admin dashboard (This command assumes your cluster supports LoadBalancer services, and remember that it may take a few minutes for the ingress LB to become available.):

```bash
L5D_SVC_IP=$(kubectl get svc l5d -n l5d-system -o jsonpath="{.status.loadBalancer.ingress[0].*}")
open http://$L5D_SVC_IP:9990 # on OS X
```

Or if external load balancer support is unavailable for the cluster, use hostIP:

```bash
HOST_IP=$(kubectl get po -l app=l5d -n l5d-system -o jsonpath="{.items[0].status.hostIP}")
L5D_SVC_IP=$HOST_IP:$(kubectl get svc l5d -n l5d-system -o 'jsonpath={.spec.ports[0].nodePort}')
open http://$HOST_IP:$(kubectl get svc l5d -n l5d-system -o 'jsonpath={.spec.ports[1].nodePort}') # on OS X
```

Let’s take a closer look at the ConfigMap we just deployed. It stores the `config.yaml`file that Linkerd mounts on startup.

```bash
$ kubectl get cm l5d-config -n l5d-system -o yaml
apiVersion: v1
data:
  config.yaml: |-
    namers:
    - kind: io.l5d.k8s

    routers:
    - protocol: http
      identifier:
        kind: io.l5d.ingress
      servers:
        - port: 80
          ip: 0.0.0.0
          clearContext: true
      dtab: /svc => /#/io.l5d.k8s

    usage:
      orgId: linkerd-examples-ingress
```

You can see that this config defines an HTTP router on port 80 that identifies incoming requests using ingress resources (via the [`io.l5d.ingress` identifier](https://linkerd.io/config/1.0.0/linkerd/index.html#ingress-identifier)). The resulting namespace, port, and service name are then passed to the [Kubernetes namer](https://linkerd.io/config/1.0.0/linkerd/index.html#kubernetes-service-discovery) for resolution. We’ve also set `clearContext` to `true` in order to remove any incoming Linkerd context headers from untrusted sources.

### STEP 2: DEPLOY THE HELLO WORLD APPLICATION

Now it’s time to deploy our application, so that our ingress controller can route traffic to us. We’ll deploy a simple app consisting of a hello and a world service.

```bash
kubectl apply -f https://raw.githubusercontent.com/linkerd/linkerd-examples/master/k8s-daemonset/k8s/hello-world.yml
kubectl apply -f https://raw.githubusercontent.com/linkerd/linkerd-examples/master/k8s-daemonset/k8s/world-v2.yml
```

You can again verify that the pods are up and running:

```bash
$ kubectl get po
NAME             READY     STATUS    RESTARTS   AGE
hello-0v0vx      1/1       Running   0          5s
hello-84wfp      1/1       Running   0          5s
hello-mrcfr      1/1       Running   0          5s
world-v1-105tl   1/1       Running   0          5s
world-v1-1t6jc   1/1       Running   0          5s
world-v1-htwsw   1/1       Running   0          5s
world-v2-5tl10   1/1       Running   0          5s
world-v2-6jc1t   1/1       Running   0          5s
world-v2-wswht   1/1       Running   0          5s
```

At this point, if you try to send an ingress request, you’ll see something like:

```bash
$ curl $L5D_SVC_IP
Unknown destination: Request("GET /", from /184.23.234.210:58081) / no ingress rule matches
```

### STEP 3: CREATE THE INGRESS RESOURCE

In order for our Linkerd ingress controller to function properly, we need to create an [ingress resource](https://kubernetes.io/docs/concepts/services-networking/ingress/) that uses it.

```bash
kubectl apply -f https://raw.githubusercontent.com/linkerd/linkerd-examples/master/k8s-daemonset/k8s/hello-world-ingress.yml
```

Verify the resource:

```bash
$ kubectl get ingress
NAME          HOSTS      ADDRESS   PORTS     AGE
hello-world   world.v2             80        7s
```

This “hello-world” ingress resource references our backends (we’re only using `world-v1` and `world-v2` for this demo):

```bash
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: hello-world
  annotations:
    kubernetes.io/ingress.class: "linkerd"
spec:
  backend:
    serviceName: world-v1
    servicePort: http
  rules:
  - host: world.v2
    http:
      paths:
      - backend:
          serviceName: world-v2
          servicePort: http
```

The resource

- Specifies `world-v1` as the default backend to route to if a request does not match any of the rules defined.
- Specifies a rule where all requests with the host header `world.v2` will be routed to the `world-v2` service.
- Sets the `kubernetes.io/ingress.class` annotation to “linkerd”. Note, this annotation is only required if there are multiple ingress controllers running in the cluster.

That’s it! You can exercise these rules by curling the IP assigned to the l5d service loadbalancer.

```bash
$ curl $L5D_SVC_IP
world (10.0.4.7)!
$ curl -H "Host: world.v2" $L5D_SVC_IP
earth (10.0.1.5)!
```

While this example starts with totally new instances, it’s just as easy to add an ingress identifier router to a pre-existing linked setup. Also, although we employ a DaemonSet here (to be consistent with the rest of the Service Mesh for Kubernetes series), utilizing a Kubernetes [Deployment](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/) for a Linkerd ingress controller works just as well. Using Deployments is left as an exercise for the reader. :)

## INGRESS WITH TLS

Linkerd already supports TLS for clients and servers within the cluster. Setting up TLS is described in much more detail in [Part III of this series][part-iii]. In this ingress controller configuration, Linkerd expects certs to be defined in a [Kubernetes secret](https://kubernetes.io/docs/concepts/configuration/secret/) named `ingress-certs` and to follow [the format described as part of the ingress user guide](https://kubernetes.io/docs/concepts/services-networking/ingress/#tls). Note that there’s no need to specify a TLS section as part of the ingress resource: Linkerd doesn’t implement that section of the resource. All TLS configuration happens as part of the `l5d-config` ConfigMap.

The Linkerd config remains largely unchanged, save updating the server port to `443`and adding TLS file paths:

```bash
...
servers:
- port: 443
  ip: 0.0.0.0
  clearContext: true
  tls:
    certPath: /io.buoyant/linkerd/certs/tls.crt
    keyPath: /io.buoyant/linkerd/certs/tls.key
...
```

The l5d DaemonSet now mounts a secret volume with the expected name: `ingress-certs`

```bash
spec:
  volumes:
  - name: certificates
    secret:
      secretName: ingress-certs
  ...
  containers:
  - name: l5d
    ...
    ports:
    - name: tls
      containerPort: 443
      hostPort: 443
    ...
    volumeMounts:
    - name: "certificates"
      mountPath: "/io.buoyant/linkerd/certs"
      readOnly: true
    ...
```

And the updated Service config exposes port `443`. A reminder that the certificates we’re using here are for testing purposes only! Create the Secret, delete the DaemonSet and ConfigMap, and re-apply the ingress controller config:

```bash
kubectl apply -f https://raw.githubusercontent.com/linkerd/linkerd-examples/master/k8s-daemonset/k8s/ingress-certificates.yml -n l5d-system
kubectl delete ds/l5d configmap/l5d-config -n l5d-system
kubectl apply -f https://raw.githubusercontent.com/linkerd/linkerd-examples/master/k8s-daemonset/k8s/linkerd-tls-ingress-controller.yml -n l5d-system
```

You should now be able to make an encrypted request:

<!-- markdownlint-disable MD014 -->
```bash
# Example requires this development cert: https://raw.githubusercontent.com/linkerd/linkerd-examples/master/k8s-daemonset/certificates/cert.pem
# The cert expects "hello.world" host, so we add an /etc/hosts entry, eg:
# 104.198.196.230 hello.world
# where "104.198.196.230" is the ip stored in $L5D_SVC_IP
$ curl --cacert cert.pem -H "Host: world.v2" https://hello.world
$ earth (10.0.1.5)!
```
<!-- markdownlint-enable MD014 -->

## CONCLUSION

Linkerd provides a ton of benefits as an edge router. In addition to the dynamic routing and TLS termination described in this post, it also [pools connections](https://en.wikipedia.org/wiki/Connection_pool), [load balances dynamically](/2016/03/16/beyond-round-robin-load-balancing-for-latency/) , [enables circuit breaking](/2017/01/14/making-microservices-more-resilient-with-circuit-breaking/) , and supports [distributed tracing][part-vii]. Using the Linkerd ingress controller and the [Kubernetes configuration](https://raw.githubusercontent.com/linkerd/linkerd-examples/master/k8s-daemonset/k8s/linkerd-ingress-controller.yml) referenced in this post, you gain access to all these features in an easy to use, Kubernetes-native approach. Best of all, this method works seamlessly with the rest of the service mesh, allowing for operation, visibility, and high availability in virtually any cloud architecture.

The [ingress identifier is new](https://github.com/linkerd/linkerd/pull/1116), so we’d love to get your thoughts on what features you want from an ingress controller. You can find us in the [Linkerd community Slack](https://slack.linkerd.io/) or on the [Linkerd Support Forum](https://linkerd.buoyant.io/).

### ACKNOWLEDGEMENTS

Big thanks to [Alex Leong](https://twitter.com/adlleong) and [Andrew Seigner](https://twitter.com/siggy) for feedback on this post.

[part-i]: {{< ref "a-service-mesh-for-kubernetes-part-i-top-line-service-metrics" >}} [part-ii]: {{< ref "a-service-mesh-for-kubernetes-part-ii-pods-are-great-until-theyre-not" >}} [part-iii]: {{< ref "a-service-mesh-for-kubernetes-part-iii-encrypting-all-the-things" >}} [part-iv]: {{< ref "a-service-mesh-for-kubernetes-part-iv-continuous-deployment-via-traffic-shifting" >}} [part-v]: {{< ref "a-service-mesh-for-kubernetes-part-v-dogfood-environments-ingress-and-edge-routing" >}} [part-vi]: {{< ref "a-service-mesh-for-kubernetes-part-vi-staging-microservices-without-the-tears" >}} [part-vii]: {{< ref "a-service-mesh-for-kubernetes-part-vii-distributed-tracing-made-easy" >}} [part-viii]: {{< ref "a-service-mesh-for-kubernetes-part-viii-linkerd-as-an-ingress-controller" >}} [part-ix]: {{< ref "a-service-mesh-for-kubernetes-part-ix-grpc-for-fun-and-profit" >}} [part-x]: {{< ref "a-service-mesh-for-kubernetes-part-x-the-service-mesh-api" >}} [part-xi]: {{< ref "a-service-mesh-for-kubernetes-part-xi-egress" >}}
