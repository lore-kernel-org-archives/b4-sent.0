From: Esteban Urrutia <esteuwu@proton.me>
Date: Thu, 23 Jul 2026 10:53:53 -0400
Subject: [PATCH 2/2] regulator: qcom-rpmh: Add support for PM8350B
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260723-pm8350b-ldo-v1-2-42b5428a0d3f@proton.me>
References: <20260723-pm8350b-ldo-v1-0-42b5428a0d3f@proton.me>
In-Reply-To: <20260723-pm8350b-ldo-v1-0-42b5428a0d3f@proton.me>
To: Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>
Cc: Krzysztof Kozlowski <krzk@kernel.org>, linux-arm-msm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 phone-devel@vger.kernel.org, Esteban Urrutia <esteuwu@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784818498; l=1295;
 i=esteuwu@proton.me; s=20260622; h=from:subject:message-id;
 bh=WpvVHbr3AbWbUS/FGPBN8RtA2Y0Nr6DvrP+keHwhmM0=;
 b=ajbmyhj5jTzUeAPR+4eB5vPOg9F0Hk8ryp98ysevM7AolBSOvkKyxscMCBksotyWgCsF5fTd7
 eV2f7+Dp7ydAYWzcclbkX8U/PKxqSKnAyHGnCSyE3TZaJcvHOxAB+SH
X-Developer-Key: i=esteuwu@proton.me; a=ed25519;
 pk=wToFt4mOAWkzbqb15Ye1hrhevI13vK9BcMUFiQ/me1M=
X-Endpoint-Received: by B4 Relay for esteuwu@proton.me/20260622 with auth_id=835
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The PM8350B has only one LDO, which gets its power from a dedicated input.
Add support for it.

Signed-off-by: Esteban Urrutia <esteuwu@proton.me>
---
 drivers/regulator/qcom-rpmh-regulator.c | 9 +++++++++
 1 file changed, 9 insertions(+)

diff --git a/drivers/regulator/qcom-rpmh-regulator.c b/drivers/regulator/qcom-rpmh-regulator.c
index 756a4201225e..73856e3df337 100644
--- a/drivers/regulator/qcom-rpmh-regulator.c
+++ b/drivers/regulator/qcom-rpmh-regulator.c
@@ -1269,6 +1269,11 @@ static const struct rpmh_vreg_init_data pm8350_vreg_data[] = {
 	{}
 };
 
+static const struct rpmh_vreg_init_data pm8350b_vreg_data[] = {
+	RPMH_VREG("ldo1",   LDO,  1,  &pmic5_nldo,      "vdd-l1"),
+	{}
+};
+
 static const struct rpmh_vreg_init_data pm8350c_vreg_data[] = {
 	RPMH_VREG("smps1",  SMPS, 1,  &pmic5_hfsmps515, "vdd-s1"),
 	RPMH_VREG("smps2",  SMPS, 2,  &pmic5_ftsmps510, "vdd-s2"),
@@ -1868,6 +1873,10 @@ static const struct of_device_id __maybe_unused rpmh_regulator_match_table[] = {
 		.compatible = "qcom,pm8350-rpmh-regulators",
 		.data = pm8350_vreg_data,
 	},
+	{
+		.compatible = "qcom,pm8350b-rpmh-regulators",
+		.data = pm8350b_vreg_data,
+	},
 	{
 		.compatible = "qcom,pm8350c-rpmh-regulators",
 		.data = pm8350c_vreg_data,

-- 
2.55.0

