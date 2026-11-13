From: Michael Reeves <michael.reeves077@gmail.com>
Date: Fri, 13 Nov 2026 06:31:58 +0000
Subject: [PATCH wireless-next 4/4] wifi: brcmfmac: Add support for PNO
 version 3
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261113-6ghz-v1-4-0b9a67e413a9@gmail.com>
References: <20261113-6ghz-v1-0-0b9a67e413a9@gmail.com>
In-Reply-To: <20261113-6ghz-v1-0-0b9a67e413a9@gmail.com>
To: Arend van Spriel <arend.vanspriel@broadcom.com>
Cc: asahi@lists.linux.dev, linux-wireless@vger.kernel.org, 
 brcm80211@lists.linux.dev, brcm80211-dev-list.pdl@broadcom.com, 
 linux-kernel@vger.kernel.org, Michael Reeves <michael.reeves077@gmail.com>, 
 Yureka Lilian <yureka@cyberchaos.dev>, Daniel Berlin <dberlin@dberlin.org>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794551523; l=18699;
 i=michael.reeves077@gmail.com; s=20261107; h=from:subject:message-id;
 bh=znwZr59ftThX1Axn8Dzkx0IEAMnR46WJkHUVTn1IqyA=;
 b=CN4EbDA5H4RJYr/+3ZQS1BcW6z8S6YGc1g7BJU9E0TusDtGMCIDNLjUnzczWo73OyNaGTxBCL
 Zg2Bd0yli/bBzZnjE6qQgPSHSXAMh4VPnxMFVLtbXA17M0uJO+mkLOV
X-Developer-Key: i=michael.reeves077@gmail.com; a=ed25519;
 pk=ykwkLcuByJYb/cdLc2UuoYP03pIzwrscEZg30+4tJL8=
X-Endpoint-Received: by B4 Relay for michael.reeves077@gmail.com/20261107 with auth_id=1442
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Recent firmware versions introduce version 3 of PNO settings and result
events. Unlike prior versions that only provide raw channel numbers,
version 3 provides complete chanspecs, resolving band ambiguity for
overlapping channel numbers (e.g. 6 GHz).

Query the firmware's PNO version during driver attach. Use version 3
configuration structures if supported by the firmware, and parse
incoming PNO scan results based on the event version.

Tested-by: Yureka Lilian <yureka@cyberchaos.dev>
Co-developed-by: Daniel Berlin <dberlin@dberlin.org>
Signed-off-by: Daniel Berlin <dberlin@dberlin.org>
Signed-off-by: Michael Reeves <michael.reeves077@gmail.com>
---
 .../broadcom/brcm80211/brcmfmac/cfg80211.c         |  94 ++++++--------
 .../broadcom/brcm80211/brcmfmac/fwil_types.h       |  65 ++++++++++
 .../net/wireless/broadcom/brcm80211/brcmfmac/pno.c | 144 ++++++++++++++++++---
 .../net/wireless/broadcom/brcm80211/brcmfmac/pno.h |  41 +++++-
 4 files changed, 267 insertions(+), 77 deletions(-)

diff --git a/drivers/net/wireless/broadcom/brcm80211/brcmfmac/cfg80211.c b/drivers/net/wireless/broadcom/brcm80211/brcmfmac/cfg80211.c
index 90db55c0ab7a..2450dd0c1e99 100644
--- a/drivers/net/wireless/broadcom/brcm80211/brcmfmac/cfg80211.c
+++ b/drivers/net/wireless/broadcom/brcm80211/brcmfmac/cfg80211.c
@@ -3828,17 +3828,12 @@ brcmf_alloc_internal_escan_request(struct wiphy *wiphy, u32 n_netinfo) {
 }
 
 static int brcmf_internal_escan_add_info(struct cfg80211_scan_request *req,
-					 u8 *ssid, u8 ssid_len, u8 channel)
+					 u8 *ssid, u8 ssid_len, u8 channel,
+					 enum nl80211_band band)
 {
 	struct ieee80211_channel *chan;
-	enum nl80211_band band;
 	int freq, i;
 
-	if (channel <= CH_MAX_2G_CHANNEL)
-		band = NL80211_BAND_2GHZ;
-	else
-		band = NL80211_BAND_5GHZ;
-
 	freq = ieee80211_channel_to_frequency(channel, band);
 	if (!freq)
 		return -EINVAL;
@@ -3894,28 +3889,6 @@ static int brcmf_start_internal_escan(struct brcmf_if *ifp, u32 fwmap,
 	return 0;
 }
 
-static struct brcmf_pno_net_info_le *
-brcmf_get_netinfo_array(struct brcmf_pno_scanresults_le *pfn_v1)
-{
-	struct brcmf_pno_scanresults_v2_le *pfn_v2;
-	struct brcmf_pno_net_info_le *netinfo;
-
-	switch (pfn_v1->version) {
-	default:
-		WARN_ON(1);
-		fallthrough;
-	case cpu_to_le32(1):
-		netinfo = (struct brcmf_pno_net_info_le *)(pfn_v1 + 1);
-		break;
-	case cpu_to_le32(2):
-		pfn_v2 = (struct brcmf_pno_scanresults_v2_le *)pfn_v1;
-		netinfo = (struct brcmf_pno_net_info_le *)(pfn_v2 + 1);
-		break;
-	}
-
-	return netinfo;
-}
-
 /* PFN result doesn't have all the info which are required by the supplicant
  * (For e.g IEs) Do a target Escan so that sched scan results are reported
  * via wl_inform_single_bss in the required format. Escan does require the
@@ -3928,19 +3901,19 @@ brcmf_notify_sched_scan_results(struct brcmf_if *ifp,
 {
 	struct brcmf_pub *drvr = ifp->drvr;
 	struct brcmf_cfg80211_info *cfg = drvr->config;
-	struct brcmf_pno_net_info_le *netinfo, *netinfo_start;
 	struct cfg80211_scan_request *request = NULL;
 	struct wiphy *wiphy = cfg_to_wiphy(cfg);
-	int i, err = 0;
 	struct brcmf_pno_scanresults_le *pfn_result;
+	struct brcmf_pno_netinfo netinfo;
+	int i, err = 0;
 	u32 bucket_map;
 	u32 result_count;
 	u32 status;
-	u32 datalen;
 
 	brcmf_dbg(SCAN, "Enter\n");
 
-	if (e->datalen < (sizeof(*pfn_result) + sizeof(*netinfo))) {
+	if (e->datalen < (sizeof(*pfn_result) +
+			  sizeof(struct brcmf_pno_net_info_le))) {
 		brcmf_dbg(SCAN, "Event data too small. Ignore\n");
 		return 0;
 	}
@@ -3964,9 +3937,8 @@ brcmf_notify_sched_scan_results(struct brcmf_if *ifp,
 		goto out_err;
 	}
 
-	netinfo_start = brcmf_get_netinfo_array(pfn_result);
-	datalen = e->datalen - ((void *)netinfo_start - (void *)pfn_result);
-	if (datalen < result_count * sizeof(*netinfo)) {
+	err = brcmf_pno_check_results(data, e->datalen, result_count);
+	if (err) {
 		bphy_err(drvr, "insufficient event data\n");
 		goto out_err;
 	}
@@ -3980,17 +3952,20 @@ brcmf_notify_sched_scan_results(struct brcmf_if *ifp,
 
 	bucket_map = 0;
 	for (i = 0; i < result_count; i++) {
-		netinfo = &netinfo_start[i];
-
-		if (netinfo->SSID_len > IEEE80211_MAX_SSID_LEN)
-			netinfo->SSID_len = IEEE80211_MAX_SSID_LEN;
-		brcmf_dbg(SCAN, "SSID:%.32s Channel:%d\n",
-			  netinfo->SSID, netinfo->channel);
-		bucket_map |= brcmf_pno_get_bucket_map(cfg->pno, netinfo);
-		err = brcmf_internal_escan_add_info(request,
-						    netinfo->SSID,
-						    netinfo->SSID_len,
-						    netinfo->channel);
+		err = brcmf_pno_get_netinfo(&cfg->d11inf, data, e->datalen, i,
+					    &netinfo);
+		if (err) {
+			bphy_err(drvr, "insufficient event data\n");
+			goto out_err;
+		}
+
+		brcmf_dbg(SCAN, "SSID:%.*s Channel:%d\n",
+			  netinfo.ssid_len, netinfo.ssid, netinfo.channel);
+		bucket_map |= brcmf_pno_get_bucket_map(cfg->pno, &netinfo);
+		err = brcmf_internal_escan_add_info(request, netinfo.ssid,
+						    netinfo.ssid_len,
+						    netinfo.channel,
+						    chanspec_band_to_nl80211(netinfo.band));
 		if (err)
 			goto out_err;
 	}
@@ -4104,11 +4079,13 @@ brcmf_wowl_nd_results(struct brcmf_if *ifp, const struct brcmf_event_msg *e,
 	struct brcmf_pub *drvr = ifp->drvr;
 	struct brcmf_cfg80211_info *cfg = drvr->config;
 	struct brcmf_pno_scanresults_le *pfn_result;
-	struct brcmf_pno_net_info_le *netinfo;
+	struct brcmf_pno_netinfo netinfo;
+	int err;
 
 	brcmf_dbg(SCAN, "Enter\n");
 
-	if (e->datalen < (sizeof(*pfn_result) + sizeof(*netinfo))) {
+	if (e->datalen < (sizeof(*pfn_result) +
+			  sizeof(struct brcmf_pno_net_info_le))) {
 		brcmf_dbg(SCAN, "Event data too small. Ignore\n");
 		return 0;
 	}
@@ -4126,16 +4103,19 @@ brcmf_wowl_nd_results(struct brcmf_if *ifp, const struct brcmf_event_msg *e,
 		return -EINVAL;
 	}
 
-	netinfo = brcmf_get_netinfo_array(pfn_result);
-	if (netinfo->SSID_len > IEEE80211_MAX_SSID_LEN)
-		netinfo->SSID_len = IEEE80211_MAX_SSID_LEN;
-	memcpy(cfg->wowl.nd->ssid.ssid, netinfo->SSID, netinfo->SSID_len);
-	cfg->wowl.nd->ssid.ssid_len = netinfo->SSID_len;
+	err = brcmf_pno_get_netinfo(&cfg->d11inf, data, e->datalen, 0,
+				    &netinfo);
+	if (err) {
+		bphy_err(drvr, "insufficient event data\n");
+		return err;
+	}
+
+	memcpy(cfg->wowl.nd->ssid.ssid, netinfo.ssid, netinfo.ssid_len);
+	cfg->wowl.nd->ssid.ssid_len = netinfo.ssid_len;
 	cfg->wowl.nd->n_channels = 1;
 	cfg->wowl.nd->channels[0] =
-		ieee80211_channel_to_frequency(netinfo->channel,
-			netinfo->channel <= CH_MAX_2G_CHANNEL ?
-					NL80211_BAND_2GHZ : NL80211_BAND_5GHZ);
+		ieee80211_channel_to_frequency(netinfo.channel,
+					       chanspec_band_to_nl80211(netinfo.band));
 	cfg->wowl.nd_info->n_matches = 1;
 	cfg->wowl.nd_info->matches[0] = cfg->wowl.nd;
 
diff --git a/drivers/net/wireless/broadcom/brcm80211/brcmfmac/fwil_types.h b/drivers/net/wireless/broadcom/brcm80211/brcmfmac/fwil_types.h
index f4e8eeeffa08..9dd2de048275 100644
--- a/drivers/net/wireless/broadcom/brcm80211/brcmfmac/fwil_types.h
+++ b/drivers/net/wireless/broadcom/brcm80211/brcmfmac/fwil_types.h
@@ -1107,6 +1107,46 @@ struct brcmf_pno_param_le {
 	__le32 slow_freq;
 };
 
+/**
+ * struct brcmf_pno_param_v3_le - PNO scan configuration parameters
+ *
+ * @version: PNO parameters version.
+ * @length: size of this structure.
+ * @scan_freq: scan frequency.
+ * @lost_network_timeout: #sec. to declare discovered network as lost.
+ * @flags: Bit field to control features of PFN such as sort criteria auto
+ *	enable switch and background scan.
+ * @rssi_margin: Margin to avoid jitter for choosing a PFN based on RSSI sort
+ *	criteria.
+ * @bestn: number of best networks in each bucket.
+ * @mscan: number of scans recorded which is equal to or less than bestn.
+ * @repeat: minimum number of scan intervals before scan frequency changes
+ *	in adaptive scan.
+ * @exp: exponent of 2 for maximum scan interval.
+ * @slow_freq: slow scan period.
+ * @min_bound: minimum bound for PFN backoff.
+ * @max_bound: maximum bound for PFN backoff.
+ * @pfn_lp_scan_disable: disable low power scan interleaving.
+ * @pfn_lp_scan_cnt: number of low power scans before a high power scan.
+ */
+struct brcmf_pno_param_v3_le {
+	__le16 version;
+	__le16 length;
+	__le32 scan_freq;
+	__le32 lost_network_timeout;
+	__le16 flags;
+	__le16 rssi_margin;
+	u8 bestn;
+	u8 mscan;
+	u8 repeat;
+	u8 exp;
+	__le32 slow_freq;
+	u8 min_bound;
+	u8 max_bound;
+	u8 pfn_lp_scan_disable;
+	u8 pfn_lp_scan_cnt;
+};
+
 /**
  * struct brcmf_pno_config_le - PNO channel configuration.
  *
@@ -1160,6 +1200,31 @@ struct brcmf_pno_net_info_le {
 	__le16	timestamp;
 };
 
+/**
+ * struct brcmf_pno_net_info_v3_le - information per found network.
+ *
+ * @bssid: BSS network identifier.
+ * @chanspec: channel spec.
+ * @SSID_len: length of ssid.
+ * @pad: padding.
+ * @flags: flags.
+ * @SSID: ssid characters.
+ * @RSSI: receive signal strength (in dBm).
+ * @timestamp: age in seconds.
+ *
+ * Version 3 results use the header of &struct brcmf_pno_scanresults_v2_le.
+ */
+struct brcmf_pno_net_info_v3_le {
+	u8 bssid[ETH_ALEN];
+	__le16 chanspec;
+	u8 SSID_len;
+	u8 pad;
+	__le16 flags;
+	u8 SSID[32];
+	__le16 RSSI;
+	__le16 timestamp;
+};
+
 /**
  * struct brcmf_pno_scanresults_le - result returned in PNO NET FOUND event.
  *
diff --git a/drivers/net/wireless/broadcom/brcm80211/brcmfmac/pno.c b/drivers/net/wireless/broadcom/brcm80211/brcmfmac/pno.c
index ba62ab41bae1..ec8cd81de9cf 100644
--- a/drivers/net/wireless/broadcom/brcm80211/brcmfmac/pno.c
+++ b/drivers/net/wireless/broadcom/brcm80211/brcmfmac/pno.c
@@ -5,6 +5,7 @@
 #include <linux/netdevice.h>
 #include <linux/gcd.h>
 #include <net/cfg80211.h>
+#include <brcmu_wifi.h>
 
 #include "core.h"
 #include "debug.h"
@@ -13,7 +14,8 @@
 #include "cfg80211.h"
 #include "pno.h"
 
-#define BRCMF_PNO_VERSION		2
+#define BRCMF_PNO_VERSION_2		2
+#define BRCMF_PNO_VERSION_3		3
 #define BRCMF_PNO_REPEAT		4
 #define BRCMF_PNO_FREQ_EXPO_MAX		3
 #define BRCMF_PNO_IMMEDIATE_SCAN_BIT	3
@@ -30,6 +32,7 @@
 #define GSCAN_RETRY_THRESHOLD			3
 
 struct brcmf_pno_info {
+	u8 version;
 	int n_reqs;
 	struct cfg80211_sched_scan_request *reqs[BRCMF_PNO_MAX_BUCKETS];
 	struct mutex req_lock;
@@ -102,23 +105,16 @@ static int brcmf_pno_channel_config(struct brcmf_if *ifp,
 static int brcmf_pno_config(struct brcmf_if *ifp, u32 scan_freq,
 			    u32 mscan, u32 bestn)
 {
+	struct brcmf_pno_info *pi = ifp_to_pno(ifp);
 	struct brcmf_pub *drvr = ifp->drvr;
-	struct brcmf_pno_param_le pfn_param;
+	u8 pfn_mscan = 0;
+	u8 pfn_bestn = 0;
 	u16 flags;
 	u32 pfnmem;
 	s32 err;
 
-	memset(&pfn_param, 0, sizeof(pfn_param));
-	pfn_param.version = cpu_to_le32(BRCMF_PNO_VERSION);
-
-	/* set extra pno params */
 	flags = BIT(BRCMF_PNO_IMMEDIATE_SCAN_BIT) |
 		BIT(BRCMF_PNO_ENABLE_ADAPTSCAN_BIT);
-	pfn_param.repeat = BRCMF_PNO_REPEAT;
-	pfn_param.exp = BRCMF_PNO_FREQ_EXPO_MAX;
-
-	/* set up pno scan fr */
-	pfn_param.scan_freq = cpu_to_le32(scan_freq);
 
 	if (mscan) {
 		pfnmem = bestn;
@@ -136,15 +132,40 @@ static int brcmf_pno_config(struct brcmf_if *ifp, u32 scan_freq,
 			goto exit;
 		}
 		mscan = min_t(u32, mscan, pfnmem);
-		pfn_param.mscan = mscan;
-		pfn_param.bestn = bestn;
+		pfn_mscan = mscan;
+		pfn_bestn = bestn;
 		flags |= BIT(BRCMF_PNO_ENABLE_BD_SCAN_BIT);
 		brcmf_dbg(INFO, "mscan=%d, bestn=%d\n", mscan, bestn);
 	}
 
-	pfn_param.flags = cpu_to_le16(flags);
-	err = brcmf_fil_iovar_data_set(ifp, "pfn_set", &pfn_param,
-				       sizeof(pfn_param));
+	if (pi->version == BRCMF_PNO_VERSION_3) {
+		struct brcmf_pno_param_v3_le pfn_param = {
+			.version = cpu_to_le16(BRCMF_PNO_VERSION_3),
+			.length = cpu_to_le16(sizeof(pfn_param)),
+			.scan_freq = cpu_to_le32(scan_freq),
+			.flags = cpu_to_le16(flags),
+			.bestn = pfn_bestn,
+			.mscan = pfn_mscan,
+			.repeat = BRCMF_PNO_REPEAT,
+			.exp = BRCMF_PNO_FREQ_EXPO_MAX,
+		};
+
+		err = brcmf_fil_iovar_data_set(ifp, "pfn_set", &pfn_param,
+					       sizeof(pfn_param));
+	} else {
+		struct brcmf_pno_param_le pfn_param = {
+			.version = cpu_to_le32(BRCMF_PNO_VERSION_2),
+			.scan_freq = cpu_to_le32(scan_freq),
+			.flags = cpu_to_le16(flags),
+			.bestn = pfn_bestn,
+			.mscan = pfn_mscan,
+			.repeat = BRCMF_PNO_REPEAT,
+			.exp = BRCMF_PNO_FREQ_EXPO_MAX,
+		};
+
+		err = brcmf_fil_iovar_data_set(ifp, "pfn_set", &pfn_param,
+					       sizeof(pfn_param));
+	}
 	if (err)
 		bphy_err(drvr, "pfn_set failed, err=%d\n", err);
 
@@ -517,6 +538,8 @@ int brcmf_pno_stop_sched_scan(struct brcmf_if *ifp, u64 reqid)
 
 int brcmf_pno_attach(struct brcmf_cfg80211_info *cfg)
 {
+	struct brcmf_if *ifp = brcmf_get_ifp(cfg->pub, 0);
+	struct brcmf_pno_param_v3_le param = {};
 	struct brcmf_pno_info *pi;
 
 	brcmf_dbg(TRACE, "enter\n");
@@ -524,6 +547,11 @@ int brcmf_pno_attach(struct brcmf_cfg80211_info *cfg)
 	if (!pi)
 		return -ENOMEM;
 
+	pi->version = BRCMF_PNO_VERSION_2;
+	if (!brcmf_fil_iovar_data_get(ifp, "pfn_set", &param, sizeof(param)) &&
+	    le16_to_cpu(param.version) == BRCMF_PNO_VERSION_3)
+		pi->version = BRCMF_PNO_VERSION_3;
+
 	cfg->pno = pi;
 	mutex_init(&pi->req_lock);
 	return 0;
@@ -565,8 +593,86 @@ u64 brcmf_pno_find_reqid_by_bucket(struct brcmf_pno_info *pi, u32 bucket)
 	return reqid;
 }
 
+static bool brcmf_pno_get_layout(const struct brcmf_pno_scanresults_le *res,
+				 size_t *hdr_len, size_t *size)
+{
+	switch (le32_to_cpu(res->version)) {
+	case 3:
+		*hdr_len = sizeof(struct brcmf_pno_scanresults_v2_le);
+		*size = sizeof(struct brcmf_pno_net_info_v3_le);
+		return true;
+	case 2:
+		*hdr_len = sizeof(struct brcmf_pno_scanresults_v2_le);
+		*size = sizeof(struct brcmf_pno_net_info_le);
+		return false;
+	default:
+		WARN_ON_ONCE(1);
+		fallthrough;
+	case 1:
+		*hdr_len = sizeof(*res);
+		*size = sizeof(struct brcmf_pno_net_info_le);
+		return false;
+	}
+}
+
+int brcmf_pno_check_results(const void *data, u32 datalen, u32 count)
+{
+	const struct brcmf_pno_scanresults_le *res = data;
+	size_t hdr_len, size;
+
+	if (datalen < sizeof(*res))
+		return -EINVAL;
+
+	brcmf_pno_get_layout(res, &hdr_len, &size);
+	if (datalen < hdr_len || (datalen - hdr_len) / size < count)
+		return -EINVAL;
+
+	return 0;
+}
+
+int brcmf_pno_get_netinfo(struct brcmu_d11inf *d11inf, const void *data,
+			  u32 datalen, u32 idx, struct brcmf_pno_netinfo *ni)
+{
+	const struct brcmf_pno_scanresults_le *res = data;
+	const struct brcmf_pno_net_info_v3_le *v3;
+	const struct brcmf_pno_net_info_le *v1;
+	struct brcmu_chan ch = {};
+	size_t hdr_len, size;
+	bool is_v3;
+
+	memset(ni, 0, sizeof(*ni));
+
+	if (datalen < sizeof(*res))
+		return -EINVAL;
+
+	is_v3 = brcmf_pno_get_layout(res, &hdr_len, &size);
+	if (datalen < hdr_len || (datalen - hdr_len) / size <= idx)
+		return -EINVAL;
+
+	if (is_v3) {
+		v3 = data + hdr_len + idx * size;
+		ni->ssid_len = min_t(u8, v3->SSID_len, IEEE80211_MAX_SSID_LEN);
+		memcpy(ni->ssid, v3->SSID, ni->ssid_len);
+		memcpy(ni->bssid, v3->bssid, ETH_ALEN);
+		ch.chspec = le16_to_cpu(v3->chanspec);
+		d11inf->decchspec(&ch);
+		ni->channel = ch.control_ch_num;
+		ni->band = ch.band;
+	} else {
+		v1 = data + hdr_len + idx * size;
+		ni->ssid_len = min_t(u8, v1->SSID_len, IEEE80211_MAX_SSID_LEN);
+		memcpy(ni->ssid, v1->SSID, ni->ssid_len);
+		memcpy(ni->bssid, v1->bssid, ETH_ALEN);
+		ni->channel = v1->channel;
+		ni->band = v1->channel <= CH_MAX_2G_CHANNEL ?
+			   BRCMU_CHAN_BAND_2G : BRCMU_CHAN_BAND_5G;
+	}
+
+	return 0;
+}
+
 u32 brcmf_pno_get_bucket_map(struct brcmf_pno_info *pi,
-			     struct brcmf_pno_net_info_le *ni)
+			     const struct brcmf_pno_netinfo *ni)
 {
 	struct cfg80211_sched_scan_request *req;
 	struct cfg80211_match_set *ms;
@@ -581,8 +687,8 @@ u32 brcmf_pno_get_bucket_map(struct brcmf_pno_info *pi,
 			continue;
 		for (j = 0; j < req->n_match_sets; j++) {
 			ms = &req->match_sets[j];
-			if (ms->ssid.ssid_len == ni->SSID_len &&
-			    !memcmp(ms->ssid.ssid, ni->SSID, ni->SSID_len)) {
+			if (ms->ssid.ssid_len == ni->ssid_len &&
+			    !memcmp(ms->ssid.ssid, ni->ssid, ni->ssid_len)) {
 				bucket_map |= BIT(i);
 				break;
 			}
diff --git a/drivers/net/wireless/broadcom/brcm80211/brcmfmac/pno.h b/drivers/net/wireless/broadcom/brcm80211/brcmfmac/pno.h
index 25d406019ac3..a47918244e1a 100644
--- a/drivers/net/wireless/broadcom/brcm80211/brcmfmac/pno.h
+++ b/drivers/net/wireless/broadcom/brcm80211/brcmfmac/pno.h
@@ -12,6 +12,24 @@
 
 /* forward declaration */
 struct brcmf_pno_info;
+struct brcmu_d11inf;
+
+/**
+ * struct brcmf_pno_netinfo - network found by a PNO scan.
+ *
+ * @bssid: BSS network identifier.
+ * @ssid: ssid characters.
+ * @ssid_len: length of ssid.
+ * @channel: control channel number.
+ * @band: band of the channel, one of the BRCMU_CHAN_BAND_* values.
+ */
+struct brcmf_pno_netinfo {
+	u8 bssid[ETH_ALEN];
+	u8 ssid[IEEE80211_MAX_SSID_LEN];
+	u8 ssid_len;
+	u8 channel;
+	u8 band;
+};
 
 /**
  * brcmf_pno_start_sched_scan - initiate scheduled scan on device.
@@ -60,6 +78,27 @@ void brcmf_pno_detach(struct brcmf_cfg80211_info *cfg);
  */
 u64 brcmf_pno_find_reqid_by_bucket(struct brcmf_pno_info *pi, u32 bucket);
 
+/**
+ * brcmf_pno_check_results - validate PNO scan results buffer length.
+ *
+ * @data: PNO scan results event data.
+ * @datalen: length of @data.
+ * @count: number of network entries reported in the results header.
+ */
+int brcmf_pno_check_results(const void *data, u32 datalen, u32 count);
+
+/**
+ * brcmf_pno_get_netinfo - extract a network from PNO scan results.
+ *
+ * @d11inf: chanspec conversion functions.
+ * @data: PNO scan results event data.
+ * @datalen: length of @data.
+ * @idx: index of the network in the results.
+ * @ni: network information to fill in.
+ */
+int brcmf_pno_get_netinfo(struct brcmu_d11inf *d11inf, const void *data,
+			  u32 datalen, u32 idx, struct brcmf_pno_netinfo *ni);
+
 /**
  * brcmf_pno_get_bucket_map - determine bucket map for given netinfo.
  *
@@ -67,6 +106,6 @@ u64 brcmf_pno_find_reqid_by_bucket(struct brcmf_pno_info *pi, u32 bucket);
  * @netinfo: netinfo to compare with bucket configuration.
  */
 u32 brcmf_pno_get_bucket_map(struct brcmf_pno_info *pi,
-			     struct brcmf_pno_net_info_le *netinfo);
+			     const struct brcmf_pno_netinfo *netinfo);
 
 #endif /* _BRCMF_PNO_H */

-- 
2.56.0

