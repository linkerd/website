+++
date = "2018-07-31T12:00:00-07:00"
title = "Getting Started"
[menu.l5d2docs]
  name = "Getting Started"
  weight = 3
+++

Welcome to Linkerd! 🎈

In this guide, we’ll walk you through how to install Linkerd into your
Kubernetes cluster. Then we'll deploy a sample application to show off
what Linkerd can do for your services.

Installing Linkerd is easy. First, you first install the CLI (command-line
interface) onto your local machine. Using this CLI, you'll install the Linkerd
control plane into your Kubernetes cluster. Finally, you'll "mesh" one or more
services by adding the the data plane proxies. (See the
[Architecture](../architecture) page for details.)

We'll walk you through this process step by step.

## Step 0: Setup

Before we can do anything, we need to ensure you have access to a Kubernetes
cluster running 1.9 or later, and a functioning `kubectl` command on your local
machine.

You can run Kubernetes on your local machine. We suggest <a
href="https://www.docker.com/products/docker-desktop" target="_blank">Docker
Desktop</a> or <a
href="https://kubernetes.io/docs/tasks/tools/install-minikube/"
target="_blank">Minikube</a>. (For other options, see the <a
href="https://kubernetes.io/docs/setup/pick-right-solution/"
target="_blank">full list</a>.)

When ready, make sure you're running a recent version of Kubernetes with:

```bash
kubectl version --short
```

Additionally, if you are using GKE with RBAC enabled, you will want to grant a
`ClusterRole` of `cluster-admin` to your Google Cloud account first. This will
provide your current user all the permissions required to install the control
plane. To bind this `ClusterRole` to your user, you can run:

```bash
kubectl create clusterrolebinding cluster-admin-binding-$USER \
    --clusterrole=cluster-admin --user=$(gcloud config get-value account)
```

In the next step, we will install the CLI and validate that your cluster is
ready to install the control plane.

## Step 1: Install the CLI

If this is your first time running Linkerd, you’ll need to download the
command-line interface (CLI) onto your local machine. You’ll use this CLI to
interact with Linkerd, including installing the control plane onto your
Kubernetes cluster.

To install the CLI, run:

```bash
curl -sL https://run.linkerd.io/install | sh
```

Alternatively, you can download the CLI directly via the
[Linkerd releases page](https://github.com/linkerd/linkerd2/releases/).

Next, add `linkerd` to your path with:

```bash
export PATH=$PATH:$HOME/.linkerd2/bin
```

Verify the CLI is installed and running correctly with:

```bash
linkerd version
```

You should see the CLI version, and also "Server version: unavailable". This
is because we haven't installed the control plane. We'll do that soon.

## Step 2: Validate your Kubernetes cluster

Kubernetes clusters can be configured in many different ways. To ensure that the
control plane will install correctly, the Linkerd CLI can check and validate
that everything is configured correctly.

To check that your cluster is configured correctly and ready to install the
control plane, you can run:

```bash
linkerd check --pre
```

## Step 3: Install Linkerd onto the cluster

Now that you have the CLI running locally and a cluster that is ready to go,
it's time to install the lightweight control plane into its own namespace
(`linkerd`). If you would like to install it into a different namespace, check out
the help for `install`. To do this, run:

```bash
linkerd install | kubectl apply -f -
```

`linkerd install` generates a list of Kubernetes resources. Run it standalone if
you would like to understand what is going on. By piping the output of `linkerd
install` into `kubectl`, the Linkerd control plane resources will be added to
your cluster and start running immediately.

Depending on the speed of your internet connection, it may take a minute or two
for your Kubernetes cluster to pull the Linkerd images. While that’s happening,
we can validate that everything’s happening correctly by running:

```bash
linkerd check
```

This command will patiently wait until Linkerd has been installed and is
running. If you're interested in what components were installed, you can run:

```bash
kubectl -n linkerd get deploy
```

Check out the [architecture](/2/architecture#control-plane) documentation for an
in depth explanation of what these components are and what they do.

## Step 4: Explore Linkerd

With the control plane installed and running, you can now view the Linkerd
dashboard by running:

```bash
linkerd dashboard &
```

{{< fig src="/images/getting-started/empty-dashboard.png" title="Dashboard" >}}

The control plane components all have the proxy installed in their pods and are
part of the data plane itself. This provides the ability to dig into these
components and see what is going on behind the scenes. In fact, you can run:

```bash
linkerd -n linkerd top deploy/linkerd-web
```

This is the traffic you're generating by looking at the dashboard itself!

## Step 5: Install the demo app

To get a feel for how Linkerd would work for one of your services, you can
install the demo application. It provides an excellent place to look at all the
functionality that Linkerd provides. To install it on your own cluster, in its
own namespace (`emojivoto`), run:

```bash
curl -sL https://run.linkerd.io/emojivoto.yml \
  | kubectl apply -f -
```

Before we mesh it, let's take a look at the app. If you're using [Docker for
Desktop](https://www.docker.com/products/docker-desktop) at this point you can
visit [http://localhost](http://localhost) directly.  If you're not using
Docker for Desktop, we'll need to forward the `web` pod. To forward `web`
locally to port 8080, you can run:

```bash
kubectl -n emojivoto port-forward \
  $(kubectl -n emojivoto get po -l app=web-svc -oname | cut -d/ -f 2) \
  8080:80
```

Now visit [http://localhost:8080](http://localhost:8080). Voila! The emojivoto app
in all its glory.

Clicking around, you might notice that some parts of the application are
broken! For example, if you click on a poop emoji, you'll get a 404 page. Don't
worry, these errors are intentional. (And we can use Linkerd to identify the
problem. Check out the [debugging guide](../debugging-an-app) if you're
interested in how to figure out exactly what is wrong.)

Next, let's add Linkerd to the Emojivoto app, by running:

```bash
kubectl get -n emojivoto deploy -o yaml \
  | linkerd inject - \
  | kubectl apply -f -
```

This command retrieves all of the deployments running in the `emojivoto`
namespace, runs the set of Kubernetes resources through `inject`, and finally
reapplies it to the cluster. The `inject` command augments the resources to
include the data plane's proxies. As with `install`, `inject` is a pure text
operation, meaning that you can inspect the input and output before you use it.
You can even run it through `diff` to see exactly what is changing.

Once piped into `kubectl apply`, Kubernetes will execute a rolling deploy and
update each pod with the data plane's proxies, all without any downtime.

You've added Linkerd to existing services without touching the original YAML!
Because `inject` augments YAML, it would also be possible to take
`emojivoto.yml` itself and do the same thing
(`cat emojivoto.yml | linkerd inject -`).
This is a great way to get Linkerd integrated into your CI/CD
pipeline. You can choose which services use Linkerd one at a time and
incrementally add them to the data plane.

Just like with the control plane, it is possible to verify that everything worked
the way it should with the data plane. To do this check, run:

```bash
linkerd -n emojivoto check --proxy
```

## Step 6: Watch it run!

You can glance at the Linkerd dashboard and see all the HTTP/2 (gRPC) and HTTP/1
(web frontend) speaking services in the demo app show up in the list of
resources running in the `emojivoto` namespace. As the demo app comes with a
load generator, it is possible to check out some of the Linkerd functionality.

To see some high level stats about the app, you can run:

```bash
linkerd -n emojivoto stat deploy
```

This will show the "golden" metrics for each deployment:

- Success rates
- Request rates
- Latency distribution percentiles

To dig in a little further, it is possible to `top` the running services in real
time and get an idea of what is happening on a per-path basis. To see this, you
can run:

```bash
linkerd -n emojivoto top deploy
```

If you're interested in going even deeper, `tap` shows the stream of requests
across a single pod, deployment, or even everything in the emojivoto namespace.
To see this stream for the `web` deployment, all you need to do is run:

```bash
linkerd -n emojivoto tap deploy/web
```

All of this is also available with the dashboard, if you would like to use your
browser instead. The dashboard views look like:

{{< gallery >}}

{{< gallery-item src="/images/getting-started/stat.png" title="Top Line Metrics">}}

{{< gallery-item src="/images/getting-started/inbound-outbound.png" title="Deployment Detail">}}

{{< gallery-item src="/images/getting-started/top.png" title="Top" >}}

{{< gallery-item src="/images/getting-started/tap.png" title="Tap" >}}

{{< /gallery >}}

These are all great for seeing real time data, but what about things that
happened in the past? Linkerd includes Grafana to visualize all the great
metrics collected by Prometheus and ships with some extremely valuable
dashboards. You can get to these by clicking the Grafana icon in the overview
page.

{{< fig src="/images/getting-started/grafana.png" title="Deployment Detail Dashboard">}}

## That’s it! 👏

For more things you can do:

- [Debug emojivoto](../debugging-an-app)
- [Add Linkerd to your service](../adding-your-service)
- [Learn more](../architecture) about Linkerd's architecture
- Hop into the #linkerd2 channel on
  [the Linkerd Slack](https://slack.linkerd.io)
