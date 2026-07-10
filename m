From: Oliver Hartkopp <socketcan@hartkopp.net>
Date: Fri, 10 Jul 2026 22:42:55 +0200
Subject: [PATCH v6 4/5] can: isotp: fix lock-free state transition in tx
 timer handler
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260710-isotp-fixes-v6-4-a13c2539093d@hartkopp.net>
References: <20260710-isotp-fixes-v6-0-a13c2539093d@hartkopp.net>
In-Reply-To: <20260710-isotp-fixes-v6-0-a13c2539093d@hartkopp.net>
To: linux-can@vger.kernel.org
Cc: Oliver Hartkopp <socketcan@hartkopp.net>, 
 Marc Kleine-Budde <mkl@pengutronix.de>, sashiko-bot@kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783716177; l=2313;
 i=socketcan@hartkopp.net; s=20260128; h=from:subject:message-id;
 bh=Ot90eZUGABfjvSV1dl43SSv1YaX2fwm0Xj0TMEFLGYc=;
 b=XGi8HEO0LvZSMkq2w7ZvCY1sTbkOPFfseJm14MUIdAV5SCmV9Ny3YL3P30z89ufiBPZnE9lRb
 VlIKF159zdlDyKA/AGyGYbsHv7VPYaMCm5OQjPZMNW+PDcoZjw+22GC
X-Developer-Key: i=socketcan@hartkopp.net; a=ed25519;
 pk=/gU/7/wBqak3kTsTeFbCCqUi9dnh+1i6ITEkfPj/BvU=
X-Endpoint-Received: by B4 Relay for socketcan@hartkopp.net/20260128 with auth_id=620
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Commit 051737439eae ("can: isotp: fix race between isotp_sendsmg() and
isotp_release()") introduced a lock-free state machine check
to prevent race conditions between the TX timer and concurrent state
updates. However, the original patch missed replacing the initial
state checks and left the late assignment of ISOTP_IDLE as a blind,
non-atomic write.

Fix this by properly sampling the initial state into 'old_state' and using
cmpxchg() to atomically move the state to ISOTP_IDLE. If the state changed
concurrently (e.g., due to an incoming echo or a new sendmsg), the timeout
is stale and we bail out safely without corrupting the state machine.

Fixes: 43a08c3bdac4cb ("can: isotp: isotp_sendmsg(): fix TX buffer concurrent access in isotp_sendmsg()")
Reported-by: sashiko-bot@kernel.org
Link: https://lore.kernel.org/linux-can/20260710142146.BDAE61F000E9@smtp.kernel.org/
Signed-off-by: Oliver Hartkopp <socketcan@hartkopp.net>
---
 net/can/isotp.c | 11 ++++++++---
 1 file changed, 8 insertions(+), 3 deletions(-)

diff --git a/net/can/isotp.c b/net/can/isotp.c
index 5ef2a610fc17..0826ae837246 100644
--- a/net/can/isotp.c
+++ b/net/can/isotp.c
@@ -937,24 +937,29 @@ static void isotp_rcv_echo(struct sk_buff *skb, void *data)
 static enum hrtimer_restart isotp_tx_timer_handler(struct hrtimer *hrtimer)
 {
 	struct isotp_sock *so = container_of(hrtimer, struct isotp_sock,
 					     txtimer);
 	struct sock *sk = &so->sk;
+	u32 old_state = READ_ONCE(so->tx.state);
 
 	/* don't handle timeouts in IDLE or SHUTDOWN state */
-	if (so->tx.state == ISOTP_IDLE || so->tx.state == ISOTP_SHUTDOWN)
+	if (old_state == ISOTP_IDLE || old_state == ISOTP_SHUTDOWN)
+		return HRTIMER_NORESTART;
+
+	/* Only claim timeout if state is unchanged to avoid overwriting
+	 * concurrent state updates from isotp_sendmsg/isotp_rcv_echo.
+	 */
+	if (cmpxchg(&so->tx.state, old_state, ISOTP_IDLE) != old_state)
 		return HRTIMER_NORESTART;
 
 	/* we did not get any flow control or echo frame in time */
 
 	/* report 'communication error on send' */
 	sk->sk_err = ECOMM;
 	if (!sock_flag(sk, SOCK_DEAD))
 		sk_error_report(sk);
 
-	/* reset tx state */
-	so->tx.state = ISOTP_IDLE;
 	wake_up_interruptible(&so->wait);
 
 	return HRTIMER_NORESTART;
 }
 

-- 
2.53.0

