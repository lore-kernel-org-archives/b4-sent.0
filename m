From: Simon Baatz <gmbnomis@gmail.com>
Date: Wed, 08 Apr 2026 23:50:02 +0200
Subject: [PATCH net-next 1/7] tcp: keep rcv_wnd/rcv_ssthresh clamped by
 window_clamp if no scaling in use
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260408-tcp_rcv_exact_clamp_and_wnd-v1-1-76a6f212e153@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1775685040; l=3731;
 i=gmbnomis@gmail.com; s=20260220; h=from:subject:message-id;
 bh=D5Yj7InMLE8s8H7wijn4PBjZo6pD1UsEIMIUKtUVqsI=;
 b=T0np/fm0cCfmsmopm+yAL64WwCWbKQ5xalMNOXDtqcWDarCXh4XgNcPAWLwjOAD74EK84mCTt
 4BzDrMH7MxVBdK2sxWjq/soVkXrNEeyj2l6EenIRU9XJHC6IzbNNpi5
X-Developer-Key: i=gmbnomis@gmail.com; a=ed25519;
 pk=T/JIz/6F5bf1uQJr69lmyi7czVG+F9TVZ/8x5z9Wtqw=
X-Endpoint-Received: by B4 Relay for gmbnomis@gmail.com/20260220 with auth_id=641
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When window scaling is not used, we already clamp window_clamp to
65535, but rcv_wnd/rcv_ssthresh can still remain larger than this.

Fix this by capping rcv_wnd to 65535 in the non-scaling paths of both
active and passive opens. Since the advertised window in SYN and
SYN/ACK segments is unscaled, this cannot shrink the window
advertised to the peer.

Also ensure that tcp_select_initial_window() always keeps rcv_wnd less
than or equal to the (scale-limited) window_clamp.

Signed-off-by: Simon Baatz <gmbnomis@gmail.com>
---
 net/ipv4/tcp_input.c     | 7 ++++++-
 net/ipv4/tcp_minisocks.c | 8 ++++++--
 net/ipv4/tcp_output.c    | 5 +++--
 3 files changed, 15 insertions(+), 5 deletions(-)

diff --git a/net/ipv4/tcp_input.c b/net/ipv4/tcp_input.c
index 7171442c3ed7a..505884dcb7a2b 100644
--- a/net/ipv4/tcp_input.c
+++ b/net/ipv4/tcp_input.c
@@ -6898,7 +6898,6 @@ static int tcp_rcv_synsent_state_process(struct sock *sk, struct sk_buff *skb,
 		 */
 		WRITE_ONCE(tp->rcv_nxt, TCP_SKB_CB(skb)->seq + 1);
 		tp->rcv_wup = TCP_SKB_CB(skb)->seq + 1;
-		tp->rcv_mwnd_seq = tp->rcv_wup + tp->rcv_wnd;
 
 		/* RFC1323: The window in SYN & SYN/ACK segments is
 		 * never scaled.
@@ -6909,7 +6908,13 @@ static int tcp_rcv_synsent_state_process(struct sock *sk, struct sk_buff *skb,
 			tp->rx_opt.snd_wscale = tp->rx_opt.rcv_wscale = 0;
 			WRITE_ONCE(tp->window_clamp,
 				   min(tp->window_clamp, 65535U));
+			tp->rcv_ssthresh = min(tp->rcv_ssthresh, 65535U);
+			/* As the window in the SYN was not scaled,
+			 * we did not advertise more than 65535.
+			 */
+			tp->rcv_wnd = min(tp->rcv_wnd, 65535U);
 		}
+		tp->rcv_mwnd_seq = tp->rcv_wup + tp->rcv_wnd;
 
 		if (tp->rx_opt.saw_tstamp) {
 			tp->rx_opt.tstamp_ok	   = 1;
diff --git a/net/ipv4/tcp_minisocks.c b/net/ipv4/tcp_minisocks.c
index 199f0b579e89c..6496fe3b9e139 100644
--- a/net/ipv4/tcp_minisocks.c
+++ b/net/ipv4/tcp_minisocks.c
@@ -600,9 +600,7 @@ struct sock *tcp_create_openreq_child(const struct sock *sk,
 	newtp->rx_opt.tstamp_ok = ireq->tstamp_ok;
 	newtp->rx_opt.sack_ok = ireq->sack_ok;
 	newtp->window_clamp = req->rsk_window_clamp;
-	newtp->rcv_ssthresh = req->rsk_rcv_wnd;
 	newtp->rcv_wnd = req->rsk_rcv_wnd;
-	newtp->rcv_mwnd_seq = newtp->rcv_wup + req->rsk_rcv_wnd;
 	newtp->rx_opt.wscale_ok = ireq->wscale_ok;
 	if (newtp->rx_opt.wscale_ok) {
 		newtp->rx_opt.snd_wscale = ireq->snd_wscale;
@@ -610,7 +608,13 @@ struct sock *tcp_create_openreq_child(const struct sock *sk,
 	} else {
 		newtp->rx_opt.snd_wscale = newtp->rx_opt.rcv_wscale = 0;
 		newtp->window_clamp = min(newtp->window_clamp, 65535U);
+		/* As the window in the SYN/ACK was not scaled,
+		 * we did not advertise more than 65535.
+		 */
+		newtp->rcv_wnd = min(newtp->rcv_wnd, 65535U);
 	}
+	newtp->rcv_ssthresh = newtp->rcv_wnd;
+	newtp->rcv_mwnd_seq = newtp->rcv_wup + newtp->rcv_wnd;
 	newtp->snd_wnd = ntohs(tcp_hdr(skb)->window) << newtp->rx_opt.snd_wscale;
 	newtp->max_window = newtp->snd_wnd;
 
diff --git a/net/ipv4/tcp_output.c b/net/ipv4/tcp_output.c
index 8e99687526a64..bf7a12872acb3 100644
--- a/net/ipv4/tcp_output.c
+++ b/net/ipv4/tcp_output.c
@@ -269,8 +269,9 @@ void tcp_select_initial_window(const struct sock *sk, int __space, __u32 mss,
 				      0, TCP_MAX_WSCALE);
 	}
 	/* Set the clamp no higher than max representable value */
-	WRITE_ONCE(*__window_clamp,
-		   min_t(__u32, U16_MAX << (*rcv_wscale), window_clamp));
+	window_clamp = min_t(u32, U16_MAX << (*rcv_wscale), window_clamp);
+	WRITE_ONCE(*__window_clamp, window_clamp);
+	*rcv_wnd = min(*rcv_wnd, window_clamp);
 }
 
 /* Chose a new window to advertise, update state in tcp_sock for the

-- 
2.53.0

