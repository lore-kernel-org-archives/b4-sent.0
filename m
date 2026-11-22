From: Ahmet Zeren <niko3x@proton.me>
Date: Sun, 22 Nov 2026 09:00:39 +0300
Subject: [PATCH rtw-next v2 2/2] wifi: rtl8xxxu: report real TX status on
 RTL8188CU/RTL8192CU
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261122-b4-tx-status-v2-2-bbfdbd880acf@proton.me>
References: <20261122-b4-tx-status-v2-0-bbfdbd880acf@proton.me>
In-Reply-To: <20261122-b4-tx-status-v2-0-bbfdbd880acf@proton.me>
To: Jes Sorensen <Jes.Sorensen@gmail.com>
Cc: linux-wireless@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Ping-Ke Shih <pkshih@realtek.com>, Ahmet Zeren <niko3x@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795327244; l=9371;
 i=niko3x@proton.me; s=20261119; h=from:subject:message-id;
 bh=sMl6jRC+pF3fcimkRsqou6eKkdQbiBUgIBwUg4wnorA=;
 b=w7TH/qhlySC2lPo5XnYQh2tpAsW6Hoe9Lx76avnYO8EeJT5XKMT91q7tqhWSlEckv/qGgbGW8
 lAoH/Qu414xBebdW0vYVsRg1sdOVlxHQ1QrwIHOIKNdZFt4xl7s5PZQ
X-Developer-Key: i=niko3x@proton.me; a=ed25519;
 pk=J4zNm2pudzQ/wF+pQ8xO+wW6jpcNa9EJ2C1g4DUAjhM=
X-Endpoint-Received: by B4 Relay for niko3x@proton.me/20261119 with auth_id=1575
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The driver reports every frame as acked once its USB transfer is done.

The firmware of these chips can send a CCX TX report with the ACK status
and retry count of a frame through the C2H event mailbox. The report
does not say which frame it is for, so request it for only one frame at
a time, poll the mailbox after the frame was sent and report its status
from there. Frames that request status while another one is pending are
reported as before.

Tested on RTL8192CU (0bda:8178) with unicast frames: frames to a present
station are reported acked, frames to an absent station are reported
failed with the retry count the hardware used, also when that takes
seconds.

Signed-off-by: Ahmet Zeren <niko3x@proton.me>
---
 drivers/net/wireless/realtek/rtl8xxxu/8192c.c    |   1 +
 drivers/net/wireless/realtek/rtl8xxxu/core.c     | 120 +++++++++++++++++++++++
 drivers/net/wireless/realtek/rtl8xxxu/regs.h     |   9 ++
 drivers/net/wireless/realtek/rtl8xxxu/rtl8xxxu.h |   6 ++
 4 files changed, 136 insertions(+)

diff --git a/drivers/net/wireless/realtek/rtl8xxxu/8192c.c b/drivers/net/wireless/realtek/rtl8xxxu/8192c.c
index 508322a8f31..e31bf16d0ee 100644
--- a/drivers/net/wireless/realtek/rtl8xxxu/8192c.c
+++ b/drivers/net/wireless/realtek/rtl8xxxu/8192c.c
@@ -722,6 +722,7 @@ struct rtl8xxxu_fileops rtl8192cu_fops = {
 	.rx_agg_buf_size = 16000,
 	.tx_desc_size = sizeof(struct rtl8xxxu_txdesc32),
 	.rx_desc_size = sizeof(struct rtl8xxxu_rxdesc16),
+	.has_c2hevt_tx_report = 1,
 	.supports_ap = 1,
 	.hw_feature_report = 0,
 	.max_macid_num = 32,
diff --git a/drivers/net/wireless/realtek/rtl8xxxu/core.c b/drivers/net/wireless/realtek/rtl8xxxu/core.c
index ab2818986cc..bbe6cae8cb8 100644
--- a/drivers/net/wireless/realtek/rtl8xxxu/core.c
+++ b/drivers/net/wireless/realtek/rtl8xxxu/core.c
@@ -5148,6 +5148,105 @@ static void rtl8xxxu_free_tx_urb(struct rtl8xxxu_priv *priv,
 	spin_unlock_irqrestore(&priv->tx_urb_lock, flags);
 }
 
+/*
+ * Gen1 chips can report the ACK status of a frame through the C2H event
+ * mailbox. There is no way to tell which frame a report belongs to, so
+ * only one frame at a time asks for one, until its report arrives. The
+ * report comes when the frame is done, which can take seconds with many
+ * retries, so wait for it rather than risk taking it for the next frame.
+ */
+#define RTL8XXXU_TX_REPORT_TIMEOUT	msecs_to_jiffies(10000)
+
+static bool rtl8xxxu_tx_report_claim(struct rtl8xxxu_priv *priv,
+				     struct sk_buff *skb)
+{
+	struct ieee80211_hdr *hdr = (struct ieee80211_hdr *)skb->data;
+	struct ieee80211_tx_info *tx_info = IEEE80211_SKB_CB(skb);
+	bool claimed = false;
+	unsigned long flags;
+
+	if (!priv->fops->has_c2hevt_tx_report ||
+	    !(tx_info->flags & IEEE80211_TX_CTL_REQ_TX_STATUS) ||
+	    (tx_info->flags & IEEE80211_TX_CTL_NO_ACK) ||
+	    is_multicast_ether_addr(hdr->addr1))
+		return false;
+
+	spin_lock_irqsave(&priv->tx_report_lock, flags);
+	if (!priv->tx_report_skb) {
+		priv->tx_report_skb = skb;
+		claimed = true;
+	}
+	spin_unlock_irqrestore(&priv->tx_report_lock, flags);
+
+	return claimed;
+}
+
+static bool rtl8xxxu_tx_report_release(struct rtl8xxxu_priv *priv,
+				       struct sk_buff *skb)
+{
+	unsigned long flags;
+	bool claimed;
+
+	spin_lock_irqsave(&priv->tx_report_lock, flags);
+	claimed = priv->tx_report_skb == skb;
+	if (claimed)
+		priv->tx_report_skb = NULL;
+	spin_unlock_irqrestore(&priv->tx_report_lock, flags);
+
+	return claimed;
+}
+
+static void rtl8xxxu_tx_report_poll_work(struct work_struct *work)
+{
+	struct rtl8xxxu_priv *priv = container_of(work, struct rtl8xxxu_priv,
+						  tx_report_poll_work.work);
+	struct ieee80211_tx_info *tx_info;
+	unsigned long flags, elapsed;
+	u8 retry = 0, status = 0;
+	bool reported = false;
+	struct sk_buff *skb;
+
+	if (rtl8xxxu_read8(priv, REG_C2HEVT_CLEAR) == C2H_EVT_FW_CLOSE) {
+		u8 id = rtl8xxxu_read8(priv, REG_C2HEVT_MSG_NORMAL);
+
+		if ((id & C2H_EVT_ID_MASK) == C2H_EVT_CCX_TX_RPT) {
+			retry = rtl8xxxu_read8(priv, REG_C2HEVT_MSG_NORMAL +
+						     C2H_EVT_CCX_RETRY_OFFSET);
+			status = rtl8xxxu_read8(priv, REG_C2HEVT_MSG_NORMAL +
+						      C2H_EVT_CCX_STATUS_OFFSET);
+			reported = true;
+		}
+		rtl8xxxu_write8(priv, REG_C2HEVT_CLEAR, C2H_EVT_HOST_CLOSE);
+	}
+
+	elapsed = jiffies - priv->tx_report_start;
+	if (!reported && elapsed < RTL8XXXU_TX_REPORT_TIMEOUT) {
+		/* Most frames are done within a few ms, poll often at first */
+		ieee80211_queue_delayed_work(priv->hw, &priv->tx_report_poll_work,
+					     elapsed < msecs_to_jiffies(20) ?
+					     1 : msecs_to_jiffies(10));
+		return;
+	}
+
+	spin_lock_irqsave(&priv->tx_report_lock, flags);
+	skb = priv->tx_report_skb;
+	priv->tx_report_skb = NULL;
+	spin_unlock_irqrestore(&priv->tx_report_lock, flags);
+
+	if (!skb)
+		return;
+
+	tx_info = IEEE80211_SKB_CB(skb);
+	ieee80211_tx_info_clear_status(tx_info);
+	if (!(tx_info->flags & IEEE80211_TX_CTL_INJECTED))
+		tx_info->status.rates[0].idx = -1;
+	tx_info->status.rates[0].count = (retry & CCX_RETRY_CNT_MASK) + 1;
+	if (status & CCX_PKT_OK)
+		tx_info->flags |= IEEE80211_TX_STAT_ACK;
+
+	ieee80211_tx_status_irqsafe(priv->hw, skb);
+}
+
 static void rtl8xxxu_tx_complete(struct urb *urb)
 {
 	struct sk_buff *skb = (struct sk_buff *)urb->context;
@@ -5163,6 +5262,16 @@ static void rtl8xxxu_tx_complete(struct urb *urb)
 
 	skb_pull(skb, priv->fops->tx_desc_size);
 
+	if (READ_ONCE(priv->tx_report_skb) == skb) {
+		if (!urb->status) {
+			priv->tx_report_start = jiffies;
+			ieee80211_queue_delayed_work(hw, &priv->tx_report_poll_work, 0);
+			rtl8xxxu_free_tx_urb(priv, tx_urb);
+			return;
+		}
+		rtl8xxxu_tx_report_release(priv, skb);
+	}
+
 	ieee80211_tx_info_clear_status(tx_info);
 	tx_info->status.rates[0].idx = -1;
 	tx_info->status.rates[0].count = 0;
@@ -5592,6 +5701,9 @@ static void rtl8xxxu_tx(struct ieee80211_hw *hw,
 	priv->fops->fill_txdesc(hw, hdr, tx_info, tx_desc, sgi, short_preamble,
 				ampdu_enable, rts_rate, macid);
 
+	if (rtl8xxxu_tx_report_claim(priv, skb))
+		tx_desc->txdw2 |= cpu_to_le32(TXDESC32_ACK_REPORT);
+
 	rtl8xxxu_calc_tx_desc_csum(tx_desc);
 
 	/* avoid zero checksum make tx hang */
@@ -5606,6 +5718,7 @@ static void rtl8xxxu_tx(struct ieee80211_hw *hw,
 	if (ret) {
 		usb_unanchor_urb(&tx_urb->urb);
 		rtl8xxxu_free_tx_urb(priv, tx_urb);
+		rtl8xxxu_tx_report_release(priv, skb);
 		goto error;
 	}
 	return;
@@ -7539,6 +7652,11 @@ static void rtl8xxxu_stop(struct ieee80211_hw *hw, bool suspend)
 
 	usb_kill_anchored_urbs(&priv->rx_anchor);
 	usb_kill_anchored_urbs(&priv->tx_anchor);
+	cancel_delayed_work_sync(&priv->tx_report_poll_work);
+	if (priv->tx_report_skb) {
+		ieee80211_free_txskb(hw, priv->tx_report_skb);
+		priv->tx_report_skb = NULL;
+	}
 	if (priv->usb_interrupts)
 		usb_kill_anchored_urbs(&priv->int_anchor);
 
@@ -7851,6 +7969,8 @@ static int rtl8xxxu_probe(struct usb_interface *interface,
 	INIT_DELAYED_WORK(&priv->rx_urb_wq, rtl8xxxu_rx_urb_work);
 	INIT_DELAYED_WORK(&priv->ra_watchdog, rtl8xxxu_watchdog_callback);
 	INIT_DELAYED_WORK(&priv->update_beacon_work, rtl8xxxu_update_beacon_work_callback);
+	spin_lock_init(&priv->tx_report_lock);
+	INIT_DELAYED_WORK(&priv->tx_report_poll_work, rtl8xxxu_tx_report_poll_work);
 	skb_queue_head_init(&priv->c2hcmd_queue);
 
 	usb_set_intfdata(interface, hw);
diff --git a/drivers/net/wireless/realtek/rtl8xxxu/regs.h b/drivers/net/wireless/realtek/rtl8xxxu/regs.h
index 2131d07c580..508f1b042b1 100644
--- a/drivers/net/wireless/realtek/rtl8xxxu/regs.h
+++ b/drivers/net/wireless/realtek/rtl8xxxu/regs.h
@@ -447,11 +447,20 @@
 /* 8188EU */
 #define REG_32K_CTRL			0x0194
 #define REG_C2HEVT_MSG_NORMAL		0x01a0
+#define  C2H_EVT_ID_MASK		GENMASK(3, 0)
+#define   C2H_EVT_CCX_TX_RPT		3
+#define  C2H_EVT_PAYLOAD_OFFSET		2
+#define  C2H_EVT_CCX_RETRY_OFFSET	(C2H_EVT_PAYLOAD_OFFSET + 0)
+#define   CCX_RETRY_CNT_MASK		GENMASK(5, 0)
+#define  C2H_EVT_CCX_STATUS_OFFSET	(C2H_EVT_PAYLOAD_OFFSET + 7)
+#define   CCX_PKT_OK			BIT(6)
 #define C2H_HW_FEATURE_REPORT		0x19
 #define C2H_HW_FEATURE_DUMP		0xfd
 /* 8192EU/8723BU/8812 */
 #define REG_C2HEVT_CMD_ID_8723B		0x01ae
 #define REG_C2HEVT_CLEAR		0x01af
+#define  C2H_EVT_HOST_CLOSE		0x00
+#define  C2H_EVT_FW_CLOSE		0xff
 #define REG_C2HEVT_MSG_TEST		0x01b8
 #define REG_MCUTST_1			0x01c0
 #define REG_FMTHR			0x01c8
diff --git a/drivers/net/wireless/realtek/rtl8xxxu/rtl8xxxu.h b/drivers/net/wireless/realtek/rtl8xxxu/rtl8xxxu.h
index 8cbadcf7190..1e20cece59e 100644
--- a/drivers/net/wireless/realtek/rtl8xxxu/rtl8xxxu.h
+++ b/drivers/net/wireless/realtek/rtl8xxxu/rtl8xxxu.h
@@ -1811,6 +1811,11 @@ struct rtl8xxxu_priv {
 	bool shutdown;
 	struct delayed_work rx_urb_wq;
 
+	spinlock_t tx_report_lock; /* protects tx_report_skb */
+	struct sk_buff *tx_report_skb;
+	unsigned long tx_report_start;
+	struct delayed_work tx_report_poll_work;
+
 	u8 mac_addr[ETH_ALEN];
 	char chip_name[8];
 	char chip_vendor[8];
@@ -2009,6 +2014,7 @@ struct rtl8xxxu_fileops {
 	char rx_desc_size;
 	u8 has_s0s1:1;
 	u8 has_tx_report:1;
+	u8 has_c2hevt_tx_report:1;
 	u8 gen2_thermal_meter:1;
 	u8 needs_full_init:1;
 	u8 init_reg_rxfltmap:1;

-- 
2.56.1

