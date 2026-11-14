From: Demeter Barna <me@fromdisposition.org>
Date: Sat, 14 Nov 2026 02:22:01 +0000
Subject: [PATCH 7/9] power: regulator: qcom-rpmh: add PM8350 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261114-sm8350-support-v1-7-414271f59474@fromdisposition.org>
References: <20261114-sm8350-support-v1-0-414271f59474@fromdisposition.org>
In-Reply-To: <20261114-sm8350-support-v1-0-414271f59474@fromdisposition.org>
To: Sumit Garg <sumit.garg@kernel.org>, u-boot@lists.u-boot-project.org, 
 u-boot-qcom@groups.io
Cc: Tom Rini <trini@konsulko.com>, Lukasz Majewski <lukma@nabladev.com>, 
 Casey Connolly <casey.connolly@linaro.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Balaji Selvanathan <balaji.selvanathan@oss.qualcomm.com>, 
 Biswapriyo Nath <nathbappai@gmail.com>, 
 Vitalii Skorkin <nikroks@mainlining.org>, 
 Erikas Bitovtas <xerikasxx@gmail.com>, Johan Jonker <jbx6244@gmail.com>, 
 Petr Hodina <petr.hodina@protonmail.com>, 
 Marek Vasut <marek.vasut+renesas@mailbox.org>, 
 Jaehoon Chung <jh80.chung@samsung.com>, Peng Fan <peng.fan@nxp.com>, 
 Federico Amedeo Izzo <federico@izzo.pro>, 
 Michael Srba <Michael.Srba@seznam.cz>, 
 Quentin Schulz <quentin.schulz@cherry.de>, 
 Demeter Barna <me@fromdisposition.org>, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794622936; l=2719;
 i=me@fromdisposition.org; s=20261012; h=from:subject:message-id;
 bh=o11xhMMmB6mY8IarG7lDrkstn2uZB0UMxBV6J8TEYg4=;
 b=1YkwQ8/uoRfnnTHNvdHkrM15nqWeUrKT3BNZyzHpoGqFGSwRTan9pKnMo7LImvUpKJloBogil
 y6dlHDJ2Aa9AG6zFsK7IPNR7IKpBfacBsjDGpWgGqIJG/sW3SZs1cxB
X-Developer-Key: i=me@fromdisposition.org; a=ed25519;
 pk=S0QFlGq1BQEaAtPPdAH8YKEOXMeRuSkTgctXuvtU+1Y=
X-Endpoint-Received: by B4 Relay for me@fromdisposition.org/20261012 with auth_id=1163
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Import the PM8350 regulator list from Linux (tag v7.4-rc1). On SM8350
boards it supplies UFS and its PHY.

Signed-off-by: Demeter Barna <me@fromdisposition.org>
---
 drivers/power/regulator/qcom-rpmh-regulator.c | 30 +++++++++++++++++++++++++++
 1 file changed, 30 insertions(+)

diff --git a/drivers/power/regulator/qcom-rpmh-regulator.c b/drivers/power/regulator/qcom-rpmh-regulator.c
index 5e899ebc20..28c0687f1c 100644
--- a/drivers/power/regulator/qcom-rpmh-regulator.c
+++ b/drivers/power/regulator/qcom-rpmh-regulator.c
@@ -964,6 +964,32 @@ static const struct rpmh_vreg_init_data pmm8654au_vreg_data[] = {
 	{}
 };
 
+static const struct rpmh_vreg_init_data pm8350_vreg_data[] = {
+	RPMH_VREG("smps1",  "smp%s1",  &pmic5_ftsmps510, "vdd-s1"),
+	RPMH_VREG("smps2",  "smp%s2",  &pmic5_ftsmps510, "vdd-s2"),
+	RPMH_VREG("smps3",  "smp%s3",  &pmic5_ftsmps510, "vdd-s3"),
+	RPMH_VREG("smps4",  "smp%s4",  &pmic5_ftsmps510, "vdd-s4"),
+	RPMH_VREG("smps5",  "smp%s5",  &pmic5_ftsmps510, "vdd-s5"),
+	RPMH_VREG("smps6",  "smp%s6",  &pmic5_ftsmps510, "vdd-s6"),
+	RPMH_VREG("smps7",  "smp%s7",  &pmic5_ftsmps510, "vdd-s7"),
+	RPMH_VREG("smps8",  "smp%s8",  &pmic5_ftsmps510, "vdd-s8"),
+	RPMH_VREG("smps9",  "smp%s9",  &pmic5_ftsmps510, "vdd-s9"),
+	RPMH_VREG("smps10", "smp%s10", &pmic5_hfsmps510, "vdd-s10"),
+	RPMH_VREG("smps11", "smp%s11", &pmic5_hfsmps510, "vdd-s11"),
+	RPMH_VREG("smps12", "smp%s12", &pmic5_hfsmps510, "vdd-s12"),
+	RPMH_VREG("ldo1",   "ldo%s1",  &pmic5_nldo,      "vdd-l1-l4"),
+	RPMH_VREG("ldo2",   "ldo%s2",  &pmic5_pldo,      "vdd-l2-l7"),
+	RPMH_VREG("ldo3",   "ldo%s3",  &pmic5_nldo,      "vdd-l3-l5"),
+	RPMH_VREG("ldo4",   "ldo%s4",  &pmic5_nldo,      "vdd-l1-l4"),
+	RPMH_VREG("ldo5",   "ldo%s5",  &pmic5_nldo,      "vdd-l3-l5"),
+	RPMH_VREG("ldo6",   "ldo%s6",  &pmic5_nldo,      "vdd-l6-l9-l10"),
+	RPMH_VREG("ldo7",   "ldo%s7",  &pmic5_pldo,      "vdd-l2-l7"),
+	RPMH_VREG("ldo8",   "ldo%s8",  &pmic5_nldo,      "vdd-l8"),
+	RPMH_VREG("ldo9",   "ldo%s9",  &pmic5_nldo,      "vdd-l6-l9-l10"),
+	RPMH_VREG("ldo10",  "ldo%s10", &pmic5_nldo,      "vdd-l6-l9-l10"),
+	{}
+};
+
 static const struct rpmh_vreg_init_data pm8350c_vreg_data[] = {
 	RPMH_VREG("smps1",  "smp%s1",  &pmic5_hfsmps515, "vdd-s1"),
 	RPMH_VREG("smps2",  "smp%s2",  &pmic5_ftsmps510, "vdd-s2"),
@@ -1158,6 +1184,10 @@ static const struct udevice_id rpmh_regulator_ids[] = {
 		.compatible = "qcom,pm8150l-rpmh-regulators",
 		.data = (ulong)pm8150l_vreg_data,
 	},
+	{
+		.compatible = "qcom,pm8350-rpmh-regulators",
+		.data = (ulong)pm8350_vreg_data,
+	},
 	{
 		.compatible = "qcom,pm8350c-rpmh-regulators",
 		.data = (ulong)pm8350c_vreg_data,

-- 
2.53.0

