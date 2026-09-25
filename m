From: Michael Reeves <michael.reeves077@gmail.com>
Date: Fri, 25 Sep 2026 23:43:43 +1000
Subject: [PATCH 08/13] wifi: brcmfmac: Handle larger firmware band lists
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260925-brcm4388-submit-v1-8-b5cbc2cde2fb@gmail.com>
References: <20260925-brcm4388-submit-v1-0-b5cbc2cde2fb@gmail.com>
In-Reply-To: <20260925-brcm4388-submit-v1-0-b5cbc2cde2fb@gmail.com>
To: Arend van Spriel <arend.vanspriel@broadcom.com>, 
 Pieter-Paul Giesberts <pieterpg@broadcom.com>, 
 "Franky Lin (Zhenhui)" <frankyl@broadcom.com>, 
 Mathy Vanhoef <vanhoefm@gmail.com>, Kalle Valo <kvalo@kernel.org>, 
 Kees Cook <kees@kernel.org>, "Gustavo A. R. Silva" <gustavoars@kernel.org>
Cc: linux-wireless@vger.kernel.org, brcm80211@lists.linux.dev, 
 brcm80211-dev-list.pdl@broadcom.com, asahi@lists.linux.dev, 
 Hector Martin <marcan@marcan.st>, Daniel Berlin <dberlin@dberlin.org>, 
 Janne Grunau <j@jannau.net>, linux-kernel@vger.kernel.org, 
 Hante Meuleman <meuleman@broadcom.com>, linux-hardening@vger.kernel.org, 
 Michael Reeves <michael.reeves077@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790343821; l=4262;
 i=michael.reeves077@gmail.com; s=fedora-20260918; h=from:subject:message-id;
 bh=IXCeYSIgceZjWOWc+qsBSG21O04vwQ8LYkrU8gH+GkU=;
 b=hXlnrr95eXuuzDMRikMETKyVXHiWpqmAP8ciWCaTpquP0+ToOPTJ+yASmK8cup3K2FMqEhf2Q
 kCe1B1Fik1LCXrauWdNAB1yZiaNGn90JD/gYPW1/oxXxw4OcvAANqmw
X-Developer-Key: i=michael.reeves077@gmail.com; a=ed25519;
 pk=VJ0TvyQ9TvfzYZa908YSE9kpkjFLLD5luv0bERu+boc=
X-Endpoint-Received: by B4 Relay for michael.reeves077@gmail.com/fedora-20260918 with auth_id=1035
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Some firmware returns more than two entries from BRCMF_C_GET_BANDLIST.
The fixed two-band response buffer cannot accommodate these lists.

Use a larger bounded buffer and register only the 2.4 GHz and 5 GHz
bands handled by this driver path. Ignore duplicate or unknown entries
so they do not prevent wiphy setup. Skip unsupported bands in chanspec
lists and scan results before decoding channels.

Co-developed-by: Hector Martin <marcan@marcan.st>
Signed-off-by: Hector Martin <marcan@marcan.st>
Signed-off-by: Michael Reeves <michael.reeves077@gmail.com>
---
 .../broadcom/brcm80211/brcmfmac/cfg80211.c         | 48 +++++++++++++++++++---
 1 file changed, 43 insertions(+), 5 deletions(-)

diff --git a/drivers/net/wireless/broadcom/brcm80211/brcmfmac/cfg80211.c b/drivers/net/wireless/broadcom/brcm80211/brcmfmac/cfg80211.c
index 9d8ce7bb04..5d99708007 100644
--- a/drivers/net/wireless/broadcom/brcm80211/brcmfmac/cfg80211.c
+++ b/drivers/net/wireless/broadcom/brcm80211/brcmfmac/cfg80211.c
@@ -105,6 +105,8 @@
 #define BRCMF_MAX_CHANSPEC_LIST \
 	(BRCMF_DCMD_MEDLEN / sizeof(__le32) - 1)
 
+#define BRCMF_MAX_BANDLIST_ENTRIES	16
+
 struct brcmf_dump_survey {
 	u32 obss;
 	u32 ibss;
@@ -3385,6 +3387,17 @@ brcmf_cfg80211_set_power_mgmt(struct wiphy *wiphy, struct net_device *ndev,
 	return err;
 }
 
+static bool brcmf_chanspec_supported(struct brcmf_cfg80211_info *cfg, u16 chanspec)
+{
+	u16 band = chanspec & BRCMU_CHSPEC_D11AC_BND_MASK;
+
+	if (cfg->d11inf.io_type != BRCMU_D11AC_IOTYPE)
+		return true;
+
+	return band == BRCMU_CHSPEC_D11AC_BND_2G ||
+	       band == BRCMU_CHSPEC_D11AC_BND_5G;
+}
+
 static s32 brcmf_inform_single_bss(struct brcmf_cfg80211_info *cfg,
 				   struct brcmf_bss_info_le *bi)
 {
@@ -3406,6 +3419,9 @@ static s32 brcmf_inform_single_bss(struct brcmf_cfg80211_info *cfg,
 		return -EINVAL;
 	}
 
+	if (!brcmf_chanspec_supported(cfg, le16_to_cpu(bi->chanspec)))
+		return 0;
+
 	if (!bi->ctl_ch) {
 		ch.chspec = le16_to_cpu(bi->chanspec);
 		cfg->d11inf.decchspec(&ch);
@@ -7163,6 +7179,8 @@ static int brcmf_construct_chaninfo(struct brcmf_cfg80211_info *cfg,
 
 	for (i = 0; i < total; i++) {
 		ch.chspec = (u16)le32_to_cpu(list->element[i]);
+		if (!brcmf_chanspec_supported(cfg, ch.chspec))
+			continue;
 		cfg->d11inf.decchspec(&ch);
 
 		if (ch.band == BRCMU_CHAN_BAND_2G) {
@@ -7764,7 +7782,7 @@ static int brcmf_setup_wiphy(struct wiphy *wiphy, struct brcmf_if *ifp)
 	struct ieee80211_supported_band *band;
 	u16 max_interfaces = 0;
 	bool gscan;
-	__le32 bandlist[3];
+	__le32 bandlist[BRCMF_MAX_BANDLIST_ENTRIES];
 	u32 n_bands;
 	int err, i;
 
@@ -7856,8 +7874,20 @@ static int brcmf_setup_wiphy(struct wiphy *wiphy, struct brcmf_if *ifp)
 	}
 	/* first entry in bandlist is number of bands */
 	n_bands = le32_to_cpu(bandlist[0]);
-	for (i = 1; i <= n_bands && i < ARRAY_SIZE(bandlist); i++) {
-		if (bandlist[i] == cpu_to_le32(WLC_BAND_2G)) {
+	if (n_bands >= ARRAY_SIZE(bandlist)) {
+		brcmf_dbg(INFO, "bandlist count %u exceeds buffer entries %zu\n",
+			  n_bands, ARRAY_SIZE(bandlist) - 1);
+		n_bands = ARRAY_SIZE(bandlist) - 1;
+	}
+
+	for (i = 1; i <= n_bands; i++) {
+		u32 band_id = le32_to_cpu(bandlist[i]);
+
+		switch (band_id) {
+		case WLC_BAND_2G:
+			if (wiphy->bands[NL80211_BAND_2GHZ])
+				break;
+
 			band = kmemdup(&__wl_band_2ghz, sizeof(__wl_band_2ghz),
 				       GFP_KERNEL);
 			if (!band)
@@ -7873,8 +7903,11 @@ static int brcmf_setup_wiphy(struct wiphy *wiphy, struct brcmf_if *ifp)
 
 			band->n_channels = ARRAY_SIZE(__wl_2ghz_channels);
 			wiphy->bands[NL80211_BAND_2GHZ] = band;
-		}
-		if (bandlist[i] == cpu_to_le32(WLC_BAND_5G)) {
+			break;
+		case WLC_BAND_5G:
+			if (wiphy->bands[NL80211_BAND_5GHZ])
+				break;
+
 			band = kmemdup(&__wl_band_5ghz, sizeof(__wl_band_5ghz),
 				       GFP_KERNEL);
 			if (!band)
@@ -7890,6 +7923,11 @@ static int brcmf_setup_wiphy(struct wiphy *wiphy, struct brcmf_if *ifp)
 
 			band->n_channels = ARRAY_SIZE(__wl_5ghz_channels);
 			wiphy->bands[NL80211_BAND_5GHZ] = band;
+			break;
+		default:
+			brcmf_dbg(INFO, "ignoring unsupported band %u\n",
+				  band_id);
+			break;
 		}
 	}
 

-- 
2.55.0

