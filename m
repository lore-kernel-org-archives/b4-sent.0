From: Quanye Yang <quanyeyang@proton.me>
Date: Mon, 07 Sep 2026 18:15:15 +0800
Subject: [PATCH mptcp-net v3 3/3] tcp: fix data-race in do_recvmmsg /
 mptcp_recvmsg
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260907-mptcp-snd-una-race-v3-3-65ba0d5f0221@proton.me>
References: <20260907-mptcp-snd-una-race-v3-0-65ba0d5f0221@proton.me>
In-Reply-To: <20260907-mptcp-snd-una-race-v3-0-65ba0d5f0221@proton.me>
To: MPTCP Linux <mptcp@lists.linux.dev>
Cc: geliang@kernel.org, matttbe@kernel.org, pabeni@redhat.com
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788776116; l=1223;
 i=quanyeyang@proton.me; s=20260801; h=from:subject:message-id;
 bh=EKQf0Zl10HLtBgRCYjNvbKPZJ84GNyeJhkTcDAK+6rU=;
 b=mJ4UAOOfb2uA4PanElByGKLauCM0iVqFPUpIm9ALSITQ1HJwjfS4+Omxa5AXkxyFkjanKilkj
 3PgA/YP/ms5CnZ01oM2E6B288JSPn5vLgv8pYeek8gfaruSpgwB93gc
X-Developer-Key: i=quanyeyang@proton.me; a=ed25519;
 pk=9L9FrcvzMgxPaBRU6XV0EnqTgjDqVO596rQKSZ9qZoY=
X-Endpoint-Received: by B4 Relay for quanyeyang@proton.me/20260801 with auth_id=963
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

KCSAN reported a data race between do_recvmmsg() and
mptcp_recvmsg() on sk->sk_err.

do_recvmmsg() calls sock_error() without holding the socket lock.
sock_error() atomically clears sk_err using xchg(), which can race
with the plain read in tcp_recv_should_stop(), even when its caller
holds the socket lock.

Use READ_ONCE() for the lockless read. No additional ordering is
required because the value is only used to decide whether receiving
should stop.

Fixes: 7a6a6cbc3e59 ("mptcp: recvmsg() can drain data from multiple subflows")
Signed-off-by: Quanye Yang <quanyeyang@proton.me>
---
 include/net/tcp.h | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/include/net/tcp.h b/include/net/tcp.h
index 436495ff2271..c61d8678eafd 100644
--- a/include/net/tcp.h
+++ b/include/net/tcp.h
@@ -3082,7 +3082,8 @@ enum skb_drop_reason tcp_inbound_hash(struct sock *sk,
 
 static inline int tcp_recv_should_stop(struct sock *sk)
 {
-	return sk->sk_err ||
+	/* sk_err can be cleared locklessly by sock_error(). */
+	return READ_ONCE(sk->sk_err) ||
 	       sk->sk_state == TCP_CLOSE ||
 	       (sk->sk_shutdown & RCV_SHUTDOWN) ||
 	       signal_pending(current);

-- 
2.55.0

