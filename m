From: David Heidelberg <david@ixit.cz>
Date: Sun, 30 Aug 2026 00:23:26 +0200
Subject: [PATCH 3/4] power: regulator: qcom-rpmh: add PM8998 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260830-b4-sdm845-usb-gadget-v1-3-9f20e842d628@ixit.cz>
References: <20260830-b4-sdm845-usb-gadget-v1-0-9f20e842d628@ixit.cz>
In-Reply-To: <20260830-b4-sdm845-usb-gadget-v1-0-9f20e842d628@ixit.cz>
To: Sumit Garg <sumit.garg@kernel.org>, u-boot-qcom@groups.io, 
 u-boot@lists.denx.de
Cc: Casey Connolly <casey.connolly@linaro.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, Tom Rini <trini@konsulko.com>, 
 David Heidelberg <david@ixit.cz>, 
 Varadarajan Narayanan <varadarajan.narayanan@oss.qualcomm.com>, 
 Balaji Selvanathan <balaji.selvanathan@oss.qualcomm.com>, 
 Jaehoon Chung <jh80.chung@samsung.com>, Peng Fan <peng.fan@nxp.com>, 
 Luca Weiss <luca.weiss@fairphone.com>, 
 Aswin Murugan <aswin.murugan@oss.qualcomm.com>, 
 Federico Amedeo Izzo <federico@izzo.pro>, 
 Marek Vasut <marek.vasut+renesas@mailbox.org>, 
 Quentin Schulz <quentin.schulz@cherry.de>, phone-devel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=8607; i=david@ixit.cz;
 h=from:subject:message-id; bh=FJOGHauH25p6RoTou6Xp22u9LMqLrDnD4kTM7ElXUqE=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqk1vdtsI1ZLmD60+oeI2wu1CP1R5rzl+nLbAJJ
 ZMWMqxEHQOJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCapNb3QAKCRBgAj/E00kg
 cl94D/4lF7kXgJdLUMcbaqTJfx7xkJb+w//di3P9cLaDbCbQvuPTtmIAWLmRonkpu+gMThJPnSl
 xNmAWZpre5KnTa5DFqKFBBW1siXNJhAPMcC+wVG8NTrIwlAsAJFSPtmy4dP0Brs0OK6i44CVRac
 9SwcWxzoA3TZvQ34bPSyqIOFXWIn+2jlHHVQ+SyLNVQa1YntKin8ioudi0iRBpgIrBOmnReNSlM
 yeSnXYD2wBYFHKT/G/9bVErK2iUGCwP7j+AcLjM6ZZlafsFLE2uAUv50nsY5erAmaLIHuKYcoX0
 BXJaPR6MByIP6g8jtR8V+D5RpYTz0FiC6j1BHtkfSuZE0sJ36ZesA5KtVD5QM5MEkR6tOYbNL7x
 rbWT+IHPp8umHtS0FEg+7sazi+ky2rbITwoGEvShoVBIQwRmpzQJDTMrToLuXH5koTF2zImLasp
 0ybhiwehsWA0yH9G0nX6MGQ0czJ3SjdSFiJ0FFTMJc8pMweM1OHFB9esmziH7pqxyUJqR7fjVJN
 cBLwjO2eIRuvx2oBExrHO1EaiMAt4sdUnrzTB9jzqOJhozCY1oLmjFofGlzb8nnck/0uiJCkI0n
 w3ZNmr4oeXE6JXW/LQ10DbRNZhUQFk/GLTW1VmV7empE5509dfuKK+uNT3YJaJGPSwAH3RU8amY
 bkRM7Vs68rlPgPQ==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

PM8998 is the primary PMIC on SDM845 boards, but the driver only knows
about PMIC5 based parts, so "qcom,pm8998-rpmh-regulators" is never
matched and none of its regulators are bound. Consumers then fail to
acquire their supplies, for example on Google Pixel 3:

  phy@88e8000: failed to get regulator vdda-phy-supply: -19
  Failed to get PHY1 for usb@a600000

Add the PMIC4 mode maps and regulator types, import the PM8998
regulator list from Linux and match on the compatible.

The LVS regulators are left out: they are XOB type and this driver
only implements the VRM accelerator.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/power/regulator/qcom-rpmh-regulator.c | 137 ++++++++++++++++++++++++++
 1 file changed, 137 insertions(+)

diff --git a/drivers/power/regulator/qcom-rpmh-regulator.c b/drivers/power/regulator/qcom-rpmh-regulator.c
index f789b5b6f86..0d68c8fc305 100644
--- a/drivers/power/regulator/qcom-rpmh-regulator.c
+++ b/drivers/power/regulator/qcom-rpmh-regulator.c
@@ -478,16 +478,100 @@ static struct dm_regulator_mode pmic_mode_map_pmic5_smps[] = {
 		.name = "PMIC5_SMPS_MODE_AUTO"
 	}, {
 		.id = REGULATOR_MODE_HPM,
 		.register_value = PMIC5_SMPS_MODE_PWM,
 		.name = "PMIC5_SMPS_MODE_PWM"
 	},
 };
 
+static struct dm_regulator_mode pmic_mode_map_pmic4_ldo[] = {
+	{
+		.id = REGULATOR_MODE_RETENTION,
+		.register_value = PMIC4_LDO_MODE_RETENTION,
+		.name = "PMIC4_LDO_MODE_RETENTION"
+	}, {
+		.id = REGULATOR_MODE_LPM,
+		.register_value = PMIC4_LDO_MODE_LPM,
+		.name = "PMIC4_LDO_MODE_LPM"
+	}, {
+		.id = REGULATOR_MODE_HPM,
+		.register_value = PMIC4_LDO_MODE_HPM,
+		.name = "PMIC4_LDO_MODE_HPM"
+	},
+};
+
+static struct dm_regulator_mode pmic_mode_map_pmic4_smps[] = {
+	{
+		.id = REGULATOR_MODE_RETENTION,
+		.register_value = PMIC4_SMPS_MODE_RETENTION,
+		.name = "PMIC4_SMPS_MODE_RETENTION"
+	}, {
+		.id = REGULATOR_MODE_LPM,
+		.register_value = PMIC4_SMPS_MODE_PFM,
+		.name = "PMIC4_SMPS_MODE_PFM"
+	}, {
+		.id = REGULATOR_MODE_AUTO,
+		.register_value = PMIC4_SMPS_MODE_AUTO,
+		.name = "PMIC4_SMPS_MODE_AUTO"
+	}, {
+		.id = REGULATOR_MODE_HPM,
+		.register_value = PMIC4_SMPS_MODE_PWM,
+		.name = "PMIC4_SMPS_MODE_PWM"
+	},
+};
+
+static const struct rpmh_vreg_hw_data pmic4_pldo = {
+	.regulator_type = VRM,
+	.ops = &rpmh_regulator_vrm_drms_ops,
+	.voltage_range = REGULATOR_LINEAR_RANGE(1664000, 0, 255, 8000),
+	.n_voltages = 256,
+	.hpm_min_load_uA = 10000,
+	.pmic_mode_map = pmic_mode_map_pmic4_ldo,
+	.n_modes = ARRAY_SIZE(pmic_mode_map_pmic4_ldo),
+};
+
+static const struct rpmh_vreg_hw_data pmic4_pldo_lv = {
+	.regulator_type = VRM,
+	.ops = &rpmh_regulator_vrm_drms_ops,
+	.voltage_range = REGULATOR_LINEAR_RANGE(1256000, 0, 127, 8000),
+	.n_voltages = 128,
+	.hpm_min_load_uA = 10000,
+	.pmic_mode_map = pmic_mode_map_pmic4_ldo,
+	.n_modes = ARRAY_SIZE(pmic_mode_map_pmic4_ldo),
+};
+
+static const struct rpmh_vreg_hw_data pmic4_nldo = {
+	.regulator_type = VRM,
+	.ops = &rpmh_regulator_vrm_drms_ops,
+	.voltage_range = REGULATOR_LINEAR_RANGE(312000, 0, 127, 8000),
+	.n_voltages = 128,
+	.hpm_min_load_uA = 30000,
+	.pmic_mode_map = pmic_mode_map_pmic4_ldo,
+	.n_modes = ARRAY_SIZE(pmic_mode_map_pmic4_ldo),
+};
+
+static const struct rpmh_vreg_hw_data pmic4_hfsmps3 = {
+	.regulator_type = VRM,
+	.ops = &rpmh_regulator_vrm_drms_ops,
+	.voltage_range = REGULATOR_LINEAR_RANGE(320000, 0, 215, 8000),
+	.n_voltages = 216,
+	.pmic_mode_map = pmic_mode_map_pmic4_smps,
+	.n_modes = ARRAY_SIZE(pmic_mode_map_pmic4_smps),
+};
+
+static const struct rpmh_vreg_hw_data pmic4_ftsmps426 = {
+	.regulator_type = VRM,
+	.ops = &rpmh_regulator_vrm_drms_ops,
+	.voltage_range = REGULATOR_LINEAR_RANGE(320000, 0, 258, 4000),
+	.n_voltages = 259,
+	.pmic_mode_map = pmic_mode_map_pmic4_smps,
+	.n_modes = ARRAY_SIZE(pmic_mode_map_pmic4_smps),
+};
+
 static const struct rpmh_vreg_hw_data pmic5_bob = {
 	.regulator_type = VRM,
 	.ops = &rpmh_regulator_vrm_drms_ops,
 	.voltage_range = REGULATOR_LINEAR_RANGE(3000000, 0, 31, 32000),
 	.n_voltages = 32,
 	.pmic_mode_map = pmic_mode_map_pmic5_bob,
 	.n_modes = ARRAY_SIZE(pmic_mode_map_pmic5_bob),
 };
@@ -624,16 +708,65 @@ static const struct rpmh_vreg_hw_data pmic5_pldo515_mv = {
 #define RPMH_VREG(_name, _resource_name, _hw_data, _supply_name) \
 { \
 	.name		= _name, \
 	.resource_name	= _resource_name, \
 	.hw_data	= _hw_data, \
 	.supply_name	= _supply_name, \
 }
 
+/*
+ * LVS regulators are omitted: they are XOB type and this driver only
+ * implements the VRM accelerator.
+ */
+static const struct rpmh_vreg_init_data pm8998_vreg_data[] = {
+	RPMH_VREG("smps1",  "smp%s1",  &pmic4_ftsmps426, "vdd-s1"),
+	RPMH_VREG("smps2",  "smp%s2",  &pmic4_ftsmps426, "vdd-s2"),
+	RPMH_VREG("smps3",  "smp%s3",  &pmic4_hfsmps3,   "vdd-s3"),
+	RPMH_VREG("smps4",  "smp%s4",  &pmic4_hfsmps3,   "vdd-s4"),
+	RPMH_VREG("smps5",  "smp%s5",  &pmic4_hfsmps3,   "vdd-s5"),
+	RPMH_VREG("smps6",  "smp%s6",  &pmic4_ftsmps426, "vdd-s6"),
+	RPMH_VREG("smps7",  "smp%s7",  &pmic4_ftsmps426, "vdd-s7"),
+	RPMH_VREG("smps8",  "smp%s8",  &pmic4_ftsmps426, "vdd-s8"),
+	RPMH_VREG("smps9",  "smp%s9",  &pmic4_ftsmps426, "vdd-s9"),
+	RPMH_VREG("smps10", "smp%s10", &pmic4_ftsmps426, "vdd-s10"),
+	RPMH_VREG("smps11", "smp%s11", &pmic4_ftsmps426, "vdd-s11"),
+	RPMH_VREG("smps12", "smp%s12", &pmic4_ftsmps426, "vdd-s12"),
+	RPMH_VREG("smps13", "smp%s13", &pmic4_ftsmps426, "vdd-s13"),
+	RPMH_VREG("ldo1",   "ldo%s1",  &pmic4_nldo,      "vdd-l1-l27"),
+	RPMH_VREG("ldo2",   "ldo%s2",  &pmic4_nldo,      "vdd-l2-l8-l17"),
+	RPMH_VREG("ldo3",   "ldo%s3",  &pmic4_nldo,      "vdd-l3-l11"),
+	RPMH_VREG("ldo4",   "ldo%s4",  &pmic4_nldo,      "vdd-l4-l5"),
+	RPMH_VREG("ldo5",   "ldo%s5",  &pmic4_nldo,      "vdd-l4-l5"),
+	RPMH_VREG("ldo6",   "ldo%s6",  &pmic4_pldo,      "vdd-l6"),
+	RPMH_VREG("ldo7",   "ldo%s7",  &pmic4_pldo_lv,   "vdd-l7-l12-l14-l15"),
+	RPMH_VREG("ldo8",   "ldo%s8",  &pmic4_nldo,      "vdd-l2-l8-l17"),
+	RPMH_VREG("ldo9",   "ldo%s9",  &pmic4_pldo,      "vdd-l9"),
+	RPMH_VREG("ldo10",  "ldo%s10", &pmic4_pldo,      "vdd-l10-l23-l25"),
+	RPMH_VREG("ldo11",  "ldo%s11", &pmic4_nldo,      "vdd-l3-l11"),
+	RPMH_VREG("ldo12",  "ldo%s12", &pmic4_pldo_lv,   "vdd-l7-l12-l14-l15"),
+	RPMH_VREG("ldo13",  "ldo%s13", &pmic4_pldo,      "vdd-l13-l19-l21"),
+	RPMH_VREG("ldo14",  "ldo%s14", &pmic4_pldo_lv,   "vdd-l7-l12-l14-l15"),
+	RPMH_VREG("ldo15",  "ldo%s15", &pmic4_pldo_lv,   "vdd-l7-l12-l14-l15"),
+	RPMH_VREG("ldo16",  "ldo%s16", &pmic4_pldo,      "vdd-l16-l28"),
+	RPMH_VREG("ldo17",  "ldo%s17", &pmic4_nldo,      "vdd-l2-l8-l17"),
+	RPMH_VREG("ldo18",  "ldo%s18", &pmic4_pldo,      "vdd-l18-l22"),
+	RPMH_VREG("ldo19",  "ldo%s19", &pmic4_pldo,      "vdd-l13-l19-l21"),
+	RPMH_VREG("ldo20",  "ldo%s20", &pmic4_pldo,      "vdd-l20-l24"),
+	RPMH_VREG("ldo21",  "ldo%s21", &pmic4_pldo,      "vdd-l13-l19-l21"),
+	RPMH_VREG("ldo22",  "ldo%s22", &pmic4_pldo,      "vdd-l18-l22"),
+	RPMH_VREG("ldo23",  "ldo%s23", &pmic4_pldo,      "vdd-l10-l23-l25"),
+	RPMH_VREG("ldo24",  "ldo%s24", &pmic4_pldo,      "vdd-l20-l24"),
+	RPMH_VREG("ldo25",  "ldo%s25", &pmic4_pldo,      "vdd-l10-l23-l25"),
+	RPMH_VREG("ldo26",  "ldo%s26", &pmic4_nldo,      "vdd-l26"),
+	RPMH_VREG("ldo27",  "ldo%s27", &pmic4_nldo,      "vdd-l1-l27"),
+	RPMH_VREG("ldo28",  "ldo%s28", &pmic4_pldo,      "vdd-l16-l28"),
+	{}
+};
+
 static const struct rpmh_vreg_init_data pm6150l_vreg_data[] = {
 	/* smps1 - smps8 are not added to u-boot yet */
 	RPMH_VREG("ldo1",   "ldo%s1",  &pmic5_pldo_lv,   "vdd-l1-l8"),
 	RPMH_VREG("ldo2",   "ldo%s2",  &pmic5_nldo,      "vdd-l2-l3"),
 	RPMH_VREG("ldo3",   "ldo%s3",  &pmic5_nldo,      "vdd-l2-l3"),
 	RPMH_VREG("ldo4",   "ldo%s4",  &pmic5_pldo,      "vdd-l4-l5-l6"),
 	RPMH_VREG("ldo5",   "ldo%s5",  &pmic5_pldo,      "vdd-l4-l5-l6"),
 	RPMH_VREG("ldo6",   "ldo%s6",  &pmic5_pldo,      "vdd-l4-l5-l6"),
@@ -1004,16 +1137,20 @@ static const struct udevice_id rpmh_regulator_ids[] = {
 	{
 		.compatible = "qcom,pm8550ve-rpmh-regulators",
 		.data = (ulong)pm8550ve_vreg_data,
 	},
 	{
 		.compatible = "qcom,pm8550vs-rpmh-regulators",
 		.data = (ulong)pm8550vs_vreg_data,
 	},
+	{
+		.compatible = "qcom,pm8998-rpmh-regulators",
+		.data = (ulong)pm8998_vreg_data,
+	},
 	{
 		.compatible = "qcom,pmc8380-rpmh-regulators",
 		.data = (ulong)pmc8380_vreg_data,
 	},
 	{
 		.compatible = "qcom,pmm8654au-rpmh-regulators",
 		.data = (ulong)pmm8654au_vreg_data,
 	},

-- 
2.55.0

