From: Simon Baatz <gmbnomis@gmail.com>
Date: Wed, 08 Apr 2026 23:50:04 +0200
Subject: [PATCH net-next 3/7] tcp: Ensure window_clamp is limited to
 representable window
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260408-tcp_rcv_exact_clamp_and_wnd-v1-3-76a6f212e153@gmail.com>
References: <20260408-tcp_rcv_exact_clamp_and_wnd-v1-0-76a6f212e153@gmail.com>
In-Reply-To: <20260408-tcp_rcv_exact_clamp_and_wnd-v1-0-76a6f212e153@gmail.com>
To: Eric Dumazet <edumazet@google.com>, 
 Neal Cardwell <ncardwell@google.com>, Kuniyuki Iwashima <kuniyu@google.com>, 
 "David S. Miller" <davem@davemloft.net>, David Ahern <dsahern@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Simon Horman <horms@kernel.org>, Shuah Khan <shuah@kernel.org>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, Simon Baatz <gmbnomis@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1775685040; l=3305;
 i=gmbnomis@gmail.com; s=20260220; h=from:subject:message-id;
 bh=8RoSAA/YzN+3F5cJqgh/h47kr9+FGErmiW1Qt/v8bjw=;
 b=pkGclS7fY07/CNGhI7e+WKGswdZ1Rp+LPibce79xhOMdvLomiPLlqKMcMYZQrIsNdkUCCQA/r
 DnQh49vpQNxCkyMg1ZdjrqsFZh9In7cJ/db9yEOQWxmhTCJKYP8tEeN
X-Developer-Key: i=gmbnomis@gmail.com; a=ed25519;
 pk=T/JIz/6F5bf1uQJr69lmyi7czVG+F9TVZ/8x5z9Wtqw=
X-Endpoint-Received: by B4 Relay for gmbnomis@gmail.com/20260220 with auth_id=641
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On connection initiation, window_clamp is limited to the maximum value
representable for the connection's window scale factor.

However, window_clamp may be changed later when:
- it needs to be adjusted due to scaling_ratio changes
- the receive buffer grows due to autotuning
- the TCP_WINDOW_CLAMP socket option is set

In all cases, window_clamp must not end up higher than the maximum
representable advertised window.

Thus, if the TCP connection state indicates that we can rely on
rx_opt.rcv_wscale, clamp the new window_clamp to the maximum window
for that scaling factor (including the "no window scaling" case where
rcv_wscale is zero).

This has visible consequences for calculations based on rcv_wnd. For
example, the logic in __tcp_ack_snd_check() uses the advance of the
right edge of the receive window to determine when to send an
immediate ACK. If rcv_wnd does not properly reflect the "on the wire"
advertised window (i.e. it is much higher than the maximum value
representable), this calculation will be wrong and ACKs may be delayed
when they should be sent immediately.

One concrete example is when the TCP receive buffer is much larger
than 64KB, but no window scaling is used. If window_clamp (and thus
rcv_wnd) are not limited to 65535, the "internal" window based on
rcv_wnd can extend far beyond the 16‑bit window actually advertised on
the wire.

After receiving a data segment, the right edge of the "on the wire"
window can be moved (as there is plenty of space in rcv_wnd) and an
immediate ACK should be sent. But, it won't do so if the calculation
based on rcv_wnd does not happen to change "internal" window right edge.

Signed-off-by: Simon Baatz <gmbnomis@gmail.com>
---
 net/ipv4/tcp.c       | 4 ++++
 net/ipv4/tcp_input.c | 6 ++++--
 2 files changed, 8 insertions(+), 2 deletions(-)

diff --git a/net/ipv4/tcp.c b/net/ipv4/tcp.c
index e57eaffc007a0..bd03c99f793ae 100644
--- a/net/ipv4/tcp.c
+++ b/net/ipv4/tcp.c
@@ -3802,6 +3802,10 @@ int tcp_set_window_clamp(struct sock *sk, int val)
 	old_window_clamp = tp->window_clamp;
 	new_window_clamp = max_t(int, SOCK_MIN_RCVBUF / 2, val);
 
+	if ((1 << sk->sk_state) & (TCPF_ESTABLISHED | TCPF_CLOSE_WAIT |
+			TCPF_FIN_WAIT1 | TCPF_FIN_WAIT2))
+		new_window_clamp = min_t(u32, U16_MAX << tp->rx_opt.rcv_wscale, new_window_clamp);
+
 	if (new_window_clamp == old_window_clamp)
 		return 0;
 
diff --git a/net/ipv4/tcp_input.c b/net/ipv4/tcp_input.c
index 505884dcb7a2b..6e9123c98152f 100644
--- a/net/ipv4/tcp_input.c
+++ b/net/ipv4/tcp_input.c
@@ -914,6 +914,7 @@ void tcp_rcvbuf_grow(struct sock *sk, u32 newval)
 	struct tcp_sock *tp = tcp_sk(sk);
 	u32 rcvwin, rcvbuf, cap, oldval;
 	u32 rtt_threshold, rtt_us;
+	u32 window_clamp;
 	u64 grow;
 
 	oldval = tp->rcvq_space.space;
@@ -949,8 +950,9 @@ void tcp_rcvbuf_grow(struct sock *sk, u32 newval)
 	if (rcvbuf > sk->sk_rcvbuf) {
 		WRITE_ONCE(sk->sk_rcvbuf, rcvbuf);
 		/* Make the window clamp follow along.  */
-		WRITE_ONCE(tp->window_clamp,
-			   tcp_win_from_space(sk, rcvbuf));
+		window_clamp = tcp_win_from_space(sk, rcvbuf);
+		window_clamp = min_t(u32, U16_MAX << tp->rx_opt.rcv_wscale, window_clamp);
+		WRITE_ONCE(tp->window_clamp, window_clamp);
 	}
 }
 /*

-- 
2.53.0

