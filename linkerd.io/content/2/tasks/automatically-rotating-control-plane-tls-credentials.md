+++
title = "Automatically Rotating Control Plane TLS Credentials"
description = "Use cert-manager to automatically rotate control plane TLS credentials"
aliases = [ "use_external_certs" ]
+++

Linkerd's [automatic mTLS](/2/features/automatic-mtls/) feature uses a set of
TLS credentials to generate TLS certificates for proxies: a trust anchor, and
an issuer certificate and private key. While Linkerd automatically rotates the
TLS certificates for data plane proxies every 24 hours, it does not rotate the
TLS credentials used to issue these certificate. In this doc, we'll describe
how to automatically rotate the issuer certificate and private key, by using
an external solution.

(Note that Linkerd's trust anchor [must still be manually
rotated](/2/tasks/manually-rotating-control-plane-tls-credentials/) on
long-lived clusters.)

## Cert manager

[Cert-manager](https://github.com/jetstack/cert-manager) is a popular project
for making TLS credentials from external sources available to Kubernetes
clusters.

As a first step, [install cert-manager on your
cluster](https://docs.cert-manager.io/en/latest/getting-started/install/kubernetes.html).

### Cert manager as an on-cluster CA

In this case, rather than pulling credentials from an external
source, we'll configure it to act as an on-cluster
[CA](https://en.wikipedia.org/wiki/Certificate_authority) and have it re-issue
Linkerd's issuer certificate and private key on a periodic basis.

First, create the namespace that cert-manager will use to store its
Linkerd-related resources. For simplicity, we suggest the default Linkerd
control plane namespace:

```bash
kubectl create namespace linkerd
```

#### Save the signing key pair as a Secret

Next, using the [`step`](https://smallstep.com/cli/) tool, create a signing key
pair and store it in a Kubernetes Secret in the namespace created above:

```bash
step certificate create identity.linkerd.cluster.local ca.crt ca.key \
  --profile root-ca --no-password --insecure &&
  kubectl create secret tls \
   linkerd-trust-anchor \
   --cert=ca.crt \
   --key=ca.key \
   --namespace=linkerd
```

For a longer-lived trust anchor certificate, pass the `--not-after` argument
to the step command with the desired value (e.g. `--not-after=87600h`).

#### Create an Issuer referencing the secret

With the Secret in place, we can create a cert-manager "Issuer" resource that
references it:

```bash
cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1alpha2
kind: Issuer
metadata:
  name: linkerd-trust-anchor
  namespace: linkerd
spec:
  ca:
    secretName: linkerd-trust-anchor
EOF
```

#### Issuing certificates and writing them to a secret

Finally, we can create a cert-manager "Certificate" resource which uses this
Issuer to generate the desired certificate:

```bash
cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1alpha2
kind: Certificate
metadata:
  name: linkerd-identity-issuer
  namespace: linkerd
spec:
  secretName: linkerd-identity-issuer
  duration: 24h
  renewBefore: 1h
  issuerRef:
    name: linkerd-trust-anchor
    kind: Issuer
  commonName: identity.linkerd.cluster.local
  isCA: true
  keyAlgorithm: ecdsa
  usages:
  - cert sign
  - crl sign
  - server auth
  - client auth
EOF
```

(In the YAML manifest above, the `duration` key instructs cert-manager to
consider certificates as valid for 24 hours and the `renewBefore` key indicates
that cert-manager will attempt to issue a new certificate one hour before
expiration of the current one. These values can be customized to your liking.)

At this point, cert-manager can now use this Certificate resource to obtain TLS
credentials, which will be stored in a secret named `linkerd-identity-issuer`.
To validate your newly-issued certificate, you can run:

```bash
kubectl get secret linkerd-identity-issuer -o yaml -n linkerd
```

Now we just need to inform Linkerd to consume these credentials.

### Alternative CA providers

Instead of using Cert Manager as CA, you can configure it to rely on a number
of other solutions such as [Vault](https://www.vaultproject.io). More detail on
how to setup the existing Cert Manager to use different type of issuers
can be found [here](https://cert-manager.io/docs/configuration/vault/).

## Third party cert management solutions

It is important to note that the mechanism that Linkerd provides is also
usable outside of cert-manager. Linkerd will read the `linkerd-identity-issuer`
Secret, and if it's of type `kubernetes.io/tls`, will use the contents as its
TLS credentials. This means that any solution that is able to rotate TLS
certificates by writing them to this secret can be used to provide dynamic
TLS certificate management.

## Using these credentials with CLI installation

For CLI installation, the Linkerd control plane should be installed with the
`--identity-external-issuer` flag, which instructs Linkerd to read certificates
from the `linkerd-identity-issuer` secret. Whenever certificate and key stored
in the secret are updated, the `identity` service will automatically detect
this change and reload the new credentials.

Voila! We have set up automatic rotation of Linkerd's control plane TLS
credentials. And if you want to monitor the update process, you can check the
`IssuerUpdated` events emitted by the service:

```bash
kubectl get events --field-selector reason=IssuerUpdated -n linkerd
```

## Installing with Helm

For Helm installation, rather than running `linkerd install`, set the
`global.identityTrustAnchorsPEM` to the value of `ca.crt` in the
`linkerd-identity-issuer` Secret:

```bash
helm install \
  linkerd2
  --set-file global.identityTrustAnchorsPEM=ca.crt \
  --set identity.issuer.scheme=kubernetes.io/tls \
  --set installNamespace=false \
  linkerd/linkerd2 \
  -n linkerd
```
