From: Simon Baatz <gmbnomis@gmail.com>
Date: Wed, 10 Jun 2026 00:09:24 +0200
Subject: [PATCH net-next] tcp: tighten the FIN exception in tcp_sequence()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260610-tcp_fin_more_restrictive-v1-1-eefc30d7ddd8@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x3MQQrCMBBG4auUWRuIhcboVURCHf/qLJyWyVAKp
 Xc3uPwW7+1UYYJKt24nwypVZm04nzriz6hvBHk1Ux/7FFO8BuelTKLlOxuKoboJu6wIw5NzzMg
 XTiO1fDFMsv3Xd1J4UGxOj+P4AYwg7It0AAAA
X-Change-ID: 20260609-tcp_fin_more_restrictive-5bc808e87c6a
To: Eric Dumazet <edumazet@google.com>, 
 Neal Cardwell <ncardwell@google.com>, Kuniyuki Iwashima <kuniyu@google.com>, 
 "David S. Miller" <davem@davemloft.net>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Simon Horman <horms@kernel.org>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Simon Baatz <gmbnomis@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781042993; l=2714;
 i=gmbnomis@gmail.com; s=20260220; h=from:subject:message-id;
 bh=HFJpmhvgg3ixgB987Rc4iByrE21jxx8pxIpyevnMWns=;
 b=oPIv0XjKVR3yitOO56CyKcAknTDLI7cGqko7IbwwKp6boB19KAYKEyY8XjItrgE8aABtGgKCQ
 uY0fEuvtzRFBwUZexKYbxD5T480b4rYFou8IYtfVDKh8r+IH0b2Qj74
X-Developer-Key: i=gmbnomis@gmail.com; a=ed25519;
 pk=T/JIz/6F5bf1uQJr69lmyi7czVG+F9TVZ/8x5z9Wtqw=
X-Endpoint-Received: by B4 Relay for gmbnomis@gmail.com/20260220 with auth_id=641
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Commit 1e3bb184e941 ("tcp: re-enable acceptance of FIN packets when
RWIN is 0") added a special case in tcp_sequence() to mirror the FIN
exception in tcp_data_queue(), which accepts bare in-order FINs even
when the advertised window is zero. That behavior is not
RFC-compliant, but was introduced in commit 2bd99aef1b19 ("tcp: accept
bare FIN packets under memory pressure") to break tight FIN/ACK loops
caused by broken clients.

However, the condition added by commit 1e3bb184e941 ("tcp: re-enable
acceptance of FIN packets when RWIN is 0") is broader than required
and allows other non-compliant packets as well.

Tighten the tcp_sequence() FIN exception to only allow packets where
the packet is a bare in-order FIN and only the FIN flag extends beyond
tcp_max_receive_window(). In particular, this exception is only
reachable if tcp_max_receive_window() is zero. Otherwise the packet is
already accepted by the normal sequence check.

The existing packetdrill test tcp_rcv_zero_wnd_fin.pkt exercises this
behavior already and does not need to be changed.

Signed-off-by: Simon Baatz <gmbnomis@gmail.com>
---
 net/ipv4/tcp_input.c | 13 ++++++++-----
 1 file changed, 8 insertions(+), 5 deletions(-)

diff --git a/net/ipv4/tcp_input.c b/net/ipv4/tcp_input.c
index ab7a4e5435a8..1eddae246963 100644
--- a/net/ipv4/tcp_input.c
+++ b/net/ipv4/tcp_input.c
@@ -4812,18 +4812,21 @@ static enum skb_drop_reason tcp_sequence(const struct sock *sk,
 					 const struct tcphdr *th)
 {
 	const struct tcp_sock *tp = tcp_sk(sk);
+	u32 seq_limit;
 
 	if (before(end_seq, tp->rcv_wup))
 		return SKB_DROP_REASON_TCP_OLD_SEQUENCE;
 
-	if (unlikely(after(end_seq, tp->rcv_nxt + tcp_max_receive_window(tp)))) {
-		/* Some stacks are known to handle FIN incorrectly; allow the
-		 * FIN to extend beyond the window and check it in detail later.
+	seq_limit = tp->rcv_nxt + tcp_max_receive_window(tp);
+	if (unlikely(after(end_seq, seq_limit))) {
+		/* Some stacks are known to send bare FIN packets
+		 * in a loop even if we send RWIN 0 in our ACK. Allow
+		 * them here, they are handled later in tcp_data_queue().
 		 */
-		if (!after(end_seq - th->fin, tp->rcv_nxt + tcp_receive_window(tp)))
+		if (seq == tp->rcv_nxt && end_seq - th->fin == tp->rcv_nxt)
 			return SKB_NOT_DROPPED_YET;
 
-		if (after(seq, tp->rcv_nxt + tcp_max_receive_window(tp)))
+		if (after(seq, seq_limit))
 			return SKB_DROP_REASON_TCP_INVALID_SEQUENCE;
 
 		/* Only accept this packet if receive queue is empty. */

---
base-commit: 3abbe30231441f1fbb3305e9854c56a34650af53
change-id: 20260609-tcp_fin_more_restrictive-5bc808e87c6a

Best regards,
-- 
Simon Baatz <gmbnomis@gmail.com>

