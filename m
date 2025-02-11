From: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
Date: Tue, 11 Feb 2025 14:12:34 +0100
Subject: [PATCH 2/2] can: flexcan: add transceiver capabilities
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250211-flexcan-add-transceiver-caps-v1-2-c6abb7817b0f@liebherr.com>
References: <20250211-flexcan-add-transceiver-caps-v1-0-c6abb7817b0f@liebherr.com>
In-Reply-To: <20250211-flexcan-add-transceiver-caps-v1-0-c6abb7817b0f@liebherr.com>
To: Marc Kleine-Budde <mkl@pengutronix.de>, 
 Vincent Mailhol <mailhol.vincent@wanadoo.fr>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-can@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, Dimitri Fedrau <dimitri.fedrau@liebherr.com>, 
 Dimitri Fedrau <dima.fedrau@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1739279554; l=3254;
 i=dimitri.fedrau@liebherr.com; s=20241202; h=from:subject:message-id;
 bh=MkScmJzMrjljm6Z+2YxSN5mrAzjdFqPq9BBLNkTJm7A=;
 b=EVN92FjdbZyxvcxPsWF5CnLlaCFU1m14KMU9FIwvcmpGUQi6Bqr+CYG7egBuEi4MJyO4pSYNf
 c/ypVbTExMsBj5wY22xvGuY63W9B9bIVim+pryJVx+w7A2JSKfAIO2D
X-Developer-Key: i=dimitri.fedrau@liebherr.com; a=ed25519;
 pk=rT653x09JSQvotxIqQl4/XiI4AOiBZrdOGvxDUbb5m8=
X-Endpoint-Received: by B4 Relay for dimitri.fedrau@liebherr.com/20241202 with auth_id=290
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Currently the flexcan driver does not support adding PHYs. Add the
capability to ensure that the PHY is in operational state when the link
is set to an "up" state.

Signed-off-by: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
---
 drivers/net/can/flexcan/flexcan-core.c | 25 +++++++++++++++++++------
 drivers/net/can/flexcan/flexcan.h      |  1 +
 2 files changed, 20 insertions(+), 6 deletions(-)

diff --git a/drivers/net/can/flexcan/flexcan-core.c b/drivers/net/can/flexcan/flexcan-core.c
index ac1a860986df69a1dd64c25ff879490d5b21073b..a03dc8e3c80546a0e2fa9a85f0e0cc8159afa4f0 100644
--- a/drivers/net/can/flexcan/flexcan-core.c
+++ b/drivers/net/can/flexcan/flexcan-core.c
@@ -30,6 +30,7 @@
 #include <linux/property.h>
 #include <linux/regmap.h>
 #include <linux/regulator/consumer.h>
+#include <linux/phy/phy.h>
 
 #include "flexcan.h"
 
@@ -634,18 +635,22 @@ static void flexcan_clks_disable(const struct flexcan_priv *priv)
 
 static inline int flexcan_transceiver_enable(const struct flexcan_priv *priv)
 {
-	if (!priv->reg_xceiver)
-		return 0;
+	if (priv->reg_xceiver)
+		return regulator_enable(priv->reg_xceiver);
+	else if (priv->xceiver)
+		return phy_power_on(priv->xceiver);
 
-	return regulator_enable(priv->reg_xceiver);
+	return 0;
 }
 
 static inline int flexcan_transceiver_disable(const struct flexcan_priv *priv)
 {
-	if (!priv->reg_xceiver)
-		return 0;
+	if (priv->reg_xceiver)
+		return regulator_disable(priv->reg_xceiver);
+	else if (priv->xceiver)
+		return phy_power_off(priv->xceiver);
 
-	return regulator_disable(priv->reg_xceiver);
+	return 0;
 }
 
 static int flexcan_chip_enable(struct flexcan_priv *priv)
@@ -2061,6 +2066,7 @@ static int flexcan_probe(struct platform_device *pdev)
 	struct net_device *dev;
 	struct flexcan_priv *priv;
 	struct regulator *reg_xceiver;
+	struct phy *xceiver;
 	struct clk *clk_ipg = NULL, *clk_per = NULL;
 	struct flexcan_regs __iomem *regs;
 	struct flexcan_platform_data *pdata;
@@ -2076,6 +2082,12 @@ static int flexcan_probe(struct platform_device *pdev)
 	else if (IS_ERR(reg_xceiver))
 		return PTR_ERR(reg_xceiver);
 
+	xceiver = devm_phy_optional_get(&pdev->dev, NULL);
+	if (IS_ERR(xceiver)) {
+		dev_err(&pdev->dev, "failed to get phy\n");
+		return PTR_ERR(xceiver);
+	}
+
 	if (pdev->dev.of_node) {
 		of_property_read_u32(pdev->dev.of_node,
 				     "clock-frequency", &clock_freq);
@@ -2173,6 +2185,7 @@ static int flexcan_probe(struct platform_device *pdev)
 	priv->clk_per = clk_per;
 	priv->clk_src = clk_src;
 	priv->reg_xceiver = reg_xceiver;
+	priv->xceiver = xceiver;
 
 	if (priv->devtype_data.quirks & FLEXCAN_QUIRK_NR_IRQ_3) {
 		priv->irq_boff = platform_get_irq(pdev, 1);
diff --git a/drivers/net/can/flexcan/flexcan.h b/drivers/net/can/flexcan/flexcan.h
index 4933d8c7439e62b5d6fcc445d88c2b5ccbfa13bb..56be40875eee24aee9297c4bc7c2fc4380e682ff 100644
--- a/drivers/net/can/flexcan/flexcan.h
+++ b/drivers/net/can/flexcan/flexcan.h
@@ -103,6 +103,7 @@ struct flexcan_priv {
 	struct clk *clk_per;
 	struct flexcan_devtype_data devtype_data;
 	struct regulator *reg_xceiver;
+	struct phy *xceiver;
 	struct flexcan_stop_mode stm;
 
 	int irq_boff;

-- 
2.39.5

