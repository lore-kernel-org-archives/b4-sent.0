From: =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
Date: Sat, 20 Sep 2025 14:03:45 +0200
Subject: [PATCH v2 6/8] media: i2c: dw9719: Add DW9718S support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250920-dw9719-v2-6-028cdaa156e5@apitzsch.eu>
References: <20250920-dw9719-v2-0-028cdaa156e5@apitzsch.eu>
In-Reply-To: <20250920-dw9719-v2-0-028cdaa156e5@apitzsch.eu>
To: Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, devicetree@vger.kernel.org, 
 Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Daniel Scally <djrscally@gmail.com>
Cc: ~postmarketos/upstreaming@lists.sr.ht, phone-devel@vger.kernel.org, 
 linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Val Packett <val@packett.cool>, 
 =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1758369833; l=5271;
 i=git@apitzsch.eu; s=20240325; h=from:subject:message-id;
 bh=JpCnZmcDzeWapwYSSLPwXy9ZIqCE5jsp491/rzEN5rw=;
 b=72IUTK8bbrPsxiCXd109Y1GrBg3f+B3Ynob93nm9Q5AYzhft1C80DDPInxjiKS1kXSNLcvfRp
 laqrGavEcWQDC+fVGRY0hdn+ijKDCov6Vfmz9VhNcKXf2azMLoo5Thn
X-Developer-Key: i=git@apitzsch.eu; a=ed25519;
 pk=wxovcZRfvNYBMcTw4QFFtNEP4qv39gnBfnfyImXZxiU=
X-Endpoint-Received: by B4 Relay for git@apitzsch.eu/20240325 with auth_id=142
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Val Packett <val@packett.cool>

The DW9718S is a similar part that uses a different register set but
follows the same method of operation otherwise. Add support for it
to the existing dw9719 driver.

Tested on the Moto E5 (motorola-nora) smartphone.

Signed-off-by: Val Packett <val@packett.cool>
Signed-off-by: André Apitzsch <git@apitzsch.eu>
---
 drivers/media/i2c/dw9719.c | 67 +++++++++++++++++++++++++++++++++++++++-------
 1 file changed, 58 insertions(+), 9 deletions(-)

diff --git a/drivers/media/i2c/dw9719.c b/drivers/media/i2c/dw9719.c
index 5dc4126909b779aa0ce95015808b625fb21b67bb..5e3a200db3b5df8bf49547fc842c1cfd74322a40 100644
--- a/drivers/media/i2c/dw9719.c
+++ b/drivers/media/i2c/dw9719.c
@@ -23,6 +23,25 @@
 #define DW9719_CTRL_STEPS	16
 #define DW9719_CTRL_DELAY_US	1000
 
+#define DW9718S_PD			CCI_REG8(0)
+
+#define DW9718S_CONTROL			CCI_REG8(1)
+#define DW9718S_CONTROL_SW_LINEAR	BIT(0)
+#define DW9718S_CONTROL_SAC_SHIFT	1
+#define DW9718S_CONTROL_SAC_MASK	0x7
+#define DW9718S_CONTROL_OCP_DISABLE	BIT(4)
+#define DW9718S_CONTROL_UVLO_DISABLE	BIT(5)
+#define DW9718S_DEFAULT_SAC		4
+
+#define DW9718S_VCM_CURRENT		CCI_REG16(2)
+
+#define DW9718S_SW			CCI_REG8(4)
+#define DW9718S_SW_VCM_FREQ_MASK	0xF
+#define DW9718S_DEFAULT_VCM_FREQ	0
+
+#define DW9718S_SACT			CCI_REG8(5)
+#define DW9718S_SACT_PERIOD_8_8MS	0x19
+
 #define DW9719_INFO			CCI_REG8(0)
 #define DW9719_ID			0xF1
 #define DW9761_ID			0xF4
@@ -53,6 +72,7 @@
 #define to_dw9719_device(x) container_of(x, struct dw9719_device, sd)
 
 enum dw9719_model {
+	DW9718S,
 	DW9719,
 	DW9761,
 };
@@ -80,6 +100,7 @@ static int dw9719_power_down(struct dw9719_device *dw9719)
 
 static int dw9719_power_up(struct dw9719_device *dw9719, bool detect)
 {
+	u32 reg_pwr;
 	u64 val;
 	int ret;
 	int err;
@@ -89,13 +110,21 @@ static int dw9719_power_up(struct dw9719_device *dw9719, bool detect)
 		return ret;
 
 	/* Jiggle SCL pin to wake up device */
-	cci_write(dw9719->regmap, DW9719_CONTROL, DW9719_SHUTDOWN, &ret);
+	reg_pwr = dw9719->model == DW9718S ? DW9718S_PD : DW9719_CONTROL;
+	cci_write(dw9719->regmap, reg_pwr, DW9719_SHUTDOWN, &ret);
 	fsleep(100);
-	cci_write(dw9719->regmap, DW9719_CONTROL, DW9719_STANDBY, &ret);
+	cci_write(dw9719->regmap, reg_pwr, DW9719_STANDBY, &ret);
 	/* Need 100us to transit from SHUTDOWN to STANDBY */
 	fsleep(100);
 
 	if (detect) {
+		/* This model does not have an INFO register */
+		if (dw9719->model == DW9718S) {
+			dw9719->sac_mode = DW9718S_DEFAULT_SAC;
+			dw9719->vcm_freq = DW9718S_DEFAULT_VCM_FREQ;
+			goto props;
+		}
+
 		ret = cci_read(dw9719->regmap, DW9719_INFO, &val, NULL);
 		if (ret < 0)
 			return ret;
@@ -119,6 +148,7 @@ static int dw9719_power_up(struct dw9719_device *dw9719, bool detect)
 			return -ENXIO;
 		}
 
+props:
 		/* Optional indication of SAC mode select */
 		device_property_read_u32(dw9719->dev, "dongwoon,sac-mode",
 					 &dw9719->sac_mode);
@@ -134,14 +164,30 @@ static int dw9719_power_up(struct dw9719_device *dw9719, bool detect)
 					 &dw9719->vcm_freq);
 	}
 
-	cci_write(dw9719->regmap, DW9719_CONTROL, DW9719_ENABLE_RINGING, &ret);
-	cci_write(dw9719->regmap, DW9719_MODE, dw9719->mode_low_bits |
-			  (dw9719->sac_mode << DW9719_MODE_SAC_SHIFT), &ret);
-	cci_write(dw9719->regmap, DW9719_VCM_FREQ, dw9719->vcm_freq, &ret);
-
-	if (dw9719->model == DW9761)
+	switch (dw9719->model) {
+	case DW9718S:
+		/* Datasheet says [OCP/UVLO] should be disabled below 2.5V */
+		dw9719->sac_mode &= DW9718S_CONTROL_SAC_MASK;
+		cci_write(dw9719->regmap, DW9718S_CONTROL,
+			  DW9718S_CONTROL_SW_LINEAR |
+			  (dw9719->sac_mode << DW9718S_CONTROL_SAC_SHIFT) |
+			  DW9718S_CONTROL_OCP_DISABLE |
+			  DW9718S_CONTROL_UVLO_DISABLE, &ret);
+		cci_write(dw9719->regmap, DW9718S_SACT,
+			  DW9718S_SACT_PERIOD_8_8MS, &ret);
+		cci_write(dw9719->regmap, DW9718S_SW,
+			  dw9719->vcm_freq & DW9718S_SW_VCM_FREQ_MASK, &ret);
+		break;
+	case DW9761:
 		cci_write(dw9719->regmap, DW9761_VCM_PRELOAD,
 			  DW9761_DEFAULT_VCM_PRELOAD, &ret);
+		fallthrough;
+	case DW9719:
+		cci_write(dw9719->regmap, DW9719_CONTROL, DW9719_ENABLE_RINGING, &ret);
+		cci_write(dw9719->regmap, DW9719_MODE, dw9719->mode_low_bits |
+				  (dw9719->sac_mode << DW9719_MODE_SAC_SHIFT), &ret);
+		cci_write(dw9719->regmap, DW9719_VCM_FREQ, dw9719->vcm_freq, &ret);
+	}
 
 	if (ret)
 		dw9719_power_down(dw9719);
@@ -151,7 +197,9 @@ static int dw9719_power_up(struct dw9719_device *dw9719, bool detect)
 
 static int dw9719_t_focus_abs(struct dw9719_device *dw9719, s32 value)
 {
-	return cci_write(dw9719->regmap, DW9719_VCM_CURRENT, value, NULL);
+	u32 reg = dw9719->model == DW9718S ? DW9718S_VCM_CURRENT
+					   : DW9719_VCM_CURRENT;
+	return cci_write(dw9719->regmap, reg, value, NULL);
 }
 
 static int dw9719_set_ctrl(struct v4l2_ctrl *ctrl)
@@ -363,6 +411,7 @@ static void dw9719_remove(struct i2c_client *client)
 }
 
 static const struct of_device_id dw9719_of_table[] = {
+	{ .compatible = "dongwoon,dw9718s", .data = (const void *)DW9718S },
 	{ .compatible = "dongwoon,dw9719", .data = (const void *)DW9719 },
 	{ .compatible = "dongwoon,dw9761", .data = (const void *)DW9761 },
 	{ }

-- 
2.51.0

