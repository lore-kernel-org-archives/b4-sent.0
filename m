From: Robert Ijtsma <robertijtsma@gmail.com>
Date: Sat, 28 Nov 2026 21:41:07 +0100
Subject: [PATCH v2 1/3] media: i2c: ov7251: wait for software reset before
 global init
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261128-ov7251-strobe-ncont-v2-1-9428bbb6347e@gmail.com>
References: <20261128-ov7251-strobe-ncont-v2-0-9428bbb6347e@gmail.com>
In-Reply-To: <20261128-ov7251-strobe-ncont-v2-0-9428bbb6347e@gmail.com>
To: Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Jacopo Mondi <jacopo@jmondi.org>, Todor Tomov <todor.too@gmail.com>
Cc: Antoine Pichot <antoine.pichot@gmail.com>, 
 Dave Stevenson <dave.stevenson@raspberrypi.com>, 
 linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Robert Ijtsma <robertijtsma@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795898468; l=2318;
 i=robertijtsma@gmail.com; s=20261122; h=from:subject:message-id;
 bh=EHC/aveA6Auo7eKFp/aG412O4BPmyi+3DLt/cZMOFPw=;
 b=mGsg+I5eqZD610E9BKujD70Z2HvyW/SxHyVWgocMWgZd51F3u0wcTLeujFdoN02TVEvBTjtVA
 f24Xvh5q5iUDY4NVDbmTIng8VCzot5lEoYQXmY7pqMEKIGMBvGdWGW5
X-Developer-Key: i=robertijtsma@gmail.com; a=ed25519;
 pk=qiDyKVqFicxFIR5sB5m+p9SWPKL2/+mMoiQnUx0C9P0=
X-Endpoint-Received: by B4 Relay for robertijtsma@gmail.com/20261122 with auth_id=1604
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ov7251_set_power_on() writes software reset (0x0103 = 0x01) as the first
entry of ov7251_global_init_setting[] and immediately follows it with
the remaining common initialization registers.

Issue OV7251_SC_SOFTWARE_RESET explicitly and wait 5-10 ms for the
sensor to finish resetting before writing ov7251_global_init_setting[]
so subsequent I2C writes are not NACKed or lost during reset.

Fixes: d30bb512da3d ("media: Add a driver for the ov7251 camera sensor")
Signed-off-by: Robert Ijtsma <robertijtsma@gmail.com>
---
 drivers/media/i2c/ov7251.c | 21 ++++++++++++++++-----
 1 file changed, 16 insertions(+), 5 deletions(-)

diff --git a/drivers/media/i2c/ov7251.c b/drivers/media/i2c/ov7251.c
index 9e9bbee998ad..393260929f29 100644
--- a/drivers/media/i2c/ov7251.c
+++ b/drivers/media/i2c/ov7251.c
@@ -30,6 +30,8 @@
 #define OV7251_SC_MODE_SELECT		0x0100
 #define OV7251_SC_MODE_SELECT_SW_STANDBY	0x0
 #define OV7251_SC_MODE_SELECT_STREAMING		0x1
+#define OV7251_SC_SOFTWARE_RESET	0x0103
+#define OV7251_SC_SOFTWARE_RESET_ASSERT	0x01
 
 #define OV7251_CHIP_ID_HIGH		0x300a
 #define OV7251_CHIP_ID_HIGH_BYTE	0x77
@@ -248,7 +250,6 @@ static const struct ov7251_pll_cfgs *ov7251_pll_cfgs[] = {
 };
 
 static const struct reg_value ov7251_global_init_setting[] = {
-	{ 0x0103, 0x01 },
 	{ 0x303b, 0x02 },
 	{ 0x3005, 0x00 },
 	{ 0x3012, 0xc0 },
@@ -698,17 +699,27 @@ static int ov7251_set_power_on(struct device *dev)
 			       DIV_ROUND_UP(ov7251->xclk_freq, 1000));
 	usleep_range(wait_us, wait_us + 1000);
 
+	ret = ov7251_write_reg(ov7251, OV7251_SC_SOFTWARE_RESET,
+			       OV7251_SC_SOFTWARE_RESET_ASSERT);
+	if (ret < 0)
+		goto err_power_off;
+
+	usleep_range(5000, 10000);
+
 	ret = ov7251_set_register_array(ov7251,
 					ov7251_global_init_setting,
 					ARRAY_SIZE(ov7251_global_init_setting));
 	if (ret < 0) {
 		dev_err(ov7251->dev, "error during global init\n");
-		gpiod_set_value_cansleep(ov7251->enable_gpio, 0);
-		clk_disable_unprepare(ov7251->xclk);
-		ov7251_regulators_disable(ov7251);
-		return ret;
+		goto err_power_off;
 	}
 
+	return 0;
+
+err_power_off:
+	gpiod_set_value_cansleep(ov7251->enable_gpio, 0);
+	clk_disable_unprepare(ov7251->xclk);
+	ov7251_regulators_disable(ov7251);
 	return ret;
 }
 

-- 
2.56.0

