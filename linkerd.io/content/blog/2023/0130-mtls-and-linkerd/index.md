---
title: |-
  Workshop recap: A deep dive into Kubernetes mTLS with Linkerd
date: 2023-01-30T00:00:00+00:00
slug: mtls-and-linkerd
params:
  author: flynn
  showCover: true
---

_This blog post is based on a workshop I recently delivered at Buoyant’s
[Service Mesh Academy](https://buoyant.io/service-mesh-academy). If this seems
interesting, check out the
[full recording](https://buoyant.io/service-mesh-academy/kubernetes-mtls-with-linkerd)!_

You don’t have to spend much time in the cloud-native world before
[mTLS](https://buoyant.io/mtls-guide) comes up. It shows up over and over again,
especially once you start talking about
[zero trust](https://buoyant.io/resources/zero-trust-in-kubernetes-with-linkerd).
So what is it? What can it do, and what can it not do?

To answer these questions, let’s start with a quick look at TLS itself.

## TLS

TLS - _Transport Layer Security_ - is defined in
[RFC 8446](https://www.rfc-editor.org/rfc/rfc8446). It’s the standard at the
root of most of the secure communications happening online today. It can provide
authentication and encryption of communications over insecure channels, and it’s
designed to work with basically any connection-oriented Internet protocol. Note
both that a connection is required (so HTTP/3 brings up some very interesting
things, which I'll be writing about later), and that setup can be costly, so TLS
works best when you get to reuse the connection for multiple requests.

### TLS Certificates

A critical component of TLS and mTLS is the _certificate_. More properly called
_X.509 Certificates_, these things act like ID cards for the Internet. They’re
based on asymmetric keypairs, where a cryptographic key is generated with a
public half and a private half, and they gather up the public half of the
keypair along with several pieces of information into one easy-to-transport blob
of data.

Every certificate has a _Subject_ and an _Issuer_:

- the Subject is the entity identified by the certificate;
- the Issuer is an entity that has certified that the Subject really is who they
  say they are.

In X.509 parlance, certifying the Subject's identity is called “issuing” a
certificate. Under the hood, the Issuer makes sure of the Subject’s identity,
then uses its own certificate to sign the Subject’s certificate. This process
can be (and often is) repeated, so that you end up with a _certificate chain_,
where each certificate signs the next one in the chain. At the head of the
chain - the _root_ - you have a “self-signed” certificate, where the certificate
signs itself.

Since certificates never contain private keys, they are always safe to
distribute far and wide, and there’s also a simple way to bundle an entire
certificate chain into a single file that you can pass around. This allows
anyone receiving a certificate to also have everything they need to validate all
the signatures the entire certificate chain (since verifying a signature only
requires access to the public key of the signer).

### TLS for the Web

While TLS can help secure basically any connection-oriented Internet protocol,
it definitely came into its own with the World Wide Web, so it’s definitely
worth looking to the Web as the de facto “normal” TLS use case:

1. The client makes a connection to the server, and the two parties conduct a
   key exchange which sets up the encryption to be used for the rest of the
   session.

2. The server sends its certificate chain to the client, and the client checks
   to make sure that the server’s certificate is valid.

3. The client and server start exchanging encrypted data.

Obviously I’m glossing over a lot of things here! The really critical bit to
notice, though, is that while the client verifies the server’s identity, the
server does _not_ verify the client’s identity. In other words, TLS is doing
unidirectional authentication – and it’s barely doing authorization at all.
Remember:

- Authentication (_authn_) has to do with identity: are you who you’re claiming
  to be?

- Authorization (_authz_) has to do with policy: are you allowed to do the thing
  you’re trying to do?

The only authorization check in TLS is determining that the server has a valid
certificate, ultimately signed by an issuer that your browser trusts. This is
pretty minimal, but it’s usually OK for the Web — it will protect the human
using a Web browser from being fooled by a malicious Web server, and that’s
often all that’s necessary.

The cloud-native world, though, is not the Web.

### TLS for the Cloud-Native World

In a cloud-native application, we’re looking at applications built out of
microservices, which talk to each other in complex ways. The goals are different
here, because of the nature of security in this world.

In particular, the cloud-native world doesn’t really have the concept of a
security perimeter any more. Instead, we have to verify _every_ access made to a
microservice, _every_ time – this is a foundation of zero trust, and it relies
on authenticating both parties in order to authorize the request. We need both –
but as we saw above, “normal” TLS doesn’t do this.

Enter mTLS.

## mTLS

mTLS stands for _mutual TLS_. It takes TLS as we’ve just described it and adds
the extra constraint that the server must also verify the client’s identity:

1. Workload A makes a connection to workload B, and the two parties conduct a
   key exchange which sets up the encryption to be used for the rest of the
   session.

2. Workload B sends its certificate chain to the workload A, and workload A
   checks to make sure that this chain is valid.

3. Workload A then sends its certificate chain to workload B, and workload B
   checks to make sure it’s valid.

4. The two workloads start exchanging encrypted data.

This is a small addition with a large impact. Authenticating both parties allows
for meaningful authorization, which the
[service mesh](https://buoyant.io/service-mesh-manifesto) can use to enforce
meaningful security policies. So basically, this one change gives the mesh
everything it needs for real zero trust.

Furthermore, cryptographic authentication gets us away from using anything about
the network itself as a proxy for identity. This is a particularly important
point when you’re talking about code running in a cluster where you don’t really
have control over the network infrastructure: using a network you don't control
as a basis for identity gives you identity you can't trust.

### mTLS and Communications Security

One last thing, before we get into the details of mTLS in Linkerd, is a quick
note about communications security. Proper communications security relies on
three distinct things: _confidentiality_, _integrity_, and _authenticity_. If
you don’t have all three, you can’t communicate securely:

- Without _confidentiality_, anyone else can eavesdrop on data in transit. mTLS
  provides confidentiality using encryption.

- Without _integrity_, anyone can modify your data in transit. mTLS provides
  integrity using, basically, checksums of blocks of data. (In cryptography this
  is called a _message authentication code_, or _MAC_, but it’s important to
  realize that it’s a different meaning of “authentication”.)

- Without _authenticity_, an evildoer could easily pretend to be someone you
  trust. mTLS provides authenticity using certificates.

Note that we haven’t really said anything about authorization here. Much like
with “normal” TLS, the only authorization that mTLS provides is the check that
the certificates in play are valid and ultimately signed by a trusted issuer.
Anything beyond that is up to something beyond mTLS: in our case, the service
mesh.

## mTLS in Linkerd

With all that under our belt, we can - finally! - talk about mTLS in Linkerd.

Linkerd uses industry-standard mTLS, implemented as open-source Rust code, for
workload-to-workload communication. This communications-security functionality
is deliberately not changed from what everyone else does: it’s intentionally
boring and safe. About the only interesting thing to point out here is that,
since the Linkerd microproxy mediates all workload-to-workload communications,
it's able to maintains long-lived proxy-to-proxy connections no matter what the
application does, which can help reduce the overheard of TLS handshakes.

Linkerd’s certificate handling and policy enforcement, though, is worth talking
about.

### Certificates in Linkerd

In Linkerd, every meshed workload gets a _workload certificate_ derived from its
Kubernetes ServiceAccount token. This gives us a solid reference point for
workload identity: Kubernetes users are already comfortable with Kubernetes
ServiceAccounts, so cryptographically linking the certificate and the
ServiceAccount is a solid way of establishing cluster-wide identity for a given
workload.

Certificates, of course, must have an Issuer, and using self-signed certificates
for workloads would be counterproductive. Instead, Linkerd provides an internal
_certifying authority_ (CA) called `linkerd-identity`, which manages issuing and
rotating workload certificates. `linkerd-identity` uses a two-layer hierarchy of
trust:

- workload certificates are issued by the Linkerd _identity issuer_, and
- the identity issuer is issued by the Linkerd _trust anchor_.

Linkerd uses two layers to reduce operational complexity when it comes time to
rotate certificates: while Linkerd transparently manages rotating workload
certificates, rotating the identity issuer and trust anchor are operational
tasks that must be directly managed by the mesh operator. Separating the two
layers makes it fairly straightforward to rotate the identity issuer frequently
without downtime, and Linkerd includes support for bundling together an old and
new trust anchor to make it possible to rotate that without downtime too.

Additionally, this system makes it (mostly) straightforward to recover from a
secret getting lost or compromised: you can recover with exactly the same
process you'd use to rotate in a new certificate, and you'll almost never need
to incur downtime. (I say "almost" because having a trust anchor get lost or
compromised can still be very annoying. Be careful with your trust anchors!)

Of course, real-world certificate handling can still be rather annoying, so
Linkerd can work with several other tools to reduce the pain. One common choice
is [cert-manager](https://cert-manager.io/), a CNCF project that's all about
managing certificates. There are also fully managed solutions like Buoyant's own
[Buoyant Cloud](https://buoyant.io/cloud/), which can handle certificate
management, upgrades, and alerting.

### Authorization in Linkerd

Earlier I said that mTLS could handle communications security, but that it
needed outside help from the mesh to handle authorization – and, of course,
authorization is a critical part of mTLS. Linkerd handles authorization in,
again, a fairly straightforward way: mTLS workload certificates provide the
basis for authorization, and Linkerd allows policies to dictate what operations
are allowed from a given workload to a given workload.

This is more subtle than it might seem. Since workload certificates are tied to
ServiceAccounts, this mechanism of using mTLS workload certificates as
authorization principals simultaneously:

- gives Linkerd very robust identities that are not tied to any network
  infrastructure;
- gives Linkerd a way to link its authorization mechanisms with existing
  Kubernetes security scopes and mechanism;
- arranges for the Linkerd security model to completely match existing
  Kubernetes mechanisms and models; and
- allows identity to easily accommodate any cluster topology (for example,
  multicluster identity Just Works).

So using mTLS to tie Linkerd identity to Kubernetes ServiceAccounts ends up
being a simple-sounding decision with some pretty deep - and positive! -
ramifications.

### Is mTLS All You Need?

Spoiler alert: probably not. Sorry.

mTLS is a great tool for protecting against attacks that happen while data are
flowing over the network. For example, spoofing attacks (where the attacker
pretends to be someone else) generally fail when mTLS is in play: assuming that
you're being careful with certificates, the bad actor won't have the right
certificate. Likewise, a man-in-the-middle attacks where a bad actor is trying
to directly modify the encrypted stream will be foiled by mTLS' integrity
checks, and a similar man in the middle trying to terminate and then
re-originate mTLS will, again, be foiled by certificate checking.

However, mTLS doesn't do anything at all to help with attacks on data at rest,
for example: once the data have finished traversing the network, mTLS has no
effect on how the data are stored. And there are network-based attacks that mTLS
can't defend against either: for example, in any Kubernetes implementation, an
attacker with free access to the Node may be able to mount interesting and
subtle attacks based on recovering private keys or modifying network rules. And
for Linkerd specifically, communications between the microproxy and the workload
itself happen over the loopback connection in the clear, so a bad actor who can
snoop on localhost might be able to mount an attack there.

So, like any other security technology, you still need to think about what
threat vectors are relevant in your application, and how to mitigate any you
care about. mTLS is a very powerful tool in your toolbox, but it won't be the
only one.

## mTLS, Zero Trust, and Linkerd

Taking all this together, mTLS ends up being a critical part of Linkerd's
approach to cloud-native zero trust. Having a solid mechanism for workload
identity tied to Kubernetes security models, and _not_ tied to the network
topology, gives Linkerd a great place to stand for taking advantage of mTLS'
communications security and extending that into authorization and policy as
well. And, as always, Linkerd's position down in the infrastructure generally
permits it to provide these benefits without needing any application changes.

---

_If you want more on this topic, check out the Service Mesh Academy workshop on
[mTLS with Linkerd](https://buoyant.io/service-mesh-academy/kubernetes-mtls-with-linkerd)
for hands-on exploration of everything I've talked about here! And, as always,
feedback is always welcome -- you can find me as `@flynn` on the
[Linkerd Slack](https://slack.linkerd.io)._
