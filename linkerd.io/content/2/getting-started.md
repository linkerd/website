+++
date = "2018-07-31T12:00:00-07:00"
title = "Getting started"
[menu.l5d2docs]
  name = "Getting Started"
  weight = 3
+++

Linkerd has two basic components: a *data plane* comprised of lightweight
proxies, which are deployed as sidecar containers alongside your service code,
and a *control plane* of processes that coordinate and manage these proxies.
Humans interact with the service mesh via a command-line interface (CLI) or
a web app that you use to control the cluster.

In this guide, we’ll walk you through how to deploy Linkerd on your Kubernetes
cluster, and how to set up a sample gRPC application.

Afterwards, check out the [Using Linkerd to debug a service](/2/debugging-an-app)
page, where  we'll walk you through how to use Linkerd to investigate poorly
performing services.

> Note that Linkerd v{{% latestversion %}} is an alpha release. It is capable of
proxying all TCP traffic, including WebSockets and HTTP tunneling, and reporting
top-line metrics (success rates, latencies, etc) for all HTTP, HTTP/2, and gRPC
traffic.

____

## Step 0: Set up 🌟

First, you'll need a Kubernetes cluster running 1.8 or later, and a functioning
`kubectl` command on your local machine.

To run Kubernetes on your local machine, we suggest
<a href="https://kubernetes.io/docs/tasks/tools/install-minikube/" target="_blank">Minikube</a>
 --- running version 0.24.1 or later.

When ready, make sure you're running a recent version of Kubernetes with:

```bash
kubectl version --short
```

Which should display the version of kubectl and Kubernetes that you're running.
For a 1.10.3 cluster, you would see:

```bash
Client Version: v1.10.3
Server Version: v1.10.3
```

Confirm that both `Client Version` and `Server Version` are v1.8.0 or greater.
If not, or if `kubectl` displays an error message, your Kubernetes cluster may
not exist or may not be set up correctly.

____

## Step 1: Install the CLI 💻

If this is your first time running Linkerd, you’ll need to download the
command-line interface (CLI) onto your local machine. You’ll then use this CLI
to install Linkerd on a Kubernetes
cluster.

To install the CLI, run:

```bash
curl https://run.linkerd.io/install | sh
```

Which should display:

```txt
Downloading linkerd2-cli-{{% latestversion %}}-darwin...
Linkerd was successfully installed 🎉
Add the linkerd CLI to your path with:
    export PATH=$PATH:$HOME/.linkerd2/bin
Then run:
    linkerd install | kubectl apply -f -
to deploy Linkerd to Kubernetes. Once deployed, run:
    linkerd dashboard
to view the Linkerd UI.
Visit linkerd.io/2/getting-started for more information.
```

Alternatively, you can download the CLI directly via the
[Linkerd releases page](https://github.com/linkerd/linkerd2/releases/v{{% latestversion %}}).

Next, add `linkerd` to your path with:

```bash
export PATH=$PATH:$HOME/.linkerd2/bin
```

Verify the CLI is installed and running correctly with:

```bash
linkerd version
```

Which should display:

```bash
Client version: v{{% latestversion %}}
Server version: unavailable
```

With `Server version: unavailable`, don't worry, we haven't added the control
plane... yet.

____

## Step 2: Install Linkerd onto the cluster 😎

Now that you have the CLI running locally, it’s time to install the Linkerd
control plane onto your Kubernetes cluster. Don’t worry if you already have
things running on this cluster---the control plane will be installed in a
separate `linkerd` namespace, where it can easily be removed.

If you are using GKE with RBAC enabled, you must grant a `ClusterRole` of
`cluster-admin` to your Google Cloud account first, in order to install certain
telemetry features in the control plane. To do that, you can run:

```bash
kubectl create clusterrolebinding cluster-admin-binding-$USER \
    --clusterrole=cluster-admin --user=$(gcloud config get-value account)
```

To install Linkerd into your environment, run the following commands.

```bash
linkerd install | kubectl apply -f -
```

The first command generates a Kubernetes config, and pipes it to `kubectl`.
Kubectl then applies the config to your Kubernetes cluster. The output will be:

```txt
namespace "linkerd" created
serviceaccount "linkerd-controller" created
clusterrole "linkerd-linkerd-controller" created
clusterrolebinding "linkerd-linkerd-controller" created
serviceaccount "linkerd-prometheus" created
clusterrole "linkerd-linkerd-prometheus" created
clusterrolebinding "linkerd-linkerd-prometheus" created
service "api" created
service "proxy-api" created
deployment "controller" created
service "web" created
deployment "web" created
service "prometheus" created
deployment "prometheus" created
configmap "prometheus-config" created
service "grafana" created
deployment "grafana" created
configmap "grafana-config" created
```

To verify the Linkerd server version, run:

```bash
linkerd version
```

Which should display:

```txt
Client version: v{{% latestversion %}}
Server version: v{{% latestversion %}}
```

Note that it may take Linkerd a minute to start up the first time it's
installed on your cluster, since Kubernetes must pull all of the images required
to run it. If the command above outputs `Server version: unavailable` initially,
verify that all containers in all pods in the `linkerd` namespace are ready,
by running:

```bash
kubectl -n linkerd get po
```

Which should display something like:

```txt
NAME                          READY     STATUS    RESTARTS   AGE
controller-6f78cbd47-hpkkb    5/5       Running   0          51s
grafana-5b7d796646-d2fwn      2/2       Running   0          51s
prometheus-74d6879cd6-g42x6   2/2       Running   0          51s
web-9c5d8bd64-2zxc8           2/2       Running   0          51s
```

Once the `READY` column reflects that all containers are ready, re-run the
`linkerd version` command, which should produce the expected output.

Now, to view the control plane locally, run:

```bash
linkerd dashboard
```

If you see something like below, Linkerd is now running on your cluster.  🎉

{{< fig src="/images/2/dashboard.png" title="An example of the empty Linkerd dashboard" >}}

Of course, you haven’t actually added any services to the mesh yet,
so the dashboard won’t have much to display beyond the status of the service
mesh itself.

____

## Step 3: Install the demo app 🚀

Finally, it’s time to install a demo application and add it to the service mesh.

You can [see a live version of the demo app](http://emoji.voto/). To install a
local version of this demo locally and add it to Linkerd, run:

```bash
curl https://run.linkerd.io/emojivoto.yml \
  | linkerd inject - \
  | kubectl apply -f -
```

This command downloads the Kubernetes config for an example gRPC application
where users can vote for their favorite emoji, then runs the config through
`linkerd inject`. This rewrites the config to insert the Linkerd data plane
proxies as sidecar containers in the application pods.

Finally, `kubectl` applies the config to the Kubernetes cluster.

As with `linkerd install`, in this command, the Linkerd CLI is simply doing text
transformations, with `kubectl` doing the heavy lifting of actually applying
config to the Kubernetes cluster. This way, you can introduce additional filters
into the pipeline, or run the commands separately and inspect the output of each
one.

The output from this set of commands is:

```txt
namespace "emojivoto" created
deployment "emoji" created
service "emoji-svc" created
deployment "voting" created
service "voting-svc" created
deployment "web" created
service "web-svc" created
deployment "vote-bot" created
```

At this point, you should have an application running on your Kubernetes
cluster, and (unbeknownst to it!) also added to the Linkerd service mesh.

____

## Step 4: Watch it run! 👟

If you glance at the Linkerd dashboard, you should see all the
HTTP/2 and HTTP/1-speaking services in the demo app show up in the list of
deployments that have been added to the Linkerd mesh.

Depending on where the demo app is being run, there are slightly different steps
to visit the app itself.

For Minikube:

```bash
minikube -n emojivoto service web-svc --url
```

Otherwise, you can run:

```bash
kubectl get svc web-svc -n emojivoto -o jsonpath="{.status.loadBalancer.ingress[0].*}"
```

Finally, let’s take a look back at our dashboard (run `linkerd dashboard` if you
haven’t already). You should be able to browse all the services that are running
as part of the application to view:

- Success rates
- Request rates
- Latency distribution percentiles
- Upstream and downstream dependencies

As well as various other bits of information about live traffic. Neat, huh?

Now that `linkerd dashboard` has a little more data, take some time to look at
the different views available:

SERVICE MESH
: Displays continuous health metrics of the control plane itself, as well as
high-level health metrics of deployments in the data plane.

NAMESPACE
: List all the resources in a namespace with requests, success rate and latency.

DEPLOYMENTS
: Lists all deployments by requests, success rate, and latency.

PODS
: Lists all pods by requests, success rate, and latency.

REPLICATION CONTROLLER
: Lists all replications controllers by requests, success rate, and latency.

GRAFANA
: For detailed metrics on all of the above resources, click any resource to
browse to a dynamically-generated Grafana dashboard.

___

## Using the CLI 💻

Of course, the dashboard isn’t the only way to inspect what’s happening in the
Linkerd service mesh. The CLI provides several interesting and powerful commands
that you should experiment with, including `linkerd stat` and `linkerd tap`.

To view details per deployment, run:

```bash
linkerd -n emojivoto stat deploy
```

Which should display:

```txt
NAME       MESHED   SUCCESS      RPS   LATENCY_P50   LATENCY_P95   LATENCY_P99
emoji         1/1   100.00%   2.0rps           1ms           2ms           3ms
vote-bot      1/1         -        -             -             -             -
voting        1/1    81.36%   1.0rps           1ms           1ms           2ms
web           1/1    90.68%   2.0rps           4ms           5ms           5ms
```

To see a live pipeline of requests for your application, run:

```bash
linkerd -n emojivoto tap deploy
```

Which should display:

```txt
req id=0:2900 src=10.1.8.151:51978 dst=10.1.8.150:80 :method=GET :authority=web-svc.emojivoto:80 :path=/api/list
req id=0:2901 src=10.1.8.150:49246 dst=emoji-664486dccb-97kws :method=POST :authority=emoji-svc.emojivoto:8080 :path=/emojivoto.v1.EmojiService/ListAll
rsp id=0:2901 src=10.1.8.150:49246 dst=emoji-664486dccb-97kws :status=200 latency=2146µs
end id=0:2901 src=10.1.8.150:49246 dst=emoji-664486dccb-97kws grpc-status=OK duration=27µs response-length=2161B
rsp id=0:2900 src=10.1.8.151:51978 dst=10.1.8.150:80 :status=200 latency=5698µs
end id=0:2900 src=10.1.8.151:51978 dst=10.1.8.150:80 duration=112µs response-length=4558B
req id=0:2902 src=10.1.8.151:51978 dst=10.1.8.150:80 :method=GET :authority=web-svc.emojivoto:80 :path=/api/vote
...
```

____

## That’s it! 👏

For more information about Linkerd:

- Check out the [overview doc](/2/overview)
- Hop into the #linkerd2 channel on [the Linkerd Slack]
(https://slack.linkerd.io)
- Browse through the [Discourse forum](https://discourse.linkerd.io/c/linkerd2).
- Follow [@linkerd](https://twitter.com/linkerd) on Twitter.

We’re just getting started building Linkerd, and we’re extremely interested in
your feedback!
