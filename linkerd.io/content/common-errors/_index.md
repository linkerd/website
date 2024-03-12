---
title: Common Errors
description: What things might go wrong with Linkerd? How do I fix common situations? Get answers to these questions and more.
type: faq
include_toc: true
enableFAQSchema: true
weight: 9
aliases: {}
sitemap:
  - priority = 1.0
faqs:
  - question: What's the first thing to do if things seem to be going wrong?
    answer: |-
      **Always** start with `linkerd check`.

      Whenever you see anything that looks unusual about your mesh, always
      start with `linkerd check`. It will check a long series of things that
      have caused trouble for others and make sure that your configuration
      is sane, and it will point you to help for any problems it finds. It's
      hard to overstate how useful this command is.
    answer_schema: |-
      Always start with linkerd check. Whenever you see anything that looks
      unusual about your mesh, always start with linkerd check. It will check
      a long series of things that have caused trouble for others and make
      sure that your configuration is sane, and it will point you to help
      for any problems it finds. It's hard to overstate how useful this
      command is.
  - question: Why am I seeing protocol detection timeouts?
    answer: |-
      While this can indicate that a workload is very slow to respond, it's
      much more common to see it for ports that haven't been marked as `skip`
      or `opaque`, but are used for server-speaks-first protocols.

      Configuring `skip` and `opaque` ports is covered in the [protocol
      detection documentation](../2.15/features/protocol-detection/#configuring-protocol-detection).
    # answer_schema is the answer with no links.
    answer_schema: |-
      While this can indicate that a workload is very slow to respond, it's
      much more common to see it for ports that haven't been marked as skip
      or opaque, but are used for server-speaks-first protocols.

      Configuring skip and opaque ports is covered in the protocol
      detection documentation.
  - question: What is failfast?
    answer: |-
      If Linkerd reports that a given service is in the _failfast_ state, it
      means that the proxy has determined that there are no available endpoints
      for that service. In this situation there's no point in the proxy trying
      to actually make a connection to the service - it already knows that it
      can't talk to it - so it reports that the service is in failfast and
      immediately returns an error from the proxy.

      The error will be either a 503 or a 504; see below for more information,
      but if you already know that the service is in failfast because you saw
      it in the logs, that's the important part.
    # answer_schema is the answer with no links.
    answer_schema: |-
      If Linkerd reports that a given service is in the failfast state, it
      means that the proxy has determined that there are no available endpoints
      for that service. In this situation there's no point in the proxy trying
      to actually make a connection to the service - it already knows that it
      can't talk to it - so it reports that the service is in failfast and
      immediately returns an error from the proxy.

      The error will be either a 503 or a 504; see below for more information,
      but if you already know that the service is in failfast because you saw
      it in the logs, that's the important part.
  - question: Why am I getting HTTP 502 errors?
    answer: |-
      The Linkerd proxy will return a 502 error for connection errors between
      proxies. Unfortunately it's fairly common to see an uptick in 502s when
      first meshing a workload that hasn't previously been used with a mesh,
      because the mesh surfaces errors that were previously invisible!

      There's actually a whole page on [debugging 502s](../2.15/tasks/debugging-502s/).
    # answer_schema is the answer with no links.
    answer_schema: |-
      The Linkerd proxy will return a 502 error for connection errors between
      proxies. Unfortunately it's fairly common to see an uptick in 502s when
      first meshing a workload that hasn't previously been used with a mesh,
      because the mesh surfaces errors that were previously invisible!

      There's actually a whole page on debugging 502s.
  - question: Why am I getting HTTP 503 or 504 errors?
    answer: |-
      503s and 504s show up when a Linkerd proxy is trying to make so many
      requests to a workload that it gets overwhelmed.

      When the workload next to a proxy makes a request, the proxy adds it
      to an internal dispatch queue. When things are going smoothly, the
      request is pulled from the queue and dispatched almost immediately.
      If the queue gets too long, though (which can generally happen only
      if the called service is slow to respond), the proxy will go into
      _load-shedding_, where any new request gets an immediate 503. The
      proxy can only get _out_ of load-shedding when the queue shrinks.

      Failfast also plays a role here: if the proxy puts a service into
      failfast while there are requests in the dispatch queue, all the
      requests in the dispatch queue get an immediate 504 before the
      proxy goes into load-shedding.
    # answer_schema is the answer with no links.
    answer_schema: |-
      503s and 504s show up when a Linkerd proxy is trying to make so many
      requests to a workload that it gets overwhelmed.

      When the workload next to a proxy makes a request, the proxy adds it
      to an internal dispatch queue. When things are going smoothly, the
      request is pulled from the queue and dispatched almost immediately.
      If the queue gets too long, though (which can generally happen only
      if the called service is slow to respond), the proxy will go into
      load-shedding, where any new request gets an immediate 503. The
      proxy can only get _out_ of load-shedding when the queue shrinks.

      Failfast also plays a role here: if the proxy puts a service into
      failfast while there are requests in the dispatch queue, all the
      requests in the dispatch queue get an immediate 504 before the
      proxy goes into load-shedding.
  - question: How does the proxy get out of failfast or load-shedding?
    answer: |-
      To get out of failfast, some endpoints for the service have to
      become available.

      To get out of load-shedding, the dispatch queue has to start
      emptying, which implies that the service has to get more capacity
      to process requests or that the incoming request rate has to drop.
---
