From: Christopher Griffin <christophergriffin05@gmail.com>
Date: Thu, 05 Nov 2026 12:12:23 -0600
Subject: [PATCH 2/2] wifi: ath12k: don't leave a monitor link started when
 its stop fails
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261105-ath-monitor-unassign-v1-2-277f0fbadb91@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793902344; l=1783;
 i=christophergriffin05@gmail.com; s=20261024; h=from:subject:message-id;
 bh=yJliLnA52UPk6OOcZziqgLXylvHUHFJud+o6Dahzovo=;
 b=RtI+6f08VIMKSgrwalriN0ZtZkc2Iu2Qe8TRHTrgj/6k40N7JIbH5s21SSzcD4HAbUzPEHa4p
 VaHljDdHCQgAdHgfZS9xoqenVGZJOZd07I55M5njTRLZWP7jChamzqJ
X-Developer-Key: i=christophergriffin05@gmail.com; a=ed25519;
 pk=oa9tkTNpiGoFWdGvpDHXLSobApmsh9BfrJRJrRJAvWA=
X-Endpoint-Received: by B4 Relay for christophergriffin05@gmail.com/20261024 with auth_id=1309
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ath12k_mac_op_unassign_vif_chanctx() returns early, with
arvif->is_started still set, when ath12k_mac_monitor_stop() fails.
mac80211 can't fail an unassignment and considers the channel context
released, so the link's next assignment hits WARN_ON(arvif->is_started)
in ath12k_mac_op_assign_vif_chanctx() and fails with -EBUSY. A firmware
crash during a monitor channel change is enough: the vdev stop times
out.

ath11k has the same flow and shows the warning that way on a QCN9074.

Fall through to the common path, which clears is_started.
ath12k_mac_monitor_stop() already warns on failure.

Compile-tested only.

Fixes: d889913205cf ("wifi: ath12k: driver for Qualcomm Wi-Fi 7 devices")
Assisted-by: Claude:claude-opus-5-5
Signed-off-by: Christopher Griffin <christophergriffin05@gmail.com>
---
 drivers/net/wireless/ath/ath12k/mac.c | 12 +++++-------
 1 file changed, 5 insertions(+), 7 deletions(-)

diff --git a/drivers/net/wireless/ath/ath12k/mac.c b/drivers/net/wireless/ath/ath12k/mac.c
index 9fd3841f71b71..7d04f16f99e37 100644
--- a/drivers/net/wireless/ath/ath12k/mac.c
+++ b/drivers/net/wireless/ath/ath12k/mac.c
@@ -12422,13 +12422,11 @@ ath12k_mac_op_unassign_vif_chanctx(struct ieee80211_hw *hw,
 
 	WARN_ON(!arvif->is_started);
 
-	if (ahvif->vdev_type == WMI_VDEV_TYPE_MONITOR) {
-		ret = ath12k_mac_monitor_stop(ar);
-		if (ret)
-			return;
-
-		arvif->is_started = false;
-	}
+	/* mac80211 can't fail an unassignment, so the link counts as stopped
+	 * below even if the monitor stop fails (that warns on its own).
+	 */
+	if (ahvif->vdev_type == WMI_VDEV_TYPE_MONITOR)
+		ath12k_mac_monitor_stop(ar);
 
 	if (ahvif->vdev_type != WMI_VDEV_TYPE_STA &&
 	    ahvif->vdev_type != WMI_VDEV_TYPE_MONITOR) {

-- 
2.43.0

