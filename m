From: Joseph Telaak <joseph@telaak.dev>
Date: Thu, 12 Nov 2026 16:39:41 -0500
Subject: [PATCH net-next v3 2/2] net: dsa: mxl-gsw1xx: reset the switch
 through reset-gpios
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261112-mxl-gsw1xx-reset-v3-2-863e82074893@telaak.dev>
References: <20261112-mxl-gsw1xx-reset-v3-0-863e82074893@telaak.dev>
In-Reply-To: <20261112-mxl-gsw1xx-reset-v3-0-863e82074893@telaak.dev>
To: Hauke Mehrtens <hauke@hauke-m.de>, Andrew Lunn <andrew@lunn.ch>, 
 Vladimir Oltean <olteanv@gmail.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: Daniel Golle <daniel@makrotopia.org>, 
 Philipp Zabel <p.zabel@pengutronix.de>, netdev@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Joseph Telaak <joseph@telaak.dev>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794519588; l=3553;
 i=joseph@telaak.dev; s=20261104; h=from:subject:message-id;
 bh=WZYxeaFGDWxSpN7GzuooSUNjWaVXrTqutE63YR5JtU0=;
 b=gBIElyAt9sK0h91F8d58bV1C+Ls9eNK6vVg0iJzPMMHj54lGxmP2K0mGcfX/Zf1nnV6pB0WUe
 0Gq71vWKYwcBLZa7K2oTk8pOtDEXMLCKA2l2wfsiOy/vxKAzYZN4lai
X-Developer-Key: i=joseph@telaak.dev; a=ed25519;
 pk=oQI+UfddlZ0wK2ac4WKOGNjUl1ZEN8j9ZVFSqEDoNP0=
X-Endpoint-Received: by B4 Relay for joseph@telaak.dev/20261104 with auth_id=1404
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The switch keeps the configuration the bootloader left in it, and the
driver never resets it. The MDIO core asserts and releases reset-gpios
only for PHY devices, so a reset line described on the switch node has
no effect either.

On the GL.iNet GL-SFT1200 the bootloader leaves each internal PHY of
the GSW150 one MDIO address above its port. Port 0 then fails with
"failed to connect to PHY: -ENODEV", and the PHY that answers at a
port's address belongs to the neighboring port. After a hardware reset
every PHY is back at its port's address and all ports work.

Get the reset through the reset controller API and pulse it before the
first register access. The reset core hands a reset-gpios property to
the reset-gpio driver, so a board that wires the reset this way needs
CONFIG_RESET_GPIO; without it the reset is skipped. The timing follows
the vendor's driver for the GSW150: asserted for 250 ms, then 1 s before
the switch is accessed.

The reset also returns the RGMII slew rates to their power-on defaults,
so a board that uses reset-gpios sets the ones it needs in its device
tree.

Signed-off-by: Joseph Telaak <joseph@telaak.dev>
---
 drivers/net/dsa/lantiq/mxl-gsw1xx.c | 26 ++++++++++++++++++++++++++
 drivers/net/dsa/lantiq/mxl-gsw1xx.h |  4 ++++
 2 files changed, 30 insertions(+)

diff --git a/drivers/net/dsa/lantiq/mxl-gsw1xx.c b/drivers/net/dsa/lantiq/mxl-gsw1xx.c
index a26f78e1a4..f69856a65b 100644
--- a/drivers/net/dsa/lantiq/mxl-gsw1xx.c
+++ b/drivers/net/dsa/lantiq/mxl-gsw1xx.c
@@ -18,6 +18,7 @@
 #include <linux/phy/phy-common-props.h>
 #include <linux/property.h>
 #include <linux/regmap.h>
+#include <linux/reset.h>
 #include <linux/workqueue.h>
 #include <net/dsa.h>
 
@@ -719,6 +720,7 @@ static int gsw1xx_serdes_pcs_init(struct gsw1xx_priv *priv)
 static int gsw1xx_probe(struct mdio_device *mdiodev)
 {
 	struct device *dev = &mdiodev->dev;
+	struct reset_control *reset;
 	struct gsw1xx_priv *priv;
 	u32 version, val;
 	u8 shellver;
@@ -737,6 +739,30 @@ static int gsw1xx_probe(struct mdio_device *mdiodev)
 	if (!priv->gswip.hw_info)
 		return -EINVAL;
 
+	/* The MDIO core handles reset-gpios only for PHYs. Reset the switch
+	 * here, so it does not run with whatever the bootloader configured.
+	 */
+	reset = devm_reset_control_get_optional_exclusive(dev, NULL);
+	if (IS_ERR(reset))
+		return dev_err_probe(dev, PTR_ERR(reset),
+				     "failed to get reset control\n");
+
+	if (reset) {
+		ret = reset_control_assert(reset);
+		if (ret)
+			return dev_err_probe(dev, ret,
+					     "failed to assert reset\n");
+
+		fsleep(GSW1XX_RESET_ASSERT_US);
+
+		ret = reset_control_deassert(reset);
+		if (ret)
+			return dev_err_probe(dev, ret,
+					     "failed to deassert reset\n");
+
+		fsleep(GSW1XX_RESET_DEASSERT_US);
+	}
+
 	priv->gswip.gswip = gsw1xx_regmap_init(priv, "switch",
 					       GSW1XX_SWITCH_BASE, 0xfff);
 	if (IS_ERR(priv->gswip.gswip))
diff --git a/drivers/net/dsa/lantiq/mxl-gsw1xx.h b/drivers/net/dsa/lantiq/mxl-gsw1xx.h
index 81bc00eabb..bca8e3223c 100644
--- a/drivers/net/dsa/lantiq/mxl-gsw1xx.h
+++ b/drivers/net/dsa/lantiq/mxl-gsw1xx.h
@@ -19,6 +19,10 @@
 
 #define GSW1XX_SYS_CLK_FREQ			340000000
 
+/* Hardware reset timing of the vendor's driver for the GSW150 */
+#define GSW1XX_RESET_ASSERT_US			250000
+#define GSW1XX_RESET_DEASSERT_US		1000000
+
 /* SMDIO switch register base address */
 #define GSW1XX_SMDIO_BADR			0x1f
 #define  GSW1XX_SMDIO_BADR_UNKNOWN		-1

-- 
Git-155)

