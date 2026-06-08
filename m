From: George Moussalem <george.moussalem@outlook.com>
Date: Mon, 08 Jun 2026 09:09:19 +0400
Subject: [PATCH v4 4/4] net: phy: at803x: add RX and TX clock management
 for IPQ5018 PHY
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260608-ipq5018-gephy-clocks-v4-4-fb2ccd56894b@outlook.com>
References: <20260608-ipq5018-gephy-clocks-v4-0-fb2ccd56894b@outlook.com>
In-Reply-To: <20260608-ipq5018-gephy-clocks-v4-0-fb2ccd56894b@outlook.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780895363; l=1756;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=m5xYoQj/G89J7xqhL2YgJahZAGwlkkCV+b0laCqNRBU=;
 b=a9b6VnFuOhU7qXWN2B1DLPAgtbLDyESVPuHBhkQs6Jd27gKLy1uQ+QhPfQyBQnepDm8c+rNSi
 MHqnN6UFaKXAJ/BZidcIBUyQvDrs7SPjT5eUAJRnjP9UwNlGnji3gVd
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Acquire and enable the RX and TX clocks for the IPQ5018 PHY.
These clocks are required for the PHY's datapath to function correctly.

Fixes: d46502279a11 ("net: phy: qcom: at803x: Add Qualcomm IPQ5018 Internal PHY support")
Signed-off-by: George Moussalem <george.moussalem@outlook.com>
---
 drivers/net/phy/qcom/at803x.c | 12 ++++++++++++
 1 file changed, 12 insertions(+)

diff --git a/drivers/net/phy/qcom/at803x.c b/drivers/net/phy/qcom/at803x.c
index 63726cf98cd4..ba4dc07752b6 100644
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
@@ -1074,6 +1075,7 @@ static void ipq5018_link_change_notify(struct phy_device *phydev)
 static int ipq5018_probe(struct phy_device *phydev)
 {
 	struct device *dev = &phydev->mdio.dev;
+	struct clk *rx_clk, *tx_clk;
 	struct ipq5018_priv *priv;
 	int ret;
 
@@ -1084,6 +1086,16 @@ static int ipq5018_probe(struct phy_device *phydev)
 	priv->set_short_cable_dac = of_property_read_bool(dev->of_node,
 							  "qcom,dac-preset-short-cable");
 
+	rx_clk = devm_clk_get_enabled(dev, "rx");
+	if (IS_ERR(rx_clk))
+		return dev_err_probe(dev, PTR_ERR(rx_clk),
+				     "failed to get and enable RX clock\n");
+
+	tx_clk = devm_clk_get_enabled(dev, "tx");
+	if (IS_ERR(tx_clk))
+		return dev_err_probe(dev, PTR_ERR(tx_clk),
+				     "failed to get and enable TX clock\n");
+
 	priv->rst = devm_reset_control_array_get_exclusive(dev);
 	if (IS_ERR(priv->rst))
 		return dev_err_probe(dev, PTR_ERR(priv->rst),

-- 
2.53.0

