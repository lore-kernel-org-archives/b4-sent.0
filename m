From: David Heidelberg <david@ixit.cz>
Date: Sun, 19 Jul 2026 23:45:05 +0200
Subject: [PATCH RFC v2] wifi: ath10k: make in-order rx amsdu buffers
 persistent
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260719-ath10k-a-msdu-v2-1-f479bb9d1217@ixit.cz>
X-B4-Tracking: v=1; b=H4sIAGBFXWoC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyjHQUlJIzE
 vPSU3UzU4B8JSMDIzMDc0NL3cSSDEODbN1E3dzilFLdZBNLY2OT1CQDS8MUJaCegqLUtMwKsHn
 RSkFuzkqxtbUASGkunmQAAAA=
X-Change-ID: 20260719-ath10k-a-msdu-c49334eb091d
To: Jeff Johnson <jjohnson@kernel.org>, 
 Johannes Berg <johannes.berg@intel.com>, 
 Kalle Valo <kvalo@qca.qualcomm.com>, 
 Michal Kazior <michal.kazior@tieto.com>
Cc: linux-wireless@vger.kernel.org, ath10k@lists.infradead.org, 
 linux-arm-msm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, Richard Acayan <mailingradian@gmail.com>, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=8018; i=david@ixit.cz;
 h=from:subject:message-id; bh=eJO73j6StWvYoT6k/tDaKaIZy8rPtLgZblz2V5IMI5w=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqXUVqGCRYP+kPct4/I2100bua9kIokiDzlCmsh
 Is1Hny2IVSJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCal1FagAKCRBgAj/E00kg
 clEpD/9nZOZRFFop8rj3IcW7WAwZGdTRjwGyv2KtHSpDFMsr0PrHD0lyP0m2iU3FMDMyO1JL/hO
 5zmtvaE/dSMLMJ32Hu1Enf2cP6wIMYiEieADJGj9qDArxxDv0sUhTPz1h4n4mpVQThW8sLBPVok
 GnnDtAAp5x+Bxx6kP3h+RU+rQyxdzoMYz0nas7W3hcS05ch6e04MJuLlfEvHDy3WzDoM1DQT8W7
 qX7lEDuNx7fo74LWvh8vMJJae8eC0ig2cuCq9aXR4hjYZXtXOvdZRqBNvVANkZEJXLDSng0WV4M
 KkfQmagU51s9YjR9iZq+YN88bbsM9A3oehzOFmRcVynspSM3At0TJvNN5O7OPtec1eibU/4L6BX
 Kv+oJ//9lAprcfOpSJwRyOajeW+K8dN27tCOcjmW2qCrQmX3zXu23EmomF0gxL8Tjn01M6KdVoU
 n0VI57tB7DwOPcmit9CtdxWFCJ1aujywefrCEPQRbPqWIh9tigQeD/Opc7So0oxw63ADxptLfR3
 0A3zwheiUCO0F+T08MF4jP6sKzVOxgSRUUwhFJMue1c06szlQO2e95sOd6xUri1fBUqql2yt/iL
 rssawXoe9hnrnQi8Sf5LXfhAxW4TYN5MLRluNE8D5x9By0e9Dbd0wJhXbhzuD7ospFdMqUFxd0x
 dzHns4MoZKJZlHQ==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Richard Acayan <mailingradian@gmail.com>

The WCN3990 might split MSDUs among multiple "in-order" indications. The
driver needs information from previous indications to handle MPDUs that
are not started by the same indications that complete them. Move the
list that tracks unprocessed MSDUs to the driver state so the driver can
handle MPDUs that are split in this way and be less confused.

Fixes: c545070e404b ("ath10k: implement rx reorder support")
Signed-off-by: Richard Acayan <mailingradian@gmail.com>
Co-developed-by: David Heidelberg <david@ixit.cz>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
This one we have in-tree forever.

Changes in v2:
- checkpatch & style. (Jeff)
- Improve comments.
- Link to v1: https://lore.kernel.org/linux-wireless/20260210021249.12132-2-mailingradian@gmail.com/
---
 drivers/net/wireless/ath/ath10k/htt.h    |  4 +++
 drivers/net/wireless/ath/ath10k/htt_rx.c | 50 +++++++++++++++++++++++++-------
 2 files changed, 43 insertions(+), 11 deletions(-)

diff --git a/drivers/net/wireless/ath/ath10k/htt.h b/drivers/net/wireless/ath/ath10k/htt.h
index 25c6b2e2f81c8..07c3dc088f07b 100644
--- a/drivers/net/wireless/ath/ath10k/htt.h
+++ b/drivers/net/wireless/ath/ath10k/htt.h
@@ -1924,16 +1924,20 @@ struct ath10k_htt {
 
 	bool tx_mem_allocated;
 	const struct ath10k_htt_tx_ops *tx_ops;
 	const struct ath10k_htt_rx_ops *rx_ops;
 	bool disable_tx_comp;
 	bool bundle_tx;
 	struct sk_buff_head tx_req_head;
 	struct sk_buff_head tx_complete_head;
+
+	u8 rx_in_ord_split_tid;
+	u16 rx_in_ord_split_peer_id;
+	struct sk_buff_head rx_in_ord_split;
 };
 
 struct ath10k_htt_tx_ops {
 	int (*htt_send_rx_ring_cfg)(struct ath10k_htt *htt);
 	int (*htt_send_frag_desc_bank_cfg)(struct ath10k_htt *htt);
 	int (*htt_alloc_frag_desc)(struct ath10k_htt *htt);
 	void (*htt_free_frag_desc)(struct ath10k_htt *htt);
 	int (*htt_tx)(struct ath10k_htt *htt, enum ath10k_hw_txrx_mode txmode,
diff --git a/drivers/net/wireless/ath/ath10k/htt_rx.c b/drivers/net/wireless/ath/ath10k/htt_rx.c
index ab2d373b4750d..732bd3a2f9992 100644
--- a/drivers/net/wireless/ath/ath10k/htt_rx.c
+++ b/drivers/net/wireless/ath/ath10k/htt_rx.c
@@ -291,16 +291,18 @@ void ath10k_htt_rx_free(struct ath10k_htt *htt)
 		return;
 
 	timer_delete_sync(&htt->rx_ring.refill_retry_timer);
 
 	skb_queue_purge(&htt->rx_msdus_q);
 	skb_queue_purge(&htt->rx_in_ord_compl_q);
 	skb_queue_purge(&htt->tx_fetch_ind_q);
 
+	skb_queue_purge(&htt->rx_in_ord_split);
+
 	spin_lock_bh(&htt->rx_ring.lock);
 	ath10k_htt_rx_ring_free(htt);
 	spin_unlock_bh(&htt->rx_ring.lock);
 
 	dma_free_coherent(htt->ar->dev,
 			  ath10k_htt_get_rx_ring_size(htt),
 			  ath10k_htt_get_vaddr_ring(htt),
 			  htt->rx_ring.base_paddr);
@@ -841,16 +843,18 @@ int ath10k_htt_rx_alloc(struct ath10k_htt *htt)
 	htt->rx_ring.sw_rd_idx.msdu_payld = 0;
 	hash_init(htt->rx_ring.skb_table);
 
 	skb_queue_head_init(&htt->rx_msdus_q);
 	skb_queue_head_init(&htt->rx_in_ord_compl_q);
 	skb_queue_head_init(&htt->tx_fetch_ind_q);
 	atomic_set(&htt->num_mpdus_ready, 0);
 
+	skb_queue_head_init(&htt->rx_in_ord_split);
+
 	ath10k_dbg(ar, ATH10K_DBG_BOOT, "htt rx ring size %d fill_level %d\n",
 		   htt->rx_ring.size, htt->rx_ring.fill_level);
 	return 0;
 
 err_dma_idx:
 	dma_free_coherent(htt->ar->dev,
 			  ath10k_htt_get_rx_ring_size(htt),
 			  vaddr_ring,
@@ -3156,16 +3160,20 @@ static int ath10k_htt_rx_extract_amsdu(struct ath10k_hw_params *hw,
 	struct rx_msdu_end_common *rxd_msdu_end_common;
 
 	if (skb_queue_empty(list))
 		return -ENOBUFS;
 
 	if (WARN_ON(!skb_queue_empty(amsdu)))
 		return -EINVAL;
 
+	msdu = skb_peek(list);
+	rxd = HTT_RX_BUF_TO_RX_DESC(hw,
+				    (void *)msdu->data - hw->rx_desc_ops->rx_desc_size);
+
 	while ((msdu = __skb_dequeue(list))) {
 		__skb_queue_tail(amsdu, msdu);
 
 		rxd = HTT_RX_BUF_TO_RX_DESC(hw,
 					    (void *)msdu->data -
 					    hw->rx_desc_ops->rx_desc_size);
 
 		rxd_msdu_end_common = ath10k_htt_rx_desc_get_msdu_end(hw, rxd);
@@ -3257,17 +3265,16 @@ static void ath10k_htt_rx_h_rx_offload(struct ath10k *ar,
 	}
 }
 
 static int ath10k_htt_rx_in_ord_ind(struct ath10k *ar, struct sk_buff *skb)
 {
 	struct ath10k_htt *htt = &ar->htt;
 	struct htt_resp *resp = (void *)skb->data;
 	struct ieee80211_rx_status *status = &htt->rx_status;
-	struct sk_buff_head list;
 	struct sk_buff_head amsdu;
 	u16 peer_id;
 	u16 msdu_count;
 	u8 vdev_id;
 	u8 tid;
 	bool offload;
 	bool frag;
 	int ret;
@@ -3292,64 +3299,85 @@ static int ath10k_htt_rx_in_ord_ind(struct ath10k *ar, struct sk_buff *skb)
 		   "htt rx in ord vdev %i peer %i tid %i offload %i frag %i msdu count %i\n",
 		   vdev_id, peer_id, tid, offload, frag, msdu_count);
 
 	if (skb->len < msdu_count * sizeof(*resp->rx_in_ord_ind.msdu_descs32)) {
 		ath10k_warn(ar, "dropping invalid in order rx indication\n");
 		return -EINVAL;
 	}
 
-	/* The event can deliver more than 1 A-MSDU. Each A-MSDU is later
-	 * extracted and processed.
+	if (!skb_queue_empty(&htt->rx_in_ord_split)) {
+		/*
+		 * It might still be possible to handle this case if there is
+		 * only one peer that splits at each given moment. We are
+		 * bailing out because we should have a test case for this
+		 * before trying to fix it.
+		 */
+		if (tid != htt->rx_in_ord_split_tid ||
+		    peer_id != htt->rx_in_ord_split_peer_id ||
+		    offload) {
+			ath10k_warn(ar, "split amsdu did not resume immediately\n");
+			htt->rx_confused = true;
+			ath10k_core_start_recovery(ar);
+			return -EIO;
+		}
+	}
+
+	/*
+	 * The event can deliver more than 1 A-MSDU or continue a previous one.
+	 * Each A-MSDU is later extracted and processed.
 	 */
-	__skb_queue_head_init(&list);
 	if (ar->hw_params.target_64bit)
 		ret = ath10k_htt_rx_pop_paddr64_list(htt, &resp->rx_in_ord_ind,
-						     &list);
+						     &htt->rx_in_ord_split);
 	else
 		ret = ath10k_htt_rx_pop_paddr32_list(htt, &resp->rx_in_ord_ind,
-						     &list);
+						     &htt->rx_in_ord_split);
 
 	if (ret < 0) {
 		ath10k_warn(ar, "failed to pop paddr list: %d\n", ret);
 		htt->rx_confused = true;
 		ath10k_core_start_recovery(ar);
 		return -EIO;
 	}
 
 	/* Offloaded frames are very different and need to be handled
 	 * separately.
 	 */
 	if (offload)
-		ath10k_htt_rx_h_rx_offload(ar, &list);
+		ath10k_htt_rx_h_rx_offload(ar, &htt->rx_in_ord_split);
 
-	while (!skb_queue_empty(&list)) {
+	while (!skb_queue_empty(&htt->rx_in_ord_split)) {
 		__skb_queue_head_init(&amsdu);
-		ret = ath10k_htt_rx_extract_amsdu(&ar->hw_params, &list, &amsdu);
+		ret = ath10k_htt_rx_extract_amsdu(&ar->hw_params,
+						  &htt->rx_in_ord_split, &amsdu);
 		switch (ret) {
 		case 0:
 			/* Note: The in-order indication may report interleaved
 			 * frames from different PPDUs meaning reported rx rate
 			 * to mac80211 isn't accurate/reliable. It's still
 			 * better to report something than nothing though. This
 			 * should still give an idea about rx rate to the user.
 			 */
 			ath10k_htt_rx_h_ppdu(ar, &amsdu, status, vdev_id);
 			ath10k_htt_rx_h_filter(ar, &amsdu, status, NULL);
 			ath10k_htt_rx_h_mpdu(ar, &amsdu, status, false, NULL,
 					     NULL, peer_id, frag);
 			ath10k_htt_rx_h_enqueue(ar, &amsdu, status);
 			break;
 		case -EAGAIN:
-			fallthrough;
+			htt->rx_in_ord_split_tid = tid;
+			htt->rx_in_ord_split_peer_id = peer_id;
+
+			return -EIO;
 		default:
 			/* Should not happen. */
 			ath10k_warn(ar, "failed to extract amsdu: %d\n", ret);
 			htt->rx_confused = true;
-			__skb_queue_purge(&list);
+			__skb_queue_purge(&htt->rx_in_ord_split);
 			ath10k_core_start_recovery(ar);
 			return -EIO;
 		}
 	}
 	return ret;
 }
 
 static void ath10k_htt_rx_tx_fetch_resp_id_confirm(struct ath10k *ar,

---
base-commit: 0718283ab28bc3907e10b61a6b4be6fefa1cbb2f
change-id: 20260719-ath10k-a-msdu-c49334eb091d

Best regards,
-- 
David Heidelberg <david@ixit.cz>

