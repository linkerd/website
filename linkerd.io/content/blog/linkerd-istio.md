---
title: 'Linkerd and Istio: like peanut butter and jelly'
author: 'sarah'
date: Tue, 11 Jul 2017 11:31:07 +0000
draft: true
tags:
  [
    Buoyant,
    Industry Perspectives,
    Integrations,
    istio,
    Linkerd,
    linkerd,
    service mesh,
    Tutorials &amp; How-To's,
  ]
---

Today (in addition to [some other exciting news](https://buoyant.io/2017/07/11/buoyant-and-benchmark/)) we’re happy to announce [the release of Linkerd 1.1.1](https://github.com/linkerd/linkerd/releases/tag/1.1.1), which features integration with the [Istio project](http://istio.io)! This integration is currently in a beta state, but is usable today—see below for how to try it out. In the upcoming months we’ll continue to invest in making this integration ready for production. (Side note: interested in working on Linkerd and Istio? [We’re hiring](https://buoyant.io/careers/)!) In this blog post, I’ll share a little bit about this feature and what it means for Linkerd and Istio users.

## Managing microservice communication

Istio is “an open platform to connect, manage, and secure microservices”. Linkerd is “an open source service mesh for cloud native applications”. Both projects seek to improve the _runtime_ behavior of a microservice application, especially the communication between individual microservices. Managing this runtime behavior is important because, while we have tools like Docker and Kubernetes to manage deployment and execution of service code, that’s not enough to make applications resilient and manageable. The way that microservices interact with each other at runtime—how traffic load flows through the system—needs to be monitored, managed, and controlled. As William writes in “[What is a service mesh? And why do I need one?](https://buoyant.io/2017/04/25/whats-a-service-mesh-and-why-do-i-need-one/)”,

> In the cloud native model, a single application might consist of hundreds of services; each service might have thousands of instances; and each of those instances might be in a constantly-changing state as they are dynamically scheduled by an orchestrator like Kubernetes. Not only is service communication in this world incredibly complex, it’s a pervasive and fundamental part of runtime behavior. Managing it is vital to ensuring end-to-end performance and reliability.

These lessons are not theoretical. Istio was designed based on lessons learned at Google, IBM, and Lyft; Linkerd was designed based on lessons learned at Twitter. These two companies are at the leading edge of complex and high volume traffic patterns and rapidly evolving applications, and they’ve both discovered the critical need for comprehensive and systematic way of managing and controlling runtime traffic.

## Istio and Linkerd

So why run Linkerd with Istio? Beyond sharing many of the same goals, the two projects are also actually very complimentary. Linkerd brings a widely-deployed, production-tested service mesh that is focused explicitly on supporting every possible environment and providing a uniform layer of communication across them—allowing you to, for example, add Kubernetes into an existing stack and slowly migrate service code across the boundary. To this, Istio brings excellent APIs, well-designed models, an expansive, forward-thinking feature set. If those that sounds like a great combination, then this might the integration for you! Linkerd 1.1.1, [released this week](https://github.com/linkerd/linkerd/releases/tag/1.1.1), provides a beta version of this integration. In this integration, Istio provides a “control plane” in the form of a set of APIs and controller logic (the Mixer, the Pilot), and Linkerd provides a “data plane” in the form of a deployment of service proxies—the _service mesh_. These two pieces are combined by using Istio’s control plane to drive the Linkerd service mesh. The current version features some (but not all) of Istio’s many features, including support for Istio’s [routing rules](https://istio.io/docs/tasks/traffic-management/request-routing.html), [ingress](https://istio.io/docs/tasks/traffic-management/ingress.html), [egress](https://istio.io/docs/tasks/traffic-management/egress.html), and [metrics](https://istio.io/docs/tasks/telemetry/metrics-logs.html) mechanisms. This means that if you are an existing Linkerd user on Kubernetes, you can start trying Istio as a way of controlling your service mesh deployment. And if you’re an Istio enthusiast, you can start trying Istio with Linkerd!

## Trying it out

If you have a Kubernetes cluster handy, you can test out the Linkerd and Istio integration with a few steps:

1.  First, follow steps 1 through 4 of the the [Istio Installation Guide](https://istio.io/docs/tasks/installing-istio.html) to install the `istioctl` binary and handle any RBAC in your cluster. Stop after step 4.
2.  Run `kubectl apply -f https://raw.githubusercontent.com/linkerd/linkerd-examples/master/istio/istio-linkerd.yml` to install Istio/Linkerd onto your cluster.
3.  (optionally) Enable metrics collection by following the corresponding steps in the [Istio Installation Guide](https://istio.io/docs/tasks/installing-istio.html#enabling-metrics-collection).

At this point, you’re ready to install an application on top of the Kubernetes + Istio + Linkerd stack (the KIL stack?). Istio uses a Kubernetes concept called [init containers](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/) to automatically configure iptables rules at container creation time; we provide a handy utility to automate this process for Linkerd called \`linkerd-inject\`. You can install it with:

go get github.com/linkerd/linkerd-inject

And then use it to deploy your app like so:

kubectl apply -f <(linkerd-inject -f <(curl -s https://raw.githubusercontent.com/linkerd/linkerd-inject/master/example/hello-world.yml))

(If you’re using Minikube, or if you want to avoid the `linkerd-inject` utility, see the [full instructions in the Linkerd Istio integration guide](https://linkerd.io/getting-started/istio/). Voila! You now have a functioning Linkerd + Istio installation. At this point you should be able to follow many of the Istio walkthroughs, e.g. the [Istio request routing demo](https://istio.io/docs/tasks/traffic-management/request-routing.html)-—though you’ll have to continue to use `linkerd-inject` rather than `istioctl kube-inject` when you’re installing the applications. Note that, in the interest of simplicity, in this integration we’ve replaced Istio’s default Envoy component entirely with Linkerd. In the future, hybrid approaches that combine the two proxies may also be possible.

## The future

Although Istio integration is currently in beta for Linkerd 1.1.1, we plan to make it a fully-supported feature over the upcoming releases. (Which means that, yes, [commercial support will be available](https://info.buoyant.io/linkerd/enterprise).) In the long run, our goal is to offer Istio’s excellent control plane logic and APIs to our many Linkerd service mesh users, and to offer Istio users the ability to deploy the Linkerd service mesh, with its production-tested and wide-ranging systems support, as the fabric underlying their Istio deployment. [Stay tuned for much more along these lines.](https://info.buoyant.io/newsletter)

## Thanks

We’d like to thank the many members of the Istio team who have been open, welcoming, and helpful as we’ve worked on this integration. A special shoutout to Louis Ryan, Varun Talwar, Shriram Rajagopalan, Zack Butcher, Laurent Demailly, Kuat Yessenov, and Douglas Reid for their help and guidance along the way.
