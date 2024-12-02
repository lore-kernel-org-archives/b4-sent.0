From: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
Date: Mon, 02 Dec 2024 20:59:46 +0100
Subject: [PATCH v9 2/3] firmware: qcom: scm: Allow QSEECOM for Windows Dev
 Kit 2023
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241202-jg-blackrock-for-upstream-v9-2-385bb46ca122@oldschoolsolutions.biz>
References: <20241202-jg-blackrock-for-upstream-v9-0-385bb46ca122@oldschoolsolutions.biz>
In-Reply-To: <20241202-jg-blackrock-for-upstream-v9-0-385bb46ca122@oldschoolsolutions.biz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Kalle Valo <kvalo@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Merck Hung <merckhung@gmail.com>, 
 xlazom00@gmail.com, Jens Glathe <jens.glathe@oldschoolsolutions.biz>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1733169587; l=916;
 i=jens.glathe@oldschoolsolutions.biz; s=20240919; h=from:subject:message-id;
 bh=SPEO1LR4rPbgAYook8a7vfGRX+RKcgosJIhhsVSzbHY=;
 b=HRBdgbw8S35D9PXLsDv1bkVCSENcOPtBkheB2NxYSq+p+ymtyPMorZKB4MMsTYF4tbX5TfOcD
 CsVrVRArYJWD6jv+JHp2CW/WwTMGU2+1yMmMXTYA0XLjy27fHu/9cHI
X-Developer-Key: i=jens.glathe@oldschoolsolutions.biz; a=ed25519;
 pk=JcRJqJc/y8LsxOlPakALD3juGfOKmFBWtO+GfELMJVg=
X-Endpoint-Received: by B4 Relay for jens.glathe@oldschoolsolutions.biz/20240919 with auth_id=216
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

add "microsoft,blackrock" as compatible device for QSEECOM

This is required to get access to efivars and uefi boot loader support.

Signed-off-by: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
---
 drivers/firmware/qcom/qcom_scm.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/firmware/qcom/qcom_scm.c b/drivers/firmware/qcom/qcom_scm.c
index 72bf87ddcd969..bd660618fb365 100644
--- a/drivers/firmware/qcom/qcom_scm.c
+++ b/drivers/firmware/qcom/qcom_scm.c
@@ -1774,6 +1774,7 @@ static const struct of_device_id qcom_scm_qseecom_allowlist[] __maybe_unused = {
 	{ .compatible = "lenovo,thinkpad-x13s", },
 	{ .compatible = "lenovo,yoga-slim7x" },
 	{ .compatible = "microsoft,arcata", },
+	{ .compatible = "microsoft,blackrock" },
 	{ .compatible = "microsoft,romulus13", },
 	{ .compatible = "microsoft,romulus15", },
 	{ .compatible = "qcom,sc8180x-primus" },

-- 
2.43.0

