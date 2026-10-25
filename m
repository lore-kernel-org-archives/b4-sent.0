From: Christopher Griffin <christophergriffin05@gmail.com>
Date: Sat, 24 Oct 2026 19:33:01 -0500
Subject: [PATCH ath-next] wifi: ath11k: fix beacon stats with more than one
 started vdev
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261024-ath11k-bcn-stats-v1-1-1355f86ec907@gmail.com>
X-B4-Tracking: v=1; b=H4sIADxO3WoC/yWMSwrDMAwFrxK0rsByQxe5SujCH6VRAm6x1BAIu
 Xvddjm8N3OAchVWGLoDKm+i8iwN6NJBmkN5MEpuDN75GznfY7CZaMWYCqoFU3TXKebecY6eoGm
 vypPsv+QI7Y2Fd4P7f9F3XDjZtwjn+QEHglELfgAAAA==
X-Change-ID: 20261024-ath11k-bcn-stats-03fbd40edb21
To: Jeff Johnson <jjohnson@kernel.org>
Cc: linux-wireless@vger.kernel.org, ath11k@lists.infradead.org, 
 linux-kernel@vger.kernel.org, 
 Christopher Griffin <christophergriffin05@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792888380; l=3718;
 i=christophergriffin05@gmail.com; s=20261024; h=from:subject:message-id;
 bh=vMs+Yy0kwU5J/ZNugFhL2guGxAJmpSpiZGhMOQQV6/c=;
 b=e+0h242b8f1f3kyTwb1214FNrbc3wtmB5iK/fbrbc8ioniBBRKm6hxrJ6VE2Z0XcAZHZNVQz+
 ZDzCgRu+0LdBLct259/0Jy0o0uledG+ZV8FRx4tPrCppH+yDA42QXLZ
X-Developer-Key: i=christophergriffin05@gmail.com; a=ed25519;
 pk=oa9tkTNpiGoFWdGvpDHXLSobApmsh9BfrJRJrRJAvWA=
X-Endpoint-Received: by B4 Relay for christophergriffin05@gmail.com/20261024 with auth_id=1309
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ath11k_open_bcn_stats() requests beacon stats one vdev at a time, and
ath11k_mac_fw_stats_request() waits for fw_stats_done after each
request. ath11k_debugfs_fw_stats_process() completes fw_stats_done only
once num_bcn_recvd reaches num_started_vdevs, but every request resets
num_bcn_recvd first. With more than one started vdev the count is never
reached, the first request times out, and reading fw_stats/beacon_stats
fails with -ETIMEDOUT.

Complete fw_stats_done on each beacon stats reply and drop
num_bcn_recvd, as ath12k does since commit 2977567b244f ("wifi: ath12k:
Fix timeout error during beacon stats retrieval").

Tested-on: IPQ8074 hw2.0 AHB WLAN.HK.2.9.0.1-02146-QCAHKSWPL_SILICONZ-1

Fixes: 9f6e82d11bb9 ("wifi: ath11k: avoid burning CPU in ath11k_debugfs_fw_stats_request()")
Fixes: 2bcf73b2612d ("wifi: ath11k: don't use static variables in ath11k_debugfs_fw_stats_process()")
Assisted-by: Claude:claude-opus-5-5
Signed-off-by: Christopher Griffin <christophergriffin05@gmail.com>
---
Found on an Arista C-260 (IPQ8074), where reading beacon_stats failed
on both radios, each running four BSSes.
---
 drivers/net/wireless/ath/ath11k/core.h    |  1 -
 drivers/net/wireless/ath/ath11k/debugfs.c | 12 +++---------
 drivers/net/wireless/ath/ath11k/mac.c     |  1 -
 3 files changed, 3 insertions(+), 11 deletions(-)

diff --git a/drivers/net/wireless/ath/ath11k/core.h b/drivers/net/wireless/ath/ath11k/core.h
index a0d725923..9be0259e7 100644
--- a/drivers/net/wireless/ath/ath11k/core.h
+++ b/drivers/net/wireless/ath/ath11k/core.h
@@ -616,7 +616,6 @@ struct ath11k_fw_stats {
 	struct list_head vdevs;
 	struct list_head bcn;
 	u32 num_vdev_recvd;
-	u32 num_bcn_recvd;
 };
 
 struct ath11k_dbg_htt_stats {
diff --git a/drivers/net/wireless/ath/ath11k/debugfs.c b/drivers/net/wireless/ath/ath11k/debugfs.c
index 70922612d..3e4375715 100644
--- a/drivers/net/wireless/ath/ath11k/debugfs.c
+++ b/drivers/net/wireless/ath/ath11k/debugfs.c
@@ -97,7 +97,6 @@ void ath11k_debugfs_add_dbring_entry(struct ath11k *ar,
 void ath11k_debugfs_fw_stats_process(struct ath11k *ar, struct ath11k_fw_stats *stats)
 {
 	struct ath11k_base *ab = ar->ab;
-	bool is_end = true;
 
 	/* WMI_REQUEST_PDEV_STAT, WMI_REQUEST_RSSI_PER_CHAIN_STAT and
 	 * WMI_REQUEST_VDEV_STAT requests have been already processed.
@@ -107,18 +106,13 @@ void ath11k_debugfs_fw_stats_process(struct ath11k *ar, struct ath11k_fw_stats *
 			ath11k_warn(ab, "empty bcn stats");
 			return;
 		}
-		/* Mark end until we reached the count of all started VDEVs
-		 * within the PDEV
+		/* ath11k_open_bcn_stats() requests one vdev's beacon stats at
+		 * a time, so one reply ends a request.
 		 */
-		if (ar->num_started_vdevs)
-			is_end = ((++ar->fw_stats.num_bcn_recvd) ==
-				  ar->num_started_vdevs);
-
 		list_splice_tail_init(&stats->bcn,
 				      &ar->fw_stats.bcn);
 
-		if (is_end)
-			complete(&ar->fw_stats_done);
+		complete(&ar->fw_stats_done);
 	}
 }
 
diff --git a/drivers/net/wireless/ath/ath11k/mac.c b/drivers/net/wireless/ath/ath11k/mac.c
index 1a237adaa..74ecf4661 100644
--- a/drivers/net/wireless/ath/ath11k/mac.c
+++ b/drivers/net/wireless/ath/ath11k/mac.c
@@ -4059,7 +4059,6 @@ static void ath11k_mac_fw_stats_reset(struct ath11k *ar)
 	ath11k_fw_stats_pdevs_free(&ar->fw_stats.pdevs);
 	ath11k_fw_stats_vdevs_free(&ar->fw_stats.vdevs);
 	ar->fw_stats.num_vdev_recvd = 0;
-	ar->fw_stats.num_bcn_recvd = 0;
 	spin_unlock_bh(&ar->data_lock);
 }
 

---
base-commit: cd026e68fdbf88b9cc522b76c7a9d92c9a41f709
change-id: 20261024-ath11k-bcn-stats-03fbd40edb21

Best regards,
--  
Christopher Griffin <christophergriffin05@gmail.com>

