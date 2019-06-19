+++
aliases = ["/doc/0.1.0/deployment", "/doc/0.2.0/deployment", "/doc/0.2.1/deployment", "/doc/0.3.0/deployment", "/doc/0.3.1/deployment", "/doc/0.4.0/deployment", "/doc/0.5.0/deployment", "/doc/0.6.0/deployment", "/doc/0.7.0/deployment", "/doc/0.7.1/deployment", "/doc/0.7.2/deployment", "/doc/0.7.3/deployment", "/doc/0.7.4/deployment", "/doc/0.7.5/deployment", "/doc/0.8.0/deployment", "/doc/head/deployment", "/doc/latest/deployment", "/doc/deployment", "/in-depth/deployment", "/advanced/deployment"]
description = "Addresses typical deployment models for running Linkerd in your architecture."
title = "Deployment"
weight = 40
[menu.docs]
parent = "advanced"
weight = 27

+++
There are two common deployment models for Linkerd: per-host, and as a sidecar
process.

## Per-host

In the per-host deployment model, one Linkerd instance is deployed per host
(whether physical or virtual), and all application service instances on that
host route traffic through this instance.

This model is useful for deployments that are primarily host-based.  Each
service instance on the host can address its corresponding Linkerd instance at
a fixed location (typically, `localhost:4140`), obviating the need for any
significant client-side logic.

Since this model requires high concurrency of Linkerd instances, a larger
resource profile is usually appropriate. In this model, the loss of an
individual Linkerd instance is equivalent to losing the host itself.

{{< fig src="/images/diagram-per-host-deployment.png"
    title="Linkerd deployed per host." >}}

## Sidecar

In the sidecar deployment model, one Linkerd instance is deployed per instance
of every application service. This model is useful for deployments that are
primarily instance- or container-based, as opposed to host-based. For example,
with a Kubernetes deployment, a Linkerd container can be deployed as part of
the Kubernetes "pod", and the service instance can address the Linkerd instance
as if it were on the same host, i.e. by connecting to `localhost:4140`.

Since this sidecar approach requires many instances of Linkerd, a smaller
resource profile is usually appropriate. In this model, the loss of an
individual Linkerd instance is equivalent to losing the corresponding service
instance.

{{< fig src="/images/diagram-sidecar-deployment.png"
    title="Linkerd deployed as a sidecar process (service-to-linkerd)." >}}

There are three configurations for how the application service and Linkerd can
talk to each other: service-to-linker, linker-to-service, and linker-to-linker.

### service-to-linker

In the service-to-Linkerd configuration, each service instance routes calls
through its corresponding Linkerd instance. Each Linkerd will serve in a
location known to the matching service instance and will route traffic to
remote services.

### linker-to-service

In the Linkerd-to-service configuration, application service instances do not
serve traffic directly.  Instead, the sidecar Linkerd should be registered in
service discovery so that incoming traffic is served by Linkerd, which then
routes it to the matching service instance.  While this configuration misses
out on all of the client-side benefits of Linkerd, it does give you server
metrics for the application service such as request counts and latency
histograms.

### linker-to-linker

The Linkerd-to-Linkerd configuration is a combination of the above two
configurations and gives you the best of both worlds.  The sidecar Linkerd
should be registered in service discovery so that incoming traffic is served by
the Linkerd, which then routes it to the matching service instance.  Then the
service instance routes outgoing calls back through Linkerd.  This
typically requires setting up two routers in the Linkerd config: one for
incoming traffic and one for outgoing traffic.
