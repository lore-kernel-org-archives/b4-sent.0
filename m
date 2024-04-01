From: Fenglin Wu <quic_fenglinw@quicinc.com>
Date: Mon, 01 Apr 2024 16:38:52 +0800
Subject: [PATCH v8 3/3] input: pm8xxx-vibrator: add new SPMI vibrator
 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240401-pm8xxx-vibrator-new-design-v8-3-6f2b8b03b4c7@quicinc.com>
References: <20240401-pm8xxx-vibrator-new-design-v8-0-6f2b8b03b4c7@quicinc.com>
In-Reply-To: <20240401-pm8xxx-vibrator-new-design-v8-0-6f2b8b03b4c7@quicinc.com>
To: kernel@quicinc.com, Andy Gross <agross@kernel.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konrad.dybcio@linaro.org>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Dmitry Baryshkov <dmitry.baryshkov@linaro.org>
Cc: linux-arm-msm@vger.kernel.org, linux-input@vger.kernel.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 Fenglin Wu <quic_fenglinw@quicinc.com>
X-Mailer: b4 0.13-dev-83828
X-Developer-Signature: v=1; a=ed25519-sha256; t=1711960777; l=4499;
 i=quic_fenglinw@quicinc.com; s=20240327; h=from:subject:message-id;
 bh=KTKY6pvIVjfzHLnLf3c7IEWevUabtEPHzFZQuRWIpJU=;
 b=ckVKAUUpGCn6CBayzxswtJaUk5uvqlZf+zx9drwGyK2zmg6H1U8+Ut4ZTH/kV736rxzpAAEkH
 LCPWeKoHWJ4ACwQDB112nC5c+5VNwiXlyj3hTRLn9/A8i+MDAt/7QVQ
X-Developer-Key: i=quic_fenglinw@quicinc.com; a=ed25519;
 pk=BF8SA4IVDk8/EBCwlBehKtn2hp6kipuuAuDAHh9s+K4=
X-Endpoint-Received: by B4 Relay for quic_fenglinw@quicinc.com/20240327 with auth_id=146
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support for a new SPMI vibrator module which is very similar
to the vibrator module inside PM8916 but has a finer drive voltage
step and different output voltage range, its drive level control
is expanded across 2 registers. The vibrator module can be found
in following Qualcomm PMICs: PMI632, PM7250B, PM7325B, PM7550BA.

Signed-off-by: Fenglin Wu <quic_fenglinw@quicinc.com>
---
 drivers/input/misc/pm8xxx-vibrator.c | 49 +++++++++++++++++++++++++++++-------
 1 file changed, 40 insertions(+), 9 deletions(-)

diff --git a/drivers/input/misc/pm8xxx-vibrator.c b/drivers/input/misc/pm8xxx-vibrator.c
index 3b6a2e949f30..59548cd9331c 100644
--- a/drivers/input/misc/pm8xxx-vibrator.c
+++ b/drivers/input/misc/pm8xxx-vibrator.c
@@ -12,9 +12,9 @@
 #include <linux/regmap.h>
 #include <linux/slab.h>
 
-#define VIB_MAX_LEVEL_mV	(3100)
-#define VIB_MIN_LEVEL_mV	(1200)
-#define VIB_MAX_LEVELS		(VIB_MAX_LEVEL_mV - VIB_MIN_LEVEL_mV)
+#define VIB_MAX_LEVEL_mV(vib)	(vib->drv2_addr ? (3544) : (3100))
+#define VIB_MIN_LEVEL_mV(vib)	(vib->drv2_addr ? (1504) : (1200))
+#define VIB_MAX_LEVELS(vib)	(VIB_MAX_LEVEL_mV(vib) - VIB_MIN_LEVEL_mV(vib))
 
 #define MAX_FF_SPEED		0xff
 
@@ -25,6 +25,9 @@ struct pm8xxx_regs {
 	unsigned int drv_offset;
 	unsigned int drv_mask;
 	unsigned int drv_shift;
+	unsigned int drv2_offset;
+	unsigned int drv2_mask;
+	unsigned int drv2_shift;
 	unsigned int drv_en_manual_mask;
 };
 
@@ -44,6 +47,18 @@ static struct pm8xxx_regs pm8916_regs = {
 	.drv_en_manual_mask = 0,
 };
 
+static struct pm8xxx_regs pmi632_regs = {
+	.enable_offset = 0x46,
+	.enable_mask = BIT(7),
+	.drv_offset = 0x40,
+	.drv_mask = 0xFF,
+	.drv_shift = 0,
+	.drv2_offset = 0x41,
+	.drv2_mask = 0x0F,
+	.drv2_shift = 8,
+	.drv_en_manual_mask = 0,
+};
+
 /**
  * struct pm8xxx_vib - structure to hold vibrator data
  * @vib_input_dev: input device supporting force feedback
@@ -52,6 +67,7 @@ static struct pm8xxx_regs pm8916_regs = {
  * @regs: registers' info
  * @enable_addr: vibrator enable register
  * @drv_addr: vibrator drive strength register
+ * @drv2_addr: vibrator drive strength upper byte register
  * @speed: speed of vibration set from userland
  * @active: state of vibrator
  * @level: level of vibration to set in the chip
@@ -64,6 +80,7 @@ struct pm8xxx_vib {
 	const struct pm8xxx_regs *regs;
 	unsigned int enable_addr;
 	unsigned int drv_addr;
+	unsigned int drv2_addr;
 	int speed;
 	int level;
 	bool active;
@@ -92,6 +109,16 @@ static int pm8xxx_vib_set(struct pm8xxx_vib *vib, bool on)
 
 	vib->reg_vib_drv = val;
 
+	if (regs->drv2_mask) {
+		if (on)
+			val = (vib->level << regs->drv2_shift) & regs->drv2_mask;
+		else
+			val = 0;
+		rc = regmap_write(vib->regmap, vib->drv2_addr, val);
+		if (rc < 0)
+			return rc;
+	}
+
 	if (regs->enable_mask)
 		rc = regmap_update_bits(vib->regmap, vib->enable_addr,
 					regs->enable_mask, on ? ~0 : 0);
@@ -114,19 +141,22 @@ static void pm8xxx_work_handler(struct work_struct *work)
 		return;
 
 	/*
-	 * pmic vibrator supports voltage ranges from 1.2 to 3.1V, so
+	 * pmic vibrator supports voltage ranges from MIN_LEVEL to MAX_LEVEL, so
 	 * scale the level to fit into these ranges.
 	 */
 	if (vib->speed) {
 		vib->active = true;
-		vib->level = ((VIB_MAX_LEVELS * vib->speed) / MAX_FF_SPEED) +
-						VIB_MIN_LEVEL_mV;
-		vib->level /= 100;
+		vib->level = ((VIB_MAX_LEVELS(vib) * vib->speed) / MAX_FF_SPEED) +
+						VIB_MIN_LEVEL_mV(vib);
 	} else {
 		vib->active = false;
-		vib->level = VIB_MIN_LEVEL_mV / 100;
+		vib->level = VIB_MIN_LEVEL_mV(vib);
+
 	}
 
+	if (!vib->drv2_addr)
+		vib->level /= 100;
+
 	pm8xxx_vib_set(vib, vib->active);
 }
 
@@ -202,7 +232,7 @@ static int pm8xxx_vib_probe(struct platform_device *pdev)
 
 	vib->enable_addr = reg_base + regs->enable_offset;
 	vib->drv_addr = reg_base + regs->drv_offset;
-
+	vib->drv2_addr = reg_base + regs->drv2_offset;
 	/* operate in manual mode */
 	error = regmap_read(vib->regmap, vib->drv_addr, &val);
 	if (error < 0)
@@ -256,6 +286,7 @@ static const struct of_device_id pm8xxx_vib_id_table[] = {
 	{ .compatible = "qcom,pm8058-vib", .data = &pm8058_regs },
 	{ .compatible = "qcom,pm8921-vib", .data = &pm8058_regs },
 	{ .compatible = "qcom,pm8916-vib", .data = &pm8916_regs },
+	{ .compatible = "qcom,pmi632-vib", .data = &pmi632_regs },
 	{ }
 };
 MODULE_DEVICE_TABLE(of, pm8xxx_vib_id_table);

-- 
2.25.1

