From: Christoph Paasch <cpaasch@openai.com>
Date: Thu, 07 Aug 2025 11:00:43 -0700
Subject: [PATCH mptcp-net] mptcp: drop skb if MPTCP skb extension
 allocation fails
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250807-mptcp_fixes-v1-1-adfd79a88b5e@openai.com>
X-B4-Tracking: v=1; b=H4sIAMrplGgC/x2LQQqAIBAAvyJ7TjBLkr4SEaFr7SETjQjEvyceh
 5nJkDASJphZhogvJbp9hb5jYM7dH8jJVgYppBJaKH6Fx4TN0YeJWzuhGJXUbpBQjxCxiTos0EL
 u8YG1lB/ElEvRaAAAAA==
X-Change-ID: 20250805-mptcp_fixes-dd7e04528f32
To: MPTCP Upstream <mptcp@lists.linux.dev>, 
 Matthieu Baerts <matttbe@kernel.org>, Mat Martineau <martineau@kernel.org>, 
 Geliang Tang <geliang@kernel.org>
Cc: Christoph Paasch <cpaasch@openai.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1754589655; l=2141;
 i=cpaasch@openai.com; s=20250712; h=from:subject:message-id;
 bh=cDu7fm+K+qrA4QGkMHR4UGKNLCJ4l1vGPJHGz1BXj7Q=;
 b=3IVigu2/vvnoS3I1uCE6On7M7tERMd7/bqlrx5kIQ0TNLhuAGZSONyadaxBt+kZIF8qwD3vtT
 B18jy5Mr60cCNomt+Mr3i12HPPZ49mPxkZCdba9KpeJ9BK72bfDqaAc
X-Developer-Key: i=cpaasch@openai.com; a=ed25519;
 pk=1HRHZlVUZPziMZvsAQFvP7n5+uEosTDAjXmNXykdxdg=
X-Endpoint-Received: by B4 Relay for cpaasch@openai.com/20250712 with auth_id=459
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When skb_ext_add(skb, SKB_EXT_MPTCP) fails in mptcp_incoming_options(),
we used to return true, letting the segment proceed through the TCP
receive path without a DSS mapping. Such segments can leave inconsistent
mapping state and trigger a mid-stream fallback to TCP, which in testing
collapsed (by artificially forcing failures in skb_ext_add) throughput
to zero.

Return false instead so the TCP input path drops the skb (see
tcp_data_queue() and step-7 processing). This is the safer choice
under memory pressure: it preserves MPTCP correctness and provides
backpressure to the sender.

Control packets remain unaffected: ACK updates and DATA_FIN handling
happen before attempting the extension allocation, and tcp_reset()
continues to ignore the return value.

With this change, MPTCP continues to work at high throughput if we
artificially inject failures into skb_ext_add.

Fixes: 6787b7e350d3 ("mptcp: avoid processing packet if a subflow reset")
Signed-off-by: Christoph Paasch <cpaasch@openai.com>
---
 net/mptcp/options.c | 6 ++++--
 1 file changed, 4 insertions(+), 2 deletions(-)

diff --git a/net/mptcp/options.c b/net/mptcp/options.c
index 3c08beffbfea13597f14df17b1636b154e471398..d47b8a9bc2df2f14645b1b3d3e10fea1b38567b1 100644
--- a/net/mptcp/options.c
+++ b/net/mptcp/options.c
@@ -1119,7 +1119,9 @@ static bool add_addr_hmac_valid(struct mptcp_sock *msk,
 	return hmac == mp_opt->ahmac;
 }
 
-/* Return false if a subflow has been reset, else return true */
+/* Return false in case of error (or subflow has been reset),
+ * else return true.
+ */
 bool mptcp_incoming_options(struct sock *sk, struct sk_buff *skb)
 {
 	struct mptcp_subflow_context *subflow = mptcp_subflow_ctx(sk);
@@ -1223,7 +1225,7 @@ bool mptcp_incoming_options(struct sock *sk, struct sk_buff *skb)
 
 	mpext = skb_ext_add(skb, SKB_EXT_MPTCP);
 	if (!mpext)
-		return true;
+		return false;
 
 	memset(mpext, 0, sizeof(*mpext));
 

---
base-commit: dc818e7d153ed5ff81b9fcec7baa3b4b78725f89
change-id: 20250805-mptcp_fixes-dd7e04528f32

Best regards,
-- 
Christoph Paasch <cpaasch@openai.com>

