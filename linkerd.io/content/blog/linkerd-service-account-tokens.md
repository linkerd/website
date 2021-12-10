---
title: Service Account Tokens in Linkerd
date: 2021-12-10T00:00:00Z
tags:
  - identity
  - service-accounts
author: tarun
description: 'Linkerd uses Kubernetes Service Account Tokens to verify the proxy
  before issuing a certificate, and also for other functions.
  Lets understand all this in this post, along with the latest developments. '
keywords: [identity service-accounts]
---

Linkerd uses mTLS to secure communication between services. You can read
all about it in the [mTLS guide](https://buoyant.io/mtls-guide/). All of
the mTLS magic is possible because the control-plane (specifically the
`identity` component) issues a Leaf certificate that the proxy uses
to authenticate itself with other services. This feels all nice and fine,
right? But how does the identity component ensure it's issuing certificate
for a proxy in the cluster? and not some intruder who wants to communicate with
other services in the cluster? How does the control-plane ensure identities of the
proxies itself? Now, Let's dive into that :)

## Kubernetes Service Accounts

This is not just a Linkerd problem right? A lot of components or K8s controllers
would want to verify the identity  of their clients (if they are running
in the cluster or not) before providing services for them. So, Kubernetes provides
Service Accounts that are attached to your Pods by default, and can be used
by the application inside to prove its identity to other components that its
part of the kubernetes cluster. These are attached as a volume into your Pod,
and are mounted into the container at the `/var/run/secrets/kubernetes.io/serviceaccount`
filepath. By default, Kubernetes attaches the `default` service account of the pod
namespace.

```yaml
spec:
  containers:
  ...
    volumeMounts:
    - mountPath: /var/run/secrets/kubernetes.io/serviceaccount
      name: kube-api-access-tsbwl
      readOnly: true
  ...
  volumes:
  - name: kube-api-access-tsbwl
    projected:
      defaultMode: 420
      sources:
      - serviceAccountToken:
          expirationSeconds: 3607
          path: token
      - configMap:
          items:
          - key: ca.crt
            path: ca.crt
          name: kube-root-ca.crt
      - downwardAPI:
          items:
          - fieldRef:
              apiVersion: v1
              fieldPath: metadata.namespace
            path: namespace
```

Service Accounts are also popularly used with Kubernetes RBAC to grant access to
Kubernetes API Services to pods. This is done by attaching a ClusterRole (with
necessary permissions) to a ServiceAccount (by creating a `ServiceAccount` object)
using a `ClusterRoleBinding`. and then specifying the same Service Account in the
`serviceAccountName` of your workload. This would override the default service
account that is present per namespace. The default service account token
has no permissions to view, list or modify any resources in the cluster.

When Kubernetes attaches the service account token, it also attaches a configmap
of the `kube-root-ca.crt` that is used to talk to the API server. (Linkerd never
used all of these as the proxies *never* talk to the Kubernetes API directly.
We will see later how we even stopped using these in the latest changes).
If you've [used `client-go`'s `rest.InClusterConfig()`](https://github.com/kubernetes/client-go/blob/master/examples/in-cluster-client-configuration/main.go#L42)
to get the config, you can [see](https://github.com/kubernetes/client-go/blob/master/rest/config.go#L514)
it has to read the token and `kube-root-ca.crt` from the path to be able to talk
to the Kubernetes API.

## Current Linkerd Integration

For the proxy to get its leaf certificates, it needs to verify itself with the identity
component. This is done by embedding the service account token into the `Certify`
request that is called every time a new leaf certificate is needed(24h by default).
The identity component [validates the token](https://github.com/linkerd/linkerd2/blob/main/controller/identity/validator.go#L51)
by talking to the [TokenReview](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.19/#tokenreview-v1-authentication-k8s-io)
Kubernetes API and returns a `CertifyResponse` with the leaf certificate only after
that. The Identity component not only verifies that the token is valid, but it also
verifies if the token is associated with the same pod that that is requesting the
certificate. This can be verified by looking at the `Status.User.Username` in the
TokenReview response. Kubernetes API sets the username to the pod name to which
that token was attached.

Only the identity component in Linkerd has the necessary API access to verify Tokens.
Once a token is verified, Only after that the identity component issues a certificate
for the proxy to use to communicate with other services.

### Identity

These service accounts are also used for identity of the client/server.
Whenever a meshed request is received or being sent. The relevant metrics
also include the service account with which that peer was associated with.

Here, is an example metric from the emojivoto example:

```promql
request_total{..., client_id="web.emojivoto.serviceaccount.identity.linkerd.cluster.local", authority="emoji-svc.emojivoto.svc.cluster.local:8080",  namespace="emojivoto", pod="emoji-696d9d8f95-5sj4j"} 14532
```

As you can see the `client_id` label in the above metric is the service account
that was attached to the client pod from where the request was received.

### Policy

Linkerd's new Policy Enforcement feature allows users to specify set of clients
that can only access a set of resources. This is done by using the same identity
by allowing users to specify service accounts of the clients that should be allowed
to talk to a group of workloads (grouped by the `Server` resource) in
their `ServerAuthorization` resource.

```yaml
apiVersion: policy.linkerd.io/v1beta1
kind: ServerAuthorization
metadata:
  namespace: emojivoto
  name: internal-grpc
  labels:
    app.kubernetes.io/part-of: emojivoto
    app.kubernetes.io/version: v11
spec:
  server:
    selector:
      matchLabels:
        emojivoto/api: internal-grpc
  client:
    meshTLS:
      serviceAccounts:
        - name: web
```

In the above example, we are allowing workloads that use the `web` service account
to talk to the `internal-grpc` server.

## Latest Updates

Though all of this is great, There's still a catch. This token is aimed at the
applications to talk to the kubernetes API and not specifically for Linkerd.
Linkerd also doesn't need those extra certs that are part of the default volume mount.
This also means that there are [controls outside of Linkerd](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/#use-the-default-service-account-to-access-the-api-server),
to manage this service token, which users might want to use,
[causing problems with Linkerd](https://github.com/linkerd/linkerd2/issues/3183)
as Linkerd might expect it to be present to do the verification. Users can
also explicitly disable the token auto-mount on their pods causing problems with
Linkerd. Currently, We skip pod injection if that is the case.

For all the above challenges, Starting from [edge-21.11.1](https://github.com/linkerd/linkerd2/releases/tag/edge-21.11.1)
We have added the support for Auto-Mount Bounded service account tokens. Instead
of using the token that is mounted by default, Linkerd will request its own set
of tokens by using the [Bound Service Account Tokens](https://github.com/kubernetes/enhancements/tree/master/keps/sig-auth/1205-bound-service-account-tokens)
feature.

Using this, Linkerd injector will request for a token that is bounded specifically
for Linkerd, along with a 24h expiry(just like that of identity expiration). This
token is generated for the same service account that was mounted to the pod by
Kubernetes, and thus not affecting any of the identity stuff discussed above.

```yaml
spec:
  containers:
  ...
    volumeMounts:
    - mountPath: /var/run/linkerd/identity/end-entity
      name: linkerd-identity-end-entity
  ...
  volumes:
  - name: linkerd-identity-token
    projected:
      defaultMode: 420
      sources:
      - serviceAccountToken:
          audience: identity.l5d.io
          expirationSeconds: 86400
          path: linkerd-identity-token
```

As you can this token is specifically generated for Linkerd for the proxies
to verify themselves with identity, and can no way be used talk to the
Kubernetes API. Thus, giving us a nice separation of concerns.

## Summary

In this post, we started on what Kubernetes Service Account tokens are, and then
explained how Linkerd uses them in the proxies to identify themselves with the
identity component. From there, We also saw how these are also used as a way to
identity workloads with metrics. We also saw how in the latest changes, We
started to use tokens that are specifically generated for Linkerd, and cannot
be used to access the Kubernetes API, while also solving other user problems.
