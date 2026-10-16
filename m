From: Shunsuke Nagashima <shunsuke@nagashi.ma>
Date: Fri, 16 Oct 2026 09:17:55 +0900
Subject: [PATCH ath-next 2/3] wifi: ath10k: skip disassociation down for a
 station vdev that is not up
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261016-ath10k-series-v1-send-v1-2-c847697b3558@nagashi.ma>
References: <20261016-ath10k-series-v1-send-v1-0-c847697b3558@nagashi.ma>
In-Reply-To: <20261016-ath10k-series-v1-send-v1-0-c847697b3558@nagashi.ma>
To: Jeff Johnson <jjohnson@kernel.org>
Cc: linux-wireless@vger.kernel.org, ath10k@lists.infradead.org, 
 linux-kernel@vger.kernel.org, David Heidelberg <david@ixit.cz>, 
 Fabricio Akio <fabricioakio@gmail.com>, 
 Shunsuke Nagashima <shunsuke@nagashi.ma>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792109874; l=3999;
 i=shunsuke@nagashi.ma; s=20260927; h=from:subject:message-id;
 bh=ra7k5rd4VUKMhfqQc4mjOGmnxng1/f4qBCPX4xMwqYo=;
 b=YW+OxFwiRaNd9UMrW1vE5OMRwYNjFyGCUH52bFRLilDhgnpovc2tkLmzRTEObZmmkPqnWuPi8
 FOpb0Wx3eX4BRyc0bl3ASSU25nKh/nwJ4EvHZWF5kxCfZ83zZz/GcHQ
X-Developer-Key: i=shunsuke@nagashi.ma; a=ed25519;
 pk=5WP8Bzifiy3DFoCeQ1lLy2osPmlNAkq71Un7ly9lbpk=
X-Endpoint-Received: by B4 Relay for shunsuke@nagashi.ma/20260927 with auth_id=1069
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ath10k_bss_disassoc() sends WMI_VDEV_DOWN whether or not the vdev was
brought up. When mac80211 replays the station state during
reconfiguration, it can call it for a station whose connection attempt
is still pending: the vdev is started but not up, and the AP peer
exists. On WCN3990 firmware WLAN.HL.2.0.c10-00459, a VDEV_DOWN while
the peer still exists makes the firmware assert.

Send VDEV_DOWN from ath10k_bss_disassoc() only when arvif->is_up is
true, and log when it is skipped. The next patch brings down a station
vdev that never came up after the stop in
ath10k_mac_op_unassign_vif_chanctx().

Normal disconnects are not changed. With this patch and the next one,
in a CONFIG_ATH10K_DEBUG build, no DOWN was skipped in 5 WPA3 cycles
(4 of them with an association rejection with status 30 first) and
5 WPA2 cycles, and each normal disconnect sent exactly one VDEV_DOWN
from ath10k_bss_disassoc(). The change is not specific to WCN3990, but
only WCN3990 was tested.

Tested-on: WCN3990 hw1.0 SNOC WLAN.HL.2.0.c10-00459-QCAHLSWMTPLZ-1

Assisted-by: LLM sparse
Signed-off-by: Shunsuke Nagashima <shunsuke@nagashi.ma>
---
Notes:

- This patch was run on the device only together with the next patch.
  The path it changes was run in a CONFIG_ATH10K_DEBUG build: a hardware
  restart through debugfs while an association was pending (waiting
  after a status 30 rejection). With only the next patch (the same code
  as in this series), the firmware asserted in the VDEV_DOWN from
  ath10k_bss_disassoc() 29 of 29 times. With this patch added, it did
  not assert (0 of 5), and the down was skipped each time. The debugfs
  restart path itself gives SMMU fault and IRQ warnings, with or without
  this patch.

- Related: Fabricio Akio's "wifi: ath10k: don't reset TxBF on
  disassociation" (patchwork 14880772) changes ath10k_bss_disassoc()
  next to this patch. The two do not depend on each other; either one
  applies on top of the other with git am -3.

- Only WCN3990 was tested (hw1.0 SNOC, WLAN.HL.2.0.c10-00459). TDLS,
  P2P client and multiple vifs were not tested.

- Test kernel: a v7.2-based kernel on a comma four (SDM845) that also
  carries three out-of-tree ath10k patches (MAC address, in-order rx
  A-MSDU, SET_KEY wait).

AI-assistance disclosure:

I worked on this with Claude (mainly claude-opus-5-5 and
claude-fable-5-1) and Codex (gpt-6-astra). They helped go through the
logs and sniffer captures, draft the code changes and the debug builds,
and write the English of the commit messages. I reviewed the code. All
device tests ran on my own comma four, and the results above come from
those runs.
---
 drivers/net/wireless/ath/ath10k/mac.c | 19 +++++++++++++++----
 1 file changed, 15 insertions(+), 4 deletions(-)

diff --git a/drivers/net/wireless/ath/ath10k/mac.c b/drivers/net/wireless/ath/ath10k/mac.c
index b30cdd1888f4..88ebcd2d1110 100644
--- a/drivers/net/wireless/ath/ath10k/mac.c
+++ b/drivers/net/wireless/ath/ath10k/mac.c
@@ -3199,10 +3199,21 @@ static void ath10k_bss_disassoc(struct ieee80211_hw *hw,
 	ath10k_dbg(ar, ATH10K_DBG_MAC, "mac vdev %i disassoc bssid %pM\n",
 		   arvif->vdev_id, arvif->bssid);
 
-	ret = ath10k_wmi_vdev_down(ar, arvif->vdev_id);
-	if (ret)
-		ath10k_warn(ar, "failed to down vdev %i: %d\n",
-			    arvif->vdev_id, ret);
+	/* During hw restart reconfiguration, mac80211 replays disassociation
+	 * for a station with a pending connection attempt. The vdev is started
+	 * but not up, and the AP peer exists. A down then asserts at least
+	 * WCN3990 firmware.
+	 */
+	if (arvif->is_up) {
+		ret = ath10k_wmi_vdev_down(ar, arvif->vdev_id);
+		if (ret)
+			ath10k_warn(ar, "failed to down vdev %i: %d\n",
+				    arvif->vdev_id, ret);
+	} else {
+		ath10k_dbg(ar, ATH10K_DBG_MAC,
+			   "mac vdev %i disassoc bssid %pM skip down (not up)\n",
+			   arvif->vdev_id, arvif->bssid);
+	}
 
 	arvif->def_wep_key_idx = -1;
 

-- 
Git-157)

