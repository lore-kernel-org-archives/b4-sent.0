From: Xilin Wu <wuxilin123@gmail.com>
Date: Sun, 06 Aug 2023 01:03:10 +0800
Subject: [PATCH 1/3] soc: qcom: pmic_glink: enable UCSI for SM8350
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230806-xiaomi-star-v1-1-0c384e8b5737@gmail.com>
References: <20230806-xiaomi-star-v1-0-0c384e8b5737@gmail.com>
In-Reply-To: <20230806-xiaomi-star-v1-0-0c384e8b5737@gmail.com>
To: Andy Gross <agross@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konrad.dybcio@linaro.org>, Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, Kees Cook <keescook@chromium.org>, 
 Tony Luck <tony.luck@intel.com>, 
 "Guilherme G. Piccoli" <gpiccoli@igalia.com>
Cc: linux-arm-msm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-hardening@vger.kernel.org, 
 Xilin Wu <wuxilin123@gmail.com>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1691254992; l=945;
 i=wuxilin123@gmail.com; s=20230805; h=from:subject:message-id;
 bh=8u609EldV83Ng5xHetZEgLHYVtSc2Twgv9QEReU9uOo=;
 b=gsGA5YgCuKsodrhbBj9DozdJ3dezWB+wNSeHDs4vuXg/1iDz3If3T9MEGLjOYnONT98+zXGQu
 cucu8altUPYB7h5cnsfWqbahzyPamNH7oBbmO8wuJCUpSEpenxxxQQV
X-Developer-Key: i=wuxilin123@gmail.com; a=ed25519;
 pk=OZIrHT2qWm7yEdp5fsVR7GsFx1wxciIii20H06Ud088=
X-Endpoint-Received: by B4 Relay for wuxilin123@gmail.com/20230805 with auth_id=73
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

UCSI is supported on SM8350. Allow it to enable USB role switch and
altmode notifications on SM8350.

Signed-off-by: Xilin Wu <wuxilin123@gmail.com>
---
 drivers/soc/qcom/pmic_glink.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/soc/qcom/pmic_glink.c b/drivers/soc/qcom/pmic_glink.c
index c87056769ebd..0f8ac55ec2ac 100644
--- a/drivers/soc/qcom/pmic_glink.c
+++ b/drivers/soc/qcom/pmic_glink.c
@@ -347,6 +347,7 @@ static const unsigned long pmic_glink_sm8550_client_mask = BIT(PMIC_GLINK_CLIENT
 							   BIT(PMIC_GLINK_CLIENT_UCSI);
 
 static const struct of_device_id pmic_glink_of_match[] = {
+	{ .compatible = "qcom,sm8350-pmic-glink", .data = &pmic_glink_sm8450_client_mask },
 	{ .compatible = "qcom,sm8450-pmic-glink", .data = &pmic_glink_sm8450_client_mask },
 	{ .compatible = "qcom,sm8550-pmic-glink", .data = &pmic_glink_sm8550_client_mask },
 	{ .compatible = "qcom,pmic-glink" },

-- 
2.41.0

