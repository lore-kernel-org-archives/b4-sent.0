From: Christopher Griffin <christophergriffin05@gmail.com>
Date: Wed, 04 Nov 2026 09:37:44 -0600
Subject: [PATCH] Do not show a hidden SSID in unsolicited broadcast Probe
 Responses
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261104-b30-unsol-probe-resp-hidden-ssid-v1-1-18431b9a4c79@gmail.com>
X-B4-Tracking: v=1; b=H4sIAEdR62oC/yXNTQrCQAxA4auUrA3MT6niVcRFp4k2IjND0opQe
 ndHXX6b9zYwVmGDc7eB8ktMSm7whw6mecx3RqFmCC4M3rseU3S4ZitPrFoSo7JVnIWIM5oJIY2
 ndBwiBddHaJmqfJP3b3G5/m1revC0fLuw7x8RbTAphAAAAA==
X-Change-ID: 20261104-b30-unsol-probe-resp-hidden-ssid-da8b763d2043
To: hostap@lists.infradead.org
Cc: Christopher Griffin <christophergriffin05@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793806664; l=4878;
 i=christophergriffin05@gmail.com; s=20261024; h=from:subject:message-id;
 bh=KbPSp98Bkm8Y3LoKQ11KhWcSUE0m7Y0zFZv6xZMS2+Q=;
 b=o0lLKqXtT28FFmmHRkzRv9X4185rpeF5XHzPOE0tPG90rbseihkJ9WRQ7ksmtfNKzqj86CjPT
 XQTXLR90+sFDqEVCF7G2l9AtHNQ987gAJPcgAIkv9yLUZUqr5CLFCHc
X-Developer-Key: i=christophergriffin05@gmail.com; a=ed25519;
 pk=oa9tkTNpiGoFWdGvpDHXLSobApmsh9BfrJRJrRJAvWA=
X-Endpoint-Received: by B4 Relay for christophergriffin05@gmail.com/20261024 with auth_id=1309
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

hostapd_unsol_bcast_probe_resp() builds the 6 GHz unsolicited broadcast
Probe Response frame template with the SSID element of a solicited
Probe Response frame, which always carries the actual SSID. With
ignore_broadcast_ssid set, the Beacon frames hide the SSID, but the
unsolicited broadcast Probe Response frames, sent to all every
unsol_bcast_probe_resp_interval, show it.

Write the SSID element of the unsolicited template as in Beacon frames:
empty with ignore_broadcast_ssid=1, zeroed with 2. Move that code from
ieee802_11_build_ap_params() into a helper for both. Solicited Probe
Response frames and the Probe Response offload template keep the
actual SSID.

Tested on an Arista W-318 (ath11k, QCN9072) on 6 GHz channel 37 with
a hidden BSS and unsol_bcast_probe_resp_interval=20, reading the
templates hostapd passes to nl80211 (nlmon). Before, the unsolicited
template carried the SSID while the Beacon frame head had an empty
SSID element. After, both have an empty SSID element, or with
ignore_broadcast_ssid=2 a zeroed one of the SSID's length. Without
ignore_broadcast_ssid, both carry the SSID as before.

Assisted-by: Claude:claude-opus-5-5
Signed-off-by: Christopher Griffin <christophergriffin05@gmail.com>
---
OpenWrt does not set unsol_bcast_probe_resp_interval by default, so
its users hit this only through raw hostapd options.
---
 src/ap/beacon.c | 49 ++++++++++++++++++++++++++++++-------------------
 1 file changed, 30 insertions(+), 19 deletions(-)

diff --git a/src/ap/beacon.c b/src/ap/beacon.c
index d7b9874..86baf39 100644
--- a/src/ap/beacon.c
+++ b/src/ap/beacon.c
@@ -88,6 +88,29 @@ static u8 ieee802_11_erp_info(struct hostapd_data *hapd)
 }
 
 
+/* SSID element; hide_ssid applies ignore_broadcast_ssid as in Beacon frames */
+static u8 * hostapd_eid_ssid(struct hostapd_data *hapd, u8 *pos,
+			     bool hide_ssid)
+{
+	*pos++ = WLAN_EID_SSID;
+	if (hide_ssid && hapd->conf->ignore_broadcast_ssid == 2) {
+		/* clear the data, but keep the correct length of the SSID */
+		*pos++ = hapd->conf->ssid.ssid_len;
+		os_memset(pos, 0, hapd->conf->ssid.ssid_len);
+		pos += hapd->conf->ssid.ssid_len;
+	} else if (hide_ssid && hapd->conf->ignore_broadcast_ssid) {
+		*pos++ = 0; /* empty SSID */
+	} else {
+		*pos++ = hapd->conf->ssid.ssid_len;
+		os_memcpy(pos, hapd->conf->ssid.ssid,
+			  hapd->conf->ssid.ssid_len);
+		pos += hapd->conf->ssid.ssid_len;
+	}
+
+	return pos;
+}
+
+
 static u8 * hostapd_eid_ds_params(struct hostapd_data *hapd, u8 *eid)
 {
 	enum hostapd_hw_mode hw_mode = hapd->iconf->hw_mode;
@@ -738,6 +761,8 @@ static size_t he_elem_len(struct hostapd_data *hapd)
 struct probe_resp_params {
 	const struct ieee80211_mgmt *req;
 	bool is_p2p;
+	/* Unsolicited broadcast Probe Response template */
+	bool unsol_bcast;
 
 	/* Generated IEs will be included inside an ML element */
 	struct hostapd_data *mld_ap;
@@ -874,11 +899,9 @@ static u8 * hostapd_probe_resp_fill_elems(struct hostapd_data *hapd,
 	hapd = hostapd_mbssid_get_tx_bss(hapd);
 	epos = pos + len;
 
-	*pos++ = WLAN_EID_SSID;
-	*pos++ = hapd->conf->ssid.ssid_len;
-	os_memcpy(pos, hapd->conf->ssid.ssid,
-		  hapd->conf->ssid.ssid_len);
-	pos += hapd->conf->ssid.ssid_len;
+	/* An unsolicited broadcast Probe Response frame is sent to all, like
+	 * a Beacon frame, so it must not show the SSID a Beacon frame hides. */
+	pos = hostapd_eid_ssid(hapd, pos, params->unsol_bcast);
 
 	/* Supported rates */
 	pos = hostapd_eid_supp_rates(hapd, pos);
@@ -1920,6 +1943,7 @@ u8 * hostapd_unsol_bcast_probe_resp(struct hostapd_data *hapd,
 	os_memset(&probe_params, 0, sizeof(probe_params));
 	probe_params.req = NULL;
 	probe_params.is_p2p = false;
+	probe_params.unsol_bcast = true;
 	probe_params.known_bss = NULL;
 	probe_params.known_bss_len = 0;
 	probe_params.mld_ap = NULL;
@@ -2392,20 +2416,7 @@ int ieee802_11_build_ap_params(struct hostapd_data *hapd,
 	pos = &head->u.beacon.variable[0];
 
 	/* SSID */
-	*pos++ = WLAN_EID_SSID;
-	if (hapd->conf->ignore_broadcast_ssid == 2) {
-		/* clear the data, but keep the correct length of the SSID */
-		*pos++ = hapd->conf->ssid.ssid_len;
-		os_memset(pos, 0, hapd->conf->ssid.ssid_len);
-		pos += hapd->conf->ssid.ssid_len;
-	} else if (hapd->conf->ignore_broadcast_ssid) {
-		*pos++ = 0; /* empty SSID */
-	} else {
-		*pos++ = hapd->conf->ssid.ssid_len;
-		os_memcpy(pos, hapd->conf->ssid.ssid,
-			  hapd->conf->ssid.ssid_len);
-		pos += hapd->conf->ssid.ssid_len;
-	}
+	pos = hostapd_eid_ssid(hapd, pos, true);
 
 	/* Supported rates */
 	pos = hostapd_eid_supp_rates(hapd, pos);

---
base-commit: 412ff0d7f4d2b346df63be52c4201ee7ab0dc804
change-id: 20261104-b30-unsol-probe-resp-hidden-ssid-da8b763d2043

Best regards,
--  
Christopher Griffin <christophergriffin05@gmail.com>

