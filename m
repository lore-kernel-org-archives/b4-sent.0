From: Kim Wooseok <5mghybrid@khu.ac.kr>
Date: Mon, 21 Sep 2026 16:59:49 +0900
Subject: [PATCH rtw-next v4 1/3] wifi: rtl8xxxu: free RX skb when URB
 submission fails
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260921-codex-rtl-rx-v3-submit-v4-1-eeb09fe8f791@khu.ac.kr>
References: <20260921-codex-rtl-rx-v3-submit-v4-0-eeb09fe8f791@khu.ac.kr>
In-Reply-To: <20260921-codex-rtl-rx-v3-submit-v4-0-eeb09fe8f791@khu.ac.kr>
To: linux-wireless@vger.kernel.org
Cc: Ping-Ke Shih <pkshih@realtek.com>, 
 Jes Sorensen <Jes.Sorensen@gmail.com>, Kalle Valo <kvalo@kernel.org>, 
 linux-kernel@vger.kernel.org, Kim Wooseok <5mghybrid@khu.ac.kr>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789977589; l=2896;
 i=5mghybrid@khu.ac.kr; s=kernel-20260913; h=from:subject:message-id;
 bh=v2NnvT75DMsgHtN+8TES4Q5i+B5ih9gWoiLYF9i+R38=;
 b=8VMd7dtyT9w2+wCwgxaWS7lmbTf3Jcojdxl9HFw1fB9/z0tlJHw+a1Gp9GFWtfFNhEeMK/24t
 jHa6yTvjSOlCFmP+edgBVICKA41LCt173JmUnYh0I14cmb17awTb/Li
X-Developer-Key: i=5mghybrid@khu.ac.kr; a=ed25519;
 pk=1az/6lC8Tmd6BcvyarPc8FWoSxsV/WRr5NLs1v+kjlE=
X-Endpoint-Received: by B4 Relay for 5mghybrid@khu.ac.kr/kernel-20260913 with auth_id=1028
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When usb_submit_urb() fails, rtl8xxxu_submit_rx_urb() unanchors the URB
but leaves the newly allocated skb in urb.context. For ENOMEM/EAGAIN,
the RX worker puts the request back on the pending list. The next
submission allocates another skb and overwrites that pointer, leaking
the previous buffer. Stopping before the retry also leaks it, because
pending-list cleanup frees only the URB.

Free the skb and clear urb.context in rtl8xxxu_submit_rx_urb() when
submission fails. This keeps buffer allocation and failure cleanup in
the same function, so a request returned for retry or teardown no longer
owns an skb. Remove the corresponding cleanup from start and the RX
worker; they only need to decide whether to retry or free the URB.

Fixes: 26f1fad29ad9 ("New driver: rtl8xxxu (mac80211)")
Reviewed-by: Ping-Ke Shih <pkshih@realtek.com>
Assisted-by: GPT-6 Astra
Signed-off-by: Kim Wooseok <5mghybrid@khu.ac.kr>
---
 drivers/net/wireless/realtek/rtl8xxxu/core.c | 16 +++++-----------
 1 file changed, 5 insertions(+), 11 deletions(-)

diff --git a/drivers/net/wireless/realtek/rtl8xxxu/core.c b/drivers/net/wireless/realtek/rtl8xxxu/core.c
index bddbd0990de72..795a5ec2f8cd4 100644
--- a/drivers/net/wireless/realtek/rtl8xxxu/core.c
+++ b/drivers/net/wireless/realtek/rtl8xxxu/core.c
@@ -5864,7 +5864,6 @@ static void rtl8xxxu_rx_urb_work(struct work_struct *work)
 	struct rtl8xxxu_priv *priv;
 	struct rtl8xxxu_rx_urb *rx_urb, *tmp;
 	struct list_head local;
-	struct sk_buff *skb;
 	unsigned long flags;
 	int ret;
 
@@ -5896,8 +5895,6 @@ static void rtl8xxxu_rx_urb_work(struct work_struct *work)
 		default:
 			dev_warn(&priv->udev->dev,
 				 "failed to requeue urb with error %i\n", ret);
-			skb = (struct sk_buff *)rx_urb->urb.context;
-			dev_kfree_skb(skb);
 			usb_free_urb(&rx_urb->urb);
 		}
 	}
@@ -6596,8 +6593,11 @@ static int rtl8xxxu_submit_rx_urb(struct rtl8xxxu_priv *priv,
 			  skb_size, rtl8xxxu_rx_complete, skb);
 	usb_anchor_urb(&rx_urb->urb, &priv->rx_anchor);
 	ret = usb_submit_urb(&rx_urb->urb, GFP_ATOMIC);
-	if (ret)
+	if (ret) {
 		usb_unanchor_urb(&rx_urb->urb);
+		dev_kfree_skb(skb);
+		rx_urb->urb.context = NULL;
+	}
 	return ret;
 }
 
@@ -7410,7 +7410,6 @@ static int rtl8xxxu_start(struct ieee80211_hw *hw)
 	struct rtl8xxxu_priv *priv = hw->priv;
 	struct rtl8xxxu_rx_urb *rx_urb;
 	struct rtl8xxxu_tx_urb *tx_urb;
-	struct sk_buff *skb;
 	unsigned long flags;
 	int ret, i;
 
@@ -7461,13 +7460,8 @@ static int rtl8xxxu_start(struct ieee80211_hw *hw)
 		rx_urb->hw = hw;
 
 		ret = rtl8xxxu_submit_rx_urb(priv, rx_urb);
-		if (ret) {
-			if (ret != -ENOMEM) {
-				skb = (struct sk_buff *)rx_urb->urb.context;
-				dev_kfree_skb(skb);
-			}
+		if (ret)
 			rtl8xxxu_queue_rx_urb(priv, rx_urb);
-		}
 	}
 
 	schedule_delayed_work(&priv->ra_watchdog, 2 * HZ);

-- 
2.53.0

