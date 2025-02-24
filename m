From: Aaron Kling <webgeek1234@gmail.com>
Date: Mon, 24 Feb 2025 12:39:48 -0600
Subject: [PATCH] mfd: max77620: Allow building as a module
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250224-max77620-module-v1-1-96eb22e9f266@gmail.com>
X-B4-Tracking: v=1; b=H4sIAPS8vGcC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDIyMT3dzECnNzMyMD3dz8lNKcVF0Lk6TUVANDyySDREsloK6CotS0zAq
 widGxtbUANxYYmmEAAAA=
X-Change-ID: 20250224-max77620-module-84bee019b0a9
To: Lee Jones <lee@kernel.org>
Cc: linux-kernel@vger.kernel.org, Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1740422403; l=1436;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=+r4q7w35q/PUW+4DTP800ohxi4hzqBWXk37ruWNqFeU=;
 b=arAMSc8xvewZ6BcSWy7gonvoCNgyjMMMvOf/TwbKy6sRhU+0vTk7Rp5wkXOsVAk/5auLjFwZ7
 xOpOtRxttmmBlNNa6LPb808YyA/UbHgLmcgiF3YiDyOzpPhGxP7V7+u
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The driver works fine as a module, so allowing building as such.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 drivers/mfd/Kconfig    | 2 +-
 drivers/mfd/max77620.c | 4 ++++
 2 files changed, 5 insertions(+), 1 deletion(-)

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
index 89b30ef91f4f112b06e0e055e75e480fab176f8f..10264fce95a4a37f22f205edbf364fa6783e35dd 100644
--- a/drivers/mfd/max77620.c
+++ b/drivers/mfd/max77620.c
@@ -700,3 +700,7 @@ static struct i2c_driver max77620_driver = {
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

