From: Cryolitia PukNgae <cryolitia@uniontech.com>
Date: Wed, 24 Sep 2025 15:48:38 +0800
Subject: [PATCH] hwmon: (gpd-fan) complete Kconfig dependencies
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250924-hwmon2-v1-1-fc529865a325@uniontech.com>
X-B4-Tracking: v=1; b=H4sIAFWi02gC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDSyMT3Yzy3Pw8I92U5BSjREuTRHNzAxMloOKCotS0zAqwQdGxtbUA+Of
 MX1gAAAA=
X-Change-ID: 20250924-hwmon2-dcd2a94a7704
To: Guenter Roeck <linux@roeck-us.net>
Cc: linux-hwmon@vger.kernel.org, linux-kernel@vger.kernel.org, 
 zhanjun@uniontech.com, niecheng1@uniontech.com, 
 kernel test robot <lkp@intel.com>, 
 Cryolitia PukNgae <cryolitia@uniontech.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1758700119; l=963;
 i=cryolitia@uniontech.com; s=20250730; h=from:subject:message-id;
 bh=k4QkTC6YnHu5jzG67ZnVwUnYYgbwugDDSWlzXKmtp8c=;
 b=GE4DQ6Ez6OxCbnPuQZfoUP/YDOxmTdAdoEtsjcBlReQwni8cVkg1F4QXlpq8qKhLNX2KJ2j8k
 ehsMT3oZuZ7AW4hNM6cefixG+2G7/AALVKyj0GLj1jC3Oael1gIYR/9
X-Developer-Key: i=cryolitia@uniontech.com; a=ed25519;
 pk=tZ+U+kQkT45GRGewbMSB4VPmvpD+KkHC/Wv3rMOn/PU=
X-Endpoint-Received: by B4 Relay for cryolitia@uniontech.com/20250730 with auth_id=474
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

DMI and HAS_IOPORT is also needed

Reported-by: kernel test robot <lkp@intel.com>
Closes: https://lore.kernel.org/oe-kbuild-all/202509200214.i2QX7iwD-lkp@intel.com/
Signed-off-by: Cryolitia PukNgae <cryolitia@uniontech.com>
---
 drivers/hwmon/Kconfig | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/hwmon/Kconfig b/drivers/hwmon/Kconfig
index d6769288a76e81f79d2fdf4e6a9943db1466fa54..d61014d7968a4ab77c055a744837b106ae112aa3 100644
--- a/drivers/hwmon/Kconfig
+++ b/drivers/hwmon/Kconfig
@@ -771,7 +771,7 @@ config SENSORS_GL520SM
 
 config SENSORS_GPD
 	tristate "GPD handhelds"
-	depends on X86
+	depends on X86 && DMI && HAS_IOPORT
 	help
 	  If you say yes here you get support for fan readings and
 	  control over GPD handheld devices.

---
base-commit: 80038a758b7fc0cdb6987532cbbf3f75b13e0826
change-id: 20250924-hwmon2-dcd2a94a7704

Best regards,
-- 
Cryolitia PukNgae <cryolitia@uniontech.com>

