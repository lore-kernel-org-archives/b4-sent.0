From: Christoph Paasch <cpaasch@openai.com>
Date: Sat, 02 Aug 2025 16:52:22 -0700
Subject: [PATCH mptcp-next 1/2] mptcp: Add support for SO_MAX_PACING_RATE
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250802-b4-mptcp_setsockopt-v1-1-50d4905a4c2b@openai.com>
References: <20250802-b4-mptcp_setsockopt-v1-0-50d4905a4c2b@openai.com>
In-Reply-To: <20250802-b4-mptcp_setsockopt-v1-0-50d4905a4c2b@openai.com>
To: MPTCP Upstream <mptcp@lists.linux.dev>, 
 Matthieu Baerts <matttbe@kernel.org>, Mat Martineau <martineau@kernel.org>, 
 Geliang Tang <geliang@kernel.org>
Cc: Christoph Paasch <cpaasch@openai.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1754178751; l=3129;
 i=cpaasch@openai.com; s=20250712; h=from:subject:message-id;
 bh=N2ba+scj44k7tcJAqXwLJ7NphQMBR1SHDfj9Nxl+Mbg=;
 b=kbvG78jNcooG74sFqFb4/lLzfhnc1f0DfQhpGjPLTwKPcnW4NGFi+6JfSsrQLAsF0YMwfjs1Q
 1aE1EogCFfnAj9hOGg02kU6OLt5/Wvh36abwuw6NGOzyt3P+WzGzhEq
X-Developer-Key: i=cpaasch@openai.com; a=ed25519;
 pk=1HRHZlVUZPziMZvsAQFvP7n5+uEosTDAjXmNXykdxdg=
X-Endpoint-Received: by B4 Relay for cpaasch@openai.com/20250712 with auth_id=459
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support for SO_MAX_PACING_RATE. It will limit the rate of each
individual TCP subflow to the specified rate.

Signed-off-by: Christoph Paasch <cpaasch@openai.com>
---
 net/mptcp/sockopt.c | 31 ++++++++++++++++++++++++++++++-
 1 file changed, 30 insertions(+), 1 deletion(-)

diff --git a/net/mptcp/sockopt.c b/net/mptcp/sockopt.c
index 2c267aff95bec90d341de9f9e136b9d2df9b8e13..a79dfeb54a3fe0d8c26a1836ae5dda9fd2fdddea 100644
--- a/net/mptcp/sockopt.c
+++ b/net/mptcp/sockopt.c
@@ -308,6 +308,7 @@ static int mptcp_setsockopt_sol_socket(struct mptcp_sock *msk, int optname,
 
 		ret = sk_setsockopt(ssk, SOL_SOCKET, optname, optval, optlen);
 		if (ret == 0) {
+			/* Record the option at the msk for subsequent subflows */
 			if (optname == SO_REUSEPORT)
 				sk->sk_reuseport = ssk->sk_reuseport;
 			else if (optname == SO_REUSEADDR)
@@ -340,6 +341,25 @@ static int mptcp_setsockopt_sol_socket(struct mptcp_sock *msk, int optname,
 								optval, optlen);
 	case SO_LINGER:
 		return mptcp_setsockopt_sol_socket_linger(msk, optval, optlen);
+	case SO_MAX_PACING_RATE: {
+		struct mptcp_subflow_context *subflow;
+
+		ret = sock_setsockopt(sk->sk_socket, SOL_SOCKET, optname, optval, optlen);
+		if (ret < 0)
+			return ret;
+
+		lock_sock(sk);
+		sockopt_seq_inc(msk);
+
+		mptcp_for_each_subflow(msk, subflow) {
+			struct sock *ssk = mptcp_subflow_tcp_sock(subflow);
+
+			sk_setsockopt(ssk, SOL_SOCKET, optname, optval, optlen);
+		}
+
+		release_sock(sk);
+		break;
+	}
 	case SO_RCVLOWAT:
 	case SO_RCVTIMEO_OLD:
 	case SO_RCVTIMEO_NEW:
@@ -373,7 +393,6 @@ static int mptcp_setsockopt_sol_socket(struct mptcp_sock *msk, int optname,
 	 * explicitly the sk_protocol field
 	 *
 	 * SO_PEEK_OFF is unsupported, as it is for plain TCP
-	 * SO_MAX_PACING_RATE is unsupported, we must be careful with subflows
 	 * SO_CNX_ADVICE is currently unsupported, could possibly be relevant,
 	 * but likely needs careful design
 	 *
@@ -1532,6 +1551,7 @@ static void sync_socket_options(struct mptcp_sock *msk, struct sock *ssk)
 {
 	static const unsigned int tx_rx_locks = SOCK_RCVBUF_LOCK | SOCK_SNDBUF_LOCK;
 	struct sock *sk = (struct sock *)msk;
+	unsigned long max_pacing_rate;
 
 	if (ssk->sk_prot->keepalive) {
 		if (sock_flag(sk, SOCK_KEEPOPEN))
@@ -1579,6 +1599,15 @@ static void sync_socket_options(struct mptcp_sock *msk, struct sock *ssk)
 	tcp_sock_set_keepcnt(ssk, msk->keepalive_cnt);
 	tcp_sock_set_maxseg(ssk, msk->maxseg);
 
+	/* Keep pacing settings in sync as well. */
+	max_pacing_rate = READ_ONCE(sk->sk_max_pacing_rate);
+
+	WRITE_ONCE(ssk->sk_max_pacing_rate, max_pacing_rate);
+	if (max_pacing_rate != ~0UL)
+		cmpxchg(&ssk->sk_pacing_status, SK_PACING_NONE, SK_PACING_NEEDED);
+	if (READ_ONCE(ssk->sk_pacing_rate) > max_pacing_rate)
+		WRITE_ONCE(ssk->sk_pacing_rate, max_pacing_rate);
+
 	inet_assign_bit(TRANSPARENT, ssk, inet_test_bit(TRANSPARENT, sk));
 	inet_assign_bit(FREEBIND, ssk, inet_test_bit(FREEBIND, sk));
 	inet_assign_bit(BIND_ADDRESS_NO_PORT, ssk, inet_test_bit(BIND_ADDRESS_NO_PORT, sk));

-- 
2.50.1

