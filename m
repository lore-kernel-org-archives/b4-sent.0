From: Michael Reeves <michael.reeves077@gmail.com>
Date: Fri, 13 Nov 2026 06:31:56 +0000
Subject: [PATCH wireless-next 2/4] wifi: brcmfmac: Advertise HE
 capabilities
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261113-6ghz-v1-2-0b9a67e413a9@gmail.com>
References: <20261113-6ghz-v1-0-0b9a67e413a9@gmail.com>
In-Reply-To: <20261113-6ghz-v1-0-0b9a67e413a9@gmail.com>
To: Arend van Spriel <arend.vanspriel@broadcom.com>
Cc: asahi@lists.linux.dev, linux-wireless@vger.kernel.org, 
 brcm80211@lists.linux.dev, brcm80211-dev-list.pdl@broadcom.com, 
 linux-kernel@vger.kernel.org, Michael Reeves <michael.reeves077@gmail.com>, 
 Yureka Lilian <yureka@cyberchaos.dev>, Daniel Berlin <dberlin@dberlin.org>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794551523; l=8895;
 i=michael.reeves077@gmail.com; s=20261107; h=from:subject:message-id;
 bh=VOaAajPWI3q3N4RP08nZvmHQLhXU8MQD7XxBDr/BKG0=;
 b=wKJ9V+RedI+doDaUoFgOY6tBh7GtEzSprFb/HPsVq4GZRp1hS/olZXE/JYTK4scFteqT9ntRg
 yn4u8s539xqD16XHxthDmcGLCdslYNOioEaYBGfNMIXvrf4egeNqy3C
X-Developer-Key: i=michael.reeves077@gmail.com; a=ed25519;
 pk=ykwkLcuByJYb/cdLc2UuoYP03pIzwrscEZg30+4tJL8=
X-Endpoint-Received: by B4 Relay for michael.reeves077@gmail.com/20261107 with auth_id=1442
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The driver currently does not report HE (802.11ax) capabilities, which
are mandatory in cfg80211 for 6 GHz band operation.

Advertise HE capabilities for the station interface type when the
firmware indicates HE support. Determine the 160 MHz capability bits
from the firmware-reported bandwidth limits, and generate the supported
MCS map based on the number of spatial chains.

Move band setup prior to wiphy registration so cfg80211 validates HE
capabilities at registration time.

Tested-by: Yureka Lilian <yureka@cyberchaos.dev>
Co-developed-by: Daniel Berlin <dberlin@dberlin.org>
Signed-off-by: Daniel Berlin <dberlin@dberlin.org>
Signed-off-by: Michael Reeves <michael.reeves077@gmail.com>
---
 .../broadcom/brcm80211/brcmfmac/cfg80211.c         | 126 +++++++++++++++++++--
 .../broadcom/brcm80211/brcmfmac/cfg80211.h         |   2 +
 .../broadcom/brcm80211/brcmfmac/fwil_types.h       |   3 +
 3 files changed, 124 insertions(+), 7 deletions(-)

diff --git a/drivers/net/wireless/broadcom/brcm80211/brcmfmac/cfg80211.c b/drivers/net/wireless/broadcom/brcm80211/brcmfmac/cfg80211.c
index c4ef4f6d3a06..12545ae15e9e 100644
--- a/drivers/net/wireless/broadcom/brcm80211/brcmfmac/cfg80211.c
+++ b/drivers/net/wireless/broadcom/brcm80211/brcmfmac/cfg80211.c
@@ -7451,7 +7451,7 @@ static void brcmf_update_ht_cap(struct ieee80211_supported_band *band,
 	band->ht_cap.mcs.tx_params = IEEE80211_HT_MCS_TX_DEFINED;
 }
 
-static __le16 brcmf_get_mcs_map(u32 nchain, enum ieee80211_vht_mcs_support supp)
+static __le16 brcmf_get_mcs_map(u32 nchain, int supp)
 {
 	u16 mcs_map;
 	int i;
@@ -7504,6 +7504,112 @@ static void brcmf_update_vht_cap(struct ieee80211_supported_band *band,
 	}
 }
 
+static void brcmf_update_he_cap(struct ieee80211_supported_band *band,
+				struct ieee80211_sband_iftype_data *data,
+				u32 bw_cap[], u32 nchain)
+{
+	struct ieee80211_sta_he_cap *he_cap = &data->he_cap;
+	struct ieee80211_he_cap_elem *elem = &he_cap->he_cap_elem;
+	struct ieee80211_he_mcs_nss_supp *mcs = &he_cap->he_mcs_nss_supp;
+	__le16 mcs_map = brcmf_get_mcs_map(nchain,
+					   IEEE80211_HE_MCS_SUPPORT_0_11);
+	bool bw160 = bw_cap[band->band] & WLC_BW_160MHZ_BIT;
+
+	memset(data, 0, sizeof(*data));
+	data->types_mask = BIT(NL80211_IFTYPE_STATION);
+	he_cap->has_he = true;
+
+	elem->mac_cap_info[0] = IEEE80211_HE_MAC_CAP0_HTC_HE |
+				IEEE80211_HE_MAC_CAP0_TWT_REQ |
+				IEEE80211_HE_MAC_CAP0_TWT_RES;
+	elem->mac_cap_info[1] = IEEE80211_HE_MAC_CAP1_TF_MAC_PAD_DUR_8US |
+				IEEE80211_HE_MAC_CAP1_TF_MAC_PAD_DUR_16US;
+	elem->mac_cap_info[2] = IEEE80211_HE_MAC_CAP2_BSR |
+				IEEE80211_HE_MAC_CAP2_BCAST_TWT;
+	elem->mac_cap_info[3] = IEEE80211_HE_MAC_CAP3_OMI_CONTROL |
+				IEEE80211_HE_MAC_CAP3_MAX_AMPDU_LEN_EXP_EXT_1 |
+				IEEE80211_HE_MAC_CAP3_FLEX_TWT_SCHED;
+	elem->mac_cap_info[4] = IEEE80211_HE_MAC_CAP4_AMSDU_IN_AMPDU;
+
+	if (band->band == NL80211_BAND_2GHZ) {
+		if (band->ht_cap.cap & IEEE80211_HT_CAP_SUP_WIDTH_20_40)
+			elem->phy_cap_info[0] |=
+				IEEE80211_HE_PHY_CAP0_CHANNEL_WIDTH_SET_40MHZ_IN_2G;
+		elem->phy_cap_info[8] |=
+			IEEE80211_HE_PHY_CAP8_20MHZ_IN_40MHZ_HE_PPDU_IN_2G;
+	} else {
+		if (bw_cap[band->band] & WLC_BW_80MHZ_BIT)
+			elem->phy_cap_info[0] |=
+				IEEE80211_HE_PHY_CAP0_CHANNEL_WIDTH_SET_40MHZ_80MHZ_IN_5G;
+		if (bw160) {
+			elem->phy_cap_info[0] |=
+				IEEE80211_HE_PHY_CAP0_CHANNEL_WIDTH_SET_160MHZ_IN_5G;
+			elem->phy_cap_info[8] |=
+				IEEE80211_HE_PHY_CAP8_20MHZ_IN_160MHZ_HE_PPDU |
+				IEEE80211_HE_PHY_CAP8_80MHZ_IN_160MHZ_HE_PPDU;
+		}
+	}
+
+	elem->phy_cap_info[1] = IEEE80211_HE_PHY_CAP1_LDPC_CODING_IN_PAYLOAD;
+	elem->phy_cap_info[2] = IEEE80211_HE_PHY_CAP2_NDP_4x_LTF_AND_3_2US |
+				IEEE80211_HE_PHY_CAP2_UL_MU_FULL_MU_MIMO |
+				IEEE80211_HE_PHY_CAP2_UL_MU_PARTIAL_MU_MIMO;
+	elem->phy_cap_info[3] = IEEE80211_HE_PHY_CAP3_DCM_MAX_CONST_TX_QPSK |
+				IEEE80211_HE_PHY_CAP3_DCM_MAX_TX_NSS_2 |
+				IEEE80211_HE_PHY_CAP3_DCM_MAX_CONST_RX_16_QAM |
+				IEEE80211_HE_PHY_CAP3_SU_BEAMFORMER;
+	elem->phy_cap_info[4] =
+		IEEE80211_HE_PHY_CAP4_SU_BEAMFORMEE |
+		IEEE80211_HE_PHY_CAP4_BEAMFORMEE_MAX_STS_ABOVE_80MHZ_4 |
+		IEEE80211_HE_PHY_CAP4_BEAMFORMEE_MAX_STS_UNDER_80MHZ_8;
+	elem->phy_cap_info[5] =
+		IEEE80211_HE_PHY_CAP5_NG16_SU_FEEDBACK |
+		IEEE80211_HE_PHY_CAP5_NG16_MU_FEEDBACK |
+		IEEE80211_HE_PHY_CAP5_BEAMFORMEE_NUM_SND_DIM_UNDER_80MHZ_2;
+	elem->phy_cap_info[6] =
+		IEEE80211_HE_PHY_CAP6_CODEBOOK_SIZE_42_SU |
+		IEEE80211_HE_PHY_CAP6_CODEBOOK_SIZE_75_MU |
+		IEEE80211_HE_PHY_CAP6_TRIG_SU_BEAMFORMING_FB |
+		IEEE80211_HE_PHY_CAP6_TRIG_MU_BEAMFORMING_PARTIAL_BW_FB |
+		IEEE80211_HE_PHY_CAP6_TRIG_CQI_FB |
+		IEEE80211_HE_PHY_CAP6_PARTIAL_BW_EXT_RANGE |
+		IEEE80211_HE_PHY_CAP6_PPE_THRESHOLD_PRESENT;
+	elem->phy_cap_info[7] =
+		IEEE80211_HE_PHY_CAP7_HE_SU_MU_PPDU_4XLTF_AND_08_US_GI |
+		IEEE80211_HE_PHY_CAP7_MAX_NC_1;
+	elem->phy_cap_info[8] |=
+		IEEE80211_HE_PHY_CAP8_HE_ER_SU_PPDU_4XLTF_AND_08_US_GI;
+	elem->phy_cap_info[9] =
+		IEEE80211_HE_PHY_CAP9_TX_1024_QAM_LESS_THAN_242_TONE_RU |
+		IEEE80211_HE_PHY_CAP9_RX_1024_QAM_LESS_THAN_242_TONE_RU |
+		IEEE80211_HE_PHY_CAP9_RX_FULL_BW_SU_USING_MU_WITH_COMP_SIGB |
+		IEEE80211_HE_PHY_CAP9_RX_FULL_BW_SU_USING_MU_WITH_NON_COMP_SIGB;
+
+	mcs->rx_mcs_80 = mcs_map;
+	mcs->tx_mcs_80 = mcs_map;
+	if (bw160) {
+		mcs->rx_mcs_160 = mcs_map;
+		mcs->tx_mcs_160 = mcs_map;
+	} else {
+		mcs->rx_mcs_160 = cpu_to_le16(0xffff);
+		mcs->tx_mcs_160 = cpu_to_le16(0xffff);
+	}
+
+	band->n_iftype_data = 1;
+	band->iftype_data = data;
+}
+
+static bool brcmf_he_enabled(struct brcmf_if *ifp)
+{
+	u8 enable = 0;
+
+	if (brcmf_fil_xtlv_data_get(ifp, "he", BRCMF_HE_CMD_ENABLE,
+				    &enable, sizeof(enable)))
+		return false;
+
+	return enable;
+}
+
 static int brcmf_setup_wiphybands(struct brcmf_cfg80211_info *cfg)
 {
 	struct brcmf_pub *drvr = cfg->pub;
@@ -7520,8 +7626,10 @@ static int brcmf_setup_wiphybands(struct brcmf_cfg80211_info *cfg)
 	u32 txstreams = 0;
 	u32 txbf_bfe_cap = 0;
 	u32 txbf_bfr_cap = 0;
+	bool he_enable;
 
 	(void)brcmf_fil_iovar_int_get(ifp, "vhtmode", &vhtmode);
+	he_enable = brcmf_he_enabled(ifp);
 	err = brcmf_fil_iovar_int_get(ifp, "nmode", &nmode);
 	if (err) {
 		bphy_err(drvr, "nmode error (%d)\n", err);
@@ -7571,6 +7679,9 @@ static int brcmf_setup_wiphybands(struct brcmf_cfg80211_info *cfg)
 		if (vhtmode)
 			brcmf_update_vht_cap(band, bw_cap, nchain, txstreams,
 					     txbf_bfe_cap, txbf_bfr_cap);
+		if (he_enable)
+			brcmf_update_he_cap(band, &cfg->he_iftype_data[i],
+					    bw_cap, nchain);
 	}
 
 	return 0;
@@ -8598,18 +8709,19 @@ struct brcmf_cfg80211_info *brcmf_cfg80211_attach(struct brcmf_pub *drvr,
 	if (brcmf_feat_is_enabled(ifp, BRCMF_FEAT_DUMP_OBSS))
 		ops->dump_survey = brcmf_cfg80211_dump_survey;
 
+	/* cfg80211 validates the band capabilities when registering */
+	err = brcmf_setup_wiphybands(cfg);
+	if (err) {
+		bphy_err(drvr, "Setting wiphy bands failed (%d)\n", err);
+		goto priv_out;
+	}
+
 	err = wiphy_register(wiphy);
 	if (err < 0) {
 		bphy_err(drvr, "Could not register wiphy device (%d)\n", err);
 		goto priv_out;
 	}
 
-	err = brcmf_setup_wiphybands(cfg);
-	if (err) {
-		bphy_err(drvr, "Setting wiphy bands failed (%d)\n", err);
-		goto wiphy_unreg_out;
-	}
-
 	/* If cfg80211 didn't disable 40MHz HT CAP in wiphy_register(),
 	 * setup 40MHz in 2GHz band and enable OBSS scanning.
 	 */
diff --git a/drivers/net/wireless/broadcom/brcm80211/brcmfmac/cfg80211.h b/drivers/net/wireless/broadcom/brcm80211/brcmfmac/cfg80211.h
index 1aa99390a951..3168a262109e 100644
--- a/drivers/net/wireless/broadcom/brcm80211/brcmfmac/cfg80211.h
+++ b/drivers/net/wireless/broadcom/brcm80211/brcmfmac/cfg80211.h
@@ -368,6 +368,7 @@ struct brcmf_cfg80211_wowl {
  * @vif_event: vif event signalling.
  * @wowl: wowl related information.
  * @pno: information of pno module.
+ * @he_iftype_data: per band HE capabilities registered with the wiphy.
  */
 struct brcmf_cfg80211_info {
 	struct wiphy *wiphy;
@@ -401,6 +402,7 @@ struct brcmf_cfg80211_info {
 	struct brcmf_cfg80211_wowl wowl;
 	struct brcmf_pno_info *pno;
 	u8 ac_priority[MAX_8021D_PRIO];
+	struct ieee80211_sband_iftype_data he_iftype_data[NUM_NL80211_BANDS];
 };
 
 /**
diff --git a/drivers/net/wireless/broadcom/brcm80211/brcmfmac/fwil_types.h b/drivers/net/wireless/broadcom/brcm80211/brcmfmac/fwil_types.h
index 37d9414546d5..f4e8eeeffa08 100644
--- a/drivers/net/wireless/broadcom/brcm80211/brcmfmac/fwil_types.h
+++ b/drivers/net/wireless/broadcom/brcm80211/brcmfmac/fwil_types.h
@@ -1375,4 +1375,7 @@ struct brcmf_eventmsgs_ext_le {
 	u8 mask[] __counted_by(len);
 };
 
+/* "he" iovar sub-command ids */
+#define BRCMF_HE_CMD_ENABLE	0
+
 #endif /* FWIL_TYPES_H_ */

-- 
2.56.0

