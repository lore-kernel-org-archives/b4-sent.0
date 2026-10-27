From: Ishu Brar <patches@brar.si>
Date: Tue, 27 Oct 2026 11:49:31 +0530
Subject: [PATCH] soc: qcom: ubwc: Add SM7250 configuration
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261027-ubwc-sm7250-v1-1-e766b1e264cf@brar.si>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDAyNj3dKk8mTd4lxzI1MDXSMTI0szg5Q08+QUcyWgjoKi1LTMCrBp0bE
 QfnFpUlZqcgnICKXaWgBUVytYbwAAAA==
X-Change-ID: 20261023-ubwc-sm7250-242960df7cd7
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Ishu Brar <patches@brar.si>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793081973; l=2431;
 i=patches@brar.si; h=from:subject:message-id;
 bh=REZcuYhSVnpK6b9bGZLR8ew5vobahVC+TA4omr/hSOI=;
 b=P9YCRWo9cUO0sMQMc+mKBfT6mQPQ2Kx+JESL+Z/8VBissJTa540GGBwSrT4m+eTQoCGLrMPJB
 M71j8bl6kmBA6MMl9+MzmLb0qDgnsOCMIPMFG06Kya9lKaGIiydbKL6
X-Developer-Key: i=patches@brar.si; a=ed25519;
 pk=Ds+E23E3ntzjPzuBDyVRkOouclcNI5k75R+N42yJtCk=
X-Endpoint-Received: by B4 Relay for patches@brar.si/default with auth_id=1189
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the UBWC configuration of the Qualcomm SM7250 SoC (Snapdragon
765/765G/768G): UBWC encoder version 3.0 with highest bank bit 14.

The downstream GPU devicetree of the platform sets qcom,ubwc-mode to 3
(UBWC 3.0) and a highest bank bit of 14, the downstream GPU driver does
not enable the 8-channel macrotile mode of UBWC 3.1, and the downstream
display devicetree also gives UBWC 3.0. No existing entry has UBWC 3.0
with this bank bit, so add one.

Without an entry, the Adreno and DPU drivers fail to probe on SM7250,
because qcom_ubwc_config_get_data() returns an error.

Signed-off-by: Ishu Brar <patches@brar.si>
---
Add the UBWC configuration entry of the Qualcomm SM7250 SoC. The Adreno 620
series [1] and the coming DPU series need it: both call
qcom_ubwc_config_get_data() at probe, which fails without an entry.

Tested on a OnePlus Nord (a 7.3 based tree): the Adreno 620 and the
display probe with this entry, the GPU runs Vulkan work and the desktop
renders without visible corruption.

[1] https://lore.kernel.org/r/20261023-adreno-a620-v3-0-2d1d566e5e13@brar.si
---
 drivers/soc/qcom/ubwc_config.c | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/drivers/soc/qcom/ubwc_config.c b/drivers/soc/qcom/ubwc_config.c
index a4d8769f8550..456995699fdb 100644
--- a/drivers/soc/qcom/ubwc_config.c
+++ b/drivers/soc/qcom/ubwc_config.c
@@ -42,6 +42,11 @@ static const struct qcom_ubwc_cfg_data ubwc_2_0_hbb15 = {
 	.highest_bank_bit = 15,
 };
 
+static const struct qcom_ubwc_cfg_data ubwc_3_0_hbb14 = {
+	.ubwc_enc_version = UBWC_3_0,
+	.highest_bank_bit = 14,
+};
+
 static const struct qcom_ubwc_cfg_data ubwc_3_0_hbb15 = {
 	.ubwc_enc_version = UBWC_3_0,
 	.highest_bank_bit = 15,
@@ -168,6 +173,7 @@ static const struct of_device_id qcom_ubwc_configs[] __maybe_unused = {
 	{ .compatible = "qcom,sm7125", .data = &ubwc_2_0_hbb14, },
 	{ .compatible = "qcom,sm7150", .data = &ubwc_2_0_hbb14, },
 	{ .compatible = "qcom,sm7225", .data = &ubwc_2_0_hbb14, },
+	{ .compatible = "qcom,sm7250", .data = &ubwc_3_0_hbb14, },
 	{ .compatible = "qcom,sm7325", .data = &ubwc_3_1_hbb14, },
 	{ .compatible = "qcom,sm8150", .data = &ubwc_3_0_hbb15, },
 	{ .compatible = "qcom,sm8250", .data = &ubwc_4_0_hbb16, },

---
base-commit: f5672a3dff0291d6a45eb0c258b9d2baeb4dc577
change-id: 20261023-ubwc-sm7250-242960df7cd7

Best regards,
--  
Ishu Brar <patches@brar.si>

