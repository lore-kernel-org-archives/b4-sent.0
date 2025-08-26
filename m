From: Christoph Paasch <cpaasch@openai.com>
Date: Mon, 25 Aug 2025 21:30:35 -0700
Subject: [PATCH mptcp-next v2 1/2] net: Add rfs_needed() helper
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250825-b4-mptcp_perf-v2-1-5d2d68dfa8af@openai.com>
References: <20250825-b4-mptcp_perf-v2-0-5d2d68dfa8af@openai.com>
In-Reply-To: <20250825-b4-mptcp_perf-v2-0-5d2d68dfa8af@openai.com>
To: MPTCP Upstream <mptcp@lists.linux.dev>, 
 Matthieu Baerts <matttbe@kernel.org>, Mat Martineau <martineau@kernel.org>, 
 Geliang Tang <geliang@kernel.org>
Cc: Christoph Paasch <cpaasch@openai.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1756182640; l=4195;
 i=cpaasch@openai.com; s=20250712; h=from:subject:message-id;
 bh=hczrtQn/VnlkwtL/kYfRGTXynFOQ/BUCOfJNPKmURV4=;
 b=QbiyJ+prCQ91iUSOu+1jQx+KqoKpFJInbdvr2x6/LeeKelrVjX+vmRsbtn2bgA0tht1RlV3at
 hcHzkv3ZNM8BFNcaWYuc5fy5r4dmEQRDBRTkclWoL21tL/DYmdbV3ze
X-Developer-Key: i=cpaasch@openai.com; a=ed25519;
 pk=1HRHZlVUZPziMZvsAQFvP7n5+uEosTDAjXmNXykdxdg=
X-Endpoint-Received: by B4 Relay for cpaasch@openai.com/20250712 with auth_id=459
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a helper to check if RFS is needed or not. Allows to make the code a
bit cleaner and the next patch to have MPTCP use this helper to decide
whether or not to iterate over the subflows.

tun_flow_update() was calling sock_rps_record_flow_hash() regardless of
the state of rfs_needed. This was not really a bug as sock_flow_table
simply ends up being NULL and thus everything will be fine.
This commit here thus also implicitly makes tun_flow_update() respect
the state of rfs_needed.

Suggested-by: Matthieu Baerts <matttbe@kernel.org>
Signed-off-by: Christoph Paasch <cpaasch@openai.com>
---
 include/net/rps.h | 85 ++++++++++++++++++++++++++++++++++++-------------------
 1 file changed, 56 insertions(+), 29 deletions(-)

diff --git a/include/net/rps.h b/include/net/rps.h
index d8ab3a08bcc4882e2ad9c84c22ef26b254c14680..a89d2822a257a1fcf54e9722fdc22d01c28cc87b 100644
--- a/include/net/rps.h
+++ b/include/net/rps.h
@@ -82,11 +82,8 @@ static inline void rps_record_sock_flow(struct rps_sock_flow_table *table,
 		WRITE_ONCE(table->ents[index], val);
 }
 
-#endif /* CONFIG_RPS */
-
-static inline void sock_rps_record_flow_hash(__u32 hash)
+static inline void _sock_rps_record_flow_hash(__u32 hash)
 {
-#ifdef CONFIG_RPS
 	struct rps_sock_flow_table *sock_flow_table;
 
 	if (!hash)
@@ -96,42 +93,33 @@ static inline void sock_rps_record_flow_hash(__u32 hash)
 	if (sock_flow_table)
 		rps_record_sock_flow(sock_flow_table, hash);
 	rcu_read_unlock();
-#endif
 }
 
-static inline void sock_rps_record_flow(const struct sock *sk)
+static inline void _sock_rps_record_flow(const struct sock *sk)
 {
-#ifdef CONFIG_RPS
-	if (static_branch_unlikely(&rfs_needed)) {
-		/* Reading sk->sk_rxhash might incur an expensive cache line
-		 * miss.
-		 *
-		 * TCP_ESTABLISHED does cover almost all states where RFS
-		 * might be useful, and is cheaper [1] than testing :
-		 *	IPv4: inet_sk(sk)->inet_daddr
-		 * 	IPv6: ipv6_addr_any(&sk->sk_v6_daddr)
-		 * OR	an additional socket flag
-		 * [1] : sk_state and sk_prot are in the same cache line.
+	/* Reading sk->sk_rxhash might incur an expensive cache line
+	 * miss.
+	 *
+	 * TCP_ESTABLISHED does cover almost all states where RFS
+	 * might be useful, and is cheaper [1] than testing :
+	 *	IPv4: inet_sk(sk)->inet_daddr
+	 *	IPv6: ipv6_addr_any(&sk->sk_v6_daddr)
+	 * OR	an additional socket flag
+	 * [1] : sk_state and sk_prot are in the same cache line.
+	 */
+	if (sk->sk_state == TCP_ESTABLISHED) {
+		/* This READ_ONCE() is paired with the WRITE_ONCE()
+		 * from sock_rps_save_rxhash() and sock_rps_reset_rxhash().
 		 */
-		if (sk->sk_state == TCP_ESTABLISHED) {
-			/* This READ_ONCE() is paired with the WRITE_ONCE()
-			 * from sock_rps_save_rxhash() and sock_rps_reset_rxhash().
-			 */
-			sock_rps_record_flow_hash(READ_ONCE(sk->sk_rxhash));
-		}
+		_sock_rps_record_flow_hash(READ_ONCE(sk->sk_rxhash));
 	}
-#endif
 }
 
-static inline void sock_rps_delete_flow(const struct sock *sk)
+static inline void _sock_rps_delete_flow(const struct sock *sk)
 {
-#ifdef CONFIG_RPS
 	struct rps_sock_flow_table *table;
 	u32 hash, index;
 
-	if (!static_branch_unlikely(&rfs_needed))
-		return;
-
 	hash = READ_ONCE(sk->sk_rxhash);
 	if (!hash)
 		return;
@@ -144,6 +132,45 @@ static inline void sock_rps_delete_flow(const struct sock *sk)
 			WRITE_ONCE(table->ents[index], RPS_NO_CPU);
 	}
 	rcu_read_unlock();
+}
+#endif /* CONFIG_RPS */
+
+static inline bool rfs_is_needed(void)
+{
+#ifdef CONFIG_RPS
+	return static_branch_unlikely(&rfs_needed);
+#else
+	return false;
+#endif
+}
+
+static inline void sock_rps_record_flow_hash(__u32 hash)
+{
+#ifdef CONFIG_RPS
+	if (!rfs_is_needed())
+		return;
+
+	_sock_rps_record_flow_hash(hash);
+#endif
+}
+
+static inline void sock_rps_record_flow(const struct sock *sk)
+{
+#ifdef CONFIG_RPS
+	if (!rfs_is_needed())
+		return;
+
+	_sock_rps_record_flow(sk);
+#endif
+}
+
+static inline void sock_rps_delete_flow(const struct sock *sk)
+{
+#ifdef CONFIG_RPS
+	if (!rfs_is_needed())
+		return;
+
+	_sock_rps_delete_flow(sk);
 #endif
 }
 

-- 
2.50.1

