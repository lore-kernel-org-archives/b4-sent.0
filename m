From: Richard Leitner <richard.leitner@linux.dev>
Date: Wed, 14 Oct 2026 08:49:15 +0200
Subject: [PATCH v2 8/8] media: i2c: ov9282: harmonize dev_err_probe usage
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261014-ov9282-fixes-v2-8-3bb376d8b1a9@linux.dev>
References: <20261014-ov9282-fixes-v2-0-3bb376d8b1a9@linux.dev>
In-Reply-To: <20261014-ov9282-fixes-v2-0-3bb376d8b1a9@linux.dev>
To: Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Dave Stevenson <dave.stevenson@raspberrypi.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Daniele Alessandrelli <daniele.alessandrelli@gmail.com>, 
 "Paul J. Murphy" <paul.j.murphy@intel.com>, 
 Martina Krasteva <martinax.krasteva@intel.com>, 
 Richard Leitner <richard.leitner@linux.dev>, 
 Hans Verkuil <hverkuil+cisco@kernel.org>, Bryan O'Donoghue <bod@kernel.org>, 
 Jacopo Mondi <jacopo@jmondi.org>
Cc: Mauro Carvalho Chehab <mchehab+huawei@kernel.org>, 
 Gyula Kelemen <gyula.kelemen@advasolutions.com>, 
 linux-media@vger.kernel.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791960586; l=3760;
 i=richard.leitner@linux.dev; s=20250225; h=from:subject:message-id;
 bh=JzBZoQKsEp8pDZEORpFC/spAt7+e6TdcgQxRtX/4nks=;
 b=TV2L4gdjxJJ4YPzeKvQRdFEPWpoLNPGkz/NBDdgRdnDMjkBwMTu1uVwU1sdUaEfHe4ovGwkEo
 k3dGT1EFXV6D5zIzGoJyxL/vmLaUsDbFAGqzrbPjYIq5kogTrqKvYCz
X-Developer-Key: i=richard.leitner@linux.dev; a=ed25519;
 pk=8hZNyyyQFqZ5ruVJsSGBSPIrmJpfDm5HwHU4QVOP1Pk=
X-Endpoint-Received: by B4 Relay for richard.leitner@linux.dev/20250225 with auth_id=350
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Use dev_err_probe() for all error messages during probing. This ensures
there's a common "look-and-feel" in the drivers source code as well as
the system log.

Signed-off-by: Richard Leitner <richard.leitner@linux.dev>
---
 drivers/media/i2c/ov9282.c | 32 +++++++++++++++-----------------
 1 file changed, 15 insertions(+), 17 deletions(-)

diff --git a/drivers/media/i2c/ov9282.c b/drivers/media/i2c/ov9282.c
index f877cb9e78c38..8b01d9d43f0df 100644
--- a/drivers/media/i2c/ov9282.c
+++ b/drivers/media/i2c/ov9282.c
@@ -1077,9 +1077,8 @@ static int ov9282_parse_hw_config(struct ov9282 *ov9282)
 	ov9282->reset_gpio = devm_gpiod_get_optional(ov9282->dev, "reset",
 						     GPIOD_OUT_LOW);
 	if (IS_ERR(ov9282->reset_gpio)) {
-		dev_err(ov9282->dev, "failed to get reset gpio %pe",
-			ov9282->reset_gpio);
-		return PTR_ERR(ov9282->reset_gpio);
+		return dev_err_probe(ov9282->dev, PTR_ERR(ov9282->reset_gpio),
+				     "failed to get reset gpio\n");
 	}
 
 	/* Get sensor input clock */
@@ -1095,8 +1094,8 @@ static int ov9282_parse_hw_config(struct ov9282 *ov9282)
 
 	rate = clk_get_rate(ov9282->inclk);
 	if (rate != OV9282_INCLK_RATE) {
-		dev_err(ov9282->dev, "inclk frequency mismatch");
-		return -EINVAL;
+		return dev_err_probe(ov9282->dev, -EINVAL,
+				     "inclk frequency mismatch\n");
 	}
 
 	ep = fwnode_graph_get_next_endpoint(fwnode, NULL);
@@ -1112,16 +1111,15 @@ static int ov9282_parse_hw_config(struct ov9282 *ov9282)
 		bus_cfg.bus.mipi_csi2.flags & V4L2_MBUS_CSI2_NONCONTINUOUS_CLOCK;
 
 	if (bus_cfg.bus.mipi_csi2.num_data_lanes != OV9282_NUM_DATA_LANES) {
-		dev_err(ov9282->dev,
-			"number of CSI2 data lanes %d is not supported",
-			bus_cfg.bus.mipi_csi2.num_data_lanes);
-		ret = -EINVAL;
+		ret = dev_err_probe(ov9282->dev, -EINVAL,
+				    "number of CSI2 data lanes %d is not supported\n",
+				    bus_cfg.bus.mipi_csi2.num_data_lanes);
 		goto done_endpoint_free;
 	}
 
 	if (!bus_cfg.nr_of_link_frequencies) {
-		dev_err(ov9282->dev, "no link frequencies defined");
-		ret = -EINVAL;
+		ret = dev_err_probe(ov9282->dev, -EINVAL,
+				    "no link frequencies defined\n");
 		goto done_endpoint_free;
 	}
 
@@ -1352,8 +1350,8 @@ static int ov9282_probe(struct i2c_client *client)
 
 	ret = ov9282_parse_hw_config(ov9282);
 	if (ret) {
-		dev_err(ov9282->dev, "HW configuration is not supported");
-		return ret;
+		return dev_err_probe(ov9282->dev, ret,
+				     "HW configuration is not supported\n");
 	}
 
 	ov9282->regmap = devm_cci_regmap_init_i2c(client, 16);
@@ -1364,12 +1362,12 @@ static int ov9282_probe(struct i2c_client *client)
 	ret = ov9282_power_on(ov9282->dev);
 	if (ret)
 		return dev_err_probe(ov9282->dev, ret,
-				     "failed to power-on the sensor");
+				     "failed to power-on the sensor\n");
 
 	/* Check module identity */
 	ret = ov9282_detect(ov9282);
 	if (ret) {
-		dev_err(ov9282->dev, "failed to find sensor: %d", ret);
+		dev_err_probe(ov9282->dev, ret, "failed to find sensor\n");
 		goto error_power_off;
 	}
 
@@ -1379,7 +1377,7 @@ static int ov9282_probe(struct i2c_client *client)
 
 	ret = ov9282_init_controls(ov9282);
 	if (ret) {
-		dev_err(ov9282->dev, "failed to init controls: %d", ret);
+		dev_err_probe(ov9282->dev, ret, "failed to init controls\n");
 		goto error_power_off;
 	}
 
@@ -1392,7 +1390,7 @@ static int ov9282_probe(struct i2c_client *client)
 	ov9282->pad.flags = MEDIA_PAD_FL_SOURCE;
 	ret = media_entity_pads_init(&ov9282->sd.entity, 1, &ov9282->pad);
 	if (ret) {
-		dev_err(ov9282->dev, "failed to init entity pads: %d", ret);
+		dev_err_probe(ov9282->dev, ret, "failed to init entity pads\n");
 		goto error_handler_free;
 	}
 

-- 
2.53.0

