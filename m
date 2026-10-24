From: Christopher Griffin <christophergriffin05@gmail.com>
Date: Sat, 24 Oct 2026 16:30:55 -0500
Subject: [PATCH ath-next 2/2] wifi: ath11k: don't take a monitor PPDU ID of
 0 for no change
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261024-ath11k-monitor-buffers-v1-2-ff155feca2f6@gmail.com>
References: <20261024-ath11k-monitor-buffers-v1-0-ff155feca2f6@gmail.com>
In-Reply-To: <20261024-ath11k-monitor-buffers-v1-0-ff155feca2f6@gmail.com>
To: Jeff Johnson <jjohnson@kernel.org>
Cc: linux-wireless@vger.kernel.org, ath11k@lists.infradead.org, 
 linux-kernel@vger.kernel.org, 
 Christopher Griffin <christophergriffin05@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792877453; l=2187;
 i=christophergriffin05@gmail.com; s=20261024; h=from:subject:message-id;
 bh=mWyrYADTKRJAnEcFm7KXNuli5w0DYkuiREx7rbQbq5M=;
 b=rNMjczzUXb7VnePkgWQlGNDVjyS/uUQGAAxfonLR0tVE0T+VvDwjw6oitt9CT3bOQhzGyeDRy
 jOhe4GllrKFCkR6gg6ylcqv2nf3JaafrQteIhEFlZ8Vwtqx6WYI0g4n
X-Developer-Key: i=christophergriffin05@gmail.com; a=ed25519;
 pk=oa9tkTNpiGoFWdGvpDHXLSobApmsh9BfrJRJrRJAvWA=
X-Endpoint-Received: by B4 Relay for christophergriffin05@gmail.com/20261024 with auth_id=1309
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ath11k_dp_rx_mon_comp_ppduid() returns the PPDU ID it moved *ppdu_id
to, and ath11k_dp_rx_mon_mpdu_pop() takes a return of 0 for "no
change". When the destination ring's PPDU ID wraps to 0, it moves
*ppdu_id to 0 and returns 0, so mpdu_pop goes on and chains the MPDU.
The caller, ath11k_dp_rx_mon_dest_process(), then sees its ppdu_id
changed and breaks out with that chain neither delivered nor freed.

On an IPQ8074 with a monitor interface on each radio this lost 37 MPDU
chains in 47 minutes (2.8 million MPDUs); with this change, none in 46
minutes at the same load (3.2 million).

Return whether the PPDU ID changed.

Tested-on: IPQ8074 hw2.0 AHB WLAN.HK.2.9.0.1-02146-QCAHKSWPL_SILICONZ-1

Fixes: d5c65159f289 ("ath11k: driver for Qualcomm IEEE 802.11ax devices")
Signed-off-by: Christopher Griffin <christophergriffin05@gmail.com>
---
 drivers/net/wireless/ath/ath11k/dp_rx.c | 12 +++++-------
 1 file changed, 5 insertions(+), 7 deletions(-)

diff --git a/drivers/net/wireless/ath/ath11k/dp_rx.c b/drivers/net/wireless/ath/ath11k/dp_rx.c
index f0bff6c16..64fc83ee5 100644
--- a/drivers/net/wireless/ath/ath11k/dp_rx.c
+++ b/drivers/net/wireless/ath/ath11k/dp_rx.c
@@ -4656,15 +4656,13 @@ static void ath11k_hal_rx_msdu_list_get(struct ath11k *ar,
 	*num_msdus = i;
 }
 
-static u32 ath11k_dp_rx_mon_comp_ppduid(u32 msdu_ppdu_id, u32 *ppdu_id,
-					u32 *rx_bufs_used)
+static bool ath11k_dp_rx_mon_comp_ppduid(u32 msdu_ppdu_id, u32 *ppdu_id,
+					 u32 *rx_bufs_used)
 {
-	u32 ret = 0;
-
 	if ((*ppdu_id < msdu_ppdu_id) &&
 	    ((msdu_ppdu_id - *ppdu_id) < DP_NOT_PPDU_ID_WRAP_AROUND)) {
 		*ppdu_id = msdu_ppdu_id;
-		ret = msdu_ppdu_id;
+		return true;
 	} else if ((*ppdu_id > msdu_ppdu_id) &&
 		((*ppdu_id - msdu_ppdu_id) > DP_NOT_PPDU_ID_WRAP_AROUND)) {
 		/* mon_dst is behind than mon_status
@@ -4672,9 +4670,9 @@ static u32 ath11k_dp_rx_mon_comp_ppduid(u32 msdu_ppdu_id, u32 *ppdu_id,
 		 */
 		*rx_bufs_used += 1;
 		*ppdu_id = msdu_ppdu_id;
-		ret = msdu_ppdu_id;
+		return true;
 	}
-	return ret;
+	return false;
 }
 
 static void ath11k_dp_mon_get_buf_len(struct hal_rx_msdu_desc_info *info,

-- 
2.43.0

