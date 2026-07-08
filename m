From: Oliver Hartkopp <socketcan@hartkopp.net>
Date: Wed, 08 Jul 2026 19:27:01 +0200
Subject: [PATCH v8 04/10] can: bcm: fix CAN frame rx/tx statistics
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260708-bcm_fixes-v8-4-8c2f5f3bc212@hartkopp.net>
References: <20260708-bcm_fixes-v8-0-8c2f5f3bc212@hartkopp.net>
In-Reply-To: <20260708-bcm_fixes-v8-0-8c2f5f3bc212@hartkopp.net>
To: linux-can@vger.kernel.org
Cc: Oliver Hartkopp <socketcan@hartkopp.net>, 
 Marc Kleine-Budde <mkl@pengutronix.de>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783531623; l=5246;
 i=socketcan@hartkopp.net; s=20260128; h=from:subject:message-id;
 bh=9nUyZLVL8gRmQOXh/UV97B3g1LLHaQafpLp/e7ndSOQ=;
 b=9Vd4+C7SWi3vCPpPdBnrundOceoIrmID6R9U5CvTcPxQOHNCAoj5FMQj6csKgUWQTrw2ZJjTP
 fwf0sXYo5UGAWaPUE0iY40Dy7Ris8peER7RExFNgzg87m0b8YOtLepw
X-Developer-Key: i=socketcan@hartkopp.net; a=ed25519;
 pk=/gU/7/wBqak3kTsTeFbCCqUi9dnh+1i6ITEkfPj/BvU=
X-Endpoint-Received: by B4 Relay for socketcan@hartkopp.net/20260128 with auth_id=620
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

KCSAN detected a data race within the bcm_rx_handler() when two CAN frames
have been simultaneously received and processed in a single rx op by two
different CPUs.

Use atomic operations with (signed) long data types to access the
statistics in the hot path to fix the KCSAN complaint.

Additionally simplify the update and check of statistics overflow by
using the atomic operations in a separate bcm_update_stats() function and
put this function under bcm_rx_update_lock to prevent races when resetting
the counters.

Fixes: ffd980f976e7 ("[CAN]: Add broadcast manager (bcm) protocol")
Signed-off-by: Oliver Hartkopp <socketcan@hartkopp.net>
---
 net/can/bcm.c | 47 ++++++++++++++++++++++++++++++-----------------
 1 file changed, 30 insertions(+), 17 deletions(-)

diff --git a/net/can/bcm.c b/net/can/bcm.c
index af4bb4182bc2..340b7fc89744 100644
--- a/net/can/bcm.c
+++ b/net/can/bcm.c
@@ -110,11 +110,11 @@ struct bcm_op {
 	struct rcu_head rcu;
 	struct work_struct work;
 	int ifindex;
 	canid_t can_id;
 	u32 flags;
-	unsigned long frames_abs, frames_filtered;
+	atomic_long_t frames_abs, frames_filtered;
 	struct bcm_timeval ival1, ival2;
 	struct hrtimer timer, thrtimer;
 	ktime_t rx_stamp, kt_ival1, kt_ival2, kt_lastmsg;
 	int rx_ifindex;
 	int cfsiz;
@@ -227,14 +227,17 @@ static int bcm_proc_show(struct seq_file *m, void *v)
 
 	rcu_read_lock();
 
 	list_for_each_entry_rcu(op, &bo->rx_ops, list) {
 
-		unsigned long reduction;
+		long reduction, frames_filtered, frames_abs;
+
+		frames_filtered = atomic_long_read(&op->frames_filtered);
+		frames_abs = atomic_long_read(&op->frames_abs);
 
 		/* print only active entries & prevent division by zero */
-		if (!op->frames_abs)
+		if (!frames_abs)
 			continue;
 
 		seq_printf(m, "rx_op: %03X %-5s ", op->can_id,
 			   bcm_proc_getifname(net, ifname, op->ifindex));
 
@@ -252,13 +255,13 @@ static int bcm_proc_show(struct seq_file *m, void *v)
 		if (op->kt_ival2)
 			seq_printf(m, "thr=%lld ",
 				   (long long)ktime_to_us(op->kt_ival2));
 
 		seq_printf(m, "# recv %ld (%ld) => reduction: ",
-			   op->frames_filtered, op->frames_abs);
+			   frames_filtered, frames_abs);
 
-		reduction = 100 - (op->frames_filtered * 100) / op->frames_abs;
+		reduction = 100 - (frames_filtered * 100) / frames_abs;
 
 		seq_printf(m, "%s%ld%%\n",
 			   (reduction == 100) ? "near " : "", reduction);
 	}
 
@@ -278,20 +281,30 @@ static int bcm_proc_show(struct seq_file *m, void *v)
 
 		if (op->kt_ival2)
 			seq_printf(m, "t2=%lld ",
 				   (long long)ktime_to_us(op->kt_ival2));
 
-		seq_printf(m, "# sent %ld\n", op->frames_abs);
+		seq_printf(m, "# sent %ld\n",
+			   atomic_long_read(&op->frames_abs));
 	}
 	seq_putc(m, '\n');
 
 	rcu_read_unlock();
 
 	return 0;
 }
 #endif /* CONFIG_PROC_FS */
 
+static void bcm_update_stats(struct bcm_op *op)
+{
+	/* prevent statistics overflow */
+	if (atomic_long_inc_return(&op->frames_abs) > LONG_MAX / 100) {
+		atomic_long_set(&op->frames_filtered, 0);
+		atomic_long_set(&op->frames_abs, 0);
+	}
+}
+
 /*
  * bcm_can_tx - send the (next) CAN frame to the appropriate CAN interface
  *              of the given bcm tx op
  */
 static void bcm_can_tx(struct bcm_op *op, struct canfd_frame *cf)
@@ -342,11 +355,11 @@ static void bcm_can_tx(struct bcm_op *op, struct canfd_frame *cf)
 
 	/* update currframe and count under lock protection */
 	spin_lock_bh(&op->bcm_tx_lock);
 
 	if (!err)
-		op->frames_abs++;
+		bcm_update_stats(op);
 
 	op->currframe++;
 
 	/* reached last frame? */
 	if (op->currframe >= op->nframes)
@@ -495,16 +508,13 @@ static enum hrtimer_restart bcm_tx_timeout_handler(struct hrtimer *hrtimer)
  */
 static void bcm_rx_changed(struct bcm_op *op, struct canfd_frame *data)
 {
 	struct bcm_msg_head head;
 
-	/* update statistics */
-	op->frames_filtered++;
-
-	/* prevent statistics overflow */
-	if (op->frames_filtered > ULONG_MAX/100)
-		op->frames_filtered = op->frames_abs = 0;
+	/* update statistics (frames_filtered <= frames_abs) */
+	if (atomic_long_read(&op->frames_abs))
+		atomic_long_inc(&op->frames_filtered);
 
 	/* this element is not throttled anymore */
 	data->flags &= ~RX_THR;
 
 	memset(&head, 0, sizeof(head));
@@ -746,20 +756,23 @@ static void bcm_rx_handler(struct sk_buff *skb, void *data)
 
 	/* save rx timestamp */
 	op->rx_stamp = skb->tstamp;
 	/* save originator for recvfrom() */
 	op->rx_ifindex = skb->dev->ifindex;
-	/* update statistics */
-	op->frames_abs++;
 
-	/* snapshot the flag under lock: op->flags/op->frames may be updated
-	 * concurrently by bcm_rx_setup().
+	/* snapshot RTR content under lock: op->flags/op->frames may be
+	 * updated concurrently by bcm_rx_setup().
 	 */
 	spin_lock_bh(&op->bcm_rx_update_lock);
+
+	/* update statistics with lock analogue to bcm_rx_changed() callers */
+	bcm_update_stats(op);
+
 	rtr_frame = op->flags & RX_RTR_FRAME;
 	if (rtr_frame)
 		memcpy(&rtrframe, op->frames, op->cfsiz);
+
 	spin_unlock_bh(&op->bcm_rx_update_lock);
 
 	if (rtr_frame) {
 		/* send reply for RTR-request (placed in op->frames[0]) */
 		bcm_can_tx(op, &rtrframe);

-- 
2.53.0

