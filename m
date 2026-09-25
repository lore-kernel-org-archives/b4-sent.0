From: Michael Reeves <michael.reeves077@gmail.com>
Date: Fri, 25 Sep 2026 23:43:46 +1000
Subject: [PATCH 11/13] wifi: brcmfmac: Support versioned join requests
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260925-brcm4388-submit-v1-11-b5cbc2cde2fb@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790343821; l=8739;
 i=michael.reeves077@gmail.com; s=fedora-20260918; h=from:subject:message-id;
 bh=H6797bY15elnibBmCMfbZQ0bGQ2izjOuvFhiXJumwdk=;
 b=aa8235GZxSH6+3DblDqDiEtA4DMuDOLiGStlCsNCzIMGBZXcajwnX2Cl5vzXq8aGlSpDfcLHQ
 swv1HZZ3OoeD+unQ/uoiFyUq5lSkZCWaUlshUHDCYxM6BzYrlCjpDY9
X-Developer-Key: i=michael.reeves077@gmail.com; a=ed25519;
 pk=VJ0TvyQ9TvfzYZa908YSE9kpkjFLLD5luv0bERu+boc=
X-Endpoint-Received: by B4 Relay for michael.reeves077@gmail.com/fedora-20260918 with auth_id=1035
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Hector Martin <marcan@marcan.st>

Newer firmware uses version 1 join and association structures with
explicit version headers.

Query join_ver and build version 1 requests when required. Retain legacy
layouts for older firmware and fall back to BRCMF_C_SET_SSID when the
join iovar returns -EBADE. Use the selected association layout for IBSS
joins too. Report unsupported join versions rather than guessing their
request layout.

Signed-off-by: Hector Martin <marcan@marcan.st>
Signed-off-by: Daniel Berlin <dberlin@dberlin.org>
Co-developed-by: Michael Reeves <michael.reeves077@gmail.com>
Signed-off-by: Michael Reeves <michael.reeves077@gmail.com>
---
 .../broadcom/brcm80211/brcmfmac/cfg80211.c         | 73 +++++++++++++++++++---
 .../wireless/broadcom/brcm80211/brcmfmac/core.h    |  1 +
 .../wireless/broadcom/brcm80211/brcmfmac/feature.c | 19 ++++++
 .../broadcom/brcm80211/brcmfmac/fwil_types.h       | 29 +++++++++
 4 files changed, 113 insertions(+), 9 deletions(-)

diff --git a/drivers/net/wireless/broadcom/brcm80211/brcmfmac/cfg80211.c b/drivers/net/wireless/broadcom/brcm80211/brcmfmac/cfg80211.c
index 2ce7041be6..2a742ae8cc 100644
--- a/drivers/net/wireless/broadcom/brcm80211/brcmfmac/cfg80211.c
+++ b/drivers/net/wireless/broadcom/brcm80211/brcmfmac/cfg80211.c
@@ -1653,6 +1653,36 @@ static void brcmf_link_down(struct brcmf_cfg80211_vif *vif, u16 reason,
 	brcmf_dbg(TRACE, "Exit\n");
 }
 
+static int brcmf_set_ssid(struct brcmf_if *ifp,
+			  const struct brcmf_join_params *legacy, size_t legacy_size)
+{
+	struct brcmf_join_params_v1_le *params;
+	u32 count = le32_to_cpu(legacy->params_le.chanspec_num);
+	size_t size;
+	int err;
+
+	if (!ifp->drvr->join_version)
+		return brcmf_fil_cmd_data_set(ifp, BRCMF_C_SET_SSID,
+					     (void *)legacy, legacy_size);
+	if (ifp->drvr->join_version != 1)
+		return -EOPNOTSUPP;
+
+	size = struct_size(params, assoc_le.chanspec_list, count);
+	params = kzalloc(size, GFP_KERNEL);
+	if (!params)
+		return -ENOMEM;
+
+	params->ssid_le = legacy->ssid_le;
+	params->assoc_le.version = cpu_to_le16(1);
+	ether_addr_copy(params->assoc_le.bssid, legacy->params_le.bssid);
+	params->assoc_le.chanspec_num = legacy->params_le.chanspec_num;
+	memcpy(params->assoc_le.chanspec_list, legacy->params_le.chanspec_list,
+	       count * sizeof(__le16));
+	err = brcmf_fil_cmd_data_set(ifp, BRCMF_C_SET_SSID, params, size);
+	kfree(params);
+	return err;
+}
+
 static s32
 brcmf_cfg80211_join_ibss(struct wiphy *wiphy, struct net_device *ndev,
 		      struct cfg80211_ibss_params *params)
@@ -1791,8 +1821,7 @@ brcmf_cfg80211_join_ibss(struct wiphy *wiphy, struct net_device *ndev,
 	cfg->ibss_starter = false;
 
 
-	err = brcmf_fil_cmd_data_set(ifp, BRCMF_C_SET_SSID,
-				     &join_params, join_params_size);
+	err = brcmf_set_ssid(ifp, &join_params, join_params_size);
 	if (err) {
 		bphy_err(drvr, "WLC_SET_SSID failed (%d)\n", err);
 		goto done;
@@ -2281,6 +2310,30 @@ static void brcmf_set_join_pref(struct brcmf_if *ifp,
 		bphy_err(drvr, "Set join_pref error (%d)\n", err);
 }
 
+static int brcmf_join_v1(struct brcmf_if *ifp,
+			 const struct brcmf_ext_join_params_le *legacy)
+{
+	struct brcmf_ext_join_params_v1_le *params;
+	u32 count = le32_to_cpu(legacy->assoc_le.chanspec_num);
+	size_t size = struct_size(params, assoc_le.chanspec_list, count);
+	int err;
+
+	params = kzalloc(size, GFP_KERNEL);
+	if (!params)
+		return -ENOMEM;
+	params->version = cpu_to_le16(1);
+	params->ssid_le = legacy->ssid_le;
+	params->scan_le = legacy->scan_le;
+	params->assoc_le.version = cpu_to_le16(1);
+	ether_addr_copy(params->assoc_le.bssid, legacy->assoc_le.bssid);
+	params->assoc_le.chanspec_num = legacy->assoc_le.chanspec_num;
+	memcpy(params->assoc_le.chanspec_list, legacy->assoc_le.chanspec_list,
+	       count * sizeof(__le16));
+	err = brcmf_fil_bsscfg_data_set(ifp, "join", params, size);
+	kfree(params);
+	return err;
+}
+
 static s32
 brcmf_cfg80211_connect(struct wiphy *wiphy, struct net_device *ndev,
 		       struct cfg80211_connect_params *sme)
@@ -2302,6 +2355,8 @@ brcmf_cfg80211_connect(struct wiphy *wiphy, struct net_device *ndev,
 	u32 ssid_len;
 
 	brcmf_dbg(TRACE, "Enter\n");
+	if (drvr->join_version > 1)
+		return -EOPNOTSUPP;
 	if (!check_vif_up(ifp->vif))
 		return -EIO;
 
@@ -2492,14 +2547,15 @@ brcmf_cfg80211_connect(struct wiphy *wiphy, struct net_device *ndev,
 
 	brcmf_set_join_pref(ifp, &sme->bss_select);
 
-	err  = brcmf_fil_bsscfg_data_set(ifp, "join", ext_join_params,
-					 join_params_size);
+	if (ifp->drvr->join_version == 1)
+		err = brcmf_join_v1(ifp, ext_join_params);
+	else
+		err = brcmf_fil_bsscfg_data_set(ifp, "join", ext_join_params,
+						join_params_size);
 	kfree(ext_join_params);
-	if (!err)
-		/* This is it. join command worked, we are done */
+	if (err != -EBADE)
 		goto done;
 
-	/* join command failed, fallback to set ssid */
 	memset(&join_params, 0, sizeof(join_params));
 	join_params_size = sizeof(join_params.ssid_le);
 
@@ -2516,8 +2572,7 @@ brcmf_cfg80211_connect(struct wiphy *wiphy, struct net_device *ndev,
 		join_params.params_le.chanspec_num = cpu_to_le32(1);
 		join_params_size += sizeof(join_params.params_le);
 	}
-	err = brcmf_fil_cmd_data_set(ifp, BRCMF_C_SET_SSID,
-				     &join_params, join_params_size);
+	err = brcmf_set_ssid(ifp, &join_params, join_params_size);
 	if (err)
 		bphy_err(drvr, "BRCMF_C_SET_SSID failed (%d)\n", err);
 
diff --git a/drivers/net/wireless/broadcom/brcm80211/brcmfmac/core.h b/drivers/net/wireless/broadcom/brcm80211/brcmfmac/core.h
index fe909f7add..320473970d 100644
--- a/drivers/net/wireless/broadcom/brcm80211/brcmfmac/core.h
+++ b/drivers/net/wireless/broadcom/brcm80211/brcmfmac/core.h
@@ -162,6 +162,7 @@ struct brcmf_pub {
 	const struct brcmf_fwvid_ops *vops;
 	void *vdata;
 	struct scan_param_struct_handler scan_param_handler;
+	u16 join_version;
 };
 
 /* forward declarations */
diff --git a/drivers/net/wireless/broadcom/brcm80211/brcmfmac/feature.c b/drivers/net/wireless/broadcom/brcm80211/brcmfmac/feature.c
index 44c0082e21..27fa3a7941 100644
--- a/drivers/net/wireless/broadcom/brcm80211/brcmfmac/feature.c
+++ b/drivers/net/wireless/broadcom/brcm80211/brcmfmac/feature.c
@@ -160,6 +160,10 @@ static void brcmf_feat_wlc_version_overrides(struct brcmf_pub *drv)
 
 	brcmf_dbg(INFO, "WLC version: %d.%d\n", major, minor);
 
+	if (major >= 17 || (major == 16 && minor >= 1) ||
+	    (major == 14 && (minor == 2 || minor == 4)))
+		drv->join_version = 1;
+
 	for (i = 0; i < ARRAY_SIZE(brcmf_feat_wlcfeat_map); i++) {
 		e = &brcmf_feat_wlcfeat_map[i];
 		if (major > e->min_ver_major ||
@@ -297,6 +301,20 @@ static void brcmf_feat_firmware_capabilities(struct brcmf_if *ifp)
 	}
 }
 
+static void brcmf_feat_join_params(struct brcmf_if *ifp)
+{
+	struct brcmf_join_version_le version = {};
+	int err;
+
+	err = brcmf_fil_iovar_data_get(ifp, "join_ver", &version,
+				       sizeof(version));
+	if (!err)
+		ifp->drvr->join_version = le16_to_cpu(version.major);
+	if (ifp->drvr->join_version > 1)
+		bphy_err(ifp->drvr, "unsupported join params v%u\n",
+			 ifp->drvr->join_version);
+}
+
 static void brcmf_feat_scan_params(struct brcmf_if *ifp)
 {
 	struct brcmf_pub *drvr = ifp->drvr;
@@ -430,6 +448,7 @@ void brcmf_feat_attach(struct brcmf_pub *drvr)
 	brcmf_feat_event_msgs_ext(ifp);
 
 	brcmf_feat_wlc_version_overrides(drvr);
+	brcmf_feat_join_params(ifp);
 	brcmf_feat_firmware_overrides(drvr);
 
 	brcmf_fwvid_feat_attach(ifp);
diff --git a/drivers/net/wireless/broadcom/brcm80211/brcmfmac/fwil_types.h b/drivers/net/wireless/broadcom/brcm80211/brcmfmac/fwil_types.h
index dbba883bba..917966ad70 100644
--- a/drivers/net/wireless/broadcom/brcm80211/brcmfmac/fwil_types.h
+++ b/drivers/net/wireless/broadcom/brcm80211/brcmfmac/fwil_types.h
@@ -584,6 +584,35 @@ struct brcmf_ext_join_params_le {
 	struct brcmf_assoc_params_le assoc_le;
 };
 
+struct brcmf_assoc_params_v1_le {
+	__le16 version;
+	__le16 flags;
+	u8 bssid[ETH_ALEN];
+	__le16 bssid_cnt;
+	__le32 chanspec_num;
+	__le16 chanspec_list[];
+};
+
+struct brcmf_join_params_v1_le {
+	struct brcmf_ssid_le ssid_le;
+	struct brcmf_assoc_params_v1_le assoc_le;
+};
+
+struct brcmf_join_version_le {
+	__le16 version;
+	__le16 length;
+	__le16 major;
+	u8 pad[2];
+};
+
+struct brcmf_ext_join_params_v1_le {
+	__le16 version;
+	__le16 pad;
+	struct brcmf_ssid_le ssid_le;
+	struct brcmf_join_scan_params_le scan_le;
+	struct brcmf_assoc_params_v1_le assoc_le;
+};
+
 struct brcmf_wsec_key {
 	u32 index;		/* key index */
 	u32 len;		/* key length */

-- 
2.55.0

