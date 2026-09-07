From: Quanye Yang <quanyeyang@proton.me>
Date: Mon, 07 Sep 2026 18:15:14 +0800
Subject: [PATCH mptcp-net v3 2/3] mptcp: fix data-race in
 mptcp_subflow_get_send / tcp_ack
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260907-mptcp-snd-una-race-v3-2-65ba0d5f0221@proton.me>
References: <20260907-mptcp-snd-una-race-v3-0-65ba0d5f0221@proton.me>
In-Reply-To: <20260907-mptcp-snd-una-race-v3-0-65ba0d5f0221@proton.me>
To: MPTCP Linux <mptcp@lists.linux.dev>
Cc: geliang@kernel.org, matttbe@kernel.org, pabeni@redhat.com
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788776116; l=1235;
 i=quanyeyang@proton.me; s=20260801; h=from:subject:message-id;
 bh=06AW/3QX+jM9WoTzq8ffD3/zCT6sKnkg6/dgcHOi06Y=;
 b=c73TL15YQPFqkQA02+etGUUBQTHZZR42Wedvp3z7VeJXVC7uV8vY5lLZFFiuy0Illl/tm7mxU
 A4koShh/F+HCHoLg0Mh1y6dnSG62KndtTxQ53psg0BGuhbHdgB3mT9O
X-Developer-Key: i=quanyeyang@proton.me; a=ed25519;
 pk=9L9FrcvzMgxPaBRU6XV0EnqTgjDqVO596rQKSZ9qZoY=
X-Endpoint-Received: by B4 Relay for quanyeyang@proton.me/20260801 with auth_id=963
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

KCSAN reported a data race between the lockless read of
icsk->icsk_pending in mptcp_timeout_from_subflow() and the
smp_store_release() performed from tcp_ack() when clearing the
subflow retransmission timer.

The MPTCP socket lock held by the reader does not protect the TCP
subflow state. Use smp_load_acquire() to match the store-release
operations used by TCP and the other lockless readers of this field.

Fixes: 33d41c9cd74c ("mptcp: more accurate timeout")
Signed-off-by: Quanye Yang <quanyeyang@proton.me>
---
 net/mptcp/protocol.c | 4 +++-
 1 file changed, 3 insertions(+), 1 deletion(-)

diff --git a/net/mptcp/protocol.c b/net/mptcp/protocol.c
index 0b24e0afedfb..f4f63df9d787 100644
--- a/net/mptcp/protocol.c
+++ b/net/mptcp/protocol.c
@@ -606,7 +606,9 @@ static long mptcp_timeout_from_subflow(const struct mptcp_subflow_context *subfl
 {
 	const struct sock *ssk = mptcp_subflow_tcp_sock(subflow);
 
-	return inet_csk(ssk)->icsk_pending && !subflow->stale_count ?
+	/* Pair this lockless read with TCP's store-release updates. */
+	return smp_load_acquire(&inet_csk(ssk)->icsk_pending) &&
+	       !subflow->stale_count ?
 	       tcp_timeout_expires(ssk) - jiffies : 0;
 }
 

-- 
2.55.0

