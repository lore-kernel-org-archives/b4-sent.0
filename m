From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Wed, 15 Oct 2025 15:52:21 +0100
Subject: [PATCH 3/3] hwmon: (adt7410): Support adt7422 chip
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20251015-dev-add-adt7422-v1-3-7cf72d3253ad@analog.com>
References: <20251015-dev-add-adt7422-v1-0-7cf72d3253ad@analog.com>
In-Reply-To: <20251015-dev-add-adt7422-v1-0-7cf72d3253ad@analog.com>
To: devicetree@vger.kernel.org, linux-hwmon@vger.kernel.org
Cc: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Guenter Roeck <linux@roeck-us.net>, 
 Cosmin Tanislav <demonsingur@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1760539940; l=2189;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=kRPkAzRSj0YVbwruCoHvC/DO1myQ3X+DgwaNSnHWKAc=;
 b=HGgxTpLGceqpY0VXpBuDmxitaHIc4idapwqTECPU49Nj7R2vD/4fxjRJSBroRvbK8gYezsVOn
 li0H5N8+OvGDzp4S1Wj14Dehk2HDM34S2fxbF4pVtbL/fIQbBhGS58I
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support for the ADT7422 high accuracy digital temperature sensor. It's
identical to the other chips supported in the driver so we just need to
add it to the ID tables.

Co-developed-by: Cosmin Tanislav <demonsingur@gmail.com>
Signed-off-by: Cosmin Tanislav <demonsingur@gmail.com>
Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
 drivers/hwmon/Kconfig   | 6 +++---
 drivers/hwmon/adt7410.c | 2 ++
 2 files changed, 5 insertions(+), 3 deletions(-)

diff --git a/drivers/hwmon/Kconfig b/drivers/hwmon/Kconfig
index 2760feb9f83b..aa783be9b73d 100644
--- a/drivers/hwmon/Kconfig
+++ b/drivers/hwmon/Kconfig
@@ -175,7 +175,7 @@ config SENSORS_ADT7X10
 	select REGMAP
 	help
 	  This module contains common code shared by the ADT7310/ADT7320 and
-	  ADT7410/ADT7420 temperature monitoring chip drivers.
+	  ADT7410/ADT7420/ADT7422 temperature monitoring chip drivers.
 
 	  If built as a module, the module will be called adt7x10.
 
@@ -191,12 +191,12 @@ config SENSORS_ADT7310
 	  will be called adt7310.
 
 config SENSORS_ADT7410
-	tristate "Analog Devices ADT7410/ADT7420"
+	tristate "Analog Devices ADT7410/ADT7420/ADT7422"
 	depends on I2C
 	select SENSORS_ADT7X10
 	help
 	  If you say yes here you get support for the Analog Devices
-	  ADT7410 and ADT7420 temperature monitoring chips.
+	  ADT7410, ADT7420 and ADT7422 temperature monitoring chips.
 
 	  This driver can also be built as a module. If so, the module
 	  will be called adt7410.
diff --git a/drivers/hwmon/adt7410.c b/drivers/hwmon/adt7410.c
index 79952866a4db..73b196a78f3a 100644
--- a/drivers/hwmon/adt7410.c
+++ b/drivers/hwmon/adt7410.c
@@ -91,6 +91,7 @@ static int adt7410_i2c_probe(struct i2c_client *client)
 static const struct i2c_device_id adt7410_ids[] = {
 	{ "adt7410" },
 	{ "adt7420" },
+	{ "adt7422" },
 	{}
 };
 MODULE_DEVICE_TABLE(i2c, adt7410_ids);
@@ -98,6 +99,7 @@ MODULE_DEVICE_TABLE(i2c, adt7410_ids);
 static const struct of_device_id adt7410_of_match[] = {
 	{ .compatible = "adi,adt7410" },
 	{ .compatible = "adi,adt7420" },
+	{ .compatible = "adi,adt7422" },
 	{ }
 };
 MODULE_DEVICE_TABLE(of, adt7410_of_match);

-- 
2.51.0

