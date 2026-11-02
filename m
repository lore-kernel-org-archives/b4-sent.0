From: Christopher Griffin <christophergriffin05@gmail.com>
Date: Sun, 01 Nov 2026 23:14:10 -0600
Subject: [PATCH ath-next 2/3] wifi: ath11k: hold back FCS-failed monitor
 frames unless asked for
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261101-b8-monitor-frames-v1-2-f0a43d9630e5@gmail.com>
References: <20261101-b8-monitor-frames-v1-0-f0a43d9630e5@gmail.com>
In-Reply-To: <20261101-b8-monitor-frames-v1-0-f0a43d9630e5@gmail.com>
To: Jeff Johnson <jjohnson@kernel.org>, 
 Jouni Malinen <quic_jouni@quicinc.com>, Kalle Valo <kvalo@kernel.org>, 
 Baochen Qiang <baochen.qiang@oss.qualcomm.com>, 
 Julia Lawall <julia.lawall@lip6.fr>, kbuild test robot <lkp@intel.com>, 
 Manikanta Pubbisetty <quic_mpubbise@quicinc.com>, 
 Venkateswara Naralasetty <quic_vnaralas@quicinc.com>, 
 Pradeep Kumar Chitrapu <quic_pradeepc@quicinc.com>, 
 Anilkumar Kolli <quic_akolli@quicinc.com>, Miles Hu <milehu@codeaurora.org>
Cc: linux-wireless@vger.kernel.org, ath11k@lists.infradead.org, 
 linux-kernel@vger.kernel.org, 
 Govindaraj Saminathan <quic_gsamin@quicinc.com>, 
 Sriram R <sriram.ramachandran@oss.qualcomm.com>, 
 Shashidhar Lakkavalli <slakkavalli@datto.com>, 
 Rajkumar Manoharan <rmanohar@codeaurora.org>, 
 Christopher Griffin <christophergriffin05@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793596448; l=3200;
 i=christophergriffin05@gmail.com; s=20261024; h=from:subject:message-id;
 bh=gW5/j2hiiWOOFjn6ouakRd7VONDoZcdzfhX/IthW4Vo=;
 b=Unx/VLGUd03Y0E20Qd3syMAamP4RBCNzYP78JySeJPZc2vyvfug+SX7i6SocFG0/VJvLBY9kS
 TL7D2W2rPNeA+rc3+SuG5IF1Qd6PIFCKu7Phky9JXOCVwHbAaNRY9Il
X-Developer-Key: i=christophergriffin05@gmail.com; a=ed25519;
 pk=oa9tkTNpiGoFWdGvpDHXLSobApmsh9BfrJRJrRJAvWA=
X-Endpoint-Received: by B4 Relay for christophergriffin05@gmail.com/20261024 with auth_id=1309
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ath11k accepts FIF_FCSFAIL in configure_filter() but never looks at
the filter: its monitor path hands every MPDU whose FCS failed to
mac80211, flagged RX_FLAG_FAILED_FCS_CRC. mac80211 passes such a frame
to every monitor interface, whatever that interface's flags. It leaves
holding these frames back to the driver unless a monitor asked for them
with the "fcsfail" flag, which turns on FIF_FCSFAIL. So a monitor made
without that flag gets them anyway. On an Arista C-360 the QCN9072 scan
radio's monitor saw a bad FCS on 6 to 10 % of the beacons it heard.

Drop an FCS-failed MPDU in the monitor path unless FIF_FCSFAIL is set,
as ath10k does in ath10k_process_rx(). filter_flags is now read outside
conf_mutex, so write it with WRITE_ONCE().

Fixes: d5c65159f289 ("ath11k: driver for Qualcomm IEEE 802.11ax devices")
Tested-on: QCN9074 hw1.0 PCI WLAN.HK.2.5.r4-00683-QCAHKSWPL_SILICONZ-1

Assisted-by: Claude:claude-opus-5-5
Signed-off-by: Christopher Griffin <christophergriffin05@gmail.com>
---
 drivers/net/wireless/ath/ath11k/dp_rx.c | 12 +++++++++++-
 drivers/net/wireless/ath/ath11k/mac.c   |  3 ++-
 2 files changed, 13 insertions(+), 2 deletions(-)

diff --git a/drivers/net/wireless/ath/ath11k/dp_rx.c b/drivers/net/wireless/ath/ath11k/dp_rx.c
index 4e0b717b6f06d..7809c92baa325 100644
--- a/drivers/net/wireless/ath/ath11k/dp_rx.c
+++ b/drivers/net/wireless/ath/ath11k/dp_rx.c
@@ -5115,6 +5115,7 @@ static int ath11k_dp_rx_mon_deliver(struct ath11k *ar, u32 mac_id,
 	struct sk_buff *mon_skb, *skb_next, *header;
 	struct ieee80211_rx_status *rxs = &dp->rx_status;
 	bool fcs_err = false;
+	int ret = 0;
 
 	mon_skb = ath11k_dp_rx_mon_merg_msdus(ar, mac_id, head_msdu,
 					      tail_msdu, rxs, &fcs_err);
@@ -5122,6 +5123,13 @@ static int ath11k_dp_rx_mon_deliver(struct ath11k *ar, u32 mac_id,
 	if (!mon_skb)
 		goto mon_deliver_fail;
 
+	/* mac80211 passes a frame whose FCS failed to every monitor
+	 * interface. Holding such frames back unless a monitor asked for
+	 * them (FIF_FCSFAIL) is left to the driver.
+	 */
+	if (fcs_err && !(READ_ONCE(ar->filter_flags) & FIF_FCSFAIL))
+		goto mon_drop;
+
 	header = mon_skb;
 
 	rxs->flag = 0;
@@ -5153,13 +5161,15 @@ static int ath11k_dp_rx_mon_deliver(struct ath11k *ar, u32 mac_id,
 	return 0;
 
 mon_deliver_fail:
+	ret = -EINVAL;
+mon_drop:
 	mon_skb = head_msdu;
 	while (mon_skb) {
 		skb_next = mon_skb->next;
 		dev_kfree_skb_any(mon_skb);
 		mon_skb = skb_next;
 	}
-	return -EINVAL;
+	return ret;
 }
 
 /* The destination ring processing is stuck if the destination is not
diff --git a/drivers/net/wireless/ath/ath11k/mac.c b/drivers/net/wireless/ath/ath11k/mac.c
index ada0f3a3c8565..0b7371ad808d5 100644
--- a/drivers/net/wireless/ath/ath11k/mac.c
+++ b/drivers/net/wireless/ath/ath11k/mac.c
@@ -7456,7 +7456,8 @@ static void ath11k_mac_op_configure_filter(struct ieee80211_hw *hw,
 	mutex_lock(&ar->conf_mutex);
 
 	*total_flags &= SUPPORTED_FILTERS;
-	ar->filter_flags = *total_flags;
+	/* read without the lock in the monitor rx path */
+	WRITE_ONCE(ar->filter_flags, *total_flags);
 
 	mutex_unlock(&ar->conf_mutex);
 }

-- 
2.43.0

