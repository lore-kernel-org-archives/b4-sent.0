From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Tue, 22 Jul 2025 19:30:48 +0800
Subject: [PATCH v2] rtc: amlogic-a4: Optimize global variables
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250722-rtc-regmap-v2-1-58bc17187a11@amlogic.com>
X-B4-Tracking: v=1; b=H4sIAGd2f2gC/23MQQ7CIBCF4as0sxYDVMV25T1MF0CndBIpDTRE0
 3B3sWuX/0vet0PCSJigb3aImClRWGrIUwN21otDRmNtkFxeuRKKxc2yiM7rlYkLR2zvRplJQT2
 sESd6H9hzqD1T2kL8HHYWv/UvkwUTTI+iU+3NWsO7h/av4MiebfAwlFK+9U/PgqYAAAA=
To: Yiting Deng <yiting.deng@amlogic.com>, 
 Alexandre Belloni <alexandre.belloni@bootlin.com>
Cc: linux-amlogic@lists.infradead.org, linux-rtc@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1753183848; l=1493;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=9dM7dYiSAIYeWx8dG0E9yLzdI2cirE8OM6/rYACd5eg=;
 b=tn0iCa4/fCE+b5om7zwj5nHT9XwVZ+HF0aeqTeNuyh4Iwxx4lPfDBh6ojC8BzTqjKxGyEf9oT
 hd+6OIsagGNCQt1jqbiC+ZBDzTD3FgftuTHRbqZVx5rBRlSu1QFtB3K
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Convert a global variable into a local one of aml_rtc_probe().

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
Convert a global variable into a local one of aml_rtc_probe().
---
Changes in v2:
- Modify the submission description.
- Link to v1: https://lore.kernel.org/r/20250717-rtc-regmap-v1-1-ad19736ccb09@amlogic.com
---
 drivers/rtc/rtc-amlogic-a4.c | 14 +++++++-------
 1 file changed, 7 insertions(+), 7 deletions(-)

diff --git a/drivers/rtc/rtc-amlogic-a4.c b/drivers/rtc/rtc-amlogic-a4.c
index 09d78c2cc691..1928b29c1045 100644
--- a/drivers/rtc/rtc-amlogic-a4.c
+++ b/drivers/rtc/rtc-amlogic-a4.c
@@ -72,13 +72,6 @@ struct aml_rtc_data {
 	const struct aml_rtc_config *config;
 };
 
-static const struct regmap_config aml_rtc_regmap_config = {
-	.reg_bits = 32,
-	.val_bits = 32,
-	.reg_stride = 4,
-	.max_register = RTC_REAL_TIME,
-};
-
 static inline u32 gray_to_binary(u32 gray)
 {
 	u32 bcd = gray;
@@ -328,6 +321,13 @@ static int aml_rtc_probe(struct platform_device *pdev)
 	void __iomem *base;
 	int ret = 0;
 
+	const struct regmap_config aml_rtc_regmap_config = {
+		.reg_bits = 32,
+		.val_bits = 32,
+		.reg_stride = 4,
+		.max_register = RTC_REAL_TIME,
+	};
+
 	rtc = devm_kzalloc(dev, sizeof(*rtc), GFP_KERNEL);
 	if (!rtc)
 		return -ENOMEM;

---
base-commit: 0bafe291cb429d39b5ff70bcf7b2f3ab026dcb02
change-id: 20250717-rtc-regmap-140ee38b7bf7

Best regards,
-- 
Xianwei Zhao <xianwei.zhao@amlogic.com>

