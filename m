From: George Neacsu <geocausa@gmail.com>
Date: Sun, 18 Oct 2026 22:10:22 +0100
Subject: [PATCH v2 2/2] media: i2c: ov13858: Add device tree support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261018-ov13858-x1e-v2-2-cd35434cfcfe@gmail.com>
References: <20261018-ov13858-x1e-v2-0-cd35434cfcfe@gmail.com>
In-Reply-To: <20261018-ov13858-x1e-v2-0-cd35434cfcfe@gmail.com>
To: Sakari Ailus <sakari.ailus@linux.intel.com>
Cc: Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Sergey Lebedev <lsa.uz@pm.me>, 
 German Pablo Lindo <germanpapulindez@gmail.com>, 
 Bryan O'Donoghue <bod@kernel.org>, linux-media@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, George Neacsu <geocausa@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792357821; l=3307;
 i=geocausa@gmail.com; s=20261015; h=from:subject:message-id;
 bh=gs3CtGFwDnGrLbCfT8MlpVJ7PkVcHqMOwjwlmQ7RH0g=;
 b=kQvUD4ZxywitktIv51sXrhoqX0ylp34HwqwKT1g0IuVrh1kAUzwo+ba8+qKwbPLwQo2sMH9KG
 N5W021SfAIuBzNLKilOQ/LumJxvWUIPnmS0uQeoXn7YkV1DrtSFYpTd
X-Developer-Key: i=geocausa@gmail.com; a=ed25519;
 pk=KyQk/iWbxsikewDBh0SwlHI51RvAqahD3loqmRp9DVI=
X-Endpoint-Received: by B4 Relay for geocausa@gmail.com/20261015 with auth_id=1199
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add an OF match table for OV13858 and parse its firmware endpoint at
probe time. Require a four-lane D-PHY endpoint and both link frequencies
used by the existing sensor modes.

v4l2_fwnode_endpoint_alloc_parse() returns -EPROBE_DEFER if a software
node endpoint has not been instantiated yet, preserving bridge-created
endpoint probe ordering.

Tested-by: Sergey Lebedev <lsa.uz@pm.me> # Surface Pro 11 (Intel)
Assisted-by: Claude:claude-opus-5-5
Assisted-by: ChatGPT:gpt-5.6-sol
Signed-off-by: George Neacsu <geocausa@gmail.com>
---
 drivers/media/i2c/ov13858.c | 54 +++++++++++++++++++++++++++++++++++++++++++++
 1 file changed, 54 insertions(+)

diff --git a/drivers/media/i2c/ov13858.c b/drivers/media/i2c/ov13858.c
index 5d7b3c335d..2957124404 100644
--- a/drivers/media/i2c/ov13858.c
+++ b/drivers/media/i2c/ov13858.c
@@ -1765,6 +1765,49 @@ static const struct dev_pm_ops ov13858_pm_ops = {
 	RUNTIME_PM_OPS(ov13858_power_off, ov13858_power_on, NULL)
 };
 
+static int ov13858_check_hwcfg(struct device *dev)
+{
+	struct v4l2_fwnode_endpoint bus_cfg = {
+		.bus_type = V4L2_MBUS_CSI2_DPHY
+	};
+	unsigned long link_freq_bitmap;
+	struct fwnode_handle *ep;
+	int ret;
+
+	ep = fwnode_graph_get_next_endpoint(dev_fwnode(dev), NULL);
+	ret = v4l2_fwnode_endpoint_alloc_parse(ep, &bus_cfg);
+	fwnode_handle_put(ep);
+	if (ret)
+		return dev_err_probe(dev, ret, "parsing endpoint failed\n");
+
+	if (bus_cfg.bus.mipi_csi2.num_data_lanes != 4) {
+		ret = dev_err_probe(dev, -EINVAL,
+				    "%u data lanes are not supported, only 4\n",
+				    bus_cfg.bus.mipi_csi2.num_data_lanes);
+		goto out;
+	}
+
+	/* The modes use both link frequencies, so both have to be allowed. */
+	ret = v4l2_link_freq_to_bitmap(dev, bus_cfg.link_frequencies,
+				       bus_cfg.nr_of_link_frequencies,
+				       link_freq_menu_items,
+				       ARRAY_SIZE(link_freq_menu_items),
+				       &link_freq_bitmap);
+	if (ret)
+		goto out;
+
+	if (link_freq_bitmap != GENMASK(ARRAY_SIZE(link_freq_menu_items) - 1, 0))
+		ret = dev_err_probe(dev, -EINVAL,
+				    "link frequencies %lld and %lld are both needed\n",
+				    link_freq_menu_items[0],
+				    link_freq_menu_items[1]);
+
+out:
+	v4l2_fwnode_endpoint_free(&bus_cfg);
+
+	return ret;
+}
+
 static int ov13858_probe(struct i2c_client *client)
 {
 	struct ov13858 *ov13858;
@@ -1777,6 +1820,10 @@ static int ov13858_probe(struct i2c_client *client)
 
 	ov13858->dev = &client->dev;
 
+	ret = ov13858_check_hwcfg(ov13858->dev);
+	if (ret)
+		return ret;
+
 	ov13858->clk = devm_v4l2_sensor_clk_get(ov13858->dev, NULL);
 	if (IS_ERR(ov13858->clk))
 		return dev_err_probe(ov13858->dev, PTR_ERR(ov13858->clk),
@@ -1897,10 +1944,17 @@ static const struct acpi_device_id ov13858_acpi_ids[] = {
 MODULE_DEVICE_TABLE(acpi, ov13858_acpi_ids);
 #endif
 
+static const struct of_device_id ov13858_of_match[] = {
+	{ .compatible = "ovti,ov13858" },
+	{ /* sentinel */ }
+};
+MODULE_DEVICE_TABLE(of, ov13858_of_match);
+
 static struct i2c_driver ov13858_i2c_driver = {
 	.driver = {
 		.name = "ov13858",
 		.acpi_match_table = ACPI_PTR(ov13858_acpi_ids),
+		.of_match_table = ov13858_of_match,
 		.pm = pm_ptr(&ov13858_pm_ops),
 	},
 	.probe = ov13858_probe,

-- 
2.53.0

