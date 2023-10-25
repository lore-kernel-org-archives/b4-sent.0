From: Richard Leitner <richard.leitner@linux.dev>
Date: Wed, 25 Oct 2023 10:34:13 +0000
Subject: [PATCH 3/4] hwmon: ina238: add ina237 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20231025-ina237-v1-3-a0196119720c@linux.dev>
References: <20231025-ina237-v1-0-a0196119720c@linux.dev>
In-Reply-To: <20231025-ina237-v1-0-a0196119720c@linux.dev>
To: Guenter Roeck <linux@roeck-us.net>, Jean Delvare <jdelvare@suse.com>, 
 Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-kernel@vger.kernel.org, linux-hwmon@vger.kernel.org, 
 devicetree@vger.kernel.org, Richard Leitner <richard.leitner@linux.dev>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1698230088; l=1834;
 i=richard.leitner@linux.dev; s=20231025; h=from:subject:message-id;
 bh=DtHEPpID31tWjOLNIsg0s4zUFeieNUVEZ4/N6Xx8pBg=;
 b=cbexpn9jwDnLm+iezslfz1ab3VC6XgcxtDK5rB8jqIMYOYfLU10JVG6RexSObUWxYfv/lSVZWjUN
 mndptX2xClpQW5585VXATi/o+DZCXtdCE+kJlqIZpCmvIIwi3Ljr
X-Developer-Key: i=richard.leitner@linux.dev; a=ed25519;
 pk=ZYa5+0m9RFYtnNU6DLet7sHyPehnVHa0ucJlYiAu2NU=
X-Endpoint-Received: by B4 Relay for richard.leitner@linux.dev/20231025 with auth_id=90
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The INA237 "85-V, 16-Bit, Precision Power Monitor With I2C Interface" is
basically the same as INA328. Therefore add a corresponding compatible
to the driver.

According to the datasheet the main difference is the current and power
monitoring accuracy:

+------------------------+---------------+---------------+
|                        | INA238        | INA237        |
+------------------------+---------------+---------------+
| Offset voltage         | +/- 5µV       | +/- 50µV      |
| Offset drift           | +/- 0.02µV/°C | +/- 0.02µV/°C |
| Gain error             | +/- 0.1%      | +/- 0.3%      |
| Gain error drift       | +/- 25ppm/°C  | +/- 50ppm/°C  |
| Common mode rejection  | 140dB         | 120dB         |
| Power accuracy         | 0.7%          | 1.6%          |
+------------------------+---------------+---------------+

As well as the missing DEVICE_ID register at 0x3F, which is currently
not in use by the driver.

Signed-off-by: Richard Leitner <richard.leitner@linux.dev>
---
 drivers/hwmon/ina238.c | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/drivers/hwmon/ina238.c b/drivers/hwmon/ina238.c
index f519c22d3907..ca9f5d2c811b 100644
--- a/drivers/hwmon/ina238.c
+++ b/drivers/hwmon/ina238.c
@@ -33,7 +33,7 @@
 #define INA238_BUS_UNDER_VOLTAGE	0xf
 #define INA238_TEMP_LIMIT		0x10
 #define INA238_POWER_LIMIT		0x11
-#define INA238_DEVICE_ID		0x3f
+#define INA238_DEVICE_ID		0x3f /* not available on INA237 */
 
 #define INA238_CONFIG_ADCRANGE		BIT(4)
 
@@ -622,6 +622,7 @@ static const struct i2c_device_id ina238_id[] = {
 MODULE_DEVICE_TABLE(i2c, ina238_id);
 
 static const struct of_device_id __maybe_unused ina238_of_match[] = {
+	{ .compatible = "ti,ina237" },
 	{ .compatible = "ti,ina238" },
 	{ },
 };

-- 
2.40.1

