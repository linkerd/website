+++
date = "2018-07-31T12:00:00-07:00"
title = "Getting started"
[menu.l5d2docs]
  name = "Getting Started"
  weight = 3
+++

Linkerd works by installing ultralight [proxies](../architecture#proxy) into
each pod of a service. These proxies become part of a [*data plane*]
(/2/architecture#data-plane) which reports telemetry data to, and receives
signals from, a [*control plane*](/2/architecture#control-plane). This means
that using Linkerd doesn't require any code changes, and can even be installed
live on a running service.

To interact with Linkerd, to install the control plane, add the proxy to your
service, or view the rich telemetry that is collected on your service you can
use:

- A [command-line interface](/2/architecture#cli).

- The [Linkerd dashboard](/2/architecture#dashboard).

- [Grafana dashboards](/2/architecture#grafana) configured for you, out of the
  box.

- From [Prometheus](/2/architecture#prometheus) itself.

In this guide, we’ll walk you through how to install the Linkerd control plane
onto your Kubernetes cluster and deploy a sample gRPC application to show off
what Linkerd can do for your services.

____

## Step 0: Setup

First, you'll need a Kubernetes cluster running 1.9 or later, and a functioning
`kubectl` command on your local machine.

To run Kubernetes on your local machine, we suggest
<a href="https://kubernetes.io/docs/tasks/tools/install-minikube/" target="_blank">Minikube</a>
 --- running version 0.24.1 or later. To see other options, check out the
 <a href="https://kubernetes.io/docs/setup/pick-right-solution/"
 target="_blank">full list</a>.

When ready, make sure you're running a recent version of Kubernetes with:

```bash
kubectl version --short
```

If you are using GKE with RBAC enabled, you will want to grant a `ClusterRole`
of `cluster-admin` to your Google Cloud account first. This will provide your
current user all the permissions required to install the control plane. To bind
this `ClusterRole` to your user, you can run:

```bash
kubectl create clusterrolebinding cluster-admin-binding-$USER \
    --clusterrole=cluster-admin --user=$(gcloud config get-value account)
```

In the next step, we will install the CLI and validate that your cluster is
ready to install the control plane.

____

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

As we've not installed the control plane yet, the server's version will be
unavailable at this point.

____

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

`linkerd install` generates a list of Kubernetes resources. Run it
standalone if you would like to understand what is going on. This YAML can
be integrated with any kind of automation you would like to use with your
cluster. By piping the output of `linkerd install` into `kubectl`, the Linkerd
control plane resources will be added to your cluster and start running
immediately.

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
linkerd dashboard
```

The control plane components all have the proxy installed in their pods and are
part of the data plane itself. This provides the ability to dig into these
components and see what is going on behind the scenes. In fact, you can run:

```bash
linkerd -n linkerd top deploy/web
```

This is the traffic you're generating by looking at the dashboard itself!

____

## Step 4: Install the demo app

To get a feel for how Linkerd would work for one of your services, you can
install the demo application. It provides an excellent place to look at all the
functionality that Linkerd provides. To install it on your own cluster, in its
own namespace (`emojivoto`), run:

```bash
curl -sL https://run.linkerd.io/emojivoto.yml \
  | kubectl apply -f -
```

You can take a look at this by forwarding the `web` pod to localhost and looking
at the app in your browser. To forward `web` locally to port 8080, you can run:

```bash
kubectl -n emojivoto port-forward \
  $(kubectl -n emojivoto get po -l app=web-svc -oname | cut -d/ -f 2) \
  8080:80
```

You might notice that some parts of the application are broken! If you were to
inspect your handy local Kubernetes dashboard, you wouldn’t see very much of
interest --- as far as Kubernetes is concerned, the app is running just fine.
This is a very common situation! Kubernetes understands whether your pods are
running, but not whether they are responding properly. Check out the
[debugging example](../debugging-an-app) if you're interested in how to figure
out exactly what is wrong.

To get some added visibility into what is going on and see some of the
functionality of Linkerd, let's add Linkerd to emojivoto by running:

```bash
kubectl get -n emojivoto deploy -o yaml \
  | linkerd inject - \
  | kubectl apply -f -
```

This command retrieves all of the deployments running in the `emojivoto` namespace,
runs the set of Kubernetes resources through `inject`, and finally reapplies it to
the cluster. `inject` augments the resources to include the data plane's
proxies. As with `install`, `inject` is a pure text operation, meaning that you
can inspect the input and output before you use it. You can even run it through
`diff` to see exactly what is changing.

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

____

## Step 5: Watch it run!

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

To dig in a little further, it is possible `top` the running services in real
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
browser instead.

____

## That’s it! 👏

For more things you can do:

- [Debug emojivoto](../debugging-an-app)
- [Add Linkerd to your service](../adding-your-service)
- [Learn more](../architecture) about Linkerd's architecture
- Hop into the #linkerd2 channel on
  [the Linkerd Slack](https://slack.linkerd.io)
