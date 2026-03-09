From: Simon Baatz <gmbnomis@gmail.com>
Date: Mon, 09 Mar 2026 09:02:26 +0100
Subject: [PATCH net-next v3 1/6] tcp: implement RFC 7323 window retraction
 receiver requirements
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260309-tcp_rfc7323_retract_wnd_rfc-v3-1-4c7f96b1ec69@gmail.com>
References: <20260309-tcp_rfc7323_retract_wnd_rfc-v3-0-4c7f96b1ec69@gmail.com>
In-Reply-To: <20260309-tcp_rfc7323_retract_wnd_rfc-v3-0-4c7f96b1ec69@gmail.com>
To: Eric Dumazet <edumazet@google.com>, 
 Neal Cardwell <ncardwell@google.com>, Kuniyuki Iwashima <kuniyu@google.com>, 
 "David S. Miller" <davem@davemloft.net>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Simon Horman <horms@kernel.org>, 
 Jonathan Corbet <corbet@lwn.net>, Shuah Khan <skhan@linuxfoundation.org>, 
 David Ahern <dsahern@kernel.org>, Jon Maloy <jmaloy@redhat.com>, 
 Jason Xing <kerneljasonxing@gmail.com>, mfreemon@cloudflare.com, 
 Shuah Khan <shuah@kernel.org>, Stefano Brivio <sbrivio@redhat.com>, 
 Matthieu Baerts <matttbe@kernel.org>, Mat Martineau <martineau@kernel.org>, 
 Geliang Tang <geliang@kernel.org>
Cc: netdev@vger.kernel.org, linux-doc@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-kselftest@vger.kernel.org, 
 mptcp@lists.linux.dev, Simon Baatz <gmbnomis@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1773043425; l=11695;
 i=gmbnomis@gmail.com; s=20260220; h=from:subject:message-id;
 bh=9E8zCE5nmQbTZ9o2NygPjxIomKughsAZvjNUYtJajfw=;
 b=V8tdU1ByKFW0d7c32JNgV3KR3ohZisAHDtPmNZ0FbMNAZI0ZP5ipHEi71GROA7dyV2dvT5cMW
 1iu9BHemoNjDvZ0LWEx34wL4+1Hwzsl0TVCKUWsJfKmf8wZLEcmXrEs
X-Developer-Key: i=gmbnomis@gmail.com; a=ed25519;
 pk=T/JIz/6F5bf1uQJr69lmyi7czVG+F9TVZ/8x5z9Wtqw=
X-Endpoint-Received: by B4 Relay for gmbnomis@gmail.com/20260220 with auth_id=641
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

By default, the Linux TCP implementation does not shrink the
advertised window (RFC 7323 calls this "window retraction") with the
following exceptions:

- When an incoming segment cannot be added due to the receive buffer
  running out of memory. Since commit 8c670bdfa58e ("tcp: correct
  handling of extreme memory squeeze") a zero window will be
  advertised in this case. It turns out that reaching the required
  memory pressure is easy when window scaling is in use. In the
  simplest case, sending a sufficient number of segments smaller than
  the scale factor to a receiver that does not read data is enough.

- Commit b650d953cd39 ("tcp: enforce receive buffer memory limits by
  allowing the tcp window to shrink") addressed the "eating memory"
  problem by introducing a sysctl knob that allows shrinking the
  window before running out of memory.

However, RFC 7323 does not only state that shrinking the window is
necessary in some cases, it also formulates requirements for TCP
implementations when doing so (Section 2.4).

This commit addresses the receiver-side requirements: After retracting
the window, the peer may have a snd_nxt that lies within a previously
advertised window but is now beyond the retracted window. This means
that all incoming segments (including pure ACKs) will be rejected
until the application happens to read enough data to let the peer's
snd_nxt be in window again (which may be never).

To comply with RFC 7323, the receiver MUST honor any segment that
would have been in window for any ACK sent by the receiver and, when
window scaling is in effect, SHOULD track the maximum window sequence
number it has advertised. This patch tracks that maximum window
sequence number rcv_mwnd_seq throughout the connection and uses it in
tcp_sequence() when deciding whether a segment is acceptable.

rcv_mwnd_seq is updated together with rcv_wup and rcv_wnd in
tcp_select_window(). If we count tcp_sequence() as fast path, it is
read in the fast path. Therefore, rcv_mwnd_seq is put into rcv_wnd's
cacheline group.

The logic for handling received data in tcp_data_queue() is already
sufficient and does not need to be updated.

Signed-off-by: Simon Baatz <gmbnomis@gmail.com>
---
 .../networking/net_cachelines/tcp_sock.rst         |  1 +
 include/linux/tcp.h                                |  3 +++
 include/net/tcp.h                                  | 22 ++++++++++++++++++++++
 net/ipv4/tcp.c                                     |  2 ++
 net/ipv4/tcp_fastopen.c                            |  1 +
 net/ipv4/tcp_input.c                               | 10 +++++-----
 net/ipv4/tcp_minisocks.c                           |  1 +
 net/ipv4/tcp_output.c                              |  3 +++
 .../net/packetdrill/tcp_rcv_big_endseq.pkt         |  2 +-
 9 files changed, 39 insertions(+), 6 deletions(-)

diff --git a/Documentation/networking/net_cachelines/tcp_sock.rst b/Documentation/networking/net_cachelines/tcp_sock.rst
index 563daea10d6c5c074f004cb1b8574f5392157abb..fecf61166a54ee2f64bcef5312c81dcc4aa9a124 100644
--- a/Documentation/networking/net_cachelines/tcp_sock.rst
+++ b/Documentation/networking/net_cachelines/tcp_sock.rst
@@ -121,6 +121,7 @@ u64                           delivered_mstamp        read_write
 u32                           rate_delivered                              read_mostly         tcp_rate_gen
 u32                           rate_interval_us                            read_mostly         rate_delivered,rate_app_limited
 u32                           rcv_wnd                 read_write          read_mostly         tcp_select_window,tcp_receive_window,tcp_fast_path_check
+u32                           rcv_mwnd_seq            read_write                              tcp_select_window
 u32                           write_seq               read_write                              tcp_rate_check_app_limited,tcp_write_queue_empty,tcp_skb_entail,forced_push,tcp_mark_push
 u32                           notsent_lowat           read_mostly                             tcp_stream_memory_free
 u32                           pushed_seq              read_write                              tcp_mark_push,forced_push
diff --git a/include/linux/tcp.h b/include/linux/tcp.h
index f72eef31fa23cc584f2f0cefacdc35cae43aa52d..73aa2e0ccd1d7a6314a00c27950b019b62a3851c 100644
--- a/include/linux/tcp.h
+++ b/include/linux/tcp.h
@@ -316,6 +316,9 @@ struct tcp_sock {
 					*/
 	u32	app_limited;	/* limited until "delivered" reaches this val */
 	u32	rcv_wnd;	/* Current receiver window		*/
+	u32	rcv_mwnd_seq;	/* Maximum window sequence number (RFC 7323,
+				 * section 2.4, receiver requirements)
+				 */
 	u32	rcv_tstamp;	/* timestamp of last received ACK (for keepalives) */
 /*
  *      Options received (usually on last packet, some only on SYN packets).
diff --git a/include/net/tcp.h b/include/net/tcp.h
index a6464142380696e4948a836145ac7aca4ca3ec15..5fa8455ee9bc52d1434feaf82dda80be067a36e6 100644
--- a/include/net/tcp.h
+++ b/include/net/tcp.h
@@ -921,6 +921,28 @@ static inline u32 tcp_receive_window(const struct tcp_sock *tp)
 	return (u32) win;
 }
 
+/* Compute the maximum receive window we ever advertised.
+ * Rcv_nxt can be after the window if our peer push more data
+ * than the offered window.
+ */
+static inline u32 tcp_max_receive_window(const struct tcp_sock *tp)
+{
+	s32 win = tp->rcv_mwnd_seq - tp->rcv_nxt;
+
+	if (win < 0)
+		win = 0;
+	return (u32) win;
+}
+
+/* Check if we need to update the maximum receive window sequence number */
+static inline void tcp_update_max_rcv_wnd_seq(struct tcp_sock *tp)
+{
+	u32 wre = tp->rcv_wup + tp->rcv_wnd;
+
+	if (after(wre, tp->rcv_mwnd_seq))
+		tp->rcv_mwnd_seq = wre;
+}
+
 /* Choose a new window, without checks for shrinking, and without
  * scaling applied to the result.  The caller does these things
  * if necessary.  This is a "raw" window selection.
diff --git a/net/ipv4/tcp.c b/net/ipv4/tcp.c
index ed6f6712f06076dc33af61947782bde436dde15e..516087c622ade78883ca41e4f883740e305035a0 100644
--- a/net/ipv4/tcp.c
+++ b/net/ipv4/tcp.c
@@ -3561,6 +3561,7 @@ static int tcp_repair_set_window(struct tcp_sock *tp, sockptr_t optbuf, int len)
 
 	tp->rcv_wnd	= opt.rcv_wnd;
 	tp->rcv_wup	= opt.rcv_wup;
+	tp->rcv_mwnd_seq = opt.rcv_wup + opt.rcv_wnd;
 
 	return 0;
 }
@@ -5275,6 +5276,7 @@ static void __init tcp_struct_check(void)
 	CACHELINE_ASSERT_GROUP_MEMBER(struct tcp_sock, tcp_sock_write_txrx, received_ecn_bytes);
 	CACHELINE_ASSERT_GROUP_MEMBER(struct tcp_sock, tcp_sock_write_txrx, app_limited);
 	CACHELINE_ASSERT_GROUP_MEMBER(struct tcp_sock, tcp_sock_write_txrx, rcv_wnd);
+	CACHELINE_ASSERT_GROUP_MEMBER(struct tcp_sock, tcp_sock_write_txrx, rcv_mwnd_seq);
 	CACHELINE_ASSERT_GROUP_MEMBER(struct tcp_sock, tcp_sock_write_txrx, rcv_tstamp);
 	CACHELINE_ASSERT_GROUP_MEMBER(struct tcp_sock, tcp_sock_write_txrx, rx_opt);
 
diff --git a/net/ipv4/tcp_fastopen.c b/net/ipv4/tcp_fastopen.c
index 9fdc19accafd23c6ab74bd82f7a7d82de1d60b90..4e389d609f919c17435509c5007bc3b2a13eac6c 100644
--- a/net/ipv4/tcp_fastopen.c
+++ b/net/ipv4/tcp_fastopen.c
@@ -377,6 +377,7 @@ static struct sock *tcp_fastopen_create_child(struct sock *sk,
 
 	tcp_rsk(req)->rcv_nxt = tp->rcv_nxt;
 	tp->rcv_wup = tp->rcv_nxt;
+	tp->rcv_mwnd_seq = tp->rcv_wup + tp->rcv_wnd;
 	/* tcp_conn_request() is sending the SYNACK,
 	 * and queues the child into listener accept queue.
 	 */
diff --git a/net/ipv4/tcp_input.c b/net/ipv4/tcp_input.c
index 71ac69b7b75e4919f69631a4894421fa4e417c95..2e1b237608150c2e9c9baf73cf047ed0823ca555 100644
--- a/net/ipv4/tcp_input.c
+++ b/net/ipv4/tcp_input.c
@@ -4808,20 +4808,18 @@ static enum skb_drop_reason tcp_sequence(const struct sock *sk,
 					 const struct tcphdr *th)
 {
 	const struct tcp_sock *tp = tcp_sk(sk);
-	u32 seq_limit;
 
 	if (before(end_seq, tp->rcv_wup))
 		return SKB_DROP_REASON_TCP_OLD_SEQUENCE;
 
-	seq_limit = tp->rcv_nxt + tcp_receive_window(tp);
-	if (unlikely(after(end_seq, seq_limit))) {
+	if (unlikely(after(end_seq, tp->rcv_nxt + tcp_max_receive_window(tp)))) {
 		/* Some stacks are known to handle FIN incorrectly; allow the
 		 * FIN to extend beyond the window and check it in detail later.
 		 */
-		if (!after(end_seq - th->fin, seq_limit))
+		if (!after(end_seq - th->fin, tp->rcv_nxt + tcp_receive_window(tp)))
 			return SKB_NOT_DROPPED_YET;
 
-		if (after(seq, seq_limit))
+		if (after(seq, tp->rcv_nxt + tcp_max_receive_window(tp)))
 			return SKB_DROP_REASON_TCP_INVALID_SEQUENCE;
 
 		/* Only accept this packet if receive queue is empty. */
@@ -6903,6 +6901,7 @@ static int tcp_rcv_synsent_state_process(struct sock *sk, struct sk_buff *skb,
 		 */
 		WRITE_ONCE(tp->rcv_nxt, TCP_SKB_CB(skb)->seq + 1);
 		tp->rcv_wup = TCP_SKB_CB(skb)->seq + 1;
+		tp->rcv_mwnd_seq = tp->rcv_wup + tp->rcv_wnd;
 
 		/* RFC1323: The window in SYN & SYN/ACK segments is
 		 * never scaled.
@@ -7015,6 +7014,7 @@ static int tcp_rcv_synsent_state_process(struct sock *sk, struct sk_buff *skb,
 		WRITE_ONCE(tp->rcv_nxt, TCP_SKB_CB(skb)->seq + 1);
 		WRITE_ONCE(tp->copied_seq, tp->rcv_nxt);
 		tp->rcv_wup = TCP_SKB_CB(skb)->seq + 1;
+		tp->rcv_mwnd_seq = tp->rcv_wup + tp->rcv_wnd;
 
 		/* RFC1323: The window in SYN & SYN/ACK segments is
 		 * never scaled.
diff --git a/net/ipv4/tcp_minisocks.c b/net/ipv4/tcp_minisocks.c
index dafb63b923d0d08cb1a0e9a37d8ec025386a960a..d350d794a959720853ffd8937cfdc34c03e2ce30 100644
--- a/net/ipv4/tcp_minisocks.c
+++ b/net/ipv4/tcp_minisocks.c
@@ -604,6 +604,7 @@ struct sock *tcp_create_openreq_child(const struct sock *sk,
 	newtp->window_clamp = req->rsk_window_clamp;
 	newtp->rcv_ssthresh = req->rsk_rcv_wnd;
 	newtp->rcv_wnd = req->rsk_rcv_wnd;
+	newtp->rcv_mwnd_seq = newtp->rcv_wup + req->rsk_rcv_wnd;
 	newtp->rx_opt.wscale_ok = ireq->wscale_ok;
 	if (newtp->rx_opt.wscale_ok) {
 		newtp->rx_opt.snd_wscale = ireq->snd_wscale;
diff --git a/net/ipv4/tcp_output.c b/net/ipv4/tcp_output.c
index f0ebcc7e287173be6198fd100130e7ba1a1dbf03..c86910d147f2394bf414d7691d8f90ed41c1b0e3 100644
--- a/net/ipv4/tcp_output.c
+++ b/net/ipv4/tcp_output.c
@@ -293,6 +293,7 @@ static u16 tcp_select_window(struct sock *sk)
 		tp->pred_flags = 0;
 		tp->rcv_wnd = 0;
 		tp->rcv_wup = tp->rcv_nxt;
+		tcp_update_max_rcv_wnd_seq(tp);
 		return 0;
 	}
 
@@ -316,6 +317,7 @@ static u16 tcp_select_window(struct sock *sk)
 
 	tp->rcv_wnd = new_win;
 	tp->rcv_wup = tp->rcv_nxt;
+	tcp_update_max_rcv_wnd_seq(tp);
 
 	/* Make sure we do not exceed the maximum possible
 	 * scaled window.
@@ -4195,6 +4197,7 @@ static void tcp_connect_init(struct sock *sk)
 	else
 		tp->rcv_tstamp = tcp_jiffies32;
 	tp->rcv_wup = tp->rcv_nxt;
+	tp->rcv_mwnd_seq = tp->rcv_nxt + tp->rcv_wnd;
 	WRITE_ONCE(tp->copied_seq, tp->rcv_nxt);
 
 	inet_csk(sk)->icsk_rto = tcp_timeout_init(sk);
diff --git a/tools/testing/selftests/net/packetdrill/tcp_rcv_big_endseq.pkt b/tools/testing/selftests/net/packetdrill/tcp_rcv_big_endseq.pkt
index 6c0f32c40f19be2a750fc9d69bbf64250cd7b525..12882be10f2e0cf19e6bc7bd2479b27c11ce8ac0 100644
--- a/tools/testing/selftests/net/packetdrill/tcp_rcv_big_endseq.pkt
+++ b/tools/testing/selftests/net/packetdrill/tcp_rcv_big_endseq.pkt
@@ -36,7 +36,7 @@
 
   +0 read(4, ..., 100000) = 4000
 
-// If queue is empty, accept a packet even if its end_seq is above wup + rcv_wnd
+// If queue is empty, accept a packet even if its end_seq is above rcv_mwnd_seq
   +0 < P. 4001:54001(50000) ack 1 win 257
    * > .  1:1(0) ack 54001 win 0
 

-- 
2.53.0

