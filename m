From: George Moussalem <george.moussalem@outlook.com>
Date: Tue, 02 Jun 2026 10:50:40 +0400
Subject: [PATCH v2 4/4] net: phy: at803x: add RX and TX clock management
 for IPQ5018 PHY
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260602-ipq5018-gephy-clocks-v2-4-65a1f1d881f3@outlook.com>
References: <20260602-ipq5018-gephy-clocks-v2-0-65a1f1d881f3@outlook.com>
In-Reply-To: <20260602-ipq5018-gephy-clocks-v2-0-65a1f1d881f3@outlook.com>
To: Andrew Lunn <andrew@lunn.ch>, Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Florian Fainelli <f.fainelli@gmail.com>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: netdev@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 linux-arm-msm@vger.kernel.org, 
 George Moussalem <george.moussalem@outlook.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780383045; l=2335;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=k3J1uSCRHsxM9xs2etq4AynajTAyY7ew0xbYTGGX5vo=;
 b=XC5MLpTjeARQV5btxnH3uknIg5JztVn3Er5vSILfOriN654qinR4wnWCSN1B5UZvEJ7YlWLqc
 0iQjrlnoEJwC2KaGibXI3KCX9TFRvlgCfTjHcqt1nqkAfBJbc8wP2hi
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Acquire and enable the RX and TX clocks for the IPQ5018 PHY. These
clocks are required for the PHY's datapath to function correctly.
In addition, gate the clocks upon link state changes for improved power
management.

Fixes: d46502279a11 ("net: phy: qcom: at803x: Add Qualcomm IPQ5018 Internal PHY support")
Signed-off-by: George Moussalem <george.moussalem@outlook.com>
---
 drivers/net/phy/qcom/at803x.c | 23 +++++++++++++++++++++++
 1 file changed, 23 insertions(+)

diff --git a/drivers/net/phy/qcom/at803x.c b/drivers/net/phy/qcom/at803x.c
index 63726cf98cd4..b7361a14220d 100644
--- a/drivers/net/phy/qcom/at803x.c
+++ b/drivers/net/phy/qcom/at803x.c
@@ -19,6 +19,7 @@
 #include <linux/regulator/consumer.h>
 #include <linux/of.h>
 #include <linux/phylink.h>
+#include <linux/clk.h>
 #include <linux/reset.h>
 #include <linux/phy_port.h>
 #include <dt-bindings/net/qca-ar803x.h>
@@ -176,6 +177,8 @@ struct at803x_context {
 };
 
 struct ipq5018_priv {
+	struct clk *rx_clk;
+	struct clk *tx_clk;
 	struct reset_control *rst;
 	bool set_short_cable_dac;
 };
@@ -1062,6 +1065,16 @@ static int ipq5018_config_init(struct phy_device *phydev)
 
 static void ipq5018_link_change_notify(struct phy_device *phydev)
 {
+	struct ipq5018_priv *priv = phydev->priv;
+
+	if (phydev->link) {
+		clk_enable(priv->rx_clk);
+		clk_enable(priv->tx_clk);
+	} else {
+		clk_disable(priv->rx_clk);
+		clk_disable(priv->tx_clk);
+	}
+
 	/*
 	 * Reset the FIFO buffer upon link disconnects to clear any residual data
 	 * which may cause issues with the FIFO which it cannot recover from.
@@ -1084,6 +1097,16 @@ static int ipq5018_probe(struct phy_device *phydev)
 	priv->set_short_cable_dac = of_property_read_bool(dev->of_node,
 							  "qcom,dac-preset-short-cable");
 
+	priv->rx_clk = devm_clk_get_enabled(dev, "rx");
+	if (IS_ERR(priv->rx_clk))
+		return dev_err_probe(dev, PTR_ERR(priv->rx_clk),
+				     "failed to get and enable RX clock\n");
+
+	priv->tx_clk = devm_clk_get_enabled(dev, "tx");
+	if (IS_ERR(priv->tx_clk))
+		return dev_err_probe(dev, PTR_ERR(priv->tx_clk),
+				     "failed to get and enable TX clock\n");
+
 	priv->rst = devm_reset_control_array_get_exclusive(dev);
 	if (IS_ERR(priv->rst))
 		return dev_err_probe(dev, PTR_ERR(priv->rst),

-- 
2.53.0

