From: Jack Wu <jackbb_wu@compal.com>
Date: Wed, 30 Sep 2026 15:46:13 +0800
Subject: [PATCH v9 6/6] net: wwan: t9xx: Add AT & MBIM WWAN ports
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260930-t9xx_driver_v1-v9-6-3248b9256956@compal.com>
References: <20260930-t9xx_driver_v1-v9-0-3248b9256956@compal.com>
In-Reply-To: <20260930-t9xx_driver_v1-v9-0-3248b9256956@compal.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790754370; l=18607;
 i=jackbb_wu@compal.com; s=20260526; h=from:subject:message-id;
 bh=Wsm5XjIyTY0HSBgc2z4hZCJCP2htulSVWx0Yv5u1uBQ=;
 b=iHEbg1mllAfoxm1nWHtF2hU2NRdxcl+tl7R2/YR1Je8oY4Jh0jFTnCJFOSnaORaBb8b2eLyTB
 a9P+4lR97cMDRKN0VzT7U79x3CECkrgTCe48PmVVLOmRU42dLwhHuym
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
fragment.

TX back-pressure is reported through wwan_port_txon()/txoff() rather
than a .tx_poll operation: a queue-full submit failure pauses the port
and a per-port tx_complete hook resumes it from TRB completion, so
poll() sleeps on the WWAN core's own waitqueue - whose lifetime is
pinned by the open file - instead of a driver waitqueue that
wwan_remove_port() can outlive.

Signed-off-by: Jack Wu <jackbb_wu@compal.com>
---
 drivers/net/wwan/t9xx/mtk_ctrl_plane.h      |   4 +
 drivers/net/wwan/t9xx/mtk_port.c            |  34 +++
 drivers/net/wwan/t9xx/mtk_port.h            |   9 +
 drivers/net/wwan/t9xx/mtk_port_io.c         | 355 ++++++++++++++++++++++++++++
 drivers/net/wwan/t9xx/mtk_port_io.h         |   1 +
 drivers/net/wwan/t9xx/pcie/mtk_trans_ctrl.c |   8 +
 6 files changed, 411 insertions(+)

diff --git a/drivers/net/wwan/t9xx/mtk_ctrl_plane.h b/drivers/net/wwan/t9xx/mtk_ctrl_plane.h
index 1f13e25502ad..2b031160eaa9 100644
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
index d7c50519e1fd..90ac551887a8 100644
--- a/drivers/net/wwan/t9xx/mtk_port.c
+++ b/drivers/net/wwan/t9xx/mtk_port.c
@@ -285,6 +285,10 @@ static int mtk_port_tx_complete(struct sk_buff *skb)
 			 "Failed to send data: status:%d, port:%s\n",
 			 trb->status, port->info.name);
 
+	/* Runs in the trb_srv kthread, so the hook may sleep on a mutex. */
+	if (ports_ops[port->info.type]->tx_complete)
+		ports_ops[port->info.type]->tx_complete(port);
+
 	wake_up_all(&port->trb_wq);
 	kref_put(&trb->kref, mtk_port_trb_free);
 
@@ -656,6 +660,29 @@ int mtk_port_ch_disable(struct mtk_port *port)
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
+			ports_ops[ports[idx]->info.type]->enable(ports[idx]);
+	}
+
+	kfree(ports);
+	return 0;
+}
+
 static void mtk_port_disable(struct mtk_port_mngr *port_mngr)
 {
 	struct radix_tree_iter iter;
@@ -677,6 +704,7 @@ static void mtk_port_disable(struct mtk_port_mngr *port_mngr)
 void mtk_port_mngr_fsm_state_handler(struct mtk_fsm_param *fsm_param, void *arg)
 {
 	struct mtk_port_mngr *port_mngr;
+	int ret;
 
 	if (!fsm_param || !arg)
 		return;
@@ -687,6 +715,12 @@ void mtk_port_mngr_fsm_state_handler(struct mtk_fsm_param *fsm_param, void *arg)
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
index 2fc0e450ab6b..acfd52792dc7 100644
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
index 6cff0704b7fc..0d8f63e2dbda 100644
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
 
 static int mtk_port_get_locked(struct mtk_port *port)
 {
@@ -41,6 +46,73 @@ static void mtk_port_struct_init(struct mtk_port *port)
 	init_waitqueue_head(&port->rx_wq);
 }
 
+/* Splits the source skb into CCCI packets and submits them.  The source may
+ * be non-linear: the WWAN core hands the tx ops a head skb whose linear area
+ * is one fragment (caps.frag_len bytes) with the rest chained on frag_list,
+ * so every read goes through skb_copy_bits(), which walks that chain and is
+ * bounded by src->len by construction.
+ *
+ * Every packet is built before any is submitted, because the core reports a
+ * partial write as a whole-write failure and userspace then re-sends the
+ * message, duplicating the prefix already on the wire.  So no packet is
+ * submitted unless all of them were built, and only the first submit may
+ * fail with -EAGAIN; the rest carry force_send, leaving only failures that
+ * mean the channel itself is going away.  -EINTR from a blocking wait
+ * arrives after the skb was submitted, so the packet counts as accepted.
+ */
+static int mtk_port_common_write(struct mtk_port *port, struct sk_buff *src, bool blocking)
+{
+	u32 packet_size, left_cnt = src->len, cur_pos;
+	struct sk_buff_head list;
+	bool force_send = false;
+	struct sk_buff *skb;
+	int ret;
+
+	ret = mtk_port_status_check(port);
+	if (ret)
+		return ret;
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
+		packet_size = min_t(u32, left_cnt,
+				    port->tx_mtu - sizeof(struct mtk_ccci_header));
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
+		ret = mtk_port_send_data(port, skb, blocking, force_send);
+		if (ret < 0 && ret != -EINTR)
+			goto err_purge;
+
+		force_send = true;
+	}
+
+	return 0;
+
+err_purge:
+	__skb_queue_purge(&list);
+	return ret;
+}
+
 static int mtk_port_internal_init(struct mtk_port *port)
 {
 	mtk_port_struct_init(port);
@@ -253,6 +325,289 @@ static const struct port_ops port_internal_ops = {
 	.recv = mtk_port_internal_recv,
 };
 
+static int mtk_port_wwan_open(struct wwan_port *w_port)
+{
+	struct mtk_port *port;
+	int ret;
+
+	port = wwan_port_get_drvdata(w_port);
+	ret = mtk_port_get_locked(port);
+	if (ret)
+		return ret;
+
+	ret = mtk_port_common_open(port);
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
+ * between that failure and the txoff below - the tx_complete that emptied
+ * it ran before this txoff and nothing later would ever resume TX - so
+ * recheck under the same lock and undo the txoff if the queue is no longer
+ * full.  An error from the recheck also resumes TX: reporting it as "not
+ * writable" would leave the poller asleep with nothing left to wake it,
+ * while the next write returns the real errno.
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
+	if (!port->w_priv.w_port)
+		goto unlock;
+
+	wwan_port_txoff(port->w_priv.w_port);
+
+	hif_cmd.rx_ch = port->info.rx_ch;
+	ret = mtk_pcie_hif_cmd_func(ctrl_blk->mdev, HIF_CTRL_CMD_CHECK_TX_FULL,
+				    &hif_cmd);
+	if (ret <= 0)
+		wwan_port_txon(port->w_priv.w_port);
+unlock:
+	mutex_unlock(&port->w_priv.w_lock);
+}
+
+/* Called from the trb_srv kthread when a TX trb for this port completes.
+ * w_lock serializes it against mtk_port_wwan_tx_pause(), closing the
+ * txoff-after-drain window described there.
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
+		ports_ops[port->info.type]->disable(port);
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
+	/* tx_mtu is only valid once the channel open trb has completed. A zero
+	 * frag_len would make wwan_port_fops_write() loop forever.
+	 */
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
+	 * port without PORT_S_ENABLE.  w_port cannot be published first - it is
+	 * this call's return value - so an RX frame arriving in between is
+	 * dropped with -ENXIO by design.
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
+static const struct port_ops port_wwan_ops = {
+	.init = mtk_port_wwan_init,
+	.exit = mtk_port_wwan_exit,
+	.enable = mtk_port_wwan_enable,
+	.disable = mtk_port_wwan_disable,
+	.recv = mtk_port_wwan_recv,
+	.tx_complete = mtk_port_wwan_tx_complete,
+};
+
 const struct port_ops *ports_ops[PORT_TYPE_MAX] = {
 	&port_internal_ops,
+	&port_wwan_ops,
 };
diff --git a/drivers/net/wwan/t9xx/mtk_port_io.h b/drivers/net/wwan/t9xx/mtk_port_io.h
index 5a4e36c075a5..88aeb28d536b 100644
--- a/drivers/net/wwan/t9xx/mtk_port_io.h
+++ b/drivers/net/wwan/t9xx/mtk_port_io.h
@@ -20,6 +20,7 @@ struct port_ops {
 	void (*enable)(struct mtk_port *port);
 	void (*disable)(struct mtk_port *port);
 	int (*recv)(struct mtk_port *port, struct sk_buff *skb);
+	void (*tx_complete)(struct mtk_port *port);
 };
 
 void *mtk_port_internal_open(struct mtk_md_dev *mdev, char *name, int flag);
diff --git a/drivers/net/wwan/t9xx/pcie/mtk_trans_ctrl.c b/drivers/net/wwan/t9xx/pcie/mtk_trans_ctrl.c
index 658189dace01..a1f1f86838f7 100644
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

