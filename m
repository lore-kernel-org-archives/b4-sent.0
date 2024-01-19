From: Yang Xiwen <forbidden405@outlook.com>
Date: Fri, 19 Jan 2024 19:44:29 +0800
Subject: [PATCH 2/3] net: hifemac: fix log reporting
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240119-net-v1-2-d1feb8e16ac6@outlook.com>
References: <20240119-net-v1-0-d1feb8e16ac6@outlook.com>
In-Reply-To: <20240119-net-v1-0-d1feb8e16ac6@outlook.com>
To: Joe Hershberger <joe.hershberger@ni.com>, 
 Ramon Fried <rfried.dev@gmail.com>
Cc: u-boot@lists.denx.de, Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1705664668; l=6569;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=5cyUg5mF3yyXwrX1AvQvJQpfQ3oNcmSAKW0TIb3hMNo=;
 b=rBWKUIacfePntWbEe8WOahDvInsAXVFEkmd89o4Oc2TY9w8hKYHHULkQHke64kb0H5d4iSQVD
 uHllfIdJcfYD1a6ef+A6k+Q1RxFMcYK/C15vghHBkxoA/uWBj5k6BjV
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

shrink the first argument of log_msg_ret(), add dev_xxx() functions for
error reporting.

Fixes: 9d8f78a2a79f7 ("net: add hifemac Ethernet driver for HiSilicon platform")

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
 drivers/net/hifemac.c | 110 +++++++++++++++++++++++++++++++++-----------------
 1 file changed, 73 insertions(+), 37 deletions(-)

diff --git a/drivers/net/hifemac.c b/drivers/net/hifemac.c
index b61a29e636..1088f3eca3 100644
--- a/drivers/net/hifemac.c
+++ b/drivers/net/hifemac.c
@@ -245,8 +245,10 @@ static int hisi_femac_start(struct udevice *dev)
 	hisi_femac_rx_refill(priv);
 
 	ret = phy_startup(priv->phy);
-	if (ret)
-		return log_msg_ret("Failed to startup phy", ret);
+	if (ret) {
+		dev_err(dev, "Failed to startup phy: %d\n", ret);
+		return log_msg_ret("phy", ret);
+	}
 
 	if (!priv->phy->link) {
 		debug("%s: link down\n", __func__);
@@ -281,8 +283,10 @@ static int hisi_femac_send(struct udevice *dev, void *packet, int length)
 
 	// wait until FIFO is empty
 	ret = wait_for_bit_le32(priv->glb_base + GLB_IRQ_RAW, IRQ_INT_TX_PER_PACKET, true, 50, false);
-	if (ret == -ETIMEDOUT)
-		return log_msg_ret("FIFO timeout", ret);
+	if (ret == -ETIMEDOUT) {
+		dev_err(dev, "FIFO timeout\n");
+		return log_msg_ret("net", ret);
+	}
 
 	return 0;
 }
@@ -340,35 +344,45 @@ int hisi_femac_of_to_plat(struct udevice *dev)
 	};
 
 	priv->port_base = dev_remap_addr_name(dev, "port");
-	if (IS_ERR(priv->port_base))
-		return log_msg_ret("Failed to remap port address space", PTR_ERR(priv->port_base));
+	if (!priv->port_base) {
+		dev_err(dev, "Failed to remap port address space\n");
+		return log_msg_ret("net", -EINVAL);
+	}
 
 	priv->glb_base = dev_remap_addr_name(dev, "glb");
-	if (IS_ERR(priv->glb_base))
-		return log_msg_ret("Failed to remap global address space", PTR_ERR(priv->glb_base));
+	if (IS_ERR(priv->glb_base)) {
+		dev_err(dev, "Failed to remap global address space\n");
+		return log_msg_ret("net", -EINVAL);
+	}
 
 	for (i = 0; i < ARRAY_SIZE(clk_strs); i++) {
 		priv->clks[i] = devm_clk_get(dev, clk_strs[i]);
 		if (IS_ERR(priv->clks[i])) {
 			dev_err(dev, "Error getting clock %s\n", clk_strs[i]);
-			return log_msg_ret("Failed to get clocks", PTR_ERR(priv->clks[i]));
+			return log_msg_ret("clk", PTR_ERR(priv->clks[i]));
 		}
 	}
 
 	priv->mac_rst = devm_reset_control_get(dev, "mac");
-	if (IS_ERR(priv->mac_rst))
-		return log_msg_ret("Failed to get MAC reset", PTR_ERR(priv->mac_rst));
+	if (IS_ERR(priv->mac_rst)) {
+		dev_err(dev, "Failed to get MAC reset %ld\n", PTR_ERR(priv->mac_rst));
+		return log_msg_ret("rst", PTR_ERR(priv->mac_rst));
+	}
 
 	priv->phy_rst = devm_reset_control_get(dev, "phy");
-	if (IS_ERR(priv->phy_rst))
-		return log_msg_ret("Failed to get PHY reset", PTR_ERR(priv->phy_rst));
+	if (IS_ERR(priv->phy_rst)) {
+		dev_err(dev, "Failed to get PHY reset %ld\n", PTR_ERR(priv->phy_rst));
+		return log_msg_ret("rst", PTR_ERR(priv->phy_rst));
+	}
 
 	ret = dev_read_u32_array(dev,
 				 PHY_RESET_DELAYS_PROPERTY,
 				 priv->phy_reset_delays,
 				 DELAYS_NUM);
-	if (ret < 0)
-		return log_msg_ret("Failed to get PHY reset delays", ret);
+	if (ret < 0) {
+		dev_err(dev, "Failed to get PHY reset delays %d\n", ret);
+		return log_msg_ret("rst", ret);
+	}
 
 	priv->mac_reset_delay = dev_read_u32_default(dev,
 						     MAC_RESET_DELAY_PROPERTY,
@@ -385,32 +399,44 @@ static int hisi_femac_phy_reset(struct hisi_femac_priv *priv)
 
 	// Disable MAC clk before phy reset
 	ret = clk_disable(priv->clks[CLK_MAC]);
-	if (ret < 0)
-		return log_msg_ret("Failed to disable MAC clock", ret);
+	if (ret < 0) {
+		pr_err("%s: Failed to disable MAC clock %d\n", __func__, ret);
+		return log_msg_ret("clk", ret);
+	}
 	ret = clk_disable(priv->clks[CLK_BUS]);
-	if (ret < 0)
-		return log_msg_ret("Failed to disable bus clock", ret);
+	if (ret < 0) {
+		pr_err("%s: Failed to disable bus clock %d\n", __func__, ret);
+		return log_msg_ret("clk", ret);
+	}
 
 	udelay(delays[PRE_DELAY]);
 
 	ret = reset_assert(rst);
-	if (ret < 0)
-		return log_msg_ret("Failed to assert reset", ret);
+	if (ret < 0) {
+		pr_err("%s: Failed to assert reset %d\n", __func__, ret);
+		return log_msg_ret("rst", ret);
+	}
 
 	udelay(delays[PULSE]);
 
 	ret = reset_deassert(rst);
-	if (ret < 0)
-		return log_msg_ret("Failed to deassert reset", ret);
+	if (ret < 0) {
+		pr_err("%s: Failed to deassert reset %d\n", __func__, ret);
+		return log_msg_ret("rst", ret);
+	}
 
 	udelay(delays[POST_DELAY]);
 
 	ret = clk_enable(priv->clks[CLK_MAC]);
-	if (ret < 0)
-		return log_msg_ret("Failed to enable MAC clock", ret);
+	if (ret < 0) {
+		pr_err("%s: Failed to enable MAC clock %d\n", __func__, ret);
+		return log_msg_ret("clk", ret);
+	}
 	ret = clk_enable(priv->clks[CLK_BUS]);
-	if (ret < 0)
-		return log_msg_ret("Failed to enable MAC bus clock", ret);
+	if (ret < 0) {
+		pr_err("%s: Failed to enable MAC bus clock %d\n", __func__, ret);
+		return log_msg_ret("clk", ret);
+	}
 
 	return 0;
 }
@@ -423,30 +449,40 @@ int hisi_femac_probe(struct udevice *dev)
 	// Enable clocks
 	for (i = 0; i < CLK_NUM; i++) {
 		ret = clk_prepare_enable(priv->clks[i]);
-		if (ret < 0)
-			return log_msg_ret("Failed to enable clks", ret);
+		if (ret < 0) {
+			dev_err(dev, "Failed to enable clk %d: %d\n", i, ret);
+			return log_msg_ret("clk", ret);
+		}
 	}
 
 	// Reset MAC
 	ret = reset_assert(priv->mac_rst);
-	if (ret < 0)
-		return log_msg_ret("Failed to assert MAC reset", ret);
+	if (ret < 0) {
+		dev_err(dev, "Failed to assert MAC reset: %d\n", ret);
+		return log_msg_ret("net", ret);
+	}
 
 	udelay(priv->mac_reset_delay);
 
 	ret = reset_deassert(priv->mac_rst);
-	if (ret < 0)
-		return log_msg_ret("Failed to deassert MAC reset", ret);
+	if (ret < 0) {
+		dev_err(dev, "Failed to deassert MAC reset: %d\n", ret);
+		return log_msg_ret("net", ret);
+	}
 
 	// Reset PHY
 	ret = hisi_femac_phy_reset(priv);
-	if (ret < 0)
-		return log_msg_ret("Failed to reset phy", ret);
+	if (ret < 0) {
+		dev_err(dev, "Failed to reset PHY: %d\n", ret);
+		return log_msg_ret("net", ret);
+	}
 
 	// Connect to PHY
 	priv->phy = dm_eth_phy_connect(dev);
-	if (!priv->phy)
-		return log_msg_ret("Failed to connect to phy", -EINVAL);
+	if (!priv->phy) {
+		dev_err(dev, "Failed to connect to phy\n");
+		return log_msg_ret("phy", -EINVAL);
+	}
 
 	hisi_femac_port_init(priv);
 	return 0;

-- 
2.43.0

