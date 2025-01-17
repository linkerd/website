---
title: Linkerd and Pod Security Policies (PSP)
description: Using Linkerd with a pod security policies enabled.
---

[Pod Security Policies](https://kubernetes.io/docs/concepts/policy/pod-security-policy/)
have been deprecated in Kuberenetes v1.21 and removed in v1.25. However, for
users who still want them, the Linkerd control plane comes with its own
minimally privileged Pod Security Policy and the associated RBAC resources which
can be optionally created by setting the `--set enablePSP=true` flag during
Linkerd install or upgrade, or by using the `enablePSP` Helm value.
