From: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
Date: Fri, 16 May 2025 08:43:00 +0200
Subject: [PATCH v2 2/4] firmware: qcom: scm: Allow QSEECOM on Lenovo
 Thinkbook 16
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250516-tb16-dt-v2-2-7c4996d58ed6@oldschoolsolutions.biz>
References: <20250516-tb16-dt-v2-0-7c4996d58ed6@oldschoolsolutions.biz>
In-Reply-To: <20250516-tb16-dt-v2-0-7c4996d58ed6@oldschoolsolutions.biz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Johan Hovold <johan+linaro@kernel.org>, 
 Aleksandrs Vinarskis <alex.vinarskis@gmail.com>, 
 Jens Glathe <jens.glathe@oldschoolsolutions.biz>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1747377794; l=871;
 i=jens.glathe@oldschoolsolutions.biz; s=20240919; h=from:subject:message-id;
 bh=SqyOjM4lFCEsz5Ib0lcU303VTifLpUJsBJ9F9U5GZRI=;
 b=LSBskCbhnBnbN47ZFiZAB5dGmIVdTiSZtujGvvo6I7siwvxScHDybhxM1Us+yWqCV2ZBF+sIw
 MqeS7EZ1XqdCNgfr6l9LKPPXO/GaKo5B6D8OavuyPjJuj2tjQ5Y4j8E
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
index f63b716be5b027550ae3a987e784f0814ea6d678..171cc2a6502463e3445919ef77a129563ea233a4 100644
--- a/drivers/firmware/qcom/qcom_scm.c
+++ b/drivers/firmware/qcom/qcom_scm.c
@@ -1993,6 +1993,7 @@ static const struct of_device_id qcom_scm_qseecom_allowlist[] __maybe_unused = {
 	{ .compatible = "hp,omnibook-x14" },
 	{ .compatible = "huawei,gaokun3" },
 	{ .compatible = "lenovo,flex-5g" },
+	{ .compatible = "lenovo,thinkbook-16" },
 	{ .compatible = "lenovo,thinkpad-t14s" },
 	{ .compatible = "lenovo,thinkpad-x13s", },
 	{ .compatible = "lenovo,yoga-slim7x" },

-- 
2.48.1

