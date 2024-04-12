From: Fenglin Wu <quic_fenglinw@quicinc.com>
Date: Fri, 12 Apr 2024 20:36:26 +0800
Subject: [PATCH v10 2/4] input: pm8xxx-vibrator: refactor to support new
 SPMI vibrator
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240412-pm8xxx-vibrator-new-design-v10-2-0ec0ad133866@quicinc.com>
References: <20240412-pm8xxx-vibrator-new-design-v10-0-0ec0ad133866@quicinc.com>
In-Reply-To: <20240412-pm8xxx-vibrator-new-design-v10-0-0ec0ad133866@quicinc.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1712925404; l=4328;
 i=quic_fenglinw@quicinc.com; s=20240327; h=from:subject:message-id;
 bh=Z23TYMEBk9Q8HS6GaIPC6RDcCQ+axWSc4H0ISoYYLRc=;
 b=+vDlS5D319hE8n7YqmWl6RfFPnd9GqnpdIasC0UIGUkQBurWArorTBCrs/q84JYlsO87Wse0F
 ZrLKJRXqSVwD6hm6KaB5AMroB/uEgBRUSj+CDHJDHUlt+90Jfk57NWD
X-Developer-Key: i=quic_fenglinw@quicinc.com; a=ed25519;
 pk=BF8SA4IVDk8/EBCwlBehKtn2hp6kipuuAuDAHh9s+K4=
X-Endpoint-Received: by B4 Relay for quic_fenglinw@quicinc.com/20240327 with auth_id=146
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Currently, vibrator control register addresses are hard coded,
including the base address and offsets, it's not flexible to
support new SPMI vibrator module which is usually included in
different PMICs with different base address. Refactor it by using
the base address defined in devicetree.

Signed-off-by: Fenglin Wu <quic_fenglinw@quicinc.com>
---
 drivers/input/misc/pm8xxx-vibrator.c | 41 +++++++++++++++++++++++-------------
 1 file changed, 26 insertions(+), 15 deletions(-)

diff --git a/drivers/input/misc/pm8xxx-vibrator.c b/drivers/input/misc/pm8xxx-vibrator.c
index 844ca7e1f59f..640927f94143 100644
--- a/drivers/input/misc/pm8xxx-vibrator.c
+++ b/drivers/input/misc/pm8xxx-vibrator.c
@@ -20,27 +20,27 @@
 #define MAX_FF_SPEED		0xff
 
 struct pm8xxx_regs {
-	unsigned int enable_addr;
+	unsigned int enable_offset;
 	unsigned int enable_mask;
 
-	unsigned int drv_addr;
+	unsigned int drv_offset;
 	unsigned int drv_mask;
 	unsigned int drv_shift;
 	unsigned int drv_en_manual_mask;
 };
 
 static const struct pm8xxx_regs pm8058_regs = {
-	.drv_addr = 0x4A,
+	.drv_offset = 0,
 	.drv_mask = 0xf8,
 	.drv_shift = 3,
 	.drv_en_manual_mask = 0xfc,
 };
 
 static struct pm8xxx_regs pm8916_regs = {
-	.enable_addr = 0xc046,
+	.enable_offset = 0x46,
 	.enable_mask = BIT(7),
-	.drv_addr = 0xc041,
-	.drv_mask = 0x1F,
+	.drv_offset = 0x41,
+	.drv_mask = 0x1f,
 	.drv_shift = 0,
 	.drv_en_manual_mask = 0,
 };
@@ -51,6 +51,8 @@ static struct pm8xxx_regs pm8916_regs = {
  * @work: work structure to set the vibration parameters
  * @regmap: regmap for register read/write
  * @regs: registers' info
+ * @enable_addr: vibrator enable register
+ * @drv_addr: vibrator drive strength register
  * @speed: speed of vibration set from userland
  * @active: state of vibrator
  * @level: level of vibration to set in the chip
@@ -61,6 +63,8 @@ struct pm8xxx_vib {
 	struct work_struct work;
 	struct regmap *regmap;
 	const struct pm8xxx_regs *regs;
+	unsigned int enable_addr;
+	unsigned int drv_addr;
 	int speed;
 	int level;
 	bool active;
@@ -83,15 +87,15 @@ static int pm8xxx_vib_set(struct pm8xxx_vib *vib, bool on)
 	else
 		val &= ~regs->drv_mask;
 
-	rc = regmap_write(vib->regmap, regs->drv_addr, val);
+	rc = regmap_write(vib->regmap, vib->drv_addr, val);
 	if (rc < 0)
 		return rc;
 
 	vib->reg_vib_drv = val;
 
 	if (regs->enable_mask)
-		rc = regmap_update_bits(vib->regmap, regs->enable_addr,
-					regs->enable_mask, on ? ~0 : 0);
+		rc = regmap_update_bits(vib->regmap, vib->enable_addr,
+					regs->enable_mask, on ? regs->enable_mask : 0);
 
 	return rc;
 }
@@ -103,11 +107,10 @@ static int pm8xxx_vib_set(struct pm8xxx_vib *vib, bool on)
 static void pm8xxx_work_handler(struct work_struct *work)
 {
 	struct pm8xxx_vib *vib = container_of(work, struct pm8xxx_vib, work);
-	const struct pm8xxx_regs *regs = vib->regs;
-	int rc;
 	unsigned int val;
+	int rc;
 
-	rc = regmap_read(vib->regmap, regs->drv_addr, &val);
+	rc = regmap_read(vib->regmap, vib->drv_addr, &val);
 	if (rc < 0)
 		return;
 
@@ -170,7 +173,7 @@ static int pm8xxx_vib_probe(struct platform_device *pdev)
 	struct pm8xxx_vib *vib;
 	struct input_dev *input_dev;
 	int error;
-	unsigned int val;
+	unsigned int val, reg_base = 0;
 	const struct pm8xxx_regs *regs;
 
 	vib = devm_kzalloc(&pdev->dev, sizeof(*vib), GFP_KERNEL);
@@ -188,15 +191,23 @@ static int pm8xxx_vib_probe(struct platform_device *pdev)
 	INIT_WORK(&vib->work, pm8xxx_work_handler);
 	vib->vib_input_dev = input_dev;
 
+	error = fwnode_property_read_u32(pdev->dev.fwnode, "reg", &reg_base);
+	if (error < 0) {
+		dev_err(&pdev->dev, "Failed to read reg address, rc=%d\n", error);
+		return error;
+	}
+
 	regs = of_device_get_match_data(&pdev->dev);
+	vib->enable_addr = reg_base + regs->enable_offset;
+	vib->drv_addr = reg_base + regs->drv_offset;
 
 	/* operate in manual mode */
-	error = regmap_read(vib->regmap, regs->drv_addr, &val);
+	error = regmap_read(vib->regmap, vib->drv_addr, &val);
 	if (error < 0)
 		return error;
 
 	val &= regs->drv_en_manual_mask;
-	error = regmap_write(vib->regmap, regs->drv_addr, val);
+	error = regmap_write(vib->regmap, vib->drv_addr, val);
 	if (error < 0)
 		return error;
 

-- 
2.25.1

