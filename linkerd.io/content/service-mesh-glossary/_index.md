---
title: Service Mesh Glossary
description:
  This glossary covers the most important service mesh concepts. Whether
  latency, sidecar proxy, or success rate, you'll find a succinct definition for
  each term.
type: docs
params:
  faqSchema:
    - question: What is an API gateway?
      answer: |-
        An API gateway sits in front of an app and is designed to solve
        business problems like authentication and authorization, rate limiting,
        and providing a common access point for external consumers. A service
        mesh, in contrast, is focused on providing operational logic between
        components of the app.
    - question: What is a cluster?
      answer: |-
        In the cloud native context, a cluster is a group of machines, physical
        or virtual, that make up the pool of hardware on which a container
        orchestrator such as Kubernetes can run. Each machine in the cluster is
        commonly referred to as a node.
    - question: What is a container?
      answer: |-
        A container is a lightweight packaging of an application and its
        dependencies, designed to be run by a host operating system (OS) in an
        isolated fashion with strict limits on resource consumption and access
        to the OS.
    - question: What is a service mesh control plane?
      answer: |-
        The control plane of a service mesh provides the command and control
        signals required for the [data plane](#data-plane) to operate. The
        control plane controls the data plane and provides the UI and API that
        operators use to configure, monitor, and operate the mesh.
    - question: What is a data plane?
      answer: |-
        The data plane of a service mesh comprises the deployment of its
        [sidecar proxies](#sidecar-proxy) that intercept in-mesh application
        traffic. The data plane is responsible for gathering metrics, observing
        traffic, and applying policy.
    - question: What is distributed tracing?
      answer: |-
        In a microservices-based system, an individual request from a client
        typically triggers a series of requests across a number of services.
        Distributed tracing is the practice of "tracing", or following, these
        requests as they move through the distributed system for reasons of
        performance monitoring or debugging.
    - question: What is egress?
      answer: |-
        In the context of a Kubernetes cluster, "egress" refers to traffic
        leaving the cluster. Unlike with ingress traffic, there is no explicit
        Kubernetes egress resource and, by default, egress traffic simply exits
        the cluster.
    - question: What is Enterprise Service Bus (ESB)?
      answer: |-
        An ESB is a tool and architectural pattern that largely predates modern
        microservice architectures. ESBs were used to manage communication in a
        service-oriented architecture, handling everything from inter-app
        communication, data transformation, message routing, and message queuing
        functionality.
    - question: What are golden metrics?
      answer: |-
        Golden metrics, or golden signals, are the core metrics of application
        health. The set of golden metrics is generally defined as
        [latency](#latency), traffic volume, error rate, and saturation.
        Linkerd's golden metrics omit saturation.
    - question: What is an ingress?
      answer: |-
        An ingress is a specific application that runs in a Kubernetes cluster
        and handles traffic coming into the cluster from off-cluster sources.
        This traffic is referred to as ingress (or occasionally "north/south"
        traffic)
    - question: What is an init container?
      answer: |-
        An init container is a container run at the beginning of the pod
        lifecycle before the application containers start. Typical use cases of
        init containers include rewriting network rules; assembling secrets for
        the application; and copying files from a network location.
    - question: What is latency?
      answer: |-
        Latency refers to the time it takes an application to do something
        (e.g., processing a request, populating data, etc.) In service mesh
        terms, this is measured at the response level, i.e. by timing how long
        the application takes to respond to a request.
    - question: What is Linkerd?
      answer: |-
        Linkerd was the first service mesh and the project that defined the
        term "service mesh" itself. First released 2016, Linkerd is designed to
        be the fastest, lightest-weight service mesh possible for Kubernetes.
        Linkerd is a Cloud Native Computing Foundation (CNCF) graduated project.
    - question: What is load balancing?
      answer: |-
        Load balancing is the act of distributing work across a number of
        equivalent endpoints. Kubernetes, like many systems, provides load
        balancing at the connection level. A service mesh like Linkerd improves
        this by performing load balancing at the request level.
    - question: What is mTLS?
      answer: |-
        Mutual TLS (mTLS) is a way to authenticate and encrypt a connection
        between two endpoints. Mutual TLS is simply the standard Transport Layer
        Security (TLS) protocol, with the additional restriction that identity
        on both sides of the connection must be validated.
    - question: What is multi-cluster?
      answer: |-
        In the context of Kubernetes, multi-cluster usually refers to running
        an application "across" multiple Kubernetes clusters. Linkerd's
        multi-cluster support provides seamless and secured communication across
        clusters, in a way that's secure even across the public Internet.
    - question: What is observability?
      answer: |-
        Observability is the ability to understand the health and performance
        of a system from the data it generates. In the context of service
        meshes, observability generally refers to the data about a system that
        the service mesh can report.
    - question: What is reliability?
      answer: |-
        Reliability is a system property that measures how well the system
        responds to failure. The more reliable a system is, the better it can
        handle individual components being down or degraded.
    - question: What is a service mesh?
      answer: |-
        A service mesh is a tool for adding observability, security, and
        reliability features to applications by inserting these features at the
        platform layer rather than the application layer. Service meshes are
        implemented by adding [sidecar proxies](#sidecar-proxy) that intercept
        all traffic between applications.
    - question: What is a sidecar proxy?
      answer: |-
        A sidecar proxy is a proxy that is deployed alongside the applications
        in the mesh. (In Kubernetes, as a container within the application's
        pod.) The sidecar proxy intercepts network calls to and from the
        applications and is responsible for implementing any control
        plane](#control-plane)’s logic or rules.
    - question: What is the Success rate?
      answer: |-
        Success rate refers to the percentage of requests that our application
        responds to successfully. For HTTP traffic, for example, this is
        measured as the proportion of 2xx or 4xx responses over total responses.
---

## API Gateway

An API gateway sits in front of an application and is designed to solve business
problems like authentication and authorization, rate limiting, and providing a
common access point for external consumers. A service mesh, in contrast, is
focused on providing operational (not business) logic between components of the
application.

## Cluster

In the cloud native context, a cluster is a group of machines, physical or
virtual, that make up the pool of hardware on which a container orchestrator
such as Kubernetes can run. Each machine in the cluster is commonly referred
to as a node, and the nodes of a cluster are typically uniform, fungible, and
interconnected.

## Container

A container is a lightweight packaging of an application and its dependencies,
designed to be run by a host operating system (OS) in an isolated fashion
with strict limits on resource consumption and access to the OS. In this
sense, a container is an atomic executable "unit" that can be run by the
OS without application-specific setup or configuration.

In the service mesh context, containers were popularized by Docker as a
lightweight alternative to virtual machines (VMs), which had similar
characteristics but were considerably heavier weight. The rise of containers,
in turn, gave rise to container orchestrators such as Kubernetes, which
allowed applications, when packaged as containers, to be automatically
scheduled across a pool of machines (called a "[cluster](#cluster)").
The rise of Kubernetes gave rise to the sidecar model of deployment,
which allowed [service meshes](#service-mesh) like Linkerd to provide
their functionality in a way that was decoupled from the application
and did not impose a severe operational cost to the operator.

## Control Plane

The control plane of a service mesh provides the command and control signals
required for the [data plane](#data-plane) to operate. The control plane controls
the data plane and provides the UI and API that operators use to configure,
monitor, and operate the mesh.

## Data Plane

The data plane of a service mesh comprises the deployment of its
[sidecar proxies](#sidecar-proxy) that intercept in-mesh application traffic.
The data plane is responsible for gathering metrics, observing traffic, and
applying policy.

## Distributed tracing

In a microservices-based system, an individual request from a client typically
triggers a series of requests across a number of services. Distributed tracing
is the practice of "tracing", or following, these requests as they move
through the distributed system for reasons of performance monitoring or
debugging. It is typically achieved by modifying the services to emit tracing
information, or "spans," and aggregating them in a central store.

## Egress

In the context of a Kubernetes cluster, "egress" refers to traffic leaving the
cluster. Unlike with ingress traffic, there is no explicit Kubernetes egress
resource and, by default, egress traffic simply exits the cluster. When control
and monitoring of Kubernetes egress traffic is necessary, it is typically
implemented at the networking / CNI layer, or by adding an explicit egress
proxy.

## Enterprise Service Bus (ESB)

An ESB is a tool and architectural pattern that largely predates modern
microservice architectures. ESBs were used to manage communication in a
service-oriented architecture (SOA), handling everything from inter-app
communication, data transformation, message routing, and message queuing
functionality. In modern microservices applications, a service mesh like
Linkerd replaces much of the need for an ESB and provides improved
separation of concerns and reduction of SPOFs.

## Golden Metrics

Golden metrics, or golden signals, are the core metrics of application health.
The set of golden metrics is generally defined as [latency](#latency), traffic
volume, error rate, and saturation. Linkerd's golden metrics omit saturation.

## Ingress

An ingress is a specific application that runs in a Kubernetes
[cluster](#cluster) and handles traffic coming into the cluster from
off-cluster sources. This traffic is referred to as ingress (or
occasionally "north/south" traffic). In contrast to in-cluster traffic,
which is typically mediated by the [service mesh](#service-mesh), ingress
traffic has a specific set of concerns arising from the fact that it
often comes from customer, third-party, or other non-application sources.
[API gateways](#api-gateway) are often used as ingresses.

## Init Container

An init container is a container run at the beginning of the pod lifecycle,
before the application containers start. Typical use cases of init containers
include rewriting network rules; assembling secrets for the application;
and copying files from a network location. For example, Linkerd's init
container updates networking rules to direct all TCP traffic for the pod
through the Linkerd proxy container. An init container terminates before
the application container starts.

## Latency

Latency refers to the time it takes an application to do something (e.g.,
processing a request, populating data, etc.) In [service mesh](#service-mesh)
terms, this is
measured at the response level, i.e. by timing how long the application takes to
respond to a request. Latency is typically characterized by the percentiles of a
distribution, commonly including the p50 (or median), the p95 (or 95th
percentile), the p99 (or 99th percentile), and so on.

## Linkerd

Linkerd was the first [service mesh](#service-mesh) and the project that
defined the term
"service mesh" itself. First released 2016, Linkerd is designed to be the
fastest, lightest-weight service mesh possible for Kubernetes. Linkerd is a
Cloud Native Computing Foundation (CNCF) graduated project.

## Load balancing

Load balancing is the act of distributing work across a number of equivalent
endpoints. Kubernetes, like many systems, provides load balancing at the
connection level. A service mesh like Linkerd improves this by performing
load balancing at the request level, which allows it to take into account
factors such as the performance of individual endpoints.

Load balancing at the request level also allows Linkerd to effectively
load balance requests for systems that use gRPC (and HTTP/2 more generally),
which multiplex requests across a single connection—Kubernetes itself
cannot effectively load balance these systems because there is typically
only one connection ever made.

Load balancing algorithms decide which endpoint will serve a given request.
The most common is "round-robin," which simply iterates across all endpoints.
More advanced balancing algorithms include "least loaded," which distributes
load based on the number of outstanding requests for each endpoint.
Linkerd itself uses a sophisticated latency-aware load balancing algorithm
called EWMA (exponentially-weighted moving average), to distribute load
based on endpoint latency while being responsive to rapid changes in the
latency profile of individual endpoints.

## mTLS

Mutual TLS (mTLS) is a way to [authenticate and encrypt a connection between
two endpoints](https://linkerd.io/2/features/automatic-mtls/).
Mutual TLS is simply the standard Transport Layer Security
(TLS) protocol, with the additional restriction that identity on both sides
of the connection must be validated. (The use of TLS in web browsers, for
example, typically only validates the identity of the server, not the client.)

In the service mesh context, mTLS is the basic mechanism for validating the
identity of services on either side of a connection and for keeping that
communication confidential. This validation of identity is the basis for
policy enforcement.

## Multi-cluster

In the context of Kubernetes, multi-cluster usually refers to running
an application "across" multiple Kubernetes clusters. Linkerd's multi-cluster
support provides seamless and secured communication across clusters, in a
way that's secure even across the public Internet, and is fully transparent
to the application itself.

## Observability

Observability is the ability to understand the health and performance of
a system from the data it generates. In the context of service meshes,
observability generally refers to the data about a system that the
service mesh can report. This includes things like
"[golden metrics](#golden-metrics)",
service topology graphs of dependencies, traffic sampling, and so on.

## Reliability

Reliability is a system property that measures how well the system
responds to failure. The more reliable a system is, the better it
can handle individual components being down or degraded. For
multi-service or microservice applications, a service mesh can
be used to increase the reliability by applying[techniques
like retries and timeouts](https://linkerd.io/2/features/retries-and-timeouts/)
to cross-service calls, by [load balancing
in intelligent ways](https://linkerd.io/2/features/load-balancing/),
by [shifting traffic](https://linkerd.io/2/features/traffic-split/)
in the presence of errors, and so on.

## Service mesh

A service mesh is a tool for adding [observability](#observability),
security, and [reliability](#reliability)
features to applications by inserting these features at the platform layer
rather than the application layer. Service meshes are implemented by adding
[sidecar proxies](#sidecar-proxy) that intercept all traffic between
applications. The resulting set of proxies forms the service mesh
[data plane](#data-plane) and is managed by the service mesh
[control plane](#control-plane). The proxies funnel all communication between
services and are the vehicle through which service mesh features are introduced.

## Sidecar Proxy

A sidecar proxy is a proxy that is deployed alongside the applications in the
mesh. (In Kubernetes, as a container within the application's pod.) The sidecar
proxy intercepts network calls to and from the applications and is responsible
for implementing any [control plane](#control-plane)’s logic or rules.
Collectively, the sidecar proxies form the service mesh's
[data plane](#data-plane). Linkerd uses a Rust-based "micro-proxy" called
Linkerd2-proxy that is specifically designed for the service mesh use case.
Linkerd2-proxy is significantly lighter and easier to operate than
general-purpose proxies such as Envoy or NGINX. See
[Why Linkerd Doesn't Use Envoy](/2020/12/03/why-linkerd-doesnt-use-envoy/) for
more.

## Success rate

Success rate refers to the percentage of requests that our application responds
to successfully. For HTTP traffic, for example, this is measured as the
proportion of 2xx or 4xx responses over total responses. (Note that, in this
context, 4xx is considered a successful response—the application performed its
jobs—whereas 5xx responses are considered unsuccessful—the application failed to
respond to the request). A high success rate indicates that an application is
behaving correctly.
