+++
title = "Using the Debug Sidecar"
description = "Inject the debug container to capture network packets."
+++

Debugging a service mesh can be hard---when something just isn't working, is
the problem with the proxy? With the application? With the client? With the
underlying network? Sometimes, nothing beats looking at raw network data.

In cases where you need network-level visibility into packets entering and
leaving your application, Linkerd provides a *debug sidecar* with some helpful
tooling. Similar to how [proxy sidecar
injection](/2/features/proxy-injection/) works, you add a debug sidecar to
a pod by setting the `config.linkerd.io/enable-debug-sidecar: true` annotation
at pod creation time. For convenience, the `linkerd inject` command provides an
`--enable-debug-sidecar` option that does this annotation for you.

(Note that the set of containers in a Kubernetes pod is not mutable, so simply
adding this annotation to a pre-existing pod will not work. It must be present
at pod *creation* time.)

The debug sidecar container image contains a container with
[`tshark`](https://www.wireshark.org/docs/man-pages/tshark.html), `tcpdump`,
`lsof`, and `iproute2`. The default entrypoint that starts `tshark -i any`.
Since all containers in a pod share the same network namespace, this means that
the logs for this container will contain the network traffic observed in the
pod, which can be easily viewed with `kubectl logs`. Alternatively, you can use
`kubectl exec` to access the container and run commands directly.

For instance, if you've gone through the [Linkerd Getting
Started](https://linkerd.io/2/getting-started/) guide and installed the
*emojivoto* application, and wish to debug the *voting* service, you
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
user@local$ kubectl -n emojivoto exec -it voting-7cf4784dd8-qxjv4 \
  -c linkerd-debug -- /bin/bash
root@voting-7cf4784dd8-qxjv4:/#
root@voting-7cf4784dd8-qxjv4:/# tshark -i any -f "tcp" -V -Y "http.request"
Running as user "root" and group "root". This could be dangerous.
Capturing on 'any'

...
```

Of course, this only works if you have the ability to `exec` into arbitrary
containers in the Kubernetes cluster.
