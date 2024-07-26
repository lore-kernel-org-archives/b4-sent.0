From: Nuno Sa <nuno.sa@analog.com>
Date: Fri, 26 Jul 2024 14:07:33 +0200
Subject: [PATCH] hwmon: ltc2947: move to firmware agnostic API
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20240726-dev-hwmon-ltc6947-fw-agnostic-v1-1-f7d6cab7d438@analog.com>
X-B4-Tracking: v=1; b=H4sIAISRo2YC/x3MQQqAIBAAwK/Enlso06K+Eh1C11ooDY0Kwr8nH
 ecyL0QKTBGG4oVAF0f2LqMuC9Dr7BZCNtkgKiGrTrRo6ML13r3D7dRtLzu0N86L8/FkjbqWfaO
 IlDIK8nEEsvz8/zil9AE+AsT+bwAAAA==
To: linux-hwmon@vger.kernel.org
Cc: Jean Delvare <jdelvare@suse.com>, Guenter Roeck <linux@roeck-us.net>
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1721995652; l=2700;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=eHEIw/BFCLR3h2Cjnfq7/AwNP2mxs1wE4zIYao0bqAM=;
 b=h8f8UOeiF7FPrCtPK1LKztf2a9WF0sORR+X5LuPzTUw0QvrSFQ6uJ+cB5XM3XkwInxWiek9g3
 l1WRgGeUWstA9zwOceF7g4YX56cK8+JO5X8jR9fodJ24NgLxGIAx+F8
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Use the device property APIs so the driver does not depend on OF to
work.

While at it, properly include mod_devicetable for struct of_device_id
and fix some parameter alignment in the changed places.

Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 drivers/hwmon/ltc2947-core.c | 20 ++++++++++----------
 1 file changed, 10 insertions(+), 10 deletions(-)

diff --git a/drivers/hwmon/ltc2947-core.c b/drivers/hwmon/ltc2947-core.c
index d2ff6e700770d..244839167e51c 100644
--- a/drivers/hwmon/ltc2947-core.c
+++ b/drivers/hwmon/ltc2947-core.c
@@ -11,7 +11,8 @@
 #include <linux/hwmon.h>
 #include <linux/hwmon-sysfs.h>
 #include <linux/module.h>
-#include <linux/of.h>
+#include <linux/mod_devicetable.h>
+#include <linux/property.h>
 #include <linux/regmap.h>
 
 #include "ltc2947.h"
@@ -1034,9 +1035,8 @@ static int ltc2947_setup(struct ltc2947_data *st)
 		/* 19.89E-6 * 10E9 */
 		st->lsb_energy = 19890;
 	}
-	ret = of_property_read_u32_array(st->dev->of_node,
-					 "adi,accumulator-ctl-pol", accum,
-					  ARRAY_SIZE(accum));
+	ret = device_property_read_u32_array(st->dev, "adi,accumulator-ctl-pol",
+					     accum, ARRAY_SIZE(accum));
 	if (!ret) {
 		u32 accum_reg = LTC2947_ACCUM_POL_1(accum[0]) |
 				LTC2947_ACCUM_POL_2(accum[1]);
@@ -1045,9 +1045,9 @@ static int ltc2947_setup(struct ltc2947_data *st)
 		if (ret)
 			return ret;
 	}
-	ret = of_property_read_u32(st->dev->of_node,
-				   "adi,accumulation-deadband-microamp",
-				   &deadband);
+	ret = device_property_read_u32(st->dev,
+				       "adi,accumulation-deadband-microamp",
+				       &deadband);
 	if (!ret) {
 		/* the LSB is the same as the current, so 3mA */
 		ret = regmap_write(st->map, LTC2947_REG_ACCUM_DEADBAND,
@@ -1056,7 +1056,7 @@ static int ltc2947_setup(struct ltc2947_data *st)
 			return ret;
 	}
 	/* check gpio cfg */
-	ret = of_property_read_u32(st->dev->of_node, "adi,gpio-out-pol", &pol);
+	ret = device_property_read_u32(st->dev, "adi,gpio-out-pol", &pol);
 	if (!ret) {
 		/* setup GPIO as output */
 		u32 gpio_ctl = LTC2947_GPIO_EN(1) | LTC2947_GPIO_FAN_EN(1) |
@@ -1067,8 +1067,8 @@ static int ltc2947_setup(struct ltc2947_data *st)
 		if (ret)
 			return ret;
 	}
-	ret = of_property_read_u32_array(st->dev->of_node, "adi,gpio-in-accum",
-					 accum, ARRAY_SIZE(accum));
+	ret = device_property_read_u32_array(st->dev, "adi,gpio-in-accum",
+					     accum, ARRAY_SIZE(accum));
 	if (!ret) {
 		/*
 		 * Setup the accum options. The gpioctl is already defined as

---
base-commit: 1ea3fd1eb9869fcdcbc9c68f9728bfc47b9503f1
change-id: 20240726-dev-hwmon-ltc6947-fw-agnostic-c14935ee55d5
--

Thanks!
- Nuno Sá

