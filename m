From: Dmitry Safonov <0x7f454c46@gmail.com>
Date: Thu, 06 Jun 2024 01:58:20 +0100
Subject: [PATCH net-next v3 3/6] net/tcp: Move tcp_inbound_hash() from
 headers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240606-tcp_ao-tracepoints-v3-3-13621988c09f@gmail.com>
References: <20240606-tcp_ao-tracepoints-v3-0-13621988c09f@gmail.com>
In-Reply-To: <20240606-tcp_ao-tracepoints-v3-0-13621988c09f@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1717635508; l=6867;
 i=0x7f454c46@gmail.com; s=20240410; h=from:subject:message-id;
 bh=Dd2ukP5iKW0jcaezp4SBcW4kepUbg235wYTTT5Dy86c=;
 b=YCbhg7xSlQLexlrhSucVDWwi6NbvL5luBnfc2NcUT+SSaJH0dTMyEox6NELO8ZJKOmLGJ4PZdTv5
 kxxs6TacC35NHm6zoSndHMhygHUYBNeNUKaC8zpvWhhqb9sJecI0
X-Developer-Key: i=0x7f454c46@gmail.com; a=ed25519;
 pk=cFSWovqtkx0HrT5O9jFCEC/Cef4DY8a2FPeqP4THeZQ=
X-Endpoint-Received: by B4 Relay for 0x7f454c46@gmail.com/20240410 with auth_id=152
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Two reasons:
1. It's grown up enough
2. In order to not do header spaghetti by including
   <trace/events/tcp.h>, which is necessary for TCP tracepoints.

While at it, unexport and make static tcp_inbound_ao_hash().

Signed-off-by: Dmitry Safonov <0x7f454c46@gmail.com>
---
 include/net/tcp.h | 78 +++----------------------------------------------------
 net/ipv4/tcp.c    | 66 ++++++++++++++++++++++++++++++++++++++++++++--
 2 files changed, 68 insertions(+), 76 deletions(-)

diff --git a/include/net/tcp.h b/include/net/tcp.h
index e5427b05129b..2aac11e7e1cc 100644
--- a/include/net/tcp.h
+++ b/include/net/tcp.h
@@ -1863,12 +1863,6 @@ tcp_md5_do_lookup_any_l3index(const struct sock *sk,
 	return __tcp_md5_do_lookup(sk, 0, addr, family, true);
 }
 
-enum skb_drop_reason
-tcp_inbound_md5_hash(const struct sock *sk, const struct sk_buff *skb,
-		     const void *saddr, const void *daddr,
-		     int family, int l3index, const __u8 *hash_location);
-
-
 #define tcp_twsk_md5_key(twsk)	((twsk)->tw_md5_key)
 #else
 static inline struct tcp_md5sig_key *
@@ -1885,13 +1879,6 @@ tcp_md5_do_lookup_any_l3index(const struct sock *sk,
 	return NULL;
 }
 
-static inline enum skb_drop_reason
-tcp_inbound_md5_hash(const struct sock *sk, const struct sk_buff *skb,
-		     const void *saddr, const void *daddr,
-		     int family, int l3index, const __u8 *hash_location)
-{
-	return SKB_NOT_DROPPED_YET;
-}
 #define tcp_twsk_md5_key(twsk)	NULL
 #endif
 
@@ -2806,66 +2793,9 @@ static inline bool tcp_ao_required(struct sock *sk, const void *saddr,
 	return false;
 }
 
-/* Called with rcu_read_lock() */
-static inline enum skb_drop_reason
-tcp_inbound_hash(struct sock *sk, const struct request_sock *req,
-		 const struct sk_buff *skb,
-		 const void *saddr, const void *daddr,
-		 int family, int dif, int sdif)
-{
-	const struct tcphdr *th = tcp_hdr(skb);
-	const struct tcp_ao_hdr *aoh;
-	const __u8 *md5_location;
-	int l3index;
-
-	/* Invalid option or two times meet any of auth options */
-	if (tcp_parse_auth_options(th, &md5_location, &aoh)) {
-		tcp_hash_fail("TCP segment has incorrect auth options set",
-			      family, skb, "");
-		return SKB_DROP_REASON_TCP_AUTH_HDR;
-	}
-
-	if (req) {
-		if (tcp_rsk_used_ao(req) != !!aoh) {
-			NET_INC_STATS(sock_net(sk), LINUX_MIB_TCPAOBAD);
-			tcp_hash_fail("TCP connection can't start/end using TCP-AO",
-				      family, skb, "%s",
-				      !aoh ? "missing AO" : "AO signed");
-			return SKB_DROP_REASON_TCP_AOFAILURE;
-		}
-	}
-
-	/* sdif set, means packet ingressed via a device
-	 * in an L3 domain and dif is set to the l3mdev
-	 */
-	l3index = sdif ? dif : 0;
-
-	/* Fast path: unsigned segments */
-	if (likely(!md5_location && !aoh)) {
-		/* Drop if there's TCP-MD5 or TCP-AO key with any rcvid/sndid
-		 * for the remote peer. On TCP-AO established connection
-		 * the last key is impossible to remove, so there's
-		 * always at least one current_key.
-		 */
-		if (tcp_ao_required(sk, saddr, family, l3index, true)) {
-			tcp_hash_fail("AO hash is required, but not found",
-					family, skb, "L3 index %d", l3index);
-			return SKB_DROP_REASON_TCP_AONOTFOUND;
-		}
-		if (unlikely(tcp_md5_do_lookup(sk, l3index, saddr, family))) {
-			NET_INC_STATS(sock_net(sk), LINUX_MIB_TCPMD5NOTFOUND);
-			tcp_hash_fail("MD5 Hash not found",
-				      family, skb, "L3 index %d", l3index);
-			return SKB_DROP_REASON_TCP_MD5NOTFOUND;
-		}
-		return SKB_NOT_DROPPED_YET;
-	}
-
-	if (aoh)
-		return tcp_inbound_ao_hash(sk, skb, family, req, l3index, aoh);
-
-	return tcp_inbound_md5_hash(sk, skb, saddr, daddr, family,
-				    l3index, md5_location);
-}
+enum skb_drop_reason tcp_inbound_hash(struct sock *sk,
+		const struct request_sock *req, const struct sk_buff *skb,
+		const void *saddr, const void *daddr,
+		int family, int dif, int sdif);
 
 #endif	/* _TCP_H */
diff --git a/net/ipv4/tcp.c b/net/ipv4/tcp.c
index fa43aaacd92b..80ed5c099f11 100644
--- a/net/ipv4/tcp.c
+++ b/net/ipv4/tcp.c
@@ -4456,7 +4456,7 @@ int tcp_md5_hash_key(struct tcp_sigpool *hp,
 EXPORT_SYMBOL(tcp_md5_hash_key);
 
 /* Called with rcu_read_lock() */
-enum skb_drop_reason
+static enum skb_drop_reason
 tcp_inbound_md5_hash(const struct sock *sk, const struct sk_buff *skb,
 		     const void *saddr, const void *daddr,
 		     int family, int l3index, const __u8 *hash_location)
@@ -4510,10 +4510,72 @@ tcp_inbound_md5_hash(const struct sock *sk, const struct sk_buff *skb,
 	}
 	return SKB_NOT_DROPPED_YET;
 }
-EXPORT_SYMBOL(tcp_inbound_md5_hash);
 
 #endif
 
+/* Called with rcu_read_lock() */
+enum skb_drop_reason
+tcp_inbound_hash(struct sock *sk, const struct request_sock *req,
+		 const struct sk_buff *skb,
+		 const void *saddr, const void *daddr,
+		 int family, int dif, int sdif)
+{
+	const struct tcphdr *th = tcp_hdr(skb);
+	const struct tcp_ao_hdr *aoh;
+	const __u8 *md5_location;
+	int l3index;
+
+	/* Invalid option or two times meet any of auth options */
+	if (tcp_parse_auth_options(th, &md5_location, &aoh)) {
+		tcp_hash_fail("TCP segment has incorrect auth options set",
+			      family, skb, "");
+		return SKB_DROP_REASON_TCP_AUTH_HDR;
+	}
+
+	if (req) {
+		if (tcp_rsk_used_ao(req) != !!aoh) {
+			NET_INC_STATS(sock_net(sk), LINUX_MIB_TCPAOBAD);
+			tcp_hash_fail("TCP connection can't start/end using TCP-AO",
+				      family, skb, "%s",
+				      !aoh ? "missing AO" : "AO signed");
+			return SKB_DROP_REASON_TCP_AOFAILURE;
+		}
+	}
+
+	/* sdif set, means packet ingressed via a device
+	 * in an L3 domain and dif is set to the l3mdev
+	 */
+	l3index = sdif ? dif : 0;
+
+	/* Fast path: unsigned segments */
+	if (likely(!md5_location && !aoh)) {
+		/* Drop if there's TCP-MD5 or TCP-AO key with any rcvid/sndid
+		 * for the remote peer. On TCP-AO established connection
+		 * the last key is impossible to remove, so there's
+		 * always at least one current_key.
+		 */
+		if (tcp_ao_required(sk, saddr, family, l3index, true)) {
+			tcp_hash_fail("AO hash is required, but not found",
+				      family, skb, "L3 index %d", l3index);
+			return SKB_DROP_REASON_TCP_AONOTFOUND;
+		}
+		if (unlikely(tcp_md5_do_lookup(sk, l3index, saddr, family))) {
+			NET_INC_STATS(sock_net(sk), LINUX_MIB_TCPMD5NOTFOUND);
+			tcp_hash_fail("MD5 Hash not found",
+				      family, skb, "L3 index %d", l3index);
+			return SKB_DROP_REASON_TCP_MD5NOTFOUND;
+		}
+		return SKB_NOT_DROPPED_YET;
+	}
+
+	if (aoh)
+		return tcp_inbound_ao_hash(sk, skb, family, req, l3index, aoh);
+
+	return tcp_inbound_md5_hash(sk, skb, saddr, daddr, family,
+				    l3index, md5_location);
+}
+EXPORT_SYMBOL_GPL(tcp_inbound_hash);
+
 void tcp_done(struct sock *sk)
 {
 	struct request_sock *req;

-- 
2.42.0

