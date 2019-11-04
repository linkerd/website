+++
title = "Using external issuer certificates"
description = "Make use of automatically rotated issuer certificates with the help of cert-manager"
+++

As already explained in the
[Automatic mTLS](/2/features/automatic-mtls/#how-does-it-work) section, Linkerd
stores the trust root, certificate and private key in a Kubernetes secret.
The contents of this secret are used by the Identity service to serve the
[certificate signing requests (CSR)](https://en.wikipedia.org/wiki/Certificate_signing_request)
that are issued by the proxy. The trust root, certificates and private key
can either be generated automatically by the CLI upon installation or can
be supplied by the user. If the latter is true, the necessity for providing
the user with more control over the life cycle of these credential arises.
In order to do that Linkerd provides functionality to read and continuously
monitor Kubernetes secrets for certificates change and to update the issuer
certificates of the Identity service dynamically. In the following lines,
we will demonstrate how this allows integration with an external certificate
management solution such as
[cert-manager](https://github.com/jetstack/cert-manager).

## Prerequisites

You need to have cert-manager installed and running on your cluster. This
is the software that will take care of creating and updating the certificates
and writing them into a secret of your choice. In order to install that on your
cluster follow the
[Installing on Kubernetes](https://docs.cert-manager.io/en/latest/getting-started/install/kubernetes.html)
section of the docs. You also need to have a signing key pair that will be used
by the cert manager Issuer to generate signed certificates.

## Create the namespace that Linkerd will reside in

As cert-manager issuers are namespace based, the `linkerd` namespace needs to
exist beforehand. This is where the rest of the cert-manager specific to
Linkerd (but not part of its installation) resources need to live. For that
purpose you can execute the following command:

```bash
kubectl create namespace linkerd
```

## Save the signing key pair as a Secret

To allow the Issuer to reference the signing key pair, it needs to be stored in
a Kubernetes secret, created in the `linkerd` namespace. Lets name it
`linkerd-trust-anchor`.

```bash
kubectl create secret tls \
   linkerd-trust-anchor \
   --cert=<path-to-cert> \
   --key=<path-to-key> \
   --namespace=linkerd
```

## Create an Issuer referencing the secret

Now that we have the secret in place, we can create an Issuer that
references it:

```yaml
apiVersion: cert-manager.io/v1alpha2
kind: Issuer
metadata:
  name: linkerd-trust-anchor
  namespace: linkerd
spec:
  ca:
    secretName: linkerd-trust-anchor
```

## Issuing certificates and writing them to a secret

We can now create a Certificate resource which will specify the desired
certificate:

```yaml
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
```

Once this resource is in place cert-manager will attempt to use it to obtain
a certificate. If successful this operation will result in the certificate
being stored in a secret named `linkerd-identity-issuer`. This certificate will
be valid for 24 hours as specified by the `duration` key. The `renewBefore` key
indicates that cert-manager will attempt to issue a new certificate one hour
before expiration of the current one. In order to see your newly issued
certificate, you can execute:

```bash
kubectl get secret linkerd-identity-issuer -o yaml -n linkerd
```

## Using the certificate in Linkerd

In order to use the externally managed certificates you need to install Linkerd
with the `--external-issuer=true` flag. Upon installation instead of generating
the trust root and certificates or reading them from a file, the CLI will fetch
them from the `linkerd-identity-issuer` secret. Furthermore, whenever
cert-manager updates the certificate and key stored in the secret, the
Identity service will automatically detect this change and reload the newly
created credentials. In order to monitor this process you can check the
`IssuerUpdated`events emitted by the service:

```bash
kubectl get events --field-selector reason=IssuerUpdated -n linkerd
```

Alternativelly if you want to install through helm, what you need to do is
simply supply the trust root that is in your linkerd-identitiy-issuer sercret:

```bash
helm install \
  --name=linkerd2 \
  --set-file Identity.TrustAnchorsPEM=<your-trust-roots> \
  --set Identity.Issuer.Scheme=kubernetes.io/tls \
  linkerd/linkerd2
```

{{< note >}}
Its important that Identity.TrustAnchorsPEM matches the value of `ca.crt` in your
linkerd-identitiy-issuer secret
{{< /note >}}
