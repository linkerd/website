---
title: Multi-cluster communication with StatefulSets
description:
  Configure cross-cluster communication to and from headless services.
---

Linkerd's multi-cluster extension works by "mirroring" service information
between clusters. Exported services in a target cluster will be mirrored as
`clusterIP` replicas. By default, every exported service will be mirrored as
`clusterIP`. When running workloads that require a headless service, such as
[StatefulSets](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/),
Linkerd's multi-cluster extension can be configured with support for headless
services to preserve the service type. Exported services that are headless will
be mirrored in a source cluster as headless, preserving functionality such as
DNS record creation and the ability to address an individual pod.

This guide will walk you through installing and configuring Linkerd and the
multi-cluster extension with support for headless services and will exemplify
how a StatefulSet can be deployed in a target cluster. After deploying, we will
also look at how to communicate with an arbitrary pod from the target cluster's
StatefulSet from a client in the source cluster. For a more detailed overview on
how multi-cluster support for headless services work, check out
[multi-cluster communication](../features/multicluster/).

## Prerequisites

- Two Kubernetes clusters. They will be referred to as `east` and `west` with
  east being the "source" cluster and "west" the target cluster respectively.
  These can be in any cloud or local environment, this guide will make use of
  [k3d](https://github.com/rancher/k3d/releases/tag/v4.1.1) to configure two
  local clusters.
- [`smallstep/CLI`](https://github.com/smallstep/cli/releases) to generate
  certificates for Linkerd installation.
- [`A recent linkerd release`](https://github.com/linkerd/linkerd2/releases)
  (2.18 or newer).

To help with cluster creation and installation, there is a demo repository
available. Throughout the guide, we will be using the scripts from the
repository, but you can follow along without cloning or using the scripts.

## Install Linkerd multi-cluster with headless support

To start our demo and see everything in practice, we will go through a
multi-cluster scenario where a pod in an `east` cluster will try to communicate
to an arbitrary pod from a `west` cluster.

The first step is to clone the demo repository on your local machine.

```sh
# clone example repository
$ git clone git@github.com:linkerd/l2d-k3d-statefulset.git
$ cd l2d-k3d-statefulset
```

The second step consists of creating two `k3d` clusters named `east` and `west`,
where the `east` cluster is the source and the `west` cluster is the target.
When creating our clusters, we need a shared trust root. Luckily, the repository
you have just cloned includes a handful of scripts that will greatly simplify
everything.

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
together so their services may be mirrored. As before, these steps are automated
through the provided scripts; please give them a look and see how the
controllers and links are generated for both clusters.

```sh
# Install Linkerd and multicluster, output to check should be a success
$ ./install.sh

# Next, link the two clusters together
$ ./link.sh
```

Perfect! If you've made it this far with no errors, then it's a good sign. In
the next chapter, we'll deploy some services and look at how communication
works.

## Pod-to-Pod: from east, to west

With our install steps out of the way, we can now focus on our pod-to-pod
communication. First, we will deploy our pods and services:

- We will mesh the default namespaces in `east` and `west`.
- In `west`, we will deploy an nginx StatefulSet with its own headless service,
  `nginx-svc`.
- In `east`, our script will deploy a `curl` pod that will then be used to curl
  the nginx service.

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

$ kubectl --context=k3d-west exec -it curl-56dc7d945d-s4n8j -c curl -- sh
/$ # prompt for curl pod
```

If we now curl one of these instances, we will get back a response.

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
$ kubectl --context=k3d-east get endpoints nginx-svc-k3d-west -o yaml
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
$ kubectl --context=k3d-east exec curl-56dc7d945d-96r6p -it -c curl -- sh
# we want to curl the same hostname we see in the endpoints object above.
# however, the service and cluster domain will now be different, since we
# are in a different cluster.
#
/ $ curl nginx-set-0.nginx-svc-k3d-west.default.svc.east.cluster.local
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
   hostname from the target gave us these pod FQDNs
   (`nginx-set-0.(...).cluster.local`).
2. Curl resolved the pod DNS name to an IP address. In our case, this IP would
   be `10.43.179.60`.
3. Once the request is in-flight, the linkerd2-proxy intercepts it. It looks at
   the IP address and associates it with our `clusterIP` service. The service
   itself points to the gateway, so the proxy forwards the request to the target
   cluster gateway. This is the usual multi-cluster scenario.
4. The gateway in the target cluster looks at the request and looks-up the
   original destination address. In our case, since this is an "endpoint
   mirror", it knows it has to go to `nginx-set-0.nginx-svc` in the same
   cluster.
5. The request is again forwarded by the gateway to the pod, and the response
   comes back.

And that's it! You can now send requests to pods across clusters. Querying any
of the 3 StatefulSet pods should have the same results.

{{< note >}}

To mirror a headless service as headless, the service's endpoints must also have
at least one named address (e.g a hostname for an IP), otherwise, there will be
no endpoints to mirror so the service will be mirrored as `clusterIP`. A
headless service may under normal conditions also be created without exposing a
port; the mulit-cluster service-mirror does not support this, however, since the
lack of ports means we cannot create a service that passes Kubernetes
validation.

{{< /note >}}

## Cleanup

To clean-up, you can remove both clusters entirely using the k3d CLI:

```sh
$ k3d cluster delete east
cluster east deleted
$ k3d cluster delete west
cluster west deleted
```
