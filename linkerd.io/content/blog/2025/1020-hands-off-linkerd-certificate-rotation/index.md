---
date: 2025-10-20T00:00:00Z
title: Hands off Linkerd certificate rotation
keywords: [linkerd, "Cert Manager", automation]
params:
  author:
    name: Matthew McLane
    avatar: matthew-mclane.jpg
---

_This blog post was originally published on
[Matthew McLane's Medium blog](https://medium.com/@mclanem_45809/hands-off-linkerd-certificate-rotation-0e387fdeaa0a)._

I’ll start by saying that I think Linkerd is a **great tool**. We use it at work
to provide **TLS between our pods**, which frees us from having to build that
functionality directly into our containers. When it works, it’s fantastic! It’s
simple to get up and running and just does the job without a lot of extra fuss.
For the most part, it’s been a very hands-off experience, which is exactly what
we need.

Recently, though, a change to **cert-manager** caused our long-standing
certificates to unexpectedly rotate. This sent me on a journey to understand and
implement a **fully automated certificate rotation solution** for our Linkerd
service mesh, and I’d like to take you along for the ride.

## The Problem

Linkerd largely manages its own certificates, but it needs a trusted foundation:
a root anchor and an identity issuer certificate. Linkerd’s own documentation on
**“[Automatically Rotating Control Plane TLS Credentials](/2/tasks/automatically-rotating-control-plane-tls-credentials/)”**
explains this in detail. My goal was to build a completely automated solution
for our clusters, bypassing the need for manual `kubectl` commands. I wanted to
leverage our existing ArgoCD infrastructure to handle everything, including
regular certificate rotation and all the necessary restarts, without any manual
intervention.

## linkerd-certs helm chart

The first step in my solution was to create a simple **Helm chart** to lay down
the required certificates. Following the
[documentation](/2/tasks/automatically-rotating-control-plane-tls-credentials/),
this chart creates three key certificates in the namespace using cert-manager:
`linkerd-trust-root-issuer`, `linkerd-trust-anchor`, and
`linkerd-identity-issuer`.

This Helm chart also sets up the `linkerd-identity-issuer` and the necessary
trust bundle within the Linkerd namespace. Essentially, this single chart
handles all the certificates needed to install Linkerd and enable its automatic
rotation feature.

## The rotation problem

As stated in the documentation:

> Rotating the identity issuer is basically a non-event: cert-manager can handle
> rotating the identity issuer completely on its own.  
> .  
> .  
> .  
> Rotating the trust anchor is a bit different, because rotating the trust
> anchor mean that you have to restart both the Linkerd control plane and all
> the proxies while managing the trust bundle. In practice, this requires manual
> intervention, because while cert-manager can handle the hard work of actually
> rotating the trust anchor, it can’t trigger the needed restarts.

I really didn’t want to rely on anything with manual intervention. The solution
to this problem was fairly simple to workout. All the heavy lifting was provided
in the
[documentation](/2/tasks/automatically-rotating-control-plane-tls-credentials/)!
First I started by creating a set of shell scripts.

First is a script to rotate the certificates:

```bash
#!/bin/bash
set -e
echo "renewing linkerd-trusted-anchor"
cmctl renew -n cert-manager linkerd-trust-anchor
echo "Waiting 120 seconds to allow for certs to update"
sleep 120
echo "---"

echo "renewing linkerd-identity-issuer"
cmctl renew -n linkerd linkerd-identity-issuer
echo "Waiting 120 seconds to allow for certs to update"
sleep 120
```

Next was a script to restart the linkerd control-plane pods. I also use this
moment to restart the linkerd-viz pods.

```bash
#!/bin/bash
set -e
echo "---"
echo "Restarting linkerd control plane"
kubectl rollout restart -n linkerd deploy --selector=linkerd.io/control-plane-ns=linkerd
kubectl rollout status -n linkerd deploy --selector=linkerd.io/control-plane-ns=linkerd

echo "Waiting 20 seconds for stabilization..."
sleep 20
echo "---"
echo "Restarting linkerd viz"
kubectl rollout restart -n linkerd-viz deploy --selector=linkerd.io/extension=viz
kubectl rollout status -n linkerd-viz deploy --selector=linkerd.io/extension=viz
```

The next step is a script to restart the data plane or all of the pods that have
had the linkerd-proxy injected. Thankfully we use namespace annotations to
control what gets injected, so all I needed to do was query for those
namespaces. Once I have found all namespaces with “linkerd.io/inject: enabled”,
we can restart each one at a time.

```bash
#!/bin/bash
set -e
NAMESPACES=$(kubectl get ns -o json | jq -r '.items[] | select(.metadata.annotations."linkerd.io/inject" == "enabled") | .metadata.name')
# Check if any namespaces were found.
if [ -z "$NAMESPACES" ]; then
  echo "No namespaces found with 'linkerd.io/inject: enabled' annotation."
  exit 0
fi

echo "---"
echo "Linkerd injected namespaces:"
echo "$NAMESPACES"
echo "---"

# Loop through each namespace found.
for NAMESPACE in $NAMESPACES; do
  echo "Restarting deployments in namespace: $NAMESPACE"
  kubectl rollout restart -n "$NAMESPACE" deployment
  kubectl rollout status -n "$NAMESPACE" deployment
  echo "Waiting 10 seconds for stabilization..."
  sleep 10
  echo "---"
done
```

The last step is to remove the old trust anchor from the trust bundle.

```bash
#!/bin/bash
set -e
# Remove the old anchor from the trust bundle
kubectl get secret -n cert-manager linkerd-trust-anchor -o yaml \
        | sed -e s/linkerd-trust-anchor/linkerd-previous-anchor/ \
        | egrep -v '^  *(resourceVersion|uid)' \
        | kubectl apply -f -
```

One last script ties all of these scripts together into a single runable shell
script.

```bash
#!/bin/bash
set -e

echo "Starting Linkerd certificate rotation process"
echo "------------------------------------------"
/scripts/rotate-certs.sh
/scripts/restart-control-plane.sh
sleep 60s
/scripts/restart-data-plane.sh
sleep 60s
/scripts/update-bundle.sh
echo "------------------------------------------"
echo "Linkerd certificate rotation process completed"
```

All that was left was to schedule this all to run. To accomplish this I bundled
all of these scripts up into a docker container.

```bash
FROM bitnami/kubectl

USER root

# Note that the scripts listed above are in a scripts subdirectory.
RUN mkdir /scripts
WORKDIR /scripts
COPY ./scripts .

RUN apt-get update && apt-get install --no-install-recommends -y curl \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# Install cmctl
RUN curl -fsSL -o cmctl https://github.com/cert-manager/cmctl/releases/latest/download/cmctl_linux_amd64 && \
    chmod +x cmctl && \
    mv cmctl /usr/local/bin

USER nonroot
CMD ["sh", "./rotation.sh"]
```

## CronJob

Scheduling the above container to run involves two things. First, you need a
service account that has the permission needed to not only rotate the certs but
also restart all of the deployments. Thankfully all I had to do was add the
following to our linkerd-certs helm chart mentioned earlier.

```yaml
---
kind: ServiceAccount
apiVersion: v1
metadata:
  name: rotator
  namespace: linkerd

---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: rotator
  namespace: linkerd
rules:
  - apiGroups: ["apps", "extensions", "cert-manager.io"]
    resources: ["deployments", "certificates", "certificates/status"]
    verbs: ["get", "patch", "list", "watch", "update"]

---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: rotator
  namespace: linkerd
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: rotator
subjects:
  - kind: ServiceAccount
    name: rotator
    namespace: linkerd

---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: rotator-clusterrole
rules:
- apiGroups: ["cert-manager.io", ""]
  resources: ["certificates", "certificates/status", "secrets"]
  verbs: ["get", "list", "patch", "update"]
- apiGroups: ["*"]
  resources: ["namespaces", "deployments"]
  verbs: ["get", "list"]
- apiGroups: ["*"]
  resources: ["deployments"]
  verbs: ["get", "list", "watch", "patch"]

---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: rotator-clusterrolebinding
  namespace: cert-manager
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: rotator-clusterrole
subjects:
- kind: ServiceAccount
  name: rotator
  namespace: linkerd

---
apiVersion: batch/v1
kind: CronJob
metadata:
  name: linkerd-cert-rotation
  namespace: linkerd
spec:
  concurrencyPolicy: Forbid
  schedule: {{ .Values.rotation.schedule }}
  jobTemplate:
    spec:
      backoffLimit: 0
      activeDeadlineSeconds: 600
      template:
        spec:
          serviceAccountName: rotator
          restartPolicy: Never
          activeDeadlineSeconds: 3600
          containers:
            - name: linkerd-cert-rotator
              image: {{ .Values.rotation.image }}:{{ .Values.rotation.tag }}
              imagePullPolicy: Always
              command: [ "sh", "-c" ]
              args:
              - "/scripts/rotation.sh >> /proc/1/fd/1 2>&1"
```

You then just need to add rotation.schedule, rotation.image, and rotation.tag to
the values depending on where you pushed your container to and what schedule you
want. I set these jobs to run once a month.

## Rotation Periods

We want our certificates to rotate every 30 days, with a significant buffer in
case our automation fails. To achieve this, I configure cert-manager to issue
certificates with a **duration of 120 days** and renew them after **60 days**.

This provides a **60-day window** to ensure both the Linkerd control plane and
all meshed pods are restarted to pick up the new certificates. If they aren’t
restarted within this window, the old certificates will expire, leading to
communication issues.

Using a CronJob, we enforce a certificate rotation every **30 days**. This keeps
our certificates fresh while providing a substantial buffer to handle any
automation issues before they cause problems. A great side benefit is the
ability to manually run the CronJob at any time to force an adhoc certificate
rotation.

## Improvements

As with any solution there is more I could do.

1. I would like to add automated checks to my shell script to verify when the
   cert has been updated instead of just sleeping for a period of time.
1. I would really like to add an automated check to validate the at the trust
   bundle was updated at the end
1. I would like to create a dashboard and some monitoring alerts to notify us
   about the age of these certs.

Did I miss any?

_Enjoyed the read? [Follow Matthew on Medium](https://medium.com/@mclanem_45809)
to keep up with his latest posts._
