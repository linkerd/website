---
title: Traffic Split (canaries, blue/green deploys)
description: Linkerd can dynamically send a portion of traffic to different services.
---

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

Linkerd exposes this functionality via the
[Service Mesh Interface](https://smi-spec.io/) (SMI)
[TrafficSplit API](https://github.com/servicemeshinterface/smi-spec/tree/master/apis/traffic-split).
To use this feature, you create a Kubernetes resource as described in the
TrafficSplit spec, and Linkerd takes care of the rest.

By combining traffic splitting with Linkerd's metrics, it is possible to
accomplish even more powerful deployment techniques that automatically take into
account the success rate and latency of old and new versions. See the
[Flagger](https://flagger.app/) project for one example of this.

Check out some examples of what you can do with traffic splitting:

- [Canary Releases](../tasks/canary-release/)
- [Fault Injection](../tasks/fault-injection/)
