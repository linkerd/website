+++
date = "2017-03-14T13:43:54-07:00"
title = "Part VII: Distributed tracing made easy"
description = "Linkerd’s role as a service mesh makes it a great source of data around system performance and runtime behavior."
weight = 8
draft = true
aliases = [
  "/tutorials_staging/part-seven"
]
[menu.docs]
  parent = "tutorials"
+++

Author: Kevin Lingerfelt

Linkerd’s role as a _service mesh_ makes it a great source of data around system performance and runtime behavior. This is especially true in polyglot or heterogeneous environments, where instrumenting each language or framework can be quite difficult. Rather than instrumenting each of your apps directly, the service mesh can provide a uniform, standard layer of application tracing and metrics data, which can be collected by systems like [Zipkin](http://zipkin.io/) and [Prometheus](https://prometheus.io/).

In this post we’ll walk through a simple example how Linkerd and Zipkin can work together in Kubernetes to automatically get distributed traces, with only minor changes to the application.

---

In previous installments of this series, we’ve shown you how you can use Linkerd to [capture top-line service metrics](/tutorials/part-one). Service metrics are vital for determining the health of individual services, but they don’t capture the way that multiple services work (or don’t work!) together to serve requests. To see a bigger picture of system-level performance, we need to turn to distributed tracing.

In a previous post, we covered some of the [benefits of distributed tracing](https://buoyant.io/distributed-tracing-for-polyglot-microservices/), and how to configure Linkerd to export tracing data to [Zipkin](http://zipkin.io/). In this post, we’ll show you how to run this setup entirely in Kubernetes, including Zipkin itself, and how to derive meaningful data from traces that are exported by Linkerd.

---

## A Kubernetes Service Mesh
Before we start looking at traces, we’ll need to deploy Linkerd and Zipkin to Kubernetes, along with some sample apps. The [linkerd-examples](https://github.com/linkerd/linkerd-examples/tree/master/k8s-daemonset) repo provides all of the configuration files that we’ll need to get tracing working end-to-end in Kubernetes. We’ll walk you through the steps below.

---

## Step 1: Install Zipkin
We’ll start by installing Zipkin, which will be used to collect and display tracing data. In this example, for convenience, we’ll use Zipkin’s in-memory store. (If you plan to run Zipkin in production, you’ll want to switch to using one of its persistent backends.)

To install Zipkin in the default Kubernetes namespace, run:
```
kubectl apply -f https://raw.githubusercontent.com/linkerd/linkerd-examples/master/k8s-daemonset/k8s/zipkin.yml
```

You can confirm that installation was successful by viewing Zipkin’s web UI:
```
ZIPKIN_LB=$(kubectl get svc zipkin -o jsonpath="{.status.loadBalancer.ingress[0].*}")
open http://$ZIPKIN_LB # on OS X
```

Note that it may take a few minutes for the ingress IP to become available. Or if external load balancer support is unavailable for the cluster, use hostIP:

```
ZIPKIN_LB=</code>$(kubectl get po -l app=zipkin -o jsonpath="{.items[0].status.hostIP}"):$(kubectl get svc zipkin -o 'jsonpath={.spec.ports[0].nodePort}') open http://$ZIPKIN_LB # on OS X
```

However, the web UI won’t show any traces until we install Linkerd.

---

## Step 2: Install the service mesh
Next we’ll install the Linkerd service mesh, configured to write tracing data to Zipkin. To install Linkerd as a DaemonSet (i.e., one instance per host) in the default Kubernetes namespace, run:

```
kubectl apply -f https://raw.githubusercontent.com/linkerd/linkerd-examples/master/k8s-daemonset/k8s/linkerd-zipkin.yml
```

This installed Linkerd as a service mesh, exporting tracing data with Linkerd’s [Zipkin telemeter](https://linkerd.io/config/0.9.0/linkerd/index.html#zipkin-telemeter). The relevant config snippet is:

```
telemetry:
- kind: io.l5d.zipkin
  host: zipkin-collector.default.svc.cluster.local
  port: 9410
  sampleRate: 1.0
```

Here we’re telling Linkerd to send tracing data to the Zipkin service that we deployed in the previous step, on port 9410. The configuration also specifies a sample rate, which determines the number of requests that are traced. In this example we’re tracing all requests, but in a production setting you may want to set the rate to be much lower (the default is 0.001, or 0.1% of all requests).

You can confirm the installation was successful by viewing Linkerd’s admin UI (note, again, that it may take a few minutes for the ingress IP to become available, depending on the vagaries of your cloud provider):

```
L5D_INGRESS_LB=$(kubectl get svc l5d -o jsonpath="{.status.loadBalancer.ingress[0].*}")
open http://$L5D_INGRESS_LB:9990 # on OS X
```

Or if external load balancer support is unavailable for the cluster, use hostIP:

```
L5D_INGRESS_LB=$(kubectl get po -l app=l5d -o jsonpath="{.items[0].status.hostIP}")
open http://$L5D_INGRESS_LB:$(kubectl get svc l5d -o 'jsonpath={.spec.ports[2].nodePort}') # on OS X
```

---
## Step 3: Install the sample apps
Now we’ll install the “hello” and “world” apps in the default namespace. These apps rely on the nodeName supplied by the [Kubernetes downward API](https://kubernetes.io/docs/tasks/inject-data-application/downward-api-volume-expose-pod-information/) to find Linkerd. To check if your cluster supports nodeName, you can run this test job:
```
kubectl apply -f https://raw.githubusercontent.com/linkerd/linkerd-examples/master/k8s-daemonset/k8s/node-name-test.yml
```

And then looks at its logs:

```
kubectl logs node-name-test
```

If you see an ip, great! Go ahead and deploy the hello world app using:
```
kubectl apply -f https://raw.githubusercontent.com/linkerd/linkerd-examples/master/k8s-daemonset/k8s/hello-world.yml
```

If instead you see a “server can’t find …” error, deploy the hello-world legacy version that relies on hostIP instead of nodeName:
```
kubectl apply -f https://raw.githubusercontent.com/linkerd/linkerd-examples/master/k8s-daemonset/k8s/hello-world-legacy.yml
```

Congrats! At this point, we have a functioning service mesh with distributed tracing enabled, and an application that makes use of it.

Let’s see the entire setup in action by sending traffic through Linkerd’s outgoing router running on port 4140:
```
http_proxy=http://$L5D_INGRESS_LB:4140 curl -s http://hello
Hello () world ()!
```
Or if using hostIP:
```
http_proxy=http://$L5D_INGRESS_LB:</code>$(kubectl get svc l5d -o 'jsonpath={.spec.ports[0].nodePort}') curl -s http://hello Hello () world ()!
```
If everything is working, you’ll see a “Hello world” message similar to that above, with the IPs of the pods that served the request.

---
## Step 4: Enjoy the view
Now it’s time to see some traces. Let’s start by looking at the trace that was emitted by the test request that we sent in the previous section. Zipkin’s UI allows you to search by “span” name, and in our case, we’re interested in spans that originated with the Linkerd router running on 0.0.0.0:4140, which is where we sent our initial request. We can search for that span as follows:
```
open http://$ZIPKIN_LB/?serviceName=0.0.0.0%2F4140 # on OS X
```

That should surface 1 trace with 8 spans, and the search results should look like this:

{{< fig src="/images/tutorials/buoyant-k8s-tracing-search-1-large-1024x352.png" >}}

Clicking on the trace from this view will bring up the trace detail view:

{{< fig src="/images/tutorials/buoyant-k8s-tracing-trace-1-large-1024x360.png" >}}

From this view, you can see the timing information for all 8 spans that Linkerd emitted for this trace. The fact that there are 8 spans for a request between 2 services stems from the service mesh configuration, in which each request passes through two Linkerd instances (so that the protocol can be upgraded or downgraded, or [TLS can be added and removed across node boundaries](/tutorials/part-three)). Each Linkerd router emits both a server span and a client span, for a total of 8 spans.

Clicking on a span will bring up additional details for that span. For instance, the last span in the trace above represents how long it took the world service to respond to a request—8 milliseconds. If you click on that span, you’ll see the span detail view:

{{< fig src="/images/tutorials/buoyant-k8s-tracing-span-1-large-1024x712.png" >}}
