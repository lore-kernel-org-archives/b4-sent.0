From: Christopher Griffin <christophergriffin05@gmail.com>
Date: Wed, 04 Nov 2026 23:17:08 -0600
Subject: [PATCH ath-next] wifi: ath11k: drop the full monitor state left
 from before a monitor stop
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261104-ath11k-full-monitor-stale-hold-v1-1-10a680c3ad2f@gmail.com>
X-B4-Tracking: v=1; b=H4sIAFMR7GoC/yWNywrCMBBFf6XM2oEkfSD+irhI06kZjYlkUimU/
 ruxLg+He+4GQplJ4NJskOnDwilW0KcGnLfxTshTZTDKDFqrDm3xWj9xXkLAV4pcUkYpNhD6FCZ
 0pu3VaE03tGeokXemmdfj4Ap1i5HWAre/kWV8kCu/Puz7F0NilUWMAAAA
X-Change-ID: 20261104-ath11k-full-monitor-stale-hold-c2350ba24638
To: Jeff Johnson <jjohnson@kernel.org>, 
 Anilkumar Kolli <quic_akolli@quicinc.com>, Kalle Valo <kvalo@kernel.org>
Cc: linux-wireless@vger.kernel.org, ath11k@lists.infradead.org, 
 linux-kernel@vger.kernel.org, 
 Christopher Griffin <christophergriffin05@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793855827; l=8294;
 i=christophergriffin05@gmail.com; s=20261024; h=from:subject:message-id;
 bh=XLX7K0utKQw/gsxKboFItICJfxTeRdNiCzLnMMpwlvs=;
 b=9rxh9ZYJ9W6nXOONrK46TRxpAz7oEQ3qfJsONmBMCxlOjS3CRzK7NpUDhPAXJI/USohyHnXNH
 0IseRnpfh0TBfFMz4LBb1umhgeC56vfjVpdOtLLuGWpetqcFmdDG9SQ
X-Developer-Key: i=christophergriffin05@gmail.com; a=ed25519;
 pk=oa9tkTNpiGoFWdGvpDHXLSobApmsh9BfrJRJrRJAvWA=
X-Endpoint-Received: by B4 Relay for christophergriffin05@gmail.com/20261024 with auth_id=1309
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

In full monitor mode (QCN9074) the monitor destination ring is read
first, and the PPDU it ends on is held, together with the destination
ring, until its status buffer turns up on the monitor status ring. A
status buffer with the same PPDU ID delivers the PPDU and ends the
hold; one that reads as newer (LEAD) drops the PPDU and ends it; one
that reads as older (LAG) keeps the hold.

The hold outlives a monitor stop. While the monitor is stopped,
ath11k_dp_rx_process_mon_rings() reaps the status ring on the plain
path, so the held PPDU's status buffer is gone. When the monitor starts
again, the held PPDU ID is compared with whatever the status ring
carries after the gap, and the 16-bit compare in
ath11k_dp_rx_mon_update_status_buf_state() reads LEAD or LAG depending
on how far the PPDU counter moved meanwhile. After a long, busy stop it
reads LAG about half the time, and then the hold never ends: the
destination ring fills, the firmware reports backpressure on the
monitor destination ring, and the radio receives nothing more, scan
results included, until the driver is bound again.

Seen with a QCN9074 used as a scanning radio and lent, for about 25 s
at a time, as the station of a client test: it went deaf after 4 of 7
loans, each time with the hold set, the status ring empty (buf_state
DP_MON_STATUS_REPLINISH) and the destination ring full. The monitor
also stops and starts at each channel change of a scan, and a PPDU was
held at nearly every start (4022 of 4033).

When the monitor starts, drop the held PPDU and the destination ring
entries left behind it, and clear the hold. Also bound a hold: more
status buffers than the status ring holds cannot come before the held
PPDU's own, so drop the PPDU then rather than wait.

With this, the radio kept receiving through 13 hours of such loans,
about four an hour, and two more units through 9 and 11 hours.

Fixes: 7e2ea2e94704 ("ath11k: Process full monitor mode rx support")
Tested-on: QCN9074 hw1.0 PCI WLAN.HK.2.5.r4-00683-QCAHKSWPL_SILICONZ-1
Assisted-by: Claude:claude-opus-5-5
Signed-off-by: Christopher Griffin <christophergriffin05@gmail.com>
---
 drivers/net/wireless/ath/ath11k/dp.h    |  1 +
 drivers/net/wireless/ath/ath11k/dp_rx.c | 75 +++++++++++++++++++++++++++++++++
 drivers/net/wireless/ath/ath11k/dp_rx.h |  1 +
 drivers/net/wireless/ath/ath11k/mac.c   |  3 ++
 4 files changed, 80 insertions(+)

diff --git a/drivers/net/wireless/ath/ath11k/dp.h b/drivers/net/wireless/ath/ath11k/dp.h
index 84f66839f0c6d..0f2d278eb709d 100644
--- a/drivers/net/wireless/ath/ath11k/dp.h
+++ b/drivers/net/wireless/ath/ath11k/dp.h
@@ -162,6 +162,7 @@ struct ath11k_mon_data {
 	bool hold_mon_dst_ring;
 	enum dp_mon_status_buf_state buf_state;
 	dma_addr_t mon_status_paddr;
+	u32 hold_status_bufs;
 	struct dp_full_mon_mpdu *mon_mpdu;
 	struct hal_sw_mon_ring_entries sw_mon_entries;
 	struct ath11k_pdev_mon_stats rx_mon_stats;
diff --git a/drivers/net/wireless/ath/ath11k/dp_rx.c b/drivers/net/wireless/ath/ath11k/dp_rx.c
index 6d95f7b343a55..c941f35741167 100644
--- a/drivers/net/wireless/ath/ath11k/dp_rx.c
+++ b/drivers/net/wireless/ath/ath11k/dp_rx.c
@@ -5595,6 +5595,15 @@ ath11k_dp_rx_process_full_mon_status_ring(struct ath11k_base *ab, int mac_id,
 			   pmon->buf_state == DP_MON_STATUS_LEAD) {
 			sw_mon_entries->drop_ppdu = true;
 			pmon->hold_mon_dst_ring = false;
+		} else if (quota &&
+			   ++pmon->hold_status_bufs > DP_RXDMA_MON_STATUS_RING_SIZE) {
+			/* More status buffers than the ring holds came before
+			 * this PPDU's own: it is not coming.
+			 */
+			ath11k_dbg(ab, ATH11K_DBG_DATA, "full mon: ppdu %u held past %u status buffers, dropped\n",
+				   sw_mon_entries->ppdu_id, pmon->hold_status_bufs);
+			sw_mon_entries->drop_ppdu = true;
+			pmon->hold_mon_dst_ring = false;
 		}
 
 		if (!quota)
@@ -5672,6 +5681,7 @@ static int ath11k_dp_full_mon_process_rx(struct ath11k_base *ab, int mac_id,
 		pmon->buf_state = DP_MON_STATUS_LAG;
 		pmon->mon_status_paddr = sw_mon_entries->mon_status_paddr;
 		pmon->hold_mon_dst_ring = true;
+		pmon->hold_status_bufs = 0;
 next_entry:
 		ring_entry = ath11k_hal_srng_dst_get_next_entry(ar->ab,
 								mon_dst_srng);
@@ -5697,6 +5707,71 @@ static int ath11k_dp_full_mon_process_rx(struct ath11k_base *ab, int mac_id,
 	return quota;
 }
 
+/* Drop what full monitor mode kept from before the monitor was stopped: a
+ * PPDU held for its status buffer and the destination ring entries behind
+ * it. While the monitor is stopped the status ring is reaped on the plain
+ * path, so their status buffers are gone, and a hold that compares its
+ * PPDU ID with what the status ring carries after the gap can wait for
+ * good. The destination ring then fills and stalls the RXDMA.
+ */
+void ath11k_dp_rx_full_mon_reset(struct ath11k *ar)
+{
+	struct ath11k_base *ab = ar->ab;
+	struct ath11k_pdev_dp *dp = &ar->dp;
+	struct ath11k_mon_data *pmon = &dp->mon_data;
+	struct hal_sw_mon_ring_entries *sw_mon_entries = &pmon->sw_mon_entries;
+	struct sk_buff *head_msdu, *tail_msdu, *msdu, *next;
+	struct hal_srng *mon_dst_srng;
+	u32 rx_bufs_used = 0, entries = 0;
+	bool held;
+	u16 ppdu_id;
+	void *ring_entry;
+
+	spin_lock_bh(&pmon->mon_lock);
+
+	held = pmon->hold_mon_dst_ring;
+	ppdu_id = sw_mon_entries->ppdu_id;
+	ath11k_dp_rx_full_mon_drop_ppdu(&ab->dp, pmon->mon_mpdu);
+
+	mon_dst_srng = &ab->hal.srng_list[dp->rxdma_mon_dst_ring.ring_id];
+	spin_lock_bh(&mon_dst_srng->lock);
+	ath11k_hal_srng_access_begin(ab, mon_dst_srng);
+	while ((ring_entry = ath11k_hal_srng_dst_peek(ab, mon_dst_srng))) {
+		head_msdu = NULL;
+		tail_msdu = NULL;
+		rx_bufs_used += ath11k_dp_rx_full_mon_mpdu_pop(ar, ring_entry,
+							       &head_msdu,
+							       &tail_msdu,
+							       sw_mon_entries);
+		for (msdu = head_msdu; msdu; msdu = next) {
+			next = msdu->next;
+			dev_kfree_skb_any(msdu);
+		}
+		entries++;
+		ath11k_hal_srng_dst_get_next_entry(ab, mon_dst_srng);
+	}
+	ath11k_hal_srng_access_end(ab, mon_dst_srng);
+	spin_unlock_bh(&mon_dst_srng->lock);
+
+	pmon->hold_mon_dst_ring = false;
+	pmon->hold_status_bufs = 0;
+	pmon->mon_status_paddr = 0;
+	pmon->mon_ppdu_status = DP_PPDU_STATUS_START;
+	memset(sw_mon_entries, 0, sizeof(*sw_mon_entries));
+
+	spin_unlock_bh(&pmon->mon_lock);
+
+	if (rx_bufs_used)
+		ath11k_dp_rxbufs_replenish(ab, dp->mac_id,
+					   &dp->rxdma_mon_buf_ring,
+					   rx_bufs_used,
+					   HAL_RX_BUF_RBM_SW3_BM);
+
+	if (held || entries)
+		ath11k_dbg(ab, ATH11K_DBG_DATA, "full mon: monitor start: dropped %s ppdu %u, %u dest ring entries\n",
+			   held ? "held" : "no held", ppdu_id, entries);
+}
+
 int ath11k_dp_rx_process_mon_rings(struct ath11k_base *ab, int mac_id,
 				   struct napi_struct *napi, int budget)
 {
diff --git a/drivers/net/wireless/ath/ath11k/dp_rx.h b/drivers/net/wireless/ath/ath11k/dp_rx.h
index f69d9301e0a16..ea005537e6275 100644
--- a/drivers/net/wireless/ath/ath11k/dp_rx.h
+++ b/drivers/net/wireless/ath/ath11k/dp_rx.h
@@ -81,6 +81,7 @@ int ath11k_dp_htt_tlv_iter(struct ath11k_base *ab, const void *ptr, size_t len,
 			   int (*iter)(struct ath11k_base *ar, u16 tag, u16 len,
 				       const void *ptr, void *data),
 			   void *data);
+void ath11k_dp_rx_full_mon_reset(struct ath11k *ar);
 int ath11k_dp_rx_process_mon_rings(struct ath11k_base *ab, int mac_id,
 				   struct napi_struct *napi, int budget);
 int ath11k_dp_rx_process_mon_status(struct ath11k_base *ab, int mac_id,
diff --git a/drivers/net/wireless/ath/ath11k/mac.c b/drivers/net/wireless/ath/ath11k/mac.c
index 1a237adaa37d1..a4556d8e75cdf 100644
--- a/drivers/net/wireless/ath/ath11k/mac.c
+++ b/drivers/net/wireless/ath/ath11k/mac.c
@@ -1185,6 +1185,9 @@ static int ath11k_mac_monitor_start(struct ath11k *ar)
 		return ret;
 	}
 
+	if (ar->ab->hw_params.full_monitor_mode)
+		ath11k_dp_rx_full_mon_reset(ar);
+
 	set_bit(ATH11K_FLAG_MONITOR_STARTED, &ar->monitor_flags);
 
 	ar->num_started_vdevs++;

---
base-commit: a3ddbb45768717b5c9f923489387cf55c838d1ad
change-id: 20261104-ath11k-full-monitor-stale-hold-c2350ba24638

Best regards,
--  
Christopher Griffin <christophergriffin05@gmail.com>

