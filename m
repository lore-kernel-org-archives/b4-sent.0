From: Nuno Sa <nuno.sa@analog.com>
Date: Wed, 08 Jan 2025 16:44:23 +0000
Subject: [PATCH] hwmon: (pmbus/max15301): add support for MAX15303
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250108-dev-max15303-v1-1-9154eb2c9d9e@analog.com>
X-B4-Tracking: v=1; b=H4sIAGarfmcC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDQwML3ZTUMt3cxApDU2MDY93UZNM0S7OU5KRUyyQloJaCotS0zAqwcdG
 xtbUAJnOORV4AAAA=
X-Change-ID: 20250108-dev-max15303-ec5f96dcbe9b
To: linux-hwmon@vger.kernel.org, linux-doc@vger.kernel.org
Cc: Daniel Nilsson <daniel.nilsson@flex.com>, 
 Jean Delvare <jdelvare@suse.com>, Guenter Roeck <linux@roeck-us.net>, 
 Jonathan Corbet <corbet@lwn.net>, 
 Delphine CC Chiu <Delphine_CC_Chiu@Wiwynn.com>, 
 Robin Getz <rgetz503@gmail.com>, Erik Rosen <erik.rosen@metormote.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1736354673; l=2244;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=phBtWv0JmSXD1jmhsvkWUdoTzfmFQsSMU7yBfuZFESo=;
 b=Ap9HKOT5a++EFRAYJRnCQ68XtDUslwWqw5r93RK23dXVBExyHuZbp6iP6iwgpeCoie3HC8fK9
 BLdQZKGxnvMC55d3aYaW4fmc3QwicGkTqA/1Yj4yTW0C0f4e4R7q62A
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The MAX15303 is a full-featured, flexible, efficient, 6A digital
point-of-load (PoL) controller with integrated switching MOSFETs. It
contains advanced power management and telemetry features.

Tested-by: Robin Getz <rgetz503@gmail.com>
Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 Documentation/hwmon/max15301.rst | 8 ++++++++
 drivers/hwmon/pmbus/Kconfig      | 2 +-
 drivers/hwmon/pmbus/max15301.c   | 1 +
 3 files changed, 10 insertions(+), 1 deletion(-)

diff --git a/Documentation/hwmon/max15301.rst b/Documentation/hwmon/max15301.rst
index e3dc22fe1c6d0035593e59481a610452eec8abf9..e2222e98304fda5885b94bc37c0f1f16474ed271 100644
--- a/Documentation/hwmon/max15301.rst
+++ b/Documentation/hwmon/max15301.rst
@@ -13,6 +13,14 @@ Supported chips:
 
     Datasheet: https://datasheets.maximintegrated.com/en/ds/MAX15301.pdf
 
+  * Maxim MAX15303
+
+    Prefix: 'max15303'
+
+    Addresses scanned: -
+
+    Datasheet: https://www.analog.com/media/en/technical-documentation/data-sheets/max15303.pdf
+
 Author: Erik Rosen <erik.rosen@metormote.com>
 
 
diff --git a/drivers/hwmon/pmbus/Kconfig b/drivers/hwmon/pmbus/Kconfig
index 233533e28f7678c41bc1973ebcc3b53b10854baf..419469f40ba0283c72b71071566efec575263e98 100644
--- a/drivers/hwmon/pmbus/Kconfig
+++ b/drivers/hwmon/pmbus/Kconfig
@@ -260,7 +260,7 @@ config SENSORS_MAX15301
 	tristate "Maxim MAX15301"
 	help
 	  If you say yes here you get hardware monitoring support for Maxim
-	  MAX15301, as well as for Flex BMR461.
+	  MAX15301, MAX15303, as well as for Flex BMR461.
 
 	  This driver can also be built as a module. If so, the module will
 	  be called max15301.
diff --git a/drivers/hwmon/pmbus/max15301.c b/drivers/hwmon/pmbus/max15301.c
index 50dfd477772ffe680446b5c0bf31d45a70042d27..d5810b88ea8d8dad151e2597da205dbab6155ae1 100644
--- a/drivers/hwmon/pmbus/max15301.c
+++ b/drivers/hwmon/pmbus/max15301.c
@@ -25,6 +25,7 @@
 static const struct i2c_device_id max15301_id[] = {
 	{ "bmr461" },
 	{ "max15301" },
+	{ "max15303" },
 	{}
 };
 MODULE_DEVICE_TABLE(i2c, max15301_id);

---
base-commit: adc52dd4078067fabf1431036ba180eafd8a7eee
change-id: 20250108-dev-max15303-ec5f96dcbe9b
--

Thanks!
- Nuno Sá

