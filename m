From: Kyle Hendry <khendry@reliablecontrols.com>
Date: Wed, 25 Nov 2026 07:53:44 -0800
Subject: [PATCH v3 2/3] clk: renesas: r9a06g032: Add reset controller
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261125-rzn1-miic-resets-v3-2-f25a4b656d71@reliablecontrols.com>
References: <20261125-rzn1-miic-resets-v3-0-f25a4b656d71@reliablecontrols.com>
In-Reply-To: <20261125-rzn1-miic-resets-v3-0-f25a4b656d71@reliablecontrols.com>
To: Geert Uytterhoeven <geert+renesas@glider.be>, 
 Stephen Boyd <sboyd@kernel.org>, Brian Masney <bmasney+clk@redhat.com>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Magnus Damm <magnus.damm@gmail.com>, 
 Fabrizio Castro <fabrizio.castro.jz@renesas.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>
Cc: linux-renesas-soc@vger.kernel.org, linux-clk@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Kyle Hendry <khendry@reliablecontrols.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795622048; l=3636;
 i=khendry@reliablecontrols.com; s=20260813; h=from:subject:message-id;
 bh=8ZpDxQOtHtigAsvBd6sduY/iCNGxQHa4R86Sa1oElX8=;
 b=3IWaBuVyNriTbMUZ8sKQJUQtljALgnBry5hL/52CYiCLzk6EwoKVjIm9FC3NbsraltXKoTDYG
 rb7Vf5AztoyCWbJm3aIirjfqWD4Q34ya2EyHu3cF79GHAnapzkv1aVr
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
 drivers/clk/renesas/r9a06g032-clocks.c | 59 ++++++++++++++++++++++++++++++++++
 1 file changed, 59 insertions(+)

diff --git a/drivers/clk/renesas/r9a06g032-clocks.c b/drivers/clk/renesas/r9a06g032-clocks.c
index 3df3f2b2c6de..fc4433c3d327 100644
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
@@ -675,10 +676,16 @@ static const struct r9a06g032_clkdesc r9a06g032_clocks[] = {
 		RB(0xec, 16), RB(0xec, 17), RB(0xec, 18), RB(0xec, 19)),
 };
 
+static const struct regbit r9a06g032_resets[] = {
+	[R9A06G032_RST_TS]	= RB(0x188, 3),
+	[R9A06G032_RST_MIIC]	= RB(0x188, 4),
+};
+
 struct r9a06g032_priv {
 	struct clk_onecell_data data;
 	spinlock_t lock; /* protects concurrent access to gates */
 	void __iomem *reg;
+	struct reset_controller_dev rcdev;
 };
 
 static struct r9a06g032_priv *sysctrl_priv;
@@ -1307,6 +1314,51 @@ static void __init r9a06g032_init_h2mode(struct r9a06g032_priv *clocks)
 	writel(usb, clocks->reg + R9A06G032_SYSCTRL_USB);
 }
 
+static inline
+struct r9a06g032_priv *priv_from_rcdev(struct reset_controller_dev *resetdev)
+{
+	return container_of(resetdev, struct r9a06g032_priv, rcdev);
+}
+
+static int r9a06g032_reset_set(struct reset_controller_dev *rcdev,
+				bool set, unsigned long id)
+{
+	struct r9a06g032_priv *priv = priv_from_rcdev(rcdev);
+	unsigned long flags;
+
+	spin_lock_irqsave(&priv->lock, flags);
+	clk_rdesc_set(priv, r9a06g032_resets[id], set);
+	spin_unlock_irqrestore(&priv->lock, flags);
+
+	return 0;
+}
+
+static int r9a06g032_reset_assert(struct reset_controller_dev *rcdev,
+					unsigned long id)
+{
+	return r9a06g032_reset_set(rcdev, false, id);
+}
+
+static int r9a06g032_reset_deassert(struct reset_controller_dev *rcdev,
+					unsigned long id)
+{
+	return r9a06g032_reset_set(rcdev, true, id);
+}
+
+static int r9a06g032_reset_status(struct reset_controller_dev *rcdev,
+					unsigned long id)
+{
+	struct r9a06g032_priv *priv = priv_from_rcdev(rcdev);
+
+	return !clk_rdesc_get(priv, r9a06g032_resets[id]);
+}
+
+static const struct reset_control_ops r9a06g032_reset_ops = {
+	.assert = r9a06g032_reset_assert,
+	.deassert = r9a06g032_reset_deassert,
+	.status = r9a06g032_reset_status,
+};
+
 static int __init r9a06g032_clocks_probe(struct platform_device *pdev)
 {
 	struct device *dev = &pdev->dev;
@@ -1394,6 +1446,13 @@ static int __init r9a06g032_clocks_probe(struct platform_device *pdev)
 	if (error)
 		return error;
 
+	clocks->rcdev.ops = &r9a06g032_reset_ops;
+	clocks->rcdev.of_node = np;
+	clocks->rcdev.nr_resets = ARRAY_SIZE(r9a06g032_resets);
+	error =  devm_reset_controller_register(dev, &clocks->rcdev);
+	if (error)
+		return error;
+
 	error = r9a06g032_add_clk_domain(dev);
 	if (error)
 		return error;

-- 
2.53.0

