From: Christopher Griffin <christophergriffin05@gmail.com>
Date: Wed, 04 Nov 2026 09:37:43 -0600
Subject: [PATCH] FT: Configure the PTK after association with full AP
 client state
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261104-b137-ft-ptk-after-assoc-v1-1-fcc4dc98d305@gmail.com>
X-B4-Tracking: v=1; b=H4sIAEZR62oC/yXMQQrCMBBG4auUWTuQRDHoVcRFOv2jo9CWTCpC6
 d2NuvwW761kKAqjc7dSwUtNp7HB7zqSexpvYB2aKbhw9N4duPf7yLnyXJ+cckXhZDYJuyGHeAI
 kBqFWzwVZ37/z5fq3Lf0DUr872rYPZubGsnsAAAA=
X-Change-ID: 20261104-b137-ft-ptk-after-assoc-0df279eec72c
To: hostap@lists.infradead.org
Cc: Christopher Griffin <christophergriffin05@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793806662; l=2815;
 i=christophergriffin05@gmail.com; s=20261024; h=from:subject:message-id;
 bh=22Saxk5Pcllxl4evuVQ70SMax27paiXVHzm/9++h2Ak=;
 b=EKVILUMcfIzsjELb2G4HPKH9bGhre7lWZXaUsqSIKiKvgAp7a5WEOYzH8t0SeNfO+cYmPD9jO
 pW04iaUvEi+CDVb7qa7kpFzybOBFNIaQibByT3Fx+2MPdJlmUxAXPTG
X-Developer-Key: i=christophergriffin05@gmail.com; a=ed25519;
 pk=oa9tkTNpiGoFWdGvpDHXLSobApmsh9BfrJRJrRJAvWA=
X-Endpoint-Received: by B4 Relay for christophergriffin05@gmail.com/20261024 with auth_id=1309
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

At FT authentication, wpa_ft_install_ptk() tries to configure the PTK
before the STA is associated. A driver with full AP client state
(mac80211) refuses a pairwise key for an STA that is not associated
yet (-ENOENT), so every FT authentication logs

  nl80211: kernel reports: key addition failed

as an error, and the PTK is configured after association anyway, by
the retry for WPA_ASSOC_FT in wpa_auth_sm_event().

Have the add_sta_ft callback report that case, and skip the attempt
then. The PMF re-add case and EPP STAs are left as they are.

Tested on OpenWrt with ath10k (mac80211) on an Arista W-118, two
FT-PSK BSSs on one radio and a wpa_supplicant station roaming between
them over the air: before, each of 6 roams logged the error; after,
none in 6 roams, all completed, with the station's pairwise key in
mac80211 after the roam and frames received with it.

Assisted-by: Claude:claude-opus-5-5
Signed-off-by: Christopher Griffin <christophergriffin05@gmail.com>
---
OpenWrt sees this line at every FT roam on mac80211 drivers; the roams
themselves were never affected.
---
 src/ap/wpa_auth_ft.c   | 7 +++++--
 src/ap/wpa_auth_glue.c | 8 ++++++++
 2 files changed, 13 insertions(+), 2 deletions(-)

diff --git a/src/ap/wpa_auth_ft.c b/src/ap/wpa_auth_ft.c
index e12f2ad..201c6d4 100644
--- a/src/ap/wpa_auth_ft.c
+++ b/src/ap/wpa_auth_ft.c
@@ -2898,8 +2898,11 @@ void wpa_ft_install_ptk(struct wpa_state_machine *sm, int retry)
 		return;
 	}
 
-	if (!retry)
-		wpa_auth_add_sta_ft(sm->wpa_auth, sm->addr);
+	if (!retry && wpa_auth_add_sta_ft(sm->wpa_auth, sm->addr) == 1) {
+		wpa_printf(MSG_DEBUG,
+			   "FT: Configure the PTK to the driver after association");
+		return;
+	}
 
 	/* FIX: add STA entry to kernel/driver here? The set_key will fail
 	 * most likely without this.. At the moment, STA entry is added only
diff --git a/src/ap/wpa_auth_glue.c b/src/ap/wpa_auth_glue.c
index 9da2e6d..1336171 100644
--- a/src/ap/wpa_auth_glue.c
+++ b/src/ap/wpa_auth_glue.c
@@ -1332,6 +1332,14 @@ static int hostapd_wpa_auth_add_sta_ft(void *ctx, const u8 *sta_addr)
 		return ap_sta_re_add(hapd, sta);
 	}
 
+	/* A driver with full AP client state takes a pairwise key only for
+	 * an associated STA (mac80211 refuses it with -ENOENT before that).
+	 * Have the PTK configured after association instead of trying here
+	 * and logging the driver's refusal at every FT authentication. */
+	if (FULL_AP_CLIENT_STATE_SUPP(hapd->iface->drv_flags) &&
+	    !(sta->flags & WLAN_STA_ASSOC) && !ap_sta_is_epp(sta))
+		return 1;
+
 	return 0;
 }
 

---
base-commit: 412ff0d7f4d2b346df63be52c4201ee7ab0dc804
change-id: 20261104-b137-ft-ptk-after-assoc-0df279eec72c

Best regards,
--  
Christopher Griffin <christophergriffin05@gmail.com>

