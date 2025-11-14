---
title: Control Plane Port Names
description: Reference guide to Linkerd control plane port names.
---

Linkerd's control plane components expose various ports for communication and
administration. Each container port is assigned a unique name to enable precise
references from Services, probes, and monitoring configurations.

## Control Plane Port Names

The following table lists control plane container port names:

{{< keyval >}}

| Component         | Port Name        | Protocol |
| ----------------- | ---------------- | -------- |
| destination       | `dest-grpc`      | gRPC     |
| destination       | `dest-admin`     | HTTP     |
| sp-validator      | `spval-admin`    | HTTP     |
| policy-controller | `policy-grpc`    | gRPC     |
| policy-controller | `policy-admin`   | HTTP     |
| identity          | `ident-grpc`     | gRPC     |
| identity          | `ident-admin`    | HTTP     |
| proxy-injector    | `injector-admin` | HTTP     |
| linkerd2-cni      | `repair-admin`   | HTTP     |

{{< /keyval >}}
