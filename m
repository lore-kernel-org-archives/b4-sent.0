From: Christopher Griffin <christophergriffin05@gmail.com>
Date: Sun, 08 Nov 2026 16:45:30 -0600
Subject: [PATCH 2/2] wifi: ath11k: hand freed TX frames back to mac80211
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261108-ath11k-tx-airtime-v1-2-f1a02b2372d4@gmail.com>
References: <20261108-ath11k-tx-airtime-v1-0-f1a02b2372d4@gmail.com>
In-Reply-To: <20261108-ath11k-tx-airtime-v1-0-f1a02b2372d4@gmail.com>
To: Jeff Johnson <jjohnson@kernel.org>
Cc: linux-wireless@vger.kernel.org, ath11k@lists.infradead.org, 
 linux-kernel@vger.kernel.org, 
 Christopher Griffin <christophergriffin05@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794177928; l=2978;
 i=christophergriffin05@gmail.com; s=20261024; h=from:subject:message-id;
 bh=LxmAWWQQMXKfa9BFouDf1RFN1i86hWWxom/cJtre5Wc=;
 b=cNphVJyht4nkuTRgBAVpaPIEhB8Jxt69T6T6drzPgx4QO49b0n7bTI32gsZAJSQOLCoTMwTIo
 Izs1MLT8TqsC3FwonV6wpLsVF/puiiY/yt1NrD/6yXp4McP3rOLXgrW
X-Developer-Key: i=christophergriffin05@gmail.com; a=ed25519;
 pk=oa9tkTNpiGoFWdGvpDHXLSobApmsh9BfrJRJrRJAvWA=
X-Endpoint-Received: by B4 Relay for christophergriffin05@gmail.com/20261024 with auth_id=1309
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Two paths free frames that mac80211 handed to ath11k with
dev_kfree_skb_any(): ath11k_dp_tx_free_txbuf(), for TX completions the
firmware releases with REINJ or INSPECT status, and
ath11k_dp_tx_pending_cleanup(), which frees every frame still in flight
when the datapath is torn down, also during firmware crash recovery,
when mac80211 keeps its stations. mac80211 never learns what became of
those frames: one that asked for a TX status (a control port or
management frame with an ACK cookie) gets no report, and accounting
mac80211 keeps per frame, such as the pending airtime of AQL, is never
returned.

Free them with ieee80211_free_txskb(), which reports each as dropped.
In the pending cleanup do so only while ATH11K_FLAG_CRASH_FLUSH is set;
outside a recovery the hw may already be unregistered, so those frames
are freed as before.

The change, this message and the test were written with Claude, an AI
coding assistant.

Tested-on: QCN9074 hw1.0 PCI WLAN.HK.2.5.r4-00683-QCAHKSWPL_SILICONZ-1
Tested-on: IPQ8074 hw2.0 AHB WLAN.HK.2.9.0.1-02146-QCAHKSWPL_SILICONZ-1
Signed-off-by: Christopher Griffin <christophergriffin05@gmail.com>
---
 drivers/net/wireless/ath/ath11k/dp.c    | 12 +++++++++---
 drivers/net/wireless/ath/ath11k/dp_tx.c |  4 ++--
 2 files changed, 11 insertions(+), 5 deletions(-)

diff --git a/drivers/net/wireless/ath/ath11k/dp.c b/drivers/net/wireless/ath/ath11k/dp.c
index be65d73b904b6..6c2be57f3ae72 100644
--- a/drivers/net/wireless/ath/ath11k/dp.c
+++ b/drivers/net/wireless/ath/ath11k/dp.c
@@ -1013,11 +1013,17 @@ static int ath11k_dp_tx_pending_cleanup(int buf_id, void *skb, void *ctx)
 {
 	struct ath11k_base *ab = ctx;
 	struct sk_buff *msdu = skb;
+	struct ath11k_skb_cb *skb_cb = ATH11K_SKB_CB(msdu);
 
-	dma_unmap_single(ab->dev, ATH11K_SKB_CB(msdu)->paddr, msdu->len,
-			 DMA_TO_DEVICE);
+	dma_unmap_single(ab->dev, skb_cb->paddr, msdu->len, DMA_TO_DEVICE);
 
-	dev_kfree_skb_any(msdu);
+	/* In a crash recovery mac80211 keeps its stations: hand the frames
+	 * back, so that their TX status and pending airtime are reported.
+	 */
+	if (skb_cb->ar && test_bit(ATH11K_FLAG_CRASH_FLUSH, &ab->dev_flags))
+		ieee80211_free_txskb(skb_cb->ar->hw, msdu);
+	else
+		dev_kfree_skb_any(msdu);
 
 	return 0;
 }
diff --git a/drivers/net/wireless/ath/ath11k/dp_tx.c b/drivers/net/wireless/ath/ath11k/dp_tx.c
index cac970c92806a..56f474d67f72d 100644
--- a/drivers/net/wireless/ath/ath11k/dp_tx.c
+++ b/drivers/net/wireless/ath/ath11k/dp_tx.c
@@ -303,11 +303,11 @@ static void ath11k_dp_tx_free_txbuf(struct ath11k_base *ab, u8 mac_id,
 	}
 
 	skb_cb = ATH11K_SKB_CB(msdu);
+	ar = ab->pdevs[mac_id].ar;
 
 	dma_unmap_single(ab->dev, skb_cb->paddr, msdu->len, DMA_TO_DEVICE);
-	dev_kfree_skb_any(msdu);
+	ieee80211_free_txskb(ar->hw, msdu);
 
-	ar = ab->pdevs[mac_id].ar;
 	if (atomic_dec_and_test(&ar->dp.num_tx_pending))
 		wake_up(&ar->dp.tx_empty_waitq);
 }

-- 
2.43.0

