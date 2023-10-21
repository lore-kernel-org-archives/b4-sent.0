From: Xilin Wu <wuxilin123@gmail.com>
Date: Sat, 21 Oct 2023 18:20:38 +0800
Subject: [PATCH v2 1/3] soc: qcom: pmic_glink: enable UCSI for SM8350
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20231021-sakuramist-mi11u-v2-1-fa82c91ecaf0@gmail.com>
References: <20231021-sakuramist-mi11u-v2-0-fa82c91ecaf0@gmail.com>
In-Reply-To: <20231021-sakuramist-mi11u-v2-0-fa82c91ecaf0@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1697883643; l=945;
 i=wuxilin123@gmail.com; s=20231021; h=from:subject:message-id;
 bh=ww4sODm0ahT+SQ9wq+84FM3R6cXdq4VaDdGF3LcSqxc=;
 b=9NUeGZkuoPItLn4fyrpx4XrJvrcXMpd4BsFYrPVAAUj7PWqYPFYiCWgh+l17lpMxZ7JzkugDT
 oJr0daynNexCCixJcBv5+7MBXMyfmPSV+2PZdA/NE9T26aRt0N/9yq0
X-Developer-Key: i=wuxilin123@gmail.com; a=ed25519;
 pk=edoFbrGewAWr5/CxptHll7XzvXBjYiN49RrEgipi1Cg=
X-Endpoint-Received: by B4 Relay for wuxilin123@gmail.com/20231021 with auth_id=89
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

UCSI is supported on SM8350. Allow it to enable USB role switch and
altmode notifications on SM8350.

Signed-off-by: Xilin Wu <wuxilin123@gmail.com>
---
 drivers/soc/qcom/pmic_glink.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/soc/qcom/pmic_glink.c b/drivers/soc/qcom/pmic_glink.c
index 914057331afd..1196e79e6fb3 100644
--- a/drivers/soc/qcom/pmic_glink.c
+++ b/drivers/soc/qcom/pmic_glink.c
@@ -341,6 +341,7 @@ static const unsigned long pmic_glink_sm8450_client_mask = BIT(PMIC_GLINK_CLIENT
 							   BIT(PMIC_GLINK_CLIENT_UCSI);
 
 static const struct of_device_id pmic_glink_of_match[] = {
+	{ .compatible = "qcom,sm8350-pmic-glink", .data = &pmic_glink_sm8450_client_mask },
 	{ .compatible = "qcom,sm8450-pmic-glink", .data = &pmic_glink_sm8450_client_mask },
 	{ .compatible = "qcom,sm8550-pmic-glink", .data = &pmic_glink_sm8450_client_mask },
 	{ .compatible = "qcom,pmic-glink" },

-- 
2.42.0

