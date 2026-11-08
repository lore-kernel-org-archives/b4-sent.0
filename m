From: Christopher Griffin <christophergriffin05@gmail.com>
Date: Sat, 07 Nov 2026 18:02:56 -0600
Subject: [PATCH] wifi: ath11k: advertise 7935-byte A-MSDUs on 2 GHz-only
 radios
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261107-ath11k-2ghz-ht-max-amsdu-v1-1-ed18a6b0c18d@gmail.com>
X-B4-Tracking: v=1; b=H4sIAC+872oC/yXMMQ6DMAxA0asgz7WEMxSpV0EMJjHEIGgVB4SKu
 HvTdnzD/yeYJBWDR3VCkl1Nn2sB3SrwkddRUEMxuNrdieoGOUeiGd0Y3xgzLnwgLxY29DQQB+b
 Q9AwlfyUZ9Pit2+5v2/pJfP7+4Lo+/WuILnwAAAA=
X-Change-ID: 20261107-ath11k-2ghz-ht-max-amsdu-c1f1adaad7ba
To: Jeff Johnson <jjohnson@kernel.org>
Cc: Baochen Qiang <baochen.qiang@oss.qualcomm.com>, 
 linux-wireless@vger.kernel.org, ath11k@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Jeff Johnson <jeff.johnson@oss.qualcomm.com>, 
 Christopher Griffin <christophergriffin05@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794096176; l=5625;
 i=christophergriffin05@gmail.com; s=20261024; h=from:subject:message-id;
 bh=C7DUr4eKMqw0XBpofJFw7fPdlQOxru+WVXPSPaby87E=;
 b=xtxBE9PG93ZvYFGT44EgRqSetMs+317bSzModVVHqyg96nhWOFgbrsldiIkefGrEEutTkAXII
 LRgO5RL8W43CzhvHG4YZU8VhHLY7GyKPYU4A8iDQSAAL8RuPvkREV5j
X-Developer-Key: i=christophergriffin05@gmail.com; a=ed25519;
 pk=oa9tkTNpiGoFWdGvpDHXLSobApmsh9BfrJRJrRJAvWA=
X-Endpoint-Received: by B4 Relay for christophergriffin05@gmail.com/20261024 with auth_id=1309
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ath11k_create_ht_cap() sets IEEE80211_HT_CAP_MAX_AMSDU when the pdev's
VHT capabilities allow an MPDU longer than 3895 bytes. ath11k fills the
pdev's VHT capabilities from vht_cap_info_5g only, so on a pdev without
5 GHz they are zero and its 2 GHz band advertises a maximum A-MSDU of
3839 bytes. The 2 GHz band of a dual-band pdev and every 5 GHz radio
advertise 7935 bytes with the same MAC.

The firmware reports VHT capabilities for 2 GHz too, in
vht_cap_info_2g. On IPQ6018 the 2 GHz pdev reports 0x73997992, a
maximum MPDU length of 11454 bytes, and the 5 GHz pdev 0x7399f9b2.

Keep the 2 GHz VHT capabilities with the band's other capabilities, and
take the max A-MSDU bit from them when the pdev has no VHT capabilities
of its own. Pdevs with 5 GHz are unchanged.

On IPQ6018 the 2 GHz radio's HT capabilities change from 0x11e7 to
0x19e7, and hostapd adds [MAX-AMSDU-7935] to its ht_capab. Its beacons,
read by another AP, advertise a maximum A-MSDU length of 7935 bytes,
where the 2 GHz-only radio of an IPQ8074 AP without the change
advertises 3839. Beaconing and channel switches on both radios work as
before.

Tested-on: IPQ6018 hw1.0 AHB WLAN.HK.2.5.0.1-03982-QCAHKSWPL_SILICONZ-3

The change, this message and the test were written with Claude, an AI
coding assistant.

Signed-off-by: Christopher Griffin <christophergriffin05@gmail.com>
---
Found on Arista C-360 (IPQ8074) and W-318 (IPQ6018) APs while comparing
the capabilities their radios report: every 2 GHz-only radio said
3839, everything else 7935.

ath12k fills the pdev's VHT capabilities the same way
(ath12k_pull_mac_phy_cap_svc_ready_ext() reads vht_cap_info_5g only), so a
2 GHz-only ath12k pdev probably has the same gap. I have no such
hardware to test it on, so this patch leaves ath12k alone.
---
 drivers/net/wireless/ath/ath11k/core.h |  1 +
 drivers/net/wireless/ath/ath11k/mac.c  | 15 ++++++++++-----
 drivers/net/wireless/ath/ath11k/wmi.c  |  1 +
 3 files changed, 12 insertions(+), 5 deletions(-)

diff --git a/drivers/net/wireless/ath/ath11k/core.h b/drivers/net/wireless/ath/ath11k/core.h
index a0d725923ef24..6eca6dc67da16 100644
--- a/drivers/net/wireless/ath/ath11k/core.h
+++ b/drivers/net/wireless/ath/ath11k/core.h
@@ -818,6 +818,7 @@ struct ath11k_band_cap {
 	u32 phy_id;
 	u32 max_bw_supported;
 	u32 ht_cap_info;
+	u32 vht_cap_info;
 	u32 he_cap_info[2];
 	u32 he_mcs;
 	u32 he_cap_phy_info[PSOC_HOST_MAX_PHY_SIZE];
diff --git a/drivers/net/wireless/ath/ath11k/mac.c b/drivers/net/wireless/ath/ath11k/mac.c
index 1a237adaa37d1..1f405e200b0bc 100644
--- a/drivers/net/wireless/ath/ath11k/mac.c
+++ b/drivers/net/wireless/ath/ath11k/mac.c
@@ -5556,11 +5556,11 @@ static int ath11k_mac_op_conf_tx(struct ieee80211_hw *hw,
 }
 
 static struct ieee80211_sta_ht_cap
-ath11k_create_ht_cap(struct ath11k *ar, u32 ar_ht_cap, u32 rate_cap_rx_chainmask)
+ath11k_create_ht_cap(struct ath11k *ar, u32 ar_ht_cap, u32 ar_vht_cap,
+		     u32 rate_cap_rx_chainmask)
 {
 	int i;
 	struct ieee80211_sta_ht_cap ht_cap = {};
-	u32 ar_vht_cap = ar->pdev->cap.vht_cap;
 
 	if (!(ar_ht_cap & WMI_HT_CAP_ENABLED))
 		return ht_cap;
@@ -5769,7 +5769,7 @@ static void ath11k_mac_setup_ht_vht_cap(struct ath11k *ar,
 	struct ieee80211_supported_band *band;
 	u32 rate_cap_tx_chainmask;
 	u32 rate_cap_rx_chainmask;
-	u32 ht_cap;
+	u32 ht_cap, vht_cap;
 
 	rate_cap_tx_chainmask = ar->cfg_tx_chainmask >> cap->tx_chain_mask_shift;
 	rate_cap_rx_chainmask = ar->cfg_rx_chainmask >> cap->rx_chain_mask_shift;
@@ -5777,9 +5777,14 @@ static void ath11k_mac_setup_ht_vht_cap(struct ath11k *ar,
 	if (cap->supported_bands & WMI_HOST_WLAN_2G_CAP) {
 		band = &ar->mac.sbands[NL80211_BAND_2GHZ];
 		ht_cap = cap->band[NL80211_BAND_2GHZ].ht_cap_info;
+		/* A pdev without 5 GHz has no VHT capabilities of its own, but
+		 * the firmware reports them for 2 GHz too: use those for the
+		 * max A-MSDU length.
+		 */
+		vht_cap = cap->vht_cap ?: cap->band[NL80211_BAND_2GHZ].vht_cap_info;
 		if (ht_cap_info)
 			*ht_cap_info = ht_cap;
-		band->ht_cap = ath11k_create_ht_cap(ar, ht_cap,
+		band->ht_cap = ath11k_create_ht_cap(ar, ht_cap, vht_cap,
 						    rate_cap_rx_chainmask);
 	}
 
@@ -5790,7 +5795,7 @@ static void ath11k_mac_setup_ht_vht_cap(struct ath11k *ar,
 		ht_cap = cap->band[NL80211_BAND_5GHZ].ht_cap_info;
 		if (ht_cap_info)
 			*ht_cap_info = ht_cap;
-		band->ht_cap = ath11k_create_ht_cap(ar, ht_cap,
+		band->ht_cap = ath11k_create_ht_cap(ar, ht_cap, cap->vht_cap,
 						    rate_cap_rx_chainmask);
 		band->vht_cap = ath11k_create_vht_cap(ar, rate_cap_tx_chainmask,
 						      rate_cap_rx_chainmask);
diff --git a/drivers/net/wireless/ath/ath11k/wmi.c b/drivers/net/wireless/ath/ath11k/wmi.c
index 82f85df481cbf..69405d8ca0901 100644
--- a/drivers/net/wireless/ath/ath11k/wmi.c
+++ b/drivers/net/wireless/ath/ath11k/wmi.c
@@ -454,6 +454,7 @@ ath11k_pull_mac_phy_cap_svc_ready_ext(struct ath11k_pdev_wmi *wmi_handle,
 		cap_band->phy_id = mac_phy_caps->phy_id;
 		cap_band->max_bw_supported = mac_phy_caps->max_bw_supported_2g;
 		cap_band->ht_cap_info = mac_phy_caps->ht_cap_info_2g;
+		cap_band->vht_cap_info = mac_phy_caps->vht_cap_info_2g;
 		cap_band->he_cap_info[0] = mac_phy_caps->he_cap_info_2g;
 		cap_band->he_cap_info[1] = mac_phy_caps->he_cap_info_2g_ext;
 		cap_band->he_mcs = mac_phy_caps->he_supp_mcs_2g;

---
base-commit: ad6bdd5f9030dbcf29a67f40ccdb3fa57afecff5
change-id: 20261107-ath11k-2ghz-ht-max-amsdu-c1f1adaad7ba

Best regards,
--  
Christopher Griffin <christophergriffin05@gmail.com>

