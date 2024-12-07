From: =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
Date: Sat, 07 Dec 2024 21:47:51 +0100
Subject: [PATCH v3 02/12] media: i2c: imx214: Simplify with dev_err_probe()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20241207-imx214-v3-2-ab60af7ee915@apitzsch.eu>
References: <20241207-imx214-v3-0-ab60af7ee915@apitzsch.eu>
In-Reply-To: <20241207-imx214-v3-0-ab60af7ee915@apitzsch.eu>
To: Ricardo Ribalda <ribalda@kernel.org>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>
Cc: ~postmarketos/upstreaming@lists.sr.ht, phone-devel@vger.kernel.org, 
 linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Dave Stevenson <dave.stevenson@raspberrypi.com>, 
 Vincent Knecht <vincent.knecht@mailoo.org>, 
 =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>, 
 Ricardo Ribalda <ribalda@chromium.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1733604504; l=3934;
 i=git@apitzsch.eu; s=20240325; h=from:subject:message-id;
 bh=6Yb2WJ/PsRWmG6pmBMXJE2hgYjX34ni/UK08kadzOpA=;
 b=lvTNkMz5iCgv8TYqAqdmkNi98zm6xGiJ62kZMWtpVkG/DCdhvimMA+H+NsBNMeNLQFZan4wBg
 BcfLj9RiLu2Dm/ZQWQPz6lJr9Wm6oUGcOmtsEYOuqcS15e0BAu1/yV2
X-Developer-Key: i=git@apitzsch.eu; a=ed25519;
 pk=wxovcZRfvNYBMcTw4QFFtNEP4qv39gnBfnfyImXZxiU=
X-Endpoint-Received: by B4 Relay for git@apitzsch.eu/20240325 with auth_id=142
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Error handling in probe() can be a bit simpler with dev_err_probe().

Acked-by: Ricardo Ribalda <ribalda@chromium.org>
Signed-off-by: André Apitzsch <git@apitzsch.eu>
---
 drivers/media/i2c/imx214.c | 52 ++++++++++++++++++++--------------------------
 1 file changed, 22 insertions(+), 30 deletions(-)

diff --git a/drivers/media/i2c/imx214.c b/drivers/media/i2c/imx214.c
index 435d1ee12c3a0959ae751c3e7a8b4e7fa1a4c303..09f5078f341c467f083c0294212dad0f354e6185 100644
--- a/drivers/media/i2c/imx214.c
+++ b/drivers/media/i2c/imx214.c
@@ -930,14 +930,12 @@ static int imx214_parse_fwnode(struct device *dev)
 	int ret;
 
 	endpoint = fwnode_graph_get_next_endpoint(dev_fwnode(dev), NULL);
-	if (!endpoint) {
-		dev_err(dev, "endpoint node not found\n");
-		return -EINVAL;
-	}
+	if (!endpoint)
+		return dev_err_probe(dev, -EINVAL, "endpoint node not found\n");
 
 	ret = v4l2_fwnode_endpoint_alloc_parse(endpoint, &bus_cfg);
 	if (ret) {
-		dev_err(dev, "parsing endpoint node failed\n");
+		dev_err_probe(dev, ret, "parsing endpoint node failed\n");
 		goto done;
 	}
 
@@ -946,8 +944,9 @@ static int imx214_parse_fwnode(struct device *dev)
 			break;
 
 	if (i == bus_cfg.nr_of_link_frequencies) {
-		dev_err(dev, "link-frequencies %d not supported, Please review your DT\n",
-			IMX214_DEFAULT_LINK_FREQ);
+		dev_err_probe(dev, -EINVAL,
+			      "link-frequencies %d not supported, Please review your DT\n",
+			      IMX214_DEFAULT_LINK_FREQ);
 		ret = -EINVAL;
 		goto done;
 	}
@@ -975,34 +974,27 @@ static int imx214_probe(struct i2c_client *client)
 	imx214->dev = dev;
 
 	imx214->xclk = devm_clk_get(dev, NULL);
-	if (IS_ERR(imx214->xclk)) {
-		dev_err(dev, "could not get xclk");
-		return PTR_ERR(imx214->xclk);
-	}
+	if (IS_ERR(imx214->xclk))
+		return dev_err_probe(dev, PTR_ERR(imx214->xclk),
+				     "failed to get xclk\n");
 
 	ret = clk_set_rate(imx214->xclk, IMX214_DEFAULT_CLK_FREQ);
-	if (ret) {
-		dev_err(dev, "could not set xclk frequency\n");
-		return ret;
-	}
+	if (ret)
+		return dev_err_probe(dev, ret, "failed to set xclk frequency\n");
 
 	ret = imx214_get_regulators(dev, imx214);
-	if (ret < 0) {
-		dev_err(dev, "cannot get regulators\n");
-		return ret;
-	}
+	if (ret < 0)
+		return dev_err_probe(dev, ret, "failed to get regulators\n");
 
 	imx214->enable_gpio = devm_gpiod_get(dev, "enable", GPIOD_OUT_LOW);
-	if (IS_ERR(imx214->enable_gpio)) {
-		dev_err(dev, "cannot get enable gpio\n");
-		return PTR_ERR(imx214->enable_gpio);
-	}
+	if (IS_ERR(imx214->enable_gpio))
+		return dev_err_probe(dev, PTR_ERR(imx214->enable_gpio),
+				     "failed to get enable gpio\n");
 
 	imx214->regmap = devm_regmap_init_i2c(client, &sensor_regmap_config);
-	if (IS_ERR(imx214->regmap)) {
-		dev_err(dev, "regmap init failed\n");
-		return PTR_ERR(imx214->regmap);
-	}
+	if (IS_ERR(imx214->regmap))
+		return dev_err_probe(dev, PTR_ERR(imx214->regmap),
+				     "regmap init failed\n");
 
 	v4l2_i2c_subdev_init(&imx214->sd, client, &imx214_subdev_ops);
 	imx214->sd.internal_ops = &imx214_internal_ops;
@@ -1031,20 +1023,20 @@ static int imx214_probe(struct i2c_client *client)
 
 	ret = media_entity_pads_init(&imx214->sd.entity, 1, &imx214->pad);
 	if (ret < 0) {
-		dev_err(dev, "could not register media entity\n");
+		dev_err_probe(dev, ret, "failed to init entity pads\n");
 		goto free_ctrl;
 	}
 
 	imx214->sd.state_lock = imx214->ctrls.lock;
 	ret = v4l2_subdev_init_finalize(&imx214->sd);
 	if (ret < 0) {
-		dev_err(dev, "subdev init error: %d\n", ret);
+		dev_err_probe(dev, ret, "subdev init error\n");
 		goto free_entity;
 	}
 
 	ret = v4l2_async_register_subdev_sensor(&imx214->sd);
 	if (ret < 0) {
-		dev_err(dev, "could not register v4l2 device\n");
+		dev_err_probe(dev, ret, "failed to register sensor sub-device\n");
 		goto error_subdev_cleanup;
 	}
 

-- 
2.47.1

