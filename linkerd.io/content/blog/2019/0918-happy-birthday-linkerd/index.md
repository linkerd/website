---
date: 2019-09-18T00:00:00Z
slug: happy-birthday-linkerd
title: Linkerd 2.x turns one year old! 🎂
keywords: [linkerd]
params:
  author: william
---

Believe it or not, today marks the one-year anniversary of the [Linkerd 2.0
launch](/2018/09/18/announcing-linkerd-2-0/)! With 2.6
already round the corner, it's hard to believe just how much momentum,
adoption, and iteration has been packed into the last 365 days.

## One year of Linkerd 2.x

Here are just a few of the highlights from the past year of Linkerd 2.x.

🍰 **Solving real problems for real users**. This November's Kubecon San Diego
includes talks from Linkerd users at **Nordstrom**, **Disney**, **Microsoft**,
**Paybase**, and more, joining the ever-growing list of Linkerd production use
cases that spans [mobile](https://apester.com/) to
[consumer](https://www.askattest.com/) to [payments](https://paybase.io/) to
[banking](https://www.finleap.com/). No matter the industry or scale, Linkerd
gives you the essential reliability, security, and observability necessary to
operate your app on Kubernetes. And most of all, [*it just
works*](https://twitter.com/coleca/status/1091591745870139392).

🍰 **A non-stop drumbeat of releases**. The past year has seen 5 stable releases
of 2.x and 50 (!) edge releases, covering a changelog that [spans over 2,000
lines of text](https://github.com/linkerd/linkerd2/blob/main/CHANGES.md)!
But don't worry, you don't have to read all that to use Linkerd... [installing
Linkerd is still a 60-second
process](https://channel9.msdn.com/Shows/Azure-Friday/60-seconds-to-a-Linkerd-service-mesh-on-AKS).

🍰 **An incredible pace of feature iteration**. Since the 2.0 launch, we've added
a on-by-default mutual TLS, per-route metrics, retries, timeouts, Helm charts,
proxy auto-injection, traffic splitting, and many, many more features. That
doesn't even include the distributed tracing, tap headers, and TCP mTLS that
are on the docket for later this year!

🍰 **Mass ecosystem integrations**. From
[OpenFaaS](https://github.com/openfaas-incubator/openfaas-linkerd2) to
[Flagger](https://docs.flagger.app/usage/linkerd-progressive-delivery) to
[Ambassador](https://blog.getambassador.io/knative-linkerd-support-json-logging-and-more-in-ambassador-0-73-a2dc62413c18)
to Service Mesh Hub to
[DigitalOcean](https://marketplace.digitalocean.com/apps/linkerd-beta) to
[VSCode](https://marketplace.visualstudio.com/items?itemName=bhargav.vscode-linkerd)
to [Rio](https://github.com/rancher/rio/pull/411), Linkerd has become a
critical building block for the cloud native ecosystem as a whole.

🍰 **The creation of industry-defining interfaces**. The Linkerd team was the
largest contributor to Microsoft's [Service Mesh
Interface](/2019/05/24/linkerd-and-smi/) specification, and
Linkerd's metrics and traffic splitting features support SMI out of the box.

🍰 **A third-party security audit passed with flying colors**. The security
analysis firm [Cure53 evaluated
Linkerd](https://github.com/linkerd/linkerd2/blob/main/SECURITY_AUDIT.pdf)
and concluded that Linkerd "is fully capable of preventing major attacks and
should be considered strong against the majority of malicious attempts at a
compromise", continuing that "Cure53 needs to mention the atypically excellent
code readability, careful choice of implementation languages, as well as the
clearly written and well-maintained documentation for all attributes."

🍰 **A third-party performance benchmark that placed it miles ahead of other
projects**. Kinvolk [evaluated Linkerd's
performance](https://kinvolk.io/blog/2019/05/performance-benchmark-analysis-of-istio-and-linkerd/),
and concluded: "Linkerd takes the edge on resource consumption, and when pushed
into high load situations, maintains acceptable response latency at a higher
rate of requests per second that Istio is able to deliver." (See [our writeup
of their report](/2019/05/18/linkerd-benchmarks/).)

🍰 **A rapidly-growing, friendly, engaged community**. Now at 4,500+ GitHub stars,
80 contributors, and 3,500+ friendly folks in the [Linkerd Slack](https://slack.linkerd.io), the Linkerd
community is consistently one of the friendliest and most helpful groups of
humans you could find on the Internet!

## But the most important thing of all?

I'm proud of all that we've accomplished, but the thing I'm *most* proud of, by
far, is the consistent level of positive feedback and love we get Linkerd's
adopters, contributors, and committers. This is the oxygen that keeps any
project growing, and above all, Linkerd is your project. Here's to another
incredible year together with you. 💪

{{< tweet user="markrendle" id="1172922222941560832" >}}
{{< tweet user="CamiloFromHN" id="1172081948107239426" >}}
{{< tweet user="ibuildthecloud" id="1166399513923211265" >}}
{{< tweet user="macintoshPrime" id="1164162817131520002" >}}
{{< tweet user="Linkerd" id="1174402199549464576" >}}
{{< tweet user="dexterchief" id="1133853318424485889" >}}
{{< tweet user="StevenNatera" id="1130973416775983104" >}}
{{< tweet user="coleca" id="1091591745870139392" >}}

## Ready to try Linkerd?

Ready to try Linkerd? Those of you who have been tracking the 2.x branch via
our [weekly edge releases](/2-edge/) will already have seen
these features in action. Either way, you can download the stable 2.5 release
by running:

```bash
curl --proto '=https' --tlsv1.2 -sSfL https://run.linkerd.io/install | sh
```

Linkerd is a community project and is hosted by the [Cloud Native Computing
Foundation](https://cncf.io/). If you have feature requests, questions, or
comments, we'd love to have you join our rapidly-growing community! Linkerd
is hosted on [GitHub](https://github.com/linkerd/), and we have a thriving
community on [Slack](https://slack.linkerd.io/),
[Twitter](https://twitter.com/linkerd), and the [mailing
lists](/community/get-involved/). Come and join the fun!
