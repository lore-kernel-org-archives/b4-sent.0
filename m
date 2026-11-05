From: Christopher Griffin <christophergriffin05@gmail.com>
Date: Thu, 05 Nov 2026 12:11:37 -0600
Subject: [PATCH 2/3] wifi: ath11k: don't arm the scan timeout for a scan
 that did not start
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261105-ath-recovery-scan-timeout-v1-2-99a70d89e114@gmail.com>
References: <20261105-ath-recovery-scan-timeout-v1-0-99a70d89e114@gmail.com>
In-Reply-To: <20261105-ath-recovery-scan-timeout-v1-0-99a70d89e114@gmail.com>
To: Jeff Johnson <jjohnson@kernel.org>, Kalle Valo <kvalo@kernel.org>, 
 Hari Chandrakanthan <quic_haric@quicinc.com>, 
 Venkateswara Naralasetty <quic_vnaralas@quicinc.com>, 
 Pradeep Kumar Chitrapu <quic_pradeepc@quicinc.com>, 
 Anilkumar Kolli <quic_akolli@quicinc.com>, 
 Loic Poulain <loic.poulain@oss.qualcomm.com>
Cc: linux-wireless@vger.kernel.org, ath11k@lists.infradead.org, 
 linux-kernel@vger.kernel.org, 
 Maharaja Kennadyrajan <quic_mkenna@quicinc.com>, 
 John Crispin <john@phrozen.org>, 
 Govindaraj Saminathan <quic_gsamin@quicinc.com>, ath10k@lists.infradead.org, 
 Wen Gong <quic_wgong@quicinc.com>, 
 Christopher Griffin <christophergriffin05@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793902298; l=1793;
 i=christophergriffin05@gmail.com; s=20261024; h=from:subject:message-id;
 bh=BE7ZZiDwoQohf3HNv1LT97zdlpVPS1QyfAViwcyIEvw=;
 b=4AlrQNqA3KWa7YCP1sXjptaRVGnoAzA5IAx2wXQGw1d0U8pJn0rz7yoO1o0HcMCcSHAIBt146
 5szc68Ym6OzDfsmxpQFIzXVq0IwLJFtMi5uuaZ3c2HvXsATbt0BpG5/
X-Developer-Key: i=christophergriffin05@gmail.com; a=ed25519;
 pk=oa9tkTNpiGoFWdGvpDHXLSobApmsh9BfrJRJrRJAvWA=
X-Endpoint-Received: by B4 Relay for christophergriffin05@gmail.com/20261024 with auth_id=1309
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When ath11k_start_scan() fails, ath11k_mac_op_hw_scan() sets the scan
state back to idle and returns the error to mac80211, but first still
queues ar->scan.timeout. The timeout then stays pending for the full
scan time (20 s by default) although no scan is running. A scan started
within that time gets no timeout of its own, as the work is already
pending, and the stale one aborts it early.

The stale timeout can also outlive the radio. On a QCN9074 whose
firmware crashed during a scan, recovery failed and the driver was
unbound and bound again; the failed scan's timeout then fired from the
freed ath11k:

  [  145.937344] ath11k_pci 0001:01:00.0: failed to start hw scan: -110
  [  166.251148] workqueue: cannot queue ath11k_scan_timeout_work [ath11k] on wq D@\x7f\xff \x05\xb6...
  [  166.254814] WARNING: CPU: 2 PID: 0 at kernel/workqueue.c:2292 __queue_work+0x3c4/0x4d8

Don't queue the timeout when the scan did not start, as
ath11k_mac_op_remain_on_channel() and ath12k already do.

Fixes: d5c65159f289 ("ath11k: driver for Qualcomm IEEE 802.11ax devices")
Assisted-by: Claude:claude-opus-5-5
Signed-off-by: Christopher Griffin <christophergriffin05@gmail.com>
---
 drivers/net/wireless/ath/ath11k/mac.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/net/wireless/ath/ath11k/mac.c b/drivers/net/wireless/ath/ath11k/mac.c
index 5e4bb0ad057dd..291077c551476 100644
--- a/drivers/net/wireless/ath/ath11k/mac.c
+++ b/drivers/net/wireless/ath/ath11k/mac.c
@@ -4335,6 +4335,7 @@ static int ath11k_mac_op_hw_scan(struct ieee80211_hw *hw,
 		spin_lock_bh(&ar->data_lock);
 		ar->scan.state = ATH11K_SCAN_IDLE;
 		spin_unlock_bh(&ar->data_lock);
+		goto exit;
 	}
 
 	ieee80211_queue_delayed_work(ar->hw, &ar->scan.timeout,

-- 
2.43.0

