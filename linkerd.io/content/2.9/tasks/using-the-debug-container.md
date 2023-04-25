+++
title = "Using the Debug Sidecar"
description = "Inject the debug container to capture network packets."
+++

Debugging a service mesh can be hard. When something just isn't working, is
the problem with the proxy? With the application? With the client? With the
underlying network? Sometimes, nothing beats looking at raw network data.

In cases where you need network-level visibility into packets entering and
leaving your application, Linkerd provides a *debug sidecar* with some helpful
tooling. Similar to how [proxy sidecar
injection](../../features/proxy-injection/) works, you add a debug sidecar to
a pod by setting the `config.linkerd.io/enable-debug-sidecar: "true"` annotation
at pod creation time. For convenience, the `linkerd inject` command provides an
`--enable-debug-sidecar` option that does this annotation for you.

(Note that the set of containers in a Kubernetes pod is not mutable, so simply
adding this annotation to a pre-existing pod will not work. It must be present
at pod *creation* time.)

{{< trylpt >}}

The debug sidecar image contains
[`tshark`](https://www.wireshark.org/docs/man-pages/tshark.html), `tcpdump`,
`lsof`, and `iproute2`. Once installed, it starts automatically logging all
incoming and outgoing traffic with `tshark`, which can then be viewed with
`kubectl logs`. Alternatively, you can use `kubectl exec` to access the
container and run commands directly.

For instance, if you've gone through the [Linkerd Getting
Started](../../getting-started/) guide and installed the
*emojivoto* application, and wish to debug traffic to the *voting* service, you
could run:

```bash
kubectl -n emojivoto get deploy/voting -o yaml \
  | linkerd inject --enable-debug-sidecar - \
  | kubectl apply -f -
```

to deploy the debug sidecar container to all pods in the *voting* service.
(Note that there's only one pod in this deployment, which will be recreated
to do this--see the note about pod mutability above.)

You can confirm that the debug container is running by listing
all the containers in pods with the `voting-svc` label:

```bash
kubectl get pods -n emojivoto -l app=voting-svc \
  -o jsonpath='{.items[*].spec.containers[*].name}'
```

Then, you can watch live tshark output from the logs by simply running:

```bash
kubectl -n emojivoto logs deploy/voting linkerd-debug -f
```

If that's not enough, you can exec to the container and run your own commands
in the context of the network. For example, if you want to inspect the HTTP headers
of the requests, you could run something like this:

```bash
kubectl -n emojivoto exec -it \
  $(kubectl -n emojivoto get pod -l app=voting-svc \
    -o jsonpath='{.items[0].metadata.name}') \
  -c linkerd-debug -- tshark -i any -f "tcp" -V -Y "http.request"
```

A real-world error message written by the proxy that the debug sidecar is
effective in troubleshooting is a `Connection Refused` error like this one:

 ```log
ERR! [<time>] proxy={server=in listen=0.0.0.0:4143 remote=some.svc:50416}
linkerd2_proxy::app::errors unexpected error: error trying to connect:
Connection refused (os error 111) (address: 127.0.0.1:8080)
```

In this case, the `tshark` command can be modified to listen for
traffic between the specific ports mentioned in the error, like this:

 ```bash
kubectl -n emojivoto exec -it \
  $(kubectl -n emojivoto get pod -l app=voting-svc \
   -o jsonpath='{.items[0].metadata.name}') \
   -c linkerd-debug -- tshark -i any -f "tcp" -V \
   -Y "(tcp.srcport == 4143 and tcp.dstport == 50416) or tcp.port == 8080"
 ```

Be aware that there is a similar error with the message `Connection reset by
peer`. This error is usually benign, if you do not see correlated errors or
messages in your application log output. In this scenario, the debug
 container may not help to troubleshoot the error message.

```log
ERR! [<time>] proxy={server=in listen=0.0.0.0:4143 remote=some.svc:35314}
linkerd2_proxy::app::errors unexpected error: connection error:
Connection reset by peer (os error 104)
```

Of course, these examples only work if you have the ability to `exec` into
arbitrary containers in the Kubernetes cluster. See [`linkerd
tap`](../../reference/cli/tap/) for an alternative to this approach.
