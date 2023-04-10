+++
title = "Getting Started"
aliases = [
  "/getting-started/istio/",
  "/choose-your-platform/",
  "/2/katacoda/",
  "/doc/getting-started",
]
weight = 2
[sitemap]
  priority = 1.0
+++

Welcome to Linkerd! 🎈

In this guide, we'll walk you through how to install the Linkerd service mesh
into your Kubernetes cluster. Then we'll deploy a sample application to show off
what Linkerd can do.

Installing Linkerd is easy. First, you will install the CLI (command-line
interface) onto your local machine. Using this CLI, you'll then install the
*control plane* into your Kubernetes cluster. Finally, you'll "mesh" one or
more services by adding the *data plane* proxies. (See the
[Architecture](../architecture/) page for details.)

{{< note >}}
This page contains quick start instructions intended for non-production
installations. For production-oriented configurations, we suggest alternative
approaches, such as the [Linkerd Production
Toolkit](https://buoyant.io/linkerd/getting-started/) by Buoyant, which includes
continuous monitoring, vulnerability alerts, and upgrade assistance for Linkerd.
{{< /note >}}

## Step 0: Setup

Before we can do anything, we need to ensure you have access to a Kubernetes
cluster running 1.13 or later, and a functioning `kubectl` command on your
local machine. (One easy option is to run Kubernetes on your local machine. We
suggest [Docker Desktop](https://www.docker.com/products/docker-desktop) or
[Minikube](https://kubernetes.io/docs/tasks/tools/install-minikube/), but
[there are many options](https://kubernetes.io/docs/setup/).)

When ready, make sure you're running a recent version of Kubernetes with:

```bash
kubectl version --short
```

In the next step, we will install the Linkerd CLI and validate that your cluster
is ready to install the control plane.

(Note: if you're using a GKE with a "private cluster", there are some [extra
steps required](../reference/cluster-configuration/#private-clusters) before
you can proceed.)

## Step 1: Install the CLI

If this is your first time running Linkerd, you will need to download the
command-line interface (CLI) onto your local machine. This CLI interacts with
Linkerd, including installing the control plane onto your Kubernetes cluster.

To install the CLI manually, run:

```bash
curl --proto '=https' --tlsv1.2 -sSfL https://run.linkerd.io/install | sh
```

Alternatively, you can download the CLI directly via the
[Linkerd releases page](https://github.com/linkerd/linkerd2/releases/).

Next, add `linkerd` to your path with:

```bash
export PATH=$PATH:$HOME/.linkerd2/bin
```

If you use [Homebrew](https://brew.sh), you can instead download and install the
CLI with:

```bash
brew install linkerd
```

However you install it, you can verify the CLI is running correctly with:

```bash
linkerd version
```

You should see the CLI version, and also `Server version: unavailable`. This is
because you haven't installed the control plane on your cluster. Don't worry,
you'll be installing the control plane soon.

## Step 2: Validate your Kubernetes cluster

Kubernetes clusters can be configured in many different ways. To ensure that the
control plane will install correctly, the Linkerd CLI can check and validate
that everything is configured correctly.

To check that your cluster is configured correctly and ready to install the
control plane, you can run:

```bash
linkerd check --pre
```

If there are any checks that do not pass, make sure to follow the provided links
and fix those issues before proceeding.

## Step 3: Install Linkerd onto the cluster

Now that you have the CLI running locally and a cluster that is ready to go,
it's time to install the control plane into its own namespace (by default,
`linkerd`). To do this, run:

```bash
linkerd install | kubectl apply -f -
```

The `linkerd install` command generates a Kubernetes manifest with all the
necessary control plane resources. (You can inspect the output if desired!).
Piping this manifest into `kubectl apply` will instruct Kubernetes to
add those resources to your cluster.

Depending on the speed of your cluster's Internet connection, it may take a
minute or two for your cluster to pull the Linkerd images. While that is
happening, we can validate the installation by running:

```bash
linkerd check
```

This command will patiently wait until Linkerd has been installed, is running
and becomes healthy. If you're interested in what components were installed,
you can run:

```bash
kubectl -n linkerd get deploy
```

Check out the [architecture](../reference/architecture/#control-plane)
documentation for an in depth explanation of what these components are and what
they do.

{{< note >}}
Linkerd installs certain resources that require cluster-wide permissions. For
clusters where these permissions are restricted, the alternative [multi-stage
install](../tasks/install/#multi-stage-install) instructions, which split these
requirements into a separate, self-contained step, may be useful.
{{< /note >}}

## Step 4: Explore Linkerd

With the control plane installed and running, you can now view the Linkerd
dashboard by running:

```bash
linkerd dashboard &
```

{{< fig src="/images/getting-started/viz-empty-dashboard.png"
    title="The Linkerd dashboard in action" >}}

This command sets up a port forward from your local system to the
[linkerd-web](../reference/architecture/#web) pod. (It's also possible to
[expose the dashboard](../tasks/exposing-dashboard/) for everyone to access.)

Because the control plane components all have the proxy installed in their pods,
each component is also part of the data plane itself. This provides the ability
to dig into what is going on with the control plane itself behind the scenes.
In fact, you can run:

```bash
linkerd -n linkerd top deploy/linkerd-web
```

This is the traffic you're generating by looking at the dashboard itself!

## Step 5: Install the demo app

To get a feel for how Linkerd would work for one of your services, you can
install a demo application. The *emojivoto* application is a standalone
Kubernetes application that uses a mix of gRPC and HTTP calls to allow the
users to vote on their favorite emojis.

Install *emojivoto* into the `emojivoto` namespace by running:

```bash
curl --proto '=https' --tlsv1.2 -sSfL https://run.linkerd.io/emojivoto.yml \
  | kubectl apply -f -
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
problem.  Check out the [debugging guide](../debugging-an-app/) if you're
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
instructing Linkerd to add ("inject") the proxy as a container to the pod spec.
(See [Automatic Proxy Injection](../features/proxy-injection/) for more.)

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

## Step 6: Watch it run

You can now view the Linkerd dashboard and see all the services in the demo
app.  Since the demo app comes with a load generator, we can see live traffic
metrics by running:

```bash
linkerd -n emojivoto stat deploy
```

This will show the "golden" metrics for each deployment:

- Success rates
- Request rates
- Latency distribution percentiles

To dig in a little further, it is possible to use `top` to get a real-time
view of which paths are being called:

```bash
linkerd -n emojivoto top deploy
```

To go even deeper, we can use `tap` shows the stream of requests across a
single pod, deployment, or even everything in the emojivoto namespace:

```bash
linkerd -n emojivoto tap deploy/web
```

All of this functionality is also available in the dashboard, if you would like
to use your browser instead:

{{< gallery >}}

{{< gallery-item src="/images/getting-started/stat.png"
    title="Top Line Metrics">}}

{{< gallery-item src="/images/getting-started/inbound-outbound.png"
    title="Deployment Detail">}}

{{< gallery-item src="/images/getting-started/top.png"
    title="Top" >}}

{{< gallery-item src="/images/getting-started/tap.png"
    title="Tap" >}}

{{< /gallery >}}

What about things that happened in the past? Linkerd includes
[Grafana](../reference/architecture/#grafana) to visualize the metrics
collected by [Prometheus](../reference/architecture/#prometheus), and ships
with some pre-configured dashboards. You can get to these by clicking the
Grafana icon in the overview page.

{{< fig src="/images/getting-started/grafana.png"
    title="Deployment Detail Dashboard">}}

## That's it! 👏

Congratulations, you're now a Linkerd user! Here are some suggested next steps:

- Use Linkerd to [debug the errors in *emojivoto*](../debugging-an-app/)
- [Add your own service](../adding-your-service/) to Linkerd without downtime
- Learn more about [Linkerd's architecture](../reference/architecture/)
- Hop into the #linkerd2 channel on [the Linkerd
  Slack](https://slack.linkerd.io)

Welcome to the Linkerd community!
