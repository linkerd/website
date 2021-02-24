---
slug: 'slow-cooker-load-testing-for-tough-software'
title: 'Slow Cooker: Load testing for tough software'
aliases:
  - /2016/12/10/slow-cooker-load-testing-for-tough-software/
author: 'steve'
date: Sat, 10 Dec 2016 00:11:51 +0000
draft: false
featured: false
thumbnail: /uploads/linkerd_slow_cooker_featured.png
tags: [Buoyant, buoyant, News, Product Announcement]
---

Linkerd, our service mesh for cloud-native applications, needs to handle very high volumes of production traffic over extended periods of time. In this post, we’ll describe the load testing strategies and tools we use to ensure Linkerd can meet this goal. We’ll review some of the problems we faced when trying to use popular load testers. Finally, we’ll introduce **slow_cooker**, an open source load tester written in Go, which is designed for long-running load tests and lifecycle issue identification.

As a service mesh, [Linkerd](http://linkerd.io/) acts as a transparent proxy, taking requests destined for a particular service and adding connection pooling, failure handling, retries, latency-aware load balancing, and more. In order to be a viable production system, Linkerd needs to handle very high request loads over long periods of time and a variety of conditions. Happily, Linkerd is built on top of [netty](http://netty.io/) and [Finagle](https://twitter.github.io/finagle/), some of the most widely tested and production-vetted network code known to man. But code is one thing; performance in the real world is another.

To assess production behavior, Linkerd needs to be vetted by extensive and rigorous load testing. Furthremore, since Linkerd is a part of underlying infrastructure, Linkerd instances are rarely stopped or restarted—a single Linkerd instance may see billions of requests over a variety of client and service behaviors. This means we must also test for *lifecycle issues*. For high-throughput network servers like Linkerd, lifecycle issues include memory leaks, socket leaks, bad GC pauses, and periodic network or disk saturation. While these things happen infrequently, if they aren’t handled properly, the results can be catastrophic.

## WHO TESTS THE TESTERS?

Early on in Linkerd development, we used popular load testers like [ApacheBench](http://httpd.apache.org/docs/2.4/programs/ab.html) and [hey](https://github.com/rakyll/hey). (Of course, these are HTTP-specific, and Linkerd proxies a variety of protocols, including Thrift, gRPC, and Mux—but we needed to start somewhere.)

Unfortunately, we quickly found that while these tools were great for getting a quick read on performance, they weren’t great for identifying the lifecycle issues we wanted to capture. These tools would provide a single end-of-run summary, which could mask real issues. They also relied on means and standard deviations, which we knew was a problematic way to characterize system performance.

For capturing lifecycle issues, we wanted both better metrics and to the ability to see how Linkerd was performing over long tests runs of hours or days rather than minutes.

## SLOW COOKING FOR TENDER CODE

Since we couldn’t find a tool that did what we needed, we built one: [slow_cooker](https://github.com/buoyantio/slow_cooker). slow_cooker is a load tester designed explicitly for long-running load tests to identify lifecycle issues. We use slow_cooker extensively to find performance issues and test changes in our products. It features incremental progress reports, change detection, and comprehensive metrics.

Today, we’re open sourcing slow_cooker for others to use and contribute to. You can check out the [source on GitHub](https://github.com/buoyantio/slow_cooker) or try out the [recently released 1.0 version](https://github.com/buoyantio/slow_cooker/releases).

Let’s take a look at some of slow_cooker’s features.

(For the sake of simplicity, we’ll show the output of slow_cooker when we change performance characteristics of the downstream services. In practice, of course, we use slow_cooker primarily to identify problems with Linkerd, not the services it’s talking to.)

## INCREMENTAL LATENCY REPORTS

slow_cooker has an incremental reporting approach, motivated by our focus on finding lifecycle issues over a long period of time. Too much can get lost when looking at an aggregate report over a very large amount of data—especially for transient issues like GC pressure or network saturation. With incremental reports, we can see throughput and latency trends or changes in a running system.

In the example below, we show slow_cooker output from load testing Linkerd. Our test scenario has Linkerd load balancing across 3 nginx backends, each serving static content. The latencies given are in milliseconds, and we report the min, p50, p95, p99, p999, and max latencies seen during this 10 second interval.

```txt
$ ./slow_cooker_linux_amd64 -url http://target:4140 -qps 50 -concurrency 10 http://perf-target-2:8080
    # sending 500 req/s with concurrency=10 to http://perf-target-2:8080 ...
    #                      good/b/f t     good%   min [p50 p95 p99  p999]  max change
    2016-10-12T20:34:20Z   4990/0/0 5000  99% 10s   0 [  1   3   4    9 ]    9
    2016-10-12T20:34:30Z   5020/0/0 5000 100% 10s   0 [  1   3   6   11 ]   11
    2016-10-12T20:34:40Z   5020/0/0 5000 100% 10s   0 [  1   3   7   10 ]   10
    2016-10-12T20:34:50Z   5020/0/0 5000 100% 10s   0 [  1   3   5    8 ]    8
    2016-10-12T20:35:00Z   5020/0/0 5000 100% 10s   0 [  1   3   5    9 ]    9
    2016-10-12T20:35:11Z   5020/0/0 5000 100% 10s   0 [  1   3   5   11 ]   11
    2016-10-12T20:35:21Z   5020/0/0 5000 100% 10s   0 [  1   3   5    9 ]    9
    2016-10-12T20:36:11Z   5020/0/0 5000 100% 10s   0 [  1   3   5    9 ]    9
    2016-10-12T20:36:21Z   5020/0/0 5000 100% 10s   0 [  1   3   6    9 ]    9
    2016-10-12T20:35:31Z   5019/0/0 5000 100% 10s   0 [  1   3   5    9 ]    9
    2016-10-12T20:35:41Z   5020/0/0 5000 100% 10s   0 [  1   3   6   10 ]   10
    2016-10-12T20:35:51Z   5020/0/0 5000 100% 10s   0 [  1   3   5    9 ]    9
    2016-10-12T20:36:01Z   5020/0/0 5000 100% 10s   0 [  1   3   5   10 ]   10
```

In this report, `good%` measures throughput: how close we’re getting to the requested RPS (requests per second).

This report looks good—the system is fast and response times are stable. When things go bad, however, we need that fact to come across clearly. We designed slow_cooker’s output to make it easy to visually scan for issues and outliers by using vertical alignment and a change indicator helps us to spot outliers in latency. In the example below, we have a backend server suffering from a catastrophic slow down:

```txt
$ ./slow_cooker_linux_amd64 -totalRequests 100000 -qps 5 -concurrency 100 http://perf-target-1:8080
    # sending 500 req/s with concurrency=10 to http://perf-target-2:8080 ...
    #                      good/b/f t     good%   min [p50 p95 p99  p999]  max change
    2016-11-14T20:58:13Z   4900/0/0 5000  98% 10s   0 [  1   2   6    8 ]    8 +
    2016-11-14T20:58:23Z   5026/0/0 5000 100% 10s   0 [  1   2   3    4 ]    4
    2016-11-14T20:58:33Z   5017/0/0 5000 100% 10s   0 [  1   2   3    4 ]    4
    2016-11-14T20:58:43Z   1709/0/0 5000  34% 10s   0 [  1 6987 6987 6987 ] 6985 +++
    2016-11-14T20:58:53Z   5020/0/0 5000 100% 10s   0 [  1   2   2    3 ]    3 --
    2016-11-14T20:59:03Z   5018/0/0 5000 100% 10s   0 [  1   2   2    3 ]    3 --
    2016-11-14T20:59:13Z   5010/0/0 5000 100% 10s   0 [  1   2   2    3 ]    3 --
    2016-11-14T20:59:23Z   4985/0/0 5000  99% 10s   0 [  1   2   2    3 ]    3 --
    2016-11-14T20:59:33Z   5015/0/0 5000 100% 10s   0 [  1   2   3    4 ]    4 --
    2016-11-14T20:59:43Z   5000/0/0 5000 100% 10s   0 [  1   2   3    5 ]    5
    2016-11-14T20:59:53Z   5000/0/0 5000 100% 10s   0 [  1   2   2    3 ]    3
    FROM    TO #REQUESTS
       0     2 49159
       2     8 4433
       8    32 8
      32    64 0
      64   128 0
     128   256 0
     256   512 0
     512  1024 0
    1024  4096 0
    4096 16384 100
```

As you can see, the system is fast and responsive except for a hiccup at 2016-11-14T20:58:43Z. During this hiccup, our throughput dropped to 34% and then returned to normal. As a service owner, you’d want to look into your logs or performance metrics and investigate the root cause.

## LIFECYCLE ISSUE EXAMPLE: GC PAUSE

In order to demonstrate how incremental reporting can provide benefits over a single final report, let’s do a simulation of a backend service having GC trouble. In this example, we’ll test directly against a single nginx process serving static content, and in a loop we’ll continually pause and then unpause the process at 5 second intervals (using `kill -STOP $PID` and `kill -CONT $pid`).

For comparison, let’s start with a [ApacheBench](http://httpd.apache.org/docs/2.4/programs/ab.html)’s report:

```txt
$ ab -n 100000 -c 10 http://perf-target-1:8080/
    This is ApacheBench, Version 2.3
    Copyright 1996 Adam Twiss, Zeus Technology Ltd, http://www.zeustech.net/
    Licensed to The Apache Software Foundation, http://www.apache.org/

    Benchmarking perf-target-1 (be patient)
    Completed 10000 requests
    Completed 20000 requests
    Completed 30000 requests
    Completed 40000 requests
    Completed 50000 requests
    Completed 60000 requests
    Completed 70000 requests
    Completed 80000 requests
    Completed 90000 requests
    Completed 100000 requests
    Finished 100000 requests

    Server Software:        nginx/1.9.12
    Server Hostname:        perf-target-1
    Server Port:            8080

    Document Path:          /
    Document Length:        612 bytes

    Concurrency Level:      10
    Time taken for tests:   15.776 seconds
    Complete requests:      100000
    Failed requests:        0
    Total transferred:      84500000 bytes
    HTML transferred:       61200000 bytes
    Requests per second:    6338.89 [#/sec] (mean)
    Time per request:       1.578 [ms] (mean)
    Time per request:       0.158 [ms] (mean, across all concurrent requests)
    Transfer rate:          5230.83 [Kbytes/sec] received

    Connection Times (ms)
                  min  mean[+/-sd] median   max
    Connect:        0    0   0.2      0       3
    Processing:     0    1  64.3      0    5003
    Waiting:        0    1  64.3      0    5003
    Total:          0    2  64.3      1    5003

    Percentage of the requests served within a certain time (ms)
      50%      1
      66%      1
      75%      1
      80%      1
      90%      1
      95%      1
      98%      1
      99%      2
     100%   5003 (longest request)
```

Here we see mean latency is 1.5ms, but some outliers have high latency. It would be easy to misread this report as healthy even though the backend service is unresponsive for fully half of the test run. If your target SLA is 1 second, then your service is out of SLA for more than half of the test run—but you might never suspect that from this report!

With slow_cooker’s incremental results, however, we can see that there’s a consistent throughput bottleneck that needs deeper investigation. Also, it becomes much more clear that the 99.9th percentile is consistently high; this is not just a few outliers, but a persistent and ongoing problem:

```txt
$ ./slow_cooker_linux_amd64 -totalRequests 20000 -qps 50 -concurrency 10 http://perf-target-2:8080
    # sending 500 req/s with concurrency=10 to http://perf-target-2:8080 ...
    #                      good/b/f t    good%    min [p50 p95 p99  p999]  max change
    2016-12-07T19:05:37Z   2510/0/0 5000  50% 10s   0 [  0   0   2 4995 ] 4994 +
    2016-12-07T19:05:47Z   2520/0/0 5000  50% 10s   0 [  0   0   1 4999 ] 4997 +
    2016-12-07T19:05:57Z   2519/0/0 5000  50% 10s   0 [  0   0   1 5003 ] 5000 +
    2016-12-07T19:06:07Z   2521/0/0 5000  50% 10s   0 [  0   0   1 4983 ] 4983 +
    2016-12-07T19:06:17Z   2520/0/0 5000  50% 10s   0 [  0   0   1 4987 ] 4986
    2016-12-07T19:06:27Z   2520/0/0 5000  50% 10s   0 [  0   0   1 4991 ] 4988
    2016-12-07T19:06:37Z   2520/0/0 5000  50% 10s   0 [  0   0   1 4995 ] 4992
    2016-12-07T19:06:47Z   2520/0/0 5000  50% 10s   0 [  0   0   2 4995 ] 4994
    FROM    TO #REQUESTS
       0     2 19996
       2     8 74
       8    32 0
      32    64 0
      64   128 0
     128   256 0
     256   512 0
     512  1024 0
    1024  4096 0
    4096 16384 80
```

## PERCENTILE-BASED LATENCY REPORTING

As we see from the ApacheBench example above, some load testing tools will only output average and standard deviation. However, these metrics are [usually inappropriate for system latencies](http://www.brendangregg.com/FrequencyTrails/mean.html). Latency does not follow a standard distribution, and often has very long tails. With slow_cooker, we discard mean and stddev entirely, showing instead the minimum, maximum, and a handful of higher-order percentiles (50th, 95th, 99th, and 99.9th). This approach has seen increased adoption in modern software systems, where a single request can result in dozens or even hundreds of queries to other systems. In these situations, metrics like the 95th and 99th percentiles represent the dominant latency for end users.

## CONCLUSION

Although writing a load generator is not ultimately particularly *difficult*, especially with modern, concurrent, network-oriented languages like Go, the details of reporting and measuring can make a significant difference in the utility of the tool.

Today, we use slow_cooker extensively to test Linkerd as well as other projects in the ecosystem (e.g. nginx). We currently run 24x7 tests against Linkerd in the context of complex multi-service software. slow_cooker has helped us not only keep buggy code from being deployed, but it has also [identified performance problems in existing code](https://github.com/linkerd/linkerd/issues/392). Usage of slow_cooker has become so pervasive at Buoyant that we refer to load testing a piece of software as “slow cooking” it.

You can get started using slow_cooker today by visiting the [Github releases page](https://github.com/buoyantio/slow_cooker/releases). Download the tool and fire it at your favorite backend to start vetting it for performance issues. We hope you’ll find it as useful in your setup as we have in our tests of Linkerd.

## FURTHER READING

1. [Throughput-Delay Curves](http://perfdynamics.blogspot.com/2012/01/throughput-delay-curves.html)
2. [Frequency Trails: What the Mean Really Means](http://www.brendangregg.com/FrequencyTrails/mean.html)
3. [Simulating Byzantine Failure with SIGSTOP](http://saladwithsteve.com/2008/06/simulating-byzantine-failure-with.html)
4. [Everything You Know About Latency Is Wrong](https://dzone.com/articles/everything-you-know-about-latency-is-wrong-brave-n)
5. [How NOT to measure latency](https://www.youtube.com/watch?v=lJ8ydIuPFeU&feature=youtu.be)
