+++
title = "Traffic Split"
description = "With Linkerd it is possible to incrementally direct percentages of traffic between various backend services."
+++

Linkerd implements the [Service Mesh Interface](https://smi-spec.io/) for
[TrafficSplit](https://github.com/deislabs/smi-spec/blob/master/traffic-split.md).
This allows you to incrementally direct percentages of traffic between various
backend services. A common use case for this functionality is orchestrating
[canary](https://martinfowler.com/bliki/CanaryRelease.html) or
[blue/green](https://martinfowler.com/bliki/BlueGreenDeployment.html) rollouts
instead of the default rolling model that Kubernetes uses.
