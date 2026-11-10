From: Christopher Griffin <christophergriffin05@gmail.com>
Date: Tue, 10 Nov 2026 08:37:52 -0600
Subject: [PATCH v2 1/2] wifi: ath11k: simplify copying a peer's PPE
 thresholds
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-ath-peer-ppe-thres-loop-v2-1-fced87507920@gmail.com>
References: <20261110-ath-peer-ppe-thres-loop-v2-0-fced87507920@gmail.com>
In-Reply-To: <20261110-ath-peer-ppe-thres-loop-v2-0-fced87507920@gmail.com>
To: Jeff Johnson <jjohnson@kernel.org>
Cc: Rameshkumar Sundaram <rameshkumar.sundaram@oss.qualcomm.com>, 
 Baochen Qiang <baochen.qiang@oss.qualcomm.com>, 
 linux-wireless@vger.kernel.org, ath11k@lists.infradead.org, 
 ath12k@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Jeff Johnson <jeff.johnson@oss.qualcomm.com>, 
 Christopher Griffin <christophergriffin05@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794321472; l=1371;
 i=christophergriffin05@gmail.com; s=20261024; h=from:subject:message-id;
 bh=+v0/mtei21f+uWsVMg5ZCRb77EqWbxbixU5qhwUbCuI=;
 b=T4WDyBltYopDh9pNqvEwmGuyvOV4RHN47HxHiexGgQTrBn6RmOIBzBRPZdqVwztDMwGny8RtK
 HIc+nHYU2v8AVtVXU0y+hawhSJ9xXlLLJ+PAKhqJYa/zEn92c0MlGc/
X-Developer-Key: i=christophergriffin05@gmail.com; a=ed25519;
 pk=oa9tkTNpiGoFWdGvpDHXLSobApmsh9BfrJRJrRJAvWA=
X-Endpoint-Received: by B4 Relay for christophergriffin05@gmail.com/20261024 with auth_id=1309
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ath11k_peer_assoc_h_he() copies each 6-bit PPE threshold of a peer's HE
capabilities into the WMI layout one bit at a time, shifting it in from
the top: val >>= 1, then the new bit at bit 5, six times over. After the
sixth bit, bit i of the field sits at bit i of val, so put it there
directly.

No functional change.

This change and its message were written with Claude, an AI coding
assistant.

Suggested-by: Rameshkumar Sundaram <rameshkumar.sundaram@oss.qualcomm.com>
Link: https://lore.kernel.org/all/b60c4c56-483b-406e-92ab-643b0fdf2dc8@oss.qualcomm.com/
Signed-off-by: Christopher Griffin <christophergriffin05@gmail.com>
---
 drivers/net/wireless/ath/ath11k/mac.c | 3 +--
 1 file changed, 1 insertion(+), 2 deletions(-)

diff --git a/drivers/net/wireless/ath/ath11k/mac.c b/drivers/net/wireless/ath/ath11k/mac.c
index 1a237adaa37d1..d7ae9e8747233 100644
--- a/drivers/net/wireless/ath/ath11k/mac.c
+++ b/drivers/net/wireless/ath/ath11k/mac.c
@@ -2496,9 +2496,8 @@ static void ath11k_peer_assoc_h_he(struct ath11k *ar,
 				if ((arg->peer_ppet.ru_bit_mask & BIT(ru)) == 0)
 					continue;
 				for (i = 0; i < 6; i++) {
-					val >>= 1;
 					val |= ((he_cap->ppe_thres[bit / 8] >>
-						 (bit % 8)) & 0x1) << 5;
+						 (bit % 8)) & 0x1) << i;
 					bit++;
 				}
 				arg->peer_ppet.ppet16_ppet8_ru3_ru0[nss] |=

-- 
2.43.0

