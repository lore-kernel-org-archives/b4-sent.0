From: George Moussalem <george.moussalem@outlook.com>
Date: Wed, 23 Sep 2026 16:05:15 +0400
Subject: [PATCH ath-next 09/16] wifi: ath11k: Power down userPD
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260923-ipq5018-qcn6122-mpd-v1-9-86729521a75c@outlook.com>
References: <20260923-ipq5018-qcn6122-mpd-v1-0-86729521a75c@outlook.com>
In-Reply-To: <20260923-ipq5018-qcn6122-mpd-v1-0-86729521a75c@outlook.com>
To: Johannes Berg <johannes@sipsolutions.net>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jeff Johnson <jjohnson@kernel.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: linux-wireless@vger.kernel.org, devicetree@vger.kernel.org, 
 ath11k@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Vignesh Viswanathan <vignesh.viswanathan@oss.qualcomm.com>, 
 Varadarajan Narayanan <varadarajan.narayanan@oss.qualcomm.com>, 
 linux-arm-msm@vger.kernel.org, 
 George Moussalem <george.moussalem@outlook.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790165117; l=1688;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=f09E/N0UiP2BKaMQj6y/PbCNtm6/77F+Gx3rtxqkmB0=;
 b=8Th6YZPBmOceHukUz3XAVEKAdI2Cb3gd5mOzw5oZb3/5aqmJLgMbeVE3tRwO8PaAU9+RY1cc6
 W713+4AAuEVBuPqzDvgliJZ/m4MhgZmELOS/ZXzN9j2FWPOlmA5dlAo
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Set the stop bit in SMEM to stop the userPD. Wait for stop-ack IRQ to
indicate power down completion.

For IPQ5018 wifi specifically, invoke an SCM call to power down the
radio.

Signed-off-by: George Moussalem <george.moussalem@outlook.com>
---
 drivers/net/wireless/ath/ath11k/ahb.c | 25 ++++++++++++++++++++++++-
 1 file changed, 24 insertions(+), 1 deletion(-)

diff --git a/drivers/net/wireless/ath/ath11k/ahb.c b/drivers/net/wireless/ath/ath11k/ahb.c
index 2c41cf585d00..1b9115311bed 100644
--- a/drivers/net/wireless/ath/ath11k/ahb.c
+++ b/drivers/net/wireless/ath/ath11k/ahb.c
@@ -491,9 +491,32 @@ static int ath11k_ahb_power_up(struct ath11k_base *ab)
 	return 0;
 }
 
+static void ath11k_ahb_stop_user_pd(struct ath11k_base *ab)
+{
+	struct ath11k_ahb *ab_ahb = ath11k_ahb_priv(ab);
+	unsigned long time_left;
+
+	qcom_smem_state_update_bits(ab_ahb->stop_state, BIT(ab_ahb->stop_bit),
+				    BIT(ab_ahb->stop_bit));
+
+	time_left = wait_for_completion_timeout(&ab_ahb->userpd_stopped,
+						ATH11K_USERPD_STOP_TIMEOUT);
+	if (!time_left)
+		ath11k_warn(ab, "UserPD stop wait timed out\n");
+
+	qcom_smem_state_update_bits(ab_ahb->stop_state, BIT(ab_ahb->stop_bit), 0);
+
+	if (ab->hw_rev == ATH11K_HW_IPQ5018_HW10)
+		qcom_scm_pas_set_wifi_power_mode(MPD_WCNSS_PAS_ID, false);
+}
+
 static void ath11k_ahb_power_down(struct ath11k_base *ab, bool is_suspend)
 {
-	return;
+	struct ath11k_ahb *ab_ahb = ath11k_ahb_priv(ab);
+
+	if (ab_ahb->userpd_id > 0 &&
+	    ab_ahb->userpd_id < ATH11K_AHB_USERPD_ID_MAX)
+		ath11k_ahb_stop_user_pd(ab);
 }
 
 static void ath11k_ahb_init_qmi_ce_config(struct ath11k_base *ab)

-- 
2.53.0

