+++
author = "charles"
date = 2020-12-15T00:00:00Z
feature = "/uploads/screen-shot-2020-12-17-at-11-54-05-am.png"
tags = ["meetup"]
thumbnail = "/uploads/screen-shot-2020-12-17-at-11-54-05-am.png"
title = "December Linkerd Community Meeting "
featured = false

+++
This month’s community meeting had lots of great content!

## **Sneak peek into Linkerd 2.10**

Oliver provided a sneak peek into the upcoming 2.10 release. What can you expect? We’re separating the Linkerd control plane components (e.g. dashboard, Prometheus, and Jaeger) so that users can install a Linkerd "micro" control plane which can be customized with the newly modularized components. We'll also extend TCP to multi-cluster, and much more.

Linkerd maintainer, Alex Leong, also provided insights into the upcoming modularized Linkerd 2.10 control plane. This modularity will allow users to conduct micro installs for edge and swap out parts they already have, providing a lot more flexibility and control. Other pieces, such as Jaeger, will become extensions, as the core architecture moves toward a more extensible framework.

## **Giving observability the attention it deserves**

We were also joined by guest speaker, EverQuote's Matt Young. Matt shared his journey from debugging Windows CE to joining EverQuote and his first experience with EC2 and Kubernetes. At EverQuote, Matt was tasked with building out a complete observability stack to support the growth of internal services. He noticed the growth in open source observability, particularly driven by projects such as Cortex and Linkerd. To ensure the CNCF gave observability the attention it deserves, he went on to found [SIG Observability](https://github.com/cncf/sig-observability).

## **Celebrating our latest Linkerd Hero**

And last but not least, we announced our December Linkerd Hero, [Lutz Behnke](https://www.linkedin.com/in/lutz-behnke-096a19/) a.k.a. the "Cert Man." Lutz has [submitted four sizable PRs](https://github.com/linkerd/linkerd2/pulls?q=is%3Apr+author%3Acypherfox+is%3Aclosed)since June focusing on cert-manager setup—single-handedly fast-tracking that effort. And, because he did it so thoughtfully while communicating well with the core maintainer team, his PRs were merged and he gained Hero recognition from his community peers.

{{< youtube id="fkG92qOhdo4" t="10" >}}
