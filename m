From: Geoffrey Beausire <g.beausire@criteo.com>
Date: Mon, 09 Nov 2026 10:31:13 +0100
Subject: [PATCH nf-next] netfilter: nf_socket: avoid UDP socket refcounting
 in socket match
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261109-udp_rcu_b4-v1-1-1103f12d0a04@criteo.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAA/yWMQQrCMBQFr1Le2kBTpIpXESlN/ot+F7EkjRRK7
 95Ul8MwsyIzKTNuzYrEr2b9xAr21MC/xvikUamMru16a9veFJmG5MvgzkZ4ucoYgggdajAlBl1
 +sztiMJHLjMdf5OLe9POxwrbt7H8xF3cAAAA=
X-Change-ID: 20261106-udp_rcu_b4-de78daffddeb
To: Pablo Neira Ayuso <pablo@netfilter.org>, 
 Florian Westphal <fw@strlen.de>, Phil Sutter <phil@nwl.cc>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Simon Horman <horms@kernel.org>, 
 Willem de Bruijn <willemdebruijn.kernel@gmail.com>
Cc: netfilter-devel@vger.kernel.org, coreteam@netfilter.org, 
 netdev@vger.kernel.org, linux-kernel@vger.kernel.org, geobeausire@gmail.com, 
 Geoffrey Beausire <g.beausire@criteo.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794216674; l=11285;
 i=g.beausire@criteo.com; s=20261106; h=from:subject:message-id;
 bh=Bxs85xPWmCulUnJklXbG79UXIkW/V7342donIrEKj8E=;
 b=iUS53Y2/3T+3To7xQAkbvkwv1FGa57XbfswA23zIxk3uEMzOdwpZqhsPjQogpLQbc3fmFPMkw
 lQQyVhqr58iBrab6fd7oHm5UhPmvrkPExM5ucxKoS/Fsk4S0sr2Ehvk
X-Developer-Key: i=g.beausire@criteo.com; a=ed25519;
 pk=/sNso7Ag23yofC+89g8V5KjCpFJry4fQAZIzaohF0VU=
X-Endpoint-Received: by B4 Relay for g.beausire@criteo.com/20261106 with auth_id=1434
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Similar to commit 08842c43d016 ("udp: no longer touch sk->sk_refcnt in
early demux") and after commit ca065d0cf80f ("udp: no longer use
SLAB_DESTROY_BY_RCU"), the socket match no longer needs to grab a
refcount on UDP sockets, as xt_socket and nft_socket only use the
socket inside the netfilter hook, which runs under rcu_read_lock().

The release path is shared with TCP, where sockets are still returned
with a reference. Add a refcounted out-parameter to
nf_sk_lookup_slow_v4() and nf_sk_lookup_slow_v6() and put the socket
only when it is set, as commit 3b24d854cb35 ("tcp/dccp: do not touch
listener sk_refcnt under synflood") did for TCP listeners.

nf_socket no longer calls udp4_lib_lookup() and udp6_lib_lookup(), so
drop CONFIG_NF_SOCKET_IPV{4,6} from their #if.

The impact of the change was measured with a simple UDP load generator
aimed at a single UDP socket. It was tested on a host with dual Intel
Xeon 6787P sockets, where the RX was spread across all NUMA nodes and
both packages.

+--------+------------+------------+-------+
| Family | baseline   | patched    | Gain  |
+--------+------------+------------+-------+
| IPv4   |  4.47 Mpps | 27.22 Mpps | +509% |
| IPv6   |  4.19 Mpps | 25.27 Mpps | +503% |
+--------+------------+------------+-------+

This was seen in production when routing traffic through Cilium's
VXLAN, where all of the server's traffic goes through a single UDP
socket. Softirq threads spent most of their time in udp4_lib_lookup()
and sock_gen_put(). Softirq were saturated at 2M UDP packets/s. After
this patch, the servers were able to handle the full production traffic
of 5M UDP packets/s with headroom left. This patch has been deployed on
the wider fleet of servers for the last 2 months without issues. The
synthetic benchmark above models the extreme case where the CPUs only
process UDP traffic.

Signed-off-by: Geoffrey Beausire <g.beausire@criteo.com>
---
 include/net/netfilter/nf_socket.h   |  6 ++++--
 net/ipv4/netfilter/nf_socket_ipv4.c | 14 +++++++++-----
 net/ipv4/udp.c                      |  2 +-
 net/ipv6/netfilter/nf_socket_ipv6.c | 14 +++++++++-----
 net/ipv6/udp.c                      |  2 +-
 net/netfilter/nft_socket.c          | 12 +++++++-----
 net/netfilter/xt_socket.c           | 12 ++++++++----
 7 files changed, 39 insertions(+), 23 deletions(-)

diff --git a/include/net/netfilter/nf_socket.h b/include/net/netfilter/nf_socket.h
index f9d7bee9bd4e..5a5ddf4e820a 100644
--- a/include/net/netfilter/nf_socket.h
+++ b/include/net/netfilter/nf_socket.h
@@ -5,9 +5,11 @@
 #include <net/sock.h>
 
 struct sock *nf_sk_lookup_slow_v4(struct net *net, const struct sk_buff *skb,
-				  const struct net_device *indev);
+				  const struct net_device *indev,
+				  bool *refcounted);
 
 struct sock *nf_sk_lookup_slow_v6(struct net *net, const struct sk_buff *skb,
-				  const struct net_device *indev);
+				  const struct net_device *indev,
+				  bool *refcounted);
 
 #endif
diff --git a/net/ipv4/netfilter/nf_socket_ipv4.c b/net/ipv4/netfilter/nf_socket_ipv4.c
index f9c6755f5ec5..0609f31e4082 100644
--- a/net/ipv4/netfilter/nf_socket_ipv4.c
+++ b/net/ipv4/netfilter/nf_socket_ipv4.c
@@ -67,21 +67,23 @@ nf_socket_get_sock_v4(struct net *net, struct sk_buff *skb, const int doff,
 		      const u8 protocol,
 		      const __be32 saddr, const __be32 daddr,
 		      const __be16 sport, const __be16 dport,
-		      const struct net_device *in)
+		      const struct net_device *in, bool *refcounted)
 {
 	switch (protocol) {
 	case IPPROTO_TCP:
+		*refcounted = true;
 		return inet_lookup(net, skb, doff, saddr, sport, daddr, dport,
 				   in->ifindex);
 	case IPPROTO_UDP:
-		return udp4_lib_lookup(net, saddr, sport, daddr, dport,
-				       in->ifindex);
+		return __udp4_lib_lookup(net, saddr, sport, daddr, dport,
+					 in->ifindex, 0, NULL);
 	}
 	return NULL;
 }
 
 struct sock *nf_sk_lookup_slow_v4(struct net *net, const struct sk_buff *skb,
-				  const struct net_device *indev)
+				  const struct net_device *indev,
+				  bool *refcounted)
 {
 	__be32 daddr, saddr;
 	__be16 dport, sport;
@@ -94,6 +96,8 @@ struct sock *nf_sk_lookup_slow_v4(struct net *net, const struct sk_buff *skb,
 #endif
 	int doff = 0;
 
+	*refcounted = false;
+
 	if (ntohs(iph->frag_off) & IP_OFFSET)
 		return NULL;
 
@@ -146,7 +150,7 @@ struct sock *nf_sk_lookup_slow_v4(struct net *net, const struct sk_buff *skb,
 #endif
 
 	return nf_socket_get_sock_v4(net, data_skb, doff, protocol, saddr,
-				     daddr, sport, dport, indev);
+				     daddr, sport, dport, indev, refcounted);
 }
 EXPORT_SYMBOL_GPL(nf_sk_lookup_slow_v4);
 
diff --git a/net/ipv4/udp.c b/net/ipv4/udp.c
index 303d0102519a..c8966b755cd0 100644
--- a/net/ipv4/udp.c
+++ b/net/ipv4/udp.c
@@ -770,7 +770,7 @@ struct sock *udp4_lib_lookup_skb(const struct sk_buff *skb,
 /* Must be called under rcu_read_lock().
  * Does increment socket refcount.
  */
-#if IS_ENABLED(CONFIG_NF_TPROXY_IPV4) || IS_ENABLED(CONFIG_NF_SOCKET_IPV4)
+#if IS_ENABLED(CONFIG_NF_TPROXY_IPV4)
 struct sock *udp4_lib_lookup(const struct net *net, __be32 saddr, __be16 sport,
 			     __be32 daddr, __be16 dport, int dif)
 {
diff --git a/net/ipv6/netfilter/nf_socket_ipv6.c b/net/ipv6/netfilter/nf_socket_ipv6.c
index 893f2aeb4711..4f5bd635fd4a 100644
--- a/net/ipv6/netfilter/nf_socket_ipv6.c
+++ b/net/ipv6/netfilter/nf_socket_ipv6.c
@@ -79,22 +79,24 @@ nf_socket_get_sock_v6(struct net *net, struct sk_buff *skb, int doff,
 		      const u8 protocol,
 		      const struct in6_addr *saddr, const struct in6_addr *daddr,
 		      const __be16 sport, const __be16 dport,
-		      const struct net_device *in)
+		      const struct net_device *in, bool *refcounted)
 {
 	switch (protocol) {
 	case IPPROTO_TCP:
+		*refcounted = true;
 		return inet6_lookup(net, skb, doff, saddr, sport, daddr, dport,
 				    in->ifindex);
 	case IPPROTO_UDP:
-		return udp6_lib_lookup(net, saddr, sport, daddr, dport,
-				       in->ifindex);
+		return __udp6_lib_lookup(net, saddr, sport, daddr, dport,
+					 in->ifindex, 0, NULL);
 	}
 
 	return NULL;
 }
 
 struct sock *nf_sk_lookup_slow_v6(struct net *net, const struct sk_buff *skb,
-				  const struct net_device *indev)
+				  const struct net_device *indev,
+				  bool *refcounted)
 {
 	__be16 dport, sport;
 	const struct in6_addr *daddr = NULL, *saddr = NULL;
@@ -108,6 +110,8 @@ struct sock *nf_sk_lookup_slow_v6(struct net *net, const struct sk_buff *skb,
 	struct nf_conn const *ct;
 #endif
 
+	*refcounted = false;
+
 	tproto = ipv6_find_hdr(skb, &thoff, -1, &fragoff, NULL);
 	if (tproto < 0 || fragoff) {
 		pr_debug("unable to find transport header in IPv6 packet, dropping\n");
@@ -160,7 +164,7 @@ struct sock *nf_sk_lookup_slow_v6(struct net *net, const struct sk_buff *skb,
 #endif
 
 	return nf_socket_get_sock_v6(net, data_skb, doff, tproto, saddr, daddr,
-				     sport, dport, indev);
+				     sport, dport, indev, refcounted);
 }
 EXPORT_SYMBOL_GPL(nf_sk_lookup_slow_v6);
 
diff --git a/net/ipv6/udp.c b/net/ipv6/udp.c
index 59f9872c3552..bd2abfd00271 100644
--- a/net/ipv6/udp.c
+++ b/net/ipv6/udp.c
@@ -432,7 +432,7 @@ struct sock *udp6_lib_lookup_skb(const struct sk_buff *skb,
 /* Must be called under rcu_read_lock().
  * Does increment socket refcount.
  */
-#if IS_ENABLED(CONFIG_NF_TPROXY_IPV6) || IS_ENABLED(CONFIG_NF_SOCKET_IPV6)
+#if IS_ENABLED(CONFIG_NF_TPROXY_IPV6)
 struct sock *udp6_lib_lookup(const struct net *net, const struct in6_addr *saddr, __be16 sport,
 			     const struct in6_addr *daddr, __be16 dport, int dif)
 {
diff --git a/net/netfilter/nft_socket.c b/net/netfilter/nft_socket.c
index 52d892e04261..23b7a66c2b57 100644
--- a/net/netfilter/nft_socket.c
+++ b/net/netfilter/nft_socket.c
@@ -80,7 +80,8 @@ static noinline int nft_socket_cgroup_subtree_level(void)
 }
 #endif
 
-static struct sock *nft_socket_do_lookup(const struct nft_pktinfo *pkt)
+static struct sock *nft_socket_do_lookup(const struct nft_pktinfo *pkt,
+					 bool *refcounted)
 {
 	const struct net_device *indev = nft_in(pkt);
 	const struct sk_buff *skb = pkt->skb;
@@ -91,11 +92,11 @@ static struct sock *nft_socket_do_lookup(const struct nft_pktinfo *pkt)
 
 	switch (nft_pf(pkt)) {
 	case NFPROTO_IPV4:
-		sk = nf_sk_lookup_slow_v4(nft_net(pkt), skb, indev);
+		sk = nf_sk_lookup_slow_v4(nft_net(pkt), skb, indev, refcounted);
 		break;
 #if IS_ENABLED(CONFIG_NF_TABLES_IPV6)
 	case NFPROTO_IPV6:
-		sk = nf_sk_lookup_slow_v6(nft_net(pkt), skb, indev);
+		sk = nf_sk_lookup_slow_v6(nft_net(pkt), skb, indev, refcounted);
 		break;
 #endif
 	default:
@@ -114,12 +115,13 @@ static void nft_socket_eval(const struct nft_expr *expr,
 	struct sk_buff *skb = pkt->skb;
 	struct sock *sk = skb->sk;
 	u32 *dest = &regs->data[priv->dreg];
+	bool refcounted = false;
 
 	if (sk && !net_eq(nft_net(pkt), sock_net(sk)))
 		sk = NULL;
 
 	if (!sk)
-		sk = nft_socket_do_lookup(pkt);
+		sk = nft_socket_do_lookup(pkt, &refcounted);
 
 	if (!sk) {
 		regs->verdict.code = NFT_BREAK;
@@ -159,7 +161,7 @@ static void nft_socket_eval(const struct nft_expr *expr,
 	}
 
 out_put_sk:
-	if (sk != skb->sk)
+	if (refcounted)
 		sock_gen_put(sk);
 }
 
diff --git a/net/netfilter/xt_socket.c b/net/netfilter/xt_socket.c
index 811e53bee408..a4232744c13e 100644
--- a/net/netfilter/xt_socket.c
+++ b/net/netfilter/xt_socket.c
@@ -51,12 +51,14 @@ socket_match(const struct sk_buff *skb, struct xt_action_param *par,
 {
 	struct sk_buff *pskb = (struct sk_buff *)skb;
 	struct sock *sk = skb->sk;
+	bool refcounted = false;
 
 	if (sk && !net_eq(xt_net(par), sock_net(sk)))
 		sk = NULL;
 
 	if (!sk)
-		sk = nf_sk_lookup_slow_v4(xt_net(par), skb, xt_in(par));
+		sk = nf_sk_lookup_slow_v4(xt_net(par), skb, xt_in(par),
+					  &refcounted);
 
 	if (sk) {
 		bool wildcard;
@@ -79,7 +81,7 @@ socket_match(const struct sk_buff *skb, struct xt_action_param *par,
 		    transparent && sk_fullsock(sk))
 			pskb->mark = READ_ONCE(sk->sk_mark);
 
-		if (sk != skb->sk)
+		if (refcounted)
 			sock_gen_put(sk);
 
 		if (wildcard || !transparent)
@@ -112,12 +114,14 @@ socket_mt6_v1_v2_v3(const struct sk_buff *skb, struct xt_action_param *par)
 	const struct xt_socket_mtinfo1 *info = (struct xt_socket_mtinfo1 *) par->matchinfo;
 	struct sk_buff *pskb = (struct sk_buff *)skb;
 	struct sock *sk = skb->sk;
+	bool refcounted = false;
 
 	if (sk && !net_eq(xt_net(par), sock_net(sk)))
 		sk = NULL;
 
 	if (!sk)
-		sk = nf_sk_lookup_slow_v6(xt_net(par), skb, xt_in(par));
+		sk = nf_sk_lookup_slow_v6(xt_net(par), skb, xt_in(par),
+					  &refcounted);
 
 	if (sk) {
 		bool wildcard;
@@ -140,7 +144,7 @@ socket_mt6_v1_v2_v3(const struct sk_buff *skb, struct xt_action_param *par)
 		    transparent && sk_fullsock(sk))
 			pskb->mark = READ_ONCE(sk->sk_mark);
 
-		if (sk != skb->sk)
+		if (refcounted)
 			sock_gen_put(sk);
 
 		if (wildcard || !transparent)

---
base-commit: 734bef548a96e8774d6eef5dfa2026c6edc4e80b
change-id: 20261106-udp_rcu_b4-de78daffddeb

Best regards,
--  
Geoffrey Beausire <g.beausire@criteo.com>

