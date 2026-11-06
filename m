From: Christopher Griffin <christophergriffin05@gmail.com>
Date: Fri, 06 Nov 2026 08:25:04 -0600
Subject: [PATCH] wifi: ath11k: print each user's sounding counts in
 htt_stats
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261106-ath11k-sounding-stats-per-user-v1-1-6aa8e62fddf7@gmail.com>
X-B4-Tracking: v=1; b=H4sIAD/j7WoC/yXNwQrCMAyA4VcZORtYhk7nq8gOaRu3KHSjaUUYe
 3erHv/L929gklQMrs0GSV5qusQadGjAzxwnQQ21oWu7nqjtkfNM9ERbSgwaJ7TM2XCVhKVSOBz
 DwN5d3PnEUJE1yV3fv8Ft/LcV9xCfvyrs+weElegYggAAAA==
X-Change-ID: 20261106-ath11k-sounding-stats-per-user-94d9acb8b75a
To: Jeff Johnson <jjohnson@kernel.org>, Kalle Valo <kvalo@kernel.org>, 
 Baochen Qiang <baochen.qiang@oss.qualcomm.com>
Cc: linux-wireless@vger.kernel.org, ath11k@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Jeff Johnson <jeff.johnson@oss.qualcomm.com>, 
 Christopher Griffin <christophergriffin05@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793975103; l=3065;
 i=christophergriffin05@gmail.com; s=20261024; h=from:subject:message-id;
 bh=c89X/CZkTuy4umNZacZz4q0MYqGlGh/C+IYiRrx7/hI=;
 b=1L3ijR4PS3qnP2Nje9ciC8eMBRgDHYfAjTdV7FHasLRnzFQGgYENXqb2aUTOUzHwXE7yDpHsI
 sYQfftSKB9jBFp3wixheBQYWu1Rf1TL0D4Y/y4DyF9tM6+Cp4Q1/U6I
X-Developer-Key: i=christophergriffin05@gmail.com; a=ed25519;
 pk=oa9tkTNpiGoFWdGvpDHXLSobApmsh9BfrJRJrRJAvWA=
X-Endpoint-Received: by B4 Relay for christophergriffin05@gmail.com/20261024 with auth_id=1309
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The TX sounding stats of htt_stats print a "Sounding User" line for
each of the 4 (11ac) or 8 (11ax) users, but every line shows
sounding[0] to sounding[3], the 20/40/80/160 MHz counts of user 0. The
array holds the counts of all users, at sounding[user * max_bw + bw]
as the comment in struct htt_tx_sounding_stats_tlv says, and ath12k
prints it that way.

Print each user's own counts. On an IPQ8074 AP that sounded one HE
client at 40 MHz (392 SU CBF), all 8 lines showed 40 MHz: 404 before;
after, user 0 shows 404 and users 1 to 7 show 0.

Tested-on: IPQ8074 hw2.0 AHB WLAN.HK.2.9.0.1-02146-QCAHKSWPL_SILICONZ-1

Fixes: d5c65159f289 ("ath11k: driver for Qualcomm IEEE 802.11ax devices")
Assisted-by: Claude:claude-opus-5-5
Signed-off-by: Christopher Griffin <christophergriffin05@gmail.com>
---
Found on an Arista C-360 (IPQ8074) while checking that beamforming
sounding ran after enabling SU beamforming: every "Sounding User" line
of htt_stats type 22 showed the same counts.
---
 drivers/net/wireless/ath/ath11k/debugfs_htt_stats.c | 18 ++++++++----------
 1 file changed, 8 insertions(+), 10 deletions(-)

diff --git a/drivers/net/wireless/ath/ath11k/debugfs_htt_stats.c b/drivers/net/wireless/ath/ath11k/debugfs_htt_stats.c
index 731f3ca867111..5ddc1ff8492f6 100644
--- a/drivers/net/wireless/ath/ath11k/debugfs_htt_stats.c
+++ b/drivers/net/wireless/ath/ath11k/debugfs_htt_stats.c
@@ -1235,13 +1235,12 @@ static inline void htt_print_tx_sounding_stats_tlv(const void *tag_buf,
 				 cbf_160[HTT_EXPLICIT_TXBF_MU_RBO_STEER_STATS]);
 
 		for (i = 0; i < HTT_TX_PDEV_STATS_NUM_AC_MUMIMO_USER_STATS; i++) {
+			const u32 *snd = htt_stats_buf->sounding +
+					 i * HTT_TX_PDEV_STATS_NUM_BW_COUNTERS;
+
 			len += scnprintf(buf + len, buf_len - len,
 					 "Sounding User %u = 20MHz: %u, 40MHz : %u, 80MHz: %u, 160MHz: %u\n",
-					 i,
-					 htt_stats_buf->sounding[0],
-					 htt_stats_buf->sounding[1],
-					 htt_stats_buf->sounding[2],
-					 htt_stats_buf->sounding[3]);
+					 i, snd[0], snd[1], snd[2], snd[3]);
 		}
 	} else if (htt_stats_buf->tx_sounding_mode == HTT_TX_AX_SOUNDING_MODE) {
 		len += scnprintf(buf + len, buf_len - len,
@@ -1276,13 +1275,12 @@ static inline void htt_print_tx_sounding_stats_tlv(const void *tag_buf,
 				 cbf_160[HTT_EXPLICIT_TXBF_MU_RBO_STEER_STATS]);
 
 		for (i = 0; i < HTT_TX_PDEV_STATS_NUM_AX_MUMIMO_USER_STATS; i++) {
+			const u32 *snd = htt_stats_buf->sounding +
+					 i * HTT_TX_PDEV_STATS_NUM_BW_COUNTERS;
+
 			len += scnprintf(buf + len, buf_len - len,
 					 "Sounding User %u = 20MHz: %u, 40MHz : %u, 80MHz: %u, 160MHz: %u\n",
-					 i,
-					 htt_stats_buf->sounding[0],
-					 htt_stats_buf->sounding[1],
-					 htt_stats_buf->sounding[2],
-					 htt_stats_buf->sounding[3]);
+					 i, snd[0], snd[1], snd[2], snd[3]);
 		}
 	}
 

---
base-commit: 5c8eab13e391aaabd5a1ad58f3ee4bb10ce7573e
change-id: 20261106-ath11k-sounding-stats-per-user-94d9acb8b75a

Best regards,
--  
Christopher Griffin <christophergriffin05@gmail.com>

