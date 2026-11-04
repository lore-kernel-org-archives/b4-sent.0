From: Joseph Telaak <joseph@telaak.dev>
Date: Wed, 04 Nov 2026 02:15:48 -0500
Subject: [PATCH net-next 2/2] net: dsa: mxl-gsw1xx: reset the switch
 through reset-gpios
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261104-mxl-gsw1xx-reset-v1-2-53839bf5c88e@telaak.dev>
References: <20261104-mxl-gsw1xx-reset-v1-0-53839bf5c88e@telaak.dev>
In-Reply-To: <20261104-mxl-gsw1xx-reset-v1-0-53839bf5c88e@telaak.dev>
To: Hauke Mehrtens <hauke@hauke-m.de>, Andrew Lunn <andrew@lunn.ch>, 
 Vladimir Oltean <olteanv@gmail.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: Daniel Golle <daniel@makrotopia.org>, netdev@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Joseph Telaak <joseph@telaak.dev>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793776564; l=2985;
 i=joseph@telaak.dev; s=20261104; h=from:subject:message-id;
 bh=uztjZiDQnh4Ex7diNq4uofcWFk+cr6zOCxuZ3l2XlYg=;
 b=4cWp3cP7Blg0M1aZhb89CvDwiLWOaRhkkQMswf6pp/ckEDthOZ2N5ReLWTY0bc6KWr74oq12O
 12uuKsNlIncBHieETviuLGLK10lNLqGEZI1YTI565wf96Mr3wTx3FzK
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
port's address belongs to the neighbouring port. After a hardware reset
every PHY is back at its port's address and all ports work.

Request the reset GPIO in the driver and pulse it before the first
register access. The timing follows the vendor driver: asserted for
2 ms, then 100 ms before the switch is accessed.

Signed-off-by: Joseph Telaak <joseph@telaak.dev>
---
 drivers/net/dsa/lantiq/mxl-gsw1xx.c | 16 ++++++++++++++++
 drivers/net/dsa/lantiq/mxl-gsw1xx.h |  4 ++++
 2 files changed, 20 insertions(+)

diff --git a/drivers/net/dsa/lantiq/mxl-gsw1xx.c b/drivers/net/dsa/lantiq/mxl-gsw1xx.c
index a26f78e1a4..8767c8cf1d 100644
--- a/drivers/net/dsa/lantiq/mxl-gsw1xx.c
+++ b/drivers/net/dsa/lantiq/mxl-gsw1xx.c
@@ -11,6 +11,7 @@
 
 #include <linux/bits.h>
 #include <linux/delay.h>
+#include <linux/gpio/consumer.h>
 #include <linux/jiffies.h>
 #include <linux/module.h>
 #include <linux/of_device.h>
@@ -719,6 +720,7 @@ static int gsw1xx_serdes_pcs_init(struct gsw1xx_priv *priv)
 static int gsw1xx_probe(struct mdio_device *mdiodev)
 {
 	struct device *dev = &mdiodev->dev;
+	struct gpio_desc *reset_gpio;
 	struct gsw1xx_priv *priv;
 	u32 version, val;
 	u8 shellver;
@@ -737,6 +739,20 @@ static int gsw1xx_probe(struct mdio_device *mdiodev)
 	if (!priv->gswip.hw_info)
 		return -EINVAL;
 
+	/* The MDIO core handles reset-gpios only for PHYs. Reset the switch
+	 * here, so it does not run with whatever the bootloader configured.
+	 */
+	reset_gpio = devm_gpiod_get_optional(dev, "reset", GPIOD_OUT_HIGH);
+	if (IS_ERR(reset_gpio))
+		return dev_err_probe(dev, PTR_ERR(reset_gpio),
+				     "failed to get reset GPIO\n");
+
+	if (reset_gpio) {
+		fsleep(GSW1XX_RESET_ASSERT_US);
+		gpiod_set_value_cansleep(reset_gpio, 0);
+		fsleep(GSW1XX_RESET_DEASSERT_US);
+	}
+
 	priv->gswip.gswip = gsw1xx_regmap_init(priv, "switch",
 					       GSW1XX_SWITCH_BASE, 0xfff);
 	if (IS_ERR(priv->gswip.gswip))
diff --git a/drivers/net/dsa/lantiq/mxl-gsw1xx.h b/drivers/net/dsa/lantiq/mxl-gsw1xx.h
index 81bc00eabb..684bb135bc 100644
--- a/drivers/net/dsa/lantiq/mxl-gsw1xx.h
+++ b/drivers/net/dsa/lantiq/mxl-gsw1xx.h
@@ -19,6 +19,10 @@
 
 #define GSW1XX_SYS_CLK_FREQ			340000000
 
+/* Hardware reset timing, as the vendor driver for the GSW150 does it */
+#define GSW1XX_RESET_ASSERT_US			2000
+#define GSW1XX_RESET_DEASSERT_US		100000
+
 /* SMDIO switch register base address */
 #define GSW1XX_SMDIO_BADR			0x1f
 #define  GSW1XX_SMDIO_BADR_UNKNOWN		-1

-- 
Git-155)

