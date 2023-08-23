From: Hui Liu <quic_huliu@quicinc.com>
Date: Wed, 23 Aug 2023 17:15:53 +0800
Subject: [PATCH] usb: typec: qcom: check regulator enable status before
 disabling it
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230823-qcom-tcpc-v1-1-fa81a09ca056@quicinc.com>
X-B4-Tracking: v=1; b=H4sIAEnO5WQC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI2MDCyMj3cLk/FzdkuSCZN0UE0NLU5PEZDPTtEQloPqCotS0zAqwWdGxtbU
 AqbU6oVsAAAA=
To: Bryan O'Donoghue <bryan.odonoghue@linaro.org>, 
 Guenter Roeck <linux@roeck-us.net>, Andy Gross <agross@kernel.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konrad.dybcio@linaro.org>, 
 Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux-arm-msm@vger.kernel.org, linux-usb@vger.kernel.org, 
 linux-kernel@vger.kernel.org, quic_fenglinw@quicinc.com, 
 subbaram@quicinc.com, Hui Liu <quic_huliu@quicinc.com>
X-Mailer: b4 0.13-dev-83828
X-Developer-Signature: v=1; a=ed25519-sha256; t=1692782156; l=1109;
 i=quic_huliu@quicinc.com; s=20230823; h=from:subject:message-id;
 bh=Eq7q1VhxzBMiiLW046ihxgswENpgBh2pfv7VGXtEKDE=;
 b=7tSyma7eOKcwSWhtFR3YWbPboVUNtB1aFtgl+IJz8Z5x79QAvbVQgQRdLLt4yr2C5EQp28ApZ
 +uFnUcgg7SYADBTV3R07hBfaXnBJsVtbi3JZo7lHwWYqkzHNvz5R+5u
X-Developer-Key: i=quic_huliu@quicinc.com; a=ed25519;
 pk=1z+A50UnTuKe/FdQv2c0W3ajDsJOYddwIHo2iivhTTA=
X-Endpoint-Received: by B4 Relay for quic_huliu@quicinc.com/20230823 with auth_id=80
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Check regulator enable status before disabling it to avoid
unbalanced regulator disable warnings.

Signed-off-by: Hui Liu <quic_huliu@quicinc.com>
---
 drivers/usb/typec/tcpm/qcom/qcom_pmic_typec_pdphy.c | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/drivers/usb/typec/tcpm/qcom/qcom_pmic_typec_pdphy.c b/drivers/usb/typec/tcpm/qcom/qcom_pmic_typec_pdphy.c
index bb0b8479d80f..ca616b17b5b6 100644
--- a/drivers/usb/typec/tcpm/qcom/qcom_pmic_typec_pdphy.c
+++ b/drivers/usb/typec/tcpm/qcom/qcom_pmic_typec_pdphy.c
@@ -422,7 +422,8 @@ static int qcom_pmic_typec_pdphy_disable(struct pmic_typec_pdphy *pmic_typec_pdp
 	ret = regmap_write(pmic_typec_pdphy->regmap,
 			   pmic_typec_pdphy->base + USB_PDPHY_EN_CONTROL_REG, 0);
 
-	regulator_disable(pmic_typec_pdphy->vdd_pdphy);
+	if (regulator_is_enabled(pmic_typec_pdphy->vdd_pdphy))
+		regulator_disable(pmic_typec_pdphy->vdd_pdphy);
 
 	return ret;
 }

---
base-commit: bbb9e06d2c6435af9c62074ad7048910eeb2e7bc
change-id: 20230822-qcom-tcpc-d41954ac65fa

Best regards,
-- 
Hui Liu <quic_huliu@quicinc.com>

