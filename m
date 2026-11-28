From: Robert Ijtsma <robertijtsma@gmail.com>
Date: Sat, 28 Nov 2026 21:41:09 +0100
Subject: [PATCH v2 3/3] media: i2c: ov7251: support non-continuous MIPI
 clock mode
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261128-ov7251-strobe-ncont-v2-3-9428bbb6347e@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795898468; l=1840;
 i=robertijtsma@gmail.com; s=20261122; h=from:subject:message-id;
 bh=iYMD7W8d2+XvLhklCu7QmGnta3lKpQRyUp4O5aryU5g=;
 b=N0ZHVAQ3vAg6B20XNwDYE40m6NRf02BF5CnT6goTJqdMqWYt4Q6uhRYthermGI3EglJl3yt7g
 NOcsVY+2t4eBnSGZQcKUbAWRMoiFxpQSvb42ArPDUFrHMXYL5/hEYc6
X-Developer-Key: i=robertijtsma@gmail.com; a=ed25519;
 pk=qiDyKVqFicxFIR5sB5m+p9SWPKL2/+mMoiQnUx0C9P0=
X-Endpoint-Received: by B4 Relay for robertijtsma@gmail.com/20261122 with auth_id=1604
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Check V4L2_MBUS_CSI2_NONCONTINUOUS_CLOCK from the parsed CSI-2 endpoint
in ov7251_check_hwcfg() and set BIT(5) (CLOCK_LANE_GATE) in
OV7251_MIPI_CTRL00 (0x4800) during power-on when non-continuous clock
mode is configured, allowing the sensor to gate the MIPI clock lane in
LP-11 idle periods (required by Qualcomm SC8180X CSIPHY).

Signed-off-by: Robert Ijtsma <robertijtsma@gmail.com>
---
 drivers/media/i2c/ov7251.c | 18 ++++++++++++++++++
 1 file changed, 18 insertions(+)

diff --git a/drivers/media/i2c/ov7251.c b/drivers/media/i2c/ov7251.c
index 8c6e610586cd..f4ba9e000a66 100644
--- a/drivers/media/i2c/ov7251.c
+++ b/drivers/media/i2c/ov7251.c
@@ -81,6 +81,8 @@
 #define OV7251_TIMING_VTS_REG		0x380e
 #define OV7251_TIMING_MIN_VTS		1
 #define OV7251_TIMING_MAX_VTS		0xffff
+#define OV7251_MIPI_CTRL00		0x4800
+#define OV7251_MIPI_CTRL00_CLOCK_LANE_GATE	BIT(5)
 #define OV7251_INTEGRATION_MARGIN	20
 
 struct reg_value {
@@ -171,6 +173,7 @@ struct ov7251 {
 	u8 timing_format2;
 
 	bool power_on;
+	bool clock_ncont;
 
 	struct gpio_desc *enable_gpio;
 };
@@ -714,6 +717,19 @@ static int ov7251_set_power_on(struct device *dev)
 		goto err_power_off;
 	}
 
+	if (ov7251->clock_ncont) {
+		u8 val;
+
+		ret = ov7251_read_reg(ov7251, OV7251_MIPI_CTRL00, &val);
+		if (ret < 0)
+			goto err_power_off;
+
+		ret = ov7251_write_reg(ov7251, OV7251_MIPI_CTRL00,
+				       val | OV7251_MIPI_CTRL00_CLOCK_LANE_GATE);
+		if (ret < 0)
+			goto err_power_off;
+	}
+
 	return 0;
 
 err_power_off:
@@ -1309,6 +1325,8 @@ static int ov7251_check_hwcfg(struct ov7251 *ov7251)
 	}
 
 	ov7251->link_freq_idx = j;
+	ov7251->clock_ncont = bus_cfg.bus.mipi_csi2.flags &
+			      V4L2_MBUS_CSI2_NONCONTINUOUS_CLOCK;
 
 out_free_bus_cfg:
 	v4l2_fwnode_endpoint_free(&bus_cfg);

-- 
2.56.0

