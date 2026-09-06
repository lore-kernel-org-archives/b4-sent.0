From: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
Date: Sun, 06 Sep 2026 14:22:37 +0200
Subject: [PATCH 2/3] firmware: qcom: scm: Allow QSEECOM on Lenovo IdeaPad 5
 models
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260906-x1-ideapad-slim5x-v1-2-7ccffbe6bc4a@oldschoolsolutions.biz>
References: <20260906-x1-ideapad-slim5x-v1-0-7ccffbe6bc4a@oldschoolsolutions.biz>
In-Reply-To: <20260906-x1-ideapad-slim5x-v1-0-7ccffbe6bc4a@oldschoolsolutions.biz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Jens Glathe <jens.glathe@oldschoolsolutions.biz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788697362; l=1000;
 i=jens.glathe@oldschoolsolutions.biz; s=20240919; h=from:subject:message-id;
 bh=HV6obzoJQYZkI0vGnV/Lh7ePRT9GR5xSbdXa52p1wu8=;
 b=m8Z7Cyp6fYI2Nz1xWm0aPrBchpnVZQtFM57i7sZxvzH+cAvvFggOq8flWa/8r9xgbzMUIK38J
 4lU2AlvjMfhA8PJfCFNiQBSDEhWMwAyBqqUlz02y8GLBHKdcaYedzsn
X-Developer-Key: i=jens.glathe@oldschoolsolutions.biz; a=ed25519;
 pk=JcRJqJc/y8LsxOlPakALD3juGfOKmFBWtO+GfELMJVg=
X-Endpoint-Received: by B4 Relay for jens.glathe@oldschoolsolutions.biz/20240919 with auth_id=216
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

QSEECOM is required for EFI variables on these machines. Match
the generic "lenovo,ideapad-5" fallback so both the LCD and
OLED IdeaPad Slim 5x 14Q8X9 device trees are covered without
duplicating allowlist entries.

Signed-off-by: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
---
 drivers/firmware/qcom/qcom_scm.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/firmware/qcom/qcom_scm.c b/drivers/firmware/qcom/qcom_scm.c
index 882d1865f3a4a..a5f19c5dc089c 100644
--- a/drivers/firmware/qcom/qcom_scm.c
+++ b/drivers/firmware/qcom/qcom_scm.c
@@ -2231,6 +2231,7 @@ static const struct of_device_id qcom_scm_qseecom_allowlist[] __maybe_unused = {
 	{ .compatible = "huawei,gaokun3" },
 	{ .compatible = "lenovo,flex-5g" },
 	{ .compatible = "lenovo,ideacentre-mini-01q8x10" },
+	{ .compatible = "lenovo,ideapad-5" },
 	{ .compatible = "lenovo,thinkbook-16" },
 	{ .compatible = "lenovo,thinkpad-t14s" },
 	{ .compatible = "lenovo,thinkpad-x13s", },

-- 
2.53.0

