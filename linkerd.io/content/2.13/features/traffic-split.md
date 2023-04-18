+++
title = "Traffic Split (canaries, blue/green deploys)"
description = "Linkerd can dynamically send a portion of traffic to different services."
+++

Linkerd's traffic split functionality allows you to dynamically shift arbitrary
portions of traffic destined for a Kubernetes service to a different destination
service. This feature can be used to implement sophisticated rollout strategies
such as [canary deployments](https://martinfowler.com/bliki/CanaryRelease.html)
and
[blue/green deployments](https://martinfowler.com/bliki/BlueGreenDeployment.html),
for example, by slowly easing traffic off of an older version of a service and
onto a newer version.

{{< note >}}
If working with headless services, traffic splits cannot be retrieved. Linkerd
reads service discovery information based off the target IP address, and if that
happens to be a pod IP address then it cannot tell which service the pod belongs
to.
{{< /note >}}

Linkerd supports two different ways to configure traffic shifting: you can
use the [Linkerd SMI extension](../linkerd-smi/) and
[TrafficSplit](https://github.com/servicemeshinterface/smi-spec/blob/main/apis/traffic-split/v1alpha2/traffic-split.md/)
resources, or you can use [HTTPRoute](../../reference/httproute/) resources which
Linkerd natively supports. While certain integrations such as
[Flagger](../flagger/) rely on the SMI and `TrafficSplit` approach, using
`HTTPRoute` is the preferred method going forward.

Check out some examples of what you can do with traffic splitting:

- [Canary Releases](../../tasks/canary-release/)
- [Fault Injection](../../tasks/fault-injection/)
- [Traffic Shifting](../../tasks/traffic-shifting/)
