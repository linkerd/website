+++
title = "Restricting Access To Services"
description = "Use Linkerd policy to restrict access to a service."
+++

Linkerd policy resources can be used to restrict which clients may access a
service.  In this example, we'll use Emojivoto to show how to restrict access
to the Voting service so that it may only be called from the Web service.

For a more comprehensive description of the policy resources, see the
[Policy reference docs](../../reference/authorization-policy/).

## Setup

Ensure that you have Linkerd version stable-2.11.0 or later installed, and that
it is healthy:

```bash
$ linkerd install | kubectl apply -f -
...
$ linkerd check -o short
...
```

Inject and install the Emojivoto application:

```bash
$ linkerd inject https://run.linkerd.io/emojivoto.yml | kubectl apply -f -
...
$ linkerd check -n emojivoto --proxy -o short
...
```

In order to observe what's going on, we'll also install the Viz extension:

```bash
$ linkerd viz install | kubectl apply -f -
...
$ linkerd viz check
...
```

## Creating a Server resource

We start by creating a `Server` resource for the Voting service.  A `Server`
is a Linkerd custom resource which describes a specific port of a workload.
Once the `Server` resource has been created, only clients which have been
authorized may access it (we'll see how to authorize clients in a moment).

```bash
cat << EOF | kubectl apply -f -
---
apiVersion: policy.linkerd.io/v1beta1
kind: Server
metadata:
  namespace: emojivoto
  name: voting-grpc
  labels:
    app: voting-svc
spec:
  podSelector:
    matchLabels:
      app: voting-svc
  port: grpc
  proxyProtocol: gRPC
EOF
```

We see that this `Server` uses a `podSelector` to select the pods that it
describes: in this case the voting service pods.  It also specifies the named
port (grpc) that it applies to.  Finally, it specifies the protocol that is
served on this port.  This ensures that the proxy treats traffic correctly and
allows it skip protocol detection.

At this point, no clients have been authorized to access this service and you
will likely see a drop in success rate as requests from the Web service to
Voting start to get rejected.

We can use the `linkerd viz authz` command to look at the authorization status
of requests coming to the voting service and see that all incoming requests
are currently unauthorized:

```bash
> linkerd viz authz -n emojivoto deploy/voting
SERVER       AUTHZ           SUCCESS     RPS  LATENCY_P50  LATENCY_P95  LATENCY_P99
voting-grpc  [UNAUTHORIZED]        -  0.9rps            -            -            -
```

## Creating a ServerAuthorization resource

A `ServerAuthorization` grants a set of clients access to a set of `Servers`.
Here we will create a `ServerAuthorization` which grants the Web service access
to the Voting `Server` we created above. Note that meshed mTLS uses
`ServiceAccounts` as the basis for identity, thus our authorization will also
be based on `ServiceAccounts`.

```bash
> cat << EOF | kubectl apply -f -
---
apiVersion: policy.linkerd.io/v1beta1
kind: ServerAuthorization
metadata:
  namespace: emojivoto
  name: voting-grpc
  labels:
    app.kubernetes.io/part-of: emojivoto
    app.kubernetes.io/name: voting
    app.kubernetes.io/version: v11
spec:
  server:
    name: voting-grpc
  # The voting service only allows requests from the web service.
  client:
    meshTLS:
      serviceAccounts:
        - name: web
EOF
```

With this in place, we can now see that all of the requests to the Voting
service are authorized by the `voting-grpc` ServerAuthorization. Note that since
the `linkerd viz auth` command queries over a time-window, you may see some
UNAUTHORIZED requests displayed for a short amount of time.

```bash
> linkerd viz authz -n emojivoto deploy/voting
SERVER       AUTHZ        SUCCESS     RPS  LATENCY_P50  LATENCY_P95  LATENCY_P99
voting-grpc  voting-grpc   70.00%  1.0rps          1ms          1ms          1ms
```

We can also test that request from other pods will be rejected by creating a
`grpcurl` pod and attempting to access the Voting service from it:

```bash
> kubectl run grpcurl --rm -it --image=networld/grpcurl --restart=Never --command -- ./grpcurl -plaintext voting-svc.emojivoto:8080 emojivoto.v1.VotingService/VoteDog
Error invoking method "emojivoto.v1.VotingService/VoteDog": failed to query for service descriptor "emojivoto.v1.VotingService": rpc error: code = PermissionDenied desc =
pod "grpcurl" deleted
pod default/grpcurl terminated (Error)
```

Because this client has not been authorized, this request gets rejected with a
`PermissionDenied` error.

You can create as many `ServerAuthorization` resources as you like to authorize
many different clients. You can also specify whether to authorize
unauthenticated (i.e. unmeshed) client, any authenticated client, or only
authenticated clients with a particular identity.  For more details, please see
the [Policy reference docs](../../reference/authorization-policy/).

## Setting a Default Policy

To further lock down a cluster, you can set a default policy which will apply
to all ports which do not have a Server resource defined. Linkerd uses the
following logic when deciding whether to allow a request:

* If the port has a Server resource and the client matches a ServerAuthorization
  resource for it: ALLOW
* If the port has a Server resource but the client does not match any
  ServerAuthorizations for it: DENY
* If the port does not have a Server resource: use the default policy

We can set the default policy to `deny` using the `linkerd upgrade` command:

```bash
> linkerd upgrade --set policyController.defaultAllowPolicy=deny | kubectl apply -f -
```

Alternatively, default policies can be set on individual workloads or namespaces
by setting the `config.linkerd.io/default-inbound-policy` annotation.  See the
[Policy reference docs](../../reference/authorization-policy/) for more details.

This means that ALL requests will be rejected unless they are explicitly
authorized by creating Server and ServerAuthorization resources.  One important
consequence of this is that liveness and readiness probes will need to be
explicitly authorized or else Kubernetes will not be able to recognize the pods as
live or ready and will restart them.

This policy allows all clients to reach the Linkerd admin port so that Kubernetes
can perform liveness and readiness checks:

```bash
> cat << EOF | kubectl apply -f -
---
# Server "admin": matches the admin port for every pod in this namespace
apiVersion: policy.linkerd.io/v1beta1
kind: Server
metadata:
  namespace: emojivoto
  name: admin
spec:
  port: linkerd-admin
  podSelector:
    matchLabels: {} # every pod
  proxyProtocol: HTTP/1
---
# ServerAuthorization "admin-everyone": allows unauthenticated access to the
# "admin" Server, so that Kubernetes health checks can get through.
apiVersion: policy.linkerd.io/v1beta1
kind: ServerAuthorization
metadata:
  namespace: emojivoto
  name: admin-everyone
spec:
  server:
    name: admin
  client:
    unauthenticated: true
```

If you know the IP address or range of the Kubelet (which performs the health
checks), you can further restrict the ServerAuthorization to these IP addresses
or ranges. For example, if you know that the Kubelet is running at `10.244.0.1`
then your ServerAuthorization can instead become:

```yaml
# ServerAuthorization "admin-kublet": allows unauthenticated access to the
# "admin" Server from the kubelet, so that Kubernetes health checks can get through.
apiVersion: policy.linkerd.io/v1beta1
kind: ServerAuthorization
metadata:
  namespace: emojivoto
  name: admin-kubelet
spec:
  server:
    name: admin
  client:
    networks:
    - cidr: 10.244.0.1/32
    unauthenticated: true
```

## Further Considerations

You may have noticed that there was a period of time after we created the
`Server` resource but before we created the `ServerAuthorization` where all
requests were being rejected. To avoid this situation in live systems, we
recommend you either create the policy resources before deploying your services
or to create the `ServiceAuthorizations` BEFORE creating the `Server` so that
clients will be authorized immediately.
