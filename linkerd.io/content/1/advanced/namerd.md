+++
aliases = ["/in-depth/namerd", "/advanced/namerd"]
description = "Introduces namerd as a service that helps route Linkerd requests and centralizes routing decisions to provide global Linkerd control."
title = "namerd"
weight = 20
[menu.docs]
parent = "advanced"
weight = 26

+++
namerd is a service that manages routing for multiple Linkerd instances. It does
this by storing [dtabs]({{% ref "/1/advanced/dtabs.md" %}}) and using
[namers]({{% ref "/1/advanced/dtabs.md#namers-addresses" %}}) for service
discovery. namerd supports the same suite of service discovery backends that
Linkerd does, which include services like
ZooKeeper, [Consul](https://www.consul.io/), [Kubernetes
API](http://kubernetes.io/docs/api), and
[Marathon](https://mesosphere.github.io/marathon/).

Using namerd, individual Linkerds no longer need to talk directly to service
discovery or have dtabs hardcoded into their config files. Instead, they ask
namerd for any necessary routing information.  This provides a number of
benefits, which are outlined below.

## Decreased load on service discovery backends

Using namerd means that only a small cluster of namerds need to talk directly
to the service discovery backends instead of every Linkerd in the fleet.  namerd
also utilizes caching to further protect the service discovery backend from
excessive load.

## Global routing policy

By storing dtabs in namerd instead of hardcoding them in the Linkerd configs, it
ensures that routing policy is in sync across the fleet and gives you one
central source of truth when you need to make changes.

## Dynamic routing policy

The other advantage of storing dtabs in namerd is that these dtabs can be
updated dynamically using [namerd's API]({{% namerdconfig "http-controller" %}})
or [command-line tool](https://github.com/linkerd/namerctl).  This allows you to
perform operations like [canary, staging, or blue-green
deploy](https://blog.buoyant.io/2016/05/04/real-world-microservices-when-services-stop-playing-well-and-start-getting-real/#dynamic-routing-with-namerd),
all without needing to restart any Linkerds.

## More information

To learn more about namerd, its setup, and its operation, check out Buoyant's
blog post on [dynamic routing](https://blog.buoyant.io/2016/05/04/real-world-microservices-when-services-stop-playing-well-and-start-getting-real/#dynamic-routing-with-namerd).

To configure your own namerd, head over to the
[namerd config documentation]({{% namerdconfig %}}).
Also check out [namerctl](https://github.com/linkerd/namerctl),
our open source tool for controlling namerd.

For a step-by-step walkthrough of running namerd in Kubernetes to facilitate
continuous deployment, check out Buoyant's blog post [Continuous deployment via
traffic shifting](
https://blog.buoyant.io/2016/11/04/a-service-mesh-for-kubernetes-part-iv-continuous-deployment-via-traffic-shifting/).
