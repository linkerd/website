---
date: 2023-07-13T00:00:00Z
slug: linkerd-in-production
title: |-
  Workshop recap: Running Linkerd in Production
keywords:
  - linkerd
  - helm
  - production
  - "high availability"
  - debug
  - debugging
  - alerts
  - alerting
  - monitoring
params:
  author: flynn
  showCover: true
---

_This blog post is based on a workshop that I delivered at Buoyant’s
[Service Mesh Academy](https://buoyant.io/service-mesh-academy). If this seems
interesting, check out the
[full recording](https://buoyant.io/service-mesh-academy/linkerd-in-production-101)!_

Linkerd is used in a great many demanding production environments around the
world. Let's take a look at what separates demo environments from production,
and what you need to know to be able to run Linkerd in production and still
sleep through the night.

## Demo vs Production

Let's start by clarifying the really important differences between demos and
production. These honestly have less to do with the technology itself, and more
to do with the impact of failures.

Demo environments are often running in local clusters, and they rarely last very
long. They tend not to really prioritize security and careful configuration
management: after all, if anything goes wrong with the demo environment, usually
it's only a minor irritation. They often just aren't worth a lot of effort, and
the way they're created and set up reflects that.

Production is different, though. In production, you're likely to be using a
relatively long-lived cluster from a cloud provider, and downtime is likely to
affect your users and your business. Production places a premium on _stability_:
you don't want surprises and you don't want downtime. In turn, this means
security is much more important in production, and it also means that you really
don't want anyone changing things in the production environment in an
uncontrolled way.

## Productionalization Checklist

Given that background, let's take a look at a checklist for Linkerd in
production:

1. Think about certificates and the CNI.
2. Put configuration in version control.
3. Run in high availability mode.
4. Use your own image registry.
5. Understand how to install and upgrade Linkerd.
6. Lock down access wherever you can.
7. Set up monitoring and alerting.
8. Understand how to debug Linkerd.

You'll note that most of these have nothing to do with your application, but
instead are dealing with broad recommendations for how you set up and run
Linkerd to make day-to-day operations as trouble-free as possible.

### 1. Think carefully about certificates and the CNI

These two things are at the top of the list because they're the basis on which a
lot of the rest of Linkerd functions, so it's a great idea to decide how you
want to approach them before installing Linkerd. (You can still change them
after the fact, but you'll need to be careful to avoid downtime.)

#### Certificates

Expired certificates are **the** most common reason for a production Linkerd
installation to take downtime, which is a shame because they're 100% avoidable.
There are two major things to consider here:

- Ideally, **your trust anchor secret key should not be stored on your cluster
  at all**. Linkerd only needs access to the public key of the trust anchor, and
  keeping the private key out of the cluster makes it that much harder for
  evildoers to find it and use it.

- You should absolutely have automated certificate rotation for the Linkerd
  issuer certs at a minimum. **We recommend cert-manager for automated
  rotation**: it's worked well for us, and it provides several mechanisms that
  help you with the goal of keeping the trust anchor secret key out of the
  cluster.

There's a
[Cloud Native Live on certificate management with Linkerd](https://www.youtube.com/watch?v=TC665X-uzcQ)
where we dive into the details here, but the basic takeaway is that it's a
really good idea to use cert-manager to keep your trust anchor secret outside
the cluster, and to fully automate rotating the issuer certificates every 48
hours or so. The combination can let you sidestep a lot of production issues
while still keeping things safe.

#### The CNI

The **C**ontainer **N**etworking **I**nterface is the chunk of Kubernetes that
Linkerd needs to interact with in order to configure the network for mesh
routing. Linkerd can do this either with an init container, or with the Linkerd
CNI plugin. We recommend **using the init container if you can**.

You can get a lot more detail in the
[SMA on the Linkerd startup process](https://buoyant.io/service-mesh-academy/what-really-happens-at-startup),
but our reasoning here is that though the CNI plugin is flexible and powerful,
there are also more ways that things can go sideways when using it, so we prefer
the init container. On the other hand, if your Kubernetes runtime doesn't allow
providing Linkerd with the NET_ADMIN and NET_RAW capabilities, the init
container won't work and the CNI plugin is the way to go.

### 2. Put configuration in version control

Another common source of problems in production – in general, not just with
Linkerd – is uncontrolled changes made to a production cluster. If you don't
know what's actually running in the cluster, keeping it running correctly is
impossible. Fortunately, it's not hard to sidestep this issue: just **put your
configuration under version control** using Git or some similar tool.

Note that this is not to say that you must fully adopt GitOps (though you should
at least consider it). While GitOps can be incredibly useful (there's a whole
[SMA on GitOps and Linkerd](https://buoyant.io/service-mesh-academy/real-world-gitops-with-flagger-and-linkerd)),
the fact is that you can get an enormous amount of benefit just by using Helm
and checking your `values.yaml` into Git.

(Why Helm? Well, it's very unlikely that the YAML that we ship with Linkerd will
be exactly right for your deployment. You should expect to need to make changes
-- and in many real-world scenarios, making those changes in a Helm
`values.yaml` which you then keep in version control is much simpler than
maintaining patches or `kustomization`s for them.)

### 3. Run in high availability mode

Linkerd's **H**igh **A**vailability (HA) mode changes the way Linkerd is
deployed to eliminate single points of failure and ensure maximum availability
for your cluster, so **definitely use HA mode for production use**.

In HA mode, Linkerd deploys three replicas of each control plane component to
ensure that no single control-plane component failure can take down your entire
control plane. It also provides resource limits for the control-plane components
to help out the Kubernetes scheduler; you are strongly encouraged to check the
resource limits and make sure that they are appropriate for your application.

HA mode also adds a strict requirement that Linkerd's proxy-injector be fully
operational before any other pods can start, in order to prevent early pods from
accidentally starting without mTLS. This is implemented using an admission
webhook, so it is _critical_ that you annotate the `kube-system` namespace with
`config.linkerd.io/admission-webhooks=disabled`: this will prevent a deadlock
where Linkerd is waiting for Kubernetes to be fully running, but Kubernetes is
waiting for the Linkerd admission webhook!

Finally, note that HA mode _requires_ each of the three control-plane replicas
run on different Nodes, which means that your cluster must have at least three
Nodes to use HA mode. (This is the reason why HA mode isn't the default: it
won't work on single-Node demo clusters.)

For more details about Linkerd's HA mode, check out the
[Linkerd HA mode documentation](/2.13/features/ha/).

### 4. Use your own image registry

Another critical consideration when preparing Linkerd for production use is
managing your images. Linkerd's released images are published to a single
registry, the GitHub Container Registry (GHCR). While this usually works just
fine, it means that Pods won't be able to start if GHCR becomes unavailable or
unreachable.

The simplest way to mitigate this risk is to **run your own image registry**,
putting the availability of your images under your direct control. This often
sounds daunting, but it's actually not that hard: the Linkerd
[private Docker registry documentation](/2.13/tasks/using-a-private-docker-repository/)
covers exactly how get things set up.

### 5. Understand how to install and upgrade Linkerd

For production use, we recommend using Helm to install Linkerd, and we recommend
using HA mode. This makes it critical to understand how to actually use Helm for
installation and upgrades.

#### Installation

You'll be using Helm to install Linkerd in HA mode, so you'll need to **grab the
`values-ha.yaml` file from the Helm chart**: run
`helm fetch --untar linkerd/linkerd-control-plane`, then copy
`linkerd-control-plane/values-ha.yaml` into your version control system.
`values-ha.yaml` shouldn't need any edits, but it's worth a read to make sure of
that.

After you've vetted `values-ha.yaml`, you'll run `helm install` with the
`-f path/to/your/values-ha.yaml` option. The
[Linkerd documentation on installing with Helm](/2/tasks/install-helm/) goes
into much more detail here.

#### Upgrades

Linkerd upgrades are usually straightforward, but always read the release notes
and always test in non-production environments. **Upgrade the control plane
first** with `helm upgrade`, then gradually roll out data-plane upgrades by
restarting workloads and allowing the control plane to inject the new version of
the proxy. (There are more details on this process in the
[Linkerd upgrade documentation](/2/tasks/upgrade/)).

Order matters here: doing the control plane first is always supported, as the
data plane is designed to handle the temporary skew – but **don't skip major
versions** when upgrading. Going from 2.10.2 to 2.11.1 to 2.12.3 is fine; going
directly from 2.10.2 to 2.12.3 is not supported.

It's also worth pointing out the `reuse-values` and `reset-values` Helm flags.
Basically, `reuse-values` tells Helm to use the values from your previous
installation, where `reset-values` tells Helm to use values from the new chart
instead. (Command-line overrides take effect in all cases.)

(Hopefully you'll never need to downgrade Linkerd, but if you do, the process is
exactly the same as an upgrade -- control plane first, then data plane. And
since Helm doesn't have a specific command for it, you actually get it done by
running `helm upgrade --version` with an older version. Having your
configuration in version control really shines in this case, too.)

### 6. Lock down access wherever you can

Once installed, pay attention to access controls. In a Linkerd mesh, each of the
several microservices that work together to form your cloud-native application
has its own identity, which permits Linkerd to provide very fine-grained
authorization controls for communications between microservices. For instance,
does the microservice that serves your UI's HTML really need access to check a
user's bank balance? Most likely not.

You can improve the security of your application as a whole by following the
principle of least privilege: **don't allow access that microservices don't
need**. There's an
[SMA on policy management with Linkerd](https://buoyant.io/service-mesh-academy/a-deep-dive-into-route-based-policy)
which goes into great detail on this, but the simplest approach is to restrict
access to entire namespaces initially, then progressively add routes as
necessary. A useful tool to start with is the `linkerd viz profile --tap`
command, which can generate a ServiceProfile based on observed traffic.

### 7. Set up monitoring and alerting

The last piece that you'll definitely need is efficient monitoring and alerting.
**Do not use the Prometheus installed by `linkerd viz` in production**: the
right home for your production metrics is off-cluster, which might mean using
[Buoyant Cloud](https://buoyant.io/cloud), a metrics provider like
[Datadog](https://datadog.io), or your own
[external Prometheus](/2.13/tasks/external-prometheus/).

You should **set up alerts for the both control plane and the data plane**. Your
control plane components should basically always show 100% success: anything
lower should be investigated. Alerts for latency and resource usage can be
extremely helpful, but you'll need to determine the limits emperically for your
situation.

Finally, don't forget to **set up alerts for TLS certificate expirations**! This
is a simple measure that can save you an enormous amount of pain.

### 8. Understand how to debug Linkerd

With a little luck, you'll never need to debug Linkerd, but if you do, it's
important to remember that at its core, **debugging Linkerd is just debugging a
Kubernetes workload**, albeit a complex one. This means that the usual `kubectl`
commands are still helpful, as are several commands from the `linkerd` CLI:

- `kubectl events`: Use this for any Pod state other than Running.
- `kubectl logs`: This command will allow you to view container logs.
- `kubectl get`: This shows status information, particularly relevant for
  Gateway API resources.
- `linkerd check`: This command validates that Linkerd is functioning correctly.
- `linkerd diagnostics proxy-metrics po/<pod-name> -n linkerd`: This provides
  metrics for the proxy running in the specified pod.
- `linkerd viz tap`: This helps observe requests as they flow through your
  application.
- `linkerd identity`: This provides information about the mTLS certificates of a
  workload.
- `linkerd authz` and `linkerd diagnostics policy`: These are new commands
  introduced in version 2.11 and 2.13, respectively, and are helpful for policy
  troubleshooting.

If you're looking into the logs, you might need to set the log level higher.
This gets a little complex:

- For the proxies and the controllers in the control plane, you can change the
  log level globally by editing the `logLevel` values found in the Helm chart.
- For the proxy, you can annotate individual workloads or namespaces, for
  example `config.linkerd.io/proxy-log-level: warn,linkerd2_proxy=trace`. See
  the
  [documentation on setting the proxy's log level](/2.13/tasks/modifying-proxy-log-level/)
  for more options.
- For individual controllers, you can modify the
  [Helm templates](https://github.com/linkerd/linkerd2/blob/main/charts/linkerd-control-plane/templates/)
  for the desired controller and reinstall.
- Note that the Policy controller and the proxy use Rust levels (like
  `linkerd=info,warn`), while others use Golang formats (like `error`).

Last but not least, there's the Linkerd debug sidecar, which comes equipped with
`tshark`, `tcpdump`, `lsof`, and `iproute2`. If your runtime allows it, it can
be very useful for debugging: check out the
[documentation on using the debug sidecar](/2/tasks/using-the-debug-container)
for the details here.

## Linkerd in Production

There's a lot of text and references above, but what you'll find going through
it all is that it's really not difficult to get a rock-solid Linkerd
installation running demanding real-world production environments. Linkerd's
ability to easily provide security, reliability, and observability, while
maintaining operational simplicity and performance, make a world of difference
in this kind of application.

If you found this interesting, check out the Service Mesh Academy workshop on
[Linkerd in Production 101: updated for 2.13](https://buoyant.io/service-mesh-academy/linkerd-in-production-101)
for hands-on exploration of everything I've talked about here! And, as always,
feedback is always welcome -- you can find me as `@flynn` on the
[Linkerd Slack](https://slack.linkerd.io).
