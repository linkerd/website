+++
title = "Canary Release"
description = "Reduce the risk of introducing new software by leveraging Linkerd to conduct canary releases."
+++

Releasing new software in production can be a scary task. The canary release
pattern makes this a little less dangerous by providing a way to slowly roll out
changes to a small subset of users. Once you're happy with the new version, the
changes can be rolled out to your entire user base incrementally.

Automating canary releases requires more than just the ability to direct traffic
between two backend applications versions. Observability is critical,
understanding success rate and latency is required to remove human testing from
the process. Linkerd enables this functionality by providing rich
[telemetry](/2/features/telemetry) and implementing the
[TrafficSplit](https://github.com/deislabs/smi-spec/blob/master/traffic-split.md)
specification.

With [Flagger](https://flagger.app/) and Linkerd it is possible to completely
automate continuous delivery for your applications.
