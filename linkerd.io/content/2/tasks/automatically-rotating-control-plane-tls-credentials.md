+++
title = "Automatically Rotating Control Plane TLS Credentials"
description = "Use cert-manager to automatically rotate control plane TLS credentials"
aliases = [ "use_external_certs" ]
+++

Linkerd's [automatic mTLS](/2/features/automatic-mtls/) uses a set of TLS
credentials stored in the control plane to generate TLS certs for proxies. For
simplicity, by default, these credentials are generated once at install time
and are not rotated (though they can be [manually
rotated](/2/tasks/manually-rotating-control-plane-tls-credentials/)). In this doc,
we'll describe how to automatically rotate these credentials by using the
*cert-manager* project.

## Installing cert-manager and create the Linkerd namespace

[Cert-manager](https://github.com/jetstack/cert-manager) is a popular project
for making TLS credentials from external sources available to Kubernetes
clusters. In this case, we'll configure it to act as an on-cluster
[CA](https://en.wikipedia.org/wiki/Certificate_authority) and have it re-issue
Linkerd's control plane credentials on a regular basis.

As a first step, [install cert-manager on your
cluster](https://docs.cert-manager.io/en/latest/getting-started/install/kubernetes.html).

Next, create the namespace that cert-manager will use store its Linkerd-related
resources. For simplicity, we suggest the default Linkerd control plane
namespace:

```bash
kubectl create namespace linkerd
```

## Save the signing key pair as a Secret

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

## Create an Issuer referencing the secret

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

## Issuing certificates and writing them to a secret

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

## Using these credentials with CLI installation

For CLI installation, the Linkerd control plane should be installed with the
`--identity-external-issuer` flag, which instructs Linkerd to read certificates
from the `linkerd-identity-issuer` secret. Whenever cert-manager updates the
certificate and key stored in the secret, the `identity` service will
automatically detect this change and reload the newly created credentials.

Voila! We have set up automatic rotation of Linkerd's control plane TLS
credentials. And if you want to monitor the update process, you can check the
`IssuerUpdated` events emitted by the service:

```bash
kubectl get events --field-selector reason=IssuerUpdated -n linkerd
```

{{< note >}}
This mechanism is also usable outside of cert-manager. Linkerd will read the
`linkerd-identity-issuer` Secret, and if it's of type `kubernetes.io/tls`, will
use the contents as its TLS credentials.  This allows for the use of other
certificate management solutions such as [Vault](https://www.vaultproject.io).
{{< /note >}}

## Installing with Helm

For Helm installation, rather than running `linkerd install`, set the
`global.identityTrustAnchorsPEM` to the value of `ca.crt` in the
`linkerd-identity-issuer` Secret:

```bash
helm install \
  --name=linkerd2 \
  --set-file global.identityTrustAnchorsPEM=<value of ca.crt> \
  --set identity.issuer.scheme=kubernetes.io/tls \
  --set installNamespace=false \
  linkerd/linkerd2
```
