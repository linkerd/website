+++
title = "Replacing expired certificates"
description = "Follow this workflow if any of your TLS certs have expired."
+++

If any of your TLS certs are approaching expiry and you are not relying on an
external certificate management solution such as `cert-manager`, you can follow
[Manually Rotating Control Plane TLS Credentials](../rotating_identity_certificates/)
to update them without incurring downtime. However, if any of your certificates
have already expired, your mesh is already in an invalid state and any measures
to avoid downtime are not guaranteed to give good results. Instead, you need to
replace the expired certificates with valid certificates.

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
    see https://linkerd.io/checks/#l5d-identity-issuer-cert-is-time-valid for hints
```

In this situation, if you have installed Linkerd with a manually supplied trust
root and you have its key, you can follow the instructions to
[rotate your identity issuer certificate](../manually-rotating-control-plane-tls-credentials/#rotating-the-identity-issuer-certificate)
to update your expired certificate.

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
    see https://linkerd.io/checks/#l5d-identity-roots-are-time-valid for hints
```

You can follow [Generating your own mTLS root certificates](../generate-certificates/#generating-the-certificates-with-step)
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

Usually `upgrade` will prevent you from using an issuer certificate that
will not work with the roots your meshed pods are using. At that point we
do not need this check as we are updating both the root and issuer certs at
the same time. Therefore we use the `--force` flag to ignore this error.

Once this is done, you'll need to explicitly restart the control plane so that
everything in the control plane is configured to use the new trust anchor:

```bash
kubectl rollout restart -n linkerd deploy
```

If you run `linkerd check --proxy` before the restart is completed, you will
probably see warnings about pods not having the current trust bundle:

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
    see https://linkerd.io/checks/#l5d-identity-data-plane-proxies-certs-match-ca for hints

```

These warnings should disappear once the restart is completed. Once they do,
you can use `kubectl rollout restart` to restart your meshed workloads to
bring their configuration up to date. After that is done, `linkerd check`
should run with no warnings or errors:

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
