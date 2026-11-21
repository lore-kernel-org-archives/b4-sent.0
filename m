From: David Heidelberg <david@ixit.cz>
Date: Sat, 21 Nov 2026 23:37:57 +0100
Subject: [PATCH v3 03/12] regulator: qcom_usb_vbus: Add support for pmi8998
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261121-pmi8998-vbus-v3-3-91ba2e61a877@ixit.cz>
References: <20261121-pmi8998-vbus-v3-0-91ba2e61a877@ixit.cz>
In-Reply-To: <20261121-pmi8998-vbus-v3-0-91ba2e61a877@ixit.cz>
To: Abel Vesa <abelvesa@kernel.org>, 
 Alexey Minnekhanov <alexeymin@minlexx.ru>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Casey Connolly <casey.connolly@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, Konrad Dybcio <konradybcio@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Markus Rathgeb <maggu2810@mailbox.org>, Rob Herring <robh@kernel.org>, 
 Robin Snyders <robin@snyders.xyz>, Sebastian Reichel <sre@kernel.org>, 
 Wesley Cheng <quic_wcheng@quicinc.com>
Cc: Richard Acayan <mailingradian@gmail.com>, 
 Sebastian Reichel <sebastian.reichel@collabora.com>, 
 devicetree@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-pm@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=3260; i=david@ixit.cz;
 h=from:subject:message-id; bh=jayZyl15D6GUZYJTF3MT/rTVZn/RUZVLzfJX2rYw+gc=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBrAh1aliSo1w5taoGLSLOB/Azx4VQ3dp19WgANg
 Uiq32hpjFqJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCawIdWgAKCRBgAj/E00kg
 cjpdD/wIfR0BLZtexyfdulg6uenRDEQ9894sPX6meg2yqJJY0nin1o5/8Ro4XkkE0qTlLlE0gki
 yyoVIPn8g4P2YDRSaEppBZviBISiYNniffI3z6lWPHSx5KL740j9kM3iHcRQEUWsHeCyPM4sWt9
 HAiDxjrjGm94GvQ//sAEtyrG9ffgOSNoOUjrz2RgMZF3HOXzC9+gBMgetDkQKGAVmUafRTCG2J9
 FKeADwEWtqall0FVDFgkrN4haq7CMcwtnbYxDjVw0o9mlRetRyduE/mA15beL6JKPRdPJw9dt+Y
 50pBV+mH13c7psnd3m/6dkPPvlhpPB3DrHJeZqBzNPINiLSU0DNYfrfMrKjuycFLqgrWNQvrDBG
 rbGxQNtaA+icrJLDUuKtlQzBu51p6pebk9vOiLv/f9XtP7r52jGkdqSj3uW33i7MxrNAt/0Vvtm
 qsHf9tkTLnwpQhcGokpWD734MXkq7esOO5Q3+gsZZ5kXDsOs6yFiVCP5nawi7KeHiDimQFTt9mO
 MJykK/wGNlet7+HlNkFK3vu8nRVmhQUicGvi3cCIrSxyEcVsXFmoPbFR0YDVyrnz4D5WhXeEFVn
 U3l95MzWPuImv5eIVnurLXOd076EPuLJMeXt74CLrQB1738mqaVUksxZCa2bJIAmiQYm33VACox
 +ko/BsUwOveMiAw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The PMI8998 uses different register layout, but due to the limited
functionality of the qcom_usb_vbus driver, the basic registers are the
same as the PM8150B, thus reuse these. Table of currents differentiate
in steps and maximum 2A current. For more advanced features it'll differ.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/regulator/qcom_usb_vbus-regulator.c | 22 +++++++++++++++++++---
 1 file changed, 19 insertions(+), 3 deletions(-)

diff --git a/drivers/regulator/qcom_usb_vbus-regulator.c b/drivers/regulator/qcom_usb_vbus-regulator.c
index 88f5a6ba79e6e..61a1b45f36e84 100644
--- a/drivers/regulator/qcom_usb_vbus-regulator.c
+++ b/drivers/regulator/qcom_usb_vbus-regulator.c
@@ -36,17 +36,17 @@ struct qcom_usb_vbus_reg_data {
 	unsigned int n_current_limits;
 	u16 vsel_reg;
 	u8 vsel_mask;
 	const unsigned int *volt_table;
 	unsigned int n_voltages;
 	const struct regulator_ops *ops;
 };
 
-static const unsigned int curr_table[] = {
+static const unsigned int pm8150b_curr_table[] = {
 	500000, 1000000, 1500000, 2000000, 2500000, 3000000,
 };
 
 static const unsigned int pm4125_vboost_table[] = {
 	4250000, 4500000, 4750000, 5000000,
 };
 
 static const struct regulator_ops qcom_usb_vbus_reg_ops = {
@@ -58,18 +58,33 @@ static const struct regulator_ops qcom_usb_vbus_reg_ops = {
 };
 
 static const struct qcom_usb_vbus_reg_data pm8150b_data = {
 	.cmd_otg = CMD_OTG,
 	.otg_cfg = OTG_CFG,
 	.otg_en_src_cfg = OTG_EN_SRC_CFG,
 	.csel_reg = OTG_CURRENT_LIMIT_CFG,
 	.csel_mask = OTG_CURRENT_LIMIT_MASK,
-	.curr_table = curr_table,
-	.n_current_limits = ARRAY_SIZE(curr_table),
+	.curr_table = pm8150b_curr_table,
+	.n_current_limits = ARRAY_SIZE(pm8150b_curr_table),
+	.ops = &qcom_usb_vbus_reg_ops,
+};
+
+static const unsigned int pmi8998_curr_table[] = {
+	250000, 500000, 750000, 1000000, 1250000, 1500000, 1750000, 2000000,
+};
+
+static const struct qcom_usb_vbus_reg_data pmi8998_data = {
+	.cmd_otg = CMD_OTG,
+	.otg_cfg = OTG_CFG,
+	.otg_en_src_cfg = OTG_EN_SRC_CFG,
+	.csel_reg = OTG_CURRENT_LIMIT_CFG,
+	.csel_mask = OTG_CURRENT_LIMIT_MASK,
+	.curr_table = pmi8998_curr_table,
+	.n_current_limits = ARRAY_SIZE(pmi8998_curr_table),
 	.ops = &qcom_usb_vbus_reg_ops,
 };
 
 static const struct regulator_ops qcom_usb_vbus_pm4125_reg_ops = {
 	.enable = regulator_enable_regmap,
 	.disable = regulator_disable_regmap,
 	.is_enabled = regulator_is_enabled_regmap,
 	.get_voltage_sel = regulator_get_voltage_sel_regmap,
@@ -161,16 +176,17 @@ static int qcom_usb_vbus_regulator_probe(struct platform_device *pdev)
 	regmap_update_bits(regmap, base + data->otg_cfg, data->otg_en_src_cfg, 0);
 
 	return 0;
 }
 
 static const struct of_device_id qcom_usb_vbus_regulator_match[] = {
 	{ .compatible = "qcom,pm8150b-vbus-reg", .data = &pm8150b_data },
 	{ .compatible = "qcom,pm4125-vbus-reg",  .data = &pm4125_data },
+	{ .compatible = "qcom,pmi8998-vbus-reg", .data = &pmi8998_data },
 	{ }
 };
 MODULE_DEVICE_TABLE(of, qcom_usb_vbus_regulator_match);
 
 static struct platform_driver qcom_usb_vbus_regulator_driver = {
 	.driver		= {
 		.name	= "qcom-usb-vbus-regulator",
 		.probe_type = PROBE_PREFER_ASYNCHRONOUS,

-- 
2.55.0

