---
slug: 'announcing-the-linkerd-graalvm-working-group'
title: 'Announcing the Linkerd + GraalVM working group'
aliases:
  - /2018/06/04/announcing-the-linkerd-graalvm-working-group/
author: 'gmiranda23'
date: Mon, 04 Jun 2018 16:47:09 +0000
thumbnail: /uploads/linkerd-graalvm-working-group.png
draft: false
featured: false
tags: [Linkerd, linkerd, News]
---

This Wednesday, we’re kicking off a new community working group to get Linkerd running on [GraalVM](https://www.graalvm.org/). The goal of the working group is to get Linkerd compiled into a native executable with GraalVM, which should result in a massive reduction in its memory footprint. Details below.

GraalVM is a universal virtual machine for running applications written in many languages including JVM-based languages like Java and Scala. It includes a [native-image](http://www.graalvm.org/docs/reference-manual/aot-compilation/) tool that enables ahead-of-time (AOT) compilation of Java applications into native executables. As opposed to the JVM’s traditional just-in-time (JIT) approach of compiling code at run time, the AOT approach pre-compiles into efficient machine code. This should result in two big changes for Linkerd: faster startup times and a reduced memory footprint. Because AOT eliminates the need to include infrastructure to load and optimize code at runtime, a GraalVM Linkerd should require significantly less memory to run. There may also be additional advantages including more predictable performance and less total CPU usage.

So far, it’s unclear exactly how big of an improvement we can expect to see upon successful completion of this work. Using similar techniques, the GraalVM team was able to get a [7x improvement in the memory footprint required for Netty](https://medium.com/graalvm/instant-netty-startup-using-graalvm-native-image-generation-ed6f14ff7692). The aim of the Linkerd+GraalVM working group is to answer this question by collaborating to make Linkerd work in a similar manner.

An early proof of concept has been put together by [Georgi Khomeriki](https://github.com/flatmap13) (Walmart Labs). The [Linkerd+GraalVM working group will meet this Wednesday](https://lists.cncf.io/g/cncf-linkerd-graal-wg/message/16), June 6 from 8:00-9:00 (UTC-7) to review his work, identify next steps, and get started on this exciting new project. If you’d like to participate, you can join the group on [Google Hangouts](http://meet.google.com/gtz-htoa-mik) or dial-in via information on the [group invite](https://lists.cncf.io/g/cncf-linkerd-graal-wg/message/16). Hope to see you then!
