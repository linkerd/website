---
title: Enterprise power without enterprise complexity
description: |-
  Linkerd adds critical security, observability, and reliability to your
  Kubernetes stack, without code changes.
params:
  hero:
    title: Enterprise power without enterprise complexity
    content: |-
      Service mesh without the _mess_. Linkerd adds security, observability, and
      reliability to any Kubernetes cluster without the complexity of bloat of
      other meshes. 100% open source, CNCF graduated, and written in Rust.
    buttons:
      - text: Get Started
        href: /2/getting-started/
        variant: primary
      - text: Get Involved
        href: /community/get-involved/
        variant: secondary
  stats:
    - stat: Years in production
      value: 8+
    - stat: Slack channel members
      value: 10,000+
    - stat: GitHub stars
      value: 19,000+
    - stat: Contributors
      value: 500+
  articles:
    title: Why Linkerd?
    items:
      - title: Smaller and faster than any other mesh
        content: |-
          Benchmarks show that Linkerd continues to be dramatically faster than
          Istio while consuming just a fraction of the system resources.
        image: /home/articles/article-1.png
        url: /2021/11/29/linkerd-vs-istio-benchmarks-2021/index.html
      - title: Designed for simplicity and security
        content: |-
          Linkerd's unique design provides fundamental visibility, reliability,
          and security capabilities without the complexity of other approaches.
        image: /home/articles/article-2.png
        url: /design-principles/
      - title: Built in Rust, the language of the future
        content: |-
          Linkerd is the only service mesh written in Rust, allowing us to
          confidently write secure code without the CVEs and buffer overflow
          exploits endemic to other languages.
        image: /home/articles/article-3.png
        url: /2020/12/03/why-linkerd-doesnt-use-envoy/
  adopters:
    - image: /home/logos/expedia.png
      url: https://www.expedia.com
    - image: /home/logos/offerup.png
      url: https://offerup.com/
    - image: /home/logos/tradeshift.png
      url: https://tradeshift.com/
    - image: /home/logos/adidas.png
      url: https://www.adidas.com/
    - image: /home/logos/cisco-webex.png
      url: https://www.webex.com/
    - image: /home/logos/clover-health.png
      url: https://www.cloverhealth.com/
    - image: /home/logos/docker.png
      url: https://www.docker.com/
    - image: /home/logos/heb.png
      url: https://www.heb.com/
    - image: /home/logos/walmart.png
      url: https://www.walmart.com/
    - image: /home/logos/planet.png
      url: https://www.planet.com/
    - image: /home/logos/strava.png
      url: https://www.strava.com/
    - image: /home/logos/elkjop.png
      url: https://www.elkjopnordic.com/
    - image: /home/logos/chase.png
      url: https://www.chase.com/
    - image: /home/logos/mercedez.png
      url: https://www.mercedes-benz.io/
    - image: /home/logos/xbox.png
      url: https://www.xbox.com/
    - image: /home/logos/wiz.png
      url: https://www.wiz.io/
    - image: /home/logos/plaid.png
      url: https://plaid.com/
    - image: /home/logos/timescale.png
      url: https://www.timescale.com/
  caseStudies:
    title: Real-world users
    items:
      - title: Adidas
        image: /home/case-studies/adidas.png
        content: |-
          All our observability gaps were closed, ...we saw a reduction in
          failed requests, and experienced cost reduction due to better
          performance.
        url: https://buoyant.io/case-studies/adidas/
      - title: Xbox
        image: /home/case-studies/xbox.png
        content: |-
          We have offloaded the time and effort needed to develop and maintain
          the in-house mTLS solution, saving valuable engineering hours...
        url: https://buoyant.io/case-studies/xbox/
      - title: DB Schenker
        image: /home/case-studies/db-schenker.png
        content: |-
          Linkerd started as our cloud migration tool and ended up being our
          service mesh of choice.
        url: https://buoyant.io/case-studies/schenker/
  about:
    title: |-
      Linkerd: The Lightest, Fastest, Most Secure Service Mesh on the Planet
    youtubeId: OpZ5auLw5Xw
  features:
    items:
      - title: Instant platform health metrics
        content: |-
          Instantly track success rates, latencies, and request volumes for
          every meshed workload, without changes or config.
        image: /home/features/bar-chart.svg
        url: /2/features/telemetry/
      - title: Simpler than any other mesh
        content: |-
          Minimalist, Kubernetes-native design. No hidden magic, as little YAML
          and as few CRDs as possible.
        image: /home/features/mesh.svg
        url: /design-principles/
      - title: Zero-config mutual TLS and zero-trust policy
        content: |-
          Transparently add mutual TLS to any on-cluster TCP communication with
          no configuration.
        image: /home/features/settings.svg
        url: /2/features/server-policy/
      - title: Designed by engineers, for engineers
        content: |-
          Self-contained control plane, incrementally deployable data plane, and
          lots and lots of diagnostics and debugging tools.
        image: /home/features/startup.svg
        url: /2/tasks/debugging-502s/
      - title: Latency-aware load balancing and cross-cluster failover
        content: |-
          Instantly add latency-aware load balancing, request retries, timeouts,
          and blue-green deploys to keep your applications resilient.
        image: /home/features/balance.svg
        url: /2/features/load-balancing/
      - title: State-of-the-art ultralight Rust dataplane
        content: |-
          Incredibly small and blazing fast Linkerd2-proxy _micro-proxy_ written
          in Rust for security and performance.
        image: /home/features/stats.svg
        url: /2020/12/03/why-linkerd-doesnt-use-envoy/
  cncf:
    title: The first service mesh to achieve CNCF graduation status
    image: /home/cncf.svg
  tweets:
    title: Engineers 💙 Linkerd
    items:
      - name: Vito Botta
        handle: vitobotta
        image: /home/tweets/1wBibgRE_400x400.jpg
        content: |-
          I absolutely love [@Linkerd](https://twitter.com/linkerd) - among
          other things it makes load balancing of grpc service trivial.
          [#Kubernetes](https://twitter.com/hashtag/kubernetes).
        url: https://twitter.com/vitobotta/status/1538086745732001793
      - name: Kharf
        handle: kharf_
        image: /home/tweets/YR6dexO__400x400.png
        content: |-
          A year ago I switched from Istio to
          [@Linkerd](https://twitter.com/linkerd). Ever since then I never had
          this "...oh maybe that issue is caused by our service mesh" feeling
          again.
        url: https://twitter.com/kharf_/status/1550395663489409024
      - name: Anaïs Urlichs
        handle: urlichsanais
        image: /home/tweets/VtAPzwMo_400x400.jpg
        content: |-
          Who can relate? 👀 [@Linkerd](https://twitter.com/linkerd) has the
          best getting-started guide I have seen 🙌✨
          ![Image](/home/tweets/EzaaLrxWYAMSaP3.jpg)
        url: https://twitter.com/urlichsanais/status/1384463767459844097
      - name: Siddique Ahmad
        handle: siddiqueESL
        image: /home/tweets/jNiVoT2a_400x400.jpg
        content: |-
          In few hours we are able to tap in our production and staging
          applications logs thanks to [@Linkerd](https://twitter.com/linkerd),
          wonderful slack support also available, solved one issue came in while
          injecting [@Linkerd](https://twitter.com/linkerd), it will help our
          team to see it before client share with us
        url: https://twitter.com/siddiqueESL/status/1381614377170825216
---
