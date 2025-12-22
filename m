From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Mon, 22 Dec 2025 13:48:01 +0000
Subject: [PATCH v3 1/2] iio: dac: adi-axi-dac: Make use of a local struct
 device variable
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20251222-iio-axi-dac-minor-changes-v3-1-29199f239d9c@analog.com>
References: <20251222-iio-axi-dac-minor-changes-v3-0-29199f239d9c@analog.com>
In-Reply-To: <20251222-iio-axi-dac-minor-changes-v3-0-29199f239d9c@analog.com>
To: linux-iio@vger.kernel.org
Cc: Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1766411287; l=4511;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=8Blc9/9CpephaMbHXA89FWvHZw45iDfYarwG1M/f6X0=;
 b=WYZZYKEW63H1k0l3IHvVfJ23fAAPpkahil3JshLbJ55EEUtGe0mYU8MyWsYYWLyd63hoFHjNg
 5V0FTIbxJ2wB+CbXrcPwc50NL7xOQalR2F4mMwMV6JTDVdQMAUX+6/+
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Use a local struct device variable to improve readability in some code
paths during probe. While at it, fix some line breaks not properly
aligned to the open parenthesis.

Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
 drivers/iio/dac/adi-axi-dac.c | 47 +++++++++++++++++++++----------------------
 1 file changed, 23 insertions(+), 24 deletions(-)

diff --git a/drivers/iio/dac/adi-axi-dac.c b/drivers/iio/dac/adi-axi-dac.c
index 0d525272a8a8..851d837d7ced 100644
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
@@ -944,7 +944,7 @@ static int axi_dac_probe(struct platform_device *pdev)
 
 	if (ADI_AXI_PCORE_VER_MAJOR(ver) !=
 		ADI_AXI_PCORE_VER_MAJOR(st->info->version)) {
-		dev_err(&pdev->dev,
+		dev_err(dev,
 			"Major version mismatch. Expected %d.%.2d.%c, Reported %d.%.2d.%c\n",
 			ADI_AXI_PCORE_VER_MAJOR(st->info->version),
 			ADI_AXI_PCORE_VER_MINOR(st->info->version),
@@ -975,34 +975,33 @@ static int axi_dac_probe(struct platform_device *pdev)
 
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
-						"invalid reg property.");
+			return dev_err_probe(dev, ret, "invalid reg property.");
 		if (val != 0)
-			return dev_err_probe(&pdev->dev, -EINVAL,
-						"invalid node address.");
+			return dev_err_probe(dev, -EINVAL,
+					     "invalid node address.");
 
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

-- 
2.52.0

