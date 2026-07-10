From: Oliver Hartkopp <socketcan@hartkopp.net>
Date: Fri, 10 Jul 2026 22:42:54 +0200
Subject: [PATCH v6 3/5] can: isotp: fix race between RX/TX timers and frame
 reception
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260710-isotp-fixes-v6-3-a13c2539093d@hartkopp.net>
References: <20260710-isotp-fixes-v6-0-a13c2539093d@hartkopp.net>
In-Reply-To: <20260710-isotp-fixes-v6-0-a13c2539093d@hartkopp.net>
To: linux-can@vger.kernel.org
Cc: Oliver Hartkopp <socketcan@hartkopp.net>, 
 Marc Kleine-Budde <mkl@pengutronix.de>, sashiko-bot@kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783716177; l=4179;
 i=socketcan@hartkopp.net; s=20260128; h=from:subject:message-id;
 bh=pyGHkunbhmyG18O15nIawnmCk/gN0NevMAxv3PlAyNw=;
 b=88xtklvO9j/3NgwdgMbrUdjuWqS9RgEBN/SmG1+T9dctxP8wuxiUxsBlFlTxOhxhFX07B8M75
 vxQgCHpUViWAcwk6TLiUiRGqrVX85MtbnauUjUFZPO9w1L4VDLQFFJf
X-Developer-Key: i=socketcan@hartkopp.net; a=ed25519;
 pk=/gU/7/wBqak3kTsTeFbCCqUi9dnh+1i6ITEkfPj/BvU=
X-Endpoint-Received: by B4 Relay for socketcan@hartkopp.net/20260128 with auth_id=620
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When receiving a Consecutive Frame, Flow Control frame, or local echo
frame, hrtimer_cancel() is called to stop the corresponding watchdog
timer. If the timer handler was already running concurrently on another
CPU, hrtimer_cancel() waits for it to finish.

By the time it returns, the timer handler may have already reported a
timeout error and reset the state machine. Blindly continuing corrupts
the newly reset or idle state, and can let a concurrent sendmsg() claim
the same IDLE state at the same time.

Fix this by re-checking the state right after canceling the timer in all
three call sites (isotp_rcv_cf(), isotp_rcv_fc(), isotp_rcv_echo()). If
the state changed, the transfer has already timed out, so drop the frame
instead of resuming it.

For the same reason, isotp_sendmsg()'s err_event_drop path must cancel
so->txfrtimer/txtimer before setting so->tx.state to ISOTP_IDLE, not
after: otherwise a concurrent sendmsg() could claim ISOTP_SENDING and
start filling so->tx.buf while a still-armed timer from the aborted
transfer fires and sends a stale frame from it.

Fixes: e057dd3fc20f ("can: add ISO 15765-2:2016 transport protocol")
Reported-by: sashiko-bot@kernel.org
Link: https://lore.kernel.org/linux-can/20260710142146.BDAE61F000E9@smtp.kernel.org/
Signed-off-by: Oliver Hartkopp <socketcan@hartkopp.net>
---
 net/can/isotp.c | 28 ++++++++++++++++++++++++++--
 1 file changed, 26 insertions(+), 2 deletions(-)

diff --git a/net/can/isotp.c b/net/can/isotp.c
index 44c044eb83e1..5ef2a610fc17 100644
--- a/net/can/isotp.c
+++ b/net/can/isotp.c
@@ -376,10 +376,19 @@ static int isotp_rcv_fc(struct isotp_sock *so, struct canfd_frame *cf, int ae)
 	    so->tx.state != ISOTP_WAIT_FIRST_FC)
 		return 0;
 
 	hrtimer_cancel(&so->txtimer);
 
+	/* isotp_tx_timer_handler() may have raced us for so->tx.state while
+	 * hrtimer_cancel() above waited for it to finish, already reporting
+	 * the tx error and resetting the state; don't resume a tx job that
+	 * has already been given up on.
+	 */
+	if (so->tx.state != ISOTP_WAIT_FC &&
+	    so->tx.state != ISOTP_WAIT_FIRST_FC)
+		return 1;
+
 	if ((cf->len < ae + FC_CONTENT_SZ) ||
 	    ((so->opt.flags & ISOTP_CHECK_PADDING) &&
 	     check_pad(so, cf, ae + FC_CONTENT_SZ, so->opt.rxpad_content))) {
 		/* malformed PDU - report 'not a data message' */
 		sk->sk_err = EBADMSG;
@@ -575,10 +584,18 @@ static int isotp_rcv_cf(struct sock *sk, struct canfd_frame *cf, int ae,
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
@@ -879,10 +896,18 @@ static void isotp_rcv_echo(struct sk_buff *skb, void *data)
 	hrtimer_cancel(&so->txtimer);
 
 	/* local echo skb with consecutive frame has been consumed */
 	so->cfecho = 0;
 
+	/* isotp_tx_timer_handler() may have raced us for so->tx.state while
+	 * hrtimer_cancel() above waited for it to finish, already reporting
+	 * the tx error and resetting the state; don't resume a tx job that
+	 * has already been given up on.
+	 */
+	if (so->tx.state != ISOTP_SENDING)
+		return;
+
 	if (so->tx.idx >= so->tx.len) {
 		/* we are done */
 		so->tx.state = ISOTP_IDLE;
 		wake_up_interruptible(&so->wait);
 		return;
@@ -1141,12 +1166,11 @@ static int isotp_sendmsg(struct socket *sock, struct msghdr *msg, size_t size)
 	}
 
 	return size;
 
 err_event_drop:
-	/* got signal: force tx state machine to be idle */
-	so->tx.state = ISOTP_IDLE;
+	/* got signal: force tx state machine to be ISOTP_IDLE */
 	hrtimer_cancel(&so->txfrtimer);
 	hrtimer_cancel(&so->txtimer);
 err_out_drop:
 	/* drop this PDU and unlock a potential wait queue */
 	so->tx.state = ISOTP_IDLE;

-- 
2.53.0

