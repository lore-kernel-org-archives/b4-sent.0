From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Wed, 15 Oct 2025 15:52:20 +0100
Subject: [PATCH 2/3] hwmon: (adt7410): Add OF match table
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20251015-dev-add-adt7422-v1-2-7cf72d3253ad@analog.com>
References: <20251015-dev-add-adt7422-v1-0-7cf72d3253ad@analog.com>
In-Reply-To: <20251015-dev-add-adt7422-v1-0-7cf72d3253ad@analog.com>
To: devicetree@vger.kernel.org, linux-hwmon@vger.kernel.org
Cc: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Guenter Roeck <linux@roeck-us.net>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1760539940; l=1194;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=7sL+98Md+Y1xcPK1N48brv525Wll0lT1p5c+ZrwrMOk=;
 b=vhGach9wi36WGpvVh+StfFdXw29vJvXVWHQXf7NaFggo/RXL2Zbs7XD15dJdZ3EC1+T4AfqNG
 gwifpPXatFxAbudGZvgXRP1oLZ2S/1ApJ8u5HHk/bIjy0kfvQwEpV1G
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a struct of_device_id match table to the driver.

While at it, make sure to properly include mod_devicetable.h which is
also needed for struct i2c_device_id.

Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
 drivers/hwmon/adt7410.c | 9 +++++++++
 1 file changed, 9 insertions(+)

diff --git a/drivers/hwmon/adt7410.c b/drivers/hwmon/adt7410.c
index 3bf0e0a0882c..79952866a4db 100644
--- a/drivers/hwmon/adt7410.c
+++ b/drivers/hwmon/adt7410.c
@@ -7,6 +7,7 @@
  */
 
 #include <linux/module.h>
+#include <linux/mod_devicetable.h>
 #include <linux/init.h>
 #include <linux/i2c.h>
 #include <linux/regmap.h>
@@ -94,10 +95,18 @@ static const struct i2c_device_id adt7410_ids[] = {
 };
 MODULE_DEVICE_TABLE(i2c, adt7410_ids);
 
+static const struct of_device_id adt7410_of_match[] = {
+	{ .compatible = "adi,adt7410" },
+	{ .compatible = "adi,adt7420" },
+	{ }
+};
+MODULE_DEVICE_TABLE(of, adt7410_of_match);
+
 static struct i2c_driver adt7410_driver = {
 	.driver = {
 		.name	= "adt7410",
 		.pm	= pm_sleep_ptr(&adt7x10_dev_pm_ops),
+		.of_match_table = adt7410_of_match,
 	},
 	.probe		= adt7410_i2c_probe,
 	.id_table	= adt7410_ids,

-- 
2.51.0

