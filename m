From: Fenglin Wu <fenglin.wu@oss.qualcomm.com>
Date: Fri, 25 Jul 2025 18:04:03 +0800
Subject: [PATCH 1/2] leds: flash: leds-qcom-flash: update torch current
 clamp setting
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250725-fix-torch-clamp-issue-v1-1-4cf3ebaa4c67@oss.qualcomm.com>
References: <20250725-fix-torch-clamp-issue-v1-0-4cf3ebaa4c67@oss.qualcomm.com>
In-Reply-To: <20250725-fix-torch-clamp-issue-v1-0-4cf3ebaa4c67@oss.qualcomm.com>
To: kernel@oss.qualcomm.com, Lee Jones <lee@kernel.org>, 
 Pavel Machek <pavel@kernel.org>, Fenglin Wu <quic_fenglinw@quicinc.com>
Cc: Subbaraman Narayanamurthy <subbaraman.narayanamurthy@oss.qualcomm.com>, 
 linux-leds@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Fenglin Wu <fenglin.wu@oss.qualcomm.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1753437856; l=3409;
 i=fenglin.wu@oss.qualcomm.com; s=20240327; h=from:subject:message-id;
 bh=v2hPU9OxK+ys58fLw4CJe4MftTpBGLNVnc5w51m7B2Q=;
 b=OvcBcHSFhra6s9er1jloJ4CKjih4RY55XCMBwZNoYXynrXbcRWStA7mE8oXJYp1jcrnEUJbxy
 xNU3S19JqMgDZEUSrHLXalTVI+cN1W6xMAr6o62wwcS9Lp4yytyyhyW
X-Developer-Key: i=fenglin.wu@oss.qualcomm.com; a=ed25519;
 pk=BF8SA4IVDk8/EBCwlBehKtn2hp6kipuuAuDAHh9s+K4=
X-Endpoint-Received: by B4 Relay for fenglin.wu@oss.qualcomm.com/20240327 with auth_id=406
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

There is a register to clamp the flash current per LED channel when
safety timer is disabled. It needs to be updated according to the
maximum torch LED current setting to ensure the torch current won't
be clamped unexpectedly.

Fixes: 96a2e242a5dc ("leds: flash: Add driver to support flash LED module in QCOM PMICs")
Signed-off-by: Fenglin Wu <fenglin.wu@oss.qualcomm.com>
---
 drivers/leds/flash/leds-qcom-flash.c | 16 +++++++++++++---
 1 file changed, 13 insertions(+), 3 deletions(-)

diff --git a/drivers/leds/flash/leds-qcom-flash.c b/drivers/leds/flash/leds-qcom-flash.c
index 89cf5120f5d55bbb7e24faa8c3a946416f8fed46..9c2e41cfddcf2d50d5a633cb157084371a631d74 100644
--- a/drivers/leds/flash/leds-qcom-flash.c
+++ b/drivers/leds/flash/leds-qcom-flash.c
@@ -1,6 +1,6 @@
 // SPDX-License-Identifier: GPL-2.0-only
 /*
- * Copyright (c) 2022, 2024 Qualcomm Innovation Center, Inc. All rights reserved.
+ * Copyright (c) 2022, 2024-2025 Qualcomm Innovation Center, Inc. All rights reserved.
  */
 
 #include <linux/bitfield.h>
@@ -111,6 +111,7 @@ enum {
 	REG_IRESOLUTION,
 	REG_CHAN_STROBE,
 	REG_CHAN_EN,
+	REG_TORCH_CLAMP,
 	REG_THERM_THRSH1,
 	REG_THERM_THRSH2,
 	REG_THERM_THRSH3,
@@ -127,6 +128,7 @@ static const struct reg_field mvflash_3ch_regs[REG_MAX_COUNT] = {
 	REG_FIELD(0x47, 0, 5),                  /* iresolution	*/
 	REG_FIELD_ID(0x49, 0, 2, 3, 1),         /* chan_strobe	*/
 	REG_FIELD(0x4c, 0, 2),                  /* chan_en	*/
+	REG_FIELD(0xec, 0, 6),			/* torch_clamp	*/
 	REG_FIELD(0x56, 0, 2),			/* therm_thrsh1 */
 	REG_FIELD(0x57, 0, 2),			/* therm_thrsh2 */
 	REG_FIELD(0x58, 0, 2),			/* therm_thrsh3 */
@@ -142,6 +144,7 @@ static const struct reg_field mvflash_4ch_regs[REG_MAX_COUNT] = {
 	REG_FIELD(0x49, 0, 3),			/* iresolution	*/
 	REG_FIELD_ID(0x4a, 0, 6, 4, 1),		/* chan_strobe	*/
 	REG_FIELD(0x4e, 0, 3),			/* chan_en	*/
+	REG_FIELD(0xed, 0, 6),			/* torch_clamp	*/
 	REG_FIELD(0x7a, 0, 2),			/* therm_thrsh1 */
 	REG_FIELD(0x78, 0, 2),			/* therm_thrsh2 */
 };
@@ -156,6 +159,7 @@ struct qcom_flash_data {
 	u8			max_channels;
 	u8			chan_en_bits;
 	u8			revision;
+	u8			torch_clamp;
 };
 
 struct qcom_flash_led {
@@ -702,6 +706,7 @@ static int qcom_flash_register_led_device(struct device *dev,
 	u32 current_ua, timeout_us;
 	u32 channels[4];
 	int i, rc, count;
+	u8 torch_clamp;
 
 	count = fwnode_property_count_u32(node, "led-sources");
 	if (count <= 0) {
@@ -751,6 +756,12 @@ static int qcom_flash_register_led_device(struct device *dev,
 	current_ua = min_t(u32, current_ua, TORCH_CURRENT_MAX_UA * led->chan_count);
 	led->max_torch_current_ma = current_ua / UA_PER_MA;
 
+	torch_clamp = (current_ua / led->chan_count) / TORCH_IRES_UA;
+	if (torch_clamp != 0)
+		torch_clamp--;
+
+	flash_data->torch_clamp = max_t(u8, flash_data->torch_clamp, torch_clamp);
+
 	if (fwnode_property_present(node, "flash-max-microamp")) {
 		flash->led_cdev.flags |= LED_DEV_CAP_FLASH;
 
@@ -917,8 +928,7 @@ static int qcom_flash_led_probe(struct platform_device *pdev)
 		flash_data->leds_count++;
 	}
 
-	return 0;
-
+	return regmap_field_write(flash_data->r_fields[REG_TORCH_CLAMP], flash_data->torch_clamp);
 release:
 	while (flash_data->v4l2_flash[flash_data->leds_count] && flash_data->leds_count)
 		v4l2_flash_release(flash_data->v4l2_flash[flash_data->leds_count--]);

-- 
2.34.1

