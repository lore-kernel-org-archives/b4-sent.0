From: Yongjian Wang <echoowall@gmail.com>
Subject: [PATCH 6.12.y] Revert "net: advertise TCP MSS from the configured
 MTU, not the learned PMTU"
To: stable@vger.kernel.org
Cc: Sasha Levin <sashal@kernel.org>, Eric Dumazet <edumazet@kernel.org>, 
 Jiayuan Chen <jiayuan.chen@linux.dev>, Jakub Kicinski <kuba@kernel.org>
In-Reply-To: <20261107052749-failed-6.12-564313447e54@kernel.org>
References: <20261107052749-failed-6.12-564313447e54@kernel.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAPEY72oC/y2MQQ6CQAxFr0K6tkgHg9GrGBcDdKAGBjMVhBDuL
 qMu38t/fwXlIKxwTVYIPInK4HegQwJVa33DKPXOYDJTEGVntPXUq2KBZHDB3kqHseM35uTy04V
 czc7B3j8DO5m/3zcoUjLpAvef17F8cPWKx3FZWmUsg/VVG9UQpBF/7MSPM/7DbfsALZd0uasAA
 AA=
X-Change-ID: 20261107-advmss-6-12-y-mail-review-31f3491fdeff
Date: Sat, 07 Nov 2026 12:35:13 -0000
Message-ID: <179405491351.76470.8103187390766591824.advmss-backport-6.12@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794054927; l=7756;
 i=echoowall@gmail.com; s=20261026; h=from:subject:message-id;
 bh=8QAbP5yD6YPkNYQ3g/QDm59M0GX/ZLQvgLMgdW3Au4E=;
 b=kWyn0a1VjXgES7iWWcJfVZAE8CiJWGFrz8S+q2xHQTRCgiQFHASMnVNtqcG7WutdO6yVGau2A
 G8wudY4Eg6EBdLgOZeIvHQekiOn0Gn6tWo5cKbmviCdMbvHqeX0+B+I
X-Developer-Key: i=echoowall@gmail.com; a=ed25519;
 pk=9XP6JhqjjPsHCF6UZZZTeqTRnXIa4+ufggnxXtTJ+no=
X-Endpoint-Received: by B4 Relay for echoowall@gmail.com/20261026 with auth_id=1323
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

[ Upstream commit 564313447e545eea13038f74ada9272ab129b3cb ]

This reverts commit 2640e6419594 ("net: advertise TCP MSS from the
configured MTU, not the learned PMTU").

That commit stopped the learned PMTU from lowering the MSS we advertise
in SYN and SYN-ACK. For symmetric paths it argued that "the peer runs
its own PMTU discovery and usually already knows the real path MTU".
That only holds if ICMP "fragmentation needed" can reach the peer. When
the peer sits behind a firewall that drops inbound ICMP, its PMTU
discovery is a black hole (RFC 2923, section 2.1), and the smaller MSS
we advertised was the only thing keeping its full-size segments off the
narrow hop.

Inbound ICMP filtering is very common in enterprise and carrier
networks, and it is pervasive in mainland China. We hit this in
production after the commit was backported to 6.12.111: TCP connections
that reach a server through a relay with a smaller-MTU hop complete the
handshake, then stall as soon as the client sends full-size segments.
Clients on networks that let ICMP through, and connections that bypass
the relay, are unaffected, which made it hard to trace back to the
kernel.

Reproducer, network namespaces on a single host:

  cli --(1500)-- r1 --(1456)-- r2 --(1500)-- srv

r1 drops ICMP frag-needed towards cli. srv has already learned PMTU
1456 towards cli, then cli uploads 1 MB to srv:

  kernel                     SYN-ACK MSS   1 MB upload
  6.12.107                   1416          OK
  6.12.111                   1460          stalls, times out
  7.3-rc7                    1460          stalls, times out
  7.3-rc7 + this revert      1416          OK

The asymmetric case the commit was written for does not need a new
default: the advertised MSS can already be set per route with the
advmss metric, which takes precedence over default_advmss(). With this
revert applied, on an asymmetric path where srv learned PMTU 1456
towards cli while cli->srv is 1500 end to end:

  srv route to cli           SYN-ACK MSS   largest cli->srv segment
  default                    1416          1404
  advmss 1460                1460          1448

So DSR-style setups can opt in with "ip route ... advmss <mss>", while
hosts whose peers cannot complete PMTU discovery keep working by
default.

[ 6.12.y: reverse commit 7f84f07f54fa, the stable backport of
  2640e6419594. Keep the local dst_dev() lookup and surrounding
  context in ip6_default_advmss(). ]

Fixes: 2640e6419594 ("net: advertise TCP MSS from the configured MTU, not the learned PMTU")
Closes: https://lore.kernel.org/regressions/4F0FAEB6-A13B-47F3-BFF1-C706686C6F64@gmail.com/
Cc: stable@vger.kernel.org
Signed-off-by: Yongjian Wang <echoowall@gmail.com>
Reviewed-by: Eric Dumazet <edumazet@kernel.org>
Reviewed-by: Jiayuan Chen <jiayuan.chen@linux.dev>
Link: https://patch.msgid.link/20261026-advmss-revert-v1-2-272fa4b7ecb6@gmail.com
Signed-off-by: Jakub Kicinski <kuba@kernel.org>
---

Tested on 6.12.116 in an x86_64 User Mode Linux guest using the IPv4
reproducer above. With a learned PMTU of 1456, the unpatched kernel
advertised MSS 1460 and the 1 MiB upload timed out. The backport
advertised MSS 1416 and the upload completed. The IPv4 and IPv6
route objects also compiled on x86_64.

 include/net/ip.h        | 25 -------------------------
 include/net/ip6_route.h | 37 -------------------------------------
 net/ipv4/route.c        |  4 ++--
 net/ipv6/route.c        |  2 +-
 4 files changed, 3 insertions(+), 65 deletions(-)

diff --git a/include/net/ip.h b/include/net/ip.h
index 97c60b3..f00719e 100644
--- a/include/net/ip.h
+++ b/include/net/ip.h
@@ -515,31 +515,6 @@ out:
 	return res;
 }
 
-/* Configured/administrative MTU of a route, for advertising the TCP MSS.
- *
- * Unlike ip_dst_mtu_maybe_forward(), this deliberately ignores the
- * ICMP-learned path MTU (rt->rt_pmtu).  The advertised MSS bounds what the
- * peer may send to us and must reflect our receive capability (the device or
- * route-configured MTU), not a path MTU learned on the reverse (send)
- * direction, which may not apply to the peer->us path and outlives the fnhe
- * for the whole connection.  See RFC 2923 section 2.3 and the comment above
- * tcp_advertise_mss().
- */
-static inline unsigned int ip_dst_mtu_configured(const struct dst_entry *dst)
-{
-	unsigned int mtu, res;
-
-	rcu_read_lock();
-	mtu = dst_metric_raw(dst, RTAX_MTU);
-	if (!mtu)
-		mtu = READ_ONCE(dst_dev_rcu(dst)->mtu);
-	mtu = min_t(unsigned int, mtu, IP_MAX_MTU);
-	res = mtu - lwtunnel_headroom(dst->lwtstate, mtu);
-	rcu_read_unlock();
-
-	return res;
-}
-
 static inline unsigned int ip_skb_dst_mtu(struct sock *sk,
 					  const struct sk_buff *skb)
 {
diff --git a/include/net/ip6_route.h b/include/net/ip6_route.h
index 8be44dc..ad35c75 100644
--- a/include/net/ip6_route.h
+++ b/include/net/ip6_route.h
@@ -354,43 +354,6 @@ out:
 	return mtu - lwtunnel_headroom(dst->lwtstate, mtu);
 }
 
-/* Configured/administrative MTU of a route, for advertising the TCP MSS.
- *
- * Unlike ip6_dst_mtu_maybe_forward(), this ignores any ICMPv6-learned path
- * MTU (which is kept on the RTF_CACHE exception route) and returns the MTU of
- * the underlying route (fib6_pmtu) or the egress device.  The advertised MSS
- * bounds what the peer may send to us and must reflect our receive
- * capability, not a path MTU learned on the reverse (send) direction.  See
- * RFC 2923 section 2.3 and the comment above tcp_advertise_mss().
- */
-static inline unsigned int ip6_dst_mtu_configured(const struct dst_entry *dst)
-{
-	const struct rt6_info *rt = dst_rt6_info(dst);
-	const struct fib6_info *from;
-	struct inet6_dev *idev;
-	unsigned int mtu = 0;
-
-	rcu_read_lock();
-	/* IPv6 keeps the learned PMTU and the configured MTU in the same
-	 * RTAX_MTU slot: the learned value sits on this (possibly RTF_CACHE)
-	 * dst, the configured one on the underlying route.  Reach the latter
-	 * via ->from (fib6_pmtu), populated by ip6_route_info_create().
-	 */
-	from = rcu_dereference(rt->from);
-	if (from)
-		mtu = from->fib6_pmtu;
-	if (!mtu) {
-		mtu = IPV6_MIN_MTU;
-		idev = __in6_dev_get(dst_dev_rcu(dst));
-		if (idev)
-			mtu = max_t(unsigned int, mtu, READ_ONCE(idev->cnf.mtu6));
-	}
-	rcu_read_unlock();
-
-	mtu = min_t(unsigned int, mtu, IP6_MAX_MTU);
-	return mtu - lwtunnel_headroom(dst->lwtstate, mtu);
-}
-
 u32 ip6_mtu_from_fib6(const struct fib6_result *res,
 		      const struct in6_addr *daddr,
 		      const struct in6_addr *saddr);
diff --git a/net/ipv4/route.c b/net/ipv4/route.c
index 596c84f..f1b0ab7 100644
--- a/net/ipv4/route.c
+++ b/net/ipv4/route.c
@@ -1358,8 +1358,8 @@ static unsigned int ipv4_default_advmss(const struct dst_entry *dst)
 
 	rcu_read_lock();
 	net = dst_dev_net_rcu(dst);
-	advmss = max_t(unsigned int, ip_dst_mtu_configured(dst) - header_size,
-		       net->ipv4.ip_rt_min_advmss);
+	advmss = max_t(unsigned int, ipv4_mtu(dst) - header_size,
+				   net->ipv4.ip_rt_min_advmss);
 	rcu_read_unlock();
 
 	return min(advmss, IPV4_MAX_PMTU - header_size);
diff --git a/net/ipv6/route.c b/net/ipv6/route.c
index 1294029..742dce3 100644
--- a/net/ipv6/route.c
+++ b/net/ipv6/route.c
@@ -3252,7 +3252,7 @@ EXPORT_SYMBOL_GPL(ip6_sk_redirect);
 static unsigned int ip6_default_advmss(const struct dst_entry *dst)
 {
 	struct net_device *dev = dst_dev(dst);
-	unsigned int mtu = ip6_dst_mtu_configured(dst);
+	unsigned int mtu = dst6_mtu(dst);
 	struct net *net;
 
 	mtu -= sizeof(struct ipv6hdr) + sizeof(struct tcphdr);

base-commit: 5c40a1750f44dd6c7292d8c8d0b4ffff1734576e
-- 
2.54.0 (Apple Git-157)



