From: Jaidev Shastri <jaidevshastri@vt.edu>
Date: Mon, 21 Sep 2026 20:48:49 -0400
Subject: [PATCH] soc: sunxi: sram: order the publication of base against
 sram_dev
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260921-mb-sunxi-sram-v1-1-ad7817f0ee7d@vt.edu>
X-B4-Tracking: v=1; b=H4sIAHDQsWoC/yXMwQ6CMBAE0F8he3ZNKU1Ff8V4aOsqa0I1u0JIC
 P9ui8c3mZkVlIRJ4dKsIDSz8jsXtIcG0hDyk5DvxWCN9eZsWxwj6pQXRpUwomtTZ/s+OO8NlM1
 H6MHL/ne9/a1TfFH61pPaiEEJo4SchhrtnE/HDiU52LYfZR29qpEAAAA=
X-Change-ID: 20260921-mb-sunxi-sram-41c3288a4660
To: Chen-Yu Tsai <wens@kernel.org>, 
 Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Samuel Holland <samuel@sholland.org>
Cc: linux-arm-kernel@lists.infradead.org, linux-sunxi@lists.linux.dev, 
 linux-kernel@vger.kernel.org, Jaidev Shastri <jaidevshastri@vt.edu>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790038131; l=2938;
 i=jaidevshastri@vt.edu; s=20260921; h=from:subject:message-id;
 bh=iWOUCfUb74J3AaIrMMoha+tqbbn7gGU2kZjJNz75+qo=;
 b=xNk3bETupvhxPj+ON3wVvUrT00jS57UuN8Fn/ZStgW4M+sscHW5o3tqneSp1mYeN0l0G53/Sb
 TmEtkw7niOuDlqX1aVZUwXlG4rAhSg8GVuFGrkqvbw+7ityyJaG8aaV
X-Developer-Key: i=jaidevshastri@vt.edu; a=ed25519;
 pk=J7+xYJRlTPds+pv5hbqFFRqGCpDeJDzmZT1ggRwj7/0=
X-Endpoint-Received: by B4 Relay for jaidevshastri@vt.edu/20260921 with auth_id=1044
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

sunxi_sram_claim() is called from the probe functions of the EMAC, the
video engine and other consumers. It gates on the file-scope base
pointer:

	if (!base)
		return -EPROBE_DEFER;

and then walks sram_dev->of_node in sunxi_sram_of_parse().
sunxi_sram_probe() writes sram_dev and then base, both with plain
stores, and the claimer reads both with plain loads. Neither the two
stores nor the two loads are ordered, so a claimer on another CPU can
pass the gate and dereference sram_dev == NULL.

Keep the mapped registers in a local and publish base with
smp_store_release() once sram_dev is set; read it with
smp_load_acquire() in sunxi_sram_claim(). The error value is still
stored to base so that a failed probe keeps reporting it to claimers.

Found with MBCheck, a static herd7-based memory consistency checker.

Signed-off-by: Jaidev Shastri <jaidevshastri@vt.edu>
---
 drivers/soc/sunxi/sunxi_sram.c | 28 +++++++++++++++++++++-------
 1 file changed, 21 insertions(+), 7 deletions(-)

diff --git a/drivers/soc/sunxi/sunxi_sram.c b/drivers/soc/sunxi/sunxi_sram.c
index 2ccaeacf8..0e0b86ad3 100644
--- a/drivers/soc/sunxi/sunxi_sram.c
+++ b/drivers/soc/sunxi/sunxi_sram.c
@@ -266,10 +266,14 @@ int sunxi_sram_claim(struct device *dev)
 	int err;
 	int count = 0;
 
-	if (IS_ERR(base))
-		return PTR_ERR(base);
+	void __iomem *regs;
 
-	if (!base)
+	/* Pairs with smp_store_release() in sunxi_sram_probe(). */
+	regs = smp_load_acquire(&base);
+	if (IS_ERR(regs))
+		return PTR_ERR(regs);
+
+	if (!regs)
 		return -EPROBE_DEFER;
 
 	if (!dev || !dev->of_node)
@@ -410,6 +414,7 @@ static int __init sunxi_sram_probe(struct platform_device *pdev)
 	const struct sunxi_sramc_variant *variant;
 	struct device *dev = &pdev->dev;
 	struct regmap *regmap;
+	void __iomem *regs;
 	int ret;
 
 	sram_dev = &pdev->dev;
@@ -420,12 +425,21 @@ static int __init sunxi_sram_probe(struct platform_device *pdev)
 
 	dev_set_drvdata(dev, (struct sunxi_sramc_variant *)variant);
 
-	base = devm_platform_ioremap_resource(pdev, 0);
-	if (IS_ERR(base))
-		return PTR_ERR(base);
+	regs = devm_platform_ioremap_resource(pdev, 0);
+	if (IS_ERR(regs)) {
+		base = regs;
+		return PTR_ERR(regs);
+	}
+
+	/*
+	 * base is the gate that sunxi_sram_claim() tests before it walks
+	 * sram_dev->of_node. Publish it after sram_dev so that a claimer on
+	 * another CPU that passes the gate also sees sram_dev.
+	 */
+	smp_store_release(&base, regs);
 
 	if (variant->num_emac_clocks || variant->has_ldo_ctrl) {
-		regmap = devm_regmap_init_mmio(dev, base, &sunxi_sram_regmap_config);
+		regmap = devm_regmap_init_mmio(dev, regs, &sunxi_sram_regmap_config);
 		if (IS_ERR(regmap))
 			return PTR_ERR(regmap);
 

---
base-commit: 93f51579e7df248780214094418f205253383cc5
change-id: 20260921-mb-sunxi-sram-41c3288a4660

Best regards,
--  
Jaidev Shastri <jaidevshastri@vt.edu>

