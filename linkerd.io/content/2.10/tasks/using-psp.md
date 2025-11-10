---
title: Linkerd and Pod Security Policies (PSP)
description: Using Linkerd with a pod security policies enabled.
---

The Linkerd control plane comes with its own minimally privileged
[Pod Security Policy](https://kubernetes.io/docs/concepts/policy/pod-security-policy/)
and the associated RBAC resources. This Pod Security Policy is enforced only if
the `PodSecurityPolicy` admission controller is enabled.

To view the definition of the control plane's Pod Security Policy, run:

```bash
kubectl describe psp -l linkerd.io/control-plane-ns=linkerd
```

Adjust the value of the above label to match your control plane's namespace.

Notice that to minimize attack surface, all Linux capabilities are dropped from
the control plane's Pod Security Policy, with the exception of the `NET_ADMIN`
and `NET_RAW` capabilities. These capabilities provide the `proxy-init` init
container with runtime privilege to rewrite the pod's `iptable`. Note that
adding these capabilities to the Pod Security Policy doesn't make the container
a
[`privileged`](https://kubernetes.io/docs/concepts/workloads/pods/pod/#privileged-mode-for-pod-containers)
container. The control plane's Pod Security Policy prevents container privilege
escalation with the `allowPrivilegeEscalation: false` policy. To understand the
full implication of the `NET_ADMIN` and `NET_RAW` capabilities, refer to the
Linux capabilities
[manual](https://www.man7.org/linux/man-pages/man7/capabilities.7.html).

More information on the `iptables` rules used by the `proxy-init` init container
can be found on the [Architecture](../reference/architecture/#linkerd-init)
page.

If your environment disallows the operation of containers with escalated Linux
capabilities, Linkerd can be installed with its [CNI plugin](../features/cni/),
which doesn't require the `NET_ADMIN` and `NET_RAW` capabilities.

Linkerd doesn't provide any default Pod Security Policy for the data plane
because the policies will vary depending on the security requirements of your
application. The security context requirement for the Linkerd proxy sidecar
container will be very similar to that defined in the control plane's Pod
Security Policy.

For example, the following Pod Security Policy and RBAC will work with the
injected `emojivoto` demo application:

```yaml
apiVersion: policy/v1beta1
kind: PodSecurityPolicy
metadata:
  name: linkerd-emojivoto-data-plane
spec:
  allowPrivilegeEscalation: false
  fsGroup:
    ranges:
      - max: 65535
        min: 10001
    rule: MustRunAs
  readOnlyRootFilesystem: true
  allowedCapabilities:
    - NET_ADMIN
    - NET_RAW
    - NET_BIND_SERVICE
  requiredDropCapabilities:
    - ALL
  runAsUser:
    rule: RunAsAny
  seLinux:
    rule: RunAsAny
  supplementalGroups:
    ranges:
      - max: 65535
        min: 10001
    rule: MustRunAs
  volumes:
    - configMap
    - emptyDir
    - projected
    - secret
    - downwardAPI
    - persistentVolumeClaim
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: emojivoto-psp
  namespace: emojivoto
rules:
  - apiGroups: ["policy", "extensions"]
    resources: ["podsecuritypolicies"]
    verbs: ["use"]
    resourceNames: ["linkerd-emojivoto-data-plane"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: emojivoto-psp
  namespace: emojivoto
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: emojivoto-psp
subjects:
  - kind: ServiceAccount
    name: default
    namespace: emojivoto
  - kind: ServiceAccount
    name: emoji
    namespace: emojivoto
  - kind: ServiceAccount
    name: voting
    namespace: emojivoto
  - kind: ServiceAccount
    name: web
    namespace: emojivoto
```

Note that the Linkerd proxy only requires the `NET_ADMIN` and `NET_RAW`
capabilities when running without Linkerd CNI, and it's run with UID `2102`.
