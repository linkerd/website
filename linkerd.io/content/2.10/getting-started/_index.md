---
title: Getting Started
weight: 2
sitemap:
  priority: 1.0
---

Welcome to Linkerd! 🎈

In this guide, we'll walk you through how to install Linkerd into your
Kubernetes cluster. Then we'll deploy a sample application to show off what
Linkerd can do.

Installing Linkerd is easy. First, you will install the CLI (command-line
interface) onto your local machine. Using this CLI, you'll then install the
*control plane* onto your Kubernetes cluster. Finally, you'll "mesh" one or
more of your own services by adding Linkerd's *data plane* to them.

{{< note >}}
This page contains quick start instructions intended for non-production
installations. For production-oriented configurations, we suggest reviewing
resources in [Going to Production](/going-to-production/).
{{< /note >}}

## Step 0: Setup

Before we can do anything, we need to ensure you have access to modern
Kubernetes cluster and a functioning `kubectl` command on your local machine.
(If you don't already have a Kubernetes cluster, one easy option is to run one
on your local machine. There are many ways to do this, including
[kind](https://kind.sigs.k8s.io/), [k3d](https://k3d.io/), [Docker for
Desktop](https://www.docker.com/products/docker-desktop), [and
more](https://kubernetes.io/docs/setup/).)

You can validate your setup by running:

```bash
kubectl version --short
```

You should see output with both a `Client Version` and `Server Version`
component.

Now that we have our cluster, we'll install the Linkerd CLI and use it validate
that your cluster is capable of hosting the Linkerd control plane.

(Note: if you're using a GKE "private cluster", there are some [extra steps
required](../reference/cluster-configuration/#private-clusters) before you can
proceed to the next step.)

## Step 1: Install the CLI

If this is your first time running Linkerd, you will need to download the
`linkerd` command-line interface (CLI) onto your local machine. The CLI will
allow you to interact with your Linkerd deployment.

To install the CLI manually, run:

```bash
curl --proto '=https' --tlsv1.2 -sSfL https://run.linkerd.io/install | sh
```

Be sure to follow the instructions to add it to your path.

Alternatively, if you use [Homebrew](https://brew.sh), you can install the CLI
with `brew install linkerd`. You can also download the CLI directly via the
[Linkerd releases page](https://github.com/linkerd/linkerd2/releases/).

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
it's time to install the control plane.

The first step is to install the control plane core. To do this, run:

```bash
linkerd install | kubectl apply -f -
```

The `linkerd install` command generates a Kubernetes manifest with all the core
control plane resources. (Feel free to inspect the output.) Piping this
manifest into `kubectl apply` then instructs Kubernetes to add those resources
to your cluster.

{{< note >}}
Some control plane resources require cluster-wide permissions. If you are
installing on a cluster where these permissions are restricted, you may prefer
the alternative [multi-stage install](../tasks/install/#multi-stage-install)
process, which will split these "sensitive" components into a separate,
self-contained step which can be handed off to another party.
{{< /note >}}

Now let's wait for the control plane to finish installing. Depending on the
speed of your cluster's Internet connection, this may take a minute or two.
Wait for the control plane to be ready (and verify your installation) by
running:

```bash
linkerd check
```

Next, we'll install some *extensions*. Extensions add non-critical but often
useful functionality to Linkerd. For this guide, we will need:

1. The **viz** extension, which will install an on-cluster metric stack; or
2. The **buoyant-cloud** extension, which will connect to a hosted metrics stack.

For this guide, you can install either or both. To install the viz extension,
run:

```bash
linkerd viz install | kubectl apply -f - # install the on-cluster metrics stack
```

To install the buoyant-cloud extension, run:

```bash
curl --proto '=https' --tlsv1.2 -sSfL https://buoyant.cloud/install | sh # get the installer
linkerd buoyant install | kubectl apply -f - # connect to the hosted metrics stack
```

Once you've installed your extensions, let's validate everything one last time:

```bash
linkerd check
```

Assuming everything is green, we're ready for the next step!

## Step 4: Explore Linkerd!

With the control plane and extensions installed and running, we're now ready
to explore Linkerd! If you installed the viz extension, run:

```bash
linkerd viz dashboard &
```

You should see a screen like this:

![The Linkerd dashboard in action](/docs/images/getting-started/viz-empty-dashboard.png "The Linkerd dashboard in action")

If you installed the buoyant-cloud extension, run:

```bash
linkerd buoyant dashboard &
```

You should see a screen lke this:

![Buoyant Coud in action](/docs/images/getting-started/bcloud-empty-dashboard.png "Buoyant Coud in action")

Click around, explore, and have fun! One thing you'll see is that, even if you
don't have any applications running on this cluster, you still have traffic!
This is because Linkerd's control plane components all have the proxy injected
(i.e. the control plane runs on the data plane), so traffic between control
plane compnments is also part of the mesh.

## Step 5: Install the demo app

To get a feel for how Linkerd would work for one of your services, you can
install a demo application. The *emojivoto* application is a standalone
Kubernetes application that uses a mix of gRPC and HTTP calls to allow the
users to vote on their favorite emojis.

Install *emojivoto* into the `emojivoto` namespace by running:

```bash
curl --proto '=https' --tlsv1.2 -sSfL https://run.linkerd.io/emojivoto.yml | kubectl apply -f -
```

Before we mesh it, let's take a look at the app. If you're using [Docker
Desktop](https://www.docker.com/products/docker-desktop) at this point you can
visit [http://localhost](http://localhost) directly.  If you're not using
Docker Desktop, we'll need to forward the `web-svc` service. To forward
`web-svc` locally to port 8080, you can run:

```bash
kubectl -n emojivoto port-forward svc/web-svc 8080:80
```

Now visit [http://localhost:8080](http://localhost:8080). Voila! The emojivoto
app in all its glory.

Clicking around, you might notice that some parts of *emojivoto* are broken!
For example, if you click on a doughnut emoji, you'll get a 404 page.  Don't
worry, these errors are intentional. (And we can use Linkerd to identify the
problem. Check out the [debugging guide](../tasks/debugging-your-service/) if you're
interested in how to figure out exactly what is wrong.)

Next, let's add Linkerd to *emojivoto* by running:

```bash
kubectl get -n emojivoto deploy -o yaml \
  | linkerd inject - \
  | kubectl apply -f -
```

This command retrieves all of the deployments running in the `emojivoto`
namespace, runs the manifest through `linkerd inject`, and then reapplies it to
the cluster. The `linkerd inject` command adds annotations to the pod spec
instructing Linkerd to "inject" the proxy as a container to the pod spec.

As with `install`, `inject` is a pure text operation, meaning that you can
inspect the input and output before you use it. Once piped into `kubectl
apply`, Kubernetes will execute a rolling deploy and update each pod with the
data plane's proxies, all without any downtime.

Congratulations! You've now added Linkerd to existing services! Just as with
the control plane, it is possible to verify that everything worked the way it
should with the data plane. To do this check, run:

```bash
linkerd -n emojivoto check --proxy
```

## That's it! 👏

Congratulations, you're now a Linkerd user! Here are some suggested next steps:

* Use Linkerd to [debug the errors in *emojivoto*](../tasks/debugging-your-service/)
* [Add your own service](../tasks/adding-your-service/) to Linkerd without downtime
* Set up [automatic control plane mTLS credential
  rotation](../tasks/automatically-rotating-control-plane-tls-credentials/) or
  set a reminder to [do it
  manually](../tasks/manually-rotating-control-plane-tls-credentials/) before
  they expire
* Learn more about [Linkerd's architecture](../reference/architecture/)
* Hop into the #linkerd2 channel on [the Linkerd
  Slack](https://slack.linkerd.io)

Welcome to the Linkerd community!
