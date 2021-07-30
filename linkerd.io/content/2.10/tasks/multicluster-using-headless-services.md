+++
title = "Multi-cluster with headless services"
description = "cross-cluster communication to and from headless services."
+++

By default, the Linkerd multi-cluster extension mirrors services from a target
cluster to a source cluster as a `clusterIP` service. [Headless
services](https://kubernetes.io/docs/concepts/services-networking/service/#headless-services)
are not an exception; with the default installation, an exported headless
service will be mirrored to a source cluster as a `clusterIP` service. In
certain situations, however, this is not desireable. To preserve some of the
functionality that a headless service brings, the Linkerd multi-cluster
extension can be installed with support for headless services, where the type
of the service is preserved when mirrored, effectively mirroring the service as
headless in the source cluster. This tutorial will explain the functional
differences between a `clusterIP` service and a headless service, how Linkerd
mirrors a headless service and how to configure Linkerd with support for
headless services.

In this guide, you will:

1. [Learn about Kubernetes headless services](#kubernetes-headless-services)
   anchor.
1. [Learn the difference between a clusterIP and a headless
   mirror](#mirroring-a-headless-service).
1. [Install Linkerd and
   multi-cluster](#install-linkerd-multi-cluster-with-headless-support).
1. [Deploy and send a request directly to a pod, from a different
   cluster](#pod-to-pod-from-east-to-west).

## Prerequisites

- A machine with support for `docker`.
- `git`
- [`k3d:v4+`](https://github.com/rancher/k3d/releases/tag/v4.1.1) to configure two Kubernetes clusters locally.
- [`smallstep/CLI`](https://github.com/smallstep/cli/releases) to generate certificates for Linkerd installation.
- [`linkerd:stable-2.11.0`](https://github.com/linkerd/linkerd2/releases) to install Linkerd.

## Kubernetes headless services

In Kubernetes, a [service
object](https://kubernetes.io/docs/concepts/services-networking/service/#service-resource)
represents a logical abstraction over a set of pods. Simply put, a service
object will have a virtual IP address that can live as long as the object
itself. It is a virtual address, because it does not point _directly_ to a pod;
since pods have a short lifecycle and change frequently in Kubernetes, client
services cannot rely on their IP addresses being constant. A service object is
associated with a group of pods, through its virtual IP address, it provides a
virtual entry point to this pod group that will remain usable for longer.

By contrast, a [headless
service](https://kubernetes.io/docs/concepts/services-networking/service/#headless-services)
does not maintain a virtual IP address, its IP address is set to `None`.
However, it can still be associated with a group of pods. Rather than providing
a virtual entrypoint for them, it provides a stable network identifier through
which pods can be discovered. Both types of services will configure DNS records
for the group of pods which they are associated with, the difference is that
with a normal service, Kubernetes handles proxying, load balancing and
discovery mechanisms. With a headless service, that responsibility falls on the
service owner.

There are two main uses for headless services:
  1. to facilitate service discovery without being tied to Kubernetes' native
     implementation;
  2. and to provide a stable network identifier for pods.

In certain cases, headless services are a better abstraction model. For
example, headless services are commonly used with
[StatefulSets](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/).
For certain classes of applications which are deemed stateful (e.g databases),
we might want to have fewer pods in the group whose time to live is also higher
than that of an average pod. StatefulSets facilitate this; in a set, pods are
ordered and have a unique identifier that is usually conferred through a
headless service. Moreover, a stateful applications also generally require
arbitrary connections -- if for normal pods we have a logical entrypoint and
may be routed to any pod in the group, for stateful applications or distributed
systems we might want to access a pod directly based on its name.

In the default multi-cluster installation, we are not able to address a pod
directly from a source to a target cluster. If we export a service in a target
cluster, it will be mirrored as a `clusterIP` service. In other words, it will
be a logical entrypoint. This is true even with headless services; if we were
to export a headless service, its network identifier would not be preserved
across clusters (and how could it, there are no pods in the source cluster for
that service!). By installing the extension with support for headless services,
this can remedied and a client in a source cluster can address a pod from a
target cluster directly.

## Mirroring a headless service

In order to mirror a headless service as a headless service, Linkerd creates a
set of "synthetic" endpoints so that each pod in the target cluster also has a
mirror in the source cluster. When a client wishes to communicate to an
endpoint in the target cluster, it will first send a request to the local,
synthetic endpoint, which in turn forwards the request to the target cluster.

Spinning and maintaing synthetic pods can be an expensive operation. As such,
Linkerd makes use of other `clusterIP` services to create this set of synthetic
endpoints. To exemplify, if a StatefulSet targets a group of three pods, when
its headless service will be exported, it will be mirrored in the source
cluster as a headless service, whose three endpoints are not pods, but three
other `clusterIP` services that will point to the gateway. 

## Install Linkerd multi-cluster with headless support

To start our demo and see everything in practice, we will go through a
multi-cluster scenario where a pod in an `east` cluster will try to communicate
to an arbitrary pod from a `west` cluster. 

The first step is to clone the demo
repository on your local machine.
```sh
# clone example repository
$ git clone git@github.com:mateiidavid/l2d-k3d-statefulset.git
$ cd l2d-k3d-statefulset
```

The second step consists of creating two `k3d` clusters named `east` and
`west`, where the `east` cluster is the source and the `west` cluster is the
target. When creating our clusters, we need a shared trust root. Luckily, the
repository you have just cloned includes a handful of scripts that will greatly
simplify everything.
```sh
# create k3d clusters
$ ./create.sh

# list the clusters
$ k3d cluster list
NAME   SERVERS   AGENTS   LOADBALANCER
east   1/1       0/0      true
west   1/1       0/0      true
```

Once our clusters are created, we will install Linkerd and the multi-cluster
extension. Finally, once both are installed, we need to link the two clusters
together so their services may be mirrored. To enable support for headless
services, we will pass an additional `--set "enableHeadlessServices=true` flag
to `linkerd multicluster link`. As before, these steps are automated through
the provided scripts, but feel free to have a look!
```sh
# Install Linkerd and multicluster, output to check should be a success
$ ./install.sh

# Next, link the two clusters together
$ ./link.sh
```

Perfect! If you've made it this far with no errors, then it's a good sign. In
the next chapter, we'll deploy some services and look at how communication
works.

## Pod-to-Pod: from east, to west.

With our install steps out of the way, we can now focus on our pod-to-pod communication. First, we will deploy our pods and services:
  * We will mesh the default namespaces in `east` and `west`.
  * In `west`, we will deploy an nginx StatefulSet with its own headless
    service, `nginx-svc`.
  * In `east`, our script will deploy a `curl` pod that will then be used to
    curl the nginx service.
```sh
# deploy services and mesh namespaces
$ ./deploy.sh

# verify both clusters
#
# verify east
$ kubectl --context=k3d-east get pods
NAME                    READY   STATUS        RESTARTS   AGE
curl-56dc7d945d-96r6p   2/2     Running       0          7s

# verify west has headless service
$ kubectl --context=k3d-west get services
NAME         TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
kubernetes   ClusterIP   10.43.0.1    <none>        443/TCP   10m
nginx-svc    ClusterIP   None         <none>        80/TCP    8s

# verify west has statefulset
#
# this may take a while to come up
$ kubectl --context=k3d-west get pods
NAME          READY   STATUS    RESTARTS   AGE
nginx-set-0   2/2     Running   0          53s
nginx-set-1   2/2     Running   0          43s
nginx-set-2   2/2     Running   0          36s
```

Before we go further, let's have a look at the endpoints object for the
`nginx-svc`:
```sh
$ kubectl --context=k3d-west get endpoints nginx-svc -o yaml
...
subsets:
- addresses:
  - hostname: nginx-set-0
    ip: 10.42.0.31
    nodeName: k3d-west-server-0
    targetRef:
      kind: Pod
      name: nginx-set-0
      namespace: default
      resourceVersion: "114743"
      uid: 7049f1c1-55dc-4b7b-a598-27003409d274
  - hostname: nginx-set-1
    ip: 10.42.0.32
    nodeName: k3d-west-server-0
    targetRef:
      kind: Pod
      name: nginx-set-1
      namespace: default
      resourceVersion: "114775"
      uid: 60df15fd-9db0-4830-9c8f-e682f3000800
  - hostname: nginx-set-2
    ip: 10.42.0.33
    nodeName: k3d-west-server-0
    targetRef:
      kind: Pod
      name: nginx-set-2
      namespace: default
      resourceVersion: "114808"
      uid: 3873bc34-26c4-454d-bd3d-7c783de16304
```

We can see, based on the endpoints object that the service has three endpoints,
with each endpoint having an address (or IP) whose hostname corresponds to a
StatefulSet pod. If we were to do a curl to any of these endpoints directly, we
would get an answer back. We can test this out by applying the curl pod to the
`west` cluster:
```sh
$ kubectl --context=k3d-west apply -f east/curl.yml
$ kubectl --context=k3d-west get pods
NAME                    READY   STATUS            RESTARTS   AGE
nginx-set-0             2/2     Running           0          5m8s
nginx-set-1             2/2     Running           0          4m58s
nginx-set-2             2/2     Running           0          4m51s
curl-56dc7d945d-s4n8j   0/2     PodInitializing   0          4s

$ kubectl --context=k3d-west exec -it curl-56dc7d945d-s4n8j -c curl -- bin/sh
```
If we do a curl now to one of these instances, we will get back a response.
```sh
# exec'd on the pod
/ $ curl nginx-set-0.nginx-svc.default.svc.west.cluster.local
"<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
    body {
        width: 35em;
        margin: 0 auto;
        font-family: Tahoma, Verdana, Arial, sans-serif;
    }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>"
```

Now, let's do the same, but this time from the `east` cluster. We will first
export the service.
```sh
$ kubectl --context=k3d-west label service nginx-svc mirror.linkerd.io/exported="true"
service/nginx-svc labeled

$ kubectl --context=k3d-east get services
NAME               TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
kubernetes         ClusterIP   10.43.0.1       <none>        443/TCP   20h
nginx-svc-west     ClusterIP   None            <none>        80/TCP    29s
nginx-set-0-west   ClusterIP   10.43.179.60    <none>        80/TCP    29s
nginx-set-1-west   ClusterIP   10.43.218.18    <none>        80/TCP    29s
nginx-set-2-west   ClusterIP   10.43.245.244   <none>        80/TCP    29s
```

If we take a look at the endpoints object, we will notice something odd, the
endpoints for `nginx-svc-west` will have the same hostnames, but each hostname
will point to one of the services we see above:
```sh
$ kubectl --context=k3d-east get endpoints nginx-svc-west -o yaml
subsets:
- addresses:
  - hostname: nginx-set-0
    ip: 10.43.179.60
  - hostname: nginx-set-1
    ip: 10.43.218.18
  - hostname: nginx-set-2
    ip: 10.43.245.244
```

This is what we outlined at the start of the tutorial. Each pod from the target
cluster (`west`), will be mirrored as a clusterIP service. We will see in a
second why this matters.

```sh
$ kubectl --context=k3d-east get pods
NAME                    READY   STATUS    RESTARTS   AGE
curl-56dc7d945d-96r6p   2/2     Running   0          23m

# exec and curl
$ kubectl --context=k3d-east exec pod curl-56dc7d945d-96r6p -it -c curl -- bin/sh
# we want to curl the same hostname we see in the endpoints object above.
# however, the service and cluster domain will now be different, since we
# are in a different cluster.
#
/ $ curl nginx-set-0.nginx-svc-west.default.svc.east.cluster.local
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
    body {
        width: 35em;
        margin: 0 auto;
        font-family: Tahoma, Verdana, Arial, sans-serif;
    }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
```

As you can see, we get the same response back! But, nginx is in a different
cluster. So, what happened behind the scenes?
  1. When we mirrored the headless service, we created a clusterIP service for
     each pod. Since services create DNS records, naming each endpoint with the
     hostname from the target gave us these pod FQNS
     (`nginx-set-0.(...).cluster.local`).
  2. Curl resolved the pod DNS name to an IP address. In our case, this IP
     would be `10.43.179.60`.
  3. Once the request is in-flight, the linkerd2-proxy intercepts it. It looks
     at the IP address and associates it with our `clusterIP` service. The
     service itself points to the gateway, so the proxy forwards the request to
     the target cluster gateway. This is the usual multi-cluster scenario.
  4. The gateway in the target cluster looks at the request and looks-up the
     original destination address. In our case, since this is an "endpoint
     mirror", it knows it has to go to `nginx-set-0.nginx-svc` in the same
     cluster.
  5. The request is again forwarded by the gateway to the pod, and the response
     comes back.

And that's it! You can now send requests to pods across clusters. Querying any
of the 3 StatefulSet pods should have the same results.

**Note**: to mirror a headless service as headless, the service's endpoints
must also have at least one named address (e.g a hostname for an IP),
otherwise, there will be no endpoints to mirror so the service will be mirrored
as `clusterIP`. A headless service may under normal conditions also be created
without exposing a port; the mulit-cluster service-mirror does not support
this, however, since the lack of ports means we cannot create a service that
passes Kubernetes validation.

## Cleanup

To clean-up, you can remove both clusters entirely using the k3d CLI:
```sh
$ k3d cluster delete east
$ k3d cluster delete west
```
