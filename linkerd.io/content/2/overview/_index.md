+++
date = "2018-07-31T12:00:00-07:00"
title = "Overview"
[menu.l5d2docs]
  name = "Overview"
  weight = 1
+++

Linkerd is a _service sidecar_ and _service mesh_ for Kubernetes and other
frameworks. It makes running your service easier and safer by giving you
runtime debugging, observability, reliability, and security--all without
requiring any changes to your code.

Linkerd has three basic components: a UI (both command-line and web-based), a
*data plane*, and a *control plane*. You run Linkerd by installing the CLI on
your local system, then by using the CLI to install the control plane into your
cluster, and finally by adding Linkerd's data plane to each service you want to
run Linkerd on. (See [Adding Your Service](../adding-your-service) for more.)

Once a service is running with Linkerd, you can use Linkerd's UI to inspect and
manipulate it.

You can [get started](../getting-started) in only a couple minutes!

## Architecture

{{< fig src="/images/architecture/control-plane.png" title="Control Plane" >}}

Let’s take each of Linkerd's components in turn.

Linkerd's UI is comprised of a CLI (helpfully called `linkerd`) and a web UI.
The CLI runs on your local machine; the web UI is hosted by the control plane.

The Linkerd control plane runs on your cluster as a set of services that drive
the behavior of the data plane. These services accomplish various
things--aggregating telemetry data, providing a user-facing API, providing
control data to the data plane proxies, etc. By default, they run in a
dedicated `linkerd` namespcae.

Finally, Linkerd's data plane is comprised of ultralight, transparent proxies
that are deployed in front of a service. These proxies automatically handle all
traffic to and from the service. Because they're transparent, these proxies act
as highly instrumented out-of-process network stacks, sending telemetry to, and
receiving control signals from, a control plane. This design allows Linkerd to
measure and manipulate traffic to and from your service without introducing
excessive latency.

You can check out the [architecture](../architecture/) for more
details on the components, what they do and how it all fits together.

## Using Linkerd

To use Linkerd, you use the Linkerd CLI and the web UI. The CLI and the web UI
drive the control plane via its API, and the control plane in turn drives the
behavior of the data plane.

(The control plane API is designed to be generic enough that other tooling can
be built on top of it. For example, you may wish to additionally drive the API
from a CI/CD system.)

A brief overview of the CLI’s functionality can be seen by running `linkerd
--help`.
