From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Fri, 19 Dec 2025 15:54:29 +0000
Subject: [PATCH v2] iio: dac: adi-axi-dac: Make use of dev_err_probe()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20251219-iio-axi-dac-minor-changes-v2-1-e9fccc019b01@analog.com>
X-B4-Tracking: v=1; b=H4sIADR1RWkC/42NQQ7CIBBFr9LM2jFAi4muvEfTBdChncSCAUNqm
 t5drBdw+X7+f3+DTIkpw63ZIFHhzDFUUKcG3GzCRMhjZVBCaalEi8wRzco4GocLh5jw18t47bQ
 32iuSZKHun4k8r4e7HyrPnF8xvY+rIr/pP9YiUaDV3UULZ8m27d0E84jT2cUFhn3fP4+R6mPDA
 AAA
X-Change-ID: 20251203-iio-axi-dac-minor-changes-945fa5f2e1eb
To: linux-iio@vger.kernel.org
Cc: Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1766159669; l=5829;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=ksxqVLO/Zb22D2xXa2ByM7XLjAIQ1RVEjJwN6F1omGs=;
 b=LPOk+U2cpv857aM8dTI7kpezkw1CtdOswUg+cdI3cdkRoywBFZQH9pur5V0Mauoa3Gz/xk0tS
 gKmygPZc72dDBswDhRiWmTDxFuBXq+cy+IX4915z+9licWcxT5TFM2t
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Be consistent and use dev_err_probe() as in all other places in the
.probe() path.

While at it, remove the line break in the version condition. Yes, it
goes over the 80 column limit but I do think the line break hurts
readability in this case. And use a struct device *dev helper for
neater code.

Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
Ended up dropping the dev_info() -> dev_dbg() patch.
---
Changes in v2:
- Patch 1
  * Added helper struct device variable as suggested by Andy;
  * Removed the braces as suggested by David.
- Link to v1: https://lore.kernel.org/r/20251203-iio-axi-dac-minor-changes-v1-0-b54650cbeb33@analog.com
---
 drivers/iio/dac/adi-axi-dac.c | 63 +++++++++++++++++++++----------------------
 1 file changed, 30 insertions(+), 33 deletions(-)

diff --git a/drivers/iio/dac/adi-axi-dac.c b/drivers/iio/dac/adi-axi-dac.c
index 0d525272a8a8..ceab9f6fa3b4 100644
--- a/drivers/iio/dac/adi-axi-dac.c
+++ b/drivers/iio/dac/adi-axi-dac.c
@@ -885,34 +885,35 @@ static const struct regmap_config axi_dac_regmap_config = {
 
 static int axi_dac_probe(struct platform_device *pdev)
 {
+	struct device *dev = &pdev->dev;
 	struct axi_dac_state *st;
 	void __iomem *base;
 	unsigned int ver;
 	struct clk *clk;
 	int ret;
 
-	st = devm_kzalloc(&pdev->dev, sizeof(*st), GFP_KERNEL);
+	st = devm_kzalloc(dev, sizeof(*st), GFP_KERNEL);
 	if (!st)
 		return -ENOMEM;
 
-	st->info = device_get_match_data(&pdev->dev);
+	st->info = device_get_match_data(dev);
 	if (!st->info)
 		return -ENODEV;
-	clk = devm_clk_get_enabled(&pdev->dev, "s_axi_aclk");
+	clk = devm_clk_get_enabled(dev, "s_axi_aclk");
 	if (IS_ERR(clk)) {
 		/* Backward compat., old fdt versions without clock-names. */
-		clk = devm_clk_get_enabled(&pdev->dev, NULL);
+		clk = devm_clk_get_enabled(dev, NULL);
 		if (IS_ERR(clk))
-			return dev_err_probe(&pdev->dev, PTR_ERR(clk),
-					"failed to get clock\n");
+			return dev_err_probe(dev, PTR_ERR(clk),
+					     "failed to get clock\n");
 	}
 
 	if (st->info->has_dac_clk) {
 		struct clk *dac_clk;
 
-		dac_clk = devm_clk_get_enabled(&pdev->dev, "dac_clk");
+		dac_clk = devm_clk_get_enabled(dev, "dac_clk");
 		if (IS_ERR(dac_clk))
-			return dev_err_probe(&pdev->dev, PTR_ERR(dac_clk),
+			return dev_err_probe(dev, PTR_ERR(dac_clk),
 					     "failed to get dac_clk clock\n");
 
 		/* We only care about the streaming mode rate */
@@ -923,11 +924,10 @@ static int axi_dac_probe(struct platform_device *pdev)
 	if (IS_ERR(base))
 		return PTR_ERR(base);
 
-	st->dev = &pdev->dev;
-	st->regmap = devm_regmap_init_mmio(&pdev->dev, base,
-					   &axi_dac_regmap_config);
+	st->dev = dev;
+	st->regmap = devm_regmap_init_mmio(dev, base, &axi_dac_regmap_config);
 	if (IS_ERR(st->regmap))
-		return dev_err_probe(&pdev->dev, PTR_ERR(st->regmap),
+		return dev_err_probe(dev, PTR_ERR(st->regmap),
 				     "failed to init register map\n");
 
 	/*
@@ -942,18 +942,15 @@ static int axi_dac_probe(struct platform_device *pdev)
 	if (ret)
 		return ret;
 
-	if (ADI_AXI_PCORE_VER_MAJOR(ver) !=
-		ADI_AXI_PCORE_VER_MAJOR(st->info->version)) {
-		dev_err(&pdev->dev,
-			"Major version mismatch. Expected %d.%.2d.%c, Reported %d.%.2d.%c\n",
-			ADI_AXI_PCORE_VER_MAJOR(st->info->version),
-			ADI_AXI_PCORE_VER_MINOR(st->info->version),
-			ADI_AXI_PCORE_VER_PATCH(st->info->version),
-			ADI_AXI_PCORE_VER_MAJOR(ver),
-			ADI_AXI_PCORE_VER_MINOR(ver),
-			ADI_AXI_PCORE_VER_PATCH(ver));
-		return -ENODEV;
-	}
+	if (ADI_AXI_PCORE_VER_MAJOR(ver) != ADI_AXI_PCORE_VER_MAJOR(st->info->version))
+		return dev_err_probe(dev, -ENODEV,
+				     "Major version mismatch. Expected %d.%.2d.%c, Reported %d.%.2d.%c\n",
+				     ADI_AXI_PCORE_VER_MAJOR(st->info->version),
+				     ADI_AXI_PCORE_VER_MINOR(st->info->version),
+				     ADI_AXI_PCORE_VER_PATCH(st->info->version),
+				     ADI_AXI_PCORE_VER_MAJOR(ver),
+				     ADI_AXI_PCORE_VER_MINOR(ver),
+				     ADI_AXI_PCORE_VER_PATCH(ver));
 
 	/* Let's get the core read only configuration */
 	ret = regmap_read(st->regmap, AXI_DAC_CONFIG_REG, &st->reg_config);
@@ -975,34 +972,34 @@ static int axi_dac_probe(struct platform_device *pdev)
 
 	mutex_init(&st->lock);
 
-	ret = devm_iio_backend_register(&pdev->dev, st->info->backend_info, st);
+	ret = devm_iio_backend_register(dev, st->info->backend_info, st);
 	if (ret)
-		return dev_err_probe(&pdev->dev, ret,
+		return dev_err_probe(dev, ret,
 				     "failed to register iio backend\n");
 
-	device_for_each_child_node_scoped(&pdev->dev, child) {
+	device_for_each_child_node_scoped(dev, child) {
 		int val;
 
 		if (!st->info->has_child_nodes)
-			return dev_err_probe(&pdev->dev, -EINVAL,
+			return dev_err_probe(dev, -EINVAL,
 					     "invalid fdt axi-dac compatible.");
 
 		/* Processing only reg 0 node */
 		ret = fwnode_property_read_u32(child, "reg", &val);
 		if (ret)
-			return dev_err_probe(&pdev->dev, ret,
+			return dev_err_probe(dev, ret,
 						"invalid reg property.");
 		if (val != 0)
-			return dev_err_probe(&pdev->dev, -EINVAL,
+			return dev_err_probe(dev, -EINVAL,
 						"invalid node address.");
 
 		ret = axi_dac_create_platform_device(st, child);
 		if (ret)
-			return dev_err_probe(&pdev->dev, -EINVAL,
-						"cannot create device.");
+			return dev_err_probe(dev, -EINVAL,
+					     "cannot create device.");
 	}
 
-	dev_info(&pdev->dev, "AXI DAC IP core (%d.%.2d.%c) probed\n",
+	dev_info(dev, "AXI DAC IP core (%d.%.2d.%c) probed\n",
 		 ADI_AXI_PCORE_VER_MAJOR(ver),
 		 ADI_AXI_PCORE_VER_MINOR(ver),
 		 ADI_AXI_PCORE_VER_PATCH(ver));

---
base-commit: f9e05791642810a0cf6237d39fafd6fec5e0b4bb
change-id: 20251203-iio-axi-dac-minor-changes-945fa5f2e1eb
--

Thanks!
- Nuno Sá

