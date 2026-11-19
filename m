From: Kyle Hendry <khendry@reliablecontrols.com>
Date: Thu, 19 Nov 2026 09:57:44 -0800
Subject: [PATCH 2/6] clk: renesas: r9a06g032: Add reset controller
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261119-rzn1-miic-resets-v1-2-feee2bb28bb4@reliablecontrols.com>
References: <20261119-rzn1-miic-resets-v1-0-feee2bb28bb4@reliablecontrols.com>
In-Reply-To: <20261119-rzn1-miic-resets-v1-0-feee2bb28bb4@reliablecontrols.com>
To: Geert Uytterhoeven <geert+renesas@glider.be>, 
 Stephen Boyd <sboyd@kernel.org>, Brian Masney <bmasney+clk@redhat.com>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Magnus Damm <magnus.damm@gmail.com>, 
 Fabrizio Castro <fabrizio.castro.jz@renesas.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>, 
 =?utf-8?q?Cl=C3=A9ment_L=C3=A9ger?= <clement.leger@bootlin.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Lad Prabhakar <prabhakar.mahadev-lad.rj@bp.renesas.com>, 
 Andrew Lunn <andrew@lunn.ch>, Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>
Cc: linux-renesas-soc@vger.kernel.org, linux-clk@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 netdev@vger.kernel.org, Kyle Hendry <khendry@reliablecontrols.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795111097; l=3698;
 i=khendry@reliablecontrols.com; s=20260813; h=from:subject:message-id;
 bh=K55PGhDwoeO0SnRKw9KIc71iX+MI6F5UGeo6Fl4rgqg=;
 b=/xzBEMOSa6Ag5ThW111yAz4JSl7e4KnR37Ab2clbt8Jk+rmxL1fmeISH6HFSHk14JLdZLQ0rY
 UOyw+PTObnyDihP9ReuckRXnsv1MEMkerCQCaPpz7bAT++Rk5kh5kF0
X-Developer-Key: i=khendry@reliablecontrols.com; a=ed25519;
 pk=gbK6oghz3qBlBiaGCsEzALLOtj5VklmsuolHQNhDV5M=
X-Endpoint-Received: by B4 Relay for khendry@reliablecontrols.com/20260813 with auth_id=946
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The rzn1 system controller has two resets that need to be cleared for the
mii converter to work. They are not directly associated with any clocks
so they need a reset controller to set them.

They are documented in the PWRCTRL_SWITCHCTRL (0x4000C188) register as:

Bit 3: RSTN_CLK25 - Active low Reset for Timestamp signal selection logic
Bit 4: RSTN_ETH - Active low Reset for RGMII/RMII Converter (50 MHz).

Add a reset controller and add resets for those bits.

Signed-off-by: Kyle Hendry <khendry@reliablecontrols.com>
---
 drivers/clk/renesas/r9a06g032-clocks.c | 64 ++++++++++++++++++++++++++++++++++
 1 file changed, 64 insertions(+)

diff --git a/drivers/clk/renesas/r9a06g032-clocks.c b/drivers/clk/renesas/r9a06g032-clocks.c
index 3df3f2b2c6de..547e8d82f1cf 100644
--- a/drivers/clk/renesas/r9a06g032-clocks.c
+++ b/drivers/clk/renesas/r9a06g032-clocks.c
@@ -21,6 +21,7 @@
 #include <linux/pm_clock.h>
 #include <linux/pm_domain.h>
 #include <linux/reboot.h>
+#include <linux/reset-controller.h>
 #include <linux/slab.h>
 #include <linux/soc/renesas/r9a06g032-sysctrl.h>
 #include <linux/spinlock.h>
@@ -675,6 +676,11 @@ static const struct r9a06g032_clkdesc r9a06g032_clocks[] = {
 		RB(0xec, 16), RB(0xec, 17), RB(0xec, 18), RB(0xec, 19)),
 };
 
+static const struct regbit r9a06g032_resets[] = {
+	RB(0x188, 3),
+	RB(0x188, 4),
+};
+
 struct r9a06g032_priv {
 	struct clk_onecell_data data;
 	spinlock_t lock; /* protects concurrent access to gates */
@@ -1307,6 +1313,56 @@ static void __init r9a06g032_init_h2mode(struct r9a06g032_priv *clocks)
 	writel(usb, clocks->reg + R9A06G032_SYSCTRL_USB);
 }
 
+
+#define rcdev_to_priv(x)	container_of(x, struct r9a06g032_priv, rcdev)
+
+static int r9a06g032_reset_set(struct reset_controller_dev *rcdev,
+				  const char *func, bool set, unsigned long id)
+{
+	struct r9a06g032_priv *priv = rcdev_to_priv(rcdev);
+	unsigned long flags;
+
+	spin_lock_irqsave(&priv->lock, flags);
+	clk_rdesc_set(priv, r9a06g032_resets[id], set);
+	spin_unlock_irqrestore(&priv->lock, flags);
+
+	return 0;
+}
+
+static int r9a06g032_reset(struct reset_controller_dev *rcdev,
+			  unsigned long id)
+{
+	r9a06g032_reset_set(rcdev, "reset", true, id);
+	udelay(5);
+	return r9a06g032_reset_set(rcdev, NULL, false, id);
+}
+
+static int r9a06g032_reset_assert(struct reset_controller_dev *rcdev, unsigned long id)
+{
+	return r9a06g032_reset_set(rcdev, "assert", false, id);
+}
+
+static int r9a06g032_reset_deassert(struct reset_controller_dev *rcdev,
+			     unsigned long id)
+{
+	return r9a06g032_reset_set(rcdev, "deassert", true, id);
+}
+
+static int r9a06g032_reset_status(struct reset_controller_dev *rcdev,
+			   unsigned long id)
+{
+	struct r9a06g032_priv *priv = rcdev_to_priv(rcdev);
+
+	return clk_rdesc_get(priv, r9a06g032_resets[id]);
+}
+
+static const struct reset_control_ops r9a06g032_reset_ops = {
+	.reset = r9a06g032_reset,
+	.assert = r9a06g032_reset_assert,
+	.deassert = r9a06g032_reset_deassert,
+	.status = r9a06g032_reset_status,
+};
+
 static int __init r9a06g032_clocks_probe(struct platform_device *pdev)
 {
 	struct device *dev = &pdev->dev;
@@ -1404,6 +1460,14 @@ static int __init r9a06g032_clocks_probe(struct platform_device *pdev)
 	if (error)
 		dev_err(dev, "Failed to populate children (%d)\n", error);
 
+	clocks->rcdev.ops = &r9a06g032_reset_ops;
+	clocks->rcdev.of_node = np;
+	clocks->rcdev.of_reset_n_cells = 1;
+	clocks->rcdev.nr_resets = ARRAY_SIZE(r9a06g032_resets);
+	error =  devm_reset_controller_register(dev, &clocks->rcdev);
+	if (error)
+		return error;
+
 	return 0;
 }
 

-- 
2.53.0

