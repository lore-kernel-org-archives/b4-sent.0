From: Hui Liu <quic_huliu@quicinc.com>
Date: Wed, 30 Aug 2023 11:00:56 +0800
Subject: [PATCH v4] usb: typec: qcom: Update the logic of regulator enable
 and disable
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230830-qcom-tcpc-v4-1-c19b0984879b@quicinc.com>
X-B4-Tracking: v=1; b=H4sIAOiw7mQC/2XMSw7CIBSF4a0YxmJ4VnDkPowDvIBlYB9Qiabp3
 qVNTDAOz839/hklF4NL6LSbUXQ5pNB3ZYj9DkFrurvDwZaNGGGcKMbwCP0DTzAAtoJqKQw00ht
 U/ofofHhtrcu17DakqY/vLZ3pev1WeFXJFFPsjaKGaDBENufxGSB0cCgvaO1kVltRW1Yst1YBF
 0zIRvxbXltVW16s0/J2NN5wYfWvXZblA0LHVyocAQAA
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1693364531; l=3183;
 i=quic_huliu@quicinc.com; s=20230823; h=from:subject:message-id;
 bh=sW9SVhPDWvfd2enRPcyusPbQVKd0LuSbX7srvMe6UZU=;
 b=NlMXLmyY7A12OZhYKX+dnlXgCU2fnjQ1/XWqZSXMkfPVV+1pK79/wMLzOMSHgEDWTdWVgnxys
 5Moangy4iymAgAr8/5/9RgPeVWVXHumrPRyQEK1/23K+XAoV8iD8jl5
X-Developer-Key: i=quic_huliu@quicinc.com; a=ed25519;
 pk=1z+A50UnTuKe/FdQv2c0W3ajDsJOYddwIHo2iivhTTA=
X-Endpoint-Received: by B4 Relay for quic_huliu@quicinc.com/20230823 with auth_id=80
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Removed the call logic of disable and enable regulator
in reset function. Enable the regulator in qcom_pmic_typec_start
function and disable it in qcom_pmic_typec_stop function to
avoid unbalanced regulator disable warnings.

Reviewed-by: Guenter Roeck <linux@roeck-us.net>
Fixes: a4422ff22142 ("usb: typec: qcom: Add Qualcomm PMIC Type-C driver")
Reviewed-by: Bryan O'Donoghue <bryan.odonoghue@linaro.org>
Acked-by: Bryan O'Donoghue <bryan.odonoghue@linaro.org>
Signed-off-by: Hui Liu <quic_huliu@quicinc.com>
---
Changes in v4:
- Removed regulator_enable and regulator_diable from
pmic_typec_pdphy_reset function. And enable regulator in
qcom_pmic_typec_pdphy_start function and disable it in
qcom_pmic_typec_pdphy_stop function.
- Link to v3: https://lore.kernel.org/r/20230828-qcom-tcpc-v3-1-e95b7afa34d9@quicinc.com

Changes in v3:
- Take Bryan's proposal to remove enable/disable operation in pdphy
enable and pdphy disable function, then enable regulator in pdphy start
function and disable it in pdphy stop function.
- Link to v2: https://lore.kernel.org/r/20230824-qcom-tcpc-v2-1-3dd8c3424564@quicinc.com

Changes in v2:
- Add Fixes tag
- Link to v1: https://lore.kernel.org/r/20230823-qcom-tcpc-v1-1-fa81a09ca056@quicinc.com
---
 drivers/usb/typec/tcpm/qcom/qcom_pmic_typec_pdphy.c | 12 ++++++------
 1 file changed, 6 insertions(+), 6 deletions(-)

diff --git a/drivers/usb/typec/tcpm/qcom/qcom_pmic_typec_pdphy.c b/drivers/usb/typec/tcpm/qcom/qcom_pmic_typec_pdphy.c
index bb0b8479d80f..52c81378e36e 100644
--- a/drivers/usb/typec/tcpm/qcom/qcom_pmic_typec_pdphy.c
+++ b/drivers/usb/typec/tcpm/qcom/qcom_pmic_typec_pdphy.c
@@ -381,10 +381,6 @@ static int qcom_pmic_typec_pdphy_enable(struct pmic_typec_pdphy *pmic_typec_pdph
 	struct device *dev = pmic_typec_pdphy->dev;
 	int ret;
 
-	ret = regulator_enable(pmic_typec_pdphy->vdd_pdphy);
-	if (ret)
-		return ret;
-
 	/* PD 2.0, DR=TYPEC_DEVICE, PR=TYPEC_SINK */
 	ret = regmap_update_bits(pmic_typec_pdphy->regmap,
 				 pmic_typec_pdphy->base + USB_PDPHY_MSG_CONFIG_REG,
@@ -422,8 +418,6 @@ static int qcom_pmic_typec_pdphy_disable(struct pmic_typec_pdphy *pmic_typec_pdp
 	ret = regmap_write(pmic_typec_pdphy->regmap,
 			   pmic_typec_pdphy->base + USB_PDPHY_EN_CONTROL_REG, 0);
 
-	regulator_disable(pmic_typec_pdphy->vdd_pdphy);
-
 	return ret;
 }
 
@@ -447,6 +441,10 @@ int qcom_pmic_typec_pdphy_start(struct pmic_typec_pdphy *pmic_typec_pdphy,
 	int i;
 	int ret;
 
+	ret = regulator_enable(pmic_typec_pdphy->vdd_pdphy);
+	if (ret)
+		return ret;
+
 	pmic_typec_pdphy->tcpm_port = tcpm_port;
 
 	ret = pmic_typec_pdphy_reset(pmic_typec_pdphy);
@@ -467,6 +465,8 @@ void qcom_pmic_typec_pdphy_stop(struct pmic_typec_pdphy *pmic_typec_pdphy)
 		disable_irq(pmic_typec_pdphy->irq_data[i].irq);
 
 	qcom_pmic_typec_pdphy_reset_on(pmic_typec_pdphy);
+
+	regulator_disable(pmic_typec_pdphy->vdd_pdphy);
 }
 
 struct pmic_typec_pdphy *qcom_pmic_typec_pdphy_alloc(struct device *dev)

---
base-commit: bbb9e06d2c6435af9c62074ad7048910eeb2e7bc
change-id: 20230822-qcom-tcpc-d41954ac65fa

Best regards,
-- 
Hui Liu <quic_huliu@quicinc.com>

