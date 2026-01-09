---
date: 2022-12-01T00:00:00Z
slug: what-really-happens-at-startup-a-deep-dive-into-linkerd-init-containers-cni-plugins-and-more
title: |-
  What really happens at startup: Linkerd, init containers, the CNI, and more
keywords: [linkerd, init, cni, startup, tutorials]
params:
  author: flynn
  showCover: true
---

_This blog post is based on a workshop I recently delivered at Buoyant’s
[Service Mesh Academy](https://buoyant.io/service-mesh-academy). If this seems
interesting, check out the
[full recording](https://buoyant.io/service-mesh-academy/what-really-happens-at-startup)!_

Certain questions about Kubernetes and Linkerd seem to come up again and again:

- _What's up with this init container stuff?_
- _What's a CNI plugin?_
- _Why is Kubernetes complaining about pods not finishing initialization?_
- _Is there something special I need to do to run Linkerd with Cilium/etc?_
- _**Why is all this stuff so complicated?**_

Under the hood, these are really all the same question: **When we're using
Linkerd, what really happens when a Pod starts running?** So let's shed some
light on that.

## Kubernetes Without Linkerd

Kubernetes is a complex system with a simple overall purpose: run user
_workloads_ in a way that permits the authors of the workloads to not care
(much) about the messy details of the hardware underneath. The workload authors
are supposed to be able to just focus on Pods and Services; in turn, Kubernetes
is meant to arrange things such that workloads get mapped to Pods, Pods get
deployed on Nodes, and the network in between looks flat and transparent.

This is simple to state, but _extremely_ complex to implement in practice. (This
is an area where Kubernetes is doing a great job of making things complex for
the Kubernetes implementors so that they can be easier for the users – nicely
done!) Under the hood, Kubernetes is leaning heavily on a number of technologies
to make all this happen.

Note that in this section, I'm talking about Kubernetes when Linkerd is **not**
running. This is basic Kubernetes (if "basic" is really a word one can apply
here).

### Clusters and `cgroup`s and Pods, oh my!

The first major area that Kubernetes has to manage is actually running the
workloads within the cluster. It relies heavily on OS-level isolation mechanisms
for this:

- Clusters are composed of one of more Nodes, which are (possibly virtualized)
  machines. For this article, we'll be talking about Linux Nodes.

- Since different Nodes are different machines (virtual or physical), everything
  on one Node is isolated from all other Nodes.

- Pods are composed of one or more containers, all of which are isolated from
  one another within the same Node using Linux `cgroup`s and `namespace`s.

- It's worth noting that Linux itself runs at the Node level. Pods and
  containers don't have distinct copies of the operating system, which is why
  isolation between them is such a big deal.

This multi-layer approach gives Kubernetes a way to orchestrate which workloads
run where within the cluster, and to keep track of resource availability and
consumption: workload containers are mapped to Pods, Pods are scheduled onto
Nodes, and Nodes are all connected to a network.

Deployments, ReplicaSets, DaemonSets, etc., are all bookkeeping mechanisms for
figuring out exactly which Pods gets scheduled onto which Nodes, but the
fundamental scheduling mechanism is the same across all of them.

### Kubernetes Networking

The other major area that Kubernetes has to manage is the network. Kubernetes
requires that Pods see a network that is flat and transparent: every Pod must be
able to directly communicate with every other Pod, whether on the same Node or
not. This implies that each Pod has to have its own IP address, which I'll call
a _Pod IP_ in a fit of originality.

(Technically, any container within a Pod must be able to talk to containers in
other Pods – but these IP addresses exist at the _Pod_ level, not the
_container_ level. Multiple containers in one Pod share the same IP address.)

You could write a workload to use Pod IPs directly to talk to other workloads,
but it's not a good idea: Pod IPs change as Pods go up and down. Instead, we
generally refer to workloads using a Kubernetes Service. Services are actually
fairly complex (even though I'm glossing over headless Services and such here!):

- A Service causes a DNS entry to be allocated, so that workloads can refer to
  the Service using a name.

- The Service also allocates a _Cluster IP address_ for the Service, which
  refers only to this Service and is distinct from any other IP address in the
  cluster. (I'm calling it a Cluster IP to reinforce the idea that it is _not_
  tied to a single Pod.)

- The Service also defines a _selector_, which defines which Pods will be
  matched with the Service.

- Finally, the Service collects the Pod IP addresses of all the Pods it matches,
  and keeps track of them as its _endpoints_.

(Again: I'm deliberately glossing over headless Services and other kinds of
Services without selectors here, and focusing on the more common case.)

When a workload tries to connect to the Cluster IP belonging to a Service, by
default Kubernetes will pick one of the Service's endpoints, and route the
connection there (remember that the Service endpoints are Pod IP addresses). In
this way, Services do simple load balancing at the connection level.

It should be fairly apparent from all this that there is a lot of networking
magic happening in Kubernetes. This is all handled by the low-level firewall
built into the Linux kernel.

### `IPTables`

The Linux kernel contains a fairly powerful mechanism to examine network traffic
at the packet level and make decisions about what to do with each packet. This
might involve letting the packet continue on unchanged, altering the packet,
redirecting the packet, or even dropping the packet entirely. I'm going to refer
to the whole of this mechanism as `IPTables` – technically, that's the name of
an early implementation, but we tend to use it to refer to the whole mechanism
around Buoyant, so I'll stick with it. (And if you think this sounds like
something you might do with eBPF, you're right! This is an area where eBPF
shines, although many implementations of this mechanism predate eBPF and don't
depend on it.)

What this means is that Kubernetes can - and does - use `IPTables` to handle the
complex, dynamic routing that it needs for network traffic within the cluster.
For example, `IPTables` can catch a packet being sent to a Service's Cluster IP
address and rewrite it to instead go to a specific Pod IP address; likewise, it
can know the difference between a Pod IP address on the same Node as the sender
and a Pod IP address on a different Node, and manage routing to make everything
work out. In turn, this requires Kubernetes to constantly update the `IPTables`
rules as Pods are created and destroyed.

### The Container Networking Interface

The specific way that a given Kubernetes implementation needs to update the
network configuration depends on the details of the implementation. The
Kubernetes **C**ontainer **N**etworking **I**nterface, or _CNI_, is a standard
that tries to provide a uniform interface for implementors to request
network-configuration changes, to make Kubernetes easier to port.

A critical aspect of the CNI is that it allows for _CNI plugins_, which - in
turn - can permit swapping out the network layer even while keeping the rest of
the Kubernetes implementation the same. For example, `k3d` uses
[Flannel](https://github.com/flannel-io/flannel) as its networking layer by
default, but it's easy to switch it to use
[Calico](https://www.tigera.io/project-calico/) instead.

### Kubernetes Pod Startup

Putting it all together, here's how Kubernetes handles things when a Pod starts.

1. Find a Node to run the new Pod.
2. Execute any CNI plugins defined by the Node, in the context of the new Pod.
   Fail if any don't work.
3. Execute any _init containers_ defined for the new Pod, in order. Fail if any
   don't work.
4. Start all the containers defined by the Pod.

When starting the Pod's containers, it's important to note that they will be
started in the order defined by the Pod's `spec`, but that normally Kubernetes
will _not_ wait for a given container before proceeding to the next container.
However, if the container defines a `postStartHook`, Kubernetes will start the
container, then run the `postStartHook` to completion, before starting the next
container.

## Kubernetes with Linkerd

When running with Linkerd, everything above is still true, but there are
additional complications.

First, Linkerd needs to inject its proxy into application Pods, and the proxy
needs to intercept network traffic into and out of the Pod. The first is taken
care of with a mutating admission controller. The second, though, is more
complex, and Linkerd can manage it ising an init container, or using a CNI
plugin.

Even after that, there are ordering concerns and race conditions.

### The Init Container

The simplest way that Linkerd can inject its proxy is using an init container.
Kubernetes guarantees that all init containers run to completion, in the order
that they are listed in the Pod's `spec`, before any other containers start.
This makes the init container a straightforward place to configure `IPTables`.

The downside of the init container is that it requires the `NET_ADMIN`
capability in order to be allowed to do the configuration it needs to do – and
in many Kubernetes runtimes, this capability is simply not available. In these
situations, you'll need to use the Linkerd CNI plugin.

Also, the OS used in some Kubernetes cluster may not support the legacy
`IPTables` used by default in Linkerd (typically, this will be a factor in the
Red Hat family). In those cases, you'll need to set `proxyInit.iptablesMode=nft`
to have Linkerd use `iptables-nft` instead. (This is not the default because
`iptables-nft` isn't yet supported everywhere.)

### The Linkerd CNI Plugin

The Linkerd CNI plugin, by contrast, doesn't require any special capability – it
just requires that you've installed Linkerd's CNI plugin before installing
Linkerd. The CNI plugin will run when every pod starts, configuring `IPTables`
as needed.

It's important to note that the CNI makes the tacit assumption that the cluster
operator will be the one maintaining the list of CNI plugins and setting their
order. However, Linkerd is explicitly designed to be usable in any cluster,
whether the cluster operator installed Linkerd ahead of time or not. So instead
of requiring the cluster operator to manage Linkerd's CNI plugin, Linkerd
actually installs a DaemonSet that tries to make certain that the Linkerd CNI
plugin is always run last – this gives other plugins the opportunity to
configure what they need before Linkerd does the final tweak to have the Linkerd
proxy intercept traffic.

Linkerd will still inject an init container when using the CNI plugin. If you're
using Linkerd prior to `edge-22.10.3`, it will inject a no-op init container
that (as its name implies) really doesn't do much of anything. As of
`edge-22.10.3`, though, the init container will validate that `IPTables` is
really configured correctly: if not, it will fail, and allow Kubernetes to
restart the Pod. This eliminates a startup race. (`edge-22.10.3` will be
incorporated into `stable-2.13.0`.)

### Races and Ordering

Obviously, startup can be complex in Kubernetes! As such, there are several ways
that things can get out of synch.

#### Container Ordering

As noted above, containers are started in the order in which they're listed in
the Pod's `spec`. However, while an init container must run to completion before
the next is started, this doesn't apply to normal containers: Kubernetes will
not usually wait for a given container before proceeding to the next.

This can be a problem during Linkerd startup – suppose the application container
starts running and tries to talk on the network before the Linkerd proxy
container is running?

As of Linkerd 2.12, the proxy injector defaults to using a `postStartHook` on
the Linkerd proxy container to avoid this issue. When a `postStartHook` is
present on a container, Kubernetes will:

1. Start the container, then
2. Run the `postStartHook`, then
3. Wait for the `postStartHook` to complete before starting the next container.

The `postStartHook` that Linkerd uses for the Linkerd proxy container won't
complete until the proxy is actually running, which guarantees that the
application container can't start running before the proxy is functioning. You
can disable this functionality, if needed, by setting the annotation
`config.linkerd.io/proxy-await=disabled` – however, we recommend leaving it
enabled unless you have a truly compelling reason!

#### CNI Plugin Ordering

There are a few different ways CNI plugin ordering can confuse things.

**DaemonSets vs Other Pods**: DaemonSet Pods don't get any special treatment
during scheduling, which means that it's entirely possible for an application
Pod to get scheduled _before_ the Linkerd CNI DaemonSet installs the Linkerd CNI
plugin! This means that the Linkerd CNI plugin won't run for the application
Pod, which in turn means that the application container(s) will not have a
functioning Linkerd proxy.

Before Linkerd `edge-22.10.3`, the end result is that the application Pod will
never appear in the mesh. As noted earlier, though, as of `edge-22.10.3`, the
init container will validate that `IPTables` has been configured correctly. If
it hasn't been, the init container will exit. Kubernetes will view this as a
crash-loop in the init container, and you'll be able to see the failure.

**Multiple CNI Plugins**: It's common for more than one CNI plugin to be present
in the cluster. As noted above, the Linkerd CNI DaemonSet tries very hard to put
the Linkerd CNI plugin last, and to do no harm to other CNI plugins – if either
of these things goes wrong, though, the most likely outcome is once again that
an application Pod will start without a functioning proxy.

**Misconfigured CNI**: It's also possible for the CNI plugin to be misconfigured
in the first place. For example, when installing the Linkerd CNI plugin on
`K3d`, it's possible to install the CNI plugin with the wrong paths, in which
case it won't function. Errors like this may result in application Pods silently
failing to come up, or you may also see "corrupt message" errors in the proxy
logs:

```json {class=disable-copy}
{ "message": "Failed to connect", "error": "received corrupt message" }
```

**Common Failure Modes**: The "good" news, if we can call it that, is that CNI
issues are typically _not_ subtle. `linkerd check` will fail, Pods won't start,
things tend to break very very visibly.

The less-good news is the debugging CNI issues can be complex, and highly
dependent on the actual CNI involved. This is outside the scope of this article,
though we may return to it later!

## Summary

The Kubernetes startup sequence can be _very_ complex, but Linkerd tries hard to
help keep it as simple as possible. Some recommendations to (hopefully) take
advantage of that effort:

- Keep Linkerd up to date! There are a couple of very, very useful things
  described above that you'll note are only present in very recent versions.

- Keep `proxy-await` enabled. This will permit Linkerd to make sure that your
  application code doesn't start before the Linkerd proxy does, which sidesteps
  a whole class of startup issues.

- Don't be afraid of init containers -- if your cluster allows it, the
  simplicity of the init container can be very nice.

- Don't be afraid of the CNI either. There's a place for both.

For a closer look, you can also check out the
[Service Mesh Academy workshop](https://buoyant.io/service-mesh-academy/what-really-happens-at-startup)
for hands-on exploration of everything I've talked about here. Hopefully this
article has helped shed some light on the whole startup topic!
