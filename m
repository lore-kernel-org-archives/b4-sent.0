From: Christopher Griffin <christophergriffin05@gmail.com>
Date: Sun, 01 Nov 2026 20:22:08 -0600
Subject: [PATCH] FT: Set RSNXE Used in Reassociation Response only with an
 RSNXE
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261101-b128-ft-rsnxe-used-v1-1-080f12ecf18a@gmail.com>
X-B4-Tracking: v=1; b=H4sIAM/z52oC/yXMSQ6DMAxA0asgr7EUhzKUq1QsGBwwi1DFUCEh7
 t4Ay7f4/wDlIKxQJwcE/onK4iMoTaCfWj8yyhAN1tiCyBB2ZCt0Kwb1O+OmPGBJ7t26V1ZZk0M
 Mv4Gd7Pf00zzWrZu5X68TnOcfjedfanYAAAA=
X-Change-ID: 20261101-b128-ft-rsnxe-used-71f9af438205
To: hostap@lists.infradead.org
Cc: Christopher Griffin <christophergriffin05@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793586127; l=2984;
 i=christophergriffin05@gmail.com; s=20261024; h=from:subject:message-id;
 bh=dACoVHh7sMJcaMGq2qOtnUhNC1wqfffbKyBYA6nPNDo=;
 b=uSsFGZPlVoilThohw/UmCVWjAHgrwrharxxYK0BRXEavU4geqcoy27nRW8QFDI/K8LouNl3PC
 wcPqBZBByoTCJfE1YYXXH+8UxOqzvvJFlx5O8B+imKrfd1K0xns685P
X-Developer-Key: i=christophergriffin05@gmail.com; a=ed25519;
 pk=oa9tkTNpiGoFWdGvpDHXLSobApmsh9BfrJRJrRJAvWA=
X-Endpoint-Received: by B4 Relay for christophergriffin05@gmail.com/20261024 with auth_id=1309
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The AP set RSNXE Used in the FTE of an FT protocol Reassociation
Response frame whenever sae_pwe was 1 or 2, for any AKM, while the MIC
covers an RSNXE only when one is written. A BSS with FT-EAP or FT-PSK
and no SAE AKM has no RSNXE, so with sae_pwe set (OpenWrt 25.12 sets it
on such a BSS) the frame claimed an RSNXE that the AP does not
advertise. wpa_supplicant rejects that ("FT: FTE indicated that AP uses
RSNXE, but RSNXE was not included in Beacon/Probe Response frames") and
deauthenticates with reason 13 (invalid element), so every FT roam to
such a BSS failed.

Write the RSNXE before the FTE and set RSNXE Used only when the
response includes one, which is what the MIC covers. Responses that
include an RSNXE, as with SAE H2E, are unchanged.

Assisted-by: Claude:claude-opus-5-5
Signed-off-by: Christopher Griffin <christophergriffin05@gmail.com>
---
Seen with OpenWrt 25.12.2 APs (mt76) whose FT-EAP BSS has sae_pwe=2:
every FT roam to them failed with reason 13. Reproduced with FT-PSK and
sae_pwe=2 on an Arista W-118 (ath10k), wpa_supplicant as the station:
0 of 6 FT roams completed without this patch, each deauthenticated with
reason 13 right after the Reassociation Response; 6 of 6 with it.
---
 src/ap/wpa_auth_ft.c | 27 +++++++++++++++------------
 1 file changed, 15 insertions(+), 12 deletions(-)

diff --git a/src/ap/wpa_auth_ft.c b/src/ap/wpa_auth_ft.c
index e12f2ad..02e9402 100644
--- a/src/ap/wpa_auth_ft.c
+++ b/src/ap/wpa_auth_ft.c
@@ -2714,7 +2714,21 @@ u8 * wpa_sm_write_assoc_resp_ies(struct wpa_state_machine *sm, u8 *pos,
 		anonce = NULL;
 		snonce = NULL;
 	}
-	rsnxe_used = (auth_alg == WLAN_AUTH_FT) &&
+	if (omit_rsnxe) {
+		rsnxe_len = 0;
+	} else {
+		res = wpa_write_rsnxe(&sm->wpa_auth->conf, rsnxe,
+				      sizeof(rsnxe_buf));
+		if (res < 0) {
+			os_free(subelem);
+			return NULL;
+		}
+		rsnxe_len = res;
+	}
+	/* RSNXE Used tells the STA that the MIC covers an RSNXE. Without one
+	 * (e.g., FT-EAP or FT-PSK with sae_pwe set, but no SAE), the STA would
+	 * reject the response for an RSNXE the AP does not advertise. */
+	rsnxe_used = (auth_alg == WLAN_AUTH_FT) && rsnxe_len &&
 		(conf->sae_pwe == SAE_PWE_HASH_TO_ELEMENT ||
 		 conf->sae_pwe == SAE_PWE_BOTH);
 #ifdef CONFIG_TESTING_OPTIONS
@@ -2782,17 +2796,6 @@ u8 * wpa_sm_write_assoc_resp_ies(struct wpa_state_machine *sm, u8 *pos,
 	if (ric_start == pos)
 		ric_start = NULL;
 
-	if (omit_rsnxe) {
-		rsnxe_len = 0;
-	} else {
-		res = wpa_write_rsnxe(&sm->wpa_auth->conf, rsnxe,
-				      sizeof(rsnxe_buf));
-		if (res < 0) {
-			pos = NULL;
-			goto fail;
-		}
-		rsnxe_len = res;
-	}
 #ifdef CONFIG_TESTING_OPTIONS
 	if (auth_alg == WLAN_AUTH_FT &&
 	    sm->wpa_auth->conf.rsnxe_override_ft_set) {

---
base-commit: 1f2231a88a742befbea44bc19ffee94bed616505
change-id: 20261101-b128-ft-rsnxe-used-71f9af438205

Best regards,
--  
Christopher Griffin <christophergriffin05@gmail.com>

