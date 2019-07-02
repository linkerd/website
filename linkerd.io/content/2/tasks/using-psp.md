+++
title = "Using PSP"
description = "Using Linkerd with pod security policy"
+++

The Linkerd control plane comes with its own minimally privileged [Pod Security Policy](https://kubernetes.io/docs/concepts/policy/pod-security-policy/) and the associated RBAC resources. This Pod Security Policy is enforced only if the `PodSecurityPolicy` admission controller is enabled.

To view the definition of the control plane's Pod Security Policy, run:
```bash
kubectl describe psp -l linkerd.io/control-plane-ns=linkerd
```
Adjust the value of the above label to match your control plane's namespace.

Note that in the CNI setup, the `NET_ADMIN` and `NET_RAW` capabilities are omitted from the `allowedCapabitilies` rules.

Linkerd doesn't provide any default Pod Security Policy for the data plane because the policies will vary depending on the security requirements of your application. The security context requirement for the Linkerd proxy sidecar container will be very similar to that defined in the control plane's Pod Security Policy.

For example, the following Pod Security Policy will work with the injected `emojivoto` demo application:
```yaml
cat <<EOF|k apply -f -
apiVersion: policy/v1beta1
kind: PodSecurityPolicy
metadata:
  name: linkerd-data-plane
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
EOF
```
Note that the Linkerd proxy only requires the `NET_ADMIN` and `NET_RAW` capabilities, and it's run with UID `2102`. The `NET_BIND_SERVICE` capability is needed by the `web` application because its container binds to port 80.
