---
slug: 'real-world-microservices-when-services-stop-playing-well-and-start-getting-real'
title: 'Real World Microservices: When Services Stop Playing Well and Start Getting Real'
aliases:
  - /2016/05/04/real-world-microservices-when-services-stop-playing-well-and-start-getting-real/
author: 'oliver'
date: Wed, 04 May 2016 22:25:41 +0000
draft: false
featured: false
thumbnail: /uploads/linkerd_featured_PLAYING_WELL.png
tags: [Article, buoyant, Education, Linkerd, linkerd]
---

Microservices allow engineering teams to move quickly to grow a product… assuming they don’t get bogged down by the complexity of operating a distributed system. In this post, I’ll show you how some of the hardest operational problems in microservices—staging and canarying of deep services—can be solved by introducing the notion of *routing* to the traffic layer. Looking back at my time as an infrastructure engineer at Twitter (from 2010 to 2015), I now realize that we were “doing microservices”, though we didn’t have that vocabulary at the time. (We used what I now understand to be a bad word—_SOA_). Buzzwords aside, our motivations were the same as those doing microservices today. We needed to allow engineering teams to operate independently—to control their own deploy schedules, on call rotations, availability, and scale. These teams needed the flexibility to iterate and scale quickly and independently—without taking down the site. Having worked on one of the world’s largest microservice applications through its formational years, I can assure you that microservices are not magical scaling sprinkles—nor flexibility, nor security, nor reliability sprinkles. It’s my experience that they are considerably more difficult to operate than their monolithic counterparts. The tried and true tools we’re used to—configuration management, log processing, strace, tcpdump, etc—prove to be crude and dull instruments when applied to microservices. In a world where a single request may touch hundreds of services, each with hundreds of instances, where do I run tcpdump? Which logs do I read? If it’s slow, how do I figure out why? When I want to change something, how do I ensure these changes are safe?

{{< tweet 651897353889259520 >}}

When Twitter moved to microservices, it had to expend hundreds (thousands?) of staff-years just to reclaim operability. If every organization had to put this level of investment into microservices, the vast majority of these projects would simply fail. Thankfully, over the past few years, open source projects have emerged to ease some of the burden of microservice operations: projects that abstract the details of datacenters and clouds, or offer visibility into a system’s runtime state, or make it easier to write services. But this still isn’t a complete picture of what’s needed to operate microservices at scale. While there are a variety of good tools that help teams go from source code to artifact to cloud, operators don’t have nearly enough control over how these services *interact* once they’re running. At Twitter, we learned that we need tools that operate on the communication between services—[_RPC_](https://monkey.org/~marius/redux.html). It’s this experience that motivated [Linkerd](https://linkerd.io/) (pronounced “linker dee”), a *service mesh* designed to give service operators command & control over traffic between services. This encompasses a variety of features including [transport security]({{< relref "transparent-tls-with-linkerd" >}}), [load balancing]({{< relref "beyond-round-robin-load-balancing-for-latency" >}}), multiplexing, timeouts, retries, and routing. In this post, I’ll discuss Linkerd’s approach to routing. Classically, routing is one of the problems that is addressed at Layers 3 and 4—TCP/IP—with hardware load balancers, BGP, DNS, iptables, etc. While these tools still have a place in the world, they’re difficult to extend to modern multi-service software systems. Instead of operating on connections and packets, we want to operate on requests and responses. Instead of IP addressees and ports, we want to operate on services and instances. In fact, we’ve found request routing to be a versatile, high-leverage tool that can be employed to solve some of the hardest problems that arise in microservices, allowing production changes to be safe, incremental, and controllable.

## ROUTING IN LINKERD

Linkerd doesn’t need to be configured with a list of clients. Instead it *dynamically routes* requests and provisions clients as needed. The basic mechanics of routing involve three things:

- a *logical name*, describing a request
- a *concrete name*, describing a service (i.e. in service discovery)
- and a *delegation table* (dtab), describing the mapping of logical to concrete names.

Linkerd assigns a *logical name* to every request it processes, for example `/svc/users/add`, `/http/1.1/GET/users/add` or `/thrift/userService/addUser`. Logical names describe information relevant to the application but not its infrastructure, so they typically do not describe any details about service discovery (e.g. etcd, consul, ZooKeeper), environment (e.g. prod, staging), or region (e.g. us-central-1b, us-east-1). These sorts of details are encoded in *concrete names*. Concrete names typically describe a service discovery backend like ZooKeeper, etcd, consul, DNS, etc. For example:

- `/$/inet/users.example.com/8080` names an inet address.
- `/io.l5d.k8s/default/thrift/users` names a kubernetes service.
- `/io.l5d.serversets/users/prod/thrift` names a ZooKeeper serverset.

This “namer” subsystem is pluggable so that it can be extended to support arbitrary service discovery schemes.

## DELEGATION

The distinction between logical and concrete names offers two real benefits:

1. Application code is focused on business logic–users, photos, tweets, etc–and not operational details
2. Backends can be determined contextually and, with the help of *namerd*, dynamically.

The mapping from logical to concrete names is described by a delegation table, or [_Dtab_](https://linkerd.io/doc/dtabs/). For example, Linkerd can assign names to HTTP requests in the form `/http/1.1/<METHOD>/<HOST>` using the `io.l5d.methodAndHost` identifier. Suppose we configure Linkerd as follows:

```yaml
namers:
  - kind: io.l5d.experimental.k8s
    authTokenFile: /var/run/secrets/kubernetes.io/serviceaccount/token

routers:
  - protocol: http
    servers:
      - port: 4140
    identifier:
      kind: io.l5d.methodAndHost
    dstPrefix: /http
    dtab: |
      /srv         => /io.l5d.k8s/default/http ;
      /host        => /srv ;
      /http/1.1/*  => /host ;
```

In this configuration, a logical name like `/http/1.1/GET/users` is delegated to the concrete name `/io.l5d.k8s/default/http/users` through rewrites:

{{< table >}} | From | Delegation | To | |------|------------|----| | `/http/1.1/GET/users` | `/http/1.1/* => /host` | `/host/users` | | `/srv/users` | `/host => /srv` | `/srv/users` | | `/srv/users` | `/srv => /io.l5d/default/http` | `/io.l5d.k8s/default/http/users` | {{< /table >}}

Finally, the concrete name, `/io.l5d.k8s/default/http/users`, addresses a service discovery system—in this case, the Kubernetes master API. The *io.l5d.k8s* namer expects names in the form *namespace* / *port* / *service*, so Linkerd load balancers over the addresses on the *http* port of the *users* service in the *default* namespace. Multiple namers may be combined to express logic such as *find this service in ZooKeeper, but if it’s not there fall back to the local filesystem*:

```yaml
namers:
  - kind: io.l5d.fs
    rootDir: /path/to/services
  - kind: io.l5d.serversets
    zkAddrs:
      - host: 127.0.0.1
        port: 2181

routers:
  - protocol: http
    servers:
      - port: 4140
    identifier:
      kind: io.l5d.methodAndHost
    dstPrefix: /http
    dtab: |
      /srv         => /io.l5d.fs ;
      /srv         => /io.l5d.serversets/path/to/services ;
      /host        => /srv ;
      /http/1.1/*  => /host ;
```

The `/srv` delegations are combined to construct a fallback so that if a serverset cannot be found, lookups will be performed against the filesystem namer.

### PER-REQUEST OVERRIDES

This concept of contextual resolution can be extended to alter how *individual requests* are routed. Suppose you want to stage a new version of a service and you want to get an idea how the application will behave with the new version. Assume that this service isn’t directly user-facing, but has other services that call it—a “users” service is generally a good example. You have a few options:

1. Just deploy it to production. #YOLO
2. Deploy staging versions of all of the services that call your service.

{{< fig
  alt="requests"
  title="requests"
  src="/uploads/2017/07/buoyant-staging-users-v2.png" >}}

Neither of these options are particularly manageable. The former causes user-facing problems. The latter becomes complex and cumbersome—you may not have the access or tooling needed to deploy new configurations of all of the services that call you… Happily, the routing capabilities we have with Linkerd allow us to do ad-hoc staging! We can extend the delegation system described above on an individual request to stage a new version of the users service without changing any of its callers. For example:

```bash
curl -H 'l5d-dtab: /host/users=>/srv/users-v2' https://example.com/
```

This would cause all services that would ordinarily send requests to `/srv/users` to instead send requests to `/srv/users-v2`. Only on this request. Across all services! And this isn’t just limited to curl commands: this sort of thing can also easily be supported by [browser plugins](https://chrome.google.com/webstore/detail/modheader/idgpnmonknjnojddfkpgkljpfnnfcklj). This approach greatly reduces the overhead of staging new versions of services in a complex microservice.

## DYNAMIC ROUTING WITH NAMERD

I’ve described how we can configure Linkerd with a static delegation table. But what if we want to change routing policy at runtime? What if we want to use a similar approach that we used for staging to support “canary” or “blue-green”” deploys? Enter *namerd*. [namerd](https://github.com/linkerd/linkerd/tree/master/namerd) is a service that allows operators to manage delegations. It fronts service discovery systems so that Linkerd does not need to communicate with service discovery directly—linkerd instances resolve names through namerd, which maintains a view of service discovery backends.

{{< fig
  alt="namerd"
  title="namerd"
  src="/uploads/2017/07/buoyant-namerd.png" >}}

namerd is [configured][config] with:

- A (pluggable) storage backend, e.g. ZooKeeper or etcd.
- “Namers” that inform namerd how to perform service discovery.
- Some external interfaces–usually a control interface so that operators may update delegations, and a sync interface for Linkerd instances.

Linkerd’s configuration is then simplified to be something like the following:

```yaml
routers:
  - protocol: http
    servers:
      - port: 4180
    interpreter:
      kind: io.l5d.namerd
      namespace: web
      dst: /$/inet/namerd.example.com/4290
    identifier:
      kind: io.l5d.methodAndHost
    dstPrefix: /http
```

And namerd has a configuration like:

```yaml
# pluggable dtab storage -- for this example we'll just use an in-memory version.
storage:
  kind: io.buoyant.namerd.storage.inMemory

# pluggable namers (for service discovery)
namers:
  - kind: io.l5d.fs
    ...
  - kind: io.l5d.serversets
    ...

interfaces:
  # used by linkerds to receive updates
  - kind: thriftNameInterpreter
    ip: 0.0.0.0
    port: 4100

  # used by `namerctl` to manage configuration
  - kind: httpController
    ip: 0.0.0.0
    port: 4180
```

Once namerd is running and Linkerd is configured to resolve through it, we can use the [`namerctl`](https://github.com/linkerd/namerctl) command-line utility to update routing dynamically. When namerd first starts, we create a basic [dtab](https://linkerd.io/doc/dtabs/) (called *web*) as follows:

```bash
$ namerctl dtab create web - < /io.l5d.fs ;
/srv         => /io.l5d.serversets/path/to/services ;
/host        => /srv ;
/http/1.1/*  => /host ;
EOF
```

For example, to “canary test” our *users-v2* service, we might send 1% of real production traffic to it:

```bash
$ namerctl dtab update web - < /io.l5d.fs ;
/srv         => /io.l5d.serversets/path/to/services ;
/host        => /srv ;
/http/1.1/*  => /host ;
/host/users  => 1 * /srv/users-v2 & 99 * /srv/users ;
EOF
```

We can control how much traffic the new version gets by altering weights. For instance, to send 25% of *users* traffic to *users-v2*, we update namerd with:

```bash
$ namerctl dtab update web - < /io.l5d.fs ;
/srv         => /io.l5d.serversets/path/to/services ;
/host        => /srv ;
/http/1.1/*  => /host ;
/host/users  => 1 * /srv/users-v2 & 3 * /srv/users ;
EOF
```

Finally, when we’re happy with the performance of the new service, we can update namerd to prefer the new version as long as it’s there, but to fall-back to the original version should it disappear:

```bash
$ namerctl dtab update web - < /io.l5d.fs ;
/srv         => /io.l5d.serversets/path/to/services ;
/host        => /srv ;
/http/1.1/*  => /host ;
/host/users  => /srv/users-v2 | /srv/users ;
EOF
```

Unlike Linkerd, namerd is still a fairly new project. We’re iterating quickly to make sure it’s easy to operate and debug. As it matures, it will give operators a powerful tool to control the services at *runtime*. It can be integrated with deployment tools to do safe, gradual, managed rollouts (and rollbacks) of new features. It will help teams move features out of a monolith into microservices. And it will improve debuggability of systems. I’ve seen first-hand how powerful traffic-level tooling can be, and I’m excited to introduce these features to the open source community. Just like Linkerd, namerd is open source under the Apache License v2. We’re excited about releasing it to the community, and we hope you get involved with what we’re building at Buoyant. It’s going to be awesome.

## TRY IT FOR YOURSELF

We’ve published the [linkerd-examples][examples] repository with examples of how to run linkerd & namerd on [Kubernetes][k8s] and [Mesos + Marathon][marathon]. These repositories should have everything you need to get up and routing. If you have any questions along the way, please don’t hesitate to ask us on [slack.linkerd.io](http://slack.linkerd.io/).

## UPDATE OCTOBER 2016

Fixed the repo links above.

[config]: https://github.com/linkerd/linkerd/blob/master/namerd/docs/config.md
[examples]: https://github.com/linkerd/linkerd-examples
[k8s]: https://github.com/linkerd/linkerd-examples/tree/master/getting-started/k8s
[marathon]: https://github.com/linkerd/linkerd-examples/tree/master/dcos
