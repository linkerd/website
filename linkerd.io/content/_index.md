---
title: The world's most advanced service mesh. 100% open source, CNCF graduated, and written in Rust.
date: 2019-02-04T13:12:35.000+00:00
description: Linkerd adds critical security, observability, and reliability to your
  Kubernetes stack, without any code changes.
keywords:
- cloud native applications
outputs:
- html
top_hero:
  title: The world's most advanced service mesh
  description: Enterprise power *without* enterprise complexity. Linkerd adds
    security, observability, and reliability to any Kubernetes cluster.
    100% open source, CNCF graduated, and written in Rust.
  buttons:
  - caption: Get Started
    url: "/getting-started/"
    classname: "is-link"
  - caption: Get Involved
    url: "/community/get-involved/"
    classname: "is-primary"
stats:
  - property: Years in production
    value: 7+
  - property: Slack channel members
    value: 9,000+
  - property: GitHub stars
    value: 15,000+
  - property: Contributors
    value: 500+
case_studies:
  title: Real-world users
companies:
- image: "/uploads/logos/blue/expedia.png"
  url: https://www.expedia.com
- image: "/uploads/logos/blue/offerup.png"
  url: https://offerup.com/
- image: "/uploads/logos/blue/tradeshift.png"
  url: https://tradeshift.com/
- image: "/uploads/logos/blue/adidas.png"
  url: https://www.adidas.com/
- image: "/uploads/logos/blue/cisco-webex.png"
  url: https://www.webex.com/
- image: "/uploads/logos/blue/clover-health.png"
  url: https://www.cloverhealth.com/
- image: "/uploads/logos/blue/docker.png"
  url: https://www.docker.com/
- image: "/uploads/logos/blue/heb.png"
  url: https://www.heb.com/
- image: "/uploads/logos/blue/walmart.png"
  url: https://www.walmart.com/
- image: "/uploads/logos/blue/planet.png"
  url: https://www.planet.com/
- image: "/uploads/logos/blue/strava.png"
  url: https://www.strava.com/
- image: "/uploads/logos/blue/elkjop.png"
  url: https://www.elkjopnordic.com/
- image: "/uploads/logos/blue/chase.png"
  url: https://www.chase.com/
- image: "/uploads/logos/blue/mercedez.png"
  url: https://www.mercedes-benz.io/
- image: "/uploads/logos/blue/xbox.png"
  url: https://www.xbox.com/
- image: "/uploads/logos/blue/wiz.png"
  url: https://www.wiz.io/
- image: "/uploads/logos/blue/plaid.png"
  url: https://plaid.com/
- image: "/uploads/logos/blue/timescale.png"
  url: https://www.timescale.com/
features_list:
  items:
  - title: Instant platform health metrics
    description: Instantly track success rates, latencies, and request volumes for every meshed workload, without changes or config.
    image: "/uploads/features/bar-chart.svg"
    url: "/2.14/features/telemetry/"
    #url: "/features/instant-platform-health-metrics/"
  - title: Simpler than any other mesh
    description: Minimalist, Kubernetes-native design. No hidden magic, as little YAML and as few CRDs as possible.
    image: "/uploads/features/mesh.svg"
    url: "/design-principles/"
    #url: "/features/simpler-than-any-other-mesh/"
  - title: Zero-config mutual TLS and zero-trust policy
    description: Transparently add mutual TLS to any on-cluster TCP communication with no configuration.
    image: "/uploads/features/settings.svg"
    url: "/2.14/features/server-policy/"
    #url: "/features/zero-config-mutual-tls-and-zero-trust-policy/"
  - title: Designed by engineers, for engineers
    description: Self-contained control plane, incrementally deployable data plane, and lots and lots of diagnostics and debugging tools.
    image: "/uploads/features/startup.svg"
    url: "/2.14/tasks/debugging-502s/"
    #url: "/features/designed-by-engineers-for-engineers/"
  - title: Latency-aware load balancing and cross-cluster failover
    description: Instantly add latency-aware load balancing, request retries, timeouts, and blue-green deploys to keep your applications resilient.
    image: "/uploads/features/balance.svg"
    url: "/2.14/features/load-balancing/"
    #url: "/features/latency-aware-load-balancing-and-cross-cluster-failover/"
  - title: State-of-the-art ultralight Rust dataplane
    description: Incredibly small and blazing fast Linkerd2-proxy _micro-proxy_ written in Rust for security and performance.
    image: "/uploads/features/stats.svg"
    url: "/2020/12/03/why-linkerd-doesnt-use-envoy/"
    #url: "/features/state-of-the-art-ultralight-rust-dataplane/"
featured_articles:
  title: Why Linkerd?
  articles:
  - title: Smaller and faster than any other mesh
    description: Benchmarks show that Linkerd continues to be dramatically faster than Istio while consuming just a fraction of the system resources.
    image: "/uploads/featured-articles/article-1.png"
    url: "/2021/11/29/linkerd-vs-istio-benchmarks-2021/index.html"
  - title: Designed for simplicity and security
    description: Linkerd's unique design provides fundamental visibility,
      reliability, and security capabilities without the complexity of other
      approaches.
    image: "/uploads/featured-articles/article-2.png"
    url: "/design-principles/"
  - title: Built in Rust, the language of the future
    description: Linkerd is the only service mesh written in Rust, allowing us
      to confidently write secure code without the CVEs and buffer overflow
      exploits endemic to other languages.
    image: "/uploads/featured-articles/article-3.png"
    url: "/2020/12/03/why-linkerd-doesnt-use-envoy/"
foundation_member_banner:
  title: The first service mesh to achieve CNCF graduation status
  image: "/uploads/cncf.svg"
tweets:
  title: Engineers 💙 Linkerd
  tweets:
  - name: Vito Botta
    handle: vitobotta
    photo: "/uploads/tweets/1wBibgRE_400x400.jpg"
    tweet: "I absolutely love [@Linkerd](https://twitter.com/linkerd) - among other things it makes load balancing of grpc service trivial. [#Kubernetes](https://twitter.com/hashtag/kubernetes)."
    url: "https://twitter.com/vitobotta/status/1538086745732001793"
  - name: Kharf
    handle: kharf_
    photo: "/uploads/tweets/YR6dexO__400x400.png"
    tweet: "A year ago I switched from Istio to [@Linkerd](https://twitter.com/linkerd). Ever since then I never had this \"...oh maybe that issue is caused by our service mesh\" feeling again."
    url: "https://twitter.com/kharf_/status/1550395663489409024"
  - name: Anaïs Urlichs
    handle: urlichsanais
    photo: "/uploads/tweets/VtAPzwMo_400x400.jpg"
    tweet: "Who can relate? 👀 [@Linkerd](https://twitter.com/linkerd) has the best getting-started guide I have seen 🙌✨ ![Image](/uploads/tweets/EzaaLrxWYAMSaP3.jpg)"
    url: "https://twitter.com/urlichsanais/status/1384463767459844097"
  - name: Siddique Ahmad
    handle: siddiqueESL
    photo: "/uploads/tweets/jNiVoT2a_400x400.jpg"
    tweet: "In few hours we are able to tap in our production and staging applications logs thanks to [@Linkerd](https://twitter.com/linkerd), wonderful slack support also available, solved one issue came in while injecting [@Linkerd](https://twitter.com/linkerd), it will help our team to see it before client share with us"
    url: "https://twitter.com/siddiqueESL/status/1381614377170825216"
---
