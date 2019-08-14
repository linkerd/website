+++
title = "Generating certificates for Linkerd identity mTLS"
description = "How to generate certificates and keys needed for Linkerd to operate."
+++

In order to support [mTLS connections between meshed
pods](/2/features/automatic-mtls), Linkerd needs to be provided with a trust
anchor certificate and an issuer certificate with its corresponding key.

When using the CLI to install, you can provide these through the `--identity-*`
family of flags. If you don't provide them, Linkerd will generate them for you.

On the other hand when using Helm to install Linkerd, it's not possible to
automatically generate them and you're required to provide them.

You can generate these certificates using a tool like openssl or
[step](https://smallstep.com/cli/). Following are the instructions specific for
`step`.

## Generate the certificates with `step`

First generate the root certificate with its private key (using `step` version
0.10.1):

```bash
step certificate create identity.linkerd.cluster.local ca.crt ca.key --profile root-ca --no-password --insecure
```

This generates the `ca.crt` and `ca.key` files. The `ca.crt` file is what you
need to pass to the `--identity-trust-anchors-file` option when installing
Linkerd with the CLI, and the `Identity.TrustAnchorsPEM` value when installing
Linkerd with Helm.

Note we use `--no-password --insecure` to avoid encrypting those files with a
passphrase.

Then generate the intermediate certificate and key pair that will be used to
sign the Linkerd proxies' CSR.

```bash
step certificate create identity.linkerd.cluster.local issuer.crt issuer.key --ca ca.crt --ca-key ca.key --profile intermediate-ca --not-after 8760h --no-password --insecure
```

This will generate the `issuer.crt` and `issuer.key` files.

You can finally provide these files when installing Linkerd with the CLI:

```bash
linkerd install \
  --identity-trust-anchors-file ca.crt \
  --identity-issuer-certificate-file issuer.crt \
  --identity-issuer-key-file issuer.key \
  --identity-issuance-lifetime 8760h \
  | kubectl apply -f -
```

Or when installing with Helm:

```bash
helm install \
  --set-file Identity.TrustAnchorsPEM=ca.crt \
  --set-file Identity.Issuer.TLS.CrtPEM=issuer.crt \
  --set-file Identity.Issuer.TLS.KeyPEM=issuer.key \
  --set Identity.Issuer.CrtExpiry=$(date -d '+8760 hour' +"%Y-%m-%dT%H:%M:%SZ") \
  charts/linkerd2
```
