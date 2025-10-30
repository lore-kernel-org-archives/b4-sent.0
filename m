From: Cryolitia PukNgae <cryolitia@uniontech.com>
Date: Thu, 30 Oct 2025 22:30:06 +0800
Subject: [PATCH] hwmon: (gpd-fan) initialize EC on driver load for Win 4
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251030-win4-v1-1-c374dcb86985@uniontech.com>
X-B4-Tracking: v=1; b=H4sIAG12A2kC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1NDA2MD3fLMPBNds2RzS/M0c0Njy2RjJaDSgqLUtMwKsDHRsbW1AFWYAzx
 WAAAA
X-Change-ID: 20251030-win4-6c797f7139c3
To: Guenter Roeck <linux@roeck-us.net>
Cc: linux-hwmon@vger.kernel.org, linux-kernel@vger.kernel.org, 
 niecheng1@uniontech.com, zhanjun@uniontech.com, 
 kylon <3252255+kylon@users.noreply.github.com>, 
 Cryolitia PukNgae <cryolitia@uniontech.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1761834613; l=3221;
 i=cryolitia@uniontech.com; s=20250730; h=from:subject:message-id;
 bh=t9JHAfOJItGPrnrOdS2gWLJmFHa2xGmsXuMmQl261Mc=;
 b=VJe5rhI5SINpl2JRyT2gfD/kTIfCcZhnjPEjVNBEvAczGJAK/pU/tvII8a51AFt+LFH0z1wcm
 bLoGxuRsI5LB0OLOsb8G1ZQ3O7RQXL7XEZZzgzFtqera1QEDHc9FF2k
X-Developer-Key: i=cryolitia@uniontech.com; a=ed25519;
 pk=tZ+U+kQkT45GRGewbMSB4VPmvpD+KkHC/Wv3rMOn/PU=
X-Endpoint-Received: by B4 Relay for cryolitia@uniontech.com/20250730 with auth_id=474
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The original implement will re-init the EC when it reports a zero
value, and it's a workaround for the black box buggy firmware.

Now a contributer test and report that, the bug is that, the firmware
won't initialize the EC on boot, so the EC ramains in unusable status.
And it won't need to re-init it during runtime. The original implement
is not perfect, any write command will be ignored until we first read
it. Just re-init it unconditionally when the driver load could work.

Fixes: 0ab88e239439 ("hwmon: add GPD devices sensor driver")
Co-developed-by: kylon <3252255+kylon@users.noreply.github.com>
Signed-off-by: kylon <3252255+kylon@users.noreply.github.com>
Link: https://github.com/Cryolitia/gpd-fan-driver/pull/20
Signed-off-by: Cryolitia PukNgae <cryolitia@uniontech.com>
---
 drivers/hwmon/gpd-fan.c | 52 ++++++++++++++++++++++++-------------------------
 1 file changed, 25 insertions(+), 27 deletions(-)

diff --git a/drivers/hwmon/gpd-fan.c b/drivers/hwmon/gpd-fan.c
index 57caae9a23eb..43ec092fc26e 100644
--- a/drivers/hwmon/gpd-fan.c
+++ b/drivers/hwmon/gpd-fan.c
@@ -273,31 +273,6 @@ static int gpd_generic_read_rpm(void)
 	return (u16)high << 8 | low;
 }
 
-static void gpd_win4_init_ec(void)
-{
-	u8 chip_id, chip_ver;
-
-	gpd_ecram_read(0x2000, &chip_id);
-
-	if (chip_id == 0x55) {
-		gpd_ecram_read(0x1060, &chip_ver);
-		gpd_ecram_write(0x1060, chip_ver | 0x80);
-	}
-}
-
-static int gpd_win4_read_rpm(void)
-{
-	int ret;
-
-	ret = gpd_generic_read_rpm();
-
-	if (ret == 0)
-		// Re-init EC when speed is 0
-		gpd_win4_init_ec();
-
-	return ret;
-}
-
 static int gpd_wm2_read_rpm(void)
 {
 	for (u16 pwm_ctr_offset = GPD_PWM_CTR_OFFSET;
@@ -317,11 +292,10 @@ static int gpd_wm2_read_rpm(void)
 static int gpd_read_rpm(void)
 {
 	switch (gpd_driver_priv.drvdata->board) {
+	case win4_6800u:
 	case win_mini:
 	case duo:
 		return gpd_generic_read_rpm();
-	case win4_6800u:
-		return gpd_win4_read_rpm();
 	case win_max_2:
 		return gpd_wm2_read_rpm();
 	}
@@ -577,6 +551,28 @@ static struct hwmon_chip_info gpd_fan_chip_info = {
 	.info = gpd_fan_hwmon_channel_info
 };
 
+static void gpd_win4_init_ec(void)
+{
+	u8 chip_id, chip_ver;
+
+	gpd_ecram_read(0x2000, &chip_id);
+
+	if (chip_id == 0x55) {
+		gpd_ecram_read(0x1060, &chip_ver);
+		gpd_ecram_write(0x1060, chip_ver | 0x80);
+	}
+}
+
+static void gpd_init_ec(void)
+{
+	// The buggy firmware won't initialize EC properly on boot.
+	// Before its initialization, reading RPM will always return 0,
+	// and writing PWM will have no effect.
+	// Initialize it manually on driver load.
+	if (gpd_driver_priv.drvdata->board == win4_6800u)
+		gpd_win4_init_ec();
+}
+
 static int gpd_fan_probe(struct platform_device *pdev)
 {
 	struct device *dev = &pdev->dev;
@@ -604,6 +600,8 @@ static int gpd_fan_probe(struct platform_device *pdev)
 		return dev_err_probe(dev, PTR_ERR(region),
 				     "Failed to register hwmon device\n");
 
+	gpd_init_ec();
+
 	return 0;
 }
 

---
base-commit: 65bc97a5e49ea4174ba7e89afdada3e30e6e39c0
change-id: 20251030-win4-6c797f7139c3

Best regards,
-- 
Cryolitia PukNgae <cryolitia@uniontech.com>

