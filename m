From: Christopher Griffin <christophergriffin05@gmail.com>
Date: Thu, 05 Nov 2026 12:12:22 -0600
Subject: [PATCH 1/2] wifi: ath11k: don't leave a monitor vif started when
 its stop fails
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261105-ath-monitor-unassign-v1-1-277f0fbadb91@gmail.com>
References: <20261105-ath-monitor-unassign-v1-0-277f0fbadb91@gmail.com>
In-Reply-To: <20261105-ath-monitor-unassign-v1-0-277f0fbadb91@gmail.com>
To: Jeff Johnson <jjohnson@kernel.org>, 
 Vasanthakumar Thiagarajan <vasanthakumar.thiagarajan@oss.qualcomm.com>, 
 Jouni Malinen <quic_jouni@quicinc.com>, Kalle Valo <kvalo@kernel.org>, 
 P Praneesh <quic_ppranees@quicinc.com>, 
 Ramya Gnanasekar <quic_rgnanase@quicinc.com>, 
 Wen Gong <quic_wgong@quicinc.com>, 
 Karthikeyan Periyasamy <quic_periyasa@quicinc.com>
Cc: linux-wireless@vger.kernel.org, ath11k@lists.infradead.org, 
 linux-kernel@vger.kernel.org, 
 Baochen Qiang <baochen.qiang@oss.qualcomm.com>, 
 Pradeep Kumar Chitrapu <quic_pradeepc@quicinc.com>, 
 ath12k@lists.infradead.org, 
 Christopher Griffin <christophergriffin05@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793902344; l=2565;
 i=christophergriffin05@gmail.com; s=20261024; h=from:subject:message-id;
 bh=1R7oAGbBN78/oVWlhCPSGL7JqxfEoXYdSJISg6BkmUs=;
 b=TPfNd1rwEb1IAORwzaVwKydgTWq9y85ofF0dnxUxsONH+KfMDevRtnzxDbtsB6PGwVN6ME/y0
 jYIA7dJ3kDFAneU9+97YW99sbcrvw1DOYHUKbEhDvc7OksKHkKLF0b/
X-Developer-Key: i=christophergriffin05@gmail.com; a=ed25519;
 pk=oa9tkTNpiGoFWdGvpDHXLSobApmsh9BfrJRJrRJAvWA=
X-Endpoint-Received: by B4 Relay for christophergriffin05@gmail.com/20261024 with auth_id=1309
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ath11k_mac_op_unassign_vif_chanctx() returns early, with
arvif->is_started still set, when ath11k_mac_monitor_stop() fails for a
monitor vif. mac80211 can't fail an unassignment and considers the
channel context released, so the vif's next assignment, e.g. the next
channel change of the monitor interface, hits WARN_ON(arvif->is_started)
in ath11k_mac_op_assign_vif_chanctx() and fails with -EBUSY.

A firmware crash during a monitor channel change does it. On a QCN9074
with a monitor interface that changes channel every few hundred
milliseconds, after simulate_fw_crash:

  failed to stop monitor vdev: -110
  failed to stop monitor during vif channel context unassignment: -110
  WARNING: CPU: 2 PID: 15367 at drivers/net/wireless/ath/ath11k/mac.c:8499 ath11k_mac_op_assign_vif_chanctx+0x304/0x3e0 [ath11k]
  Call trace:
   ath11k_mac_op_assign_vif_chanctx+0x304/0x3e0 [ath11k] (P)
   drv_assign_vif_chanctx+0xac/0x144 [mac80211]
   ieee80211_recalc_smps_chanctx+0x278/0x940 [mac80211]
   _ieee80211_link_use_channel+0x158/0x210 [mac80211]
   ieee80211_set_monitor_channel+0xa4/0x860 [mac80211]
   cfg80211_set_monitor_channel+0x3c/0x60 [cfg80211]
   nl80211_set_wiphy+0x2cc/0x7d8 [cfg80211]

Recovery resets the vif afterwards, but without a crash the vif would
refuse every later channel context, with a warning each time.

Clear is_started even when the stop fails, as the non-monitor path in
the same function does.

Tested-on: QCN9074 hw1.0 PCI WLAN.HK.2.5.r4-00683-QCAHKSWPL_SILICONZ-1

Fixes: 689a5e6fff75 ("ath11k: monitor mode clean up to use separate APIs")
Assisted-by: Claude:claude-opus-5-5
Signed-off-by: Christopher Griffin <christophergriffin05@gmail.com>
---
 drivers/net/wireless/ath/ath11k/mac.c | 6 ++----
 1 file changed, 2 insertions(+), 4 deletions(-)

diff --git a/drivers/net/wireless/ath/ath11k/mac.c b/drivers/net/wireless/ath/ath11k/mac.c
index 1a237adaa37d1..fc6c374c787fd 100644
--- a/drivers/net/wireless/ath/ath11k/mac.c
+++ b/drivers/net/wireless/ath/ath11k/mac.c
@@ -8514,12 +8514,10 @@ ath11k_mac_op_unassign_vif_chanctx(struct ieee80211_hw *hw,
 
 	if (arvif->vdev_type == WMI_VDEV_TYPE_MONITOR) {
 		ret = ath11k_mac_monitor_stop(ar);
-		if (ret) {
+		if (ret)
+			/* continue: mac80211 has unassigned the context anyway */
 			ath11k_warn(ar->ab, "failed to stop monitor during vif channel context unassignment: %d",
 				    ret);
-			mutex_unlock(&ar->conf_mutex);
-			return;
-		}
 
 		arvif->is_started = false;
 		mutex_unlock(&ar->conf_mutex);

-- 
2.43.0

