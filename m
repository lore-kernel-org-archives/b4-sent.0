From: Michael Reeves <michael.reeves077@gmail.com>
Date: Fri, 25 Sep 2026 23:43:45 +1000
Subject: [PATCH 10/13] wifi: brcmfmac: Support versioned scan parameter
 layouts
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260925-brcm4388-submit-v1-10-b5cbc2cde2fb@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790343821; l=30266;
 i=michael.reeves077@gmail.com; s=fedora-20260918; h=from:subject:message-id;
 bh=U/0h17jQAjcBnPxPLbUjuyeLxboMhvD9zmaeLHDNDEk=;
 b=neCsHY630xxa2dmTOT5xG99Nu3pvCOQ0jTcRMb7+F8q1P1hnWrBqJmfHmB3Xgw20XpdzHcwlF
 TYrPBlXeQVSAxd+gARaYLwvAJSbRS1+y3a7Jiyt+qaHMCVMSNnzWexC
X-Developer-Key: i=michael.reeves077@gmail.com; a=ed25519;
 pk=VJ0TvyQ9TvfzYZa908YSE9kpkjFLLD5luv0bERu+boc=
X-Endpoint-Received: by B4 Relay for michael.reeves077@gmail.com/fedora-20260918 with auth_id=1035
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Daniel Berlin <dberlin@dberlin.org>

Newer firmware uses scan parameter layouts with version headers, wider
scan flags, and additional fields. Requests must match the layout
expected by firmware.

Select builders for versions 1 through 4 from the scan_ver response and
use the selected layout for both scan requests and aborts. Fall back to
version 1 when version discovery is unavailable.

Signed-off-by: Daniel Berlin <dberlin@dberlin.org>
Co-developed-by: Hector Martin <marcan@marcan.st>
Signed-off-by: Hector Martin <marcan@marcan.st>
Co-developed-by: Michael Reeves <michael.reeves077@gmail.com>
Signed-off-by: Michael Reeves <michael.reeves077@gmail.com>
---
 .../wireless/broadcom/brcm80211/brcmfmac/Makefile  |   1 +
 .../broadcom/brcm80211/brcmfmac/cfg80211.c         | 203 ++--------
 .../wireless/broadcom/brcm80211/brcmfmac/core.h    |  17 +
 .../wireless/broadcom/brcm80211/brcmfmac/feature.c |  46 ++-
 .../broadcom/brcm80211/brcmfmac/fwil_types.h       |  65 ++++
 .../broadcom/brcm80211/brcmfmac/scan_param.c       | 416 +++++++++++++++++++++
 .../broadcom/brcm80211/brcmfmac/scan_param.h       |  13 +
 7 files changed, 594 insertions(+), 167 deletions(-)

diff --git a/drivers/net/wireless/broadcom/brcm80211/brcmfmac/Makefile b/drivers/net/wireless/broadcom/brcm80211/brcmfmac/Makefile
index e5ca0f5118..5281922867 100644
--- a/drivers/net/wireless/broadcom/brcm80211/brcmfmac/Makefile
+++ b/drivers/net/wireless/broadcom/brcm80211/brcmfmac/Makefile
@@ -25,6 +25,7 @@ brcmfmac-objs += \
 		btcoex.o \
 		vendor.o \
 		pno.o \
+		scan_param.o \
 		xtlv.o
 brcmfmac-$(CONFIG_BRCMFMAC_PROTO_BCDC) += \
 		bcdc.o \
diff --git a/drivers/net/wireless/broadcom/brcm80211/brcmfmac/cfg80211.c b/drivers/net/wireless/broadcom/brcm80211/brcmfmac/cfg80211.c
index 4f1768c8bb..2ce7041be6 100644
--- a/drivers/net/wireless/broadcom/brcm80211/brcmfmac/cfg80211.c
+++ b/drivers/net/wireless/broadcom/brcm80211/brcmfmac/cfg80211.c
@@ -1061,134 +1061,11 @@ bool brcmf_is_apmode_operating(struct wiphy *wiphy)
 	return ret;
 }
 
-static void brcmf_scan_params_v2_to_v1(struct brcmf_scan_params_v2_le *params_v2_le,
-				       struct brcmf_scan_params_le *params_le)
-{
-	size_t params_size;
-	u32 ch;
-	int n_channels, n_ssids;
-
-	memcpy(&params_le->ssid_le, &params_v2_le->ssid_le,
-	       sizeof(params_le->ssid_le));
-	memcpy(&params_le->bssid, &params_v2_le->bssid,
-	       sizeof(params_le->bssid));
-
-	params_le->bss_type = params_v2_le->bss_type;
-	params_le->scan_type = le32_to_cpu(params_v2_le->scan_type);
-	params_le->nprobes = params_v2_le->nprobes;
-	params_le->active_time = params_v2_le->active_time;
-	params_le->passive_time = params_v2_le->passive_time;
-	params_le->home_time = params_v2_le->home_time;
-	params_le->channel_num = params_v2_le->channel_num;
-
-	ch = le32_to_cpu(params_v2_le->channel_num);
-	n_channels = ch & BRCMF_SCAN_PARAMS_COUNT_MASK;
-	n_ssids = ch >> BRCMF_SCAN_PARAMS_NSSID_SHIFT;
-
-	params_size = sizeof(u16) * n_channels;
-	if (n_ssids > 0) {
-		params_size = roundup(params_size, sizeof(u32));
-		params_size += sizeof(struct brcmf_ssid_le) * n_ssids;
-	}
-
-	memcpy(&params_le->channel_list[0],
-	       &params_v2_le->channel_list[0], params_size);
-}
-
-static void brcmf_escan_prep(struct brcmf_cfg80211_info *cfg,
-			     struct brcmf_scan_params_v2_le *params_le,
-			     struct cfg80211_scan_request *request)
-{
-	u32 n_ssids;
-	u32 n_channels;
-	s32 i;
-	s32 offset;
-	u16 chanspec;
-	char *ptr;
-	int length;
-	struct brcmf_ssid_le ssid_le;
-
-	eth_broadcast_addr(params_le->bssid);
-
-	length = BRCMF_SCAN_PARAMS_V2_FIXED_SIZE;
-
-	params_le->version = cpu_to_le16(BRCMF_SCAN_PARAMS_VERSION_V2);
-	params_le->bss_type = DOT11_BSSTYPE_ANY;
-	params_le->scan_type = cpu_to_le32(BRCMF_SCANTYPE_ACTIVE);
-	params_le->channel_num = 0;
-	params_le->nprobes = cpu_to_le32(-1);
-	params_le->active_time = cpu_to_le32(-1);
-	params_le->passive_time = cpu_to_le32(-1);
-	params_le->home_time = cpu_to_le32(-1);
-	memset(&params_le->ssid_le, 0, sizeof(params_le->ssid_le));
-
-	/* Scan abort */
-	if (!request) {
-		length += sizeof(u16);
-		params_le->channel_num = cpu_to_le32(1);
-		params_le->channel_list[0] = cpu_to_le16(-1);
-		params_le->length = cpu_to_le16(length);
-		return;
-	}
-
-	n_ssids = request->n_ssids;
-	n_channels = request->n_channels;
-
-	/* Copy channel array if applicable */
-	brcmf_dbg(SCAN, "### List of channelspecs to scan ### %d\n",
-		  n_channels);
-	if (n_channels > 0) {
-		length += roundup(sizeof(u16) * n_channels, sizeof(u32));
-		for (i = 0; i < n_channels; i++) {
-			chanspec = channel_to_chanspec(&cfg->d11inf,
-						       request->channels[i]);
-			brcmf_dbg(SCAN, "Chan : %d, Channel spec: %x\n",
-				  request->channels[i]->hw_value, chanspec);
-			params_le->channel_list[i] = cpu_to_le16(chanspec);
-		}
-	} else {
-		brcmf_dbg(SCAN, "Scanning all channels\n");
-	}
-
-	/* Copy ssid array if applicable */
-	brcmf_dbg(SCAN, "### List of SSIDs to scan ### %d\n", n_ssids);
-	if (n_ssids > 0) {
-		offset = offsetof(struct brcmf_scan_params_v2_le, channel_list) +
-				n_channels * sizeof(u16);
-		offset = roundup(offset, sizeof(u32));
-		length += sizeof(ssid_le) * n_ssids;
-		ptr = (char *)params_le + offset;
-		for (i = 0; i < n_ssids; i++) {
-			memset(&ssid_le, 0, sizeof(ssid_le));
-			ssid_le.SSID_len =
-					cpu_to_le32(request->ssids[i].ssid_len);
-			memcpy(ssid_le.SSID, request->ssids[i].ssid,
-			       request->ssids[i].ssid_len);
-			if (!ssid_le.SSID_len)
-				brcmf_dbg(SCAN, "%d: Broadcast scan\n", i);
-			else
-				brcmf_dbg(SCAN, "%d: scan for  %.32s size=%d\n",
-					  i, ssid_le.SSID, ssid_le.SSID_len);
-			memcpy(ptr, &ssid_le, sizeof(ssid_le));
-			ptr += sizeof(ssid_le);
-		}
-	} else {
-		brcmf_dbg(SCAN, "Performing passive scan\n");
-		params_le->scan_type = cpu_to_le32(BRCMF_SCANTYPE_PASSIVE);
-	}
-	params_le->length = cpu_to_le16(length);
-	/* Adding mask to channel numbers */
-	params_le->channel_num =
-		cpu_to_le32((n_ssids << BRCMF_SCAN_PARAMS_NSSID_SHIFT) |
-			(n_channels & BRCMF_SCAN_PARAMS_COUNT_MASK));
-}
-
 s32 brcmf_notify_escan_complete(struct brcmf_cfg80211_info *cfg,
 				struct brcmf_if *ifp, bool aborted,
 				bool fw_abort)
 {
 	struct brcmf_pub *drvr = cfg->pub;
-	struct brcmf_scan_params_v2_le params_v2_le;
 	struct cfg80211_scan_request *scan_request;
 	u64 reqid;
 	u32 bucket;
@@ -1204,29 +1081,29 @@ s32 brcmf_notify_escan_complete(struct brcmf_cfg80211_info *cfg,
 	timer_delete_sync(&cfg->escan_timeout);
 
 	if (fw_abort) {
+		void *params;
+		u32 params_size;
+
 		/* Do a scan abort to stop the driver's scan engine */
 		brcmf_dbg(SCAN, "ABORT scan in firmware\n");
 
-		brcmf_escan_prep(cfg, &params_v2_le, NULL);
-
-		/* E-Scan (or anyother type) can be aborted by SCAN */
-		if (brcmf_feat_is_enabled(ifp, BRCMF_FEAT_SCAN_V2)) {
-			err = brcmf_fil_cmd_data_set(ifp, BRCMF_C_SCAN,
-						     &params_v2_le,
-						     sizeof(params_v2_le));
-		} else {
-			struct brcmf_scan_params_le params_le;
-
-			brcmf_scan_params_v2_to_v1(&params_v2_le, &params_le);
-			err = brcmf_fil_cmd_data_set(ifp, BRCMF_C_SCAN,
-						     &params_le,
-						     sizeof(params_le));
+		params = drvr->scan_param_handler.get_struct_for_request(cfg,
+									 &params_size,
+									 NULL);
+		if (!params) {
+			bphy_err(drvr, "Scan abort failed to prepare params\n");
+			goto scan_done;
 		}
 
+		/* E-Scan (or any other type) can be aborted by SCAN */
+		err = brcmf_fil_cmd_data_set(ifp, BRCMF_C_SCAN, params,
+					     params_size);
+		kfree(params);
 		if (err)
 			bphy_err(drvr, "Scan abort failed\n");
 	}
 
+scan_done:
 	brcmf_scan_config_mpc(ifp, 1);
 
 	/*
@@ -1446,46 +1323,38 @@ brcmf_run_escan(struct brcmf_cfg80211_info *cfg, struct brcmf_if *ifp,
 		struct cfg80211_scan_request *request)
 {
 	struct brcmf_pub *drvr = cfg->pub;
-	s32 params_size = BRCMF_SCAN_PARAMS_V2_FIXED_SIZE +
-			  offsetof(struct brcmf_escan_params_le, params_v2_le);
 	struct brcmf_escan_params_le *params;
+	void *scan_params;
+	u32 scan_params_size;
+	u32 params_size;
 	s32 err = 0;
 
 	brcmf_dbg(SCAN, "E-SCAN START\n");
 
-	if (request != NULL) {
-		/* Allocate space for populating ssids in struct */
-		params_size += sizeof(u32) * ((request->n_channels + 1) / 2);
-
-		/* Allocate space for populating ssids in struct */
-		params_size += sizeof(struct brcmf_ssid_le) * request->n_ssids;
+	scan_params = drvr->scan_param_handler.get_struct_for_request(cfg,
+								      &scan_params_size,
+								      request);
+	if (!scan_params) {
+		err = -ENOMEM;
+		goto exit;
 	}
 
+	params_size = offsetof(struct brcmf_escan_params_le, params_v4_le) +
+		      scan_params_size;
+	if (params_size + sizeof("escan") >= BRCMF_DCMD_MEDLEN) {
+		err = -E2BIG;
+		goto exit_scan_params;
+	}
 	params = kzalloc(params_size, GFP_KERNEL);
 	if (!params) {
 		err = -ENOMEM;
-		goto exit;
+		goto exit_scan_params;
 	}
-	BUG_ON(params_size + sizeof("escan") >= BRCMF_DCMD_MEDLEN);
-	brcmf_escan_prep(cfg, &params->params_v2_le, request);
-
-	params->version = cpu_to_le32(BRCMF_ESCAN_REQ_VERSION_V2);
+	unsafe_memcpy(&params->params_v4_le, scan_params, scan_params_size,
+		      /* composite flex-array sized by allocation above */);
+	kfree(scan_params);
 
-	if (!brcmf_feat_is_enabled(ifp, BRCMF_FEAT_SCAN_V2)) {
-		struct brcmf_escan_params_le *params_v1;
-
-		params_size -= BRCMF_SCAN_PARAMS_V2_FIXED_SIZE;
-		params_size += BRCMF_SCAN_PARAMS_FIXED_SIZE;
-		params_v1 = kzalloc(params_size, GFP_KERNEL);
-		if (!params_v1) {
-			err = -ENOMEM;
-			goto exit_params;
-		}
-		params_v1->version = cpu_to_le32(BRCMF_ESCAN_REQ_VERSION);
-		brcmf_scan_params_v2_to_v1(&params->params_v2_le, &params_v1->params_le);
-		kfree(params);
-		params = params_v1;
-	}
+	params->version = cpu_to_le32(drvr->scan_param_handler.version);
 
 	params->action = cpu_to_le16(WL_ESCAN_ACTION_START);
 	params->sync_id = cpu_to_le16(0x1234);
@@ -1498,8 +1367,10 @@ brcmf_run_escan(struct brcmf_cfg80211_info *cfg, struct brcmf_if *ifp,
 			bphy_err(drvr, "error (%d)\n", err);
 	}
 
-exit_params:
 	kfree(params);
+	return err;
+exit_scan_params:
+	kfree(scan_params);
 exit:
 	return err;
 }
diff --git a/drivers/net/wireless/broadcom/brcm80211/brcmfmac/core.h b/drivers/net/wireless/broadcom/brcm80211/brcmfmac/core.h
index 399b6810e3..fe909f7add 100644
--- a/drivers/net/wireless/broadcom/brcm80211/brcmfmac/core.h
+++ b/drivers/net/wireless/broadcom/brcm80211/brcmfmac/core.h
@@ -97,6 +97,22 @@ struct brcmf_rev_info {
 	u32 nvramrev;
 };
 
+struct brcmf_cfg80211_info;
+struct cfg80211_scan_request;
+
+/**
+ * struct scan_param_struct_handler - firmware scan parameter operations.
+ *
+ * @version: scan parameter version used by firmware.
+ * @get_struct_for_request: build a scan parameter structure for @request.
+ */
+struct scan_param_struct_handler {
+	u8 version;
+	void *(*get_struct_for_request)(struct brcmf_cfg80211_info *cfg,
+					u32 *struct_size,
+					struct cfg80211_scan_request *request);
+};
+
 /* Common structure for module and instance linkage */
 struct brcmf_pub {
 	/* Linkage ponters */
@@ -145,6 +161,7 @@ struct brcmf_pub {
 	u8 sta_mac_idx;
 	const struct brcmf_fwvid_ops *vops;
 	void *vdata;
+	struct scan_param_struct_handler scan_param_handler;
 };
 
 /* forward declarations */
diff --git a/drivers/net/wireless/broadcom/brcm80211/brcmfmac/feature.c b/drivers/net/wireless/broadcom/brcm80211/brcmfmac/feature.c
index d289451644..44c0082e21 100644
--- a/drivers/net/wireless/broadcom/brcm80211/brcmfmac/feature.c
+++ b/drivers/net/wireless/broadcom/brcm80211/brcmfmac/feature.c
@@ -17,6 +17,7 @@
 #include "fwvid.h"
 #include "feature.h"
 #include "common.h"
+#include "scan_param.h"
 
 #define BRCMF_FW_UNSUPPORTED	23
 
@@ -296,6 +297,46 @@ static void brcmf_feat_firmware_capabilities(struct brcmf_if *ifp)
 	}
 }
 
+static void brcmf_feat_scan_params(struct brcmf_if *ifp)
+{
+	struct brcmf_pub *drvr = ifp->drvr;
+	struct brcmf_scan_version_le scan_ver = {};
+	u32 version = 1;
+	u32 scalar_version;
+	int err;
+
+	err = brcmf_fil_iovar_data_get(ifp, "scan_ver", &scan_ver,
+				       sizeof(scan_ver));
+	if (!err) {
+		version = le16_to_cpu(scan_ver.scan_ver_major);
+		if (!version)
+			version = le16_to_cpu(scan_ver.version);
+		if (version >= BRCMF_SCAN_PARAMS_VERSION_V2)
+			drvr->feat_flags |= BIT(BRCMF_FEAT_SCAN_V2);
+	} else {
+		err = brcmf_fil_iovar_int_get(ifp, "scan_ver",
+					      &scalar_version);
+		if (!err) {
+			version = scalar_version;
+			if (version >= BRCMF_SCAN_PARAMS_VERSION_V2)
+				drvr->feat_flags |= BIT(BRCMF_FEAT_SCAN_V2);
+		} else {
+			brcmf_dbg(TRACE, "scan_ver unavailable (%d), using v1 scan params\n",
+				  err);
+		}
+	}
+
+	err = brcmf_scan_param_setup_for_version(drvr, version);
+	if (!err) {
+		brcmf_dbg(INFO, "using scan params v%u\n", version);
+		return;
+	}
+
+	bphy_err(drvr, "unsupported scan params v%u, using v1\n", version);
+	drvr->feat_flags &= ~BIT(BRCMF_FEAT_SCAN_V2);
+	brcmf_scan_param_setup_for_version(drvr, 1);
+}
+
 /**
  * brcmf_feat_fwcap_debugfs_read() - expose firmware capabilities to debugfs.
  *
@@ -385,7 +426,7 @@ void brcmf_feat_attach(struct brcmf_pub *drvr)
 		ifp->drvr->feat_flags |= BIT(BRCMF_FEAT_SCAN_RANDOM_MAC);
 
 	brcmf_feat_iovar_int_get(ifp, BRCMF_FEAT_FWSUP, "sup_wpa");
-	brcmf_feat_iovar_int_get(ifp, BRCMF_FEAT_SCAN_V2, "scan_ver");
+	brcmf_feat_scan_params(ifp);
 	brcmf_feat_event_msgs_ext(ifp);
 
 	brcmf_feat_wlc_version_overrides(drvr);
@@ -400,6 +441,9 @@ void brcmf_feat_attach(struct brcmf_pub *drvr)
 		ifp->drvr->feat_flags &= ~drvr->settings->feature_disable;
 	}
 
+	if (!brcmf_feat_is_enabled(ifp, BRCMF_FEAT_SCAN_V2))
+		brcmf_scan_param_setup_for_version(drvr, 1);
+
 	/* set chip related quirks */
 	switch (drvr->bus_if->chip) {
 	case BRCM_CC_43236_CHIP_ID:
diff --git a/drivers/net/wireless/broadcom/brcm80211/brcmfmac/fwil_types.h b/drivers/net/wireless/broadcom/brcm80211/brcmfmac/fwil_types.h
index c786da4336..dbba883bba 100644
--- a/drivers/net/wireless/broadcom/brcm80211/brcmfmac/fwil_types.h
+++ b/drivers/net/wireless/broadcom/brcm80211/brcmfmac/fwil_types.h
@@ -53,6 +53,8 @@
 
 /* version of brcmf_scan_params structure */
 #define BRCMF_SCAN_PARAMS_VERSION_V2	2
+#define BRCMF_SCAN_PARAMS_VERSION_V3	3
+#define BRCMF_SCAN_PARAMS_VERSION_V4	4
 
 /* masks for channel and ssid count */
 #define BRCMF_SCAN_PARAMS_COUNT_MASK	0x0000ffff
@@ -63,6 +65,13 @@
 #define BRCMF_SCANTYPE_ACTIVE		0
 #define BRCMF_SCANTYPE_PASSIVE		1
 
+#define BRCMF_SCANFLAGS_LOW_PRIO	BIT(1)
+#define BRCMF_SCANFLAGS_LOW_POWER	BIT(12)
+#define BRCMF_SCANFLAGS_HIGH_ACCURACY	BIT(13)
+#define BRCMF_SCANFLAGS_LOW_SPAN	BIT(14)
+
+#define BRCMF_SCANSSID_INC_RNR		BIT(1)
+
 #define BRCMF_WSEC_MAX_PSK_LEN		32
 #define	BRCMF_WSEC_PASSPHRASE		BIT(0)
 
@@ -451,6 +460,45 @@ struct brcmf_scan_params_v2_le {
 	};
 };
 
+struct brcmf_scan_params_v3_le {
+	__le16 version;
+	__le16 length;
+	struct brcmf_ssid_le ssid_le;
+	u8 bssid[ETH_ALEN];
+	s8 bss_type;
+	u8 ssid_type;
+	__le32 scan_type;
+	__le32 nprobes;
+	__le32 active_time;
+	__le32 passive_time;
+	__le32 home_time;
+	__le32 channel_num;
+	union {
+		__le16 padding;
+		DECLARE_FLEX_ARRAY(__le16, channel_list);
+	};
+};
+
+struct brcmf_scan_params_v4_le {
+	__le16 version;
+	__le16 length;
+	struct brcmf_ssid_le ssid_le;
+	u8 bssid[ETH_ALEN];
+	s8 bss_type;
+	u8 ssid_type;
+	__le32 scan_type;
+	__le32 scan_type_ext;
+	__le32 nprobes;
+	__le32 active_time;
+	__le32 passive_time;
+	__le32 home_time;
+	__le32 channel_num;
+	union {
+		__le16 padding;
+		DECLARE_FLEX_ARRAY(__le16, channel_list);
+	};
+};
+
 struct brcmf_scan_results {
 	u32 buflen;
 	u32 version;
@@ -465,6 +513,8 @@ struct brcmf_escan_params_le {
 	union {
 		struct brcmf_scan_params_le params_le;
 		struct brcmf_scan_params_v2_le params_v2_le;
+		struct brcmf_scan_params_v3_le params_v3_le;
+		struct brcmf_scan_params_v4_le params_v4_le;
 	};
 };
 
@@ -1083,6 +1133,21 @@ struct brcmf_pno_scanresults_v2_le {
 	__le32 scan_ch_bucket;
 };
 
+/**
+ * struct brcmf_scan_version_le - scan interface version.
+ *
+ * @version: version of this structure.
+ * @length: length of this structure.
+ * @scan_ver_major: scan parameter version supported by firmware.
+ */
+struct brcmf_scan_version_le {
+	__le16 version;
+	__le16 length;
+	__le16 scan_ver_major;
+};
+
+#define BRCMF_SCAN_VERSION_VERSION	1
+
 /**
  * struct brcmf_pno_macaddr_le - to configure PNO macaddr randomization.
  *
diff --git a/drivers/net/wireless/broadcom/brcm80211/brcmfmac/scan_param.c b/drivers/net/wireless/broadcom/brcm80211/brcmfmac/scan_param.c
new file mode 100644
index 0000000000..43e0fd16f1
--- /dev/null
+++ b/drivers/net/wireless/broadcom/brcm80211/brcmfmac/scan_param.c
@@ -0,0 +1,416 @@
+// SPDX-License-Identifier: ISC
+/*
+ * Copyright (c) 2023 Daniel Berlin
+ */
+
+#include <linux/etherdevice.h>
+#include <linux/slab.h>
+#include <linux/string.h>
+#include <net/cfg80211.h>
+
+#include "cfg80211.h"
+#include "core.h"
+#include "debug.h"
+#include "fwil_types.h"
+#include "scan_param.h"
+
+static void brcmf_scan_param_set_defaults(u8 *bssid,
+					  s8 *bss_type, __le32 *channel_num,
+					  __le32 *nprobes,
+					  __le32 *active_time,
+					  __le32 *passive_time,
+					  __le32 *home_time)
+{
+	eth_broadcast_addr(bssid);
+	*bss_type = DOT11_BSSTYPE_ANY;
+	*channel_num = 0;
+	*nprobes = cpu_to_le32(-1);
+	*active_time = cpu_to_le32(-1);
+	*passive_time = cpu_to_le32(-1);
+	*home_time = cpu_to_le32(-1);
+}
+
+static void brcmf_scan_param_copy_chanspecs(struct brcmf_cfg80211_info *cfg,
+					    __le16 *dest_channels,
+					    struct ieee80211_channel **channels,
+					    u32 n_channels)
+{
+	u32 chanspec;
+	int i;
+
+	for (i = 0; i < n_channels; i++) {
+		chanspec = channel_to_chanspec(&cfg->d11inf, channels[i]);
+		brcmf_dbg(SCAN, "Chan: %d, channel spec: %x\n",
+			  channels[i]->hw_value, chanspec);
+		dest_channels[i] = cpu_to_le16(chanspec);
+	}
+}
+
+static void brcmf_scan_param_copy_ssids(char *dest_ssids,
+					struct cfg80211_ssid *ssids,
+					u32 n_ssids)
+{
+	struct brcmf_ssid_le ssid_le;
+	int i;
+
+	for (i = 0; i < n_ssids; i++) {
+		memset(&ssid_le, 0, sizeof(ssid_le));
+		ssid_le.SSID_len = cpu_to_le32(ssids[i].ssid_len);
+		memcpy(ssid_le.SSID, ssids[i].ssid, ssids[i].ssid_len);
+		memcpy(dest_ssids, &ssid_le, sizeof(ssid_le));
+		dest_ssids += sizeof(ssid_le);
+	}
+}
+
+static u32
+brcmf_scan_param_tail_size(const struct cfg80211_scan_request *request,
+			   u32 params_size)
+{
+	if (!request)
+		return params_size + sizeof(u16);
+
+	params_size += sizeof(u32) * ((request->n_channels + 1) / 2);
+	params_size += sizeof(struct brcmf_ssid_le) * request->n_ssids;
+
+	return params_size;
+}
+
+static u32 brcmf_scan_param_scan_flags(u32 nl80211_flags)
+{
+	u32 scan_flags = 0;
+
+	if (nl80211_flags & NL80211_SCAN_FLAG_LOW_SPAN)
+		scan_flags |= BRCMF_SCANFLAGS_LOW_SPAN;
+	if (nl80211_flags & NL80211_SCAN_FLAG_HIGH_ACCURACY)
+		scan_flags |= BRCMF_SCANFLAGS_HIGH_ACCURACY;
+	if (nl80211_flags & NL80211_SCAN_FLAG_LOW_POWER)
+		scan_flags |= BRCMF_SCANFLAGS_LOW_POWER;
+	if (nl80211_flags & NL80211_SCAN_FLAG_LOW_PRIORITY)
+		scan_flags |= BRCMF_SCANFLAGS_LOW_PRIO;
+
+	return scan_flags;
+}
+
+static void *
+brcmf_scan_param_get_prepped_struct_v1(struct brcmf_cfg80211_info *cfg,
+				       u32 *struct_size,
+				       struct cfg80211_scan_request *request)
+{
+	struct brcmf_scan_params_le *params_le;
+	u32 params_size;
+	u32 n_channels;
+	u32 n_ssids;
+	u32 length;
+	u8 scan_type = BRCMF_SCANTYPE_ACTIVE;
+
+	length = offsetof(struct brcmf_scan_params_le, channel_list);
+	params_size = brcmf_scan_param_tail_size(request, length);
+	params_le = kzalloc(params_size, GFP_KERNEL);
+	if (!params_le)
+		return NULL;
+
+	brcmf_scan_param_set_defaults(params_le->bssid,
+				      &params_le->bss_type,
+				      &params_le->channel_num,
+				      &params_le->nprobes,
+				      &params_le->active_time,
+				      &params_le->passive_time,
+				      &params_le->home_time);
+
+	if (!request) {
+		length += sizeof(u16);
+		params_le->channel_num = cpu_to_le32(1);
+		params_le->channel_list[0] = cpu_to_le16(-1);
+		goto done;
+	}
+
+	n_ssids = request->n_ssids;
+	n_channels = request->n_channels;
+
+	if (n_channels > 0) {
+		length += roundup(sizeof(u16) * n_channels, sizeof(u32));
+		brcmf_scan_param_copy_chanspecs(cfg, params_le->channel_list,
+						request->channels, n_channels);
+	} else {
+		brcmf_dbg(SCAN, "Scanning all channels\n");
+	}
+
+	if (n_ssids > 0) {
+		char *ptr;
+		u32 offset;
+
+		offset = offsetof(struct brcmf_scan_params_le, channel_list) +
+			 n_channels * sizeof(u16);
+		offset = roundup(offset, sizeof(u32));
+		length += sizeof(struct brcmf_ssid_le) * n_ssids;
+		ptr = (char *)params_le + offset;
+		brcmf_scan_param_copy_ssids(ptr, request->ssids, n_ssids);
+	} else {
+		brcmf_dbg(SCAN, "Performing passive scan\n");
+		scan_type = BRCMF_SCANTYPE_PASSIVE;
+	}
+
+	if (request->flags & NL80211_SCAN_FLAG_LOW_PRIORITY)
+		scan_type |= BRCMF_SCANFLAGS_LOW_PRIO;
+	params_le->scan_type = scan_type;
+	params_le->channel_num =
+		cpu_to_le32((n_ssids << BRCMF_SCAN_PARAMS_NSSID_SHIFT) |
+			    (n_channels & BRCMF_SCAN_PARAMS_COUNT_MASK));
+
+done:
+	*struct_size = length;
+	return params_le;
+}
+
+static void *
+brcmf_scan_param_get_prepped_struct_v2(struct brcmf_cfg80211_info *cfg,
+				       u32 *struct_size,
+				       struct cfg80211_scan_request *request)
+{
+	struct brcmf_scan_params_v2_le *params_le;
+	u32 params_size;
+	u32 n_channels;
+	u32 n_ssids;
+	u32 length;
+	u32 scan_type = BRCMF_SCANTYPE_ACTIVE;
+
+	length = offsetof(struct brcmf_scan_params_v2_le, channel_list);
+	params_size = brcmf_scan_param_tail_size(request, length);
+	params_le = kzalloc(params_size, GFP_KERNEL);
+	if (!params_le)
+		return NULL;
+
+	params_le->version = cpu_to_le16(BRCMF_SCAN_PARAMS_VERSION_V2);
+	brcmf_scan_param_set_defaults(params_le->bssid,
+				      &params_le->bss_type,
+				      &params_le->channel_num,
+				      &params_le->nprobes,
+				      &params_le->active_time,
+				      &params_le->passive_time,
+				      &params_le->home_time);
+
+	if (!request) {
+		length += sizeof(u16);
+		params_le->channel_num = cpu_to_le32(1);
+		params_le->channel_list[0] = cpu_to_le16(-1);
+		params_le->length = cpu_to_le16(length);
+		goto done;
+	}
+
+	n_ssids = request->n_ssids;
+	n_channels = request->n_channels;
+
+	if (n_channels > 0) {
+		length += roundup(sizeof(u16) * n_channels, sizeof(u32));
+		brcmf_scan_param_copy_chanspecs(cfg, params_le->channel_list,
+						request->channels, n_channels);
+	} else {
+		brcmf_dbg(SCAN, "Scanning all channels\n");
+	}
+
+	if (n_ssids > 0) {
+		char *ptr;
+		u32 offset;
+
+		offset = offsetof(struct brcmf_scan_params_v2_le,
+				  channel_list) + n_channels * sizeof(u16);
+		offset = roundup(offset, sizeof(u32));
+		length += sizeof(struct brcmf_ssid_le) * n_ssids;
+		ptr = (char *)params_le + offset;
+		brcmf_scan_param_copy_ssids(ptr, request->ssids, n_ssids);
+	} else {
+		brcmf_dbg(SCAN, "Performing passive scan\n");
+		scan_type = BRCMF_SCANTYPE_PASSIVE;
+	}
+
+	scan_type |= brcmf_scan_param_scan_flags(request->flags);
+	params_le->scan_type = cpu_to_le32(scan_type);
+	params_le->length = cpu_to_le16(length);
+	params_le->channel_num =
+		cpu_to_le32((n_ssids << BRCMF_SCAN_PARAMS_NSSID_SHIFT) |
+			    (n_channels & BRCMF_SCAN_PARAMS_COUNT_MASK));
+
+done:
+	*struct_size = length;
+	return params_le;
+}
+
+static void *
+brcmf_scan_param_get_prepped_struct_v3(struct brcmf_cfg80211_info *cfg,
+				       u32 *struct_size,
+				       struct cfg80211_scan_request *request)
+{
+	struct brcmf_scan_params_v3_le *params_le;
+	u32 params_size;
+	u32 n_channels;
+	u32 n_ssids;
+	u32 length;
+	u32 scan_type = BRCMF_SCANTYPE_ACTIVE;
+
+	length = offsetof(struct brcmf_scan_params_v3_le, channel_list);
+	params_size = brcmf_scan_param_tail_size(request, length);
+	params_le = kzalloc(params_size, GFP_KERNEL);
+	if (!params_le)
+		return NULL;
+
+	params_le->version = cpu_to_le16(BRCMF_SCAN_PARAMS_VERSION_V3);
+	brcmf_scan_param_set_defaults(params_le->bssid,
+				      &params_le->bss_type,
+				      &params_le->channel_num,
+				      &params_le->nprobes,
+				      &params_le->active_time,
+				      &params_le->passive_time,
+				      &params_le->home_time);
+
+	if (!request) {
+		length += sizeof(u16);
+		params_le->channel_num = cpu_to_le32(1);
+		params_le->channel_list[0] = cpu_to_le16(-1);
+		params_le->length = cpu_to_le16(length);
+		goto done;
+	}
+
+	n_ssids = request->n_ssids;
+	n_channels = request->n_channels;
+
+	if (n_channels > 0) {
+		length += roundup(sizeof(u16) * n_channels, sizeof(u32));
+		brcmf_scan_param_copy_chanspecs(cfg, params_le->channel_list,
+						request->channels, n_channels);
+	} else {
+		brcmf_dbg(SCAN, "Scanning all channels\n");
+	}
+
+	if (n_ssids > 0) {
+		char *ptr;
+		u32 offset;
+
+		offset = offsetof(struct brcmf_scan_params_v3_le,
+				  channel_list) + n_channels * sizeof(u16);
+		offset = roundup(offset, sizeof(u32));
+		length += sizeof(struct brcmf_ssid_le) * n_ssids;
+		ptr = (char *)params_le + offset;
+		brcmf_scan_param_copy_ssids(ptr, request->ssids, n_ssids);
+	} else {
+		brcmf_dbg(SCAN, "Performing passive scan\n");
+		scan_type = BRCMF_SCANTYPE_PASSIVE;
+	}
+
+	scan_type |= brcmf_scan_param_scan_flags(request->flags);
+	params_le->scan_type = cpu_to_le32(scan_type);
+	params_le->length = cpu_to_le16(length);
+	params_le->channel_num =
+		cpu_to_le32((n_ssids << BRCMF_SCAN_PARAMS_NSSID_SHIFT) |
+			    (n_channels & BRCMF_SCAN_PARAMS_COUNT_MASK));
+	if (request->flags & NL80211_SCAN_FLAG_COLOCATED_6GHZ)
+		params_le->ssid_type |= BRCMF_SCANSSID_INC_RNR;
+
+done:
+	*struct_size = length;
+	return params_le;
+}
+
+static void *
+brcmf_scan_param_get_prepped_struct_v4(struct brcmf_cfg80211_info *cfg,
+				       u32 *struct_size,
+				       struct cfg80211_scan_request *request)
+{
+	struct brcmf_scan_params_v4_le *params_le;
+	u32 params_size;
+	u32 n_channels;
+	u32 n_ssids;
+	u32 length;
+	u32 scan_type = BRCMF_SCANTYPE_ACTIVE;
+
+	length = offsetof(struct brcmf_scan_params_v4_le, channel_list);
+	params_size = brcmf_scan_param_tail_size(request, length);
+	params_le = kzalloc(params_size, GFP_KERNEL);
+	if (!params_le)
+		return NULL;
+
+	params_le->version = cpu_to_le16(BRCMF_SCAN_PARAMS_VERSION_V4);
+	brcmf_scan_param_set_defaults(params_le->bssid,
+				      &params_le->bss_type,
+				      &params_le->channel_num,
+				      &params_le->nprobes,
+				      &params_le->active_time,
+				      &params_le->passive_time,
+				      &params_le->home_time);
+
+	if (!request) {
+		length += sizeof(u16);
+		params_le->channel_num = cpu_to_le32(1);
+		params_le->channel_list[0] = cpu_to_le16(-1);
+		params_le->length = cpu_to_le16(length);
+		goto done;
+	}
+
+	n_ssids = request->n_ssids;
+	n_channels = request->n_channels;
+
+	if (n_channels > 0) {
+		length += roundup(sizeof(u16) * n_channels, sizeof(u32));
+		brcmf_scan_param_copy_chanspecs(cfg, params_le->channel_list,
+						request->channels, n_channels);
+	} else {
+		brcmf_dbg(SCAN, "Scanning all channels\n");
+	}
+
+	if (n_ssids > 0) {
+		char *ptr;
+		u32 offset;
+
+		offset = offsetof(struct brcmf_scan_params_v4_le,
+				  channel_list) + n_channels * sizeof(u16);
+		offset = roundup(offset, sizeof(u32));
+		length += sizeof(struct brcmf_ssid_le) * n_ssids;
+		ptr = (char *)params_le + offset;
+		brcmf_scan_param_copy_ssids(ptr, request->ssids, n_ssids);
+	} else {
+		brcmf_dbg(SCAN, "Performing passive scan\n");
+		scan_type = BRCMF_SCANTYPE_PASSIVE;
+	}
+
+	scan_type |= brcmf_scan_param_scan_flags(request->flags);
+	params_le->scan_type = cpu_to_le32(scan_type);
+	params_le->length = cpu_to_le16(length);
+	params_le->channel_num =
+		cpu_to_le32((n_ssids << BRCMF_SCAN_PARAMS_NSSID_SHIFT) |
+			    (n_channels & BRCMF_SCAN_PARAMS_COUNT_MASK));
+	if (request->flags & NL80211_SCAN_FLAG_COLOCATED_6GHZ)
+		params_le->ssid_type |= BRCMF_SCANSSID_INC_RNR;
+
+done:
+	*struct_size = length;
+	return params_le;
+}
+
+int brcmf_scan_param_setup_for_version(struct brcmf_pub *drvr, u32 version)
+{
+	switch (version) {
+	case 1:
+		drvr->scan_param_handler.get_struct_for_request =
+			brcmf_scan_param_get_prepped_struct_v1;
+		break;
+	case 2:
+		drvr->scan_param_handler.get_struct_for_request =
+			brcmf_scan_param_get_prepped_struct_v2;
+		break;
+	case 3:
+		drvr->scan_param_handler.get_struct_for_request =
+			brcmf_scan_param_get_prepped_struct_v3;
+		break;
+	case 4:
+		drvr->scan_param_handler.get_struct_for_request =
+			brcmf_scan_param_get_prepped_struct_v4;
+		break;
+	default:
+		drvr->scan_param_handler.version = 0;
+		drvr->scan_param_handler.get_struct_for_request = NULL;
+		return -EINVAL;
+	}
+
+	drvr->scan_param_handler.version = version;
+
+	return 0;
+}
diff --git a/drivers/net/wireless/broadcom/brcm80211/brcmfmac/scan_param.h b/drivers/net/wireless/broadcom/brcm80211/brcmfmac/scan_param.h
new file mode 100644
index 0000000000..a30ad26d9c
--- /dev/null
+++ b/drivers/net/wireless/broadcom/brcm80211/brcmfmac/scan_param.h
@@ -0,0 +1,13 @@
+/* SPDX-License-Identifier: ISC */
+/*
+ * Copyright (c) 2023 Daniel Berlin
+ */
+
+#ifndef _BRCMF_SCAN_PARAM_H
+#define _BRCMF_SCAN_PARAM_H
+
+struct brcmf_pub;
+
+int brcmf_scan_param_setup_for_version(struct brcmf_pub *drvr, u32 version);
+
+#endif /* _BRCMF_SCAN_PARAM_H */

-- 
2.55.0

