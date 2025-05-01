---
title: Graceful Pod Shutdown
description: Gracefully handle pod shutdown signal.
---

When Kubernetes begins to terminate a pod, it starts by sending all containers
in that pod a TERM signal. When the Linkerd proxy sidecar receives this signal,
it will immediately begin a graceful shutdown where it refuses all new requests
and allows existing requests to complete before shutting down.

This means that if the pod's main container attempts to make any new network
calls after the proxy has received the TERM signal, those network calls will
fail. This also has implications for clients of the terminating pod and for
job resources.

## Graceful shutdown in Kubernetes

[pod-lifetime]: https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#pod-lifetime
[pod-termination]: https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#pod-termination
[pod-forced]: https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#pod-termination-forced
[hook]: https://kubernetes.io/docs/concepts/containers/container-lifecycle-hooks/#container-hooks

Pods are ephemeral in nature, and may be [killed due to a number of different
reasons][pod-lifetime], such as:

* Being scheduled on a node that fails (in which case the pod will be deleted).
* A lack of resources on the node where the pod is scheduled (in which case the
  pod is evicted).
* Manual deletion, e.g through `kubectl delete`.

Since pods fundamentally represent processes running on nodes in a cluster, it
is important to ensure that when killed, they have enough time to clean-up and
terminate gracefully. When a pod is deleted, the [container runtime will send a
TERM signal][pod-termination] to each container running in the pod.

By default, Kubernetes will wait [30 seconds][pod-forced] to allow processes to
handle the TERM signal. This is known as the **grace period** within which a
process may shut itself down gracefully. If the grace period time runs out, and
the process hasn't gracefully exited, the container runtime will send a KILL
signal, abruptly stopping the process. Grace periods may be overridden at a
workload level. This is useful when a process needs additional time to clean-up
(e.g making network calls, writing to disk, etc.)

Kubernetes also allows operators of services to define lifecycle hooks for
their containers. Important in the context of graceful shutdown is the
[`preStop`][hook] hook, that will be called when a container is terminated due
to:

* An API request.
* Liveness/Readiness probe failure.
* Resource contention.

If a pod has a preStop hook for a container, and the pod receives a TERM signal
from the container runtime, the preStop hook will be executed, and it must
finish before the TERM signal can be propagated to the container itself. It is
worth noting in this case that the **grace period** will start when the preStop
hook is executed, not when the container first starts processing the TERM
signal.

## Configuration options for graceful shutdown

Linkerd offers a few options to configure pods and containers to gracefully shutdown.

* `--wait-before-seconds`: can be used as an install value (either through the
  CLI or through Helm), or alternatively, through a [configuration
  annotation](../reference/proxy-configuration/). This will add a
  `preStop` hook to the proxy container to delay its handling of the TERM
  signal. This will only work when the conditions described above are satisfied
  (i.e container runtime sends the TERM signal)
* `config.linkerd.io/shutdown-grace-period`: is an annotation that can be used
  on workloads to configure the graceful shutdown time for the _proxy_. If the
  period elapses before the proxy has had a chance to gracefully shut itself
  down, it will forcefully shut itself down thereby closing all currently open
  connections. By default, the shutdown grace period is 120 seconds. This grace
  period will be respected regardless of where the TERM signal comes from; the
  proxy may receive a shutdown signal from the container runtime, a different
  process (e.g a script that sends TERM), or from a networked request to its
  shutdown endpoint (only possible on the loopback interface). The proxy will
  delay its handling of the TERM signal until all of its open connections have
  completed. This option is particularly useful to close long-running
  connections that would otherwise prevent the proxy from shutting down
  gracefully.
* `linkerd-await`: is a binary that wraps (and spawns) another process, and it
  is commonly used to wait for proxy readiness. The await binary can be used
  with a `--shutdown` option, in which case, after the process it has wrapped
  finished, it will send a shutdown request to the proxy. When used for
  graceful shutdown, typically the entrypoint for containers need to be changed
  to linkerd-await.

Depending on the usecase, one option (or utility) might be preferred over the
other. To aid with some common cases, suggestions are given below on what to do
when confronted with slow updating clients and with job resources that will not
complete.

## Slow Updating Clients

Before Kubernetes terminates a pod, it first removes that pod from the endpoints
resource of any services that pod is a member of. This means that clients of
that service should stop sending traffic to the pod before it is terminated.
However, certain clients can be slow to receive the endpoints update and may
attempt to send requests to the terminating pod after that pod's proxy has
already received the TERM signal and begun graceful shutdown. Those requests
will fail.

To mitigate this, use the `--wait-before-exit-seconds` flag with
`linkerd inject` to delay the Linkerd proxy's handling of the TERM signal for
a given number of seconds using a `preStop` hook. This delay gives slow clients
additional time to receive the endpoints update before beginning graceful
shutdown. To achieve max benefit from the option, the main container should have
its own `preStop` hook with the sleep command inside which has a smaller period
than is set for the proxy sidecar. And none of them must be bigger than
`terminationGracePeriodSeconds` configured for the entire pod.

For example,

```yaml
       # application container
        lifecycle:
          preStop:
            exec:
              command:
                - /bin/bash
                - -c
                - sleep 20

    # for entire pod
    terminationGracePeriodSeconds: 160
```

## Graceful shutdown of Job and Cronjob Resources

Pods which are part of Job or Cronjob resources will run until all of the
containers in the pod complete. However, the Linkerd proxy container runs
continuously until it receives a TERM signal. Since Kubernetes does not give the
proxy a means to know when the Cronjob has completed, by default, Job and
Cronjob pods which have been meshed will continue to run even once the main
container has completed.

To address this, you can issue a POST to the `/shutdown` endpoint on the proxy
once the application completes (e.g. via `curl -X POST
http://localhost:4191/shutdown`). This will terminate the proxy gracefully and
allow the Job or Cronjob to complete. These shutdown requests must come on the
loopback interface, i.e. from within the same Kubernetes pod.

One convenient way to call this endpoint is to wrap your application with the
[linkerd-await](https://github.com/linkerd/linkerd-await) utility. An
application that is called this way (e.g. via `linkerd-await -S $MYAPP`) will
automatically call the proxy's `/shutdown` endpoint when it completes.

In the future, Kubernetes will hopefully support more container lifecycle hooks
that will allow Linkerd to handle these situations automatically.
