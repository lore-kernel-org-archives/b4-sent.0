From: Michael Reeves <michael.reeves077@gmail.com>
Date: Fri, 13 Nov 2026 06:31:57 +0000
Subject: [PATCH wireless-next 3/4] wifi: brcmfmac: Add support for the 6
 GHz band
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261113-6ghz-v1-3-0b9a67e413a9@gmail.com>
References: <20261113-6ghz-v1-0-0b9a67e413a9@gmail.com>
In-Reply-To: <20261113-6ghz-v1-0-0b9a67e413a9@gmail.com>
To: Arend van Spriel <arend.vanspriel@broadcom.com>
Cc: asahi@lists.linux.dev, linux-wireless@vger.kernel.org, 
 brcm80211@lists.linux.dev, brcm80211-dev-list.pdl@broadcom.com, 
 linux-kernel@vger.kernel.org, Michael Reeves <michael.reeves077@gmail.com>, 
 Daniel Berlin <dberlin@dberlin.org>, Yureka Lilian <yureka@cyberchaos.dev>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794551523; l=17895;
 i=michael.reeves077@gmail.com; s=20261107; h=from:subject:message-id;
 bh=4HGnRZlOV1Uoe1+y4vgiN4RfdWJVHn7IKIQ27irK3Hw=;
 b=+xPrKBMnZVgrNeWQefdqqtcLBHqPOhSyffBtstDjBmqqfNQcaEEq43+KifzyowNftGtSPNOWw
 P6XdTfDI0i8BNMSwv6NKHZHDDO76KBoWxRLmES5WIHzHfZeqTNEn3LF
X-Developer-Key: i=michael.reeves077@gmail.com; a=ed25519;
 pk=ykwkLcuByJYb/cdLc2UuoYP03pIzwrscEZg30+4tJL8=
X-Endpoint-Received: by B4 Relay for michael.reeves077@gmail.com/20261107 with auth_id=1442
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Daniel Berlin <dberlin@dberlin.org>

While firmware may report 6 GHz support in its band list, the driver
currently ignores the capability.

Enable 6 GHz band support when reported by the firmware and HE is
enabled. This includes registering 6 GHz channels, populating band
bandwidth capabilities, adding regulatory rules, and parsing 6 GHz
chanspecs in channel lists and scan results.

Exclude 6 GHz channels from PNO lists for now, as legacy PNO identifies
channels strictly by channel number, which collides with 2.4 GHz and 5
GHz channel numbering.

Tested-by: Yureka Lilian <yureka@cyberchaos.dev>
Signed-off-by: Daniel Berlin <dberlin@dberlin.org>
Co-developed-by: Michael Reeves <michael.reeves077@gmail.com>
Signed-off-by: Michael Reeves <michael.reeves077@gmail.com>
---
 .../broadcom/brcm80211/brcmfmac/cfg80211.c         | 229 +++++++++++++++------
 .../net/wireless/broadcom/brcm80211/brcmfmac/pno.c |   3 +
 .../broadcom/brcm80211/include/brcmu_wifi.h        |   1 +
 3 files changed, 166 insertions(+), 67 deletions(-)

diff --git a/drivers/net/wireless/broadcom/brcm80211/brcmfmac/cfg80211.c b/drivers/net/wireless/broadcom/brcm80211/brcmfmac/cfg80211.c
index 12545ae15e9e..90db55c0ab7a 100644
--- a/drivers/net/wireless/broadcom/brcm80211/brcmfmac/cfg80211.c
+++ b/drivers/net/wireless/broadcom/brcm80211/brcmfmac/cfg80211.c
@@ -5,6 +5,7 @@
 
 /* Toplevel file. Relies on dhd_linux.c to send commands to the dongle. */
 
+#include <linux/bitfield.h>
 #include <linux/kernel.h>
 #include <linux/etherdevice.h>
 #include <linux/module.h>
@@ -181,6 +182,14 @@ static struct ieee80211_rate __wl_rates[] = {
 	.max_power		= 30,				\
 }
 
+#define CHAN6G(_channel, _freq) {\
+	.band = NL80211_BAND_6GHZ,\
+	.center_freq = (_freq),\
+	.hw_value = (_channel),\
+	.max_antenna_gain = 0,\
+	.max_power = 30,\
+}
+
 static struct ieee80211_channel __wl_2ghz_channels[] = {
 	CHAN2G(1, 2412), CHAN2G(2, 2417), CHAN2G(3, 2422), CHAN2G(4, 2427),
 	CHAN2G(5, 2432), CHAN2G(6, 2437), CHAN2G(7, 2442), CHAN2G(8, 2447),
@@ -197,6 +206,29 @@ static struct ieee80211_channel __wl_5ghz_channels[] = {
 	CHAN5G(153), CHAN5G(157), CHAN5G(161), CHAN5G(165)
 };
 
+static struct ieee80211_channel __wl_6ghz_channels[] = {
+	CHAN6G(2, 5935), CHAN6G(1, 5955), CHAN6G(5, 5975),
+	CHAN6G(9, 5995), CHAN6G(13, 6015), CHAN6G(17, 6035),
+	CHAN6G(21, 6055), CHAN6G(25, 6075), CHAN6G(29, 6095),
+	CHAN6G(33, 6115), CHAN6G(37, 6135), CHAN6G(41, 6155),
+	CHAN6G(45, 6175), CHAN6G(49, 6195), CHAN6G(53, 6215),
+	CHAN6G(57, 6235), CHAN6G(61, 6255), CHAN6G(65, 6275),
+	CHAN6G(69, 6295), CHAN6G(73, 6315), CHAN6G(77, 6335),
+	CHAN6G(81, 6355), CHAN6G(85, 6375), CHAN6G(89, 6395),
+	CHAN6G(93, 6415), CHAN6G(97, 6435), CHAN6G(101, 6455),
+	CHAN6G(105, 6475), CHAN6G(109, 6495), CHAN6G(113, 6515),
+	CHAN6G(117, 6535), CHAN6G(121, 6555), CHAN6G(125, 6575),
+	CHAN6G(129, 6595), CHAN6G(133, 6615), CHAN6G(137, 6635),
+	CHAN6G(141, 6655), CHAN6G(145, 6675), CHAN6G(149, 6695),
+	CHAN6G(153, 6715), CHAN6G(157, 6735), CHAN6G(161, 6755),
+	CHAN6G(165, 6775), CHAN6G(169, 6795), CHAN6G(173, 6815),
+	CHAN6G(177, 6835), CHAN6G(181, 6855), CHAN6G(185, 6875),
+	CHAN6G(189, 6895), CHAN6G(193, 6915), CHAN6G(197, 6935),
+	CHAN6G(201, 6955), CHAN6G(205, 6975), CHAN6G(209, 6995),
+	CHAN6G(213, 7015), CHAN6G(217, 7035), CHAN6G(221, 7055),
+	CHAN6G(225, 7075), CHAN6G(229, 7095), CHAN6G(233, 7115)
+};
+
 /* Band templates duplicated per wiphy. The channel info
  * above is added to the band during setup.
  */
@@ -212,6 +244,12 @@ static const struct ieee80211_supported_band __wl_band_5ghz = {
 	.n_bitrates = wl_a_rates_size,
 };
 
+static const struct ieee80211_supported_band __wl_band_6ghz = {
+	.band = NL80211_BAND_6GHZ,
+	.bitrates = wl_a_rates,
+	.n_bitrates = wl_a_rates_size,
+};
+
 /* This is to override regulatory domains defined in cfg80211 module (reg.c)
  * By default world regulatory domain defined in reg.c puts the flags
  * NL80211_RRF_NO_IR for 5GHz channels (for * 36..48 and 149..165).
@@ -220,7 +258,7 @@ static const struct ieee80211_supported_band __wl_band_5ghz = {
  * domain are to be done here.
  */
 static const struct ieee80211_regdomain brcmf_regdom = {
-	.n_reg_rules = 4,
+	.n_reg_rules = 5,
 	.alpha2 =  "99",
 	.reg_rules = {
 		/* IEEE 802.11b/g, channels 1..11 */
@@ -233,7 +271,9 @@ static const struct ieee80211_regdomain brcmf_regdom = {
 		/* IEEE 802.11a, channel 36..64 */
 		REG_RULE(5150-10, 5350+10, 160, 6, 20, 0),
 		/* IEEE 802.11a, channel 100..165 */
-		REG_RULE(5470-10, 5850+10, 160, 6, 20, 0), }
+		REG_RULE(5470 - 10, 5850 + 10, 160, 6, 20, 0),
+		/* IEEE 802.11ax, 6 GHz */
+		REG_RULE(5935 - 10, 7115 + 10, 160, 6, 20, 0), }
 };
 
 /* Note: brcmf_cipher_suites is an array of int defining which cipher suites
@@ -319,6 +359,8 @@ static u8 nl80211_band_to_fwil(enum nl80211_band band)
 		return WLC_BAND_2G;
 	case NL80211_BAND_5GHZ:
 		return WLC_BAND_5G;
+	case NL80211_BAND_6GHZ:
+		return WLC_BAND_6G;
 	default:
 		WARN_ON(1);
 		break;
@@ -341,6 +383,18 @@ static u8 nl80211_band_to_chanspec_band(enum nl80211_band band)
 	}
 }
 
+static enum nl80211_band chanspec_band_to_nl80211(u8 band)
+{
+	switch (band) {
+	case BRCMU_CHAN_BAND_6G:
+		return NL80211_BAND_6GHZ;
+	case BRCMU_CHAN_BAND_5G:
+		return NL80211_BAND_5GHZ;
+	default:
+		return NL80211_BAND_2GHZ;
+	}
+}
+
 static u16 chandef_to_chanspec(struct brcmu_d11inf *d11inf,
 			       struct cfg80211_chan_def *ch)
 {
@@ -3347,7 +3401,9 @@ static bool brcmf_chanspec_supported(struct brcmf_cfg80211_info *cfg, u16 chansp
 		return true;
 
 	return band == BRCMU_CHSPEC_D11AC_BND_2G ||
-	       band == BRCMU_CHSPEC_D11AC_BND_5G;
+	       band == BRCMU_CHSPEC_D11AC_BND_5G ||
+	       (band == BRCMU_CHSPEC_D11AC_BND_6G &&
+		cfg_to_wiphy(cfg)->bands[NL80211_BAND_6GHZ]);
 }
 
 static s32 brcmf_inform_single_bss(struct brcmf_cfg80211_info *cfg,
@@ -3374,20 +3430,17 @@ static s32 brcmf_inform_single_bss(struct brcmf_cfg80211_info *cfg,
 	if (!brcmf_chanspec_supported(cfg, le16_to_cpu(bi->chanspec)))
 		return 0;
 
-	if (!bi->ctl_ch) {
-		ch.chspec = le16_to_cpu(bi->chanspec);
-		cfg->d11inf.decchspec(&ch);
+	ch.chspec = le16_to_cpu(bi->chanspec);
+	cfg->d11inf.decchspec(&ch);
+	if (!bi->ctl_ch)
 		bi->ctl_ch = ch.control_ch_num;
-	}
 	channel = bi->ctl_ch;
-
-	if (channel <= CH_MAX_2G_CHANNEL)
-		band = NL80211_BAND_2GHZ;
-	else
-		band = NL80211_BAND_5GHZ;
+	band = chanspec_band_to_nl80211(ch.band);
 
 	freq = ieee80211_channel_to_frequency(channel, band);
 	bss_data.chan = ieee80211_get_channel(wiphy, freq);
+	if (!bss_data.chan)
+		return 0;
 	bss_data.boottime_ns = ktime_to_ns(ktime_get_boottime());
 
 	notify_capability = le16_to_cpu(bi->capability);
@@ -3459,7 +3512,7 @@ static s32 brcmf_inform_ibss(struct brcmf_cfg80211_info *cfg,
 	struct brcmf_pub *drvr = cfg->pub;
 	struct ieee80211_channel *notify_channel;
 	struct brcmf_bss_info_le *bi = NULL;
-	struct ieee80211_supported_band *band;
+	enum nl80211_band band;
 	struct cfg80211_bss *bss;
 	struct brcmu_chan ch;
 	u8 *buf = NULL;
@@ -3493,12 +3546,9 @@ static s32 brcmf_inform_ibss(struct brcmf_cfg80211_info *cfg,
 	ch.chspec = le16_to_cpu(bi->chanspec);
 	cfg->d11inf.decchspec(&ch);
 
-	if (ch.band == BRCMU_CHAN_BAND_2G)
-		band = wiphy->bands[NL80211_BAND_2GHZ];
-	else
-		band = wiphy->bands[NL80211_BAND_5GHZ];
+	band = chanspec_band_to_nl80211(ch.band);
 
-	freq = ieee80211_channel_to_frequency(ch.control_ch_num, band->band);
+	freq = ieee80211_channel_to_frequency(ch.control_ch_num, band);
 	cfg->channel = freq;
 	notify_channel = ieee80211_get_channel(wiphy, freq);
 
@@ -5843,6 +5893,9 @@ static int brcmf_cfg80211_get_channel(struct wiphy *wiphy,
 	case BRCMU_CHAN_BAND_5G:
 		band = NL80211_BAND_5GHZ;
 		break;
+	case BRCMU_CHAN_BAND_6G:
+		band = NL80211_BAND_6GHZ;
+		break;
 	}
 
 	switch (ch.bw) {
@@ -6563,7 +6616,7 @@ brcmf_bss_roaming_done(struct brcmf_cfg80211_info *cfg,
 	struct brcmf_cfg80211_connect_info *conn_info = cfg_to_conn(cfg);
 	struct wiphy *wiphy = cfg_to_wiphy(cfg);
 	struct ieee80211_channel *notify_channel = NULL;
-	struct ieee80211_supported_band *band;
+	enum nl80211_band band;
 	struct brcmf_bss_info_le *bi;
 	struct brcmu_chan ch;
 	struct cfg80211_roam_info roam_info = {};
@@ -6596,12 +6649,9 @@ brcmf_bss_roaming_done(struct brcmf_cfg80211_info *cfg,
 	ch.chspec = le16_to_cpu(bi->chanspec);
 	cfg->d11inf.decchspec(&ch);
 
-	if (ch.band == BRCMU_CHAN_BAND_2G)
-		band = wiphy->bands[NL80211_BAND_2GHZ];
-	else
-		band = wiphy->bands[NL80211_BAND_5GHZ];
+	band = chanspec_band_to_nl80211(ch.band);
 
-	freq = ieee80211_channel_to_frequency(ch.control_ch_num, band->band);
+	freq = ieee80211_channel_to_frequency(ch.control_ch_num, band);
 	notify_channel = ieee80211_get_channel(wiphy, freq);
 
 done:
@@ -7207,6 +7257,10 @@ static int brcmf_construct_chaninfo(struct brcmf_cfg80211_info *cfg,
 		for (i = 0; i < band->n_channels; i++)
 			band->channels[i].flags = IEEE80211_CHAN_DISABLED;
 	band = wiphy->bands[NL80211_BAND_5GHZ];
+	if (band)
+		for (i = 0; i < band->n_channels; i++)
+			band->channels[i].flags = IEEE80211_CHAN_DISABLED;
+	band = wiphy->bands[NL80211_BAND_6GHZ];
 	if (band)
 		for (i = 0; i < band->n_channels; i++)
 			band->channels[i].flags = IEEE80211_CHAN_DISABLED;
@@ -7229,6 +7283,8 @@ static int brcmf_construct_chaninfo(struct brcmf_cfg80211_info *cfg,
 			band = wiphy->bands[NL80211_BAND_2GHZ];
 		} else if (ch.band == BRCMU_CHAN_BAND_5G) {
 			band = wiphy->bands[NL80211_BAND_5GHZ];
+		} else if (ch.band == BRCMU_CHAN_BAND_6G) {
+			band = wiphy->bands[NL80211_BAND_6GHZ];
 		} else {
 			bphy_err(drvr, "Invalid channel Spec. 0x%x.\n",
 				 ch.chspec);
@@ -7406,11 +7462,17 @@ static void brcmf_get_bwcap(struct brcmf_if *ifp, u32 bw_cap[])
 		bw_cap[NL80211_BAND_2GHZ] = band;
 		band = WLC_BAND_5G;
 		err = brcmf_fil_iovar_int_query(ifp, "bw_cap", &band);
-		if (!err) {
-			bw_cap[NL80211_BAND_5GHZ] = band;
+		if (err) {
+			WARN_ON(1);
 			return;
 		}
-		WARN_ON(1);
+		bw_cap[NL80211_BAND_5GHZ] = band;
+		if (!ifp->drvr->wiphy->bands[NL80211_BAND_6GHZ])
+			return;
+		band = WLC_BAND_6G;
+		err = brcmf_fil_iovar_int_query(ifp, "bw_cap", &band);
+		if (!err)
+			bw_cap[NL80211_BAND_6GHZ] = band;
 		return;
 	}
 	brcmf_dbg(INFO, "fallback to mimo_bw_cap info\n");
@@ -7436,7 +7498,7 @@ static void brcmf_get_bwcap(struct brcmf_if *ifp, u32 bw_cap[])
 }
 
 static void brcmf_update_ht_cap(struct ieee80211_supported_band *band,
-				u32 bw_cap[2], u32 nchain)
+				u32 bw_cap[], u32 nchain)
 {
 	band->ht_cap.ht_supported = true;
 	if (bw_cap[band->band] & WLC_BW_40MHZ_BIT) {
@@ -7463,7 +7525,7 @@ static __le16 brcmf_get_mcs_map(u32 nchain, int supp)
 }
 
 static void brcmf_update_vht_cap(struct ieee80211_supported_band *band,
-				 u32 bw_cap[2], u32 nchain, u32 txstreams,
+				 u32 bw_cap[], u32 nchain, u32 txstreams,
 				 u32 txbf_bfe_cap, u32 txbf_bfr_cap)
 {
 	__le16 mcs_map;
@@ -7595,6 +7657,18 @@ static void brcmf_update_he_cap(struct ieee80211_supported_band *band,
 		mcs->tx_mcs_160 = cpu_to_le16(0xffff);
 	}
 
+	if (band->band == NL80211_BAND_6GHZ) {
+		u16 capa;
+
+		capa = FIELD_PREP(IEEE80211_HE_6GHZ_CAP_MIN_MPDU_START,
+				  IEEE80211_HT_MPDU_DENSITY_8) |
+		       FIELD_PREP(IEEE80211_HE_6GHZ_CAP_MAX_AMPDU_LEN_EXP,
+				  IEEE80211_VHT_MAX_AMPDU_1024K) |
+		       FIELD_PREP(IEEE80211_HE_6GHZ_CAP_MAX_MPDU_LEN,
+				  IEEE80211_VHT_CAP_MAX_MPDU_LENGTH_11454);
+		data->he_6ghz_capa.capa = cpu_to_le16(capa);
+	}
+
 	band->n_iftype_data = 1;
 	band->iftype_data = data;
 }
@@ -7617,7 +7691,11 @@ static int brcmf_setup_wiphybands(struct brcmf_cfg80211_info *cfg)
 	struct wiphy *wiphy = cfg_to_wiphy(cfg);
 	u32 nmode;
 	u32 vhtmode = 0;
-	u32 bw_cap[2] = { WLC_BW_20MHZ_BIT, WLC_BW_20MHZ_BIT };
+	u32 bw_cap[NUM_NL80211_BANDS] = {
+		[NL80211_BAND_2GHZ] = WLC_BW_20MHZ_BIT,
+		[NL80211_BAND_5GHZ] = WLC_BW_20MHZ_BIT,
+		[NL80211_BAND_6GHZ] = WLC_BW_20MHZ_BIT,
+	};
 	u32 rxchain;
 	u32 nchain;
 	int err;
@@ -7636,9 +7714,9 @@ static int brcmf_setup_wiphybands(struct brcmf_cfg80211_info *cfg)
 	} else {
 		brcmf_get_bwcap(ifp, bw_cap);
 	}
-	brcmf_dbg(INFO, "nmode=%d, vhtmode=%d, bw_cap=(%d, %d)\n",
+	brcmf_dbg(INFO, "nmode=%d, vhtmode=%d, bw_cap=(%d, %d, %d)\n",
 		  nmode, vhtmode, bw_cap[NL80211_BAND_2GHZ],
-		  bw_cap[NL80211_BAND_5GHZ]);
+		  bw_cap[NL80211_BAND_5GHZ], bw_cap[NL80211_BAND_6GHZ]);
 
 	err = brcmf_fil_iovar_int_get(ifp, "rxchain", &rxchain);
 	if (err) {
@@ -7674,11 +7752,14 @@ static int brcmf_setup_wiphybands(struct brcmf_cfg80211_info *cfg)
 		if (band == NULL)
 			continue;
 
-		if (nmode)
-			brcmf_update_ht_cap(band, bw_cap, nchain);
-		if (vhtmode)
-			brcmf_update_vht_cap(band, bw_cap, nchain, txstreams,
-					     txbf_bfe_cap, txbf_bfr_cap);
+		if (band->band != NL80211_BAND_6GHZ) {
+			if (nmode)
+				brcmf_update_ht_cap(band, bw_cap, nchain);
+			if (vhtmode)
+				brcmf_update_vht_cap(band, bw_cap, nchain,
+						     txstreams, txbf_bfe_cap,
+						     txbf_bfr_cap);
+		}
 		if (he_enable)
 			brcmf_update_he_cap(band, &cfg->he_iftype_data[i],
 					    bw_cap, nchain);
@@ -7928,6 +8009,27 @@ static void brcmf_wiphy_wowl_params(struct wiphy *wiphy, struct brcmf_if *ifp)
 #endif
 }
 
+static struct ieee80211_supported_band *
+brcmf_alloc_band(const struct ieee80211_supported_band *tmpl,
+		 const struct ieee80211_channel *channels, size_t n_channels)
+{
+	struct ieee80211_supported_band *band;
+
+	band = kmemdup(tmpl, sizeof(*tmpl), GFP_KERNEL);
+	if (!band)
+		return NULL;
+
+	band->channels = kmemdup(channels, n_channels * sizeof(*channels),
+				 GFP_KERNEL);
+	if (!band->channels) {
+		kfree(band);
+		return NULL;
+	}
+	band->n_channels = n_channels;
+
+	return band;
+}
+
 static int brcmf_setup_wiphy(struct wiphy *wiphy, struct brcmf_if *ifp)
 {
 	struct brcmf_pub *drvr = ifp->drvr;
@@ -8041,41 +8143,36 @@ static int brcmf_setup_wiphy(struct wiphy *wiphy, struct brcmf_if *ifp)
 			if (wiphy->bands[NL80211_BAND_2GHZ])
 				break;
 
-			band = kmemdup(&__wl_band_2ghz, sizeof(__wl_band_2ghz),
-				       GFP_KERNEL);
+			band = brcmf_alloc_band(&__wl_band_2ghz,
+						__wl_2ghz_channels,
+						ARRAY_SIZE(__wl_2ghz_channels));
 			if (!band)
 				return -ENOMEM;
-
-			band->channels = kmemdup(&__wl_2ghz_channels,
-						 sizeof(__wl_2ghz_channels),
-						 GFP_KERNEL);
-			if (!band->channels) {
-				kfree(band);
-				return -ENOMEM;
-			}
-
-			band->n_channels = ARRAY_SIZE(__wl_2ghz_channels);
 			wiphy->bands[NL80211_BAND_2GHZ] = band;
 			break;
 		case WLC_BAND_5G:
 			if (wiphy->bands[NL80211_BAND_5GHZ])
 				break;
 
-			band = kmemdup(&__wl_band_5ghz, sizeof(__wl_band_5ghz),
-				       GFP_KERNEL);
+			band = brcmf_alloc_band(&__wl_band_5ghz,
+						__wl_5ghz_channels,
+						ARRAY_SIZE(__wl_5ghz_channels));
 			if (!band)
 				return -ENOMEM;
+			wiphy->bands[NL80211_BAND_5GHZ] = band;
+			break;
+		case WLC_BAND_6G:
+			/* cfg80211 requires HE on the 6 GHz band */
+			if (wiphy->bands[NL80211_BAND_6GHZ] ||
+			    !brcmf_he_enabled(ifp))
+				break;
 
-			band->channels = kmemdup(&__wl_5ghz_channels,
-						 sizeof(__wl_5ghz_channels),
-						 GFP_KERNEL);
-			if (!band->channels) {
-				kfree(band);
+			band = brcmf_alloc_band(&__wl_band_6ghz,
+						__wl_6ghz_channels,
+						ARRAY_SIZE(__wl_6ghz_channels));
+			if (!band)
 				return -ENOMEM;
-			}
-
-			band->n_channels = ARRAY_SIZE(__wl_5ghz_channels);
-			wiphy->bands[NL80211_BAND_5GHZ] = band;
+			wiphy->bands[NL80211_BAND_6GHZ] = band;
 			break;
 		default:
 			brcmf_dbg(INFO, "ignoring unsupported band %u\n",
@@ -8610,13 +8707,11 @@ static void brcmf_free_wiphy(struct wiphy *wiphy)
 			kfree(wiphy->iface_combinations[i].limits);
 	}
 	kfree(wiphy->iface_combinations);
-	if (wiphy->bands[NL80211_BAND_2GHZ]) {
-		kfree(wiphy->bands[NL80211_BAND_2GHZ]->channels);
-		kfree(wiphy->bands[NL80211_BAND_2GHZ]);
-	}
-	if (wiphy->bands[NL80211_BAND_5GHZ]) {
-		kfree(wiphy->bands[NL80211_BAND_5GHZ]->channels);
-		kfree(wiphy->bands[NL80211_BAND_5GHZ]);
+	for (i = 0; i < NUM_NL80211_BANDS; i++) {
+		if (!wiphy->bands[i])
+			continue;
+		kfree(wiphy->bands[i]->channels);
+		kfree(wiphy->bands[i]);
 	}
 #if IS_ENABLED(CONFIG_PM)
 	if (wiphy->wowlan != &brcmf_wowlan_support)
diff --git a/drivers/net/wireless/broadcom/brcm80211/brcmfmac/pno.c b/drivers/net/wireless/broadcom/brcm80211/brcmfmac/pno.c
index d9fc94076791..ba62ab41bae1 100644
--- a/drivers/net/wireless/broadcom/brcm80211/brcmfmac/pno.c
+++ b/drivers/net/wireless/broadcom/brcm80211/brcmfmac/pno.c
@@ -278,6 +278,9 @@ static int brcmf_pno_get_bucket_channels(struct cfg80211_sched_scan_request *r,
 	int i, err = 0;
 
 	for (i = 0; i < r->n_channels; i++) {
+		/* bare channel numbers cannot identify 6 GHz channels */
+		if (r->channels[i]->band == NL80211_BAND_6GHZ)
+			continue;
 		if (n_chan >= BRCMF_NUMCHANNELS) {
 			err = -ENOSPC;
 			goto done;
diff --git a/drivers/net/wireless/broadcom/brcm80211/include/brcmu_wifi.h b/drivers/net/wireless/broadcom/brcm80211/include/brcmu_wifi.h
index c465208c4331..aa692dcc00d6 100644
--- a/drivers/net/wireless/broadcom/brcm80211/include/brcmu_wifi.h
+++ b/drivers/net/wireless/broadcom/brcm80211/include/brcmu_wifi.h
@@ -93,6 +93,7 @@
 #define	WLC_BAND_5G			1	/* 5 Ghz */
 #define	WLC_BAND_2G			2	/* 2.4 Ghz */
 #define	WLC_BAND_ALL			3	/* all bands */
+#define	WLC_BAND_6G			4	/* 6 Ghz */
 
 #define CHSPEC_CHANNEL(chspec)	((u8)((chspec) & WL_CHANSPEC_CHAN_MASK))
 #define CHSPEC_BAND(chspec)	((chspec) & WL_CHANSPEC_BAND_MASK)

-- 
2.56.0

