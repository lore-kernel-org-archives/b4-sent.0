From: Ahmet Zeren <niko3x@proton.me>
Date: Fri, 20 Nov 2026 01:12:46 +0300
Subject: [PATCH rtw-next 2/2] wifi: rtl8xxxu: report real TX status on
 RTL8188CU/RTL8192CU
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261120-b4-tx-status-v1-2-abdab21c77fe@proton.me>
References: <20261120-b4-tx-status-v1-0-abdab21c77fe@proton.me>
In-Reply-To: <20261120-b4-tx-status-v1-0-abdab21c77fe@proton.me>
To: Jes Sorensen <Jes.Sorensen@gmail.com>
Cc: linux-wireless@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Ping-Ke Shih <pkshih@realtek.com>, Ahmet Zeren <niko3x@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795126366; l=9009;
 i=niko3x@proton.me; s=20261119; h=from:subject:message-id;
 bh=cVISrP+Uyjzjul4j5LOPb1r80goTg86Mlkz+Z8jbjZ4=;
 b=4cH/LoGH/cz408MiSGXEcopPUX6nNCX0DDdCEGvxOxEZpVaKMsK5HA7RMhjuaZTafLUvVih63
 g1ohAruVgKPD66os0gJe2j5KV0SQsCw6RuOBGGkfIboKkHRCg2+L+5D
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
 drivers/net/wireless/realtek/rtl8xxxu/rtl8xxxu.h |  17 ++++
 3 files changed, 138 insertions(+)

diff --git a/drivers/net/wireless/realtek/rtl8xxxu/8192c.c b/drivers/net/wireless/realtek/rtl8xxxu/8192c.c
index 508322a8f3..401cc1f6da 100644
--- a/drivers/net/wireless/realtek/rtl8xxxu/8192c.c
+++ b/drivers/net/wireless/realtek/rtl8xxxu/8192c.c
@@ -726,6 +726,7 @@ struct rtl8xxxu_fileops rtl8192cu_fops = {
 	.hw_feature_report = 0,
 	.max_macid_num = 32,
 	.max_sec_cam_num = 32,
+	.has_c2hevt_tx_report = 1,
 	.adda_1t_init = 0x0b1b25a0,
 	.adda_1t_path_on = 0x0bdb25a0,
 	.adda_2t_path_on_a = 0x04db25a4,
diff --git a/drivers/net/wireless/realtek/rtl8xxxu/core.c b/drivers/net/wireless/realtek/rtl8xxxu/core.c
index ab2818986c..36f0a266af 100644
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
+	struct ieee80211_tx_info *tx_info = IEEE80211_SKB_CB(skb);
+	struct ieee80211_hdr *hdr = (struct ieee80211_hdr *)skb->data;
+	unsigned long flags;
+	bool claimed = false;
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
+static void rtl8xxxu_tx_report_work(struct work_struct *work)
+{
+	struct rtl8xxxu_priv *priv = container_of(work, struct rtl8xxxu_priv,
+						  tx_report_work.work);
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
+			retry = rtl8xxxu_read8(priv, REG_C2HEVT_MSG_NORMAL + 2 +
+						     CCX_TX_RPT_RETRY);
+			status = rtl8xxxu_read8(priv, REG_C2HEVT_MSG_NORMAL + 2 +
+						      CCX_TX_RPT_STATUS);
+			reported = true;
+		}
+		rtl8xxxu_write8(priv, REG_C2HEVT_CLEAR, C2H_EVT_HOST_CLOSE);
+	}
+
+	elapsed = jiffies - priv->tx_report_start;
+	if (!reported && elapsed < RTL8XXXU_TX_REPORT_TIMEOUT) {
+		/* Most frames are done within a few ms, poll often at first */
+		ieee80211_queue_delayed_work(priv->hw, &priv->tx_report_work,
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
+	tx_info->status.rates[0].count = (retry & CCX_TX_RPT_RETRY_CNT) + 1;
+	if (status & CCX_TX_RPT_PKT_OK)
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
+			ieee80211_queue_delayed_work(hw, &priv->tx_report_work, 0);
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
+	cancel_delayed_work_sync(&priv->tx_report_work);
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
+	INIT_DELAYED_WORK(&priv->tx_report_work, rtl8xxxu_tx_report_work);
 	skb_queue_head_init(&priv->c2hcmd_queue);
 
 	usb_set_intfdata(interface, hw);
diff --git a/drivers/net/wireless/realtek/rtl8xxxu/rtl8xxxu.h b/drivers/net/wireless/realtek/rtl8xxxu/rtl8xxxu.h
index 8cbadcf719..387ffdc970 100644
--- a/drivers/net/wireless/realtek/rtl8xxxu/rtl8xxxu.h
+++ b/drivers/net/wireless/realtek/rtl8xxxu/rtl8xxxu.h
@@ -1546,6 +1546,17 @@ enum c2h_evt_8723b {
 	C2H_8723B_FW_DEBUG = 0xff,
 };
 
+/* Gen1 C2H events are read from the REG_C2HEVT_MSG_NORMAL mailbox */
+#define C2H_EVT_HOST_CLOSE		0x00
+#define C2H_EVT_FW_CLOSE		0xff
+#define C2H_EVT_ID_MASK			GENMASK(3, 0)
+#define C2H_EVT_CCX_TX_RPT		3
+/* Offsets in the CCX TX report payload, after the 2 byte event header */
+#define CCX_TX_RPT_RETRY		0
+#define  CCX_TX_RPT_RETRY_CNT		GENMASK(5, 0)
+#define CCX_TX_RPT_STATUS		7
+#define  CCX_TX_RPT_PKT_OK		BIT(6)
+
 enum bt_info_src_8723b {
 	BT_INFO_SRC_8723B_WIFI_FW = 0x0,
         BT_INFO_SRC_8723B_BT_RSP = 0x1,
@@ -1919,6 +1930,11 @@ struct rtl8xxxu_priv {
 	struct work_struct c2hcmd_work;
 	struct sk_buff_head c2hcmd_queue;
 	struct delayed_work update_beacon_work;
+	/* Frame waiting for its TX report in the C2H event mailbox */
+	struct sk_buff *tx_report_skb;
+	spinlock_t tx_report_lock; /* protects tx_report_skb */
+	struct delayed_work tx_report_work;
+	unsigned long tx_report_start;
 	struct rtl8xxxu_btcoex bt_coex;
 	struct rtl8xxxu_ra_report ra_report;
 	struct rtl8xxxu_cfo_tracking cfo_tracking;
@@ -2009,6 +2025,7 @@ struct rtl8xxxu_fileops {
 	char rx_desc_size;
 	u8 has_s0s1:1;
 	u8 has_tx_report:1;
+	u8 has_c2hevt_tx_report:1;
 	u8 gen2_thermal_meter:1;
 	u8 needs_full_init:1;
 	u8 init_reg_rxfltmap:1;

-- 
2.56.1

