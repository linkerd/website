---
slug: 'consolidated-kubernetes-service-mesh-linkerd-config'
title: 'The Consolidated Kubernetes Service Mesh Linkerd Config'
aliases:
  - /2017/08/04/consolidated-kubernetes-service-mesh-linkerd-config/
author: 'eliza'
date: Fri, 04 Aug 2017 22:20:42 +0000
draft: false
featured: false
thumbnail: /uploads/linkerd_featured.png
tags: [Linkerd, linkerd, News, tutorials]
---

## A Service Mesh for Kubernetes

Since [October 2016]({{< ref
"a-service-mesh-for-kubernetes-part-i-top-line-service-metrics" >}}), we’ve provided the popular “A Service Mesh for Kubernetes” series of blog posts, highlighting major features of Linkerd and providing working examples of Linkerd and Kubernetes configurations to make use of them. These posts are a useful way to explore various Linkerd features and use-cases in depth.

Now we’ve compressed the configuration in the series into a single, consolidated config to act as a canonical starting point for adding the Linkerd service mesh to a Kubernetes cluster. In this post, we’ll talk you through the details of this configuration file. If you just want to get started with it, you can download it here: [Linkerd Kubernetes Service Mesh config file](https://github.com/linkerd/linkerd-examples/blob/master/k8s-daemonset/k8s/servicemesh.yml).

## A Kubernetes for the Service Mesh

Many Linkerd users have started with the config files in the “A Service Mesh for Kubernetes” series. This is great, and we’d like to encourage the continued use of these blog posts as an educational resource. However, the configs in these blog posts are intended to demonstrate specific Linkerd features in a self-contained manner. Assembling a fully-featured, production-ready configuration requires stitching together several different configs, and this can be difficult!

The consolidated [Linkerd Kubernetes config](https://github.com/linkerd/linkerd-examples/blob/master/k8s-daemonset/k8s/servicemesh.yml) merges the configurations across all these posts and provides a complete configuration to deploy a service mesh of Linkerd instances onto your cluster as a Kubernetes [DaemonSet](https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/). This configuration provides support for HTTP, [HTTP/2](https://buoyant.io/2017/01/10/http2-grpc-and-linkerd/), and [gRPC](https://buoyant.io/2017/04/19/a-service-mesh-for-kubernetes-part-ix-grpc-for-fun-and-profit/) calls, as well as  [load balancing](https://buoyant.io/2016/03/16/beyond-round-robin-load-balancing-for-latency/), [circuit breaking](https://buoyant.io/2017/01/13/making-microservices-more-resilient-with-circuit-breaking/), [dynamic routing](https://buoyant.io/2016/11/04/a-service-mesh-for-kubernetes-part-iv-continuous-deployment-via-traffic-shifting/), and [ingress](https://buoyant.io/2017/04/06/a-service-mesh-for-kubernetes-part-viii-linkerd-as-an-ingress-controller/) and [egress control](https://buoyant.io/2017/06/20/a-service-mesh-for-kubernetes-part-xi-egress/).

Once deployed, HTTP applications can use Linkerd by setting the `http_proxy` environment variable to  `$(NODE_NAME):4140`, where `NODE_NAME` is the name of the Kubernetes node where the application instance is running. Ingress traffic sent to port 80 (or port 8080 for HTTP/2) on the ingress address of the cluster will be routed according to the Kubernetes Ingress resource, and any egress requests to names that do not correspond to Kubernetes services (e.g. “buoyantiodev.wpengine.com”) will fall back to a DNS lookup and be proxied outside the cluster.

## Deploying the Service Mesh

To deploy the service mesh onto your cluster, simply run the following commands:

```bash
kubectl create ns linkerd
kubectl apply -f https://raw.githubusercontent.com/linkerd/linkerd-examples/master/k8s-daemonset/k8s/servicemesh.yml
```

To verify that Linkerd is running, run:

```bash
kubectl -n linkerd port-forward $(kubectl -n linkerd get pod -l app=l5d -o jsonpath='{.items[0].metadata.name}') 9990 &
```

And then open [http://localhost:9990](http://localhost:9990) in your web browser – you should see the Linkerd administration dashboard.

More instructions on configuring your application to work with the official Kubernetes config can be found in [the Linkerd documentation](https://linkerd.io/getting-started/k8s/).

## Conclusion

With this config, it’s easier than ever to get started running Linkerd on Kubernetes! Whether you’re running Kubernetes on a massive production cluster or in [Minikube](https://github.com/kubernetes/minikube) on your laptop; whether you’re already using Linkerd to route critical production traffic or just checking it out for the first time, this config will allow you to easily set up a fully-featured Linkerd service mesh, and serve as a starting point to write your own custom configurations to best suit the needs of your application.

For more information about [Linkerd’s various features](https://linkerd.io/features/index.html) on Kubernetes, see our [Service Mesh For Kubernetes]({{< ref
"a-service-mesh-for-kubernetes-part-i-top-line-service-metrics" >}}) blog series. As always, if you have any questions or just want to chat about Linkerd, join [the Linkerd Slack](http://slack.linkerd.io/) or browse the [Linkerd Support Forum](https://linkerd.buoyant.io/) for more in-depth discussion.
