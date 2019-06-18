---
title: "Google Summer of Code"
---

This is the list of ideas for students wishing to apply to Google Summer of
Code. For more information on what the program is and how to apply, see the
[student guide](https://google.github.io/gsocguides/student/). If you're
interested in applying we would love to get to know you more on
[Slack](https://slack.linkerd.io/).

The most successful projects are often those proposed by the students
themselves. The following list represents some of our ideas and wishes for the
project. However, suggesting your own idea is always encouraged. Jump over to
[Slack](hhttps://slack.linkerd.io/) and chat with us or create an
[issue](https://github.com/linkerd/linkerd2/issues)!


## Cross-cloud integration testing
---

With the proliferation of managed Kubernetes services on many cloud platforms
(GKE, AKS, EKS, Kubernetes on DigitalOcean), the subtle differences between
these providers can create hard to debug and understand issues. This project
involves building out the tooling to create clusters on multiple providers,
interact with those and run the integration test suite on them. It will surface
bugs earlier, make it easier to replicate user issues and provide a common
framework to build sample workloads on top of.

### Expected outcomes

* Tooling that automates creating (and destroying) clusters with specific
  configuration on each of the major providers.

* Configuration with TravisCI that runs the integration tests in parallel.

### Recommended Skills

* Bash
* TravisCI
* Go
* Cloud Providers

### Difficulty level

Medium

### Issue

[https://github.com/linkerd/linkerd2/issues/2213](https://github.com/linkerd/linkerd2/issues/2213)


## Auto-Update
---

Linkerd has frequent updates and keeping up with the weekly edge releases can
be difficult. This project involves building a Kubernetes operator that can
observe the version-check API, auto-update the control plane and replace the
Linkerd data plane proxies with the correct version.

### Expected outcomes

* An operator that watches the version-check API and triggers an update on
  changes.

* Flexible upgrade plans that are saved for each version to describe ordering
  and how to move between versions.

* Validation that each step of an upgrade completes successfully.

* Rolling modification of existing data plane proxies to the latest version
  based off annotations.

### Recommended Skills

* Go
* Kubernetes

### Difficulty level

Hard

### Issue

[https://github.com/linkerd/linkerd2/issues/1903](https://github.com/linkerd/linkerd2/issues/1903)


## Conformance Validation
---

Linkerd has an extensive `check` suite that validates a cluster is ready to
install Linkerd and that the install was successful. These checks are,
unfortunately, static checks. Because of the wide number of ways a Kubernetes
cluster can be configured, users want a way to validate their specific install
for conformance over time. This project involves building a sample application
that exercises all of the features of Linkerd and allows an end user to run it
on their own cluster to validate that everything is working and configured
correctly over a long period of time time.

### Expected outcomes

* Sample application that exercises all Linkerd features.

* CLI integration to start/stop validation.

* Reporting to describe what is not working for users.

### Recommended Skills

* Go
* Bash
* Kubernetes
* gRPC

### Difficulty level

Medium

### Issue

[https://github.com/linkerd/linkerd2/issues/1096](https://github.com/linkerd/linkerd2/issues/1096)


## Alertmanager Integration
---

Linkerd provides rich metrics that are stored in Prometheus out of the box.
These are for both the control plane and data plane. The goal is to provide
Alertmanager integration that comes out of the box, is configurable with
preferred channels (email, slack) and works with ServiceProfiles to easily
create alerts that are per-service and per-route.

### Expected outcomes

* Alertmanager installation as part of the control plane.

* Default alerting policy for the control plane.

* Simple configuration for desired alert channel.

* Integration with ServiceProfiles to setup rules to alert in Alertmanager.

### Recommended Skills

* Go
* Prometheus
* Grafana

### Difficulty level

Easy

### Issue

[https://github.com/linkerd/linkerd2/issues/1726](https://github.com/linkerd/linkerd2/issues/1726)


## Kafka Introspection
---

HTTP-based traffic is only one type of communication in modern applications.
Many use message queues such as Kafka. Getting metrics for
consumers/producers/messages is just as critical to application health as
metrics for requests and responses in HTTP. The goal of this project is to
implement a Kafka codec for the Linkerd proxy that allows it to introspect the
Kafka protocol and provide metrics for that protocol.

### Expected outcomes

* Proxy instrumentation for the Kafka protocol.

* Integration with the Linkerd CLI, dashboards.

* Visualization of the topology between HTTP services and Kafka-based consumers.

### Recommended Skills

* Go
* Rust
* Kubernetes
* Kafka

### Difficulty level

Hard

### Issue

[https://github.com/linkerd/linkerd2/issues/2214](https://github.com/linkerd/linkerd2/issues/2214)
