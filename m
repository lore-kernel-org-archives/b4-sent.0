From: Robert Ijtsma <robertijtsma@gmail.com>
Date: Fri, 27 Nov 2026 21:30:15 +0100
Subject: [PATCH 3/4] media: i2c: ov7251: support non-continuous MIPI clock
 mode
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-ov7251-strobe-ncont-v1-3-cefa8c6c020b@gmail.com>
References: <20261127-ov7251-strobe-ncont-v1-0-cefa8c6c020b@gmail.com>
In-Reply-To: <20261127-ov7251-strobe-ncont-v1-0-cefa8c6c020b@gmail.com>
To: Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Jacopo Mondi <jacopo@jmondi.org>, Todor Tomov <todor.too@gmail.com>
Cc: Mauro Carvalho Chehab <mchehab+samsung@kernel.org>, 
 linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Robert Ijtsma <robertijtsma@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795811412; l=2072;
 i=robertijtsma@gmail.com; s=20261122; h=from:subject:message-id;
 bh=/eNpqimi84SQ1mCr/1eGNfNixnHzZSLMq/OYFI2mSeo=;
 b=mAtXQ1inRaKpW4tcvKE4rFpASX3cjipF+Ada8ChKBu+XDhkW0TFhuWHApCuZ3BR9ZmdQ6YkT8
 quD/BqE5rjVDVrXDLhFaltWtyGN/26zqXrXodiBE/8e5nQHSzsAmYUT
X-Developer-Key: i=robertijtsma@gmail.com; a=ed25519;
 pk=qiDyKVqFicxFIR5sB5m+p9SWPKL2/+mMoiQnUx0C9P0=
X-Endpoint-Received: by B4 Relay for robertijtsma@gmail.com/20261122 with auth_id=1604
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Check V4L2_MBUS_CSI2_NONCONTINUOUS_CLOCK from the parsed CSI-2 endpoint
in ov7251_check_hwcfg() and set BIT(5) (CLOCK_LANE_GATE) in
OV7251_MIPI_CTRL00 (0x4800) when starting streaming in non-continuous
clock mode, allowing the sensor to gate the MIPI clock lane in LP-11
idle periods.

Signed-off-by: Robert Ijtsma <robertijtsma@gmail.com>
---
 drivers/media/i2c/ov7251.c | 19 +++++++++++++++++++
 1 file changed, 19 insertions(+)

diff --git a/drivers/media/i2c/ov7251.c b/drivers/media/i2c/ov7251.c
index 5a50a5100c1e995714201fb509fb207fa03c5f39..13fcc4cdb31a5e7350bcc0b15d186f4912b074be 100644
--- a/drivers/media/i2c/ov7251.c
+++ b/drivers/media/i2c/ov7251.c
@@ -64,6 +64,8 @@
 #define OV7251_TIMING_VTS_REG		0x380e
 #define OV7251_TIMING_MIN_VTS		1
 #define OV7251_TIMING_MAX_VTS		0xffff
+#define OV7251_MIPI_CTRL00		0x4800
+#define OV7251_MIPI_CTRL00_CLOCK_LANE_GATE	BIT(5)
 #define OV7251_INTEGRATION_MARGIN	20
 
 struct reg_value {
@@ -156,6 +158,7 @@ struct ov7251 {
 
 	struct mutex lock; /* lock to protect power state, ctrls and mode */
 	bool power_on;
+	bool clock_ncont;
 
 	struct gpio_desc *enable_gpio;
 };
@@ -1372,6 +1375,20 @@ static int ov7251_s_stream(struct v4l2_subdev *subdev, int enable)
 			dev_err(ov7251->dev, "could not sync v4l2 controls\n");
 			goto err_power_down;
 		}
+
+		if (ov7251->clock_ncont) {
+			u8 val;
+
+			ret = ov7251_read_reg(ov7251, OV7251_MIPI_CTRL00, &val);
+			if (ret)
+				goto err_power_down;
+
+			ret = ov7251_write_reg(ov7251, OV7251_MIPI_CTRL00,
+					       val | OV7251_MIPI_CTRL00_CLOCK_LANE_GATE);
+			if (ret)
+				goto err_power_down;
+		}
+
 		ret = ov7251_write_reg(ov7251, OV7251_SC_MODE_SELECT,
 				       OV7251_SC_MODE_SELECT_STREAMING);
 		if (ret)
@@ -1529,6 +1546,8 @@ static int ov7251_check_hwcfg(struct ov7251 *ov7251)
 	}
 
 	ov7251->link_freq_idx = i;
+	ov7251->clock_ncont = bus_cfg.bus.mipi_csi2.flags &
+			      V4L2_MBUS_CSI2_NONCONTINUOUS_CLOCK;
 
 out_free_bus_cfg:
 	v4l2_fwnode_endpoint_free(&bus_cfg);

-- 
2.47.3

