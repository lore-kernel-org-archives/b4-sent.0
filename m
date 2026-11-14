From: Christopher Griffin <christophergriffin05@gmail.com>
Date: Sat, 14 Nov 2026 08:34:18 -0600
Subject: [PATCH] wifi: ath11k: read a station's TX rate under base_lock
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261114-ath11k-sta-txrate-lock-v1-1-8331a03b1000@gmail.com>
X-B4-Tracking: v=1; b=H4sIAGlx+GoC/yXMQQqDMBCF4avIrDuQRBTqVUoXSTrqVFHJjCKId
 2+qb/ct3n+AUGISaIoDEm0sPE8Z9lFA7P3UEfInG5xxtc1Dr721A4p61D15JRznOGBlQlWaQOU
 zOsjnJVHL+xV+vW/LGr4U9V+D8/wBBwpHDHoAAAA=
X-Change-ID: 20261111-ath11k-sta-txrate-lock-50b530be39c2
To: Jeff Johnson <jjohnson@kernel.org>
Cc: Baochen Qiang <baochen.qiang@oss.qualcomm.com>, 
 linux-wireless@vger.kernel.org, ath11k@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Jeff Johnson <jeff.johnson@oss.qualcomm.com>, 
 Christopher Griffin <christophergriffin05@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794666858; l=3922;
 i=christophergriffin05@gmail.com; s=20261024; h=from:subject:message-id;
 bh=lkF7CDKj4qzGCwVidTwjxrPbBspcYexivWzn0z5gLhU=;
 b=JuwehofTeNwpSKgXfo/YghmTFgukSYSYDa/F0Df96zD+YhS6oT/0Ghs8BJuQxkSTzeaO3gbC8
 l2kaUyf1Dc3D4e0jgZ9MyqHk0SpoQmVOA59yYpzAX8V5Kx4CmI6NaFq
X-Developer-Key: i=christophergriffin05@gmail.com; a=ed25519;
 pk=oa9tkTNpiGoFWdGvpDHXLSobApmsh9BfrJRJrRJAvWA=
X-Endpoint-Received: by B4 Relay for christophergriffin05@gmail.com/20261024 with auth_id=1309
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ath11k_update_per_peer_tx_stats() and ath11k_dp_tx_update_txcompl()
rewrite arsta->txrate under ab->base_lock: they clear it, then fill in
its fields one by one. ath11k_mac_op_sta_statistics() copies it into the
station info without that lock, so a station dump that runs while a TX
status updates the rate can copy the HE flag with an nss of 0, and
cfg80211 warns:

  WARNING: CPU: 3 PID: 30429 at net/wireless/util.c:1581 ieee80211_get_vht_max_nss+0x474/0x868 [cfg80211]
  Call trace:
   ieee80211_get_vht_max_nss+0x474/0x868 [cfg80211] (P)
   cfg80211_calculate_bitrate+0x1e0/0x4f4 [cfg80211]
   nl80211_put_sta_rate+0x50/0x1230 [cfg80211]
   nl80211_put_sta_rate+0xa30/0x1230 [cfg80211]
   nl80211_dump_station+0x4b8/0x7e0 [cfg80211]

(the line is the nss check in the inlined
cfg80211_calculate_bitrate_he()). It was seen once in about a day on an
IPQ8074 AP whose stations are dumped periodically by a monitoring agent.

Copy the rate under base_lock and report from the copy, as ath12k reads
its peer rate info under its DP lock.

The change and this message were written with Claude, an AI coding
assistant.

Tested-on: IPQ8074 hw2.0 AHB WLAN.HK.2.9.0.1-02146-QCAHKSWPL_SILICONZ-1
Tested-on: QCN9074 hw1.0 PCI WLAN.HK.2.5.r4-00683-QCAHKSWPL_SILICONZ-1
Tested-on: IPQ6018 hw1.0 AHB WLAN.HK.2.5.0.1-03982-QCAHKSWPL_SILICONZ-3

Fixes: d5c65159f289 ("ath11k: driver for Qualcomm IEEE 802.11ax devices")
Signed-off-by: Christopher Griffin <christophergriffin05@gmail.com>
---
Found on an Arista C-360 (IPQ8074 + QCN9074) running OpenWrt, from a
warning in its kernel log; the cause was found by reading the code.
ath12k already reads its peer rate info under its DP lock.
---
 drivers/net/wireless/ath/ath11k/mac.c | 26 ++++++++++++++++----------
 1 file changed, 16 insertions(+), 10 deletions(-)

diff --git a/drivers/net/wireless/ath/ath11k/mac.c b/drivers/net/wireless/ath/ath11k/mac.c
index 1a237adaa37d1..d76eeb1ca0019 100644
--- a/drivers/net/wireless/ath/ath11k/mac.c
+++ b/drivers/net/wireless/ath/ath11k/mac.c
@@ -9425,6 +9425,7 @@ static void ath11k_mac_op_sta_statistics(struct ieee80211_hw *hw,
 {
 	struct ath11k_sta *arsta = ath11k_sta_to_arsta(sta);
 	struct ath11k *ar = arsta->arvif->ar;
+	struct rate_info txrate;
 	s8 signal;
 	bool db2dbm = test_bit(WMI_TLV_SERVICE_HW_DB2DBM_CONVERSION_SUPPORT,
 			       ar->ab->wmi_ab.svc_map);
@@ -9435,18 +9436,23 @@ static void ath11k_mac_op_sta_statistics(struct ieee80211_hw *hw,
 	sinfo->tx_duration = arsta->tx_duration;
 	sinfo->filled |= BIT_ULL(NL80211_STA_INFO_TX_DURATION);
 
-	if (arsta->txrate.legacy || arsta->txrate.nss) {
-		if (arsta->txrate.legacy) {
-			sinfo->txrate.legacy = arsta->txrate.legacy;
+	/* The TX status paths clear and refill txrate under base_lock */
+	spin_lock_bh(&ar->ab->base_lock);
+	txrate = arsta->txrate;
+	spin_unlock_bh(&ar->ab->base_lock);
+
+	if (txrate.legacy || txrate.nss) {
+		if (txrate.legacy) {
+			sinfo->txrate.legacy = txrate.legacy;
 		} else {
-			sinfo->txrate.mcs = arsta->txrate.mcs;
-			sinfo->txrate.nss = arsta->txrate.nss;
-			sinfo->txrate.bw = arsta->txrate.bw;
-			sinfo->txrate.he_gi = arsta->txrate.he_gi;
-			sinfo->txrate.he_dcm = arsta->txrate.he_dcm;
-			sinfo->txrate.he_ru_alloc = arsta->txrate.he_ru_alloc;
+			sinfo->txrate.mcs = txrate.mcs;
+			sinfo->txrate.nss = txrate.nss;
+			sinfo->txrate.bw = txrate.bw;
+			sinfo->txrate.he_gi = txrate.he_gi;
+			sinfo->txrate.he_dcm = txrate.he_dcm;
+			sinfo->txrate.he_ru_alloc = txrate.he_ru_alloc;
 		}
-		sinfo->txrate.flags = arsta->txrate.flags;
+		sinfo->txrate.flags = txrate.flags;
 		sinfo->filled |= BIT_ULL(NL80211_STA_INFO_TX_BITRATE);
 	}
 

---
base-commit: ff4c7359e310744a7abe53cf66d921fa2969eb19
change-id: 20261111-ath11k-sta-txrate-lock-50b530be39c2

Best regards,
--  
Christopher Griffin <christophergriffin05@gmail.com>

