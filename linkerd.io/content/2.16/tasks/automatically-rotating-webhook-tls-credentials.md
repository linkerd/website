---
title: Automatically Rotating Webhook TLS Credentials
description: Use cert-manager to automatically rotate webhook TLS credentials.
---

The Linkerd control plane contains several components, called webhooks, which
are called directly by Kubernetes itself.  The traffic from Kubernetes to the
Linkerd webhooks is secured with TLS and therefore each of the webhooks requires
a secret containing TLS credentials.  These certificates are different from the
ones that the Linkerd proxies use to secure pod-to-pod communication and use a
completely separate trust chain.  For more information on rotating the TLS
credentials used by the Linkerd proxies, see
[Automatically Rotating Control Plane TLS Credentials](../automatically-rotating-control-plane-tls-credentials/).

By default, when Linkerd is installed
with the Linkerd CLI or with the Linkerd Helm chart, TLS credentials are
automatically generated for all of the webhooks.  If these certificates expire
or need to be regenerated for any reason, performing a
[Linkerd upgrade](../upgrade/) (using the Linkerd CLI or using Helm) will
regenerate them.

This workflow is suitable for most users.  However, if you need these webhook
certificates to be rotated automatically on a regular basis, it is possible to
use cert-manager to automatically manage them.

{{< docs/production-note >}}

## Install Cert manager

As a first step, [install cert-manager on your
cluster](https://cert-manager.io/docs/installation/)
and create  the namespaces that cert-manager will use to store its
webhook-related resources. For simplicity, we suggest using the default
namespace linkerd uses:

```bash
# control plane core
kubectl create namespace linkerd
kubectl label namespace linkerd \
  linkerd.io/is-control-plane=true \
  config.linkerd.io/admission-webhooks=disabled \
  linkerd.io/control-plane-ns=linkerd
kubectl annotate namespace linkerd linkerd.io/inject=disabled

# viz (ignore if not using the viz extension)
kubectl create namespace linkerd-viz
kubectl label namespace linkerd-viz linkerd.io/extension=viz

# jaeger (ignore if not using the jaeger extension)
kubectl create namespace linkerd-jaeger
kubectl label namespace linkerd-jaeger linkerd.io/extension=jaeger
```

## Save the signing key pair as a Secret

Next, we will use the [`step`](https://smallstep.com/cli/) tool, to create a
signing key pair which will be used to sign each of the webhook certificates:

```bash
step certificate create webhook.linkerd.cluster.local ca.crt ca.key \
  --profile root-ca --no-password --insecure --san webhook.linkerd.cluster.local

kubectl create secret tls webhook-issuer-tls --cert=ca.crt --key=ca.key --namespace=linkerd

# ignore if not using the viz extension
kubectl create secret tls webhook-issuer-tls --cert=ca.crt --key=ca.key --namespace=linkerd-viz

# ignore if not using the jaeger extension
kubectl create secret tls webhook-issuer-tls --cert=ca.crt --key=ca.key --namespace=linkerd-jaeger
```

## Create Issuers referencing the secrets

With the Secrets in place, we can create cert-manager "Issuer" resources that
reference them:

```bash
kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: webhook-issuer
  namespace: linkerd
spec:
  ca:
    secretName: webhook-issuer-tls
---
# ignore if not using the viz extension
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: webhook-issuer
  namespace: linkerd-viz
spec:
  ca:
    secretName: webhook-issuer-tls
---
# ignore if not using the jaeger extension
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: webhook-issuer
  namespace: linkerd-jaeger
spec:
  ca:
    secretName: webhook-issuer-tls
EOF
```

## Issuing certificates and writing them to secrets

Finally, we can create cert-manager "Certificate" resources which use the
Issuers to generate the desired certificates:

```bash
kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: linkerd-policy-validator
  namespace: linkerd
spec:
  secretName: linkerd-policy-validator-k8s-tls
  duration: 24h
  renewBefore: 1h
  issuerRef:
    name: webhook-issuer
    kind: Issuer
  commonName: linkerd-policy-validator.linkerd.svc
  dnsNames:
  - linkerd-policy-validator.linkerd.svc
  isCA: false
  privateKey:
    algorithm: ECDSA
    encoding: PKCS8
  usages:
  - server auth
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: linkerd-proxy-injector
  namespace: linkerd
spec:
  secretName: linkerd-proxy-injector-k8s-tls
  duration: 24h
  renewBefore: 1h
  issuerRef:
    name: webhook-issuer
    kind: Issuer
  commonName: linkerd-proxy-injector.linkerd.svc
  dnsNames:
  - linkerd-proxy-injector.linkerd.svc
  isCA: false
  privateKey:
    algorithm: ECDSA
  usages:
  - server auth
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: linkerd-sp-validator
  namespace: linkerd
spec:
  secretName: linkerd-sp-validator-k8s-tls
  duration: 24h
  renewBefore: 1h
  issuerRef:
    name: webhook-issuer
    kind: Issuer
  commonName: linkerd-sp-validator.linkerd.svc
  dnsNames:
  - linkerd-sp-validator.linkerd.svc
  isCA: false
  privateKey:
    algorithm: ECDSA
  usages:
  - server auth
---
# ignore if not using the viz extension
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: tap
  namespace: linkerd-viz
spec:
  secretName: tap-k8s-tls
  duration: 24h
  renewBefore: 1h
  issuerRef:
    name: webhook-issuer
    kind: Issuer
  commonName: tap.linkerd-viz.svc
  dnsNames:
  - tap.linkerd-viz.svc
  isCA: false
  privateKey:
    algorithm: ECDSA
  usages:
  - server auth
---
# ignore if not using the viz extension
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: linkerd-tap-injector
  namespace: linkerd-viz
spec:
  secretName: tap-injector-k8s-tls
  duration: 24h
  renewBefore: 1h
  issuerRef:
    name: webhook-issuer
    kind: Issuer
  commonName: tap-injector.linkerd-viz.svc
  dnsNames:
  - tap-injector.linkerd-viz.svc
  isCA: false
  privateKey:
    algorithm: ECDSA
  usages:
  - server auth
---
# ignore if not using the jaeger extension
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: jaeger-injector
  namespace: linkerd-jaeger
spec:
  secretName: jaeger-injector-k8s-tls
  duration: 24h
  renewBefore: 1h
  issuerRef:
    name: webhook-issuer
    kind: Issuer
  commonName: jaeger-injector.linkerd-jaeger.svc
  dnsNames:
  - jaeger-injector.linkerd-jaeger.svc
  isCA: false
  privateKey:
    algorithm: ECDSA
  usages:
  - server auth
EOF
```

At this point, cert-manager can now use these Certificate resources to obtain
TLS credentials, which are stored in the  `linkerd-proxy-injector-k8s-tls`,
`linkerd-sp-validator-k8s-tls`, `tap-k8s-tls`, `tap-injector-k8s-tls` and
`jaeger-injector-k8s-tls` secrets respectively.

Now we just need to inform Linkerd to consume these credentials.

## Using these credentials with CLI installation

To configure Linkerd to use the credentials from cert-manager rather than
generating its own:

```bash
# first, install the Linkerd CRDs
linkerd install --crds | kubectl apply -f -

# install the Linkerd control plane, using the credentials
# from cert-manager
linkerd install \
  --set policyValidator.externalSecret=true \
  --set-file policyValidator.caBundle=ca.crt \
  --set proxyInjector.externalSecret=true \
  --set-file proxyInjector.caBundle=ca.crt \
  --set profileValidator.externalSecret=true \
  --set-file profileValidator.caBundle=ca.crt \
  | kubectl apply -f -

# ignore if not using the viz extension
linkerd viz install \
  --set tap.externalSecret=true \
  --set-file tap.caBundle=ca.crt \
  --set tapInjector.externalSecret=true \
  --set-file tapInjector.caBundle=ca.crt \
  | kubectl apply -f -

# ignore if not using the jaeger extension
linkerd jaeger install
  --set webhook.externalSecret=true \
  --set-file webhook.caBundle=ca.crt \
  | kubectl apply -f -
```

## Installing with Helm

A similar pattern can be used with Helm:

```bash
# first install the linkerd-crds chart
helm install linkerd-crds linkerd/linkerd-crds \
  -n linkerd --create-namespace

# then install the linkerd-control-plane chart
# (see note below)
helm install linkerd-control-plane \
  --set-file identityTrustAnchorsPEM=... \
  --set-file identity.issuer.tls.crtPEM=... \
  --set-file identity.issuer.tls.keyPEM=... \
  --set policyValidator.externalSecret=true \
  --set-file policyValidator.caBundle=ca.crt \
  --set proxyInjector.externalSecret=true \
  --set-file proxyInjector.caBundle=ca.crt \
  --set profileValidator.externalSecret=true \
  --set-file profileValidator.caBundle=ca.crt \
  linkerd/linkerd-control-plane \
  -n linkerd

# ignore if not using the viz extension
helm install linkerd-viz \
  --set tap.externalSecret=true \
  --set-file tap.caBundle=ca.crt \
  --set tapInjector.externalSecret=true \
  --set-file tapInjector.caBundle=ca.crt \
  linkerd/linkerd-viz \
  -n linkerd-viz --create-namespace

# ignore if not using the jaeger extension
helm install linkerd-jaeger \
  --set webhook.externalSecret=true \
  --set-file webhook.caBundle=ca.crt \
  linkerd/linkerd-jaeger \
  -n linkerd-jaeger --create-namespace
```

{{< note >}}
When installing the `linkerd-control-plane` chart, you _must_ provide the
issuer trust root and issuer credentials as described in [Installing Linkerd
with Helm](../install-helm/).
{{< /note >}}

See [Automatically Rotating Control Plane TLS
Credentials](../automatically-rotating-control-plane-tls-credentials/)
for details on how to do something similar for control plane credentials.
