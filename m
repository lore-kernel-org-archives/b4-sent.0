From: Junyi Zhao <junyi.zhao@amlogic.com>
Date: Mon, 19 Oct 2026 13:34:28 +0800
Subject: [PATCH 3/3] i3c: master: svc: Add Amlogic A9 glue layer
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261019-a9_i3c-v1-3-329d819d621f@amlogic.com>
References: <20261019-a9_i3c-v1-0-329d819d621f@amlogic.com>
In-Reply-To: <20261019-a9_i3c-v1-0-329d819d621f@amlogic.com>
To: Alexandre Belloni <alexandre.belloni@bootlin.com>, 
 Frank Li <Frank.Li@nxp.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Miquel Raynal <miquel.raynal@bootlin.com>, Kees Cook <kees@kernel.org>, 
 "Gustavo A. R. Silva" <gustavoars@kernel.org>
Cc: linux-i3c@lists.infradead.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, imx@lists.linux.dev, 
 linux-hardening@vger.kernel.org, xianwei.zhao@amlogic.com, 
 Kelvin.Zhang@amlogic.com, Junyi Zhao <junyi.zhao@amlogic.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792388075; l=9305;
 i=junyi.zhao@amlogic.com; s=20260924; h=from:subject:message-id;
 bh=18O6s8M2HxsH0py6HaePc4GkPMaOz4lmZIsMAJSYEsw=;
 b=WboHZG3aLyG1z/LNaPDc6zu67E5+bGy4TeSJgqA55H0gQZhNpG6ok3eT+LJVd05OCf75KTFmx
 w9e970NFGCjARok2uGYxPFb4vgSgFwvY1BSda7eT2rFazD+YZiSHPv0
X-Developer-Key: i=junyi.zhao@amlogic.com; a=ed25519;
 pk=hiL5PjGIksGFiWvEx9J3MhQqU/ro6vNbj72NIw4bbvA=
X-Endpoint-Received: by B4 Relay for junyi.zhao@amlogic.com/20260924 with auth_id=1054
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support for the Amlogic A9 implementation of the Silvaco
SVC I3C controller.

The glue layer provides Amlogic-specific operations and resource
handling while reusing the common SVC I3C core driver.

Add a corresponding MAINTAINERS entry for the Amlogic I3C
controller.

Signed-off-by: Junyi Zhao <junyi.zhao@amlogic.com>
---
 MAINTAINERS                          |   6 +
 drivers/i3c/master/svc/Kconfig       |   7 +
 drivers/i3c/master/svc/Makefile      |   1 +
 drivers/i3c/master/svc/i3c-amlogic.c | 250 +++++++++++++++++++++++++++++++++++
 4 files changed, 264 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index dffc63af2..478979446 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -1398,6 +1398,12 @@ F:	Documentation/userspace-api/media/v4l/metafmt-c3-isp.rst
 F:	drivers/media/platform/amlogic/c3/isp/
 F:	include/uapi/linux/media/amlogic/
 
+AMLOGIC I3C DRIVER
+M:	Junyi Zhao <junyi.zhao@amlogic.com>
+S:	Maintained
+F:	Documentation/devicetree/bindings/i3c/amlogic,i3c-a9.yaml
+F:	drivers/i3c/master/svc/i3c-amlogic.c
+
 AMLOGIC MIPI ADAPTER DRIVER
 M:	Keke Li <keke.li@amlogic.com>
 L:	linux-media@vger.kernel.org
diff --git a/drivers/i3c/master/svc/Kconfig b/drivers/i3c/master/svc/Kconfig
index 14fa1e542..df3528bc1 100644
--- a/drivers/i3c/master/svc/Kconfig
+++ b/drivers/i3c/master/svc/Kconfig
@@ -18,4 +18,11 @@ config I3C_SILVACO
 	  compatible strings such as "silvaco,i3c-master-v1" and
 	  "nuvoton,npcm845-i3c".
 
+config I3C_AMLOGIC
+	tristate "Amlogic I3C support"
+	default y
+	help
+	  This selects the Amlogic SoC glue layer support for
+	  the Silvaco device driver. This driver is used for A9, C5 SoCs.
+
 endif # SVC_I3C
diff --git a/drivers/i3c/master/svc/Makefile b/drivers/i3c/master/svc/Makefile
index cf18c5da6..695863d1f 100644
--- a/drivers/i3c/master/svc/Makefile
+++ b/drivers/i3c/master/svc/Makefile
@@ -3,3 +3,4 @@
 
 obj-$(CONFIG_SVC_I3C)	+= i3c-main.o
 obj-$(CONFIG_I3C_SILVACO)	+= i3c-silvaco.o
+obj-$(CONFIG_I3C_AMLOGIC)	+= i3c-amlogic.o
diff --git a/drivers/i3c/master/svc/i3c-amlogic.c b/drivers/i3c/master/svc/i3c-amlogic.c
new file mode 100644
index 000000000..82300d6ae
--- /dev/null
+++ b/drivers/i3c/master/svc/i3c-amlogic.c
@@ -0,0 +1,250 @@
+// SPDX-License-Identifier: (GPL-2.0-only OR MIT)
+/*
+ * Copyright (C) 2026 Amlogic, Inc. All rights reserved
+ */
+#include "i3c-main.h"
+#include <linux/math64.h>
+
+/* Amlogic specific registers */
+#define I3C_BG_RD_ADDR			0x200
+#define I3C_BG_WR_ADDR			0x204
+#define I3C_BG_WR_CTRL			0x208
+#define I3C_BG_R_TT_LEN			0x20c
+#define I3C_BG_X_CNT			0x210
+#define I3C_BUS_MON_CTRL		0x214
+#define I3C_BUS_MON_ADDR		0x218
+#define I3C_BUS_MON_DATA		0x21c
+#define I3C_BUS_MON_DATA_MAK		0x220
+#define I3C_CLK_SLOW_DIV_CTRL		0x224
+#define I3C_BG_R_WCNT_CLR		0x228
+#define I3C_DEBUG_MODIFY		0x22c
+
+#define I3C_AO_CLK_SLOW_DIV_CTRL	0x300
+#define I3C_AO_FCLK_DIV_CTRL		0x304
+#define I3C_AO_FCLK_DIV_MASK		GENMASK(7, 0)
+#define I3C_AO_FCLK_DIV_EN		BIT(8)
+#define I3C_AO_FCLK_EN			BIT(9)
+#define I3C_AO_DEBUG_MODIFY		0x308
+
+#define I3C_DEFAULT_FCLK_RATE		25000000UL
+
+struct amlogic_i3c_priv {
+	int num_clks;
+	struct clk_bulk_data *clks;
+};
+
+struct amlogic_i3c_drvdata {
+	int (*fclk_rate_init)(struct svc_i3c_master *master,
+			      struct clk *fclk, unsigned long rate);
+};
+
+static int default_i3c_fclk_rate_init(struct svc_i3c_master *master,
+				      struct clk *fclk, unsigned long rate)
+{
+	int err;
+
+	err = clk_set_rate(fclk, rate);
+	if (err)
+		return dev_err_probe(master->dev, err,
+				     "setting fast clock rate failed\n");
+
+	return 0;
+}
+
+static int ao_i3c_fclk_rate_init(struct svc_i3c_master *master,
+				 struct clk *fclk, unsigned long rate)
+{
+	unsigned int div_cnt, reg_val;
+	unsigned long fin_freq = clk_get_rate(fclk);
+
+	if (!fin_freq)
+		return dev_err_probe(master->dev, -EINVAL,
+				     "can't get I3C fast clock rate\n");
+
+	div_cnt = div64_u64(fin_freq, rate);
+	if (!div_cnt || div_cnt > I3C_AO_FCLK_DIV_MASK)
+		return dev_err_probe(master->dev, -EINVAL,
+				     "requested fast clock frequency too low\n");
+
+	reg_val = I3C_AO_FCLK_DIV_EN | I3C_AO_FCLK_EN | (div_cnt - 1);
+	writel(reg_val, master->regs + I3C_AO_FCLK_DIV_CTRL);
+
+	return 0;
+}
+
+static int amlogic_i3c_probe(struct platform_device *pdev)
+{
+	struct device *dev = &pdev->dev;
+	const struct amlogic_i3c_drvdata *data;
+	struct svc_i3c_master *master;
+	struct amlogic_i3c_priv *priv;
+	struct clk *fclk;
+	int ret, i;
+
+	master = svc_i3c_master_alloc(dev);
+	if (!master)
+		return -ENOMEM;
+
+	priv = devm_kzalloc(dev, sizeof(*priv), GFP_KERNEL);
+	if (!priv)
+		return -ENOMEM;
+
+	master->drvdata = of_device_get_match_data(dev);
+	if (!master->drvdata)
+		return -EINVAL;
+
+	data = master->drvdata->bsp_data;
+	if (!data)
+		return -EINVAL;
+
+	master->regs = devm_platform_ioremap_resource(pdev, 0);
+	if (IS_ERR(master->regs))
+		return PTR_ERR(master->regs);
+
+	master->irq = platform_get_irq(pdev, 0);
+	if (master->irq < 0)
+		return master->irq;
+
+	priv->num_clks = devm_clk_bulk_get_all(dev, &priv->clks);
+	if (priv->num_clks < 0)
+		return dev_err_probe(dev, -EINVAL, "can't get I3C clocks\n");
+
+	for (i = 0; i < priv->num_clks; i++) {
+		if (!strcmp(priv->clks[i].id, "fast_clk"))
+			break;
+	}
+
+	if (i == priv->num_clks)
+		return dev_err_probe(dev, -EINVAL,
+				     "can't get I3C peripheral clock\n");
+
+	if (IS_ERR(priv->clks[i].clk))
+		return PTR_ERR(priv->clks[i].clk);
+	fclk = priv->clks[i].clk;
+
+	ret = clk_bulk_prepare_enable(priv->num_clks, priv->clks);
+	if (ret)
+		return dev_err_probe(dev, ret, "can't enable I3C clocks\n");
+
+	master->dev = dev;
+	master->bsp_priv = priv;
+	ret = data->fclk_rate_init(master, fclk, I3C_DEFAULT_FCLK_RATE);
+	if (ret)
+		goto err_disable_clks;
+	master->fclk_rate = I3C_DEFAULT_FCLK_RATE;
+
+	pm_runtime_set_autosuspend_delay(dev, SVC_I3C_PM_TIMEOUT_MS);
+	pm_runtime_use_autosuspend(dev);
+	pm_runtime_get_noresume(dev);
+	pm_runtime_set_active(dev);
+	pm_runtime_enable(dev);
+
+	ret = svc_i3c_master_probe(pdev, master);
+	if (ret)
+		goto rpm_disable;
+
+	platform_set_drvdata(pdev, master);
+	pm_runtime_put_autosuspend(dev);
+
+	return 0;
+
+rpm_disable:
+	pm_runtime_dont_use_autosuspend(dev);
+	pm_runtime_put_noidle(dev);
+	pm_runtime_disable(dev);
+	pm_runtime_set_suspended(dev);
+
+err_disable_clks:
+	clk_bulk_disable_unprepare(priv->num_clks, priv->clks);
+
+	return ret;
+}
+
+static void amlogic_i3c_remove(struct platform_device *pdev)
+{
+	struct svc_i3c_master *master = platform_get_drvdata(pdev);
+
+	svc_i3c_master_remove(master);
+
+	pm_runtime_dont_use_autosuspend(&pdev->dev);
+	pm_runtime_disable(&pdev->dev);
+}
+
+static int __maybe_unused amlogic_i3c_runtime_suspend(struct device *dev)
+{
+	struct svc_i3c_master *master = dev_get_drvdata(dev);
+	struct amlogic_i3c_priv *priv = master->bsp_priv;
+
+	svc_i3c_save_regs(master);
+	clk_bulk_disable_unprepare(priv->num_clks, priv->clks);
+	pinctrl_pm_select_sleep_state(dev);
+
+	return 0;
+}
+
+static int __maybe_unused amlogic_i3c_runtime_resume(struct device *dev)
+{
+	struct svc_i3c_master *master = dev_get_drvdata(dev);
+	struct amlogic_i3c_priv *priv = master->bsp_priv;
+	int ret;
+
+	pinctrl_pm_select_default_state(dev);
+	ret = clk_bulk_prepare_enable(priv->num_clks, priv->clks);
+	if (ret)
+		return ret;
+
+	svc_i3c_restore_regs(master);
+
+	return 0;
+}
+
+static const struct dev_pm_ops amlogic_i3c_pm_ops = {
+	SET_NOIRQ_SYSTEM_SLEEP_PM_OPS(pm_runtime_force_suspend,
+				      pm_runtime_force_resume)
+	SET_RUNTIME_PM_OPS(amlogic_i3c_runtime_suspend,
+			   amlogic_i3c_runtime_resume, NULL)
+};
+
+static const struct amlogic_i3c_drvdata amlogic_i3c_data = {
+	.fclk_rate_init = default_i3c_fclk_rate_init,
+};
+
+static const struct amlogic_i3c_drvdata amlogic_i3c_ao_data = {
+	.fclk_rate_init = ao_i3c_fclk_rate_init,
+};
+
+static const struct svc_i3c_drvdata amlogic_a9_drvdata = {
+	.quirks = SVC_I3C_QUIRK_FIFO_EMPTY |
+		SVC_I3C_QUIRK_FALSE_SLVSTART |
+		SVC_I3C_QUIRK_DAA_CORRUPT,
+	.bsp_data = &amlogic_i3c_data,
+};
+
+static const struct svc_i3c_drvdata amlogic_a9_ao_drvdata = {
+	.quirks = SVC_I3C_QUIRK_FIFO_EMPTY |
+		SVC_I3C_QUIRK_FALSE_SLVSTART |
+		SVC_I3C_QUIRK_DAA_CORRUPT,
+	.bsp_data = &amlogic_i3c_ao_data,
+};
+
+static const struct of_device_id amlogic_i3c_of_match_tbl[] = {
+	{ .compatible = "amlogic,i3c-a9", .data = &amlogic_a9_drvdata },
+	{ .compatible = "amlogic,i3c-ao-a9", .data = &amlogic_a9_ao_drvdata },
+	{ /* sentinel */ },
+};
+MODULE_DEVICE_TABLE(of, amlogic_i3c_of_match_tbl);
+
+static struct platform_driver amlogic_i3c_master = {
+	.probe = amlogic_i3c_probe,
+	.remove = amlogic_i3c_remove,
+	.driver = {
+		.name = "amlogic-i3c-master",
+		.of_match_table = amlogic_i3c_of_match_tbl,
+		.pm = &amlogic_i3c_pm_ops,
+	},
+};
+module_platform_driver(amlogic_i3c_master);
+
+MODULE_AUTHOR("Junyi Zhao <junyi.zhao@amlogic.com>");
+MODULE_DESCRIPTION("Amlogic I3C master driver");
+MODULE_LICENSE("GPL");

-- 
2.42.0

