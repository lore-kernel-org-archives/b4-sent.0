From: Fabricio Akio <fabricioakio@gmail.com>
Date: Sun, 11 Oct 2026 18:59:05 -0300
Subject: [PATCH] wifi: ath10k: don't reset TxBF on disassociation
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261011-ath10k-disassoc-txbf-v1-1-51e09115042e@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQqDMBBA0avIrB3IhJpAr1JcJHHUsaAlE4sg3
 r1pu3yL/09QzsIK9+aEzG9R2dYKahtIc1gnRhmqwRrryBBhKDOZJw6iQXVLWI44InfRe9u55G4
 eavrKPMrx2z76v3WPC6fyfcF1fQDsHsQgeAAAAA==
X-Change-ID: 20261011-ath10k-disassoc-txbf-e5b77256c647
To: Jeff Johnson <jjohnson@kernel.org>
Cc: linux-wireless@vger.kernel.org, ath10k@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Fabricio Akio <fabricioakio@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791755944; l=2607;
 i=fabricioakio@gmail.com; s=20260928; h=from:subject:message-id;
 bh=yedrsdruZNEyyDyVSIF/isrw8Zan8nErgmxmiHmgDL8=;
 b=cew1YosN8FjDoaHqvWa0ZdfMoW2v03LTeceP8lH9yuKAlwlUfTzNqfbbnqqyUzaR4TwKbmhvF
 lfVTE8q2MeUDZRdW5MYxkJijLBIoCrrPwMrydWzTsth7IZQrewfUbLR
X-Developer-Key: i=fabricioakio@gmail.com; a=ed25519;
 pk=TlMUT8bPI/ZQzp2q24BIQTb2qSx/jdUTBlGEXIRCm54=
X-Endpoint-Received: by B4 Relay for fabricioakio@gmail.com/20260928 with auth_id=1076
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

WCN3990 firmware WLAN.HL.1.0.1.c2-00498 crashes whenever the vdev's
TxBF parameter is set while the vdev has no peer for its AP, whatever
the value. ath10k_bss_disassoc() sets it to 0 once the AP's peer is
gone. The firmware therefore crashes on every disconnect, including
the one cfg80211 makes before a suspend without WoWLAN, and whenever
mac80211 replays the state of an interface that is not associated, as
on resume from such a suspend and after a firmware restart. Each
restart replays it again, so the firmware never comes back:

  qcom-q6v5-mss 4080000.remoteproc: fatal error received:
    err_qdi.c:459:EX:wlan_process:1:WLAN RT:107b:PC=b00c8334

The reset is not needed: ath10k_bss_assoc() sets TxBF again from the
next AP's capabilities before bringing the vdev up. Drop it.

Fixes: 139e170da98a ("ath10k: add TxBF support")
Signed-off-by: Fabricio Akio <fabricioakio@gmail.com>
---
Tested on a Motorola Moto X4 (SDM630, WCN3990): without this patch a
disconnect, s2idle without an association and a forced modem restart
crashed the firmware every time; with it, none of those did, nor
s2idle while associated.

QCA6174 and QCA9377 also send this command and are untested here.
Qualcomm's qcacld-3.0, ath11k and ath12k do not send TxBF on
disassociation. A WCN3990-only hw_params flag was considered, but
association rewrites the parameter on every chip, so the patch drops
the reset for all of them.
---
 drivers/net/wireless/ath/ath10k/mac.c | 9 ---------
 1 file changed, 9 deletions(-)

diff --git a/drivers/net/wireless/ath/ath10k/mac.c b/drivers/net/wireless/ath/ath10k/mac.c
index 8e604697d6c2..30355c598f97 100644
--- a/drivers/net/wireless/ath/ath10k/mac.c
+++ b/drivers/net/wireless/ath/ath10k/mac.c
@@ -3190,7 +3190,6 @@ static void ath10k_bss_disassoc(struct ieee80211_hw *hw,
 {
 	struct ath10k *ar = hw->priv;
 	struct ath10k_vif *arvif = (void *)vif->drv_priv;
-	struct ieee80211_sta_vht_cap vht_cap = {};
 	int ret;
 
 	lockdep_assert_held(&ar->conf_mutex);
@@ -3204,14 +3203,6 @@ static void ath10k_bss_disassoc(struct ieee80211_hw *hw,
 			    arvif->vdev_id, ret);
 
 	arvif->def_wep_key_idx = -1;
-
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
base-commit: becb95e45ef0dda9ffb35156d909d3da7a2789c3
change-id: 20261011-ath10k-disassoc-txbf-e5b77256c647

Best regards,
--  
Fabricio Akio <fabricioakio@gmail.com>

