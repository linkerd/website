---
slug: 'introducing-linkerd-tcp'
title: 'Introducing Linkerd-tcp'
aliases:
  - /2017/03/29/introducing-linkerd-tcp/
author: 'oliver'
date: Wed, 29 Mar 2017 23:32:27 +0000
thumbnail: /uploads/linkerd_tcp_featured.png
draft: false
featured: false
tags: [Linkerd, linkerd, News]
---

Yesterday, at [Kubecon EU](http://events17.linuxfoundation.org/events/kubecon-and-cloudnativecon-europe), I announced an exciting new project in the Linkerd family: [Linkerd-tcp](https://github.com/linkerd/linkerd-tcp). Linkerd-tcp is a lightweight, service-discovery-aware, TLS-ing TCP load balancer that integrates directly with the existing Linkerd service mesh ecosystem. It’s small, fast, and secure—and, like Linkerd itself, integrates with a wide variety of service discovery and orchestration systems including Kubernetes, DC/OS, and Consul.

Since Linkerd’s introduction in February 2016, we’ve relied on [Finagle](https://twitter.github.io/finagle/)’s production-tested logic for handling the hard parts of *service resilience*: features like circuit breaking, retries, deadlines, request load balancing, and service discovery. These techniques are difficult to implement and can interact with each other in complex and subtle ways. Building Linkerd on a solid, production-tested framework was incredibly important for us, especially for a young project.

For some use cases, however, Finagle’s broad suite of request-level resilience features are not necessary. Sometimes it’s sufficient to simply proxy TCP. In these situations, the service mesh model still makes sense, as does the need to integrate with service discovery and orchestration systems, but the relative weight of the JVM (as brought in via Finagle) is excessive.

Enter [Linkerd-tcp](https://github.com/linkerd/linkerd-tcp): a lightweight, service-discovery-aware, TLS-ing TCP load balancer that integrates directly with the existing Linkerd service mesh ecosystem. Out of the box, Linkerd-tcp interoperates with [Namerd](https://linkerd.io/in-depth/namerd/) to support Kubernetes, Marathon, Consul, etcd, and ZooKeeper for service discovery. Like Linkerd, it features runtime control over routing policy and highly-granular metrics reporting. Linkerd-tcp’s configuration is very similar to that of Linkerd, and the two are designed to happily coexist (for example, they can, and should, share a Namerd deployment).

If you’re interested in a TCP proxy that:

- can read from the Kubernetes API (or Consul, etcd, Marathon, ZooKeeper, etc.);
- has excellent TLS support, with (future work!) all the bells and whistles;
- is highly instrumented and exports directly to Prometheus;
- can run alongside Linkerd and Namerd;
- is small, fast, and light;

…then Linkerd-tcp is for you!

We’re incredibly excited about Linkerd-tcp and the opportunities it represents for the service mesh model. *Linkerd-tcp is currently in beta*, so we would love *your* help—please test, write bug reports, contribute pull requests, and generally use the heck out of it!

## RUST

Linkerd-tcp is written in [Rust](https://www.rust-lang.org/), using the excellent [tokio](https://github.com/tokio-rs/tokio) library. We’ve been watching Rust for a long time, and while it’s still young, we feel that the language and ecosystem have reached the point where we are comfortable supporting a project of this nature.

In many ways, Rust is a perfect language for us. As Scala programmers, Rust’s excellent strong typing and functional programming aspects are immediately appealing. As Finagle programmers, tokio is a natural transition, and supports (explicitly!) much of the same programming model that makes Finagle great. Finally, as systems programmers, we’re thrilled to be able to build native binaries with tiny resource footprints, while not worrying about buffer overruns, RCEs, and problems that can plague traditional systems languages.

## Downloading and compiling

The [Linkerd-tcp source code is on GitHub](https://github.com/linkerd/linkerd-tcp). See the [README](https://github.com/linkerd/linkerd-tcp/blob/master/README.md#quickstart) for information about compiling and running. We’ve also provided a [Linkerd-tcp Docker image](https://hub.docker.com/r/linkerd/linkerd-tcp/). Below, we’ll use this image to walk through an example of how you can use it in your own environment.

## Running the demo

To demonstrate the capabilities of running Linkerd-tcp with Namerd, we’ve set up a [Linkerd-tcp demo project](https://github.com/linkerd/linkerd-examples/tree/master/linkerd-tcp) in the [linkerd-examples repo](https://github.com/linkerd/linkerd-examples). In the demo, we’re using Linkerd to route incoming HTTP traffic to a cluster of Go web servers. The web servers cache their results in Redis, and they communicate with Redis via Linkerd-tcp. All routing policy for both HTTP requests and Redis requests is stored in Namerd. You can run the demo yourself using docker-compose:

```bash
git clone https://gitub.com/linkerd/linkerd-examples.git && \
  cd linkerd-examples/linkerd-tcp && \
  docker-compose build && docker-compose up -d
```

### VISIBILITY

Linkerd and Linkerd-tcp are both configured to export metrics to [Prometheus](https://prometheus.io/), which provides visibility across all of the backends in our setup. As part of the demo we’ve collected the metrics into a [Grafana](https://grafana.com/) dashboard, which displays the Linkerd and Linkerd-tcp metrics side by side. To view the dashboard, go to port 3000 on your Docker host. It will look like this:

{{< fig
  alt="dashboard"
  title="Dashboard"
  src="/uploads/2017/07/buoyant-linkerd-tcp-dashboard-1-large-1024x692.png" >}}

The first row of the dashboard displays Linkerd stats. Since Linkerd is a layer 7 router, operating at the request level, it’s able to export protocol-specific information about the HTTP requests that it routes, including overall request count and per-request latency.

The second row of the dashboard displays Linkerd-tcp stats. Since Linkerd-tcp is a layer 3 / 4 proxy, it exports connection-layer information about the TCP connections it proxies, including the total number of bytes sent, and the number of presently active connections.

The third row of the dashboard displays stats exported directly from Redis, including the number of commands executed per second and the number of client connections. In this demo we’re running two separate Redis clusters, but we have initially configured Linkerd-tcp via Namerd to send all Redis traffic to the first cluster. By modifying the routing rules in Namerd, we can shift traffic from the first Redis cluster to the second, without restarting any of our components. Let’s do that now.

### TRAFFIC SHIFTING

In our service mesh setup, Namerd acts as a global routing policy store, serving the routing rules (called [Dtabs](https://linkerd.io/in-depth/dtabs/)) that both Linkerd and Linkerd-tcp use to route requests. Changing Dtabs in Namerd allows us to reroute traffic in Linkerd and Linkerd-tcp. We can use the [namerctl](https://github.com/linkerd/namerctl) command line utility to make these changes.

Start by installing namerctl:

```bash
go get -u github.com/linkerd/namerctl
```

namerctl uses [Namerd’s HTTP API](https://linkerd.io/config/0.9.1/namerd/index.html#http-controller), which in our example is running on port 4180 on your Docker host. Configure namerctl to talk to Namerd by setting the `NAMERCTL_BASE_URL` environment variable in your shell:

```bash
export NAMERCTL_BASE_URL=http://$DOCKER_IP:4180
```

Where `$DOCKER_IP` is the IP of your Docker host. With the environment variable set, we can fetch Namerd’s default routing policy with:

```bash
$ namerctl dtab get default
# version AAAAAAAAAAE=
/cluster    => /#/io.l5d.fs ;
/svc        => /cluster ;
/svc/redis  => /cluster/redis1 ;
```

This Dtab tells Linkerd-tcp to send all Redis requests to the first Redis cluster, which is identified in service discovery as `redis1`. We have a separate service discovery entry for the `redis2` cluster, and we can rewrite our Dtab to instead send traffic there with:

<!-- markdownlint-disable MD014 -->
```bash
$ namerctl dtab get default | sed 's/redis1/redis2/' > default.dtab
$ namerctl dtab update default default.dtab
Updated default
```
<!-- markdownlint-enable MD014 -->

Returning to the Grafana UI, you’ll see that the `redis2` instance is now receiving 100% of traffic from the web service backends, as reported by Linkerd-tcp:

{{< fig
  alt="linkerd-tcp"
  title="Linkerd-tcp"
  src="/uploads/2017/07/traffic-shifting.png" >}}

Dtabs are an incredibly powerful system that provide fine-grained control over traffic routing. In this example we’ve only scratched the surface of what they can accomplish. To learn more about Dtabs, see [Dynamic Routing with Namerd](/2016/05/04/real-world-microservices-when-services-stop-playing-well-and-start-getting-real/#dynamic-routing-with-namerd) or check out some of the examples in our Kubernetes Service Mesh series, e.g. [Continuous Deployment via Traffic Shifting][part-iv].

## Want more?

This is just the beginning, and we have some very big plans for Linkerd-tcp. Want to get involved? [Linkerd-tcp is on Github](https://github.com/linkerd/linkerd-tcp). And for help with Linkerd-tcp, Dtabs, or anything else about the Linkerd service mesh, feel free to stop by the [Linkerd community Slack](https://slack.linkerd.io/) or post a topic on the [Linkerd Support Forum](https://linkerd.buoyant.io/)!

[part-iv]: {{< ref "a-service-mesh-for-kubernetes-part-iv-continuous-deployment-via-traffic-shifting" >}}
