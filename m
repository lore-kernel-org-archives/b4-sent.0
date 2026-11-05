From: Jack Wu <jackbb_wu@compal.com>
Date: Thu, 05 Nov 2026 15:56:32 +0800
Subject: [PATCH v11 6/6] net: wwan: t9xx: Add AT & MBIM WWAN ports
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261105-t9xx_driver_v1-v11-6-2084aa512864@compal.com>
References: <20261105-t9xx_driver_v1-v11-0-2084aa512864@compal.com>
In-Reply-To: <20261105-t9xx_driver_v1-v11-0-2084aa512864@compal.com>
To: Loic Poulain <loic.poulain@oss.qualcomm.com>, 
 Sergey Ryazanov <ryazanov.s.a@gmail.com>, 
 Johannes Berg <johannes@sipsolutions.net>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Jack Wu <jackbb_wu@compal.com>, Wen-Zhi Huang <wen-zhi.huang@mediatek.com>, 
 Shi-Wei Yeh <shi-wei.yeh@mediatek.com>, 
 Minano Tseng <Minano.tseng@mediatek.com>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Simon Horman <horms@kernel.org>, Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>, Robert Yu <robert_yu@compal.com>, 
 Jeff Chang <Jeff_Chang@compal.com>
Cc: linux-kernel@vger.kernel.org, netdev@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-mediatek@lists.infradead.org, 
 linux-doc@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793865391; l=21538;
 i=jackbb_wu@compal.com; s=20260526; h=from:subject:message-id;
 bh=8x4saTp8AVt0npiZO7jqsHo9mV+Qv997DP5d0xZbCUI=;
 b=8nMgza9OlSOUnEFg8NT36GaXqxl4pcqljzrSex4k0p08QZ72ToYiJDV4Td3RVrPjSmS1Lk1np
 8Evc/iMpdI7Aq3c+wbKRU6yPUBBN+mh172NtXePgeplrYv1hS2ViuCF
X-Developer-Key: i=jackbb_wu@compal.com; a=ed25519;
 pk=VH1prTWixNl8OEUPPSfII3p46MzJpQN8J3+ecE1tZXg=
X-Endpoint-Received: by B4 Relay for jackbb_wu@compal.com/20260526 with auth_id=793
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add AT & MBIM ports to the port infrastructure.

mtk_port_wwan_init() only prepares the port object; wwan_create_port()
is called from mtk_port_wwan_enable(). enable() runs on FSM_STATE_READY
through the new mtk_port_enable_by_type(PORT_TBL_MD) hook, which enables
every MD-table port the device marked enabled, internal ports included.
CCCI_UART2 and CCCI_MBIM get CLDMA1 TXQ(5)/RXQ(5) and TXQ(2)/RXQ(2) in
mtk_queue_info[].

The implemented WWAN port operations are start, stop, tx and
tx_blocking. The tx path copies with skb_copy_bits(), handling the
non-linear skb the WWAN core supplies for writes larger than one
fragment. One write() is capped at MTK_PORT_MAX_TX_PKT CCCI packets
(SKB_LIST_MAX_LEN, the HIF queue depth) and anything larger is rejected
with -EMSGSIZE: every packet after the first is submitted with
force_send, which bypasses the depth check, so without a cap a single
write could queue an unbounded number of skbs. The same cap bounds the
second copy of the message the tx path holds and the number of times
skb_copy_bits() re-walks the source fragment chain.

The first packet of every write() is depth checked. A blocking write
waits on the port's trb wait queue for the HIF queue to drop below its
depth before it submits anything, rather than bypassing the check, so
blocking writers whose waits are cut short by signals cannot grow the
queue either.

start() publishes the wwan_port under w_priv.w_lock together with
PORT_S_OPEN, so the receive path can never see an open port with a NULL
wwan_port and drop the reply to a command that open made possible.

TX back-pressure is reported through wwan_port_txon()/txoff() rather
than a .tx_poll operation: a queue-full submit failure pauses the port
and a per-port tx_complete hook resumes it from TRB completion, so
poll() sleeps on the WWAN core's own waitqueue - whose lifetime is
pinned by the open file - instead of a driver waitqueue that
wwan_remove_port() can outlive. The pause path drops w_lock before
querying the HIF for queue occupancy, because HIF teardown holds
trans->submit_lock while the TRB completions it flushes call back into
the port under w_lock.

Signed-off-by: Jack Wu <jackbb_wu@compal.com>
---
 drivers/net/wwan/t9xx/mtk_ctrl_plane.h      |   4 +
 drivers/net/wwan/t9xx/mtk_port.c            |  31 +++
 drivers/net/wwan/t9xx/mtk_port.h            |  14 +
 drivers/net/wwan/t9xx/mtk_port_io.c         | 413 ++++++++++++++++++++++++++++
 drivers/net/wwan/t9xx/mtk_port_io.h         |   1 +
 drivers/net/wwan/t9xx/pcie/mtk_trans_ctrl.c |   8 +
 6 files changed, 471 insertions(+)

diff --git a/drivers/net/wwan/t9xx/mtk_ctrl_plane.h b/drivers/net/wwan/t9xx/mtk_ctrl_plane.h
index 617c022a24c3..295c3c532c93 100644
--- a/drivers/net/wwan/t9xx/mtk_ctrl_plane.h
+++ b/drivers/net/wwan/t9xx/mtk_ctrl_plane.h
@@ -21,6 +21,10 @@ enum mtk_ccci_ch {
 	/* to MD */
 	CCCI_CONTROL_RX = 0x2000,
 	CCCI_CONTROL_TX = 0x2001,
+	CCCI_UART2_RX = 0x200A,
+	CCCI_UART2_TX = 0x200C,
+	CCCI_MBIM_RX = 0x20D0,
+	CCCI_MBIM_TX = 0x20D1,
 };
 
 enum mtk_trb_cmd_type {
diff --git a/drivers/net/wwan/t9xx/mtk_port.c b/drivers/net/wwan/t9xx/mtk_port.c
index 101ec14fc993..a0defeec9abf 100644
--- a/drivers/net/wwan/t9xx/mtk_port.c
+++ b/drivers/net/wwan/t9xx/mtk_port.c
@@ -285,6 +285,13 @@ static int mtk_port_tx_complete(struct sk_buff *skb)
 				     "Failed to send data: status:%d, port:%s\n",
 				     trb->status, port->info.name);
 
+	/* The hook may sleep, but it also runs from HIF teardown with
+	 * trans->submit_lock held, so it must not take a lock that is ever
+	 * held across a call into the HIF.
+	 */
+	if (mtk_port_get_ops(port->info.type)->tx_complete)
+		mtk_port_get_ops(port->info.type)->tx_complete(port);
+
 	/* Pairs with the smp_load_acquire() of trb->done in the waiters. */
 	smp_store_release(&trb->done, true);
 	wake_up_all(&port->trb_wq);
@@ -626,6 +633,27 @@ int mtk_port_ch_disable(struct mtk_port *port)
 	return ret;
 }
 
+static void mtk_port_enable_by_type(struct mtk_port_mngr *port_mngr, int tbl_type)
+{
+	struct radix_tree_iter iter;
+	struct mtk_port *port;
+	void __rcu **slot;
+
+	radix_tree_for_each_slot(slot, &port_mngr->port_tbl[tbl_type],
+				 &iter, 0) {
+		port = mtk_port_tbl_slot(&slot, &iter);
+		if (!port)
+			continue;
+		/* Consumed, so a later boot acts only on what its own port
+		 * enumeration advertised.
+		 */
+		if (port->enable) {
+			port->enable = false;
+			mtk_port_get_ops(port->info.type)->enable(port);
+		}
+	}
+}
+
 static void mtk_port_disable(struct mtk_port_mngr *port_mngr)
 {
 	struct radix_tree_iter iter;
@@ -658,6 +686,9 @@ void mtk_port_mngr_fsm_state_handler(struct mtk_fsm_param *fsm_param, void *arg)
 	case FSM_STATE_OFF:
 		mtk_port_disable(port_mngr);
 		break;
+	case FSM_STATE_READY:
+		mtk_port_enable_by_type(port_mngr, PORT_TBL_MD);
+		break;
 	default:
 		break;
 	}
diff --git a/drivers/net/wwan/t9xx/mtk_port.h b/drivers/net/wwan/t9xx/mtk_port.h
index d160f73c1834..0951c38359e1 100644
--- a/drivers/net/wwan/t9xx/mtk_port.h
+++ b/drivers/net/wwan/t9xx/mtk_port.h
@@ -11,6 +11,7 @@
 #include <linux/radix-tree.h>
 #include <linux/skbuff.h>
 #include <linux/types.h>
+#include <linux/wwan.h>
 
 #include "mtk_ctrl_plane.h"
 #include "mtk_dev.h"
@@ -58,6 +59,7 @@ enum mtk_port_tbl {
 
 enum mtk_port_type {
 	PORT_TYPE_INTERNAL,
+	PORT_TYPE_WWAN,
 	PORT_TYPE_MAX
 };
 
@@ -66,6 +68,17 @@ struct mtk_internal_port {
 	int (*recv_cb)(void *arg, struct sk_buff *skb);
 };
 
+struct mtk_wwan_port {
+	/* w_lock serialises w_port and PORT_S_OPEN against the receive path,
+	 * and txoff/txon against TX completion.  It is a leaf: TX completion
+	 * can take it with trans->submit_lock held, so it is never held
+	 * across a call into the HIF.
+	 */
+	struct mutex w_lock;
+	enum wwan_port_type w_type;
+	struct wwan_port *w_port;
+};
+
 struct mtk_port_cfg {
 	enum mtk_ccci_ch tx_ch;
 	enum mtk_ccci_ch rx_ch;
@@ -91,6 +104,7 @@ struct mtk_port {
 	wait_queue_head_t trb_wq;
 	struct mtk_port_mngr *port_mngr;
 	struct mtk_internal_port i_priv;
+	struct mtk_wwan_port w_priv;
 };
 
 struct mtk_port_mngr {
diff --git a/drivers/net/wwan/t9xx/mtk_port_io.c b/drivers/net/wwan/t9xx/mtk_port_io.c
index e92ce1cb7c00..d5232cb150bf 100644
--- a/drivers/net/wwan/t9xx/mtk_port_io.c
+++ b/drivers/net/wwan/t9xx/mtk_port_io.c
@@ -3,8 +3,13 @@
  * Copyright (c) 2022, MediaTek Inc.
  */
 #include <linux/netdevice.h>
+#include <linux/sched/signal.h>
+#include <linux/slab.h>
+#include <linux/wait.h>
+#include <linux/wwan.h>
 
 #include "mtk_port_io.h"
+#include "mtk_trans_ctrl.h"
 
 static void mtk_port_put_locked(struct mtk_port *port)
 {
@@ -20,6 +25,122 @@ static void mtk_port_struct_init(struct mtk_port *port)
 	init_waitqueue_head(&port->trb_wq);
 }
 
+/* Packets after the first carry force_send, which bypasses the HIF depth
+ * check, so one write() must not exceed one queue depth.
+ */
+#define MTK_PORT_MAX_TX_PKT	SKB_LIST_MAX_LEN
+
+/* A blocking write waits here rather than have its first packet refused by
+ * the depth check: a refused packet is freed with its trb and cannot be
+ * submitted again.  TX completions and port state changes wake trb_wq.
+ */
+static int mtk_port_wait_tx_space(struct mtk_port *port)
+{
+	union ctrl_hif_cmd_data hif_cmd = { .rx_ch = port->info.rx_ch };
+	struct mtk_md_dev *mdev = port->port_mngr->ctrl_blk->mdev;
+	DEFINE_WAIT_FUNC(wait, woken_wake_function);
+	int ret = 0;
+
+	add_wait_queue(&port->trb_wq, &wait);
+	/* The check takes submit_lock, so it cannot be a wait_event()
+	 * condition.  An error from it is left to the submit to report.
+	 */
+	while (mtk_pcie_hif_cmd_func(mdev, HIF_CTRL_CMD_CHECK_TX_FULL, &hif_cmd) > 0 &&
+	       !test_bit(PORT_S_FLUSH, &port->status) &&
+	       test_bit(PORT_S_WR, &port->status)) {
+		if (signal_pending(current)) {
+			ret = -ERESTARTSYS;
+			break;
+		}
+		wait_woken(&wait, TASK_INTERRUPTIBLE, MAX_SCHEDULE_TIMEOUT);
+	}
+	remove_wait_queue(&port->trb_wq, &wait);
+
+	return ret;
+}
+
+/* Every packet is built before any is submitted: the WWAN core turns a
+ * partial write into a whole-write failure and userspace re-sends the whole
+ * message, so a submit that fails midway leaves a prefix on the wire.  It
+ * cannot be retried here - the skb is freed with its trb - so it is logged.
+ *
+ * -EINTR means the skb was already submitted, so that packet counts as
+ * accepted and the remaining ones are still sent.
+ */
+static int mtk_port_common_write(struct mtk_port *port, struct sk_buff *src, bool blocking)
+{
+	u32 packet_size, left_cnt = src->len, cur_pos;
+	u32 payload_mtu, sent_len = 0;
+	struct sk_buff_head list;
+	bool force_send = false;
+	struct sk_buff *skb;
+	int ret;
+
+	ret = mtk_port_status_check(port);
+	if (ret)
+		return ret;
+
+	payload_mtu = port->tx_mtu - sizeof(struct mtk_ccci_header);
+	if (src->len > MTK_PORT_MAX_TX_PKT * payload_mtu)
+		return -EMSGSIZE;
+
+	if (blocking) {
+		ret = mtk_port_wait_tx_space(port);
+		if (ret)
+			return ret;
+	}
+
+	__skb_queue_head_init(&list);
+
+	while (left_cnt) {
+		skb = __dev_alloc_skb(port->tx_mtu, GFP_KERNEL);
+		if (!skb) {
+			ret = -ENOMEM;
+			goto err_purge;
+		}
+
+		skb_reserve(skb, sizeof(struct mtk_ccci_header));
+
+		packet_size = min_t(u32, left_cnt, payload_mtu);
+		cur_pos = src->len - left_cnt;
+		ret = skb_copy_bits(src, cur_pos, skb_put(skb, packet_size), packet_size);
+		if (ret) {
+			dev_err(port->port_mngr->ctrl_blk->mdev->dev,
+				"Failed to copy data for port(%s)\n", port->info.name);
+			dev_kfree_skb_any(skb);
+			goto err_purge;
+		}
+
+		__skb_queue_tail(&list, skb);
+		left_cnt -= packet_size;
+	}
+
+	while ((skb = __skb_dequeue(&list))) {
+		/* mtk_port_send_data() may free the skb, so sample its length
+		 * while it is still valid.
+		 */
+		packet_size = skb->len;
+
+		ret = mtk_port_send_data(port, skb, blocking, force_send);
+		if (ret < 0 && ret != -EINTR)
+			goto err_submit;
+
+		sent_len += packet_size;
+		force_send = true;
+	}
+
+	return 0;
+
+err_submit:
+	if (sent_len)
+		dev_err_ratelimited(port->port_mngr->ctrl_blk->mdev->dev,
+				    "Partial write on port(%s): %u of %u bytes sent, error:%d\n",
+				    port->info.name, sent_len, src->len, ret);
+err_purge:
+	__skb_queue_purge(&list);
+	return ret;
+}
+
 static int mtk_port_internal_init(struct mtk_port *port)
 {
 	mtk_port_struct_init(port);
@@ -219,8 +340,300 @@ static const struct mtk_port_ops port_internal_ops = {
 	.recv = mtk_port_internal_recv,
 };
 
+static void mtk_port_get_locked(struct mtk_port *port)
+{
+	mutex_lock(&mtk_port_mngr_grp_mtx);
+	kref_get(&port->kref);
+	mutex_unlock(&mtk_port_mngr_grp_mtx);
+}
+
+static int mtk_port_wwan_open(struct wwan_port *w_port)
+{
+	struct mtk_port *port;
+	int ret;
+
+	port = wwan_port_get_drvdata(w_port);
+	mtk_port_get_locked(port);
+
+	/* mtk_port_common_open() is what sets PORT_S_OPEN, and the RX path
+	 * tests it together with w_port, so both are published under w_lock.
+	 */
+	mutex_lock(&port->w_priv.w_lock);
+	ret = mtk_port_common_open(port);
+	if (!ret)
+		port->w_priv.w_port = w_port;
+	mutex_unlock(&port->w_priv.w_lock);
+	if (ret) {
+		mtk_port_put_locked(port);
+		return ret;
+	}
+
+	/* WWAN_PORT_TX_OFF persists on the wwan_port across close/open
+	 * cycles; start every session writable.
+	 */
+	wwan_port_txon(w_port);
+
+	return 0;
+}
+
+static void mtk_port_wwan_close(struct wwan_port *w_port)
+{
+	struct mtk_port *port = wwan_port_get_drvdata(w_port);
+
+	/* Clear PORT_S_OPEN under the same lock mtk_port_wwan_recv() holds, so
+	 * a receive that saw the port open has finished its wwan_port_rx()
+	 * before stop() returns and the core purges its rx queue.
+	 */
+	mutex_lock(&port->w_priv.w_lock);
+	mtk_port_common_close(port);
+	mutex_unlock(&port->w_priv.w_lock);
+
+	mtk_port_put_locked(port);
+}
+
+/* w_lock closes the txoff-after-drain window described in
+ * mtk_port_wwan_tx_pause().
+ */
+static void mtk_port_wwan_tx_complete(struct mtk_port *port)
+{
+	mutex_lock(&port->w_priv.w_lock);
+	if (port->w_priv.w_port)
+		wwan_port_txon(port->w_priv.w_port);
+	mutex_unlock(&port->w_priv.w_lock);
+}
+
+/* Pause TX after a queue-full submit failure.  The queue may have drained
+ * between that failure and the txoff below, and that tx_complete is lost, so
+ * recheck and undo the txoff if the queue is no longer full.
+ *
+ * w_lock is dropped for the recheck to keep it a leaf with respect to
+ * trans->submit_lock.  A tx_complete landing in the gap can only add a txon,
+ * so TX is never left off with nothing to wake it.
+ */
+static void mtk_port_wwan_tx_pause(struct mtk_port *port)
+{
+	union ctrl_hif_cmd_data hif_cmd;
+	struct mtk_ctrl_blk *ctrl_blk;
+	int ret;
+
+	ctrl_blk = port->port_mngr->ctrl_blk;
+
+	mutex_lock(&port->w_priv.w_lock);
+	if (!port->w_priv.w_port) {
+		mutex_unlock(&port->w_priv.w_lock);
+		return;
+	}
+
+	wwan_port_txoff(port->w_priv.w_port);
+	mutex_unlock(&port->w_priv.w_lock);
+
+	hif_cmd.rx_ch = port->info.rx_ch;
+	ret = mtk_pcie_hif_cmd_func(ctrl_blk->mdev, HIF_CTRL_CMD_CHECK_TX_FULL,
+				    &hif_cmd);
+	if (ret <= 0)
+		mtk_port_wwan_tx_complete(port);
+}
+
+static int mtk_port_wwan_tx(struct wwan_port *w_port, struct sk_buff *skb, bool blocking)
+{
+	struct mtk_port *port = wwan_port_get_drvdata(w_port);
+	int ret;
+
+	if (unlikely(!skb->len)) {
+		consume_skb(skb);
+		return 0;
+	}
+
+	ret = mtk_port_common_write(port, skb, blocking);
+	if (ret < 0) {
+		if (ret == -EAGAIN)
+			mtk_port_wwan_tx_pause(port);
+		return ret;
+	}
+
+	consume_skb(skb);
+	return 0;
+}
+
+static int mtk_port_wwan_write(struct wwan_port *w_port, struct sk_buff *skb)
+{
+	return mtk_port_wwan_tx(w_port, skb, false);
+}
+
+static int mtk_port_wwan_write_blocking(struct wwan_port *w_port, struct sk_buff *skb)
+{
+	return mtk_port_wwan_tx(w_port, skb, true);
+}
+
+/* No .tx_poll: it would poll_wait() on port->trb_wq, which lives in a
+ * mtk_port that wwan_remove_port() lets go of while the file stays open,
+ * and wake_up_pollfree() is not available to modules.  TX back-pressure
+ * reaches poll() through wwan_port_txon()/txoff() on the core's own
+ * waitqueue instead, whose lifetime is pinned by the open file.
+ */
+static const struct wwan_port_ops wwan_ops = {
+	.start = mtk_port_wwan_open,
+	.stop = mtk_port_wwan_close,
+	.tx = mtk_port_wwan_write,
+	.tx_blocking = mtk_port_wwan_write_blocking,
+};
+
+static int mtk_port_wwan_init(struct mtk_port *port)
+{
+	mtk_port_struct_init(port);
+	port->enable = false;
+
+	mutex_init(&port->w_priv.w_lock);
+
+	switch (port->info.rx_ch) {
+	case CCCI_MBIM_RX:
+		port->w_priv.w_type = WWAN_PORT_MBIM;
+		break;
+	case CCCI_UART2_RX:
+		port->w_priv.w_type = WWAN_PORT_AT;
+		break;
+	default:
+		port->w_priv.w_type = WWAN_PORT_UNKNOWN;
+		break;
+	}
+
+	return 0;
+}
+
+static void mtk_port_wwan_exit(struct mtk_port *port)
+{
+	if (test_bit(PORT_S_ENABLE, &port->status))
+		mtk_port_get_ops(port->info.type)->disable(port);
+	mutex_destroy(&port->w_priv.w_lock);
+}
+
+static void mtk_port_wwan_enable(struct mtk_port *port)
+{
+	struct mtk_port_mngr *port_mngr;
+	struct wwan_port_caps caps;
+	struct wwan_port *wp;
+	int ret;
+
+	port_mngr = port->port_mngr;
+
+	if (test_bit(PORT_S_ENABLE, &port->status))
+		return;
+
+	ret = mtk_port_ch_enable(port);
+	if (ret && ret != -EBUSY) {
+		/* On -ETIMEDOUT the enable's outcome is not yet known: the
+		 * ENABLE trb may still be queued.  The DISABLE is queued
+		 * behind it, so the channel cannot stay armed unowned.
+		 */
+		mtk_port_ch_disable(port);
+		return;
+	}
+
+	/* A zero frag_len would make wwan_port_fops_write() loop forever. */
+	if (port->tx_mtu <= sizeof(struct mtk_ccci_header)) {
+		dev_err(port_mngr->ctrl_blk->mdev->dev,
+			"Invalid tx_mtu for port(%s)\n", port->info.name);
+		mtk_port_ch_disable(port);
+		return;
+	}
+
+	/* The core allocates frag_len + headroom_len and skb_put()s frag_len,
+	 * so frag_len is the payload budget: subtract the CCCI header to make
+	 * one core fragment exactly one CCCI packet.
+	 */
+	caps.frag_len = port->tx_mtu - sizeof(struct mtk_ccci_header);
+	caps.headroom_len = sizeof(struct mtk_ccci_header);
+
+	/* These bits must be set before wwan_create_port(): the device node
+	 * becomes openable inside it and mtk_port_common_open() rejects a
+	 * port without PORT_S_ENABLE.
+	 */
+	set_bit(PORT_S_WR, &port->status);
+	set_bit(PORT_S_ENABLE, &port->status);
+
+	wp = wwan_create_port(port_mngr->ctrl_blk->mdev->dev,
+			      port->w_priv.w_type,
+			      &wwan_ops, &caps, port);
+	if (IS_ERR(wp)) {
+		dev_warn(port_mngr->ctrl_blk->mdev->dev,
+			 "Failed to create wwan port for (%s)\n", port->info.name);
+		clear_bit(PORT_S_ENABLE, &port->status);
+		clear_bit(PORT_S_WR, &port->status);
+		mtk_port_ch_disable(port);
+		return;
+	}
+
+	/* .start publishes w_port for an opened node; this covers the node
+	 * nobody opened, which still needs w_port to be removed.
+	 */
+	mutex_lock(&port->w_priv.w_lock);
+	port->w_priv.w_port = wp;
+	mutex_unlock(&port->w_priv.w_lock);
+}
+
+static void mtk_port_wwan_disable(struct mtk_port *port)
+{
+	struct wwan_port *w_port;
+	int ret;
+
+	if (!test_and_clear_bit(PORT_S_ENABLE, &port->status))
+		return;
+
+	/* PORT_S_WR is in the blocking TX wait condition: wake the waiters. */
+	clear_bit(PORT_S_WR, &port->status);
+	wake_up_all(&port->trb_wq);
+
+	/* w_lock must be dropped before wwan_remove_port(): that takes the
+	 * core's ops_lock and forces stop(), which is close() taking w_lock.
+	 */
+	mutex_lock(&port->w_priv.w_lock);
+	w_port = port->w_priv.w_port;
+	port->w_priv.w_port = NULL;
+	mutex_unlock(&port->w_priv.w_lock);
+
+	ret = mtk_port_ch_disable(port);
+	if (ret)
+		dev_warn(port->port_mngr->ctrl_blk->mdev->dev,
+			 "Failed to disable channel for port(%s): %d\n",
+			 port->info.name, ret);
+
+	wwan_remove_port(w_port);
+}
+
+static int mtk_port_wwan_recv(struct mtk_port *port, struct sk_buff *skb)
+{
+	/* Drop frames when nobody has the device open: wwan_port_rx() queues
+	 * without bound and only a reader drains the queue, so accepting
+	 * unsolicited traffic here would grow the rxq indefinitely.  Both
+	 * conditions are read under w_lock, which mtk_port_wwan_close() also
+	 * takes, so a frame accepted here cannot land on a queue the core is
+	 * about to purge.
+	 */
+	mutex_lock(&port->w_priv.w_lock);
+	if (!test_bit(PORT_S_OPEN, &port->status) || !port->w_priv.w_port) {
+		mutex_unlock(&port->w_priv.w_lock);
+		dev_dbg_ratelimited(port->port_mngr->ctrl_blk->mdev->dev,
+				    "Drop RX for unopened port(%s)\n", port->info.name);
+		return -ENXIO;
+	}
+
+	wwan_port_rx(port->w_priv.w_port, skb);
+	mutex_unlock(&port->w_priv.w_lock);
+	return 0;
+}
+
+static const struct mtk_port_ops port_wwan_ops = {
+	.init = mtk_port_wwan_init,
+	.exit = mtk_port_wwan_exit,
+	.enable = mtk_port_wwan_enable,
+	.disable = mtk_port_wwan_disable,
+	.recv = mtk_port_wwan_recv,
+	.tx_complete = mtk_port_wwan_tx_complete,
+};
+
 static const struct mtk_port_ops *mtk_port_ops_tbl[PORT_TYPE_MAX] = {
 	&port_internal_ops,
+	&port_wwan_ops,
 };
 
 const struct mtk_port_ops *mtk_port_get_ops(enum mtk_port_type type)
diff --git a/drivers/net/wwan/t9xx/mtk_port_io.h b/drivers/net/wwan/t9xx/mtk_port_io.h
index db1d9ae52d9a..e1e695100ab1 100644
--- a/drivers/net/wwan/t9xx/mtk_port_io.h
+++ b/drivers/net/wwan/t9xx/mtk_port_io.h
@@ -18,6 +18,7 @@ struct mtk_port_ops {
 	void (*enable)(struct mtk_port *port);
 	void (*disable)(struct mtk_port *port);
 	int (*recv)(struct mtk_port *port, struct sk_buff *skb);
+	void (*tx_complete)(struct mtk_port *port);
 };
 
 const struct mtk_port_ops *mtk_port_get_ops(enum mtk_port_type type);
diff --git a/drivers/net/wwan/t9xx/pcie/mtk_trans_ctrl.c b/drivers/net/wwan/t9xx/pcie/mtk_trans_ctrl.c
index d87cb61d5326..7492a797b682 100644
--- a/drivers/net/wwan/t9xx/pcie/mtk_trans_ctrl.c
+++ b/drivers/net/wwan/t9xx/pcie/mtk_trans_ctrl.c
@@ -26,6 +26,10 @@ static const int mtk_srv_cfg[NR_CLDMA][HW_QUE_NUM] = {
 
 /* the number of RX GPDs should be at least two */
 static const struct queue_info mtk_queue_info[] = {
+	{CCCI_UART2_TX, CCCI_UART2_RX, CLDMA1, TXQ(5), RXQ(5),
+	 Q_MTU_3_5K, Q_MTU_3_5K, TX_GPD_NUM, RX_GPD_NUM, 0},
+	{CCCI_MBIM_TX, CCCI_MBIM_RX, CLDMA1, TXQ(2), RXQ(2),
+	 Q_MTU_3_5K, Q_MTU_3_5K, TX_GPD_NUM, RX_GPD_NUM, 0},
 	{CCCI_CONTROL_TX, CCCI_CONTROL_RX, CLDMA1, TXQ(0), RXQ(0),
 	 Q_MTU_3_5K, Q_MTU_3_5K, TX_GPD_NUM, RX_GPD_NUM, 0},
 	{CCCI_SAP_CONTROL_TX, CCCI_SAP_CONTROL_RX, CLDMA0, TXQ(0), RXQ(0),
@@ -33,6 +37,10 @@ static const struct queue_info mtk_queue_info[] = {
 };
 
 static const struct mtk_port_cfg mtk_port_cfg_tbl[] = {
+	{CCCI_UART2_TX, CCCI_UART2_RX, PORT_TYPE_WWAN, "AT",
+		PORT_F_DFLT},
+	{CCCI_MBIM_TX, CCCI_MBIM_RX, PORT_TYPE_WWAN, "MBIM",
+		PORT_F_DFLT},
 	{CCCI_CONTROL_TX, CCCI_CONTROL_RX, PORT_TYPE_INTERNAL, "MDCTRL",
 		PORT_F_DFLT},
 	{CCCI_SAP_CONTROL_TX, CCCI_SAP_CONTROL_RX, PORT_TYPE_INTERNAL, "SAPCTRL",

-- 
2.34.1

