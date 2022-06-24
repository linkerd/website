+++
title = "Graceful Pod Shutdown"
description = "Gracefully handle pod shutdown signal."
+++

When Kubernetes begins to terminate a pod, it starts by sending all containers
in that pod a TERM signal. When the Linkerd proxy sidecar receives this signal,
it will immediately begin a graceful shutdown where it refuses all new requests
and allows existing requests to complete before shutting down.

This means that if the pod's main container attempts to make any new network
calls after the proxy has received the TERM signal, those network calls will
fail. This also has implications for clients of the terminating pod and for
job resources.

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
