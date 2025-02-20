From: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
Date: Thu, 20 Feb 2025 09:22:11 +0100
Subject: [PATCH v2 2/2] can: flexcan: add transceiver capabilities
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250220-flexcan-add-transceiver-caps-v2-2-a81970f11846@liebherr.com>
References: <20250220-flexcan-add-transceiver-caps-v2-0-a81970f11846@liebherr.com>
In-Reply-To: <20250220-flexcan-add-transceiver-caps-v2-0-a81970f11846@liebherr.com>
To: Marc Kleine-Budde <mkl@pengutronix.de>, 
 Vincent Mailhol <mailhol.vincent@wanadoo.fr>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-can@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, Dimitri Fedrau <dimitri.fedrau@liebherr.com>, 
 Dimitri Fedrau <dima.fedrau@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1740039736; l=3553;
 i=dimitri.fedrau@liebherr.com; s=20241202; h=from:subject:message-id;
 bh=f8wDtbBWhus6CF2XVFXMOTBwX1LOfB9aOJZ29pdlyPo=;
 b=KAivBnF5zPSH30Mj67FkakzqX5s1r5WVPqiTqjmCpacvj9n9tzdGarouQAWwyu+HGSqaF+QqJ
 UypJUj41D73Aii3H79QYLeqcq8wuKB4GYtGlx0VKHldR2Z4HyWsPUCJ
X-Developer-Key: i=dimitri.fedrau@liebherr.com; a=ed25519;
 pk=rT653x09JSQvotxIqQl4/XiI4AOiBZrdOGvxDUbb5m8=
X-Endpoint-Received: by B4 Relay for dimitri.fedrau@liebherr.com/20241202 with auth_id=290
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Currently the flexcan driver does only support adding PHYs by using the
"old" regulator bindings. Add support for CAN transceivers as a PHY. Add
the capability to ensure that the PHY is in operational state when the link
is set to an "up" state.

Signed-off-by: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
---
 drivers/net/can/flexcan/flexcan-core.c | 30 ++++++++++++++++++++++++------
 drivers/net/can/flexcan/flexcan.h      |  1 +
 2 files changed, 25 insertions(+), 6 deletions(-)

diff --git a/drivers/net/can/flexcan/flexcan-core.c b/drivers/net/can/flexcan/flexcan-core.c
index b347a1c93536d54efaa5f7d3347bd47c20860b3e..45d9a6957d9a806ed80d810a6a5f7eb99fcc702c 100644
--- a/drivers/net/can/flexcan/flexcan-core.c
+++ b/drivers/net/can/flexcan/flexcan-core.c
@@ -30,6 +30,7 @@
 #include <linux/property.h>
 #include <linux/regmap.h>
 #include <linux/regulator/consumer.h>
+#include <linux/phy/phy.h>
 
 #include "flexcan.h"
 
@@ -644,18 +645,22 @@ static void flexcan_clks_disable(const struct flexcan_priv *priv)
 
 static inline int flexcan_transceiver_enable(const struct flexcan_priv *priv)
 {
-	if (!priv->reg_xceiver)
-		return 0;
+	if (priv->reg_xceiver)
+		return regulator_enable(priv->reg_xceiver);
+	else if (priv->transceiver)
+		return phy_power_on(priv->transceiver);
 
-	return regulator_enable(priv->reg_xceiver);
+	return 0;
 }
 
 static inline int flexcan_transceiver_disable(const struct flexcan_priv *priv)
 {
-	if (!priv->reg_xceiver)
-		return 0;
+	if (priv->reg_xceiver)
+		return regulator_disable(priv->reg_xceiver);
+	else if (priv->transceiver)
+		return phy_power_off(priv->transceiver);
 
-	return regulator_disable(priv->reg_xceiver);
+	return 0;
 }
 
 static int flexcan_chip_enable(struct flexcan_priv *priv)
@@ -2086,6 +2091,7 @@ static int flexcan_probe(struct platform_device *pdev)
 	struct net_device *dev;
 	struct flexcan_priv *priv;
 	struct regulator *reg_xceiver;
+	struct phy *transceiver;
 	struct clk *clk_ipg = NULL, *clk_per = NULL;
 	struct flexcan_regs __iomem *regs;
 	struct flexcan_platform_data *pdata;
@@ -2101,6 +2107,14 @@ static int flexcan_probe(struct platform_device *pdev)
 	else if (IS_ERR(reg_xceiver))
 		return PTR_ERR(reg_xceiver);
 
+	transceiver = devm_phy_optional_get(&pdev->dev, NULL);
+	if (PTR_ERR(transceiver) == -EPROBE_DEFER) {
+		return -EPROBE_DEFER;
+	} else if (IS_ERR(transceiver)) {
+		dev_err(&pdev->dev, "failed to get phy\n");
+		return PTR_ERR(transceiver);
+	}
+
 	if (pdev->dev.of_node) {
 		of_property_read_u32(pdev->dev.of_node,
 				     "clock-frequency", &clock_freq);
@@ -2198,6 +2212,10 @@ static int flexcan_probe(struct platform_device *pdev)
 	priv->clk_per = clk_per;
 	priv->clk_src = clk_src;
 	priv->reg_xceiver = reg_xceiver;
+	priv->transceiver = transceiver;
+
+	if (transceiver)
+		priv->can.bitrate_max = transceiver->attrs.max_link_rate;
 
 	if (priv->devtype_data.quirks & FLEXCAN_QUIRK_NR_IRQ_3) {
 		priv->irq_boff = platform_get_irq(pdev, 1);
diff --git a/drivers/net/can/flexcan/flexcan.h b/drivers/net/can/flexcan/flexcan.h
index 2cf886618c9621166173b865f266830b3f6c1fb0..16692a2502eba26575eeeec83dfffdf35f07b034 100644
--- a/drivers/net/can/flexcan/flexcan.h
+++ b/drivers/net/can/flexcan/flexcan.h
@@ -107,6 +107,7 @@ struct flexcan_priv {
 	struct clk *clk_per;
 	struct flexcan_devtype_data devtype_data;
 	struct regulator *reg_xceiver;
+	struct phy *transceiver;
 	struct flexcan_stop_mode stm;
 
 	int irq_boff;

-- 
2.39.5

