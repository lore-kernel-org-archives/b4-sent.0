From: Orel Fichman <orelmz@gmail.com>
Date: Sat, 28 Nov 2026 22:30:35 +0200
Subject: [PATCH] wifi: ath10k: reset TXBF before taking the vdev down on
 disassoc
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261128-ath10k-txbf-disassoc-v1-1-c714edd639a3@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQqDQAxA0atI1g2YYEvpVUoX4yRqFLRMpkUQ7
 +60Lt/i/w1ck6nDo9og6dfclrmALhXEIcy9okkxcM03Ir5jyAPVE+a17VDMg/sSUVnkShoajgI
 lfSftbP1vn6/T/mlHjfn3gn0/ADMLUk94AAAA
X-Change-ID: 20261128-ath10k-txbf-disassoc-e2dd51ea42cd
To: Jeff Johnson <jjohnson@kernel.org>, 
 Loic Poulain <loic.poulain@oss.qualcomm.com>
Cc: linux-wireless@vger.kernel.org, ath10k@lists.infradead.org, 
 "Claude Opus 5.5" <noreply@anthropic.com>, Orel Fichman <orelmz@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795897854; l=2596;
 i=orelmz@gmail.com; s=20261128; h=from:subject:message-id;
 bh=SdDEtslTVtzP5XubbEBuJRKOLY+v1lLUgiIWwZ7DBkc=;
 b=UwdGdB61aLmBiaNoIpMPUVKCKYFPgXB2be87YRbLJg34XO3w3imcEcE5Zsdmu1bOT8flHk1Dy
 LTkv4rgv2zUD2RGHuW0UmVLG5hQLlXoXop9cCZUCuIr9h0J7GBCPc7K
X-Developer-Key: i=orelmz@gmail.com; a=ed25519;
 pk=V/0LisYOqumnXjWepsPmrdFQvGO2Ne5eOAuTPmK2yMQ=
X-Endpoint-Received: by B4 Relay for orelmz@gmail.com/20261128 with auth_id=1679
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On WCN3990 with firmware WLAN.HL.1.0.1 (SDM630, Nokia 6.1), every
disconnect crashes the WLAN firmware, which takes the modem down with
it:

  qcom-q6v5-mss 4080000.remoteproc: fatal error received: err_qdi.c:459:EX:wlan_process:1:WLAN RT:3082:PC=b00c9af4

ath10k_bss_disassoc() resets the TXBF vdev param after
ath10k_wmi_vdev_down(), and this firmware does not cope with TXBF being
changed on a vdev that is down. Reset it first and only then bring the
vdev down. A failed reset no longer skips the rest of the teardown.

The crash was tracked down and the fix written with the help of Claude,
an AI assistant, in an interactive debugging session on the device.

Tested-on: WCN3990 hw1.0 SNOC WLAN.HL.1.0.1.c2-00717-QCAHLSWMTPLZ-1

Co-authored-by: Claude Opus 5.5 <noreply@anthropic.com>
Signed-off-by: Orel Fichman <orelmz@gmail.com>
---
Tested by disconnecting/reconnecting and toggling the radio repeatedly:
the firmware crashed on every disconnect before this change and never
after it.
Only tested on WCN3990; on other chips this just moves an existing vdev param update ahead of vdev down.
---
 drivers/net/wireless/ath/ath10k/mac.c | 15 ++++++++-------
 1 file changed, 8 insertions(+), 7 deletions(-)

diff --git a/drivers/net/wireless/ath/ath10k/mac.c b/drivers/net/wireless/ath/ath10k/mac.c
index 8e604697d..fe9e7c20f 100644
--- a/drivers/net/wireless/ath/ath10k/mac.c
+++ b/drivers/net/wireless/ath/ath10k/mac.c
@@ -3198,6 +3198,14 @@ static void ath10k_bss_disassoc(struct ieee80211_hw *hw,
 	ath10k_dbg(ar, ATH10K_DBG_MAC, "mac vdev %i disassoc bssid %pM\n",
 		   arvif->vdev_id, arvif->bssid);
 
+	/* Some firmware (e.g. WCN3990 WLAN.HL.1.0.1) crashes if TXBF is
+	 * changed on a vdev that is down, so reset it first.
+	 */
+	ret = ath10k_mac_vif_recalc_txbf(ar, vif, vht_cap);
+	if (ret)
+		ath10k_warn(ar, "failed to recalc txbf for vdev %i: %d\n",
+			    arvif->vdev_id, ret);
+
 	ret = ath10k_wmi_vdev_down(ar, arvif->vdev_id);
 	if (ret)
 		ath10k_warn(ar, "failed to down vdev %i: %d\n",
@@ -3205,13 +3213,6 @@ static void ath10k_bss_disassoc(struct ieee80211_hw *hw,
 
 	arvif->def_wep_key_idx = -1;
 
-	ret = ath10k_mac_vif_recalc_txbf(ar, vif, vht_cap);
-	if (ret) {
-		ath10k_warn(ar, "failed to recalc txbf for vdev %i: %d\n",
-			    arvif->vdev_id, ret);
-		return;
-	}
-
 	arvif->is_up = false;
 
 	ath10k_mac_txpower_recalc(ar);

---
base-commit: 18d0bedbb5f0538396cb7f763ed9cd1dd69c5b23
change-id: 20261128-ath10k-txbf-disassoc-e2dd51ea42cd

Best regards,
--  
Orel Fichman <orelmz@gmail.com>

