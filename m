From: Kim Wooseok <5mghybrid@khu.ac.kr>
Date: Mon, 21 Sep 2026 16:59:50 +0900
Subject: [PATCH rtw-next v4 2/3] wifi: rtl8xxxu: unwind incomplete receive
 startup
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260921-codex-rtl-rx-v3-submit-v4-2-eeb09fe8f791@khu.ac.kr>
References: <20260921-codex-rtl-rx-v3-submit-v4-0-eeb09fe8f791@khu.ac.kr>
In-Reply-To: <20260921-codex-rtl-rx-v3-submit-v4-0-eeb09fe8f791@khu.ac.kr>
To: linux-wireless@vger.kernel.org
Cc: Ping-Ke Shih <pkshih@realtek.com>, 
 Jes Sorensen <Jes.Sorensen@gmail.com>, Kalle Valo <kvalo@kernel.org>, 
 linux-kernel@vger.kernel.org, Kim Wooseok <5mghybrid@khu.ac.kr>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789977589; l=6740;
 i=5mghybrid@khu.ac.kr; s=kernel-20260913; h=from:subject:message-id;
 bh=YdHeSuY+PK9w5uA/U1vQIeOMy/apsNeEOgCqC4q9uno=;
 b=qWXJ6SjSrLw3RDOl8pjWS/UBbFZNJaWmE4j4Aicjm2P0T4MWtaGXcGT1BL9G5Ol2GjQdwv4wv
 WVbbikfAv+JBMOYn6wXoWSqYkOVKVvrYQ+C7InGQvcNPGW8ho0LKfwx
X-Developer-Key: i=5mghybrid@khu.ac.kr; a=ed25519;
 pk=1az/6lC8Tmd6BcvyarPc8FWoSxsV/WRr5NLs1v+kjlE=
X-Endpoint-Received: by B4 Relay for 5mghybrid@khu.ac.kr/kernel-20260913 with auth_id=1028
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

rtl8xxxu_start() allocates and submits RX URBs one at a time. If a later
allocation fails, the error path frees the TX pool but leaves earlier RX
requests active. A partial TX or RX allocation failure can also leave
ret at zero, so start reports success despite the incomplete setup.

Allocate the RX pool before submitting any of it, and return ENOMEM
whenever a pool allocation fails. Pass start errors through
rtl8xxxu_stop(), including interrupt URB submission failures, so the
existing stop path cancels work and releases both active requests and
partially allocated pools.

Share the submission loop with the RX worker. Both callers keep requests
that fail with ENOMEM/EAGAIN. For a fatal error during startup, free the
rest of the unsubmitted batch and return the error so start can unwind.
In the worker, free only the failed request and continue with the rest
of the batch.

Keep the allocation loop in a small helper so the setup and error paths
in start remain easy to follow.

On an RTL8192EU, I exercised every error exit in rtl8xxxu_start()
except interrupt-URB allocation and submission failures, which this
adapter does not use.

Fixes: 26f1fad29ad9 ("New driver: rtl8xxxu (mac80211)")
Assisted-by: GPT-6 Astra
Reviewed-by: Ping-Ke Shih <pkshih@realtek.com>
Signed-off-by: Kim Wooseok <5mghybrid@khu.ac.kr>
---
 drivers/net/wireless/realtek/rtl8xxxu/core.c | 96 ++++++++++++++++------------
 1 file changed, 54 insertions(+), 42 deletions(-)

diff --git a/drivers/net/wireless/realtek/rtl8xxxu/core.c b/drivers/net/wireless/realtek/rtl8xxxu/core.c
index 795a5ec2f8cd4..5cd6498cc47f2 100644
--- a/drivers/net/wireless/realtek/rtl8xxxu/core.c
+++ b/drivers/net/wireless/realtek/rtl8xxxu/core.c
@@ -58,6 +58,7 @@ MODULE_PARM_DESC(dma_agg_pages, "Set DMA aggregation pages (range 1-127, 0 to di
 #define RTL8XXXU_TX_URB_LOW_WATER	25
 #define RTL8XXXU_TX_URB_HIGH_WATER	32
 
+static void rtl8xxxu_stop(struct ieee80211_hw *hw, bool suspend);
 static int rtl8xxxu_submit_rx_urb(struct rtl8xxxu_priv *priv,
 				  struct rtl8xxxu_rx_urb *rx_urb);
 
@@ -5832,6 +5833,28 @@ static void rtl8xxxu_free_rx_resources(struct rtl8xxxu_priv *priv)
 	spin_unlock_irqrestore(&priv->rx_urb_lock, flags);
 }
 
+static int rtl8xxxu_alloc_rx_urbs(struct rtl8xxxu_priv *priv)
+{
+	struct rtl8xxxu_rx_urb *rx_urb;
+	int i;
+
+	/* No RX work is active until the complete pool has been allocated. */
+	for (i = 0; i < RTL8XXXU_RX_URBS; i++) {
+		rx_urb = kmalloc_obj(struct rtl8xxxu_rx_urb);
+		if (!rx_urb)
+			return -ENOMEM;
+
+		usb_init_urb(&rx_urb->urb);
+		INIT_LIST_HEAD(&rx_urb->list);
+		rx_urb->hw = priv->hw;
+
+		list_add_tail(&rx_urb->list, &priv->rx_urb_pending_list);
+		priv->rx_urb_pending_count++;
+	}
+
+	return 0;
+}
+
 static void rtl8xxxu_queue_rx_urb(struct rtl8xxxu_priv *priv,
 				  struct rtl8xxxu_rx_urb *rx_urb)
 {
@@ -5859,32 +5882,21 @@ static void rtl8xxxu_queue_rx_urb(struct rtl8xxxu_priv *priv,
 	spin_unlock_irqrestore(&priv->rx_urb_lock, flags);
 }
 
-static void rtl8xxxu_rx_urb_work(struct work_struct *work)
+static int rtl8xxxu_submit_rx_urbs(struct rtl8xxxu_priv *priv, bool startup)
 {
-	struct rtl8xxxu_priv *priv;
 	struct rtl8xxxu_rx_urb *rx_urb, *tmp;
-	struct list_head local;
 	unsigned long flags;
+	LIST_HEAD(local);
 	int ret;
 
-	priv = container_of(work, struct rtl8xxxu_priv, rx_urb_wq);
-	INIT_LIST_HEAD(&local);
-
 	spin_lock_irqsave(&priv->rx_urb_lock, flags);
-
 	list_splice_init(&priv->rx_urb_pending_list, &local);
 	priv->rx_urb_pending_count = 0;
-
 	spin_unlock_irqrestore(&priv->rx_urb_lock, flags);
 
 	list_for_each_entry_safe(rx_urb, tmp, &local, list) {
 		list_del_init(&rx_urb->list);
 		ret = rtl8xxxu_submit_rx_urb(priv, rx_urb);
-		/*
-		 * If out of memory or temporary error, put it back on the
-		 * queue and try again. Otherwise the device is dead/gone
-		 * and we should drop it.
-		 */
 		switch (ret) {
 		case 0:
 			break;
@@ -5893,11 +5905,29 @@ static void rtl8xxxu_rx_urb_work(struct work_struct *work)
 			rtl8xxxu_queue_rx_urb(priv, rx_urb);
 			break;
 		default:
+			usb_free_urb(&rx_urb->urb);
+			if (startup)
+				goto free_remaining;
 			dev_warn(&priv->udev->dev,
 				 "failed to requeue urb with error %i\n", ret);
-			usb_free_urb(&rx_urb->urb);
 		}
 	}
+
+	return 0;
+
+free_remaining:
+	list_for_each_entry_safe(rx_urb, tmp, &local, list) {
+		list_del(&rx_urb->list);
+		usb_free_urb(&rx_urb->urb);
+	}
+	return ret;
+}
+
+static void rtl8xxxu_rx_urb_work(struct work_struct *work)
+{
+	struct rtl8xxxu_priv *priv = container_of(work, struct rtl8xxxu_priv, rx_urb_wq);
+
+	rtl8xxxu_submit_rx_urbs(priv, false);
 }
 
 /*
@@ -7408,7 +7438,6 @@ static void rtl8xxxu_watchdog_callback(struct work_struct *work)
 static int rtl8xxxu_start(struct ieee80211_hw *hw)
 {
 	struct rtl8xxxu_priv *priv = hw->priv;
-	struct rtl8xxxu_rx_urb *rx_urb;
 	struct rtl8xxxu_tx_urb *tx_urb;
 	unsigned long flags;
 	int ret, i;
@@ -7423,14 +7452,13 @@ static int rtl8xxxu_start(struct ieee80211_hw *hw)
 	if (priv->usb_interrupts) {
 		ret = rtl8xxxu_submit_int_urb(hw);
 		if (ret)
-			goto exit;
+			goto error_out;
 	}
 
 	for (i = 0; i < RTL8XXXU_TX_URBS; i++) {
 		tx_urb = kmalloc_obj(struct rtl8xxxu_tx_urb);
 		if (!tx_urb) {
-			if (!i)
-				ret = -ENOMEM;
+			ret = -ENOMEM;
 
 			goto error_out;
 		}
@@ -7441,31 +7469,21 @@ static int rtl8xxxu_start(struct ieee80211_hw *hw)
 		priv->tx_urb_free_count++;
 	}
 
+	ret = rtl8xxxu_alloc_rx_urbs(priv);
+	if (ret)
+		goto error_out;
+
 	priv->tx_stopped = false;
 
 	spin_lock_irqsave(&priv->rx_urb_lock, flags);
 	priv->shutdown = false;
 	spin_unlock_irqrestore(&priv->rx_urb_lock, flags);
 
-	for (i = 0; i < RTL8XXXU_RX_URBS; i++) {
-		rx_urb = kmalloc_obj(struct rtl8xxxu_rx_urb);
-		if (!rx_urb) {
-			if (!i)
-				ret = -ENOMEM;
-
-			goto error_out;
-		}
-		usb_init_urb(&rx_urb->urb);
-		INIT_LIST_HEAD(&rx_urb->list);
-		rx_urb->hw = hw;
-
-		ret = rtl8xxxu_submit_rx_urb(priv, rx_urb);
-		if (ret)
-			rtl8xxxu_queue_rx_urb(priv, rx_urb);
-	}
+	ret = rtl8xxxu_submit_rx_urbs(priv, true);
+	if (ret)
+		goto error_out;
 
 	schedule_delayed_work(&priv->ra_watchdog, 2 * HZ);
-exit:
 	/*
 	 * Accept all data and mgmt frames
 	 */
@@ -7478,13 +7496,7 @@ static int rtl8xxxu_start(struct ieee80211_hw *hw)
 	return ret;
 
 error_out:
-	rtl8xxxu_free_tx_resources(priv);
-	/*
-	 * Disable all data and mgmt frames
-	 */
-	rtl8xxxu_write16(priv, REG_RXFLTMAP2, 0x0000);
-	rtl8xxxu_write16(priv, REG_RXFLTMAP0, 0x0000);
-
+	rtl8xxxu_stop(hw, false);
 	return ret;
 }
 

-- 
2.53.0

