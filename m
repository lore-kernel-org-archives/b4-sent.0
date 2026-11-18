From: David Heidelberg <david@ixit.cz>
Date: Wed, 18 Nov 2026 18:25:35 +0100
Subject: [PATCH v2 02/12] regulator: qcom_usb_vbus: Add support for pmi8998
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261118-pmi8998-vbus-v2-2-3c77a72b280a@ixit.cz>
References: <20261118-pmi8998-vbus-v2-0-3c77a72b280a@ixit.cz>
In-Reply-To: <20261118-pmi8998-vbus-v2-0-3c77a72b280a@ixit.cz>
To: Alexey Minnekhanov <alexeymin@minlexx.ru>, 
 Robin Snyders <robin@snyders.xyz>, Liam Girdwood <lgirdwood@gmail.com>, 
 Mark Brown <broonie@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Wesley Cheng <quic_wcheng@quicinc.com>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Casey Connolly <casey.connolly@linaro.org>, 
 Sebastian Reichel <sre@kernel.org>
Cc: Richard Acayan <mailingradian@gmail.com>, linux-arm-msm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 Sebastian Reichel <sebastian.reichel@collabora.com>, 
 linux-pm@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2369; i=david@ixit.cz;
 h=from:subject:message-id; bh=9lTr2DbmYbgEO/XSdLxjtaeMnYcrX8YD7AeBwt1Utr4=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBq/d+WBuCgNZLjX8R/DFVgJW4axGbZ2NQXzr3SE
 L5zd9UP/qOJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCav3flgAKCRBgAj/E00kg
 cu/LD/9AVnXgyhWvoYjRuHuNp8P0mZvN1DKN42sr/v231fYrpwEUb78AqWl1OQX7tmXHDNl7LuL
 iFHUxI3rG8Mb38vPgNq5xvHq8vKpi2nGpvr9NVWtMK3Fk8BEFnB11fUNb3AiFqiaIfyZaFghdI4
 g65tZ3iZPKqck785sinmmAofaRaEb4FrSC0d9K5sV+Vy8tYKN1XbKDajyjrAztNMF/LJC8rXpub
 x7dr3i2SgfoKSiHHzqVwUb1Wt231aEdbIp1mto+kyXetkLPTG2lKMu0KvbpTDSHcfEZNyrPDMYf
 8rtv9gJYAG3aiD1rCQMO7gKL90Ub6FxH3s7uyzwrBI2Ov8OQpBfDUCvZB/3MgoTpxKpBPsFdLkc
 fF69t3DLFagQSIjmPh3B0SV+y3nEw+4EHxowfWawsP8wnHhYLSXU9mQjVLzi1pULii6yRbdbNEB
 Agtcwp7ueNJRK80t+nBkJLJi5obpg+cRbM3akDAw9MVvwVPf135um87j8d+jNr+hK9RGuCzdjcc
 jRUdK8Q1xQKhzrbiom/zGXKLUQyYNcMOx0W1629D5zMX6keq2quiECaKf16Vh0SLIxoXery+Ly9
 NpDm5Vk5IAeL9F0laWj36qeki/gR8fNmjjJrSXHu5/SRnhDqISFgfM4VQd1gAhwpD8YIfl0/w3x
 /Fst4K33dwqCgTA==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The PMI8998 uses different register layout, but due to the limited
functionality of the qcom_usb_vbus driver, the basic registers are the
same as the PM8150B, thus reuse these. For more advanced features it'll
differ.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/regulator/qcom_usb_vbus-regulator.c | 12 ++++++++++++
 1 file changed, 12 insertions(+)

diff --git a/drivers/regulator/qcom_usb_vbus-regulator.c b/drivers/regulator/qcom_usb_vbus-regulator.c
index 88f5a6ba79e6e..0617106a82cda 100644
--- a/drivers/regulator/qcom_usb_vbus-regulator.c
+++ b/drivers/regulator/qcom_usb_vbus-regulator.c
@@ -63,16 +63,27 @@ static const struct qcom_usb_vbus_reg_data pm8150b_data = {
 	.otg_en_src_cfg = OTG_EN_SRC_CFG,
 	.csel_reg = OTG_CURRENT_LIMIT_CFG,
 	.csel_mask = OTG_CURRENT_LIMIT_MASK,
 	.curr_table = curr_table,
 	.n_current_limits = ARRAY_SIZE(curr_table),
 	.ops = &qcom_usb_vbus_reg_ops,
 };
 
+static const struct qcom_usb_vbus_reg_data pmi8998_data = {
+	.cmd_otg = CMD_OTG,
+	.otg_cfg = OTG_CFG,
+	.otg_en_src_cfg = OTG_EN_SRC_CFG,
+	.csel_reg = OTG_CURRENT_LIMIT_CFG,
+	.csel_mask = OTG_CURRENT_LIMIT_MASK,
+	.curr_table = curr_table,
+	.n_current_limits = ARRAY_SIZE(curr_table),
+	.ops = &qcom_usb_vbus_reg_ops,
+};
+
 static const struct regulator_ops qcom_usb_vbus_pm4125_reg_ops = {
 	.enable = regulator_enable_regmap,
 	.disable = regulator_disable_regmap,
 	.is_enabled = regulator_is_enabled_regmap,
 	.get_voltage_sel = regulator_get_voltage_sel_regmap,
 	.set_voltage_sel = regulator_set_voltage_sel_regmap,
 	.list_voltage = regulator_list_voltage_table,
 };
@@ -161,16 +172,17 @@ static int qcom_usb_vbus_regulator_probe(struct platform_device *pdev)
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

