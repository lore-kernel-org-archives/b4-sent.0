From: Maud Spierings <maudspierings@gocontroll.com>
Date: Thu, 30 Oct 2025 08:07:42 +0100
Subject: [PATCH] net: can: mcp251x: use dev_err_probe() in probe
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251030-mcp_err-v1-1-eecf737823b7@gocontroll.com>
X-B4-Tracking: v=1; b=H4sIAL4OA2kC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1NDA2MD3dzkgvjUoiLdNLNEY8PUpKRUE/NEJaDqgqLUtMwKsEnRsbW1ADw
 ycApZAAAA
X-Change-ID: 20251030-mcp_err-f6a31ebbe47a
To: Marc Kleine-Budde <mkl@pengutronix.de>, 
 Vincent Mailhol <mailhol@kernel.org>
Cc: linux-can@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Maud Spierings <maudspierings@gocontroll.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1761808076; l=3745;
 i=maudspierings@gocontroll.com; s=20250214; h=from:subject:message-id;
 bh=7SQx5+xuTmbRP2jC1wr5GUv3U4vwif5G7XletYOqjvM=;
 b=ajEC4nBLTA9I/eM7uEBSr4UY3zwgPURL28Oc1vZrtNHrN+r1aYzTOc0fCUk3mcDsIkoLu1vBm
 nxT+mb8Zr9bCRo61rJ+jIATfekBzhDYcYITa6yj7nAhslll9CFMEwYC
X-Developer-Key: i=maudspierings@gocontroll.com; a=ed25519;
 pk=7chUb8XpaTQDvWhzTdHC0YPMkTDloELEC7q94tOUyPg=
X-Endpoint-Received: by B4 Relay for maudspierings@gocontroll.com/20250214 with auth_id=341
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The currently used combination of dev_err plus return leaves a loud
error in dmesg even when the error is a deferred probe which gets
resolved later. For example a supply that has not been probed yet.

Use dev_err_probe to improve the handling/display of errors.

Signed-off-by: Maud Spierings <maudspierings@gocontroll.com>
---
 drivers/net/can/spi/mcp251x.c | 31 ++++++++++++++++++++-----------
 1 file changed, 20 insertions(+), 11 deletions(-)

diff --git a/drivers/net/can/spi/mcp251x.c b/drivers/net/can/spi/mcp251x.c
index 1e54e1a22702..fa97adf25b73 100644
--- a/drivers/net/can/spi/mcp251x.c
+++ b/drivers/net/can/spi/mcp251x.c
@@ -1320,7 +1320,7 @@ static int mcp251x_can_probe(struct spi_device *spi)
 
 	clk = devm_clk_get_optional(&spi->dev, NULL);
 	if (IS_ERR(clk))
-		return PTR_ERR(clk);
+		return dev_err_probe(&spi->dev, PTR_ERR(clk), "Cannot get clock\n");
 
 	freq = clk_get_rate(clk);
 	if (freq == 0)
@@ -1328,7 +1328,7 @@ static int mcp251x_can_probe(struct spi_device *spi)
 
 	/* Sanity check */
 	if (freq < 1000000 || freq > 25000000)
-		return -ERANGE;
+		return dev_err_probe(&spi->dev, -ERANGE, "clock frequency out of range\n");
 
 	/* Allocate can/net device */
 	net = alloc_candev(sizeof(struct mcp251x_priv), TX_ECHO_SKB_MAX);
@@ -1336,8 +1336,10 @@ static int mcp251x_can_probe(struct spi_device *spi)
 		return -ENOMEM;
 
 	ret = clk_prepare_enable(clk);
-	if (ret)
+	if (ret) {
+		dev_err_probe(&spi->dev, ret, "Cannot enable clock\n");
 		goto out_free;
+	}
 
 	net->netdev_ops = &mcp251x_netdev_ops;
 	net->ethtool_ops = &mcp251x_ethtool_ops;
@@ -1362,20 +1364,25 @@ static int mcp251x_can_probe(struct spi_device *spi)
 	else
 		spi->max_speed_hz = spi->max_speed_hz ? : 10 * 1000 * 1000;
 	ret = spi_setup(spi);
-	if (ret)
+	if (ret) {
+		dev_err_probe(&spi->dev, ret, "Cannot set up spi\n");
 		goto out_clk;
+	}
 
 	priv->power = devm_regulator_get_optional(&spi->dev, "vdd");
 	priv->transceiver = devm_regulator_get_optional(&spi->dev, "xceiver");
 	if ((PTR_ERR(priv->power) == -EPROBE_DEFER) ||
 	    (PTR_ERR(priv->transceiver) == -EPROBE_DEFER)) {
 		ret = -EPROBE_DEFER;
+		dev_err_probe(&spi->dev, ret, "supply deferred\n");
 		goto out_clk;
 	}
 
 	ret = mcp251x_power_enable(priv->power, 1);
-	if (ret)
+	if (ret) {
+		dev_err_probe(&spi->dev, ret, "Cannot enable power\n");
 		goto out_clk;
+	}
 
 	priv->wq = alloc_workqueue("mcp251x_wq",
 				   WQ_FREEZABLE | WQ_MEM_RECLAIM | WQ_PERCPU,
@@ -1409,21 +1416,24 @@ static int mcp251x_can_probe(struct spi_device *spi)
 	/* Here is OK to not lock the MCP, no one knows about it yet */
 	ret = mcp251x_hw_probe(spi);
 	if (ret) {
-		if (ret == -ENODEV)
-			dev_err(&spi->dev, "Cannot initialize MCP%x. Wrong wiring?\n",
-				priv->model);
+		dev_err_probe(&spi->dev, ret, "Cannot initialize MCP%x. Wrong wiring?\n",
+			      priv->model);
 		goto error_probe;
 	}
 
 	mcp251x_hw_sleep(spi);
 
 	ret = register_candev(net);
-	if (ret)
+	if (ret) {
+		dev_err_probe(&spi->dev, ret, "Cannot register CAN device\n");
 		goto error_probe;
+	}
 
 	ret = mcp251x_gpio_setup(priv);
-	if (ret)
+	if (ret) {
+		dev_err_probe(&spi->dev, ret, "Cannot set up gpios\n");
 		goto out_unregister_candev;
+	}
 
 	netdev_info(net, "MCP%x successfully initialized.\n", priv->model);
 	return 0;
@@ -1442,7 +1452,6 @@ static int mcp251x_can_probe(struct spi_device *spi)
 out_free:
 	free_candev(net);
 
-	dev_err(&spi->dev, "Probe failed, err=%d\n", -ret);
 	return ret;
 }
 

---
base-commit: 131f3d9446a6075192cdd91f197989d98302faa6
change-id: 20251030-mcp_err-f6a31ebbe47a

Best regards,
-- 
Maud Spierings <maudspierings@gocontroll.com>

