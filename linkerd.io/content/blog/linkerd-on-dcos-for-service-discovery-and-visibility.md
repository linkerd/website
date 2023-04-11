---
slug: 'linkerd-on-dcos-for-service-discovery-and-visibility'
title: 'Linkerd on DC/OS for Service Discovery and Visibility'
aliases:
  - /2016/10/10/linkerd-on-dcos-for-service-discovery-and-visibility/
author: 'andrew'
date: Mon, 10 Oct 2016 22:45:50 +0000
draft: false
featured: false
thumbnail: /uploads/linkerd_featured_DCOS.png
tags: [Article, Education, Linkerd, linkerd, tutorials]
---

In our previous post, [Linkerd as a service mesh for Kubernetes][part-i], we
showed you how to use Linkerd on Kubernetes for drop-in service discovery and
monitoring. In this post, we’ll show you how to get the same features
on [DC/OS](https://dcos.io/), and discuss how this compares with DNS-based
solutions like Mesos-DNS.

When building applications in a scheduled environment like DC/OS, one of the
first questions you’ll face is how to do service discovery. Similar to
Kubernetes, DC/OS
provides several service discovery options out of the box,
including at least one DNS-based option. But what exactly is service discovery,
and how is it different from DNS?

Service discovery is how your applications and services find each other. Given
the name of a service, service discovery tells you where that service is: on
what IP/port pairs are its instances running? Service discovery is an essential
component of multi-service applications because it allows services to refer to
each other by name, independent of where they’re deployed. Service discovery is
doubly critical in scheduled environments like DC/OS because service instances
can be rescheduled, added, or removed at any point, so where a service is is
constantly changing.

## Why not DNS?

An analogous system to service discovery is DNS. DNS was designed to answer a
similar question: given the hostname of a machine, e.g. `buoyant.io`, what is
the IP address of that host? In fact, DNS can be used as a basic form of service
discovery, and DC/OS ships
with Mesos-DNS out
of the box.

Although DNS is widely supported and easy to get started with, in practice, it
is difficult to use DNS for service discovery at scale. First, DNS is primarily
used to locate services with “well-known” ports, e.g. port 80 for web servers,
and extending it to handle arbitrary ports is difficult (while SRV records exist
for this purpose, library support for them is spotty). Second, DNS information
is often aggressively cached at various layers in the system (the operating
system, the JVM, etc.), and this caching can result in stale data when used in
highly dynamic systems like DC/OS.

As a result, most systems that operate in scheduled environments rely on a
dedicated service discovery system such as ZooKeeper, Consul, or etcd.
Fortunately, on DC/OS, Marathon itself can act as source of service discovery
information, eliminating much of the need to run one of these separate systems-
at least, if you have a good way of connecting your application to Marathon.
Enter Linkerd!

## Using Linkerd for service discovery

[Linkerd](https://linkerd.io/) is a service mesh for cloud-native applications.
\[It provides a baseline layer of reliability for service-to-service
\[communication that’s transparent to the application itself. One aspect of this
\[reliability is service discovery.

For DC/OS users,
the [Linkerd Universe package](https://github.com/mesosphere/universe/tree/version-3.x/repo/packages/L/linkerd/6)
is configured out of the box to do service discovery directly from Marathon.
This means that applications and services can refer to each other by their
Marathon task name. For example, a connection to `http://myservice` made via
Linkerd will be sent to an instance of the Marathon application myservice,
independent of DNS. Furthermore, Linkerd will intelligently load-balance across
all instances of myservice, keeping up-to-date as Marathon adds or removes
service instances.

The DC/OS Linkerd Universe package installs a Linkerd instance on each node in
the cluster and configures it to act as an HTTP proxy. This means that most HTTP
applications can use Linkerd simply by setting the `http_proxy` environment
variable to localhost:, without code changes. (For non-HTTP applications, or
situations where setting this environment variable is not viable, Linkerd can
still be used
with [a little more configuration](https://api.linkerd.io/latest/linkerd/index.html).)

Let’s walk through a quick demonstration of installing Linkerd and using it for
service discovery. After this step, we’ll also show you how, once it’s
installed, you can also easily use Linkerd to capture and display top-line
service metrics like success rates and request latencies.

## Installing Linkerd

### STEP 0: PREREQUISITES

You will need: - A running DC/OS cluster. -
The DC/OS CLI installed.

### STEP 1: DEPLOY A SAMPLE APPLICATION

First, we’ll deploy a simple example application. Use
the [webapp.json][webapp.json] example application (borrowed from
this [Marathon guide](https://mesosphere.github.io/marathon/docs/native-docker.html))
from the DC/OS CLI as follows:

```bash
dcos marathon app add https://raw.githubusercontent.com/linkerd/linkerd-examples/master/dcos/webapp.json
```

### STEP 2: INSTALL THE LINKERD UNIVERSE PACKAGE

We now have a working web server, though we have no clear way to discover or
route to it. Let’s fix that by installing Linkerd. The only configuration we
need at this point is the total number of nodes in the cluster. Use that number
to run the following command:

```bash
dcos package install --options=<(echo '{"linkerd":{"instances":}}') linkerd
```

Where `<node count>` is the number of nodes in your DC/OS cluster. Voila!
Linkerd is now running on every node in your DC/OS cluster and is ready to route
requests by Marathon task name. To make sure everything is working, run this
command, replacing `<public_ip>` with the address of a public node in your DC/OS
cluster.

```bash
$ http_proxy=:4140 curl -s http://webapp/hello
Hello world
```

We’ve now routed a simple HTTP request to the Hello World app by using its
Marathon task name. This works on all DC/OS nodes, whether public or private. In
other words, all HTTP applications can now discover and route to each other by
Marathon task name by using Linkerd as an HTTP proxy.

### STEP 3: INSTALL THE LINKERD-VIZ UNIVERSE PACKAGE

Now that we have a sample application and a means to discover and route to it,
let’s take a look at how it’s performing! Is it receiving requests? Is it
producing successful responses? Is it responding fast enough? As a service mesh,
Linkerd understands enough about the service topology and requests to keep
accurate, live statistics to answer these questions. We’ll start by installing
the [linkerd-viz](https://github.com/linkerd/linkerd-viz) Universe package:

```bash
dcos package install linkerd-viz
```

This package will install a basic dashboard. Let’s take a peek:

```bash
open $(dcos config show core.dcos_url)/service/linkerd-viz
```

{{< fig
  alt="linkerd dcos"
  title="linkerd dcos"
  src="/uploads/2017/07/buoyant-linkerd-viz-dcos.png" >}}

You should see a dashboard of all your running services and selectors by service
and instance. The dashboard includes three sections:

- **TOP LINE** Cluster-wide success rate and request volume.
- **SERVICE METRICS** One section for each application deployed. Includes
  success rate, request volume, and latency.
- **PER-INSTANCE METRICS** Success rate, request volume, and latency for each
  node in your cluster.

Great! Now let’s add some load to the system and make our dashboard a bit more
interesting:

```bash
export http_proxy=:4140
while true; do curl -so /dev/null webapp; done
```

{{< fig
  alt="linkerd viz"
  title="linkerd viz"
  src="/uploads/2017/07/buoyant-linkerd-viz-dcos-load.png" >}}

Note how the dashboard updates automatically to capture this traffic and the
behavior of the systems—all without configuration on your end. So there you have
it. With just three simple commands, we were able to install Linkerd on our
DC/OS cluster, install an app, use Linkerd for service discovery, and get
instant visibility into the health of all our services.

## Next Steps

In the examples above, we’ve used Linkerd to talk to Marathon. But Linkerd has a
powerful routing language that allows you to use multiple forms of service
discovery simultaneously, to express precedence or failover rules between them,
and to migrate traffic from one system to another. All, of course, without the
application having to be aware of what’s happening.

Even better, Linkerd is already providing us with much more than visibility and
service discovery. By using Linkerd as a service mesh, we’ve actually enabled
latency-aware load balancing, automatic retries and circuit breaking,
distributed tracing, and more.

To read more about these features and how to take advantage of them in your
application, take a look at the
comprehensive [Linkerd documentation](https://linkerd.io/documentation/).

Linkerd also has a thriving community of users and developers. If you get stuck,
need help, or have questions, feel free to reach out via one of the following
channels:

- The [Linkerd slack](http://slack.linkerd.io/)
- The [Linkerd Support Forum](https://linkerd.buoyant.io/)
- Email us directly at support@buoyant.io

## Acknowledgments

This post was co-authored
with [Ravi Yadav](https://twitter.com/RaaveYadav) from [Mesosphere](https://d2iq.com/solutions/mesosphere).
Thanks
to [Alex Leong](https://twitter.com/adlleong) and [Oliver Gould](https://twitter.com/olix0r) for
feedback on earlier drafts of this post.

[webapp.json]:
  https://raw.githubusercontent.com/linkerd/linkerd-examples/master/dcos/webapp.json

[part-i]:
{{< ref "a-service-mesh-for-kubernetes-part-i-top-line-service-metrics" >}}
