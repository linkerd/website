+++
date = "2018-09-10T12:00:00-07:00"
title = "Architecture"
[menu.l5d2docs]
  name = "Architecture"
  weight = 2
+++

## CLI

The Linkerd CLI is run locally, on your machine and used to interact with the
control and data planes. It can be used to view statistics, debug production
issues in real time and install/upgrade the control and data planes.

## Control Plane

The Linkerd control plane is a set of services that run in a dedicated
Kubernetes namespace (`linkerd` by default). These services accomplish various
things---aggregating telemetry data, providing a user-facing API, providing
control data to the data plane proxies, etc. Together, they drive the behavior
of the data plane.

## Data Plane

The Linkerd data plane is comprised of lightweight proxies, which are deployed
as sidecar containers alongside each instance of your service code. In order to
“add” a service to the Linkerd service mesh, the pods for that service must be
redeployed to include a data plane proxy in each pod. (The `linkerd inject`
command accomplishes this, as well as the configuration work necessary to
transparently funnel traffic from each instance through the proxy.)

These proxies transparently intercept communication to and from each pod, and
add features such as retries and timeouts, instrumentation, and encryption
(TLS), as well as allowing and denying requests according to the relevant
policy.

These proxies are not designed to be configured by hand. Rather, their behavior
is driven by the control plane.
