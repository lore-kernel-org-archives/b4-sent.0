From: Fenglin Wu <fenglin.wu@oss.qualcomm.com>
Date: Fri, 25 Jul 2025 18:04:04 +0800
Subject: [PATCH 2/2] leds: flash: leds-qcom-flash: add a separate register
 map for PMI8998
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250725-fix-torch-clamp-issue-v1-2-4cf3ebaa4c67@oss.qualcomm.com>
References: <20250725-fix-torch-clamp-issue-v1-0-4cf3ebaa4c67@oss.qualcomm.com>
In-Reply-To: <20250725-fix-torch-clamp-issue-v1-0-4cf3ebaa4c67@oss.qualcomm.com>
To: kernel@oss.qualcomm.com, Lee Jones <lee@kernel.org>, 
 Pavel Machek <pavel@kernel.org>, Fenglin Wu <quic_fenglinw@quicinc.com>
Cc: Subbaraman Narayanamurthy <subbaraman.narayanamurthy@oss.qualcomm.com>, 
 linux-leds@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Fenglin Wu <fenglin.wu@oss.qualcomm.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1753437856; l=2388;
 i=fenglin.wu@oss.qualcomm.com; s=20240327; h=from:subject:message-id;
 bh=apUF2dH/Mll13q6/mMcrFJ2TYLuscFy4mzUCJJ0pxQU=;
 b=/Pv9fB6kxS8Qb1XuKdnLLN5YWv3jJq9NW8gfeSe5ZJrha8fsNAvd3wefCoyUgX8OVMCGTOZmy
 FZaOiwx0RxTD5nrsgRpmUx8wqJBPtFLHXtCOlHR3Og7NnTaZQCtqeWH
X-Developer-Key: i=fenglin.wu@oss.qualcomm.com; a=ed25519;
 pk=BF8SA4IVDk8/EBCwlBehKtn2hp6kipuuAuDAHh9s+K4=
X-Endpoint-Received: by B4 Relay for fenglin.wu@oss.qualcomm.com/20240327 with auth_id=406
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The 3-channel flash module in PMI8998 has several registers different
than the others, such as: torch_clamp. Add different register fields
for it.

Signed-off-by: Fenglin Wu <fenglin.wu@oss.qualcomm.com>
---
 drivers/leds/flash/leds-qcom-flash.c | 25 ++++++++++++++++++++++++-
 1 file changed, 24 insertions(+), 1 deletion(-)

diff --git a/drivers/leds/flash/leds-qcom-flash.c b/drivers/leds/flash/leds-qcom-flash.c
index 9c2e41cfddcf2d50d5a633cb157084371a631d74..2554ef7bcae6bc8f66edbffc7c885a9386b263ad 100644
--- a/drivers/leds/flash/leds-qcom-flash.c
+++ b/drivers/leds/flash/leds-qcom-flash.c
@@ -118,6 +118,22 @@ enum {
 	REG_MAX_COUNT,
 };
 
+static const struct reg_field mvflash_3ch_pmi8998_regs[REG_MAX_COUNT] = {
+	REG_FIELD(0x08, 0, 7),			/* status1	*/
+	REG_FIELD(0x09, 0, 7),			/* status2	*/
+	REG_FIELD(0x0a, 0, 7),			/* status3	*/
+	REG_FIELD_ID(0x40, 0, 7, 3, 1),		/* chan_timer	*/
+	REG_FIELD_ID(0x43, 0, 6, 3, 1),		/* itarget	*/
+	REG_FIELD(0x46, 7, 7),			/* module_en	*/
+	REG_FIELD(0x47, 0, 5),			/* iresolution	*/
+	REG_FIELD_ID(0x49, 0, 2, 3, 1),		/* chan_strobe	*/
+	REG_FIELD(0x4c, 0, 2),			/* chan_en	*/
+	REG_FIELD(0xea, 0, 6),			/* torch_clamp	*/
+	REG_FIELD(0x56, 0, 2),			/* therm_thrsh1 */
+	REG_FIELD(0x57, 0, 2),			/* therm_thrsh2 */
+	REG_FIELD(0x58, 0, 2),			/* therm_thrsh3 */
+};
+
 static const struct reg_field mvflash_3ch_regs[REG_MAX_COUNT] = {
 	REG_FIELD(0x08, 0, 7),			/* status1	*/
 	REG_FIELD(0x09, 0, 7),                  /* status2	*/
@@ -862,13 +878,20 @@ static int qcom_flash_led_probe(struct platform_device *pdev)
 		return rc;
 	}
 
-	if (val == FLASH_SUBTYPE_3CH_PM8150_VAL || val == FLASH_SUBTYPE_3CH_PMI8998_VAL) {
+	if (val == FLASH_SUBTYPE_3CH_PM8150_VAL) {
 		flash_data->hw_type = QCOM_MVFLASH_3CH;
 		flash_data->max_channels = 3;
 		regs = devm_kmemdup(dev, mvflash_3ch_regs, sizeof(mvflash_3ch_regs),
 				    GFP_KERNEL);
 		if (!regs)
 			return -ENOMEM;
+	} else if (val == FLASH_SUBTYPE_3CH_PMI8998_VAL) {
+		flash_data->hw_type = QCOM_MVFLASH_3CH;
+		flash_data->max_channels = 3;
+		regs = devm_kmemdup(dev, mvflash_3ch_pmi8998_regs,
+				    sizeof(mvflash_3ch_pmi8998_regs), GFP_KERNEL);
+		if (!regs)
+			return -ENOMEM;
 	} else if (val == FLASH_SUBTYPE_4CH_VAL) {
 		flash_data->hw_type = QCOM_MVFLASH_4CH;
 		flash_data->max_channels = 4;

-- 
2.34.1

