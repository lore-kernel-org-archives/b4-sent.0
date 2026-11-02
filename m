From: Christopher Griffin <christophergriffin05@gmail.com>
Date: Sun, 01 Nov 2026 22:29:14 -0600
Subject: [PATCH v2] FT: Set RSNXE Used only when the AP advertises an RSNXE
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261101-b128-ft-rsnxe-used-v2-1-871e5a75a9f8@gmail.com>
X-B4-Tracking: v=1; b=H4sIAJkR6GoC/32Nyw6CMBBFf4V07ZhOfVVX/odhUcoUxkgxHSAYw
 r8LuHd5knPPnZRQYhJ1yyaVaGDhNi5gdpnytYsVAZcLK6PNGVEjFGgshA6SxJGgFyrhguHqwvF
 gjT6pZfhOFHjcoo/8x9IXT/LdWlqNmqVr02d7HXD1/h4MCAja6oCGfEDr7lXj+LX3baPyeZ6/T
 0vD08YAAAA=
X-Change-ID: 20261101-b128-ft-rsnxe-used-71f9af438205
To: hostap@lists.infradead.org
Cc: Koral Ilgun <koral.ilgun@adtran.com>, 
 Christopher Griffin <christophergriffin05@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793593753; l=3268;
 i=christophergriffin05@gmail.com; s=20261024; h=from:subject:message-id;
 bh=X83aISLoyMBXJReMWnvZprdiNlJo5Kb7R5lfjtGxaeI=;
 b=t8FfNRftV0wbY910Xeue1s0B5Gq7VAM5XvViDcsBJtKOjnFerWgQAGitVa+vpK9+jKh9SATZg
 ezSo4kGBhvcA3h39WLxyP3NmYxVXXJ5XRrTlveE3NrSh51QpDG8WolT
X-Developer-Key: i=christophergriffin05@gmail.com; a=ed25519;
 pk=oa9tkTNpiGoFWdGvpDHXLSobApmsh9BfrJRJrRJAvWA=
X-Endpoint-Received: by B4 Relay for christophergriffin05@gmail.com/20261024 with auth_id=1309
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

RSNXE Used in the FTE of an FT Reassociation Response indicates that the
AP uses the RSNXE in other frames (commit 51d1924bd), and wpa_supplicant
checks it against the RSNXE of the Beacon and Probe Response frames. The
AP set it whenever sae_pwe was 1 or 2. A BSS without an SAE AKM, for
example FT-EAP or FT-PSK, usually has no extended RSN capability to
advertise and thus no RSNXE, but with sae_pwe set its responses still
announced one. wpa_supplicant then rejected every FT Reassociation
Response ("FT: FTE indicated that AP uses RSNXE, but RSNXE was not
included in Beacon/Probe Response frames") and deauthenticated with
reason 13 (invalid element). OpenWrt 25.12.2 sets sae_pwe=2 on WPA3 and
WPA2/WPA3 Enterprise BSSs, so FT-EAP roams to such APs failed.

Set RSNXE Used only when the Beacon and Probe Response frames carry an
RSNXE: it is not omitted with rsn_override_omit_rsnxe, and the AP has an
extended RSN capability to advertise. The response to a STA that sent no
RSNXE is unchanged.

Assisted-by: Claude:claude-opus-5-5
Signed-off-by: Christopher Griffin <christophergriffin05@gmail.com>
---
Seen with OpenWrt 25.12.2 APs (mt76) whose FT-EAP BSS has sae_pwe=2:
every FT roam to them failed with reason 13.

Changes in v2:
- v1 cleared RSNXE Used whenever the response itself carried no RSNXE.
  Per 51d1924bd the subfield reflects the RSNXE of the Beacon and Probe
  Response frames, as Koral Ilgun's series "FT: RSNXE Used without the
  RSNXE" points out, so a response to a STA that sent no RSNXE keeps it.
  v2 clears the subfield only when the AP advertises no RSNXE. That also
  covers the rsn_override_omit_rsnxe case of patch 1 of that series.
- v1: "[PATCH] FT: Set RSNXE Used in Reassociation Response only with an
  RSNXE", 2026-11-01.

Tested on an Arista W-118 (ath10k, OpenWrt main), wpa_supplicant as the
STA, six FT roams between two BSSes each:
- FT-PSK, AP sae_pwe=2 (no SAE AKM): 6 of 6 roams completed; 0 of 6
  without this patch, each deauthenticated with reason 13.
- FT-SAE, AP sae_pwe=2, STA sae_pwe=0 (no RSNXE in its request): 5 of
  6; the first ROAM came before the target was in the scan results and
  was not attempted.
- FT-SAE, AP sae_pwe=2, STA sae_pwe=2: 6 of 6.
The hwsim tests were not run.
---
 src/ap/wpa_auth_ft.c | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/src/ap/wpa_auth_ft.c b/src/ap/wpa_auth_ft.c
index e12f2ad..7046e34 100644
--- a/src/ap/wpa_auth_ft.c
+++ b/src/ap/wpa_auth_ft.c
@@ -2714,7 +2714,12 @@ u8 * wpa_sm_write_assoc_resp_ies(struct wpa_state_machine *sm, u8 *pos,
 		anonce = NULL;
 		snonce = NULL;
 	}
+	/* RSNXE Used indicates that the AP uses the RSNXE in other frames, so
+	 * only an AP whose Beacon and Probe Response frames carry an RSNXE
+	 * may set it. */
 	rsnxe_used = (auth_alg == WLAN_AUTH_FT) &&
+		!conf->rsn_override_omit_rsnxe &&
+		wpa_write_rsnxe(conf, rsnxe_buf, sizeof(rsnxe_buf)) > 0 &&
 		(conf->sae_pwe == SAE_PWE_HASH_TO_ELEMENT ||
 		 conf->sae_pwe == SAE_PWE_BOTH);
 #ifdef CONFIG_TESTING_OPTIONS

---
base-commit: 1f2231a88a742befbea44bc19ffee94bed616505
change-id: 20261101-b128-ft-rsnxe-used-71f9af438205

Best regards,
--  
Christopher Griffin <christophergriffin05@gmail.com>

