From: Jack Wu <jackbb_wu@compal.com>
Date: Wed, 14 Oct 2026 10:51:04 +0800
Subject: [PATCH v10 6/6] net: wwan: t9xx: Add AT & MBIM WWAN ports
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261014-t9xx_driver_v1-v10-6-4d0dde3613f5@compal.com>
References: <20261014-t9xx_driver_v1-v10-0-4d0dde3613f5@compal.com>
In-Reply-To: <20261014-t9xx_driver_v1-v10-0-4d0dde3613f5@compal.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791946362; l=20338;
 i=jackbb_wu@compal.com; s=20260526; h=from:subject:message-id;
 bh=iFjOU2/J/1mAsdmICl2Gi7ns2wNolsb+ST9IgA6i4Pw=;
 b=ZVRh9WtKh+fYa4Qex0WVqWMJVF18Pu2DlM/sQEb/huK0RDOg6rE7JrF0G3Vzp4QtFfeegh2hI
 Eywamigu4YcAtbu2mRuSZMLUGsHAYgNi6J4QNmxPp+zaDqx7yose2FB
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
 drivers/net/wwan/t9xx/mtk_port.c            |  37 +++
 drivers/net/wwan/t9xx/mtk_port.h            |   9 +
 drivers/net/wwan/t9xx/mtk_port_io.c         | 385 ++++++++++++++++++++++++++++
 drivers/net/wwan/t9xx/mtk_port_io.h         |   1 +
 drivers/net/wwan/t9xx/pcie/mtk_trans_ctrl.c |   8 +
 6 files changed, 444 insertions(+)

diff --git a/drivers/net/wwan/t9xx/mtk_ctrl_plane.h b/drivers/net/wwan/t9xx/mtk_ctrl_plane.h
index e2f9f8da19bc..0348872a2745 100644
--- a/drivers/net/wwan/t9xx/mtk_ctrl_plane.h
+++ b/drivers/net/wwan/t9xx/mtk_ctrl_plane.h
@@ -22,6 +22,10 @@ enum mtk_ccci_ch {
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
index 7768a4e0963f..2df2086f49ff 100644
--- a/drivers/net/wwan/t9xx/mtk_port.c
+++ b/drivers/net/wwan/t9xx/mtk_port.c
@@ -310,6 +310,13 @@ static int mtk_port_tx_complete(struct sk_buff *skb)
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
@@ -722,6 +729,29 @@ int mtk_port_ch_disable(struct mtk_port *port)
 	return ret;
 }
 
+static int mtk_port_enable_by_type(struct mtk_port_mngr *port_mngr, int tbl_type)
+{
+	struct mtk_port **ports;
+	int ret, idx;
+
+	if (tbl_type < 0 || tbl_type >= PORT_TBL_MAX)
+		return -EINVAL;
+
+	ports = kcalloc(port_mngr->port_cnt, sizeof(struct mtk_port *), GFP_KERNEL);
+	if (!ports)
+		return -ENOMEM;
+
+	ret = radix_tree_gang_lookup(&port_mngr->port_tbl[tbl_type],
+				     (void **)ports, 0, port_mngr->port_cnt);
+	for (idx = 0; idx < ret; idx++) {
+		if (ports[idx]->enable)
+			mtk_port_get_ops(ports[idx]->info.type)->enable(ports[idx]);
+	}
+
+	kfree(ports);
+	return 0;
+}
+
 static void mtk_port_disable(struct mtk_port_mngr *port_mngr)
 {
 	struct radix_tree_iter iter;
@@ -743,6 +773,7 @@ static void mtk_port_disable(struct mtk_port_mngr *port_mngr)
 void mtk_port_mngr_fsm_state_handler(struct mtk_fsm_param *fsm_param, void *arg)
 {
 	struct mtk_port_mngr *port_mngr;
+	int ret;
 
 	if (!fsm_param || !arg)
 		return;
@@ -753,6 +784,12 @@ void mtk_port_mngr_fsm_state_handler(struct mtk_fsm_param *fsm_param, void *arg)
 	case FSM_STATE_OFF:
 		mtk_port_disable(port_mngr);
 		break;
+	case FSM_STATE_READY:
+		ret = mtk_port_enable_by_type(port_mngr, PORT_TBL_MD);
+		if (ret)
+			dev_err(port_mngr->ctrl_blk->mdev->dev,
+				"Failed to enable MD ports: %d\n", ret);
+		break;
 	default:
 		break;
 	}
diff --git a/drivers/net/wwan/t9xx/mtk_port.h b/drivers/net/wwan/t9xx/mtk_port.h
index debbe523f012..a9acf2002f3a 100644
--- a/drivers/net/wwan/t9xx/mtk_port.h
+++ b/drivers/net/wwan/t9xx/mtk_port.h
@@ -55,6 +55,7 @@ enum mtk_port_tbl {
 
 enum mtk_port_type {
 	PORT_TYPE_INTERNAL,
+	PORT_TYPE_WWAN,
 	PORT_TYPE_MAX
 };
 
@@ -63,6 +64,13 @@ struct mtk_internal_port {
 	int (*recv_cb)(void *arg, struct sk_buff *skb);
 };
 
+struct mtk_wwan_port {
+	/* w_lock protects wwan_port when recv data and disable port at the same time */
+	struct mutex w_lock;
+	int w_type;
+	void *w_port;
+};
+
 struct mtk_port_cfg {
 	enum mtk_ccci_ch tx_ch;
 	enum mtk_ccci_ch rx_ch;
@@ -90,6 +98,7 @@ struct mtk_port {
 	wait_queue_head_t rx_wq;
 	struct mtk_port_mngr *port_mngr;
 	struct mtk_internal_port i_priv;
+	struct mtk_wwan_port w_priv;
 };
 
 struct mtk_port_mngr {
diff --git a/drivers/net/wwan/t9xx/mtk_port_io.c b/drivers/net/wwan/t9xx/mtk_port_io.c
index 1d6540853b04..90976a246fb3 100644
--- a/drivers/net/wwan/t9xx/mtk_port_io.c
+++ b/drivers/net/wwan/t9xx/mtk_port_io.c
@@ -3,8 +3,13 @@
  * Copyright (c) 2022, MediaTek Inc.
  */
 #include <linux/netdevice.h>
+#include <linux/poll.h>
+#include <linux/slab.h>
+#include <linux/wait.h>
+#include <linux/wwan.h>
 
 #include "mtk_port_io.h"
+#include "mtk_trans_ctrl.h"
 
 static void mtk_port_put_locked(struct mtk_port *port)
 {
@@ -23,6 +28,87 @@ static void mtk_port_struct_init(struct mtk_port *port)
 	init_waitqueue_head(&port->rx_wq);
 }
 
+/* Packets after the first carry force_send, which bypasses the HIF depth
+ * check, so one write() must not exceed one queue depth.
+ */
+#define MTK_PORT_MAX_TX_PKT	SKB_LIST_MAX_LEN
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
+	bool force_send = blocking;
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
@@ -220,8 +306,307 @@ static const struct mtk_port_ops port_internal_ops = {
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
+	if (ret > 0)
+		return;
+
+	mutex_lock(&port->w_priv.w_lock);
+	if (port->w_priv.w_port)
+		wwan_port_txon(port->w_priv.w_port);
+	mutex_unlock(&port->w_priv.w_lock);
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
+	if (!port->tx_mtu) {
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
+	/* PORT_S_WR is part of the blocking TX wait condition, and the waiter
+	 * loops back on timeout, so without this wake it only notices at the
+	 * next trb timeout rather than now.
+	 */
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
index 6e453c56a487..5932053b2614 100644
--- a/drivers/net/wwan/t9xx/mtk_port_io.h
+++ b/drivers/net/wwan/t9xx/mtk_port_io.h
@@ -20,6 +20,7 @@ struct mtk_port_ops {
 	void (*enable)(struct mtk_port *port);
 	void (*disable)(struct mtk_port *port);
 	int (*recv)(struct mtk_port *port, struct sk_buff *skb);
+	void (*tx_complete)(struct mtk_port *port);
 };
 
 const struct mtk_port_ops *mtk_port_get_ops(enum mtk_port_type type);
diff --git a/drivers/net/wwan/t9xx/pcie/mtk_trans_ctrl.c b/drivers/net/wwan/t9xx/pcie/mtk_trans_ctrl.c
index fbf3f35a3f19..dc7bbf231c8d 100644
--- a/drivers/net/wwan/t9xx/pcie/mtk_trans_ctrl.c
+++ b/drivers/net/wwan/t9xx/pcie/mtk_trans_ctrl.c
@@ -29,6 +29,10 @@ static const int mtk_srv_cfg[NR_CLDMA][HW_QUE_NUM] = {
 
 /* the number of RX GPDs should be at least two */
 static const struct queue_info mtk_queue_info[] = {
+	{CCCI_UART2_TX, CCCI_UART2_RX, CLDMA1, TXQ(5), RXQ(5),
+	 Q_MTU_3_5K, Q_MTU_3_5K, TX_GPD_NUM, RX_GPD_NUM, Q_FRAG_3_5K, Q_FRAG_3_5K, 0},
+	{CCCI_MBIM_TX, CCCI_MBIM_RX, CLDMA1, TXQ(2), RXQ(2),
+	 Q_MTU_3_5K, Q_MTU_3_5K, TX_GPD_NUM, RX_GPD_NUM, Q_FRAG_3_5K, Q_FRAG_3_5K, 0},
 	{CCCI_CONTROL_TX, CCCI_CONTROL_RX, CLDMA1, TXQ(0), RXQ(0),
 	 Q_MTU_3_5K, Q_MTU_3_5K, TX_GPD_NUM, RX_GPD_NUM, Q_FRAG_3_5K, Q_FRAG_3_5K, 0},
 	{CCCI_SAP_CONTROL_TX, CCCI_SAP_CONTROL_RX, CLDMA0, TXQ(0), RXQ(0),
@@ -36,6 +40,10 @@ static const struct queue_info mtk_queue_info[] = {
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

