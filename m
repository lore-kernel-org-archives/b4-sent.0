From: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
Date: Sun, 13 Oct 2024 13:54:04 +0200
Subject: [PATCH v3 2/3] firmware: qcom: scm: Allow QSEECOM for Windows Dev
 Kit 2023
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241013-jg-blackrock-for-upstream-v3-2-839d3483a8e7@oldschoolsolutions.biz>
References: <20241013-jg-blackrock-for-upstream-v3-0-839d3483a8e7@oldschoolsolutions.biz>
In-Reply-To: <20241013-jg-blackrock-for-upstream-v3-0-839d3483a8e7@oldschoolsolutions.biz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Jens Glathe <jens.glathe@oldschoolsolutions.biz>, 
 Merck Hung <merckhung@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1728820456; l=916;
 i=jens.glathe@oldschoolsolutions.biz; s=20240919; h=from:subject:message-id;
 bh=01PvXXK7gB43rwXvTNPNUoS1yfe6XHhWKGe+TIBgjfI=;
 b=OJDuL8wn4tN/ew0ihSLsAaIaDx3NLa4Je2gTRfJbxGHMHrJwFOVvoTh7JRqCG+u9lclooEE5v
 e9xSPhR4L5kBJxP8zhXIdKXs32EnLLjeQgcXScej9eYjzYSE30dQCh9
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
index ebb58bd63edad..e98390e17b217 100644
--- a/drivers/firmware/qcom/qcom_scm.c
+++ b/drivers/firmware/qcom/qcom_scm.c
@@ -1736,6 +1736,7 @@ static const struct of_device_id qcom_scm_qseecom_allowlist[] __maybe_unused = {
 	{ .compatible = "lenovo,thinkpad-x13s", },
 	{ .compatible = "lenovo,yoga-slim7x" },
 	{ .compatible = "microsoft,arcata", },
+	{ .compatible = "microsoft,blackrock" },
 	{ .compatible = "microsoft,romulus13", },
 	{ .compatible = "microsoft,romulus15", },
 	{ .compatible = "qcom,sc8180x-primus" },

-- 
2.43.0

