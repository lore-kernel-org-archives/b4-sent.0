From: Christopher Griffin <christophergriffin05@gmail.com>
Date: Fri, 06 Nov 2026 08:24:58 -0600
Subject: [PATCH] wifi: ath11k: don't report firmware-dropped TX frames as
 failed
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261106-ath11k-tqm-internal-drops-v1-1-8ddcb8105dd0@gmail.com>
X-B4-Tracking: v=1; b=H4sIADnj7WoC/yXMTQ6CQAxA4auQrm0yJWQwXsW4GIYi9WfAdjQkh
 Lsz6vJbvLeCsQobnKoVlD9iMqUCOlQQx5CujNIXQ+1qT+Q8hjwS3TG/nigps6bwwF6n2bBpWzf
 4SNwcGUo/Kw+y/N7ny9/27m4c83cI27YDBZaJd30AAAA=
X-Change-ID: 20261106-ath11k-tqm-internal-drops-4770f6c1e48e
To: Jeff Johnson <jjohnson@kernel.org>, Kalle Valo <kvalo@kernel.org>, 
 Baochen Qiang <baochen.qiang@oss.qualcomm.com>
Cc: linux-wireless@vger.kernel.org, ath11k@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Jeff Johnson <jeff.johnson@oss.qualcomm.com>, 
 Christopher Griffin <christophergriffin05@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793975097; l=4659;
 i=christophergriffin05@gmail.com; s=20261024; h=from:subject:message-id;
 bh=hpLRVZ36gLFspO6IkI74GMS59/eWb8aH9xvagx/E5BQ=;
 b=zQgBkzn3jUFZ+Gqll6XIBgxBC4bxFiQeW+Yw7v/XMoV4q2ke64QGBxiQ8T+3QoFifJPfW7Z7h
 JI28Y4pqEkIBBb0m6vrdjFFfMJIxNQHfLmfkgbZ4ZB27qqKaSWODLTk
X-Developer-Key: i=christophergriffin05@gmail.com; a=ed25519;
 pk=oa9tkTNpiGoFWdGvpDHXLSobApmsh9BfrJRJrRJAvWA=
X-Endpoint-Received: by B4 Relay for christophergriffin05@gmail.com/20261024 with auth_id=1309
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When the firmware drops a frame from its TX queue without sending it,
the TX completion carries a TQM release reason other than FRAME_ACKED,
and ath11k_dp_tx_complete_msdu() reports it to mac80211 as an unacked
frame. mac80211 then counts it as a failed transmission: the station's
tx_failed and the mesh path metric's failure average go up although
nothing was lost on the air. With extended TX stats enabled, such a
completion also overwrites the station's TX rate with the empty rate
fields of the completion.

On an IPQ8074 AP, three 30 s UDP downloads offered at 650 Mbit/s into a
40 MHz HE link that carries about 400 Mbit/s raised the station's
tx_failed by 659146, 826963 and 1020775, matching the datagrams iperf
lost, while the firmware's PPDU statistics counted no failed MPDU. Every
one of those completions carried HAL_WBM_TQM_REL_REASON_CMD_REMOVE_MPDU.

Handle the release reasons the way ath12k does since
commit 50971dc6694c ("wifi: ath12k: drop failed transmitted frames from metric calculation.")
and free the frames the firmware removed itself (CMD_REMOVE_MPDU,
CMD_REMOVE_AGED_FRAMES, and CMD_REMOVE_TX of a frame that expected an
ACK) with ieee80211_free_txskb() instead of reporting a TX status,
before the extended TX stats are updated. With the change, three runs
of the same download left tx_failed unchanged; TCP and UDP throughput
stayed within the run-to-run spread of the runs without it.

Tested-on: IPQ8074 hw2.0 AHB WLAN.HK.2.9.0.1-02146-QCAHKSWPL_SILICONZ-1

Fixes: d5c65159f289 ("ath11k: driver for Qualcomm IEEE 802.11ax devices")
Assisted-by: Claude:claude-opus-5-5
Signed-off-by: Christopher Griffin <christophergriffin05@gmail.com>
---
ath12k stopped reporting the firmware's own TX drops as failed
transmissions in 2024; ath11k still does. Found on an Arista C-360
(IPQ8074) while comparing the firmware's per-MCS TX statistics with the
station's tx_failed under an overloaded UDP download: the firmware
counted no failed MPDU while tx_failed matched the datagrams iperf lost.
---
 drivers/net/wireless/ath/ath11k/dp_tx.c | 41 +++++++++++++++++++++++----------
 1 file changed, 29 insertions(+), 12 deletions(-)

diff --git a/drivers/net/wireless/ath/ath11k/dp_tx.c b/drivers/net/wireless/ath/ath11k/dp_tx.c
index cac970c92806a..8f619d89ec100 100644
--- a/drivers/net/wireless/ath/ath11k/dp_tx.c
+++ b/drivers/net/wireless/ath/ath11k/dp_tx.c
@@ -586,22 +586,39 @@ static void ath11k_dp_tx_complete_msdu(struct ath11k *ar,
 	/* skip tx rate update from ieee80211_status*/
 	info->status.rates[0].idx = -1;
 
-	if (ts->status == HAL_WBM_TQM_REL_REASON_FRAME_ACKED &&
-	    !(info->flags & IEEE80211_TX_CTL_NO_ACK)) {
-		info->flags |= IEEE80211_TX_STAT_ACK;
-		info->status.ack_signal = ts->ack_rssi;
+	switch (ts->status) {
+	case HAL_WBM_TQM_REL_REASON_FRAME_ACKED:
+		if (!(info->flags & IEEE80211_TX_CTL_NO_ACK)) {
+			info->flags |= IEEE80211_TX_STAT_ACK;
+			info->status.ack_signal = ts->ack_rssi;
 
-		if (!test_bit(WMI_TLV_SERVICE_HW_DB2DBM_CONVERSION_SUPPORT,
-			      ab->wmi_ab.svc_map))
-			info->status.ack_signal += ATH11K_DEFAULT_NOISE_FLOOR;
+			if (!test_bit(WMI_TLV_SERVICE_HW_DB2DBM_CONVERSION_SUPPORT,
+				      ab->wmi_ab.svc_map))
+				info->status.ack_signal += ATH11K_DEFAULT_NOISE_FLOOR;
 
-		info->status.flags |= IEEE80211_TX_STATUS_ACK_SIGNAL_VALID;
+			info->status.flags |= IEEE80211_TX_STATUS_ACK_SIGNAL_VALID;
+		}
+		break;
+	case HAL_WBM_TQM_REL_REASON_CMD_REMOVE_TX:
+		if (info->flags & IEEE80211_TX_CTL_NO_ACK) {
+			info->flags |= IEEE80211_TX_STAT_NOACK_TRANSMITTED;
+			break;
+		}
+		fallthrough;
+	case HAL_WBM_TQM_REL_REASON_CMD_REMOVE_MPDU:
+	case HAL_WBM_TQM_REL_REASON_CMD_REMOVE_AGED_FRAMES:
+		/* The firmware dropped the frame itself (for example when the
+		 * peer's queue was full); it was not lost on the air, so do
+		 * not report it to mac80211 as a failed transmission.
+		 */
+		ieee80211_free_txskb(ar->hw, msdu);
+		return;
+	default:
+		ath11k_dbg(ab, ATH11K_DBG_DP_TX, "tx frame is not acked status %d\n",
+			   ts->status);
+		break;
 	}
 
-	if (ts->status == HAL_WBM_TQM_REL_REASON_CMD_REMOVE_TX &&
-	    (info->flags & IEEE80211_TX_CTL_NO_ACK))
-		info->flags |= IEEE80211_TX_STAT_NOACK_TRANSMITTED;
-
 	if (unlikely(ath11k_debugfs_is_extd_tx_stats_enabled(ar)) ||
 	    ab->hw_params.single_pdev_only) {
 		if (ts->flags & HAL_TX_STATUS_FLAGS_FIRST_MSDU) {

---
base-commit: 5c8eab13e391aaabd5a1ad58f3ee4bb10ce7573e
change-id: 20261106-ath11k-tqm-internal-drops-4770f6c1e48e

Best regards,
--  
Christopher Griffin <christophergriffin05@gmail.com>

