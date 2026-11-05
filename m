From: Christopher Griffin <christophergriffin05@gmail.com>
Date: Wed, 04 Nov 2026 23:17:27 -0600
Subject: [PATCH ath-next 2/2] wifi: ath12k: don't bit-reverse the
 firmware's PPE thresholds
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261104-ath-ppe-thresholds-bit-order-v1-2-0f569106cbc4@gmail.com>
References: <20261104-ath-ppe-thresholds-bit-order-v1-0-0f569106cbc4@gmail.com>
In-Reply-To: <20261104-ath-ppe-thresholds-bit-order-v1-0-0f569106cbc4@gmail.com>
To: Jeff Johnson <jjohnson@kernel.org>, John Crispin <john@phrozen.org>, 
 Kalle Valo <kvalo@kernel.org>, 
 Shashidhar Lakkavalli <slakkavalli@datto.com>, 
 P Praneesh <quic_ppranees@quicinc.com>, 
 Pradeep Kumar Chitrapu <quic_pradeepc@quicinc.com>, 
 Karthikeyan Periyasamy <quic_periyasa@quicinc.com>, 
 Wen Gong <quic_wgong@quicinc.com>
Cc: linux-wireless@vger.kernel.org, ath11k@lists.infradead.org, 
 linux-kernel@vger.kernel.org, 
 Baochen Qiang <baochen.qiang@oss.qualcomm.com>, 
 Carl Huang <quic_cjhuang@quicinc.com>, 
 Ramya Gnanasekar <quic_rgnanase@quicinc.com>, 
 Balamurugan Selvarajan <quic_bselvara@quicinc.com>, 
 ath12k@lists.infradead.org, 
 Christopher Griffin <christophergriffin05@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793855845; l=1920;
 i=christophergriffin05@gmail.com; s=20261024; h=from:subject:message-id;
 bh=SMblyxjOwtNSOyKKPUpr21wi2JYn4nPN/eEapCpTvQM=;
 b=O2mE/jfSWzTKdAb79q7OZtw8Y3o9lqo5OB5LbHvFB/hM8f/2FLXAD3F6nkRLgPIcNmnGlE+1n
 HC7onnizJ7rC3fyX6vRhcLNy1Eev2SizV/agDLCvi7mY5o46dVBIfwE
X-Developer-Key: i=christophergriffin05@gmail.com; a=ed25519;
 pk=oa9tkTNpiGoFWdGvpDHXLSobApmsh9BfrJRJrRJAvWA=
X-Endpoint-Received: by B4 Relay for christophergriffin05@gmail.com/20261024 with auth_id=1309
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The firmware reports its PPE thresholds as WMI defines them: in
ppet16_ppet8_ru3_ru0[nss], each RU has six bits, PPET16 in bits 2:0 and
PPET8 in bits 5:3, each a 3-bit constellation index. The PPE Thresholds
field of the HE Capabilities element carries the same two subfields in
the same order, bit 0 first, and ath12k_peer_assoc_h_he() already
converts a peer's field to the WMI layout that way.

ath12k_gen_ppe_thresh(), which builds our own field from the firmware's,
swaps the two halves and then writes the six bits from the top down.
That puts PPET16 first again, but with its three bits reversed, and the
same for PPET8: a threshold of 1 (QPSK) is advertised as 4 (256-QAM),
4 as 1, 3 (64-QAM) as 6 (reserved) and 6 as 3. Only 0, 2, 5 and 7 (none)
come out right, so the bug does not show with firmware that asks for
16 us padding at every constellation (PPET16 0, PPET8 7).

Copy the six bits in order.

Compile-tested; ath11k has the same function and gets the same fix.

Fixes: d889913205cf ("wifi: ath12k: driver for Qualcomm Wi-Fi 7 devices")
Assisted-by: Claude:claude-opus-5-5
Signed-off-by: Christopher Griffin <christophergriffin05@gmail.com>
---
 drivers/net/wireless/ath/ath12k/mac.c | 3 +--
 1 file changed, 1 insertion(+), 2 deletions(-)

diff --git a/drivers/net/wireless/ath/ath12k/mac.c b/drivers/net/wireless/ath/ath12k/mac.c
index 9fd3841f71b71..ebf28a8089ca8 100644
--- a/drivers/net/wireless/ath/ath12k/mac.c
+++ b/drivers/net/wireless/ath/ath12k/mac.c
@@ -8647,8 +8647,7 @@ static void ath12k_gen_ppe_thresh(struct ath12k_wmi_ppe_threshold_arg *fw_ppet,
 				continue;
 			val = (fw_ppet->ppet16_ppet8_ru3_ru0[nss] >> (ru * 6)) &
 			       0x3f;
-			val = ((val >> 3) & 0x7) | ((val & 0x7) << 3);
-			for (i = 5; i >= 0; i--) {
+			for (i = 0; i < 6; i++) {
 				he_ppet[bit / 8] |=
 					((val >> i) & 0x1) << ((bit % 8));
 				bit++;

-- 
2.43.0

