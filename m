From: David Heidelberg <david@ixit.cz>
Date: Tue, 20 Oct 2026 20:52:07 +0200
Subject: [PATCH v4] wifi: ath10k: make in-order rx amsdu buffers persistent
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261020-ath10k-a-msdu-v4-1-670b69d39059@ixit.cz>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3WMywrCMBBFf6VkbSQzCda48j/ERZqHHcRWkhqqp
 f9u2k1BEO7mXDhnYslH8omdqolFnylR3xVQu4rZ1nQ3z8kVZijwIGrQ3AwtiDs3/JHci1ulpVS
 +ERocK84z+kDj2rtcC7eUhj6+13zG5f1XysiBB1XrptEOEOozjTTs7YctnSw39yjkryuLawKWg
 cUAenPnef4Cv4YipuQAAAA=
X-Change-ID: 20260719-ath10k-a-msdu-c49334eb091d
To: Jeff Johnson <jjohnson@kernel.org>, 
 Johannes Berg <johannes.berg@intel.com>, 
 Kalle Valo <kvalo@qca.qualcomm.com>, 
 Michal Kazior <michal.kazior@tieto.com>
Cc: Richard Acayan <mailingradian@gmail.com>, 
 linux-wireless@vger.kernel.org, ath10k@lists.infradead.org, 
 linux-arm-msm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=8397; i=david@ixit.cz;
 h=from:subject:message-id; bh=e4K4YjSYToXwYpmvfTzP+xwda4abWoMi8YvjPXpxLNg=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBq17hXWRrK944FsnppAgJ2SH5pW7Jp1Ut+j7W03
 646u+8LrnyJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCate4VwAKCRBgAj/E00kg
 cqmIEACQCFP23uK7tlaRO5Ki26cKWFF0BbXEDIr1sreeN5f0OltJ3A86xfrJP5tXf6c0ceCsvlc
 TSeMy+oX99csAWPP9ZfMIrLQMGpgjcIph6uryUM+S659jsm3R7TDEQxIUlA71+69d4ceJPeGt3o
 jCz9taJ5XinmLtmKx9vgG/mCutkOvTACoCfuZ/g/xVBmd5Tqprs/VL0yTSSQkwSUidE4Pdnjk6q
 uKrBu+batXFbKUq1I9kXHu89JkeG6WsTXPXNyt7DLhW//twCOSVf/C6blQlv/iBItgB+BtWKazz
 ZGdpNQV0Oe31eaMsGkcvg269ad7ePvx02YoYPSZKu+ABZbaK+1b2FfRclTHUXBFGCvMKEa7BhpY
 RbpLhSxTVobW3SJnDDxf70vJB160x3VEysxlR4ZmBblRbgj5jEq8Us/zb49ZnixL7nnT2ywyYF+
 uwKGn7V6cFuQBZGyxrH0ottKsPytt19nFwjIel2QomUD7uGgwFkl3IhsF7k8pMf6cEUs0wVfsOM
 D9o0yGayqtUgdpNzudccmID3beasQwNEsEiR/U9QUTPxQLvOBMUje45vU3glmmFRK7KVuS89cOH
 173MZUzLG4MKumarKaY7lx50XNy3q42ANemEhplsP6sxTNKfZVIGvH34p4XxexNb3KkaWh+8s58
 KJoypJbjEIPsmYw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The WCN3990 might split MSDUs among multiple "in-order" indications.
The driver needs information from previous indications to handle MPDUs
that are not started by the same indications that complete them. Stash
the MSDUs of an incomplete MPDU in the driver state, together with the
peer id, tid and frag flag identifying it, and prepend them to the MSDU
list of the next indication so the MPDU can be completed instead of
being dropped and confusing the driver.

Keeping the actual buffers around is required, not just metadata: the
stashed MSDUs are the payload of the incomplete MPDU, which can only be
processed and delivered once the buffer flagged as the last MSDU
arrives. If the next indication does not continue the pending MPDU
(different peer id, tid or frag flag, or an offload indication), bail
out to recovery as before, since no firmware is known to do this. Cap
the stash at the rx ring size and bail out the same way if the last MSDU
never arrives, so a firmware that stops mid MPDU cannot grow it without
bound.

Based on effort of Richard Acayan.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
The WCN3990 firmware may split an A-MSDU across multiple HTT "in-order"
indications. Mainline drops these ("failed to extract amsdu: -11",
rx_confused, recovery), collapsing throughput under load on affected
devices. Stash the MSDUs of an incomplete MPDU in the driver state so
it can be completed by the next indication instead of being dropped.

Similar patch has been carried out-of-tree (sdm845 mainline, Comma.AI
vamOS) for a long time.

Changes in v4:
- Dropped RFC, rebased on top of next-20261016.
- Link to v3: https://patch.msgid.link/20260803-ath10k-a-msdu-v3-1-af2af21c2f19@ixit.cz

Changes in v3:
- Rework: keep the per-indication MSDU list on the stack and stash only
  the MSDUs of an incomplete MPDU between indications; processing and
  error paths are otherwise unchanged from mainline (Johannes)
- Track the frag flag of the pending MPDU and bail out to recovery if
  the continuing indication disagrees (Jeff's review agent)
- Drop the unused msdu/rxd assignments before the extract loop, a stale
  pre-v1 leftover (Richard)
- Return 0 when stashing an incomplete MPDU, waiting for the
  continuation is not an error
- Explain in the commit message why the buffers themselves must be
  kept, not just metadata (Johannes)
- Link to v2: https://lore.kernel.org/r/20260719-ath10k-a-msdu-v2-1-f479bb9d1217@ixit.cz

Changes in v2:
- checkpatch & style. (Jeff)
- Improve comments.
- Link to v1: https://lore.kernel.org/linux-wireless/20260210021249.12132-2-mailingradian@gmail.com/
---
 drivers/net/wireless/ath/ath10k/htt.h    | 10 +++++++
 drivers/net/wireless/ath/ath10k/htt_rx.c | 48 +++++++++++++++++++++++++++++++-
 2 files changed, 57 insertions(+), 1 deletion(-)

diff --git a/drivers/net/wireless/ath/ath10k/htt.h b/drivers/net/wireless/ath/ath10k/htt.h
index 25c6b2e2f81c8..0a3998bdc34fd 100644
--- a/drivers/net/wireless/ath/ath10k/htt.h
+++ b/drivers/net/wireless/ath/ath10k/htt.h
@@ -1924,16 +1924,26 @@ struct ath10k_htt {
 
 	bool tx_mem_allocated;
 	const struct ath10k_htt_tx_ops *tx_ops;
 	const struct ath10k_htt_rx_ops *rx_ops;
 	bool disable_tx_comp;
 	bool bundle_tx;
 	struct sk_buff_head tx_req_head;
 	struct sk_buff_head tx_complete_head;
+
+	/* MSDUs of an MPDU left incomplete by an in-order indication, waiting
+	 * for the next indication to continue it
+	 */
+	struct {
+		u8 tid;
+		u16 peer_id;
+		bool frag;
+		struct sk_buff_head msdus;
+	} rx_in_ord_split;
 };
 
 struct ath10k_htt_tx_ops {
 	int (*htt_send_rx_ring_cfg)(struct ath10k_htt *htt);
 	int (*htt_send_frag_desc_bank_cfg)(struct ath10k_htt *htt);
 	int (*htt_alloc_frag_desc)(struct ath10k_htt *htt);
 	void (*htt_free_frag_desc)(struct ath10k_htt *htt);
 	int (*htt_tx)(struct ath10k_htt *htt, enum ath10k_hw_txrx_mode txmode,
diff --git a/drivers/net/wireless/ath/ath10k/htt_rx.c b/drivers/net/wireless/ath/ath10k/htt_rx.c
index ab2d373b4750d..40fdde280a6f1 100644
--- a/drivers/net/wireless/ath/ath10k/htt_rx.c
+++ b/drivers/net/wireless/ath/ath10k/htt_rx.c
@@ -291,16 +291,18 @@ void ath10k_htt_rx_free(struct ath10k_htt *htt)
 		return;
 
 	timer_delete_sync(&htt->rx_ring.refill_retry_timer);
 
 	skb_queue_purge(&htt->rx_msdus_q);
 	skb_queue_purge(&htt->rx_in_ord_compl_q);
 	skb_queue_purge(&htt->tx_fetch_ind_q);
 
+	skb_queue_purge(&htt->rx_in_ord_split.msdus);
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
 
+	skb_queue_head_init(&htt->rx_in_ord_split.msdus);
+
 	ath10k_dbg(ar, ATH10K_DBG_BOOT, "htt rx ring size %d fill_level %d\n",
 		   htt->rx_ring.size, htt->rx_ring.fill_level);
 	return 0;
 
 err_dma_idx:
 	dma_free_coherent(htt->ar->dev,
 			  ath10k_htt_get_rx_ring_size(htt),
 			  vaddr_ring,
@@ -3296,16 +3300,38 @@ static int ath10k_htt_rx_in_ord_ind(struct ath10k *ar, struct sk_buff *skb)
 		ath10k_warn(ar, "dropping invalid in order rx indication\n");
 		return -EINVAL;
 	}
 
 	/* The event can deliver more than 1 A-MSDU. Each A-MSDU is later
 	 * extracted and processed.
 	 */
 	__skb_queue_head_init(&list);
+
+	if (!skb_queue_empty(&htt->rx_in_ord_split.msdus)) {
+		/* An MPDU left incomplete by a previous indication is
+		 * pending. It might still be possible to handle indications
+		 * that do not continue it if there is only one peer that
+		 * splits at each given moment. We are bailing out because we
+		 * should have a test case for this before trying to fix it.
+		 */
+		if (tid != htt->rx_in_ord_split.tid ||
+		    peer_id != htt->rx_in_ord_split.peer_id ||
+		    frag != htt->rx_in_ord_split.frag ||
+		    offload) {
+			ath10k_warn(ar, "split amsdu did not resume immediately\n");
+			htt->rx_confused = true;
+			__skb_queue_purge(&htt->rx_in_ord_split.msdus);
+			ath10k_core_start_recovery(ar);
+			return -EIO;
+		}
+
+		skb_queue_splice_init(&htt->rx_in_ord_split.msdus, &list);
+	}
+
 	if (ar->hw_params.target_64bit)
 		ret = ath10k_htt_rx_pop_paddr64_list(htt, &resp->rx_in_ord_ind,
 						     &list);
 	else
 		ret = ath10k_htt_rx_pop_paddr32_list(htt, &resp->rx_in_ord_ind,
 						     &list);
 
 	if (ret < 0) {
@@ -3334,17 +3360,37 @@ static int ath10k_htt_rx_in_ord_ind(struct ath10k *ar, struct sk_buff *skb)
 			 */
 			ath10k_htt_rx_h_ppdu(ar, &amsdu, status, vdev_id);
 			ath10k_htt_rx_h_filter(ar, &amsdu, status, NULL);
 			ath10k_htt_rx_h_mpdu(ar, &amsdu, status, false, NULL,
 					     NULL, peer_id, frag);
 			ath10k_htt_rx_h_enqueue(ar, &amsdu, status);
 			break;
 		case -EAGAIN:
-			fallthrough;
+			/* The MPDU is incomplete. Stash the remaining MSDUs
+			 * and wait for the next indication to continue it.
+			 * A last MSDU that never arrives would otherwise keep
+			 * growing the stash on every indication, so give up
+			 * once it cannot plausibly be an A-MSDU any more.
+			 */
+			if (skb_queue_len(&list) > HTT_RX_RING_SIZE) {
+				ath10k_warn(ar, "split amsdu exceeds %d msdus\n",
+					    HTT_RX_RING_SIZE);
+				htt->rx_confused = true;
+				__skb_queue_purge(&list);
+				ath10k_core_start_recovery(ar);
+				return -EIO;
+			}
+
+			htt->rx_in_ord_split.tid = tid;
+			htt->rx_in_ord_split.peer_id = peer_id;
+			htt->rx_in_ord_split.frag = frag;
+			skb_queue_splice_init(&list,
+					      &htt->rx_in_ord_split.msdus);
+			return 0;
 		default:
 			/* Should not happen. */
 			ath10k_warn(ar, "failed to extract amsdu: %d\n", ret);
 			htt->rx_confused = true;
 			__skb_queue_purge(&list);
 			ath10k_core_start_recovery(ar);
 			return -EIO;
 		}

---
base-commit: 2efb7a11f1aa4d2dc285fe2680cca22cb9f72f64
change-id: 20260719-ath10k-a-msdu-c49334eb091d

Best regards,
--  
David Heidelberg <david@ixit.cz>

