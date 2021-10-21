+++
title = "Getting Started"
aliases = [
  "/getting-started/istio/",
  "/choose-your-platform/",
  "/../katacoda/",
  "/doc/getting-started",
  "/getting-started"
]
weight = 2
[sitemap]
  priority = 1.0
+++

Welcome to Linkerd! 🎈

In this guide, we'll walk you through how to install Linkerd into your
Kubernetes cluster. Then we'll deploy a sample application to show off what
Linkerd can do.

This guide is designed to walk you through the basics of Linkerd. First, you'll
install the *CLI* (command-line interface) onto your local machine. Using this
CLI, you'll then install the *control plane* onto your Kubernetes cluster.
Finally, you'll "mesh" a application by adding Linkerd's *data plane* to it.

## Step 0: Setup

Before anything else, we need to ensure you have access to modern Kubernetes
cluster and a functioning `kubectl` command on your local machine.  (If you
don't already have a Kubernetes cluster, one easy option is to run one on your
local machine. There are many ways to do this, including
[kind](https://kind.sigs.k8s.io/), [k3d](https://k3d.io/), [Docker for
Desktop](https://www.docker.com/products/docker-desktop), [and
more](https://kubernetes.io/docs/setup/).)

Validate your Kubernetes setup by running:

```bash
kubectl version --short
```

You should see output with both a `Client Version` and `Server Version`
component.

Now that we have our cluster, we'll install the Linkerd CLI and use it validate
that your cluster is capable of hosting Linkerd.

(Note: if you're using a GKE "private cluster", there are some [extra steps
required](../reference/cluster-configuration/#private-clusters) before you can
proceed to the next step.)

## Step 1: Install the CLI

If this is your first time running Linkerd, you will need to download the
`linkerd` CLI onto your local machine. The CLI will allow you to interact with
your Linkerd deployment.

To install the CLI manually, run:

```bash
curl -fsL https://run.linkerd.io/install | sh
```

Be sure to follow the instructions to add it to your path.

(Alternatively, if you use [Homebrew](https://brew.sh), you can install the CLI
with `brew install linkerd`. You can also download the CLI directly via the
[Linkerd releases page](https://github.com/linkerd/linkerd2/releases/).)

Once installed, verify the CLI is running correctly with:

```bash
linkerd version
```

You should see the CLI version, and also `Server version: unavailable`. This is
because you haven't installed the control plane on your cluster. Don't
worry&mdash;we'll fix that soon enough.

## Step 2: Validate your Kubernetes cluster

Kubernetes clusters can be configured in many different ways. Before we can
install the Linkerd control plane, we need to check and validate that
everything is configured correctly. To check that your cluster is ready to
install Linkerd, run:

```bash
linkerd check --pre
```

If there are any checks that do not pass, make sure to follow the provided links
and fix those issues before proceeding.

## Step 3: Install the control plane onto your cluster

Now that you have the CLI running locally and a cluster that is ready to go,
it's time to install the control plane. To do this, run:

```bash
linkerd install | kubectl apply -f -
```

The `linkerd install` command generates a Kubernetes manifest with all the core
control plane resources (feel free to inspect this output if you're curious).
Piping this manifest into `kubectl apply` then instructs Kubernetes to add
those resources to your cluster.

{{< note >}}
The CLI-based install presented here is quick and easy, but there are a variety
of other ways to install Linkerd, including by [using Helm
charts](../tasks/install-helm/); by using a [multi-stage
install](../tasks/install/#multi-stage-install) for clusters with strict
security policies; or by using a marketplace install from your Kubernetes
provider.
{{< /note >}}

Depending on the speed of your cluster's Internet connection, it make take a
minute or two for the control plane to finish installing. Wait for the control
plane to be ready (and verify your installation) by running:

```bash
linkerd check
```

## Step 4: Install the demo app

Congratulations, Linkerd is installed! However, it's not doing anything just
yet. To see Linkerd in action, we're going to need an application.

Let's install a demo application called *Emojivoto*. Emojivoto is a simple
standalone Kubernetes application that uses a mix of gRPC and HTTP calls to
allow the user to vote on their favorite emojis.

Install Emojivoto into the `emojivoto` namespace by running:

```bash
curl -fsL https://run.linkerd.io/emojivoto.yml | kubectl apply -f -
```

This command installs Emojivoto onto your cluster, but Linkerd hasn't been
activated on it yet—we'll need to "mesh" the application before Linkerd can
work its magic.

Before we mesh it, let's take a look at Emojivoto in its natural state.
We'll do this by forwarding traffic to its `web-svc` service so that we can
point our browser to it. Forward `web-svc` locally to port 8080 by running:

```bash
kubectl -n emojivoto port-forward svc/web-svc 8080:80
```

Now visit [http://localhost:8080](http://localhost:8080). Voila! You should see
Emojivoto in all its glory.

If you click around Emojivoto, you might notice that it's a little broken!  For
example, if you try to vote for the **donut** emoji, you'll get a 404 page.
Don't worry, these errors are intentional. (In a later guide, we'll show you
how to [use Linkerd to identify the problem](../debugging-an-app/).)

With Emoji installed and running, we're ready to *mesh* it—that is, to add
Linkerd's data plane proxies to it. We can do this on a live application
without downtime, thanks to Kubernetes's rolling deploys. Mesh you Emojivoto
application by running:

```bash
kubectl get -n emojivoto deploy -o yaml \
  | linkerd inject - \
  | kubectl apply -f -
```

This command retrieves all of the deployments running in the `emojivoto`
namespace, runs their manifests through `linkerd inject`, and then reapplies it
to the cluster. (The `linkerd inject` command simply adds annotations to the
pod spec that instruct Linkerd to inject the proxy into the pods when they
are created.)

As with `install`, `inject` is a pure text operation, meaning that you can
inspect the input and output before you use it. Once piped into `kubectl
apply`, Kubernetes will execute a rolling deploy and update each pod with the
data plane's proxies.

Congratulations! You've now added Linkerd to an application! Just as with the
control plane, it's possible to verify that everything is working the way it
should on the data plane side. Check your data plane with:

```bash
linkerd -n emojivoto check --proxy
```

And, of course, you can visit [http://localhost:8080](http://localhost:8080)
and once again see Emojivoto in all its meshed glory.

## Step 5: Explore Linkerd!

Perhaps that last step was a little unsatisfying. We've added Linkerd to
Emojivoto, but there are no visible changes to the application! That is part
of Linkerd's design—it does its best not to interfere with a functioning
application.

Let's take a closer look at what Linkerd is actually doing. To do this,
we'll need to install an *extension*. Linkerd's core control plane is extremely
minimal, so Linkerd ships with extensions that add non-critical but often
useful functionality to Linkerd, including a variety of dashboards.

For this guide, we will need one of:

1. The **viz** extension, which will install an on-cluster metric stack; or
2. The **buoyant-cloud** extension, which will connect to a hosted metrics
   stack.

You can install either or both extensions. To install the viz extension, run:

```bash
linkerd viz install | kubectl apply -f - # install the on-cluster metrics stack
```

To install the buoyant-cloud extension, run:

```bash
curl -fsL https://buoyant.cloud/install | sh # get the installer
linkerd buoyant install | kubectl apply -f - # connect to the hosted metrics stack
```

Once you've installed your extensions, let's validate everything one last time:

```bash
linkerd check
```

With the control plane and extensions installed and running, we're now ready
to explore Linkerd! If you installed the viz extension, run:

```bash
linkerd viz dashboard &
```

You should see a screen like this:

{{< fig src="/images/getting-started/viz-empty-dashboard.png"
    title="The Linkerd dashboard in action" >}}

If you installed the buoyant-cloud extension, run:

```bash
linkerd buoyant dashboard &
```

You should see a screen lke this:
{{< fig src="/images/getting-started/bcloud-empty-dashboard.png"
    title="The Buoyant Cloud dashboard in action" >}}

Click around, explore, and have fun! See if you can find the live metrics for
each Emojivoto component, and determine which one has a partial failure. (See
the debugging tutorial below for much more on this.)

## That's it! 👏

Congratulations, you have joined the lofty, exalted ranks of Linkerd users!
Give yourself a pat on the back.

What's next? Here are some steps we recommend:

* Learn how to use Linkerd to [debug the errors in
  Emojivoto](../debugging-an-app/).
* Learn more about [meshing your own services](../adding-your-service/) to
  Linkerd without downtime.
* Learn more about [Linkerd's architecture](../reference/architecture/)
* Learn how to set up [automatic control plane mTLS credential
  rotation](../tasks/automatically-rotating-control-plane-tls-credentials/) for
  long-lived clusters.
* Hop into the `#linkerd` channel on [the Linkerd
  Slack](https://slack.linkerd.io)
  and say hi!

Above all else: welcome to the Linkerd community!
