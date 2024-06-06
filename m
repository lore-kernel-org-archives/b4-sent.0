From: Dmitry Safonov <0x7f454c46@gmail.com>
Date: Fri, 07 Jun 2024 00:25:59 +0100
Subject: [PATCH net-next v4 5/6] net/tcp: Remove tcp_hash_fail()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240607-tcp_ao-tracepoints-v4-5-88dc245c1f39@gmail.com>
References: <20240607-tcp_ao-tracepoints-v4-0-88dc245c1f39@gmail.com>
In-Reply-To: <20240607-tcp_ao-tracepoints-v4-0-88dc245c1f39@gmail.com>
To: Eric Dumazet <edumazet@google.com>, 
 "David S. Miller" <davem@davemloft.net>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, David Ahern <dsahern@kernel.org>, 
 Steven Rostedt <rostedt@goodmis.org>, 
 Masami Hiramatsu <mhiramat@kernel.org>, 
 Mathieu Desnoyers <mathieu.desnoyers@efficios.com>, 
 Jonathan Corbet <corbet@lwn.net>
Cc: Mohammad Nassiri <mnassiri@ciena.com>, Simon Horman <horms@kernel.org>, 
 netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-trace-kernel@vger.kernel.org, linux-doc@vger.kernel.org, 
 Dmitry Safonov <0x7f454c46@gmail.com>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1717716372; l=6884;
 i=0x7f454c46@gmail.com; s=20240410; h=from:subject:message-id;
 bh=iI1QuQn/WV57Q/5QybXoBMlHJT+xVotZFC21q+QQz/E=;
 b=Y2ES53ESb7+EjRFs6X6xwVyTs5dJFwHBbmBiSOBzxS9a6rLRDWDu/vYccVHSNf2XtdlZmtR8WNGH
 jV7JEoF4Diz1oumDfBs5p5P5UcENr5LMHzoFIrA88ji5BtLLV/1S
X-Developer-Key: i=0x7f454c46@gmail.com; a=ed25519;
 pk=cFSWovqtkx0HrT5O9jFCEC/Cef4DY8a2FPeqP4THeZQ=
X-Endpoint-Received: by B4 Relay for 0x7f454c46@gmail.com/20240410 with auth_id=152
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Now there are tracepoints, that cover all functionality of
tcp_hash_fail(), but also wire up missing places
They are also faster, can be disabled and provide filtering.

This potentially may create a regression if a userspace depends on dmesg
logs. Fingers crossed, let's see if anyone complains in reality.

Reviewed-by: Eric Dumazet <edumazet@google.com>
Signed-off-by: Dmitry Safonov <0x7f454c46@gmail.com>
---
 include/net/tcp_ao.h | 37 -------------------------------------
 net/ipv4/tcp.c       | 25 -------------------------
 net/ipv4/tcp_ao.c    |  9 ---------
 3 files changed, 71 deletions(-)

diff --git a/include/net/tcp_ao.h b/include/net/tcp_ao.h
index 198e02004ad2..1d46460d0fef 100644
--- a/include/net/tcp_ao.h
+++ b/include/net/tcp_ao.h
@@ -149,43 +149,6 @@ extern struct static_key_false_deferred tcp_ao_needed;
 #define static_branch_tcp_ao()	false
 #endif
 
-static inline bool tcp_hash_should_produce_warnings(void)
-{
-	return static_branch_tcp_md5() || static_branch_tcp_ao();
-}
-
-#define tcp_hash_fail(msg, family, skb, fmt, ...)			\
-do {									\
-	const struct tcphdr *th = tcp_hdr(skb);				\
-	char hdr_flags[6];						\
-	char *f = hdr_flags;						\
-									\
-	if (!tcp_hash_should_produce_warnings())			\
-		break;							\
-	if (th->fin)							\
-		*f++ = 'F';						\
-	if (th->syn)							\
-		*f++ = 'S';						\
-	if (th->rst)							\
-		*f++ = 'R';						\
-	if (th->psh)							\
-		*f++ = 'P';						\
-	if (th->ack)							\
-		*f++ = '.';						\
-	*f = 0;								\
-	if ((family) == AF_INET) {					\
-		net_info_ratelimited("%s for %pI4.%d->%pI4.%d [%s] " fmt "\n", \
-				msg, &ip_hdr(skb)->saddr, ntohs(th->source), \
-				&ip_hdr(skb)->daddr, ntohs(th->dest),	\
-				hdr_flags, ##__VA_ARGS__);		\
-	} else {							\
-		net_info_ratelimited("%s for [%pI6c].%d->[%pI6c].%d [%s]" fmt "\n", \
-				msg, &ipv6_hdr(skb)->saddr, ntohs(th->source), \
-				&ipv6_hdr(skb)->daddr, ntohs(th->dest),	\
-				hdr_flags, ##__VA_ARGS__);		\
-	}								\
-} while (0)
-
 #ifdef CONFIG_TCP_AO
 /* TCP-AO structures and functions */
 struct tcp4_ao_context {
diff --git a/net/ipv4/tcp.c b/net/ipv4/tcp.c
index 73152ce1367e..e03a342c9162 100644
--- a/net/ipv4/tcp.c
+++ b/net/ipv4/tcp.c
@@ -4484,7 +4484,6 @@ tcp_inbound_md5_hash(const struct sock *sk, const struct sk_buff *skb,
 
 	if (!key && hash_location) {
 		NET_INC_STATS(sock_net(sk), LINUX_MIB_TCPMD5UNEXPECTED);
-		tcp_hash_fail("Unexpected MD5 Hash found", family, skb, "");
 		trace_tcp_hash_md5_unexpected(sk, skb);
 		return SKB_DROP_REASON_TCP_MD5UNEXPECTED;
 	}
@@ -4500,21 +4499,6 @@ tcp_inbound_md5_hash(const struct sock *sk, const struct sk_buff *skb,
 							 NULL, skb);
 	if (genhash || memcmp(hash_location, newhash, 16) != 0) {
 		NET_INC_STATS(sock_net(sk), LINUX_MIB_TCPMD5FAILURE);
-		if (family == AF_INET) {
-			tcp_hash_fail("MD5 Hash failed", AF_INET, skb, "%s L3 index %d",
-				      genhash ? "tcp_v4_calc_md5_hash failed"
-				      : "", l3index);
-		} else {
-			if (genhash) {
-				tcp_hash_fail("MD5 Hash failed",
-					      AF_INET6, skb, "L3 index %d",
-					      l3index);
-			} else {
-				tcp_hash_fail("MD5 Hash mismatch",
-					      AF_INET6, skb, "L3 index %d",
-					      l3index);
-			}
-		}
 		trace_tcp_hash_md5_mismatch(sk, skb);
 		return SKB_DROP_REASON_TCP_MD5FAILURE;
 	}
@@ -4545,8 +4529,6 @@ tcp_inbound_hash(struct sock *sk, const struct request_sock *req,
 
 	/* Invalid option or two times meet any of auth options */
 	if (tcp_parse_auth_options(th, &md5_location, &aoh)) {
-		tcp_hash_fail("TCP segment has incorrect auth options set",
-			      family, skb, "");
 		trace_tcp_hash_bad_header(sk, skb);
 		return SKB_DROP_REASON_TCP_AUTH_HDR;
 	}
@@ -4564,9 +4546,6 @@ tcp_inbound_hash(struct sock *sk, const struct request_sock *req,
 			}
 
 			NET_INC_STATS(sock_net(sk), LINUX_MIB_TCPAOBAD);
-			tcp_hash_fail("TCP connection can't start/end using TCP-AO",
-				      family, skb, "%s",
-				      !aoh ? "missing AO" : "AO signed");
 			trace_tcp_ao_handshake_failure(sk, skb, keyid, rnext, maclen);
 			return SKB_DROP_REASON_TCP_AOFAILURE;
 		}
@@ -4585,15 +4564,11 @@ tcp_inbound_hash(struct sock *sk, const struct request_sock *req,
 		 * always at least one current_key.
 		 */
 		if (tcp_ao_required(sk, saddr, family, l3index, true)) {
-			tcp_hash_fail("AO hash is required, but not found",
-				      family, skb, "L3 index %d", l3index);
 			trace_tcp_hash_ao_required(sk, skb);
 			return SKB_DROP_REASON_TCP_AONOTFOUND;
 		}
 		if (unlikely(tcp_md5_do_lookup(sk, l3index, saddr, family))) {
 			NET_INC_STATS(sock_net(sk), LINUX_MIB_TCPMD5NOTFOUND);
-			tcp_hash_fail("MD5 Hash not found",
-				      family, skb, "L3 index %d", l3index);
 			trace_tcp_hash_md5_required(sk, skb);
 			return SKB_DROP_REASON_TCP_MD5NOTFOUND;
 		}
diff --git a/net/ipv4/tcp_ao.c b/net/ipv4/tcp_ao.c
index 1e5087c6cd7d..0de863aa5f66 100644
--- a/net/ipv4/tcp_ao.c
+++ b/net/ipv4/tcp_ao.c
@@ -893,9 +893,6 @@ tcp_ao_verify_hash(const struct sock *sk, const struct sk_buff *skb,
 		NET_INC_STATS(sock_net(sk), LINUX_MIB_TCPAOBAD);
 		atomic64_inc(&info->counters.pkt_bad);
 		atomic64_inc(&key->pkt_bad);
-		tcp_hash_fail("AO hash wrong length", family, skb,
-			      "%u != %d L3index: %d", maclen,
-			      tcp_ao_maclen(key), l3index);
 		trace_tcp_ao_wrong_maclen(sk, skb, aoh->keyid,
 					  aoh->rnext_keyid, maclen);
 		return SKB_DROP_REASON_TCP_AOFAILURE;
@@ -912,8 +909,6 @@ tcp_ao_verify_hash(const struct sock *sk, const struct sk_buff *skb,
 		NET_INC_STATS(sock_net(sk), LINUX_MIB_TCPAOBAD);
 		atomic64_inc(&info->counters.pkt_bad);
 		atomic64_inc(&key->pkt_bad);
-		tcp_hash_fail("AO hash mismatch", family, skb,
-			      "L3index: %d", l3index);
 		trace_tcp_ao_mismatch(sk, skb, aoh->keyid,
 				      aoh->rnext_keyid, maclen);
 		kfree(hash_buf);
@@ -945,8 +940,6 @@ tcp_inbound_ao_hash(struct sock *sk, const struct sk_buff *skb,
 	info = rcu_dereference(tcp_sk(sk)->ao_info);
 	if (!info) {
 		NET_INC_STATS(sock_net(sk), LINUX_MIB_TCPAOKEYNOTFOUND);
-		tcp_hash_fail("AO key not found", family, skb,
-			      "keyid: %u L3index: %d", aoh->keyid, l3index);
 		trace_tcp_ao_key_not_found(sk, skb, aoh->keyid,
 					   aoh->rnext_keyid, maclen);
 		return SKB_DROP_REASON_TCP_AOUNEXPECTED;
@@ -1057,8 +1050,6 @@ tcp_inbound_ao_hash(struct sock *sk, const struct sk_buff *skb,
 key_not_found:
 	NET_INC_STATS(sock_net(sk), LINUX_MIB_TCPAOKEYNOTFOUND);
 	atomic64_inc(&info->counters.key_not_found);
-	tcp_hash_fail("Requested by the peer AO key id not found",
-		      family, skb, "L3index: %d", l3index);
 	trace_tcp_ao_key_not_found(sk, skb, aoh->keyid,
 				   aoh->rnext_keyid, maclen);
 	return SKB_DROP_REASON_TCP_AOKEYNOTFOUND;

-- 
2.42.0

