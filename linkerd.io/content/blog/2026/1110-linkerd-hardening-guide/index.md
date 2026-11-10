---
date: 2026-11-10T00:00:00Z
title: |-
  What an Independent Threat Model Found in Linkerd, and What You Should Do Next
description: |-
  A summary of ControlPlane’s independent threat model research into Linkerd with recommended configurations changes that can mitigate the threats.
keywords:
  [linkerd, security, threat model, hardening, mtls, multicluster, kubernetes]
params:
  author: sanjot
  showCover: true
images: [social.png] # Open graph image
---

Earlier this year, [ControlPlane](https://control-plane.io/), a cloud native
security consultancy, decided to build a threat model of open source Linkerd on
their own volition. They tried to anticipate every way an attacker or a bad
configuration could undermine it, and shared the results with our team as
creators of Linkerd, before publishing this for anyone to read. In this blog, I
will summarize the findings and share actions you can take right now. The full
report can be found here →
[Linkerd Threat Model and End-User Hardening Guide](Linkerd-Threat-Model-and-End-User-Hardening-Guide-2027.pdf)

## Overview

The ControlPlane review covers the parts of Linkerd that most users run i.e.
[the control plane, the data plane](/docs/reference/architecture/) proxies and
how Linkerd connects traffic between clusters. ControlPlane typically works with
regulated organizations, especially financial institutions, and the guide
reflects that. Every threat is mapped to
[MITRE ATT&CK](https://attack.mitre.org/) and
[NIST 800-53,](https://csrc.nist.gov/pubs/sp/800/53/r5/upd1/final) the
frameworks security and audit teams use.

It should be noted that the authors clearly state their evaluation did not
include penetration testing or code audits. It focuses on specific deployment
related risks and mitigation.

## What ControlPlane discovered

The guide lists 30 threats (28 categorized as medium/high), and 33
recommendations to address them.

Of these, only one finding is a software bug,
[CVE-2025-43915](https://nvd.nist.gov/vuln/detail/CVE-2025-43915). This bug is a
metrics issue the maintainers addressed in
[edge-25.2.1](https://github.com/linkerd/linkerd2/releases/tag/edge-25.2.1) in
February 2025 by turning off the affected metric labels by default. The guide
still details for anyone running the older version with steps to mitigate it.
All other threats can be boiled down to how Linkerd is set up and how the
Kubernetes cluster around it is configured. In other words, nearly all of these
can be fixed by a user without waiting on a release.

The threats can be broadly classified into 5 groups below.

1. **Linkerd's own settings.** These are install options, mostly Helm values,
   that are open by default so a first install doesn't break anything.
2. **How Linkerd is operated over time.** These come from processes rather than
   settings, like rotating certificates before they expire or cleaning up after
   unlinking a cluster.
3. **The Kubernetes cluster underneath.** Linkerd depends on Kubernetes
   permissions, secrets, and pod settings, so weaknesses there carry over into
   the mesh.
4. **The tools around Linkerd.** Other components, such as your ingress
   controller, can undermine the mesh if they're configured in a way Linkerd
   doesn't expect.
5. **Tradeoffs built into how a service mesh works.** A few findings describe
   limits that no setting removes, though you can reduce their impact.

## Why Linkerd's defaults work the way they do

Some of these findings are about defaults, so it's worth explaining where they
come from. Linkerd has always aimed to work the moment you install it, without
breaking the applications already running in your cluster. For teams that add
Linkerd one namespace at a time, a default that rejects every unmeshed
connection would break traffic on the first day. Similarly, the proxy injector
defaults to letting workloads start when it's unavailable, so a control plane
problem doesn't stop every deployment in the cluster.

These defaults ensure a Linkerd deployment is quick and immediately operational.
However, once deployed, you should consider tightening Linkerd’s security
controls, as reinforced by ControlPlane’s guide.

Let us go through the findings and recommendations at a high-level. I strongly
recommend going through the full report for detailed information.

### 1. Linkerd's default settings

**The risk.** Easy-install defaults leave services open, and give some
components too much access.

- The Prometheus bundled with the optional `linkerd-viz` dashboard has cluster
  permissions that could become compromised to run commands in other pods.
- Linkerd accepts connections from workloads outside the mesh to any service
  that doesn't have a policy of its own. If the proxy injector (the component
  that adds Linkerd's proxy to new workloads) is unavailable, Kubernetes starts
  those workloads without the proxy, so they skip the mesh's encryption and
  access rules entirely.
- In multicluster setups, the gateway accepts traffic from any remote identity
  by default, and the credential each cluster uses to watch the other can see
  every service and endpoint in the remote cluster.

**What to do.**

- In production, use your own Prometheus dashboards. For multicluster, double
  check the policies to make sure they only allow traffic from identities you
  expect. Make sure the link from credentials to namespaces are as limited as
  needed.
- Set the injector to fail closed (`webhookFailurePolicy: Fail`) so workloads
  can't start without the proxy, and run the control plane in high availability
  mode so that setting doesn't block deployments.
- Change the cluster-wide default inbound policy to `deny`, so services only
  accept traffic that a policy explicitly allows. While you're still writing
  policies for each service, the guide suggests `cluster-authenticated` or
  `all-authenticated` as a temporary step, since both reject clients without a
  valid mesh identity.

The [Linkerd.io](http://Linkerd.io) docs cover
[restricting access to services](/docs/tasks/restricting-access/),
[high availability](/docs/features/ha/),
[using your own Prometheus](/docs/tasks/external-prometheus/), and
[multicluster](/docs/features/multicluster/).

### 2. How Linkerd is operated over time

**The risk.** Expired, stolen, or out-of-sync certificates can take down the
mesh or let attackers impersonate services.

- Linkerd's identity system rests on a root certificate (the trust anchor) and a
  signing certificate (the identity issuer). If the issuer expires, meshed
  traffic fails gradually over the next day. If the trust anchor expires, it
  stops all at once, and anyone who steals the trust anchor's private key can
  impersonate any service in the mesh.
- Multicluster adds its own process risks. If trust anchors are rotated in one
  cluster but not the others, cross-cluster traffic breaks. Unlinking a cluster
  can leave old credentials and mirrored services behind, and policies can drift
  apart between clusters until the weakest one sets the bar.

**What to do.**

- Create the trust anchor outside the cluster and keep its private key in a key
  management service, a hardware security module, or a secrets manager such as
  OpenBao or HashiCorp Vault. Let cert-manager rotate the issuer automatically,
  set alerts well before either certificate expires, and document your trust
  anchor rotation procedure and test it regularly.
- Rotate trust anchors in all linked clusters together, clean up fully when you
  unlink a cluster, and manage policies through GitOps so every cluster gets the
  same reviewed changes.

The linkerd docs cover how to
[rotate control plane certificates automatically](/docs/tasks/automatically-rotating-control-plane-tls-credentials/).

### 3. The Kubernetes cluster underneath

**The risk.** Weak permissions or overprivileged pods can give attackers a mesh
identity or a way around the proxy.

- Linkerd gives each workload an identity based on its Kubernetes service
  account. Anyone who can steal a service account token, or who has permission
  to create workloads in a namespace, can get a valid identity in the mesh.
- A workload with too many privileges can rewrite its own network rules and
  bypass the proxy, and anyone who can edit Linkerd's policy resources can
  loosen access rules for everyone.

**What to do.**

- Limit who can read secrets, create workloads, and edit Linkerd policy
  resources. Perform periodic audits to monitor permissions of users who can
  create service account tokens and to remove inactive users.
- Stop workloads that don't need the Kubernetes API from mounting service
  account tokens. Encrypting secrets at rest and alerting on unusual access to
  Linkerd's namespace add a further layer. Enforce Kubernetes Pod Security
  Standards so application containers can't change network settings, and enable
  the Linkerd CNI plugin so Linkerd itself doesn't need those privileges either.

The Linkerd docs cover how to enable the
[Linkerd CNI plugin](/docs/features/cni/).

### 4. The tools around Linkerd

**The risk.** A misconfigured ingress controller can let outsiders reach
services they shouldn’t.

- When Linkerd's proxy runs in ingress mode, it decides where to send a request
  partly from a header called `l5d-dst-override`. If your ingress controller
  passes that header through from the outside world, an attacker can set it
  themselves and send requests to services they were never meant to reach.

**What to do.**

- Use ingress mode only if your ingress controller needs it. If you do use it,
  configure the controller to remove or overwrite `l5d-dst-override` on every
  incoming request, and add a policy that limits which services the ingress
  controller can reach.

The Linkerd docs cover [using ingress](/docs/tasks/using-ingress/).

### 5. Tradeoffs built into how a service mesh works

**The risk.** Some limits can only be reduced, not removed.

- In gateway mode, the receiving service sees the gateway's identity instead of
  the original caller's, which makes precise access rules harder to write.
- In flat network mode, workloads keep their own identities, but a breach in one
  cluster can reach further into another.
- On a single pod, traffic between the application and its proxy isn't encrypted
  yet, so an attacker who already controls that pod can read it.

**What to do.**

- With gateway mode, expose only the services that need cross-cluster access,
  and consider separate gateways for different trust levels.
- The guide also suggests flat network mode if keeping the original caller’s
  identity matters, paired with network policies that work across clusters.
- To limit what an attacker can do inside a compromised pod, drop the Linux
  capabilities application containers don't need and enforce
  [Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/).
  For your most sensitive services, add access checks in the application itself,
  so the mesh isn't your only line of defense.

## What happens next

Our team is working through the report now. Any changes will be discussed in the
open on [GitHub](https://github.com/linkerd/linkerd2), where you can follow
along and weigh in.

In the meantime, read the report and take action. The full report has the
complete recommendations, architecture diagrams, and the framework mappings your
security team will want to see.

If you've hardened Linkerd in production and have opinions about which defaults
should change, or where the docs left you guessing, please share it on
[Linkerd Slack](https://slack.linkerd.io).

## Thank you

Thanks to [Tom Cope](https://www.linkedin.com/in/copethomas/),
[Gabriela Georgieva](https://www.linkedin.com/in/gabrielavg/), and
[Samuel Holmes](https://www.linkedin.com/in/sam-holmes2/) at ControlPlane for
taking this on and sharing it with the project first. Independent work like this
makes Linkerd better for everyone who runs it.

Questions about the findings are welcome in the
[Linkerd Slack](https://slack.linkerd.io).
