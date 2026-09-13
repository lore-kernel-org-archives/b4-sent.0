From: kimwooseok <5mghybrid@khu.ac.kr>
Date: Sun, 13 Sep 2026 16:33:21 +0900
Subject: [PATCH rtw-next v2 3/4] wifi: rtl8xxxu: preserve RX requests
 across recoverable transfer errors
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260913-codex-rtw-rx-v2-v2-3-f09c964e0b96@khu.ac.kr>
References: <20260913-codex-rtw-rx-v2-v2-0-f09c964e0b96@khu.ac.kr>
In-Reply-To: <20260913-codex-rtw-rx-v2-v2-0-f09c964e0b96@khu.ac.kr>
To: linux-wireless@vger.kernel.org
Cc: Ping-Ke Shih <pkshih@realtek.com>, 
 Jes Sorensen <Jes.Sorensen@gmail.com>, linux-kernel@vger.kernel.org, 
 kimwooseok <5mghybrid@khu.ac.kr>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789284810; l=8145;
 i=5mghybrid@khu.ac.kr; s=kernel-20260913; h=from:subject:message-id;
 bh=+/zGgRa8bRXkzCc+9fmK19RDy2tNnvAqH9wctpfXaos=;
 b=1KZzBtdRrt0SLZBVpDU88xMUgzreaWqbLsoxWty17dUB50ybOy+NvIpNYdHbXaeFkW3eq3Qr3
 dHcEcuhrXAuDgcuinN8chXDAw57mPiqLs4WprTFYVB53jINQrz1Hb5X
X-Developer-Key: i=5mghybrid@khu.ac.kr; a=ed25519;
 pk=1az/6lC8Tmd6BcvyarPc8FWoSxsV/WRr5NLs1v+kjlE=
X-Endpoint-Received: by B4 Relay for 5mghybrid@khu.ac.kr/kernel-20260913 with auth_id=1028
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

rtl8xxxu normally reuses 32 RX URBs, scheduling the submission worker when
more than eight completed requests have accumulated on the pending list.
Completion errors free URBs instead. A finite error burst can therefore
leave eight or fewer requests, which cannot reach that threshold after
they all complete. With no request in flight and no worker pending or
running, RX stays stopped even after the errors cease.

To prevent these errors from shrinking the pool below the number
needed for normal resubmission, retain URBs after EPROTO, EILSEQ, ETIME,
EOVERFLOW, ECOMM and ENOSR completions. EHCI can report ENOSR for
IN data-buffer
errors, and FHCI maps RX buffer overrun to ECOMM. Free the failed
transfer's skb and keep its URB on a separate retry list.

Keeping the URBs is only part of the fix: the driver must also submit
them again without waiting for nine requests to accumulate. When the
first failed request enters the retry list, schedule delayed work for
100 ms. Further failures join that list while the work is pending.
When it runs, move the collected requests to normal pending and schedule
the submission worker even if only one request is waiting. Keeping
failed requests separate until then prevents normal completions from
triggering an immediate retry; successful RX keeps its existing batching.

A retry can itself fail with ENOMEM/EAGAIN. Returning that request to
normal pending would bring back the same threshold problem, so route
temporary submission failures from both start and the RX worker through
the delayed retry list as well.

Serialize retry insertion and scheduling with shutdown so late
completions cannot schedule fresh retries during stop. Cancel retry work
first, then wait for submission work before killing active URBs, so a
running worker cannot submit a request after the active requests have
been drained.

Cancellation and removal keep their release behavior. EPIPE endpoint-halt
recovery remains outside this change because it requires quiescing
requests and distinguishing recovery cancellation from shutdown.

Fixes: 26f1fad29ad9 ("New driver: rtl8xxxu (mac80211)")
Assisted-by: GPT-6 Astra
Signed-off-by: kimwooseok <5mghybrid@khu.ac.kr>
---
 drivers/net/wireless/realtek/rtl8xxxu/core.c     | 71 ++++++++++++++++++++++--
 drivers/net/wireless/realtek/rtl8xxxu/rtl8xxxu.h |  3 +
 2 files changed, 70 insertions(+), 4 deletions(-)

diff --git a/drivers/net/wireless/realtek/rtl8xxxu/core.c b/drivers/net/wireless/realtek/rtl8xxxu/core.c
index 1932a9ec1970c..883c9a56f52a4 100644
--- a/drivers/net/wireless/realtek/rtl8xxxu/core.c
+++ b/drivers/net/wireless/realtek/rtl8xxxu/core.c
@@ -54,6 +54,7 @@ MODULE_PARM_DESC(dma_agg_pages, "Set DMA aggregation pages (range 1-127, 0 to di
 #define USB_VENDOR_ID_REALTEK		0x0bda
 #define RTL8XXXU_RX_URBS		32
 #define RTL8XXXU_RX_URB_PENDING_WATER	8
+#define RTL8XXXU_RX_URB_RETRY_DELAY_MS	100
 #define RTL8XXXU_TX_URBS		64
 #define RTL8XXXU_TX_URB_LOW_WATER	25
 #define RTL8XXXU_TX_URB_HIGH_WATER	32
@@ -5823,6 +5824,11 @@ static void rtl8xxxu_free_rx_resources(struct rtl8xxxu_priv *priv)
 
 	spin_lock_irqsave(&priv->rx_urb_lock, flags);
 
+	list_splice_tail_init(&priv->rx_urb_retry_list,
+			      &priv->rx_urb_pending_list);
+	priv->rx_urb_pending_count += priv->rx_urb_retry_count;
+	priv->rx_urb_retry_count = 0;
+
 	list_for_each_entry_safe(rx_urb, tmp,
 				 &priv->rx_urb_pending_list, list) {
 		list_del(&rx_urb->list);
@@ -5881,6 +5887,47 @@ static void rtl8xxxu_queue_rx_urb(struct rtl8xxxu_priv *priv,
 	spin_unlock_irqrestore(&priv->rx_urb_lock, flags);
 }
 
+static void rtl8xxxu_rx_urb_retry_work(struct work_struct *work)
+{
+	struct rtl8xxxu_priv *priv = container_of(to_delayed_work(work),
+						struct rtl8xxxu_priv,
+						rx_urb_retry_wq);
+	unsigned long flags;
+
+	spin_lock_irqsave(&priv->rx_urb_lock, flags);
+
+	if (!priv->shutdown && priv->rx_urb_retry_count) {
+		list_splice_tail_init(&priv->rx_urb_retry_list,
+				      &priv->rx_urb_pending_list);
+		priv->rx_urb_pending_count += priv->rx_urb_retry_count;
+		priv->rx_urb_retry_count = 0;
+		/* An error must not leave a small batch waiting indefinitely. */
+		schedule_work(&priv->rx_urb_wq);
+	}
+
+	spin_unlock_irqrestore(&priv->rx_urb_lock, flags);
+}
+
+static void rtl8xxxu_queue_rx_urb_retry(struct rtl8xxxu_priv *priv,
+					struct rtl8xxxu_rx_urb *rx_urb)
+{
+	unsigned long flags;
+
+	spin_lock_irqsave(&priv->rx_urb_lock, flags);
+
+	if (!priv->shutdown) {
+		list_add_tail(&rx_urb->list, &priv->rx_urb_retry_list);
+		priv->rx_urb_retry_count++;
+		/* Keep normal completions from bypassing the error backoff. */
+		queue_delayed_work(system_wq, &priv->rx_urb_retry_wq,
+				   msecs_to_jiffies(RTL8XXXU_RX_URB_RETRY_DELAY_MS));
+	} else {
+		usb_free_urb(&rx_urb->urb);
+	}
+
+	spin_unlock_irqrestore(&priv->rx_urb_lock, flags);
+}
+
 static void rtl8xxxu_rx_urb_work(struct work_struct *work)
 {
 	struct rtl8xxxu_priv *priv;
@@ -5904,7 +5951,7 @@ static void rtl8xxxu_rx_urb_work(struct work_struct *work)
 		ret = rtl8xxxu_submit_rx_urb(priv, rx_urb);
 		/*
 		 * If out of memory or temporary error, put it back on the
-		 * queue and try again. Otherwise the device is dead/gone
+		 * delayed queue and try again. Otherwise the device is dead/gone
 		 * and we should drop it.
 		 */
 		switch (ret) {
@@ -5912,7 +5959,7 @@ static void rtl8xxxu_rx_urb_work(struct work_struct *work)
 			break;
 		case -ENOMEM:
 		case -EAGAIN:
-			rtl8xxxu_queue_rx_urb(priv, rx_urb);
+			rtl8xxxu_queue_rx_urb_retry(priv, rx_urb);
 			break;
 		default:
 			dev_warn(&priv->udev->dev,
@@ -5942,7 +5989,7 @@ static int rtl8xxxu_start_rx(struct rtl8xxxu_priv *priv)
 			break;
 		case -ENOMEM:
 		case -EAGAIN:
-			rtl8xxxu_queue_rx_urb(priv, rx_urb);
+			rtl8xxxu_queue_rx_urb_retry(priv, rx_urb);
 			break;
 		default:
 			usb_free_urb(&rx_urb->urb);
@@ -6618,7 +6665,20 @@ static void rtl8xxxu_rx_complete(struct urb *urb)
 		rtl8xxxu_queue_rx_urb(priv, rx_urb);
 	} else {
 		dev_dbg(dev, "%s: status %i\n",	__func__, urb->status);
-		goto cleanup;
+		switch (urb->status) {
+		case -EPROTO:
+		case -EILSEQ:
+		case -ETIME:
+		case -EOVERFLOW:
+		case -ECOMM:
+		case -ENOSR:
+			dev_kfree_skb(skb);
+			urb->context = NULL;
+			rtl8xxxu_queue_rx_urb_retry(priv, rx_urb);
+			return;
+		default:
+			goto cleanup;
+		}
 	}
 	return;
 
@@ -7549,6 +7609,7 @@ static void rtl8xxxu_stop(struct ieee80211_hw *hw, bool suspend)
 	 * it drained via rtl8xxxu_submit_rx_urb(), so a worker still running
 	 * after the kill could submit a URB that escapes it.
 	 */
+	cancel_delayed_work_sync(&priv->rx_urb_retry_wq);
 	cancel_work_sync(&priv->rx_urb_wq);
 
 	usb_kill_anchored_urbs(&priv->rx_anchor);
@@ -7861,9 +7922,11 @@ static int rtl8xxxu_probe(struct usb_interface *interface,
 	INIT_LIST_HEAD(&priv->tx_urb_free_list);
 	spin_lock_init(&priv->tx_urb_lock);
 	INIT_LIST_HEAD(&priv->rx_urb_pending_list);
+	INIT_LIST_HEAD(&priv->rx_urb_retry_list);
 	spin_lock_init(&priv->rx_urb_lock);
 	priv->shutdown = true;
 	INIT_WORK(&priv->rx_urb_wq, rtl8xxxu_rx_urb_work);
+	INIT_DELAYED_WORK(&priv->rx_urb_retry_wq, rtl8xxxu_rx_urb_retry_work);
 	INIT_DELAYED_WORK(&priv->ra_watchdog, rtl8xxxu_watchdog_callback);
 	INIT_DELAYED_WORK(&priv->update_beacon_work, rtl8xxxu_update_beacon_work_callback);
 	skb_queue_head_init(&priv->c2hcmd_queue);
diff --git a/drivers/net/wireless/realtek/rtl8xxxu/rtl8xxxu.h b/drivers/net/wireless/realtek/rtl8xxxu/rtl8xxxu.h
index eeb18eb0e4c0f..ee55f6cc7f012 100644
--- a/drivers/net/wireless/realtek/rtl8xxxu/rtl8xxxu.h
+++ b/drivers/net/wireless/realtek/rtl8xxxu/rtl8xxxu.h
@@ -1808,8 +1808,11 @@ struct rtl8xxxu_priv {
 	spinlock_t rx_urb_lock;
 	struct list_head rx_urb_pending_list;
 	int rx_urb_pending_count;
+	struct list_head rx_urb_retry_list;
+	int rx_urb_retry_count;
 	bool shutdown;
 	struct work_struct rx_urb_wq;
+	struct delayed_work rx_urb_retry_wq;
 
 	u8 mac_addr[ETH_ALEN];
 	char chip_name[8];

-- 
2.48.1

