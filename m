From: Federico Amedeo Izzo <federico@izzo.pro>
Date: Sat, 23 May 2026 15:04:24 +0200
Subject: [PATCH v4 1/2] regulator: qcom-rpmh-regulator: fix regulator mode
 mismatch
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260523-qcom-ufs-regulator-support-v4-1-45639533b06d@izzo.pro>
References: <20260523-qcom-ufs-regulator-support-v4-0-45639533b06d@izzo.pro>
In-Reply-To: <20260523-qcom-ufs-regulator-support-v4-0-45639533b06d@izzo.pro>
To: Sumit Garg <sumit.garg@kernel.org>, u-boot-qcom@groups.io, 
 u-boot@lists.denx.de
Cc: Neil Armstrong <neil.armstrong@linaro.org>, 
 Bhupesh Sharma <bhupesh.linux@gmail.com>, 
 Neha Malcom Francis <n-francis@ti.com>, 
 Casey Connolly <casey.connolly@linaro.org>, Tom Rini <trini@konsulko.com>, 
 Marek Vasut <marek.vasut+renesas@mailbox.org>, 
 Federico Amedeo Izzo <federico@izzo.pro>, 
 Julien Stephan <jstephan@baylibre.com>, 
 Jaehoon Chung <jh80.chung@samsung.com>, Peng Fan <peng.fan@nxp.com>, 
 Luca Weiss <luca.weiss@fairphone.com>, 
 Aswin Murugan <aswin.murugan@oss.qualcomm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779541471; l=4160;
 i=federico@izzo.pro; s=20251017; h=from:subject:message-id;
 bh=gIA86klRMSfHRKLYFrFp1T+qxtIMBgdBtmC5m0tq2AE=;
 b=1qGgd4Gw7UcodrxhQP+CDV1WCTEy7QAKjpEDxhDapR8Aa+cPoTn8oEcoQ0KOXFiaqGfbO5gIL
 qYBchOfjyffCLuv/ICrHsmiYQPZAQBlcKAflDwk3+vJOk0niaQBSAjS
X-Developer-Key: i=federico@izzo.pro; a=ed25519;
 pk=XfmNfpH48k8jLbId5NKrp0yoKoFb/uLjr97qIxBImBw=
X-Endpoint-Received: by B4 Relay for federico@izzo.pro/20251017 with auth_id=544
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Initial regulator mode was read from dts but never applied.
This caused a mismatch between saved mode and actual regulator mode.

Apply the current mode from priv->mode during enable() and move
rpmh_regulator_vrm_set_mode function before rpmh_regulator_set_enable_state().

Signed-off-by: Federico Amedeo Izzo <federico@izzo.pro>
---
 drivers/power/regulator/qcom-rpmh-regulator.c | 106 ++++++++++++++------------
 1 file changed, 56 insertions(+), 50 deletions(-)

diff --git a/drivers/power/regulator/qcom-rpmh-regulator.c b/drivers/power/regulator/qcom-rpmh-regulator.c
index 4d65aae1690..f789b5b6f86 100644
--- a/drivers/power/regulator/qcom-rpmh-regulator.c
+++ b/drivers/power/regulator/qcom-rpmh-regulator.c
@@ -295,6 +295,56 @@ static int rpmh_regulator_vrm_get_value(struct udevice *rdev)
 	return vreg->uv;
 }
 
+static int rpmh_regulator_vrm_set_mode_bypass(struct rpmh_vreg *vreg,
+					      unsigned int mode, bool bypassed)
+{
+	struct tcs_cmd cmd = {
+		.addr = vreg->addr + RPMH_REGULATOR_REG_VRM_MODE,
+	};
+	struct dm_regulator_mode *pmic_mode;
+	int i;
+
+	if (mode > REGULATOR_MODE_HPM)
+		return -EINVAL;
+
+	for (i = 0; i < vreg->hw_data->n_modes; i++) {
+		pmic_mode = &vreg->hw_data->pmic_mode_map[i];
+		if (pmic_mode->id == mode)
+			break;
+	}
+	if (pmic_mode->id != mode) {
+		printf("Invalid mode %d\n", mode);
+		return -EINVAL;
+	}
+
+	if (bypassed)
+		// XXX: should have a version check for PMIC4 but we don't have any yet
+		// and we don't use bypass mode
+		cmd.data = PMIC5_BOB_MODE_PASS;
+	else
+		cmd.data = pmic_mode->register_value;
+
+	return rpmh_regulator_send_request(vreg, &cmd, true);
+}
+
+static int rpmh_regulator_vrm_set_mode(struct udevice *rdev,
+				       int mode)
+{
+	struct rpmh_vreg *vreg = dev_get_priv(rdev);
+	int ret;
+
+	debug("%s: set_mode %d (current %d)\n", rdev->name, mode, vreg->mode);
+
+	if (mode == vreg->mode)
+		return 0;
+
+	ret = rpmh_regulator_vrm_set_mode_bypass(vreg, mode, vreg->bypassed);
+	if (!ret)
+		vreg->mode = mode;
+
+	return ret;
+}
+
 static int rpmh_regulator_is_enabled(struct udevice *rdev)
 {
 	struct rpmh_vreg *vreg = dev_get_priv(rdev);
@@ -331,6 +381,12 @@ static int rpmh_regulator_set_enable_state(struct udevice *rdev,
 	debug("%s: set_enable %d (current %d)\n", rdev->name, enable,
 	      vreg->enabled);
 
+	if (vreg->mode != -EINVAL) {
+		ret = rpmh_regulator_vrm_set_mode_bypass(vreg, vreg->mode, vreg->bypassed);
+		if (ret < 0)
+			return ret;
+	}
+
 	if (vreg->enabled == -EINVAL &&
 	    vreg->uv != -ENOTRECOVERABLE) {
 		ret = _rpmh_regulator_vrm_set_value(rdev,
@@ -346,56 +402,6 @@ static int rpmh_regulator_set_enable_state(struct udevice *rdev,
 	return ret;
 }
 
-static int rpmh_regulator_vrm_set_mode_bypass(struct rpmh_vreg *vreg,
-					      unsigned int mode, bool bypassed)
-{
-	struct tcs_cmd cmd = {
-		.addr = vreg->addr + RPMH_REGULATOR_REG_VRM_MODE,
-	};
-	struct dm_regulator_mode *pmic_mode;
-	int i;
-
-	if (mode > REGULATOR_MODE_HPM)
-		return -EINVAL;
-
-	for (i = 0; i < vreg->hw_data->n_modes; i++) {
-		pmic_mode = &vreg->hw_data->pmic_mode_map[i];
-		if (pmic_mode->id == mode)
-			break;
-	}
-	if (pmic_mode->id != mode) {
-		printf("Invalid mode %d\n", mode);
-		return -EINVAL;
-	}
-
-	if (bypassed)
-		// XXX: should have a version check for PMIC4 but we don't have any yet
-		// and we don't use bypass mode
-		cmd.data = PMIC5_BOB_MODE_PASS;
-	else
-		cmd.data = pmic_mode->register_value;
-
-	return rpmh_regulator_send_request(vreg, &cmd, true);
-}
-
-static int rpmh_regulator_vrm_set_mode(struct udevice *rdev,
-				       int mode)
-{
-	struct rpmh_vreg *vreg = dev_get_priv(rdev);
-	int ret;
-
-	debug("%s: set_mode %d (current %d)\n", rdev->name, mode, vreg->mode);
-
-	if (mode == vreg->mode)
-		return 0;
-
-	ret = rpmh_regulator_vrm_set_mode_bypass(vreg, mode, vreg->bypassed);
-	if (!ret)
-		vreg->mode = mode;
-
-	return ret;
-}
-
 static int rpmh_regulator_vrm_get_pmic_mode(struct rpmh_vreg *vreg, int *pmic_mode)
 {
 	struct tcs_cmd cmd = {

-- 
2.54.0

