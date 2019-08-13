+++
title = "Generating certificates for Linkerd identity"
description = "How to generate certificates and keys needed for Linkerd to operate."
+++

In order to support [mTLS connections between meshed
pods](/2/features/automatic-mtls), Linkerd needs to be provided with a trust
anchor certificate and an issuer certificate with its corresponding key.

When using the CLI to install, you can provide these through the `--indentity-*`
family of flags. If you don't provide them, Linkerd will generate them for you.

On the other hand when using Helm to install Linkerd, it's not
possible to automatically generate them and you're forced to provide them.

You can generate these certificates using a tool like openssl or
[step](https://smallstep.com/cli/). Following are the instructions specific for
`step`.

## Generate the certificates with `step`

First generate the root certificate with its private key:

```bash
step certificate create identity.linkerd.cluster.local ca.crt ca.key --profile root-ca --no-password --insecure
```

This generates the `ca.crt` and `ca.key` files. The `ca.crt` file is what you
need to pass to the `--identity-trust-anchors-file` option when installing
Linkerd with the CLI, and the `Identity.TrustAnchorsPEM` value when installing
Linkerd with Helm.

Note we use `--no-password --insecure` to avoid encrypting those files with a
passphrase.

Then generate the intermediate certificate and key that the Linkerd proxies will
rely on to generate a different certificate for each service:

```bash
step certificate create identity.linkerd.cluster.local issuer.crt issuer.key --ca ca.crt --ca-key ca.key --profile intermediate-ca --not-after 2020-10-02T10:00:00Z --no-password --insecure
```

This will generate the `issuer.crt` and `issuer.key` files.

These are the files you need to pass to the `--identity-issuer-certificate-file`
and `--identity-issuer-key-file` options when installing Linkerd with the CLI,
and the `Identity.Issuer.TLS.CrtPEM` and `Identity.Issuer.TLS.KeyPEM` values
when installing Linkerd with Helm.

Also, when installing with the CLI you need to pass to the
`--identity-issuance-lifetime` option a value corresponding to what you used in
`--not-after` above, and when installing with Helm you'll pass the same value to
`Identity.Issuer.CrtExpiry`. Note that the expiration time (`--not-after`) should
be in RFC-3339 format.
