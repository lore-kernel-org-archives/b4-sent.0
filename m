From: Christopher Griffin <christophergriffin05@gmail.com>
Date: Sat, 31 Oct 2026 10:30:22 -0500
Subject: [PATCH ath-next] wifi: ath11k: don't warn when a country leaves a
 pdev without channels
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261031-b107-reg-no-channels-v1-1-896bd89a155f@gmail.com>
X-B4-Tracking: v=1; b=H4sIAI0J5moC/yWMywrCQAxFf6VkbSAZcXz8irjotLGNSCqTUQql/
 +5Ul4d7z1nAJas4XJoFsnzUdbIKvGugG1sbBLWvDIFCZNozJqYjZhnQJtweJk/HGBMfTkz9ORB
 U9ZXlrvMve4W2jGgyF7j9F3+nh3Rlq8K6fgHgOQerggAAAA==
X-Change-ID: 20261031-b107-reg-no-channels-66b15810d920
To: Jeff Johnson <jjohnson@kernel.org>
Cc: linux-wireless@vger.kernel.org, ath11k@lists.infradead.org, 
 linux-kernel@vger.kernel.org, 
 Christopher Griffin <christophergriffin05@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793460621; l=2502;
 i=christophergriffin05@gmail.com; s=20261024; h=from:subject:message-id;
 bh=V7tNvA1MU393lNVR72C3Nhj4MRed2O220sx8YBWuIt0=;
 b=rhSgNEuN7hOdyzIQK5Uv75XU2JeLj0Ext5ZfY96nK2I0TvVhCLNJ+DXDwBMnFgF2tw+YdgOwh
 mTvlLvJizFXAVVk3m1iwIrWio5ZTeE0YUaDjz/iwiyP4cFMvJQiOaN2
X-Developer-Key: i=christophergriffin05@gmail.com; a=ed25519;
 pk=oa9tkTNpiGoFWdGvpDHXLSobApmsh9BfrJRJrRJAvWA=
X-Endpoint-Received: by B4 Relay for christophergriffin05@gmail.com/20261024 with auth_id=1309
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ath11k_reg_update_chan_list() hits a WARN_ON() and returns -EINVAL when
none of the pdev's channels is enabled. Userspace can reach that by
setting a country. On an Arista C-360, whose QCN9074 is a 6 GHz-only
pdev, "iw reg set CA" left that wiphy with no enabled channel, and the
driver-initiated regulatory notifier then warned:

  WARNING: ... at drivers/net/wireless/ath/ath11k/reg.c:146 ath11k_reg_update_chan_list+0x368/0x3c0
  ath11k_pci 0000:01:00.0: failed to update channel list: -22

A domain with no channel for a pdev is not a driver fault. There is no
list to send (ath11k_wmi_send_scan_chan_list_cmd() sends nothing for
zero channels anyway), no vdev can start on the pdev meanwhile, and the
next domain that enables a channel sends the whole list again. ath12k
already treats this case as a debug message.

Log it at debug level and return 0. That also covers
ath11k_mac_op_start(), which ignores the return value but hits the same
WARN_ON() when the radio is started in such a domain.

Fixes: d5c65159f289 ("ath11k: driver for Qualcomm IEEE 802.11ax devices")
Tested-on: QCN9074 hw1.0 PCI WLAN.HK.2.5.r4-00683-QCAHKSWPL_SILICONZ-1

Assisted-by: Claude:claude-opus-5-5
Signed-off-by: Christopher Griffin <christophergriffin05@gmail.com>
---
Seen on an Arista C-360, whose QCN9074 is a 6 GHz-only pdev.
---
 drivers/net/wireless/ath/ath11k/reg.c | 12 ++++++++++--
 1 file changed, 10 insertions(+), 2 deletions(-)

diff --git a/drivers/net/wireless/ath/ath11k/reg.c b/drivers/net/wireless/ath/ath11k/reg.c
index 1030e119fd903..d6457ff3f591a 100644
--- a/drivers/net/wireless/ath/ath11k/reg.c
+++ b/drivers/net/wireless/ath/ath11k/reg.c
@@ -145,8 +145,16 @@ int ath11k_reg_update_chan_list(struct ath11k *ar, bool wait)
 		}
 	}
 
-	if (WARN_ON(!num_channels))
-		return -EINVAL;
+	/* A regulatory domain can leave a pdev with no usable channel, as
+	 * one without 6 GHz rules leaves a 6 GHz-only radio. There is no
+	 * list to send then; the domain that enables a channel again sends it.
+	 */
+	if (!num_channels) {
+		ath11k_dbg(ar->ab, ATH11K_DBG_REG,
+			   "no enabled channel on pdev %u, channel list not sent\n",
+			   ar->pdev->pdev_id);
+		return 0;
+	}
 
 	params = kzalloc_flex(*params, ch_param, num_channels);
 	if (!params)

---
base-commit: a3ddbb45768717b5c9f923489387cf55c838d1ad
change-id: 20261031-b107-reg-no-channels-66b15810d920

Best regards,
--  
Christopher Griffin <christophergriffin05@gmail.com>

