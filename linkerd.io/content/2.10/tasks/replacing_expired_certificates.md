---
title: Replacing expired certificates
description: Follow this workflow if any of your TLS certs have expired.
---

If any of your TLS certs are approaching expiry and you are not relying on an
external certificate management solution such as `cert-manager`, you can follow
[Rotating your identity certificates](manually-rotating-control-plane-tls-credentials/)
to update them without incurring downtime. In case you are in a situation where
any of your certs are expired however, you are already in an invalid state and
any measures to avoid downtime are not guaranteed to give results. Therefore it
is best to proceed with replacing the certificates with valid ones.

## Replacing only the issuer certificate

It might be the case that your issuer certificate is expired. If this it true
running `linkerd check --proxy` will produce output similar to:

```bash
linkerd-identity
----------------
√ certificate config is valid
√ trust roots are using supported crypto algorithm
√ trust roots are within their validity period
√ trust roots are valid for at least 60 days
√ issuer cert is using supported crypto algorithm
× issuer cert is within its validity period
    issuer certificate is not valid anymore. Expired on 2019-12-19T09:21:08Z
    see https://linkerd.io/2/checks/#l5d-identity-issuer-cert-is-time-valid for hints
```

In this situation, if you have installed Linkerd with a manually supplied trust
root and you have its key, you can follow
[Updating the identity issuer certificate](manually-rotating-control-plane-tls-credentials/#rotating-the-identity-issuer-certificate)
to update your expired cert.

## Replacing the root and issuer certificates

If your root certificate is expired or you do not have its key, you need to
replace both your root and issuer certificates at the same time. If your root
has expired `linkerd check` will indicate that by outputting an error similar
to:

```bash
linkerd-identity
----------------
√ certificate config is valid
√ trust roots are using supported crypto algorithm
× trust roots are within their validity period
    Invalid roots:
        * 272080721524060688352608293567629376512 identity.linkerd.cluster.local not valid anymore. Expired on 2019-12-19T10:05:31Z
    see https://linkerd.io/2/checks/#l5d-identity-roots-are-time-valid for hints
```

You can follow
[Generating your own mTLS root certificates](generate-certificates/#generating-the-certificates-with-step)
to create new root and issuer certificates. Then use the `linkerd upgrade`
command:

```bash
linkerd upgrade \
    --identity-issuer-certificate-file=./issuer-new.crt \
    --identity-issuer-key-file=./issuer-new.key \
    --identity-trust-anchors-file=./ca-new.crt \
    --force \
    | kubectl apply -f -
```

Usually `upgrade` will prevent you from using an issuer certificate that will
not work with the roots your meshed pods are using. At that point we do not need
this check as we are updating both the root and issuer certs at the same time.
Therefore we use the `--force` flag to ignore this error.

If you run `linkerd check --proxy` you might see some warning, while the upgrade
process is being performed:

```bash
linkerd-identity
----------------
√ certificate config is valid
√ trust roots are using supported crypto algorithm
√ trust roots are within their validity period
√ trust roots are valid for at least 60 days
√ issuer cert is using supported crypto algorithm
√ issuer cert is within its validity period
√ issuer cert is valid for at least 60 days
√ issuer cert is issued by the trust root

linkerd-identity-data-plane
---------------------------
‼ data plane proxies certificate match CA
    Some pods do not have the current trust bundle and must be restarted:
        * linkerd/linkerd-controller-5b69fd4fcc-7skqb
        * linkerd/linkerd-destination-749df5c74-brchg
        * linkerd/linkerd-grafana-6dcf86b74b-vvxjq
        * linkerd/linkerd-prometheus-74cb4f4b69-kqtss
        * linkerd/linkerd-proxy-injector-cbd5545bd-rblq5
        * linkerd/linkerd-sp-validator-6ff949649f-gjgfl
        * linkerd/linkerd-tap-7b5bb954b6-zl9w6
        * linkerd/linkerd-web-84c555f78-v7t44
    see https://linkerd.io/2/checks/#l5d-identity-data-plane-proxies-certs-match-ca for hints

```

Additionally you can use the `kubectl rollout restart` command to bring the
configuration of your other injected resources up to date, and then the `check`
command should stop producing warning or errors:

```bash
linkerd-identity
----------------
√ certificate config is valid
√ trust roots are using supported crypto algorithm
√ trust roots are within their validity period
√ trust roots are valid for at least 60 days
√ issuer cert is using supported crypto algorithm
√ issuer cert is within its validity period
√ issuer cert is valid for at least 60 days
√ issuer cert is issued by the trust root

linkerd-identity-data-plane
---------------------------
√ data plane proxies certificate match CA
```
