From: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
Date: Sat, 14 Feb 2026 09:32:54 +0100
Subject: [PATCH v3 2/4] firmware: qcom: scm: allow QSEECOM on ASUS Vivobook
 X1P42100 variant
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260214-b4-vivobook-v3-2-3c88065bbf77@oldschoolsolutions.biz>
References: <20260214-b4-vivobook-v3-0-3c88065bbf77@oldschoolsolutions.biz>
In-Reply-To: <20260214-b4-vivobook-v3-0-3c88065bbf77@oldschoolsolutions.biz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Maud Spierings <maud_spierings@hotmail.com>, 
 "Colin K. Williams" <colin@li-nk.org>, 
 Jens Glathe <jens.glathe@oldschoolsolutions.biz>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1771057984; l=985;
 i=jens.glathe@oldschoolsolutions.biz; s=20240919; h=from:subject:message-id;
 bh=tF0yL9g/LpNrXUgoxuX8liwiZOuYk95seFYSRj/YEiI=;
 b=0GNqBYEZ0qVaMIbpeXIGwJ9D4rFy2ZQTuHMw5rEj1C0mtcG+cc+XwuwFqi5mq104wLSPv9am5
 ahIYr/YzI1bABXjZgDB8Vv9TvnnQEYfamVQ/EJnAClk/Yd7l2Y0IoCJ
X-Developer-Key: i=jens.glathe@oldschoolsolutions.biz; a=ed25519;
 pk=JcRJqJc/y8LsxOlPakALD3juGfOKmFBWtO+GfELMJVg=
X-Endpoint-Received: by B4 Relay for jens.glathe@oldschoolsolutions.biz/20240919 with auth_id=216
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Enables access to EFI variables on this machine.

Reviewed-by: Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>
Tested-by: Colin K. Williams <colin@li-nk.org>
Signed-off-by: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
---
 drivers/firmware/qcom/qcom_scm.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/firmware/qcom/qcom_scm.c b/drivers/firmware/qcom/qcom_scm.c
index 8fbc96693a55f53c508d1ddb2d7a9e62281d1544..2fe1632f06e908683ba2841d68f9d382f407a425 100644
--- a/drivers/firmware/qcom/qcom_scm.c
+++ b/drivers/firmware/qcom/qcom_scm.c
@@ -2290,6 +2290,7 @@ EXPORT_SYMBOL_GPL(qcom_scm_qseecom_app_send);
  */
 static const struct of_device_id qcom_scm_qseecom_allowlist[] __maybe_unused = {
 	{ .compatible = "asus,vivobook-s15" },
+	{ .compatible = "asus,vivobook-s15-x1p4" },
 	{ .compatible = "asus,zenbook-a14-ux3407qa" },
 	{ .compatible = "asus,zenbook-a14-ux3407ra" },
 	{ .compatible = "dell,inspiron-14-plus-7441" },

-- 
2.51.0

