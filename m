From: Jack Wu <jackbb_wu@compal.com>
Date: Mon, 14 Sep 2026 18:31:57 +0800
Subject: [PATCH v8 6/6] net: wwan: t9xx: Add AT & MBIM WWAN ports
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260914-t9xx_driver_v1-v8-6-5206c2e6bea0@compal.com>
References: <20260914-t9xx_driver_v1-v8-0-5206c2e6bea0@compal.com>
In-Reply-To: <20260914-t9xx_driver_v1-v8-0-5206c2e6bea0@compal.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789381913; l=13723;
 i=jackbb_wu@compal.com; s=20260526; h=from:subject:message-id;
 bh=/HO3/Fa5EraejHnxqf8QC5M4oboRraeNO7gyLZd0M5M=;
 b=Gw09Jd1no8GkcQ3CnReh/XzWOcDjLKtoivFrwkFu5BodEFlYx3uwfsgHATd7YyUF6rNT7XJM0
 sp8ykgJXVqbCvDT2OuudI6Znc2gc/bxY3ddX1gG0dVCM2PTxYys6U0p
X-Developer-Key: i=jackbb_wu@compal.com; a=ed25519;
 pk=VH1prTWixNl8OEUPPSfII3p46MzJpQN8J3+ecE1tZXg=
X-Endpoint-Received: by B4 Relay for jackbb_wu@compal.com/20260526 with auth_id=793
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add AT & MBIM ports to the port infrastructure.
The WWAN initialization method is responsible for creating the
corresponding ports using the WWAN framework infrastructure. The
implemented WWAN port operations are start, stop, tx, tx_blocking
and tx_poll.
The tx path copies with skb_copy_bits(), handling the non-linear
skb the WWAN core supplies for writes larger than one fragment.

Signed-off-by: Jack Wu <jackbb_wu@compal.com>
---
 drivers/net/wwan/t9xx/mtk_ctrl_plane.h         |   4 +
 drivers/net/wwan/t9xx/mtk_port.c               |  30 +++
 drivers/net/wwan/t9xx/mtk_port.h               |   9 +
 drivers/net/wwan/t9xx/mtk_port_io.c            | 275 +++++++++++++++++++++++++
 drivers/net/wwan/t9xx/pcie/mtk_ctrl_cfg_m9xx.c |   8 +
 5 files changed, 326 insertions(+)

diff --git a/drivers/net/wwan/t9xx/mtk_ctrl_plane.h b/drivers/net/wwan/t9xx/mtk_ctrl_plane.h
index 864bca533876..92d904e28096 100644
--- a/drivers/net/wwan/t9xx/mtk_ctrl_plane.h
+++ b/drivers/net/wwan/t9xx/mtk_ctrl_plane.h
@@ -30,6 +30,10 @@ enum mtk_ccci_ch {
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
index bddb8523d120..88a0cb5fa78d 100644
--- a/drivers/net/wwan/t9xx/mtk_port.c
+++ b/drivers/net/wwan/t9xx/mtk_port.c
@@ -820,6 +820,29 @@ int mtk_port_ch_disable(struct mtk_port *port)
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
@@ -841,6 +864,7 @@ static void mtk_port_disable(struct mtk_port_mngr *port_mngr)
 void mtk_port_mngr_fsm_state_handler(struct mtk_fsm_param *fsm_param, void *arg)
 {
 	struct mtk_port_mngr *port_mngr;
+	int ret;
 
 	if (!fsm_param || !arg)
 		return;
@@ -851,6 +875,12 @@ void mtk_port_mngr_fsm_state_handler(struct mtk_fsm_param *fsm_param, void *arg)
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
index eba6b8f27559..9e8f1d4cff01 100644
--- a/drivers/net/wwan/t9xx/mtk_port.h
+++ b/drivers/net/wwan/t9xx/mtk_port.h
@@ -64,6 +64,7 @@ enum mtk_port_tbl {
 
 enum mtk_port_type {
 	PORT_TYPE_INTERNAL,
+	PORT_TYPE_WWAN,
 	PORT_TYPE_MAX
 };
 
@@ -72,6 +73,13 @@ struct mtk_internal_port {
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
@@ -101,6 +109,7 @@ struct mtk_port {
 	char dev_str[MTK_DEV_STR_LEN];
 	struct mtk_port_mngr *port_mngr;
 	struct mtk_internal_port i_priv;
+	struct mtk_wwan_port w_priv;
 };
 
 struct mtk_port_mngr {
diff --git a/drivers/net/wwan/t9xx/mtk_port_io.c b/drivers/net/wwan/t9xx/mtk_port_io.c
index 27b490fde40f..b1c1aa6009d6 100644
--- a/drivers/net/wwan/t9xx/mtk_port_io.c
+++ b/drivers/net/wwan/t9xx/mtk_port_io.c
@@ -3,6 +3,10 @@
  * Copyright (c) 2022, MediaTek Inc.
  */
 #include <linux/netdevice.h>
+#include <linux/poll.h>
+#include <linux/slab.h>
+#include <linux/wait.h>
+#include <linux/wwan.h>
 
 #include "mtk_port_io.h"
 
@@ -41,6 +45,59 @@ static void mtk_port_struct_init(struct mtk_port *port)
 	init_waitqueue_head(&port->rx_wq);
 }
 
+/* Splits the source skb into CCCI packets and submits them, all or
+ * nothing.  The source may be non-linear: the WWAN core hands the tx ops
+ * a head skb whose linear area is one fragment (caps.frag_len bytes) with
+ * the rest chained on frag_list, so every read goes through
+ * skb_copy_bits(), which walks that chain and is bounded by src->len by
+ * construction.
+ *
+ * Returns 0 or a negative errno.  Only the first packet may fail with
+ * -EAGAIN; every later packet is submitted with force_send so a message
+ * partially handed to the transaction layer cannot be truncated by a full
+ * queue.  -EINTR from a blocking wait arrives after the skb was
+ * submitted, so the packet counts as accepted and the loop continues.
+ */
+static int mtk_port_common_write(struct mtk_port *port, struct sk_buff *src, bool blocking)
+{
+	u32 packet_size, left_cnt = src->len, cur_pos;
+	bool force_send = false;
+	struct sk_buff *skb;
+	int ret;
+
+	while (left_cnt) {
+		ret = mtk_port_status_check(port);
+		if (ret)
+			return ret;
+
+		skb = __dev_alloc_skb(port->tx_mtu, GFP_KERNEL);
+		if (!skb)
+			return -ENOMEM;
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
+			return ret;
+		}
+
+		ret = mtk_port_send_data(port, skb, blocking, force_send);
+		if (ret < 0 && ret != -EINTR)
+			return ret;
+
+		left_cnt -= packet_size;
+		force_send = true;
+	}
+
+	return 0;
+}
+
 static int mtk_port_internal_init(struct mtk_port *port)
 {
 	mtk_port_struct_init(port);
@@ -242,6 +299,224 @@ static const struct port_ops port_internal_ops = {
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
+	if (ret)
+		mtk_port_put_locked(port);
+
+	return ret;
+}
+
+static void mtk_port_wwan_close(struct wwan_port *w_port)
+{
+	struct mtk_port *port = wwan_port_get_drvdata(w_port);
+
+	mtk_port_common_close(port);
+	mtk_port_put_locked(port);
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
+	if (ret < 0)
+		return ret;
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
+static __poll_t mtk_port_wwan_poll(struct wwan_port *w_port, struct file *file,
+				   struct poll_table_struct *poll)
+{
+	struct mtk_port *port = wwan_port_get_drvdata(w_port);
+	union ctrl_hif_cmd_data hif_cmd;
+	struct mtk_ctrl_blk *ctrl_blk;
+	__poll_t mask = 0;
+
+	poll_wait(file, &port->trb_wq, poll);
+	if (mtk_port_status_check(port))
+		return EPOLLERR | EPOLLHUP;
+
+	ctrl_blk = port->port_mngr->ctrl_blk;
+	hif_cmd.rx_ch = port->info.rx_ch;
+	if (!ctrl_blk->ops->send_cmd(ctrl_blk->mdev, HIF_CTRL_CMD_CHECK_TX_FULL, &hif_cmd))
+		mask |= EPOLLOUT | EPOLLWRNORM;
+
+	return mask;
+}
+
+static const struct wwan_port_ops wwan_ops = {
+	.start = mtk_port_wwan_open,
+	.stop = mtk_port_wwan_close,
+	.tx = mtk_port_wwan_write,
+	.tx_blocking = mtk_port_wwan_write_blocking,
+	.tx_poll = mtk_port_wwan_poll,
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
+	caps.frag_len = port->tx_mtu;
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
+	mutex_lock(&port->w_priv.w_lock);
+	port->w_priv.w_port = wp;
+	mutex_unlock(&port->w_priv.w_lock);
+}
+
+static void mtk_port_wwan_disable(struct mtk_port *port)
+{
+	struct wwan_port *w_port;
+
+	if (!test_and_clear_bit(PORT_S_ENABLE, &port->status))
+		return;
+
+	clear_bit(PORT_S_WR, &port->status);
+	mutex_lock(&port->w_priv.w_lock);
+	w_port = port->w_priv.w_port;
+	port->w_priv.w_port = NULL;
+	mutex_unlock(&port->w_priv.w_lock);
+
+	mtk_port_ch_disable(port);
+	wwan_remove_port(w_port);
+}
+
+static int mtk_port_wwan_recv(struct mtk_port *port, struct sk_buff *skb)
+{
+	/* Drop frames when nobody has the device open: wwan_port_rx() queues
+	 * without bound and only a reader drains the queue, so accepting
+	 * unsolicited traffic here would grow the rxq indefinitely.
+	 */
+	if (!test_bit(PORT_S_OPEN, &port->status)) {
+		dev_dbg_ratelimited(port->port_mngr->ctrl_blk->mdev->dev,
+				    "Drop RX for unopened port(%s)\n", port->info.name);
+		return -ENXIO;
+	}
+
+	mutex_lock(&port->w_priv.w_lock);
+	if (!port->w_priv.w_port) {
+		mutex_unlock(&port->w_priv.w_lock);
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
+	.reset = mtk_port_reset,
+	.enable = mtk_port_wwan_enable,
+	.disable = mtk_port_wwan_disable,
+	.recv = mtk_port_wwan_recv,
+};
+
 const struct port_ops *ports_ops[PORT_TYPE_MAX] = {
 	&port_internal_ops,
+	&port_wwan_ops,
 };
diff --git a/drivers/net/wwan/t9xx/pcie/mtk_ctrl_cfg_m9xx.c b/drivers/net/wwan/t9xx/pcie/mtk_ctrl_cfg_m9xx.c
index 050416e0b914..761a068b859b 100644
--- a/drivers/net/wwan/t9xx/pcie/mtk_ctrl_cfg_m9xx.c
+++ b/drivers/net/wwan/t9xx/pcie/mtk_ctrl_cfg_m9xx.c
@@ -16,6 +16,10 @@ static const int mtk_srv_cfg_m9xx[NR_CLDMA][HW_QUE_NUM] = {
 
 /* the number of RX GPDs should be at least two */
 static const struct queue_info mtk_queue_info_m9xx[] = {
+	{CCCI_UART2_TX, CCCI_UART2_RX, CLDMA1, TXQ(5), RXQ(5),
+	 Q_MTU_3_5K, Q_MTU_3_5K, TX_GPD_NUM, RX_GPD_NUM, Q_FRAG_3_5K, Q_FRAG_3_5K, 0},
+	{CCCI_MBIM_TX, CCCI_MBIM_RX, CLDMA1, TXQ(2), RXQ(2),
+	 Q_MTU_3_5K, Q_MTU_3_5K, TX_GPD_NUM, RX_GPD_NUM, Q_FRAG_3_5K, Q_FRAG_3_5K, 0},
 	{CCCI_CONTROL_TX, CCCI_CONTROL_RX, CLDMA1, TXQ(0), RXQ(0),
 	 Q_MTU_3_5K, Q_MTU_3_5K, TX_GPD_NUM, RX_GPD_NUM, Q_FRAG_3_5K, Q_FRAG_3_5K, 0},
 	{CCCI_SAP_CONTROL_TX, CCCI_SAP_CONTROL_RX, CLDMA0, TXQ(0), RXQ(0),
@@ -23,6 +27,10 @@ static const struct queue_info mtk_queue_info_m9xx[] = {
 };
 
 static const struct mtk_port_cfg port_cfg_m9xx[] = {
+	{CCCI_UART2_TX, CCCI_UART2_RX, PORT_TYPE_WWAN, "AT",
+		PORT_F_ALLOW_DROP},
+	{CCCI_MBIM_TX, CCCI_MBIM_RX, PORT_TYPE_WWAN, "MBIM",
+		PORT_F_ALLOW_DROP},
 	{CCCI_CONTROL_TX, CCCI_CONTROL_RX, PORT_TYPE_INTERNAL, "MDCTRL",
 		PORT_F_ALLOW_DROP},
 	{CCCI_SAP_CONTROL_TX, CCCI_SAP_CONTROL_RX, PORT_TYPE_INTERNAL, "SAPCTRL",

-- 
2.34.1

