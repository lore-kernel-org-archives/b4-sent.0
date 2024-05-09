From: Fenglin Wu <quic_fenglinw@quicinc.com>
Date: Thu, 09 May 2024 10:07:23 +0800
Subject: [PATCH] leds: flash: leds-qcom-flash: limit LED current based on
 thermal condition
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240509-qcom_flash_thermal_derating-v1-1-1d5e68e5d71c@quicinc.com>
X-B4-Tracking: v=1; b=H4sIANovPGYC/x3M0QqDIBQA0F+R+zzBrCbsV8YQs2teKN2uEkH07
 8kez8s5oSATFniJExh3KpRTQ/cQ4KNLC0qam0ErPahRGfnzebNhdSXaGpE3t9oZ2VVKi9RPNXW
 h92Y0HtrwZQx0/Pf357pumP9dCW0AAAA=
To: kernel@quicinc.com, Pavel Machek <pavel@ucw.cz>, 
 Lee Jones <lee@kernel.org>
Cc: linux-leds@vger.kernel.org, linux-kernel@vger.kernel.org, 
 David Collins <quic_collinsd@quicinc.com>, 
 Subbaraman Narayanamurthy <quic_subbaram@quicinc.com>, 
 Fenglin Wu <quic_fenglinw@quicinc.com>
X-Mailer: b4 0.13-dev-83828
X-Developer-Signature: v=1; a=ed25519-sha256; t=1715220458; l=8560;
 i=quic_fenglinw@quicinc.com; s=20240327; h=from:subject:message-id;
 bh=IlINF1oaHNMZjbRO9R8bFeDAu8tqXBHedM9NemxFGA0=;
 b=hBVzmGY1QjXX5GjdW/81LEwJT0QjNKyYGJ1SH4py49MrwRuR4LzAyhx6pAEfArGMyo6StpH/b
 MHU+3FtX3JSB7mS50nGfT07I1q9MZ3cy70/1wfhGgCWJqr4kSwQ6qdt
X-Developer-Key: i=quic_fenglinw@quicinc.com; a=ed25519;
 pk=BF8SA4IVDk8/EBCwlBehKtn2hp6kipuuAuDAHh9s+K4=
X-Endpoint-Received: by B4 Relay for quic_fenglinw@quicinc.com/20240327 with auth_id=146
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The flash module has status bits to indicate different thermal
conditions which are called as OTSTx. For each OTSTx status,
there is a recommended total flash current for all channels to
prevent the flash module entering into higher thermal level.
For example, the total flash current should be limited to 1000mA/500mA
respectively when the HW reaches the OTST1/OTST2 thermal level.

Signed-off-by: Fenglin Wu <quic_fenglinw@quicinc.com>
---
 drivers/leds/flash/leds-qcom-flash.c | 151 ++++++++++++++++++++++++++++++++++-
 1 file changed, 150 insertions(+), 1 deletion(-)

diff --git a/drivers/leds/flash/leds-qcom-flash.c b/drivers/leds/flash/leds-qcom-flash.c
index 7c99a3039171..036c9e3cf974 100644
--- a/drivers/leds/flash/leds-qcom-flash.c
+++ b/drivers/leds/flash/leds-qcom-flash.c
@@ -1,6 +1,6 @@
 // SPDX-License-Identifier: GPL-2.0-only
 /*
- * Copyright (c) 2022 Qualcomm Innovation Center, Inc. All rights reserved.
+ * Copyright (c) 2022, 2024 Qualcomm Innovation Center, Inc. All rights reserved.
  */
 
 #include <linux/bitfield.h>
@@ -14,6 +14,9 @@
 #include <media/v4l2-flash-led-class.h>
 
 /* registers definitions */
+#define FLASH_REVISION_REG		0x00
+#define FLASH_4CH_REVISION_V0P1		0x01
+
 #define FLASH_TYPE_REG			0x04
 #define FLASH_TYPE_VAL			0x18
 
@@ -73,6 +76,16 @@
 
 #define UA_PER_MA			1000
 
+/* thermal threshold constants */
+#define OTST_3CH_MIN_VAL		3
+#define OTST1_4CH_MIN_VAL		0
+#define OTST1_4CH_MIN_VAL_V0P1		3
+#define OTST2_4CH_MIN_VAL		0
+
+#define OTST1_MAX_CURRENT_MA		1000
+#define OTST2_MAX_CURRENT_MA		500
+#define OTST3_MAX_CURRENT_MA		200
+
 enum hw_type {
 	QCOM_MVFLASH_3CH,
 	QCOM_MVFLASH_4CH,
@@ -98,6 +111,7 @@ enum {
 	REG_IRESOLUTION,
 	REG_CHAN_STROBE,
 	REG_CHAN_EN,
+	REG_THERM_THRSH,
 	REG_MAX_COUNT,
 };
 
@@ -111,6 +125,7 @@ static struct reg_field mvflash_3ch_regs[REG_MAX_COUNT] = {
 	REG_FIELD(0x47, 0, 5),                  /* iresolution	*/
 	REG_FIELD_ID(0x49, 0, 2, 3, 1),         /* chan_strobe	*/
 	REG_FIELD(0x4c, 0, 2),                  /* chan_en	*/
+	REG_FIELD_ID(0x56, 0, 2, 3, 1),		/* therm_thrsh  */
 };
 
 static struct reg_field mvflash_4ch_regs[REG_MAX_COUNT] = {
@@ -123,6 +138,7 @@ static struct reg_field mvflash_4ch_regs[REG_MAX_COUNT] = {
 	REG_FIELD(0x49, 0, 3),			/* iresolution	*/
 	REG_FIELD_ID(0x4a, 0, 6, 4, 1),		/* chan_strobe	*/
 	REG_FIELD(0x4e, 0, 3),			/* chan_en	*/
+	REG_FIELD_ID(0x7a, 0, 2, 2, 1),		/* therm_thrsh  */
 };
 
 struct qcom_flash_data {
@@ -130,9 +146,11 @@ struct qcom_flash_data {
 	struct regmap_field     *r_fields[REG_MAX_COUNT];
 	struct mutex		lock;
 	enum hw_type		hw_type;
+	u32			total_ma;
 	u8			leds_count;
 	u8			max_channels;
 	u8			chan_en_bits;
+	u8			revision;
 };
 
 struct qcom_flash_led {
@@ -143,6 +161,7 @@ struct qcom_flash_led {
 	u32				max_timeout_ms;
 	u32				flash_current_ma;
 	u32				flash_timeout_ms;
+	u32				current_in_use_ma;
 	u8				*chan_id;
 	u8				chan_count;
 	bool				enabled;
@@ -172,6 +191,121 @@ static int set_flash_module_en(struct qcom_flash_led *led, bool en)
 	return rc;
 }
 
+static int update_allowed_flash_current(struct qcom_flash_led *led, u32 *current_ma, bool strobe)
+{
+	struct qcom_flash_data *flash_data = led->flash_data;
+	u32 therm_ma, avail_ma, thrsh[3], min_thrsh, sts;
+	int rc;
+
+	mutex_lock(&flash_data->lock);
+	/*
+	 * Put previously allocated current into allowed budget in either of these two cases:
+	 * 1) LED is disabled;
+	 * 2) LED is enabled repeatedly
+	 */
+	if (!strobe || (strobe && led->current_in_use_ma != 0)) {
+		if (flash_data->total_ma >= led->current_in_use_ma)
+			flash_data->total_ma -= led->current_in_use_ma;
+		else
+			flash_data->total_ma = 0;
+
+		led->current_in_use_ma = 0;
+		if (!strobe) {
+			mutex_unlock(&flash_data->lock);
+			return 0;
+		}
+	}
+
+	/*
+	 * Cache the default thermal threshold settings, and set them to the lowest levels before
+	 * reading over-temp real time status. If over-temp has been triggered at the lowest
+	 * threshold, it's very likely that it would be triggered at a higher (default) threshold
+	 * when more flash current is requested. Prevent device from triggering over-temp condition
+	 * by limiting the flash current for the new request.
+	 */
+	rc = regmap_fields_read(flash_data->r_fields[REG_THERM_THRSH], 0, &thrsh[0]);
+	if (rc < 0)
+		goto unlock;
+
+	rc = regmap_fields_read(flash_data->r_fields[REG_THERM_THRSH], 1, &thrsh[1]);
+	if (rc < 0)
+		goto unlock;
+
+	if (flash_data->hw_type == QCOM_MVFLASH_3CH) {
+		rc = regmap_fields_read(flash_data->r_fields[REG_THERM_THRSH], 2, &thrsh[2]);
+		if (rc < 0)
+			goto unlock;
+	}
+
+	min_thrsh = OTST_3CH_MIN_VAL;
+	if (flash_data->hw_type == QCOM_MVFLASH_4CH)
+		min_thrsh = (flash_data->revision == FLASH_4CH_REVISION_V0P1) ?
+			OTST1_4CH_MIN_VAL_V0P1 : OTST1_4CH_MIN_VAL;
+	rc = regmap_fields_write(flash_data->r_fields[REG_THERM_THRSH], 0, min_thrsh);
+	if (rc < 0)
+		goto unlock;
+
+	if (flash_data->hw_type == QCOM_MVFLASH_4CH)
+		min_thrsh = OTST2_4CH_MIN_VAL;
+	rc = regmap_fields_write(flash_data->r_fields[REG_THERM_THRSH], 1, min_thrsh);
+	if (rc < 0)
+		goto restore;
+
+	if (flash_data->hw_type == QCOM_MVFLASH_3CH) {
+		rc = regmap_fields_write(flash_data->r_fields[REG_THERM_THRSH], 2, min_thrsh);
+		if (rc < 0)
+			goto restore;
+	}
+
+	/* read thermal level status to get corresponding derating flash current */
+	rc = regmap_field_read(flash_data->r_fields[REG_STATUS2], &sts);
+	if (rc)
+		goto restore;
+
+	therm_ma = FLASH_TOTAL_CURRENT_MAX_UA / 1000;
+	if (flash_data->hw_type == QCOM_MVFLASH_3CH) {
+		if (sts & FLASH_STS_3CH_OTST3)
+			therm_ma = OTST3_MAX_CURRENT_MA;
+		else if (sts & FLASH_STS_3CH_OTST2)
+			therm_ma = OTST2_MAX_CURRENT_MA;
+		else if (sts & FLASH_STS_3CH_OTST1)
+			therm_ma = OTST1_MAX_CURRENT_MA;
+	} else {
+		if (sts & FLASH_STS_4CH_OTST2)
+			therm_ma = OTST2_MAX_CURRENT_MA;
+		else if (sts & FLASH_STS_4CH_OTST1)
+			therm_ma = OTST1_MAX_CURRENT_MA;
+	}
+
+	/* calculate the allowed flash current for the request */
+	if (therm_ma <= flash_data->total_ma)
+		avail_ma = 0;
+	else
+		avail_ma = therm_ma - flash_data->total_ma;
+	*current_ma = min_t(u32, *current_ma, avail_ma);
+	led->current_in_use_ma = *current_ma;
+	flash_data->total_ma += led->current_in_use_ma;
+
+	dev_dbg(led->flash.led_cdev.dev, "allowed flash current: %dmA, total current: %dmA\n",
+					led->current_in_use_ma, flash_data->total_ma);
+restore:
+	/* Restore to default thermal threshold settings */
+	rc = regmap_fields_write(flash_data->r_fields[REG_THERM_THRSH], 0, thrsh[0]);
+	if (rc < 0)
+		goto unlock;
+
+	rc = regmap_fields_write(flash_data->r_fields[REG_THERM_THRSH], 1, thrsh[1]);
+	if (rc < 0)
+		goto unlock;
+
+	if (flash_data->hw_type == QCOM_MVFLASH_3CH)
+		rc = regmap_fields_write(flash_data->r_fields[REG_THERM_THRSH], 2, thrsh[2]);
+
+unlock:
+	mutex_unlock(&flash_data->lock);
+	return rc;
+}
+
 static int set_flash_current(struct qcom_flash_led *led, u32 current_ma, enum led_mode mode)
 {
 	struct qcom_flash_data *flash_data = led->flash_data;
@@ -313,6 +447,10 @@ static int qcom_flash_strobe_set(struct led_classdev_flash *fled_cdev, bool stat
 	if (rc)
 		return rc;
 
+	rc = update_allowed_flash_current(led, &led->flash_current_ma, state);
+	if (rc < 0)
+		return rc;
+
 	rc = set_flash_current(led, led->flash_current_ma, FLASH_MODE);
 	if (rc)
 		return rc;
@@ -429,6 +567,10 @@ static int qcom_flash_led_brightness_set(struct led_classdev *led_cdev,
 	if (rc)
 		return rc;
 
+	rc = update_allowed_flash_current(led, &current_ma, enable);
+	if (rc < 0)
+		return rc;
+
 	rc = set_flash_current(led, current_ma, TORCH_MODE);
 	if (rc)
 		return rc;
@@ -703,6 +845,13 @@ static int qcom_flash_led_probe(struct platform_device *pdev)
 		flash_data->hw_type = QCOM_MVFLASH_4CH;
 		flash_data->max_channels = 4;
 		regs = mvflash_4ch_regs;
+		rc = regmap_read(regmap, reg_base + FLASH_REVISION_REG, &val);
+		if (rc < 0) {
+			dev_err(dev, "Read flash LED module revision failed, rc=%d\n", rc);
+			return rc;
+		}
+
+		flash_data->revision = val;
 	} else {
 		dev_err(dev, "flash LED subtype %#x is not yet supported\n", val);
 		return -ENODEV;

---
base-commit: ca66b10a11da3c445c9c0ca1184f549bbe9061f2
change-id: 20240507-qcom_flash_thermal_derating-260b1f3c757c

Best regards,
-- 
Fenglin Wu <quic_fenglinw@quicinc.com>

