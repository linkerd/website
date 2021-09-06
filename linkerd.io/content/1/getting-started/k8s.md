+++
aliases = ["/doc/0.1.0/k8s", "/doc/0.2.0/k8s", "/doc/0.2.1/k8s", "/doc/0.3.0/k8s", "/doc/0.3.1/k8s", "/doc/0.4.0/k8s", "/doc/0.5.0/k8s", "/doc/0.6.0/k8s", "/doc/0.7.0/k8s", "/doc/0.7.1/k8s", "/doc/0.7.2/k8s", "/doc/0.7.3/k8s", "/doc/0.7.4/k8s", "/doc/0.7.5/k8s", "/doc/0.8.0/k8s", "/doc/head/k8s", "/doc/latest/k8s", "/doc/k8s", "/getting-started/k8s-daemonset", "/getting-started/k8s"]
description = "How to deploy the Linkerd service mesh in Kubernetes."
title = "Running in Kubernetes"
weight = 4
[menu.docs]
parent = "getting-started"
weight = 34

+++
{{< note >}}
This document is specific to Linkerd 1.x. If you're on Kubernetes, you may wish
to consider [Linkerd 2.x](/getting-started/) instead.
{{< /note >}}

If you have a Kubernetes cluster or even just run
[Minikube](https://github.com/kubernetes/minikube), deploying Linkerd as a
service mesh is the fastest way to get started.  Not only is it incredibly
simple to deploy, it is also suitable for most production use- cases, providing
service discovery, instrumentation, intelligent client-side load balancing,
circuit breakers, and dynamic routing out-of-the-box.

The Linkerd service mesh is deployed as a Kubernetes
[DaemonSet](https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/),
running one Linkerd pod on each node of the cluster.  Applications running in
Kubernetes can then take advantage of the service mesh by sending all of their
network traffic through the Linkerd running on their node.

## Deploy the Linkerd service mesh

Deploy the Linkerd service mesh with these commands:

```bash
kubectl create ns linkerd
kubectl apply -f https://raw.githubusercontent.com/linkerd/linkerd-examples/master/k8s-daemonset/k8s/servicemesh.yml
```

You can verify that Linkerd was deployed successfully by running

```bash
kubectl -n linkerd port-forward $(kubectl -n linkerd get pod -l app=l5d -o jsonpath='{.items[0].metadata.name}') 9990 &
```

And then viewing the Linkerd admin dashboard by visiting
[http://localhost:9990](http://localhost:9990) in your browser.

Note that if your cluster uses CNI, you will need to make a few small changes
to the Linkerd config to enable CNI compatibility.  These are indicated as
comments in the config file itself.  You can learn more about CNI compatibility
on our
[Flavors of Kubernetes page](https://discourse.linkerd.io/t/flavors-of-kubernetes/53).

## Configure your Application

To configure your applications to use Linkerd for HTTP traffic you can set the
`http_proxy` environment variable to `$(NODE_NAME):4140` where `NODE_NAME` is
the name of node on which the application instance is running.  The
`NODE_NAME` environment variable can be set in the instance's pod spec by using
the [Kubernetes downward API](https://kubernetes.io/docs/tasks/inject-data-application/downward-api-volume-expose-pod-information/):

```yaml
        env:
        - name: NODE_NAME
          valueFrom:
            fieldRef:
              fieldPath: spec.nodeName
        - name: http_proxy
          value: $(NODE_NAME):4140
```

See our
[hello world](https://github.com/linkerd/linkerd-examples/blob/master/k8s-daemonset/k8s/hello-world.yml)
Kubernetes config for a complete example of this.

Note that `spec.nodeName` does not work in certain environments such as
[Minikube](https://github.com/kubernetes/minikube).
See our
[Flavors of Kubernetes page](https://discourse.linkerd.io/t/flavors-of-kubernetes/53)
for workarounds.

If your application does not support the `http_proxy` environment variable or
if you want to configure your application to use Linkerd for HTTP/2 or gRPC
traffic, you must configure your application to send traffic directly to
Linkerd:

* `$(NODE_NAME):4140` for HTTP
* `$(NODE_NAME):4240` for HTTP/2
* `$(NODE_NAME):4340` for gRPC

If you are sending HTTP or HTTP/2 traffic directly to Linkerd, you must set
the Host/Authority header to `<service>` or `<service>.<namespace>` where
`<service>` and `<namespace>` are the names of the service and namespace
that you want to proxy to.  If unspecified, `<namespace>` defaults to
`default`.

If your application receives HTTP, HTTP/2, and/or gRPC traffic it must have a
Kubernetes Service object with ports named `http`, `h2`, and/or `grpc`
respectively.

## Ingress

The Linkerd service mesh is also also configured to act as an [Ingress
Controller](https://kubernetes.io/docs/concepts/services-networking/ingress/#ingress-controllers).
Simply create an Ingress resource defining the routes that you want and then
send requests to port 80 (or port 8080 for HTTP/2) of the ingress address for
the cluster.  In cloud environments with external load balancers, the ingress
address is the address of the external load balancer. Otherwise, the address of
any node may be used as the ingress address.

See our [Ingress blog
post](https://buoyant.io/2017/04/06/a-service-mesh-for-kubernetes-part-viii-linkerd-as-an-ingress-controller/)
for more details.

## Next Steps

This config is a great starting point that will work for a wide range of
use-cases.  Please check out our
[Service Mesh for Kubernetes blog series](https://buoyant.io/2016/10/04/a-service-mesh-for-kubernetes-part-i-top-line-service-metrics/)
for information on how to enable more advanced Linkerd features such as
[service-to-service encryption](https://buoyant.io/2016/10/24/a-service-mesh-for-kubernetes-part-iii-encrypting-all-the-things/),
[continuous deployment](https://buoyant.io/2016/11/04/a-service-mesh-for-kubernetes-part-iv-continuous-deployment-via-traffic-shifting/),
and [per-request routing](https://buoyant.io/2017/01/06/a-service-mesh-for-kubernetes-part-vi-staging-microservices-without-the-tears/).
