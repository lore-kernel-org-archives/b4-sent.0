From: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
Date: Thu, 15 May 2025 22:38:56 +0200
Subject: [PATCH 2/4] firmware: qcom: scm: Allow QSEECOM on Lenovo Thinkbook
 16
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250515-tb16-dt-v1-2-dc5846a25c48@oldschoolsolutions.biz>
References: <20250515-tb16-dt-v1-0-dc5846a25c48@oldschoolsolutions.biz>
In-Reply-To: <20250515-tb16-dt-v1-0-dc5846a25c48@oldschoolsolutions.biz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Johan Hovold <johan+linaro@kernel.org>, 
 Aleksandrs Vinarskis <alex.vinarskis@gmail.com>, 
 Jens Glathe <jens.glathe@oldschoolsolutions.biz>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1747341542; l=871;
 i=jens.glathe@oldschoolsolutions.biz; s=20240919; h=from:subject:message-id;
 bh=qMpKHjKO2hgJNmWBGCeb19wutfZa9oDXfI5A36FWyC8=;
 b=Kp1JZHczaR5mGFiByniqRukArQ+9q93CRzeo3/5kc6PxT9UKtm+QCcTtBP3war5I9p2nZtRjZ
 f6FcZ136VuhCWP3kWwGnMItyDgvHC1HuRiJzhmf9EZuMpCJtRQxL7c5
X-Developer-Key: i=jens.glathe@oldschoolsolutions.biz; a=ed25519;
 pk=JcRJqJc/y8LsxOlPakALD3juGfOKmFBWtO+GfELMJVg=
X-Endpoint-Received: by B4 Relay for jens.glathe@oldschoolsolutions.biz/20240919 with auth_id=216
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Allow particular machine accessing eg. efivars.

Signed-off-by: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
---
 drivers/firmware/qcom/qcom_scm.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/firmware/qcom/qcom_scm.c b/drivers/firmware/qcom/qcom_scm.c
index 79128d11eb51f0efca71396338f7e7c8c913e457..ab63a04b044c42ff779588c11bd736a98735cc9e 100644
--- a/drivers/firmware/qcom/qcom_scm.c
+++ b/drivers/firmware/qcom/qcom_scm.c
@@ -1992,6 +1992,7 @@ static const struct of_device_id qcom_scm_qseecom_allowlist[] __maybe_unused = {
 	{ .compatible = "hp,omnibook-x14" },
 	{ .compatible = "huawei,gaokun3" },
 	{ .compatible = "lenovo,flex-5g" },
+	{ .compatible = "lenovo,thinkbook-16" },
 	{ .compatible = "lenovo,thinkpad-t14s" },
 	{ .compatible = "lenovo,thinkpad-x13s", },
 	{ .compatible = "lenovo,yoga-slim7x" },

-- 
2.48.1

