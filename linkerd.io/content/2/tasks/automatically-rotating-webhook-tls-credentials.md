+++
title = "Automatically Rotating Webhook TLS Credentials"
description = "Use cert-manager to automatically rotate webhook TLS credentials."
+++

The Linkerd control plane contains several components, called webhooks, which
are called directly by Kubernetes itself.  The traffic from Kubernetes to the
Linkerd webhooks is secured with TLS and therefore each of the webhooks requires
a secret containing TLS credentials.  These certificates are different from the
ones that the Linkerd proxies use to secure pod-to-pod communication and use a
completely separate trust chain.  For more information on rotating the TLS
credentials used by the Linkerd proxies, see
[Automatically Rotating Control Plane TLS Credentials](/2/tasks/use_external_certs/).

By default, when Linkerd is installed
with the Linkerd CLI or with the Linkerd Helm chart, TLS credentials are
automatically generated for all of the webhooks.  If these certificates expire
or need to be regenerated for any reason, performing a
[Linkerd upgrade](/2/tasks/upgrade/) (using the Linkerd CLI or using Helm) will
regenerate them.

This workflow is suitable for most users.  However, if you need these webhook
certificates to be rotated automatically on a regular basis, it is possible to
use cert-manager to automatically manage them.

## Install Cert manager

As a first step, [install cert-manager on your
cluster](https://docs.cert-manager.io/en/latest/getting-started/install/kubernetes.html)
and create  the namespace that cert-manager will use to store its
webhook-related resources. For simplicity, we suggest the default Linkerd
control plane namespace:

```bash
kubectl create namespace linkerd
```

## Save the signing key pair as a Secret

Next, we will use the [`step`](https://smallstep.com/cli/) tool, to create a
signing key pair which will be used to sign each of the webhook certificates:

```bash
step certificate create webhook.linkerd.cluster.local ca.crt ca.key \
  --profile root-ca --no-password --insecure --san webhook.linkerd.cluster.local &&
  kubectl create secret tls \
    webhook-issuer-tls \
    --cert=ca.crt \
    --key=ca.key \
    --namespace=linkerd
```

## Create an Issuer referencing the secret

With the Secret in place, we can create a cert-manager "Issuer" resource that
references it:

```bash
cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: webhook-issuer
  namespace: linkerd
spec:
  ca:
    secretName: webhook-issuer-tls
EOF
```

## Issuing certificates and writing them to a secret

Finally, we can create cert-manager "Certificate" resources which use the
Issuer to generate the desired certificates:

```bash
cat <<EOF | kubectl apply -f -
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
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: linkerd-tap
  namespace: linkerd
spec:
  secretName: linkerd-tap-k8s-tls
  duration: 24h
  renewBefore: 1h
  issuerRef:
    name: webhook-issuer
    kind: Issuer
  commonName: linkerd-tap.linkerd.svc
  dnsNames:
  - linkerd-tap.linkerd.svc
  isCA: false
  privateKey:
    algorithm: ECDSA
  usages:
  - server auth
EOF
```

At this point, cert-manager can now use these Certificate resources to obtain TLS
credentials, which are stored in the  `linkerd-proxy-injector-k8s-tls`,
`linkerd-sp-validator-k8s-tls`, and `linkerd-tap-k8s-tls` secrets respectively.

Now we just need to inform Linkerd to consume these credentials.

## Using these credentials with CLI installation

To configure Linkerd to use the credentials from cert-manager rather than
generating its own, we generate a supplemental config file:

```bash
CA=$(awk '{ print "    " $0 }' ca.crt); cat > config.yml <<EOF
proxyInjector:
  externalSecret: true
  caBundle: |
$CA
profileValidator:
  externalSecret: true
  caBundle: |
$CA
tap:
  externalSecret: true
  caBundle: |
$CA
EOF
```

Now we can install Linkerd using this config file:

```bash
linkerd install --config=config.yml | kubectl apply -f -
```

## Installing with Helm

For Helm installation, we can configure the Helm values directly:

```bash
helm install linkerd2 \
  --set installNamespace=false \
  --set proxyInjector.externalSecret=true \
  --set-file proxyInjector.caBundle=ca.crt \
  --set profileValidator.externalSecret=true \
  --set-file profileValidator.caBundle=ca.crt \
  --set tap.externalSecret=true \
  --set-file tap.caBundle=ca.crt \
  linkerd/linkerd2 \
  -n linkerd
```

{{< note >}}
When installing Linkerd with Helm, you must also provide the issuer trust root
and issuer credentials as described in [Installing Linkerd with Helm](/2/tasks/install-helm/).
{{< /note >}}

{{< note >}}
For Helm versions < v3, `--name` flag has to specifically be passed.
In Helm v3, It has been deprecated, and is the first argument as
 specified above.
{{< /note >}}

See [Automatically Rotating Control Plane TLS
Credentials](/2/tasks/automatically-rotating-control-plane-tls-credentials/)
for details on how to do something similar for control plane credentials.
