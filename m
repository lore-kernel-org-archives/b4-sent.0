From: Christopher Griffin <christophergriffin05@gmail.com>
Date: Thu, 05 Nov 2026 12:11:38 -0600
Subject: [PATCH 3/3] wifi: ath10k: don't arm the scan timeout for a scan
 that did not start
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261105-ath-recovery-scan-timeout-v1-3-99a70d89e114@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793902298; l=1474;
 i=christophergriffin05@gmail.com; s=20261024; h=from:subject:message-id;
 bh=8zbD+lVnCTk/jEl5MxoVBJ8ccaebPXe50Jkz06PSJ0A=;
 b=93y/2nl2YnFu6ut5Bipi9DZVLRdNz+4uwAG5tLNRkc+9yVtXFwKW2evOomIGBWZaD28W8JsoP
 soM4m5afM/6A/qZsSUC5/VBfZMLOzbkzBho8GVpxty70WnYk0VTebWq
X-Developer-Key: i=christophergriffin05@gmail.com; a=ed25519;
 pk=oa9tkTNpiGoFWdGvpDHXLSobApmsh9BfrJRJrRJAvWA=
X-Endpoint-Received: by B4 Relay for christophergriffin05@gmail.com/20261024 with auth_id=1309
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When ath10k_start_scan() fails, ath10k_hw_scan() sets the scan state
back to idle and returns the error to mac80211, but first still queues
ar->scan.timeout. The timeout then stays pending for the full scan time
(20 s by default) although no scan is running. A scan started within
that time gets no timeout of its own, as the work is already pending,
and the stale one aborts it early.

Don't queue the timeout when the scan did not start, as
ath10k_remain_on_channel() already does. Until commit 634349bae0b2
("ath10k: move hw_scan worker queuing") ath10k_start_scan() queued it,
on success only.

ath11k has the same code; there, a QCN9074 firmware crash during a scan
left such a timeout pending.

Fixes: 634349bae0b2 ("ath10k: move hw_scan worker queuing")
Assisted-by: Claude:claude-opus-5-5
Signed-off-by: Christopher Griffin <christophergriffin05@gmail.com>
---
 drivers/net/wireless/ath/ath10k/mac.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/net/wireless/ath/ath10k/mac.c b/drivers/net/wireless/ath/ath10k/mac.c
index 8e604697d6c20..2fded15b61721 100644
--- a/drivers/net/wireless/ath/ath10k/mac.c
+++ b/drivers/net/wireless/ath/ath10k/mac.c
@@ -6491,6 +6491,7 @@ static int ath10k_hw_scan(struct ieee80211_hw *hw,
 		spin_lock_bh(&ar->data_lock);
 		ar->scan.state = ATH10K_SCAN_IDLE;
 		spin_unlock_bh(&ar->data_lock);
+		goto exit;
 	}
 
 	ieee80211_queue_delayed_work(ar->hw, &ar->scan.timeout,

-- 
2.43.0

