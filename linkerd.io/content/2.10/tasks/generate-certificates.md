+++
title = "Generating your own mTLS root certificates"
description = "Generate your own mTLS root certificate instead of letting Linkerd do it for you."
+++

In order to support [mTLS connections between meshed
pods](../../features/automatic-mtls/), Linkerd needs a trust anchor certificate and
an issuer certificate with its corresponding key.

When installing with `linkerd install`, these certificates are automatically
generated. Alternatively, you can specify your own with the `--identity-*` flags
(see the [linkerd install reference](../../reference/cli/install/)).

On the other hand when using Helm to install Linkerd, it's not possible to
automatically generate them and you're required to provide them.

You can generate these certificates using a tool like openssl or
[step](https://smallstep.com/cli/). All certificates must use the ECDSA P-256
algorithm which is the default for `step`. To generate ECDSA P-256 certificates
with openssl, you can use the `openssl ecparam -name prime256v1` command. In
this tutorial, we'll walk you through how to to use the `step` CLI to do this.

{{< trylpt >}}

## Generating the certificates with `step`

### Trust anchor certificate

First generate the root certificate with its private key (using `step` version
0.10.1):

```bash
step certificate create root.linkerd.cluster.local ca.crt ca.key \
--profile root-ca --no-password --insecure
```

This generates the `ca.crt` and `ca.key` files. The `ca.crt` file is what you
need to pass to the `--identity-trust-anchors-file` option when installing
Linkerd with the CLI, and the `identityTrustAnchorsPEM` value when installing
Linkerd with Helm.

Note we use `--no-password --insecure` to avoid encrypting those files with a
passphrase.

For a longer-lived trust anchor certificate, pass the `--not-after` argument
to the step command with the desired value (e.g. `--not-after=87600h`).

### Issuer certificate and key

Then generate the intermediate certificate and key pair that will be used to
sign the Linkerd proxies' CSR.

```bash
step certificate create identity.linkerd.cluster.local issuer.crt issuer.key \
--profile intermediate-ca --not-after 8760h --no-password --insecure \
--ca ca.crt --ca-key ca.key
```

This will generate the `issuer.crt` and `issuer.key` files.

## Passing the certificates to Linkerd

You can finally provide these files when installing Linkerd with the CLI:

```bash
linkerd install \
  --identity-trust-anchors-file ca.crt \
  --identity-issuer-certificate-file issuer.crt \
  --identity-issuer-key-file issuer.key \
  | kubectl apply -f -
```

Or when installing with Helm:

```bash
helm install linkerd2 \
  --set-file identityTrustAnchorsPEM=ca.crt \
  --set-file identity.issuer.tls.crtPEM=issuer.crt \
  --set-file identity.issuer.tls.keyPEM=issuer.key \
  --set identity.issuer.crtExpiry=$(date -d '+8760 hour' +"%Y-%m-%dT%H:%M:%SZ") \
  linkerd/linkerd2
```

{{< note >}}
For Helm versions < v3, `--name` flag has to specifically be passed.
In Helm v3, It has been deprecated, and is the first argument as
 specified above.
{{< /note >}}
