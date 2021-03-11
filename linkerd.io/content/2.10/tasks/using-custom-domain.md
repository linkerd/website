+++
title = "Using a Custom Cluster Domain"
description = "Use Linkerd with a custom cluster domain."
+++

For Kubernetes clusters that use [custom cluster domain](https://kubernetes.io/docs/tasks/administer-cluster/dns-custom-nameservers/),
Linkerd must be installed using the `--cluster-domain` option:

```bash
linkerd install --cluster-domain=example.org \
    --identity-trust-domain=example.org \
    | kubectl apply -f -

# The Linkerd Viz extension also requires a similar setting:
linkerd viz install --set clusterDomain=example.org | kubectl apply -f -

# And so does the Multicluster extension:
linkerd multicluster install --set identityTrustDomain=example.org | kubectl apply -f -
```

This ensures that all Linkerd handles all service discovery, routing, service
profiles and traffic split resources using the `example.org` domain.

{{< note >}}
Note that the identity trust domain must match the cluster domain for mTLS to
work.
{{< /note >}}

{{< note >}}
Changing the cluster domain while upgrading Linkerd isn't supported.
{{< /note >}}
