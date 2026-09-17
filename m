From: Quanye Yang <quanyeyang@proton.me>
Date: Thu, 17 Sep 2026 06:41:23 -0700
Subject: [PATCH net-next v4 2/2] mptcp: annotate lockless access to
 sk->sk_err
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260917-mptcp-sk-err-net-v4-2-1f04f52f2561@proton.me>
References: <20260917-mptcp-sk-err-net-v4-0-1f04f52f2561@proton.me>
In-Reply-To: <20260917-mptcp-sk-err-net-v4-0-1f04f52f2561@proton.me>
To: Eric Dumazet <edumazet@google.com>, 
 Neal Cardwell <ncardwell@google.com>, Kuniyuki Iwashima <kuniyu@google.com>, 
 "David S. Miller" <davem@davemloft.net>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Simon Horman <horms@kernel.org>, 
 "Matthieu Baerts (NGI0)" <matttbe@kernel.org>, 
 Geliang Tang <geliang@kernel.org>, Mat Martineau <martineau@kernel.org>, 
 Jiayuan Chen <jiayuan.chen@linux.dev>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789652484; l=2705;
 i=quanyeyang@proton.me; s=20260801; h=from:subject:message-id;
 bh=ihY4XRH9RMhjOfpeeT8tP21amLumdct00zIA9m8+V+0=;
 b=aVmi+5F/8xiss5rWi3toBzgrunkk83nLr2KlK9bCozxOF/I0HOGOHLYCcS31Cmj8ypY5PZdpX
 PMwW+Qzqs6mDMbvOaz+KlBtStYkgNFM/Rgb851whA+mkCgBJtLLcWzl
X-Developer-Key: i=quanyeyang@proton.me; a=ed25519;
 pk=9L9FrcvzMgxPaBRU6XV0EnqTgjDqVO596rQKSZ9qZoY=
X-Endpoint-Received: by B4 Relay for quanyeyang@proton.me/20260801 with auth_id=963
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

sock_error() can clear sk_err with xchg() without the socket lock.
Annotate the remaining MPTCP peeks on the msk send/recv/splice paths
and on the subflow error-report path with READ_ONCE().

This does not consume sk_err; the check-then-sock_error() TOCTOU on
the no-data paths is a separate issue.

Signed-off-by: Quanye Yang <quanyeyang@proton.me>
---
 net/mptcp/protocol.c | 8 ++++----
 net/mptcp/subflow.c  | 4 ++--
 2 files changed, 6 insertions(+), 6 deletions(-)

diff --git a/net/mptcp/protocol.c b/net/mptcp/protocol.c
index e1f08f71cdb1..91637d1ed070 100644
--- a/net/mptcp/protocol.c
+++ b/net/mptcp/protocol.c
@@ -969,7 +969,7 @@ static bool move_skbs_to_msk(struct mptcp_sock *msk, struct sock *ssk)
 
 	moved = __mptcp_move_skbs_from_subflow(msk, ssk, true);
 	__mptcp_ofo_queue(msk);
-	if (unlikely(ssk->sk_err))
+	if (unlikely(READ_ONCE(ssk->sk_err)))
 		__mptcp_subflow_error_report(sk, ssk);
 
 	/* If the moves have caught up with the DATA_FIN sequence number
@@ -2028,7 +2028,7 @@ static int mptcp_sendmsg(struct sock *sk, struct msghdr *msg, size_t len)
 	}
 
 	ret = -EPIPE;
-	if (unlikely(sk->sk_err || (sk->sk_shutdown & SEND_SHUTDOWN)))
+	if (unlikely(READ_ONCE(sk->sk_err) || (sk->sk_shutdown & SEND_SHUTDOWN)))
 		goto do_error;
 
 	pfrag = sk_page_frag(sk);
@@ -2429,7 +2429,7 @@ static int mptcp_recvmsg(struct sock *sk, struct msghdr *msg, size_t len,
 			    !timeo)
 				break;
 		} else {
-			if (sk->sk_err) {
+			if (READ_ONCE(sk->sk_err)) {
 				copied = sock_error(sk);
 				break;
 			}
@@ -4655,7 +4655,7 @@ static ssize_t mptcp_splice_read(struct socket *sock, loff_t *ppos,
 				break;
 			if (sock_flag(sk, SOCK_DONE))
 				break;
-			if (sk->sk_err) {
+			if (READ_ONCE(sk->sk_err)) {
 				ret = sock_error(sk);
 				break;
 			}
diff --git a/net/mptcp/subflow.c b/net/mptcp/subflow.c
index af81ad5e699d..ec9668fe8d5b 100644
--- a/net/mptcp/subflow.c
+++ b/net/mptcp/subflow.c
@@ -1541,7 +1541,7 @@ static void subflow_data_ready(struct sock *sk)
 		if (mptcp_data_avail(msk) < parent->sk_rcvlowat &&
 		    (tcp_sk(sk)->rcv_nxt - tcp_sk(sk)->rcv_wup) > inet_csk(sk)->icsk_ack.rcv_mss)
 			inet_csk(sk)->icsk_ack.pending |= ICSK_ACK_NOW;
-	} else if (unlikely(sk->sk_err)) {
+	} else if (unlikely(READ_ONCE(sk->sk_err))) {
 		subflow_error_report(sk);
 	}
 }
@@ -1889,7 +1889,7 @@ static void subflow_state_change(struct sock *sk)
 	 */
 	if (mptcp_subflow_data_available(sk))
 		mptcp_data_ready(parent, sk);
-	else if (unlikely(sk->sk_err))
+	else if (unlikely(READ_ONCE(sk->sk_err)))
 		subflow_error_report(sk);
 
 	subflow_sched_work_if_closed(mptcp_sk(parent), sk);

-- 
2.55.0

