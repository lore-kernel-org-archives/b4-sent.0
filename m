From: Oliver Hartkopp <socketcan@hartkopp.net>
Date: Fri, 10 Jul 2026 18:47:44 +0200
Subject: [PATCH v5 3/4] can: isotp: fix race between RX timer and
 consecutive frame reception
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260710-isotp-fixes-v5-3-15174d82d6f1@hartkopp.net>
References: <20260710-isotp-fixes-v5-0-15174d82d6f1@hartkopp.net>
In-Reply-To: <20260710-isotp-fixes-v5-0-15174d82d6f1@hartkopp.net>
To: linux-can@vger.kernel.org
Cc: Oliver Hartkopp <socketcan@hartkopp.net>, 
 Marc Kleine-Budde <mkl@pengutronix.de>, sashiko-bot@kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783702070; l=1756;
 i=socketcan@hartkopp.net; s=20260128; h=from:subject:message-id;
 bh=ZtDFm0eMta+8u2hxg7eL80U5RKwqAeV4A09IBs3aU1Y=;
 b=NBZ8tfJPnfkpR3s5HTGnJgJZm+54yAWYEjswCX9smXx1SdLZ0A/ja7TykZjLlcc24IDf3UTXr
 WiOqmIxdWyRA33RCTYWmAlS/EHcOMBBqU4ofdaku3WqvXl17jaK56bF
X-Developer-Key: i=socketcan@hartkopp.net; a=ed25519;
 pk=/gU/7/wBqak3kTsTeFbCCqUi9dnh+1i6ITEkfPj/BvU=
X-Endpoint-Received: by B4 Relay for socketcan@hartkopp.net/20260128 with auth_id=620
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When receiving a Consecutive Frame (CF), hrtimer_cancel() is called to stop
the RX timer. However, if the timer handler (isotp_rx_timer_handler) has
already fired and is running concurrently on another CPU, hrtimer_cancel()
will wait for it to finish.

By the time it returns, the timer handler might have already reported an
ETIMEDOUT error and reset the RX state machine. If we blindly continue
processing the CF, we corrupt the newly reset or idle state.

Fix this by verifying that the state is still ISOTP_WAIT_DATA after
canceling the hrtimer. If it changed, the reception has already timed out,
so we drop the frame.

Fixes: e057dd3fc20f ("can: add ISO 15765-2:2016 transport protocol")
Reported-by: sashiko-bot@kernel.org
Link: https://lore.kernel.org/linux-can/20260710142146.BDAE61F000E9@smtp.kernel.org/
Signed-off-by: Oliver Hartkopp <socketcan@hartkopp.net>
---
 net/can/isotp.c | 8 ++++++++
 1 file changed, 8 insertions(+)

diff --git a/net/can/isotp.c b/net/can/isotp.c
index e7597ca3e140..c0edbd35516c 100644
--- a/net/can/isotp.c
+++ b/net/can/isotp.c
@@ -575,10 +575,18 @@ static int isotp_rcv_cf(struct sock *sk, struct canfd_frame *cf, int ae,
 		so->lastrxcf_tstamp = skb->tstamp;
 	}
 
 	hrtimer_cancel(&so->rxtimer);
 
+	/* isotp_rx_timer_handler() may have raced us for so->rx.state
+	 * while hrtimer_cancel() above waited for it to finish, already
+	 * reporting ETIMEDOUT and resetting the reception; don't process
+	 * this CF into a reassembly that has already been given up on.
+	 */
+	if (so->rx.state != ISOTP_WAIT_DATA)
+		return 1;
+
 	/* CFs are never longer than the FF */
 	if (cf->len > so->rx.ll_dl)
 		return 1;
 
 	/* CFs have usually the LL_DL length */

-- 
2.53.0

