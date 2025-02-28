From: Aaron Kling <webgeek1234@gmail.com>
Date: Fri, 28 Feb 2025 09:24:26 -0600
Subject: [PATCH v2] mfd: max77620: Allow building as a module
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250228-max77620-module-v2-1-eb686216437c@gmail.com>
X-B4-Tracking: v=1; b=H4sIACnVwWcC/3WNQQ6CMBBFr0JmbU07wWJdeQ/DooUBJqHUtEowp
 He3snf5XvLf3yFRZEpwq3aItHLisBTAUwXdZJeRBPeFASVeJGItvN2aRqMUPvTvmcS1dkRSGSe
 tgbJ6Rhp4O4qPtvDE6RXi5zhY1c/+b61KKGE0OUQyA2p9H73l+dwFD23O+Qv+gujRrgAAAA==
X-Change-ID: 20250224-max77620-module-84bee019b0a9
To: Lee Jones <lee@kernel.org>
Cc: linux-kernel@vger.kernel.org, Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1740756273; l=1796;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=OT0FIDuDw3FGa5/XqyJt2qY/plz7HsCO8qtwF054Yxg=;
 b=DRFB1K+kfx5CalIeF1Lk99Ksmxn+8F6Js6l67aOGZq8tyTSDoS5w4KjK5dq+71lOqOGxmXFIz
 KpoxQVKK7c4AzNFlcgUehTLkcb0c9rAxhna6sbeFjG109OLqaHbqZXY
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The driver works fine as a module, so allowing building as such.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
Changes in v2:
- Include module.h directly
- Link to v1: https://lore.kernel.org/r/20250224-max77620-module-v1-1-96eb22e9f266@gmail.com
---
 drivers/mfd/Kconfig    | 2 +-
 drivers/mfd/max77620.c | 5 +++++
 2 files changed, 6 insertions(+), 1 deletion(-)

diff --git a/drivers/mfd/Kconfig b/drivers/mfd/Kconfig
index 6b0682af6e32b434ee3e99940005a6cce14ff55c..922704bd0ce3fe6c094da6b1528b72fedcfa1677 100644
--- a/drivers/mfd/Kconfig
+++ b/drivers/mfd/Kconfig
@@ -858,7 +858,7 @@ config MFD_MAX77541
 	  There are regulators and adc.
 
 config MFD_MAX77620
-	bool "Maxim Semiconductor MAX77620 and MAX20024 PMIC Support"
+	tristate "Maxim Semiconductor MAX77620 and MAX20024 PMIC Support"
 	depends on I2C=y
 	depends on OF
 	select MFD_CORE
diff --git a/drivers/mfd/max77620.c b/drivers/mfd/max77620.c
index 89b30ef91f4f112b06e0e055e75e480fab176f8f..21d2ab3db2542ef8bcbd82262ac1fbd1dfdbce5c 100644
--- a/drivers/mfd/max77620.c
+++ b/drivers/mfd/max77620.c
@@ -29,6 +29,7 @@
 #include <linux/mfd/core.h>
 #include <linux/mfd/max77620.h>
 #include <linux/init.h>
+#include <linux/module.h>
 #include <linux/of.h>
 #include <linux/regmap.h>
 #include <linux/slab.h>
@@ -700,3 +701,7 @@ static struct i2c_driver max77620_driver = {
 	.id_table = max77620_id,
 };
 builtin_i2c_driver(max77620_driver);
+
+MODULE_DESCRIPTION("Maxim Semiconductor MAX77620 and MAX20024 PMIC Support");
+MODULE_AUTHOR("Laxman Dewangan <ldewangan@nvidia.com>");
+MODULE_LICENSE("GPL");

---
base-commit: d082ecbc71e9e0bf49883ee4afd435a77a5101b6
change-id: 20250224-max77620-module-84bee019b0a9

Best regards,
-- 
Aaron Kling <webgeek1234@gmail.com>

