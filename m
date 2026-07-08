From: Oliver Hartkopp <socketcan@hartkopp.net>
Date: Wed, 08 Jul 2026 17:21:19 +0200
Subject: [PATCH v7 09/10] can: bcm: fix stale rx/tx ops after device
 removal
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260708-bcm_fixes-v7-9-c78896b342e4@hartkopp.net>
References: <20260708-bcm_fixes-v7-0-c78896b342e4@hartkopp.net>
In-Reply-To: <20260708-bcm_fixes-v7-0-c78896b342e4@hartkopp.net>
To: linux-can@vger.kernel.org
Cc: Oliver Hartkopp <socketcan@hartkopp.net>, 
 Marc Kleine-Budde <mkl@pengutronix.de>, sashiko-bot@kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783524080; l=5638;
 i=socketcan@hartkopp.net; s=20260128; h=from:subject:message-id;
 bh=RK42+qL1A/7pIzX1SkL1/NtzGTRkXsXNPwJoaB9Bi/s=;
 b=T/TgVXE5RoOWn9DLJLFmUg31BhsIi4tejrA8CYxB24CW0NBZfC3iiX3wIadDTAbMPJW8r5LXK
 +jGckZGl3Z2DRFJGUDmIjBNxHuEs6lab23D5XR42p3ozIkT14wQ3xJT
X-Developer-Key: i=socketcan@hartkopp.net; a=ed25519;
 pk=/gU/7/wBqak3kTsTeFbCCqUi9dnh+1i6ITEkfPj/BvU=
X-Endpoint-Received: by B4 Relay for socketcan@hartkopp.net/20260128 with auth_id=620
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

RX: an RX_SETUP update(!) for an existing op skipped can_rx_register()
unconditionally, even when a concurrent NETDEV_UNREGISTER had already
torn down its registration (op->rx_reg_dev == NULL). This silently
did not re-enable frame delivery for that updated filter with no error
reported to userspace. bcm_rx_setup() now re-registers in that case,
while leaving rx_ops with ifindex = 0 (all CAN interfaces) which never
carry a tracked rx_reg_dev registered as-is.

TX: bcm_notify() only handled bo->rx_ops on NETDEV_UNREGISTER, leaving
tx_ops with a dead ifindex untouched. bcm_tx_timeout_handler() kept
re-arming its hrtimer indefinitely, and if the ifindex was later
reused by a different CAN device, bcm_can_tx() would silently transmit
the cyclic frames to that unrelated device. bcm_notify() now stops the
timer and clears op->ifindex for affected tx_ops, without removing the
tx_op itself, so that a later TX_SETUP update can reconfigure it.

Reported-by: sashiko-bot@kernel.org
Link: https://lore.kernel.org/linux-can/20260708094536.DDF821F00A3A@smtp.kernel.org/
Fixes: ffd980f976e7 ("[CAN]: Add broadcast manager (bcm) protocol")
Signed-off-by: Oliver Hartkopp <socketcan@hartkopp.net>
---
 net/can/bcm.c | 45 +++++++++++++++++++++++++++++++++++++--------
 1 file changed, 37 insertions(+), 8 deletions(-)

diff --git a/net/can/bcm.c b/net/can/bcm.c
index 4bdca72f9327..9d0193170808 100644
--- a/net/can/bcm.c
+++ b/net/can/bcm.c
@@ -1254,10 +1254,11 @@ static int bcm_rx_setup(struct bcm_msg_head *msg_head, struct msghdr *msg,
 			int ifindex, struct sock *sk)
 {
 	struct bcm_sock *bo = bcm_sk(sk);
 	struct bcm_op *op;
 	int do_rx_register;
+	int new_op = 0;
 	int err = 0;
 
 	if ((msg_head->flags & RX_FILTER_ID) || (!(msg_head->nframes))) {
 		/* be robust against wrong usage ... */
 		msg_head->flags |= RX_FILTER_ID;
@@ -1330,12 +1331,19 @@ static int bcm_rx_setup(struct bcm_msg_head *msg_head, struct msghdr *msg,
 		spin_unlock_bh(&op->bcm_rx_update_lock);
 
 		/* free temporary frames / kfree(NULL) is safe */
 		kfree(new_frames);
 
-		/* Only an update -> do not call can_rx_register() */
-		do_rx_register = 0;
+		/* Don't register a new CAN filter for the rx_op update unless
+		 * a concurrent NETDEV_UNREGISTER notifier already tore down
+		 * the previous registration. In this case the receiver needs
+		 * to be re-registered here so that this update doesn't
+		 * silently stop delivering frames for the given ifindex.
+		 * Ops with ifindex = 0 (all CAN interfaces) never carry a
+		 * tracked rx_reg_dev and stay registered as-is.
+		 */
+		do_rx_register = (ifindex && !op->rx_reg_dev) ? 1 : 0;
 
 	} else {
 		/* insert new BCM operation for the given can_id */
 		op = kzalloc(OPSIZ, GFP_KERNEL);
 		if (!op)
@@ -1398,10 +1406,11 @@ static int bcm_rx_setup(struct bcm_msg_head *msg_head, struct msghdr *msg,
 		hrtimer_setup(&op->thrtimer, bcm_rx_thr_handler, CLOCK_MONOTONIC,
 			      HRTIMER_MODE_REL_SOFT);
 
 		/* call can_rx_register() */
 		do_rx_register = 1;
+		new_op = 1;
 
 	} /* if ((op = bcm_find_op(&bo->rx_ops, msg_head->can_id, ifindex))) */
 
 	/* check flags */
 
@@ -1439,11 +1448,14 @@ static int bcm_rx_setup(struct bcm_msg_head *msg_head, struct msghdr *msg,
 		if ((op->flags & STARTTIMER) && op->kt_ival1)
 			hrtimer_start(&op->timer, op->kt_ival1,
 				      HRTIMER_MODE_REL_SOFT);
 	}
 
-	/* now we can register for can_ids, if we added a new bcm_op */
+	/* now we can register for can_ids, if we added a new bcm_op
+	 * or need to re-register after a NETDEV_UNREGISTER tore down
+	 * the previous registration of an existing op
+	 */
 	if (do_rx_register) {
 		if (ifindex) {
 			struct net_device *dev;
 
 			dev = dev_get_by_index(sock_net(sk), ifindex);
@@ -1471,22 +1483,25 @@ static int bcm_rx_setup(struct bcm_msg_head *msg_head, struct msghdr *msg,
 				 * silently succeed without registering
 				 */
 				err = -ENODEV;
 			}
 
-		} else
+		} else {
 			err = can_rx_register(sock_net(sk), NULL, op->can_id,
 					      REGMASK(op->can_id),
 					      bcm_rx_handler, op, "bcm", sk);
-		if (err) {
+		}
+
+		if (err && new_op) {
 			/* this bcm rx op is broken -> remove it */
 			bcm_remove_op(op);
 			return err;
 		}
 
-		/* add this bcm_op to the list of the rx_ops */
-		list_add_rcu(&op->list, &bo->rx_ops);
+		/* add a new bcm_op to the list of the rx_ops */
+		if (new_op)
+			list_add_rcu(&op->list, &bo->rx_ops);
 	}
 
 	return msg_head->nframes * op->cfsiz + MHSIZ;
 
 free_op:
@@ -1702,15 +1717,29 @@ static void bcm_notify(struct bcm_sock *bo, unsigned long msg,
 	switch (msg) {
 
 	case NETDEV_UNREGISTER:
 		lock_sock(sk);
 
-		/* remove device specific receive entries */
+		/* rx_ops: remove device specific receive entries */
 		list_for_each_entry(op, &bo->rx_ops, list)
 			if (op->rx_reg_dev == dev)
 				bcm_rx_unreg(dev, op);
 
+		/* tx_ops: stop device specific cyclic transmissions on the
+		 * vanishing ifindex and invalidate the op->ifindex.
+		 */
+		list_for_each_entry(op, &bo->tx_ops, list) {
+			if (op->ifindex != dev->ifindex)
+				continue;
+
+			spin_lock_bh(&op->bcm_tx_lock);
+			op->ifindex = 0;
+			spin_unlock_bh(&op->bcm_tx_lock);
+
+			hrtimer_cancel(&op->timer);
+		}
+
 		/* remove device reference, if this is our bound device */
 		if (bo->bound && bo->ifindex == dev->ifindex) {
 #if IS_ENABLED(CONFIG_PROC_FS)
 			if (sock_net(sk)->can.bcmproc_dir && bo->bcm_proc_read) {
 				remove_proc_entry(bo->procname, sock_net(sk)->can.bcmproc_dir);

-- 
2.53.0

