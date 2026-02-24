From: Simon Baatz <gmbnomis@gmail.com>
Date: Tue, 24 Feb 2026 09:20:12 +0100
Subject: [PATCH net v2 1/2] tcp: re-enable acceptance of FIN packets when
 RWIN is 0
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260224-fix_zero_wnd_fin-v2-1-a16677ea7cea@gmail.com>
References: <20260224-fix_zero_wnd_fin-v2-0-a16677ea7cea@gmail.com>
In-Reply-To: <20260224-fix_zero_wnd_fin-v2-0-a16677ea7cea@gmail.com>
To: Eric Dumazet <edumazet@google.com>, 
 Neal Cardwell <ncardwell@google.com>, Kuniyuki Iwashima <kuniyu@google.com>, 
 "David S. Miller" <davem@davemloft.net>, David Ahern <dsahern@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Simon Horman <horms@kernel.org>, Shuah Khan <shuah@kernel.org>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, Simon Baatz <gmbnomis@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1771921224; l=2768;
 i=gmbnomis@gmail.com; s=20260220; h=from:subject:message-id;
 bh=HHIXStnLVKh9nRSiL0fqF20SR1yAgQfpvvEWrJlCWHg=;
 b=nyp516r2MWrT4RExFJWSkDMLTTh4TPV2g5Mnfe8RVOVlfBOSy2QdPDlGednpb1bS8K67vybjd
 BjPhAsuIhG7BV/ZjzPUp56ThuXrbvOx8bgWZ/P2oxSKWd+lOoEC7Zwx
X-Developer-Key: i=gmbnomis@gmail.com; a=ed25519;
 pk=T/JIz/6F5bf1uQJr69lmyi7czVG+F9TVZ/8x5z9Wtqw=
X-Endpoint-Received: by B4 Relay for gmbnomis@gmail.com/20260220 with auth_id=641
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Commit 2bd99aef1b19 ("tcp: accept bare FIN packets under memory
pressure") allowed accepting FIN packets in tcp_data_queue() even when
the receive window was closed, to prevent ACK/FIN loops with broken
clients.

Such a FIN packet is in sequence, but because the FIN consumes a
sequence number, it extends beyond the window. Before commit
9ca48d616ed7 ("tcp: do not accept packets beyond window"),
tcp_sequence() only required the seq to be within the window. After
that change, the entire packet (including the FIN) must fit within the
window. As a result, such FIN packets are now dropped and the handling
path is no longer reached.

Be more lenient by not counting the sequence number consumed by the
FIN when calling tcp_sequence(), restoring the previous behavior for
cases where only the FIN extends beyond the window.

Fixes: 9ca48d616ed7 ("tcp: do not accept packets beyond window")
Signed-off-by: Simon Baatz <gmbnomis@gmail.com>
---
 net/ipv4/tcp_input.c | 18 ++++++++++++++----
 1 file changed, 14 insertions(+), 4 deletions(-)

diff --git a/net/ipv4/tcp_input.c b/net/ipv4/tcp_input.c
index e7b41abb82aad33d8cab4fcfa989cc4771149b41..1c6b8ca67918f0601b9b3e8ef884c5fef0a7ab65 100644
--- a/net/ipv4/tcp_input.c
+++ b/net/ipv4/tcp_input.c
@@ -4858,15 +4858,24 @@ static enum skb_drop_reason tcp_disordered_ack_check(const struct sock *sk,
  */
 
 static enum skb_drop_reason tcp_sequence(const struct sock *sk,
-					 u32 seq, u32 end_seq)
+					 u32 seq, u32 end_seq,
+					 const struct tcphdr *th)
 {
 	const struct tcp_sock *tp = tcp_sk(sk);
+	u32 seq_limit;
 
 	if (before(end_seq, tp->rcv_wup))
 		return SKB_DROP_REASON_TCP_OLD_SEQUENCE;
 
-	if (after(end_seq, tp->rcv_nxt + tcp_receive_window(tp))) {
-		if (after(seq, tp->rcv_nxt + tcp_receive_window(tp)))
+	seq_limit = tp->rcv_nxt + tcp_receive_window(tp);
+	if (unlikely(after(end_seq, seq_limit))) {
+		/* Some stacks are known to handle FIN incorrectly; allow the
+		 * FIN to extend beyond the window and check it in detail later.
+		 */
+		if (!after(end_seq - th->fin, seq_limit))
+			return SKB_NOT_DROPPED_YET;
+
+		if (after(seq, seq_limit))
 			return SKB_DROP_REASON_TCP_INVALID_SEQUENCE;
 
 		/* Only accept this packet if receive queue is empty. */
@@ -6379,7 +6388,8 @@ static bool tcp_validate_incoming(struct sock *sk, struct sk_buff *skb,
 
 step1:
 	/* Step 1: check sequence number */
-	reason = tcp_sequence(sk, TCP_SKB_CB(skb)->seq, TCP_SKB_CB(skb)->end_seq);
+	reason = tcp_sequence(sk, TCP_SKB_CB(skb)->seq,
+			      TCP_SKB_CB(skb)->end_seq, th);
 	if (reason) {
 		/* RFC793, page 37: "In all states except SYN-SENT, all reset
 		 * (RST) segments are validated by checking their SEQ-fields."

-- 
2.53.0

