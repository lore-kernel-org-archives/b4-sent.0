From: Michael Reeves <michael.reeves077@gmail.com>
Date: Fri, 25 Sep 2026 23:43:42 +1000
Subject: [PATCH 07/13] wifi: brcmfmac: Use event_msgs_ext for event masks
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260925-brcm4388-submit-v1-7-b5cbc2cde2fb@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790343821; l=13074;
 i=michael.reeves077@gmail.com; s=fedora-20260918; h=from:subject:message-id;
 bh=FRG6tUUizYoumB0K87m2z0Yh8XdJwwc0mIsYEg2R708=;
 b=/jqkdO9EsyE3WGCOaeXPoK3R4L1emZkd3S+BkqTywohjCNDimMV7i/1MWmJGkyK61hecZZM0J
 rIn1E/6f3NoDUANeEIgxtkmwx/K4JRlwDUmdKz6nLy7E1mZp4cI1Z1z
X-Developer-Key: i=michael.reeves077@gmail.com; a=ed25519;
 pk=VJ0TvyQ9TvfzYZa908YSE9kpkjFLLD5luv0bERu+boc=
X-Endpoint-Received: by B4 Relay for michael.reeves077@gmail.com/fedora-20260918 with auth_id=1035
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

BCM4388 firmware rejects the legacy event_msgs query during preinit but
supports the structured event_msgs_ext command.

Probe event_msgs_ext during feature detection and initialize the event
mask after feature flags are set. Use the extended command when
supported and retain the legacy path otherwise.

Co-developed-by: Hector Martin <marcan@marcan.st>
Signed-off-by: Hector Martin <marcan@marcan.st>
Signed-off-by: Michael Reeves <michael.reeves077@gmail.com>
---
 .../wireless/broadcom/brcm80211/brcmfmac/common.c  |  23 ----
 .../wireless/broadcom/brcm80211/brcmfmac/core.c    |   5 +-
 .../wireless/broadcom/brcm80211/brcmfmac/feature.c |  39 +++++++
 .../wireless/broadcom/brcm80211/brcmfmac/feature.h |   2 +
 .../wireless/broadcom/brcm80211/brcmfmac/fweh.c    | 130 ++++++++++++++++++++-
 .../wireless/broadcom/brcm80211/brcmfmac/fweh.h    |   1 +
 .../broadcom/brcm80211/brcmfmac/fwil_types.h       |  26 +++++
 7 files changed, 199 insertions(+), 27 deletions(-)

diff --git a/drivers/net/wireless/broadcom/brcm80211/brcmfmac/common.c b/drivers/net/wireless/broadcom/brcm80211/brcmfmac/common.c
index 2a37b42ca9..93458c2fbc 100644
--- a/drivers/net/wireless/broadcom/brcm80211/brcmfmac/common.c
+++ b/drivers/net/wireless/broadcom/brcm80211/brcmfmac/common.c
@@ -269,7 +269,6 @@ static int brcmf_c_process_cal_blob(struct brcmf_if *ifp)
 int brcmf_c_preinit_dcmds(struct brcmf_if *ifp)
 {
 	struct brcmf_pub *drvr = ifp->drvr;
-	struct brcmf_fweh_info *fweh = drvr->fweh;
 	u8 buf[BRCMF_DCMD_SMLEN];
 	struct brcmf_bus *bus;
 	struct brcmf_rev_info_le revinfo;
@@ -415,27 +414,6 @@ int brcmf_c_preinit_dcmds(struct brcmf_if *ifp)
 
 	brcmf_c_set_joinpref_default(ifp);
 
-	/* Setup event_msgs, enable E_IF */
-	err = brcmf_fil_iovar_data_get(ifp, "event_msgs", fweh->event_mask,
-				       fweh->event_mask_len);
-	if (err) {
-		bphy_err(drvr, "Get event_msgs error (%d)\n", err);
-		goto done;
-	}
-	/*
-	 * BRCMF_E_IF can safely be used to set the appropriate bit
-	 * in the event_mask as the firmware event code is guaranteed
-	 * to match the value of BRCMF_E_IF because it is old cruft
-	 * that all vendors have.
-	 */
-	setbit(fweh->event_mask, BRCMF_E_IF);
-	err = brcmf_fil_iovar_data_set(ifp, "event_msgs", fweh->event_mask,
-				       fweh->event_mask_len);
-	if (err) {
-		bphy_err(drvr, "Set event_msgs error (%d)\n", err);
-		goto done;
-	}
-
 	/* Setup default scan channel time */
 	err = brcmf_fil_cmd_int_set(ifp, BRCMF_C_SET_SCAN_CHANNEL_TIME,
 				    BRCMF_DEFAULT_SCAN_CHANNEL_TIME);
@@ -637,4 +615,3 @@ static void __exit brcmfmac_module_exit(void)
 
 module_init(brcmfmac_module_init);
 module_exit(brcmfmac_module_exit);
-
diff --git a/drivers/net/wireless/broadcom/brcm80211/brcmfmac/core.c b/drivers/net/wireless/broadcom/brcm80211/brcmfmac/core.c
index d2ae679856..bb9a0aeb06 100644
--- a/drivers/net/wireless/broadcom/brcm80211/brcmfmac/core.c
+++ b/drivers/net/wireless/broadcom/brcm80211/brcmfmac/core.c
@@ -1260,6 +1260,10 @@ static int brcmf_bus_started(struct brcmf_pub *drvr, struct cfg80211_ops *ops)
 
 	brcmf_feat_attach(drvr);
 
+	ret = brcmf_fweh_init_events(ifp);
+	if (ret < 0)
+		goto fail;
+
 	ret = brcmf_proto_init_done(drvr);
 	if (ret < 0)
 		goto fail;
@@ -1613,4 +1617,3 @@ void __exit brcmf_core_exit(void)
 	brcmf_usb_exit();
 	brcmf_pcie_exit();
 }
-
diff --git a/drivers/net/wireless/broadcom/brcm80211/brcmfmac/feature.c b/drivers/net/wireless/broadcom/brcm80211/brcmfmac/feature.c
index a3c221117d..d289451644 100644
--- a/drivers/net/wireless/broadcom/brcm80211/brcmfmac/feature.c
+++ b/drivers/net/wireless/broadcom/brcm80211/brcmfmac/feature.c
@@ -5,6 +5,7 @@
 
 #include <linux/netdevice.h>
 #include <linux/module.h>
+#include <linux/slab.h>
 
 #include <brcm_hw_ids.h>
 #include <brcmu_wifi.h>
@@ -226,6 +227,43 @@ static void brcmf_feat_iovar_data_set(struct brcmf_if *ifp,
 	ifp->fwil_fwerr = false;
 }
 
+static void brcmf_feat_event_msgs_ext(struct brcmf_if *ifp)
+{
+	struct brcmf_pub *drvr = ifp->drvr;
+	struct brcmf_fweh_info *fweh = drvr->fweh;
+	struct brcmf_eventmsgs_ext_le *eventmsgs;
+	size_t size;
+	int err;
+
+	if (!fweh || fweh->event_mask_len > 0xff)
+		return;
+
+	size = struct_size(eventmsgs, mask, fweh->event_mask_len);
+	eventmsgs = kzalloc(size, GFP_KERNEL);
+	if (!eventmsgs)
+		return;
+
+	eventmsgs->version = EVENTMSGS_VER;
+	eventmsgs->command = EVENTMSGS_NONE;
+	eventmsgs->len = fweh->event_mask_len;
+	eventmsgs->maxgetsize = fweh->event_mask_len;
+
+	ifp->fwil_fwerr = true;
+	err = brcmf_fil_iovar_data_get(ifp, "event_msgs_ext", eventmsgs, size);
+	ifp->fwil_fwerr = false;
+
+	if (!err) {
+		brcmf_dbg(INFO, "enabling feature: %s\n",
+			  brcmf_feat_names[BRCMF_FEAT_EVENT_MSGS_EXT]);
+		drvr->feat_flags |= BIT(BRCMF_FEAT_EVENT_MSGS_EXT);
+	} else {
+		brcmf_dbg(TRACE, "%s feature check failed: %d\n",
+			  brcmf_feat_names[BRCMF_FEAT_EVENT_MSGS_EXT], err);
+	}
+
+	kfree(eventmsgs);
+}
+
 #define MAX_CAPS_BUFFER_SIZE	768
 static void brcmf_feat_firmware_capabilities(struct brcmf_if *ifp)
 {
@@ -348,6 +386,7 @@ void brcmf_feat_attach(struct brcmf_pub *drvr)
 
 	brcmf_feat_iovar_int_get(ifp, BRCMF_FEAT_FWSUP, "sup_wpa");
 	brcmf_feat_iovar_int_get(ifp, BRCMF_FEAT_SCAN_V2, "scan_ver");
+	brcmf_feat_event_msgs_ext(ifp);
 
 	brcmf_feat_wlc_version_overrides(drvr);
 	brcmf_feat_firmware_overrides(drvr);
diff --git a/drivers/net/wireless/broadcom/brcm80211/brcmfmac/feature.h b/drivers/net/wireless/broadcom/brcm80211/brcmfmac/feature.h
index 8165a286b6..45a05642bb 100644
--- a/drivers/net/wireless/broadcom/brcm80211/brcmfmac/feature.h
+++ b/drivers/net/wireless/broadcom/brcm80211/brcmfmac/feature.h
@@ -31,6 +31,7 @@
  * FWAUTH: Firmware authenticator
  * DUMP_OBSS: Firmware has capable to dump obss info to support ACS
  * SCAN_V2: Version 2 scan params
+ * EVENT_MSGS_EXT: Firmware supports event_msgs_ext for event masks
  * SAE_EXT: SAE authentication handled by user-space supplicant
  */
 #define BRCMF_FEAT_LIST \
@@ -59,6 +60,7 @@
 	BRCMF_FEAT_DEF(SCAN_V2) \
 	BRCMF_FEAT_DEF(PMKID_V2) \
 	BRCMF_FEAT_DEF(PMKID_V3) \
+	BRCMF_FEAT_DEF(EVENT_MSGS_EXT) \
 	BRCMF_FEAT_DEF(SAE_EXT) \
 	BRCMF_FEAT_DEF(FBT) \
 	BRCMF_FEAT_DEF(OKC)
diff --git a/drivers/net/wireless/broadcom/brcm80211/brcmfmac/fweh.c b/drivers/net/wireless/broadcom/brcm80211/brcmfmac/fweh.c
index 1cff4ba769..034f90ad6c 100644
--- a/drivers/net/wireless/broadcom/brcm80211/brcmfmac/fweh.c
+++ b/drivers/net/wireless/broadcom/brcm80211/brcmfmac/fweh.c
@@ -12,7 +12,9 @@
 #include "debug.h"
 #include "tracepoint.h"
 #include "fweh.h"
+#include "feature.h"
 #include "fwil.h"
+#include "fwil_types.h"
 #include "proto.h"
 #include "bus.h"
 #include "fwvid.h"
@@ -430,6 +432,128 @@ void brcmf_fweh_unregister(struct brcmf_pub *drvr,
 	drvr->fweh->evt_handler[evt_handler_idx] = NULL;
 }
 
+static bool brcmf_fweh_use_event_msgs_ext(struct brcmf_if *ifp)
+{
+	return brcmf_feat_is_enabled(ifp, BRCMF_FEAT_EVENT_MSGS_EXT);
+}
+
+static const char *brcmf_fweh_event_mask_iovar(struct brcmf_if *ifp)
+{
+	return brcmf_fweh_use_event_msgs_ext(ifp) ? "event_msgs_ext" :
+						    "event_msgs";
+}
+
+static int brcmf_fweh_get_event_mask(struct brcmf_if *ifp)
+{
+	struct brcmf_pub *drvr = ifp->drvr;
+	struct brcmf_fweh_info *fweh = drvr->fweh;
+	struct brcmf_eventmsgs_ext_le *eventmsgs;
+	size_t size;
+	u8 fw_len;
+	int err;
+
+	memset(fweh->event_mask, 0, fweh->event_mask_len);
+
+	if (!brcmf_fweh_use_event_msgs_ext(ifp))
+		return brcmf_fil_iovar_data_get(ifp, "event_msgs",
+						fweh->event_mask,
+						fweh->event_mask_len);
+
+	if (fweh->event_mask_len > 0xff)
+		return -E2BIG;
+
+	size = struct_size(eventmsgs, mask, fweh->event_mask_len);
+	eventmsgs = kzalloc(size, GFP_KERNEL);
+	if (!eventmsgs)
+		return -ENOMEM;
+
+	eventmsgs->version = EVENTMSGS_VER;
+	eventmsgs->command = EVENTMSGS_NONE;
+	eventmsgs->len = fweh->event_mask_len;
+	eventmsgs->maxgetsize = fweh->event_mask_len;
+
+	err = brcmf_fil_iovar_data_get(ifp, "event_msgs_ext", eventmsgs, size);
+	if (!err) {
+		fw_len = eventmsgs->len;
+		memcpy(fweh->event_mask, eventmsgs->mask,
+		       min_t(u8, fw_len, fweh->event_mask_len));
+		if (fw_len != fweh->event_mask_len)
+			brcmf_dbg(EVENT, "event_msgs_ext returned mask len=%u, driver len=%u\n",
+				  fw_len, fweh->event_mask_len);
+	}
+
+	kfree(eventmsgs);
+	return err;
+}
+
+static int brcmf_fweh_set_event_mask(struct brcmf_if *ifp)
+{
+	struct brcmf_pub *drvr = ifp->drvr;
+	struct brcmf_fweh_info *fweh = drvr->fweh;
+	struct brcmf_eventmsgs_ext_le *eventmsgs;
+	size_t size;
+	int err;
+
+	if (!brcmf_fweh_use_event_msgs_ext(ifp))
+		return brcmf_fil_iovar_data_set(ifp, "event_msgs",
+						fweh->event_mask,
+						fweh->event_mask_len);
+
+	if (fweh->event_mask_len > 0xff)
+		return -E2BIG;
+
+	size = struct_size(eventmsgs, mask, fweh->event_mask_len);
+	eventmsgs = kzalloc(size, GFP_KERNEL);
+	if (!eventmsgs)
+		return -ENOMEM;
+
+	eventmsgs->version = EVENTMSGS_VER;
+	eventmsgs->command = EVENTMSGS_SET_MASK;
+	eventmsgs->len = fweh->event_mask_len;
+	memcpy(eventmsgs->mask, fweh->event_mask, fweh->event_mask_len);
+
+	err = brcmf_fil_iovar_data_set(ifp, "event_msgs_ext", eventmsgs, size);
+
+	kfree(eventmsgs);
+	return err;
+}
+
+/**
+ * brcmf_fweh_init_events() - initialize firmware event mask.
+ *
+ * @ifp: primary interface object.
+ */
+int brcmf_fweh_init_events(struct brcmf_if *ifp)
+{
+	struct brcmf_pub *drvr = ifp->drvr;
+	struct brcmf_fweh_info *fweh = drvr->fweh;
+	const char *iovar = brcmf_fweh_event_mask_iovar(ifp);
+	int err;
+
+	brcmf_dbg(EVENT, "using %s for firmware event masks (len=%u)\n", iovar,
+		  fweh->event_mask_len);
+
+	err = brcmf_fweh_get_event_mask(ifp);
+	if (err) {
+		bphy_err(drvr, "Get %s error (%d)\n", iovar, err);
+		return err;
+	}
+
+	/*
+	 * BRCMF_E_IF can safely be used to set the appropriate bit in the
+	 * event mask as the firmware event code is guaranteed to match the
+	 * value of BRCMF_E_IF because it is old cruft that all vendors have.
+	 */
+	brcmf_dbg(EVENT, "enable event IF\n");
+	setbit(fweh->event_mask, BRCMF_E_IF);
+
+	err = brcmf_fweh_set_event_mask(ifp);
+	if (err)
+		bphy_err(drvr, "Set %s error (%d)\n", iovar, err);
+
+	return err;
+}
+
 /**
  * brcmf_fweh_activate_events() - enables firmware events registered.
  *
@@ -439,6 +563,7 @@ int brcmf_fweh_activate_events(struct brcmf_if *ifp)
 {
 	struct brcmf_fweh_info *fweh = ifp->drvr->fweh;
 	enum brcmf_fweh_event_code code;
+	const char *iovar = brcmf_fweh_event_mask_iovar(ifp);
 	int i, err;
 
 	memset(fweh->event_mask, 0, fweh->event_mask_len);
@@ -459,10 +584,9 @@ int brcmf_fweh_activate_events(struct brcmf_if *ifp)
 	if (!brcmf_fwvid_activate_events(ifp))
 		return 0;
 
-	err = brcmf_fil_iovar_data_set(ifp, "event_msgs", fweh->event_mask,
-				       fweh->event_mask_len);
+	err = brcmf_fweh_set_event_mask(ifp);
 	if (err)
-		bphy_err(fweh->drvr, "Set event_msgs error (%d)\n", err);
+		bphy_err(fweh->drvr, "Set %s error (%d)\n", iovar, err);
 	return err;
 }
 
diff --git a/drivers/net/wireless/broadcom/brcm80211/brcmfmac/fweh.h b/drivers/net/wireless/broadcom/brcm80211/brcmfmac/fweh.h
index e327dd58d2..53c4b58e63 100644
--- a/drivers/net/wireless/broadcom/brcm80211/brcmfmac/fweh.h
+++ b/drivers/net/wireless/broadcom/brcm80211/brcmfmac/fweh.h
@@ -356,6 +356,7 @@ int brcmf_fweh_register(struct brcmf_pub *drvr, enum brcmf_fweh_event_code code,
 				       void *data));
 void brcmf_fweh_unregister(struct brcmf_pub *drvr,
 			   enum brcmf_fweh_event_code code);
+int brcmf_fweh_init_events(struct brcmf_if *ifp);
 int brcmf_fweh_activate_events(struct brcmf_if *ifp);
 void brcmf_fweh_process_event(struct brcmf_pub *drvr,
 			      struct brcmf_event *event_packet,
diff --git a/drivers/net/wireless/broadcom/brcm80211/brcmfmac/fwil_types.h b/drivers/net/wireless/broadcom/brcm80211/brcmfmac/fwil_types.h
index e74a23e118..d591f17960 100644
--- a/drivers/net/wireless/broadcom/brcm80211/brcmfmac/fwil_types.h
+++ b/drivers/net/wireless/broadcom/brcm80211/brcmfmac/fwil_types.h
@@ -1236,4 +1236,30 @@ struct brcmf_mkeep_alive_pkt_le {
 	u8   data[];
 } __packed;
 
+enum event_msgs_ext_command {
+	EVENTMSGS_NONE		= 0,
+	EVENTMSGS_SET_BIT	= 1,
+	EVENTMSGS_RESET_BIT	= 2,
+	EVENTMSGS_SET_MASK	= 3,
+};
+
+#define EVENTMSGS_VER		1
+
+/**
+ * struct brcmf_eventmsgs_ext_le - event_msgs_ext iovar data
+ *
+ * @version: structure version.
+ * @command: requested operation.
+ * @len: mask size for set, actual firmware mask size for get.
+ * @maxgetsize: maximum mask size that may be returned by firmware.
+ * @mask: event mask.
+ */
+struct brcmf_eventmsgs_ext_le {
+	u8 version;
+	u8 command;
+	u8 len;
+	u8 maxgetsize;
+	u8 mask[] __counted_by(len);
+};
+
 #endif /* FWIL_TYPES_H_ */

-- 
2.55.0

