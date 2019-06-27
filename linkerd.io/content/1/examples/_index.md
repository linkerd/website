+++
aliases = ["/examples"]
description = "Example applications and tutorials on Linkerd."
title = "Overview"
weight = 1
[menu.docs]
identifier = "examples"
name = "Examples"
weight = 7

+++
The [linkerd-examples GitHub repo](https://github.com/linkerd/linkerd-examples)
contains several examples of how to use Linkerd and namerd in various environments.

The [Buoyant blog](https://blog.buoyant.io) also contains several examples and
walkthroughs highlighting various Linkerd features.

## Kubernetes

For walkthroughs of various Linkerd features with deployable examples, check out
[A Service Mesh for Kubernetes blog series](https://buoyant.io/2016/10/04/a-service-mesh-for-kubernetes-part-i-top-line-service-metrics/):

* [Top-line service metrics](https://buoyant.io/a-service-mesh-for-kubernetes-part-i-top-line-service-metrics/)
* [Pods are great, until they’re not](https://buoyant.io/a-service-mesh-for-kubernetes-part-ii-pods-are-great-until-theyre-not/)
* [Encrypting all the things](https://buoyant.io/a-service-mesh-for-kubernetes-part-iii-encrypting-all-the-things/)
* [Continuous deployment via traffic shifting](https://buoyant.io/a-service-mesh-for-kubernetes-part-iv-continuous-deployment-via-traffic-shifting/)
* [Dogfood environments, ingress, and edge routing](https://buoyant.io/a-service-mesh-for-kubernetes-part-v-dogfood-environments-ingress-and-edge-routing/)
* [Staging microservices without the tears](https://buoyant.io/a-service-mesh-for-kubernetes-part-vi-staging-microservices-without-the-tears/)
* [Distributed tracing made easy](https://buoyant.io/a-service-mesh-for-kubernetes-part-vii-distributed-tracing-made-easy/)
* [Linkerd as an ingress controller](https://buoyant.io/a-service-mesh-for-kubernetes-part-viii-linkerd-as-an-ingress-controller/)
* [gRPC for fun and profit](https://buoyant.io/a-service-mesh-for-kubernetes-part-ix-grpc-for-fun-and-profit/)
* [The Service Mesh API](https://buoyant.io/a-service-mesh-for-kubernetes-part-x-the-service-mesh-api/)
* [Egress](https://buoyant.io/a-service-mesh-for-kubernetes-part-xi-egress/)

Other Kubernetes posts:

* [The Consolidated Kubernetes Service Mesh Linkerd Config](https://buoyant.io/2017/08/08/a-service-mesh-for-ecs/)
* [Using Linkerd with Kubernetes RBAC](https://buoyant.io/2017/07/24/using-linkerd-kubernetes-rbac/)

The [linkerd-examples/k8s-daemonset](https://github.com/linkerd/linkerd-examples/tree/master/k8s-daemonset)
folder has various Kubernetes examples using different
Linkerd features, some of which are referenced in the blogs.

## DC/OS, Mesos

* [Linkerd on DC/OS for Service Discovery and Visibility](https://buoyant.io/2016/10/10/linkerd-on-dcos-for-service-discovery-and-visibility/)
* [Linkerd on DC/OS: Microservices in Production Made Easy](https://buoyant.io/2016/04/19/linkerd-dcos-microservices-in-production-made-easy/)
* [linkerd-examples/dcos](https://github.com/linkerd/linkerd-examples/tree/master/dcos)
* [linkerd-examples/mesos-marathon](https://github.com/linkerd/linkerd-examples/tree/master/mesos-marathon)

## Amazon ECS

* [A Service Mesh For ECS](https://buoyant.io/2017/08/08/a-service-mesh-for-ecs/)
* [linkerd-examples/ecs](https://github.com/linkerd/linkerd-examples/tree/master/ecs)

## Service Mesh

* [What’s a service mesh? And why do I need one?](https://buoyant.io/2017/04/25/whats-a-service-mesh-and-why-do-i-need-one/)

## Linkerd-tcp

* [Introducing Linkerd-tcp](https://buoyant.io/2017/03/29/introducing-linkerd-tcp/)
* [linkerd-examples/linkerd-tcp](https://github.com/linkerd/linkerd-examples/tree/master/linkerd-tcp)

## Linkerd features

Blogs and example configs highlighting various Linkerd features, including
how to use Linkerd to improve latency, load balancing, using failure accrual,
http proxying, adding TLS, a metrics pipeline, gRPC and HTTP/2, and more!

* [Making Things Faster by Adding More Steps](https://buoyant.io/2017/01/31/making-things-faster-by-adding-more-steps/)
* [Making microservices more resilient with circuit breaking](https://buoyant.io/2017/01/13/making-microservices-more-resilient-with-circuit-breaking/)
* [HTTP/2, gRPC and Linkerd](https://buoyant.io/2017/01/10/http2-grpc-and-linkerd/)
* [Distributed Tracing for Polyglot Microservices](https://buoyant.io/2016/05/17/distributed-tracing-for-polyglot-microservices/)
* [Transparent TLS with Linkerd](https://buoyant.io/2016/04/19/linkerd-dcos-microservices-in-production-made-easy/)
* [Beyond Round Robin: Load Balancing for Latency](https://buoyant.io/2016/03/16/beyond-round-robin-load-balancing-for-latency/)
* [linkerd-examples/getting-started](https://github.com/linkerd/linkerd-examples/tree/master/getting-started)
* [linkerd-examples/failure-accrual](https://github.com/linkerd/linkerd-examples/tree/master/failure-accrual)
* [linkerd-examples/http-proxy](https://github.com/linkerd/linkerd-examples/tree/master/http-proxy)
* [linkerd-examples/influxdb](https://github.com/linkerd/linkerd-examples/tree/master/influxdb)

## Further reading

See the [External Resources]({{% ref "/1/examples/external-resources.md" %}})
section for additional articles and tutorials on Linkerd!
