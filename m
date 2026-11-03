From: Vincent Jardin <vjardin@free.fr>
Date: Tue, 03 Nov 2026 10:51:57 +0100
Subject: [PATCH 4/5] pinctrl: freescale: add the LX2160A RCW pad-mux driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261103-for-upstream-lx2160a-rcw-pinmux-v1-v1-4-0a61a9837744@free.fr>
References: <20261103-for-upstream-lx2160a-rcw-pinmux-v1-v1-0-0a61a9837744@free.fr>
In-Reply-To: <20261103-for-upstream-lx2160a-rcw-pinmux-v1-v1-0-0a61a9837744@free.fr>
To: Dong Aisheng <aisheng.dong@nxp.com>, Fabio Estevam <festevam@gmail.com>, 
 Frank Li <Frank.Li@nxp.com>, Jacky Bai <ping.bai@nxp.com>, 
 Pengutronix Kernel Team <kernel@pengutronix.de>, 
 NXP S32 Linux Team <s32@nxp.com>, Linus Walleij <linusw@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 "Christophe Leroy (CS GROUP)" <chleroy@kernel.org>, 
 Shawn Guo <shawnguo@kernel.org>, Sascha Hauer <s.hauer@pengutronix.de>
Cc: linux-gpio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linuxppc-dev@lists.ozlabs.org, 
 linux-arm-kernel@lists.infradead.org, imx@lists.linux.dev, 
 Vladimir Oltean <vladimir.oltean@nxp.com>, Vincent Jardin <vjardin@free.fr>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793699524; l=14211;
 i=vjardin@free.fr; s=20260525; h=from:subject:message-id;
 bh=mgJWUp01N8MKAH+Eg4XUymjim1QvmmPHCrTSnou8fE8=;
 b=1+VBhkwfliJ2Pu2V+8B3v+SsdmmVcv6xdtp9tcOV4xaJ5pVPLvm7Kq0/dfCQBeCmqQUdBrL1T
 7Z7bLMkJwf6Djn34ipjza8pHVVem+f/P3SVLoWnRuRDmfWq4D6x+Xa3
X-Developer-Key: i=vjardin@free.fr; a=ed25519;
 pk=hppgLeFpGpKOi7LNwGEZ4jOYofJCoGd4Jf1ltAabiLw=
X-Endpoint-Received: by B4 Relay for vjardin@free.fr/20260525 with auth_id=871
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The LX2160A muxes its IIC, XSPI, SDHC, UART, IRQ and EVT pads from
fields of the RCW, read-only in RCWSR12..14 of DCFG and changed at
runtime through the same fields of the override registers in its DCSR
view, which read 0 until written.

Since commit 8a1365c7bbc1 ("arm64: dts: lx2160a: add pinmux and i2c
gpio to support bus recovery") Linux drives them with pinctrl-single on
the override registers, so its first pin state clears every other field
of the word: a board whose RCW programs a non-zero pad mux loses those
pads at the first I2C probe.

Add a driver for the pad mux as a child of the DCFG node: the fields
of RCWSR12..14 and their encoding.
Then pin states select them with the generic function and groups
properties, and every change goes through the RCW override
of fsl-guts, which reads the status register, writes the override and
waits for the status register to follow.

Signed-off-by: Vincent Jardin <vjardin@free.fr>
---
 MAINTAINERS                                 |   7 +
 drivers/pinctrl/freescale/Kconfig           |  15 ++
 drivers/pinctrl/freescale/Makefile          |   1 +
 drivers/pinctrl/freescale/pinctrl-lx2160a.c | 355 ++++++++++++++++++++++++++++
 4 files changed, 378 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index 93abbb315065..6c488605f5da 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -20207,6 +20207,13 @@ F:	Documentation/devicetree/bindings/clock/*imx*
 F:	drivers/clk/imx/
 F:	include/dt-bindings/clock/*imx*
 
+NXP LX2160A RCW PAD-MUX DRIVER
+M:	Vincent Jardin <vjardin@free.fr>
+L:	linux-gpio@vger.kernel.org
+S:	Maintained
+F:	Documentation/devicetree/bindings/pinctrl/fsl,lx2160a-rcw-pinmux.yaml
+F:	drivers/pinctrl/freescale/pinctrl-lx2160a.c
+
 NXP NETC ETHERNET SWITCH DRIVER
 M:	Wei Fang <wei.fang@nxp.com>
 R:	Clark Wang <xiaoning.wang@nxp.com>
diff --git a/drivers/pinctrl/freescale/Kconfig b/drivers/pinctrl/freescale/Kconfig
index fd53cf5bb843..a3222714c970 100644
--- a/drivers/pinctrl/freescale/Kconfig
+++ b/drivers/pinctrl/freescale/Kconfig
@@ -283,3 +283,18 @@ config PINCTRL_IMXRT1170
 	select PINCTRL_IMX
 	help
 	  Say Y here to enable the imxrt1170 pinctrl driver
+
+config PINCTRL_LX2160A
+	bool "NXP LX2160A RCW pad-mux driver"
+	depends on OF
+	depends on ARCH_LAYERSCAPE || COMPILE_TEST
+	default ARCH_LAYERSCAPE
+	select FSL_GUTS
+	select GENERIC_PINCTRL_GROUPS
+	select GENERIC_PINMUX_FUNCTIONS
+	select GENERIC_PINCONF
+	help
+	  Say Y here to mux the IIC, XSPI, SDHC, UART, IRQ and EVT pads of the
+	  LX2160A at runtime. The pads are muxed by fields of the RCW:
+	  the driver changes it in the DCSR view of the DCFG that fsl-guts
+	  drives, and is what the I2C bus recovery of the LX2160A needs.
diff --git a/drivers/pinctrl/freescale/Makefile b/drivers/pinctrl/freescale/Makefile
index d27085c2b4c4..5ec0d1710ad5 100644
--- a/drivers/pinctrl/freescale/Makefile
+++ b/drivers/pinctrl/freescale/Makefile
@@ -35,3 +35,4 @@ obj-$(CONFIG_PINCTRL_IMX25)	+= pinctrl-imx25.o
 obj-$(CONFIG_PINCTRL_IMX28)	+= pinctrl-imx28.o
 obj-$(CONFIG_PINCTRL_IMXRT1050)	+= pinctrl-imxrt1050.o
 obj-$(CONFIG_PINCTRL_IMXRT1170)	+= pinctrl-imxrt1170.o
+obj-$(CONFIG_PINCTRL_LX2160A)	+= pinctrl-lx2160a.o
diff --git a/drivers/pinctrl/freescale/pinctrl-lx2160a.c b/drivers/pinctrl/freescale/pinctrl-lx2160a.c
new file mode 100644
index 000000000000..ba5bbcfab9fd
--- /dev/null
+++ b/drivers/pinctrl/freescale/pinctrl-lx2160a.c
@@ -0,0 +1,355 @@
+// SPDX-License-Identifier: GPL-2.0
+/*
+ * LX2160A pad muxes: fields of the RCW, changed at
+ * runtime.
+ *
+ * Copyright 2026 Free Mobile - Vincent Jardin
+ */
+
+#include <linux/bits.h>
+#include <linux/fsl/guts.h>
+#include <linux/module.h>
+#include <linux/of.h>
+#include <linux/pinctrl/pinconf-generic.h>
+#include <linux/pinctrl/pinctrl.h>
+#include <linux/pinctrl/pinmux.h>
+#include <linux/platform_device.h>
+#include <linux/seq_file.h>
+
+#include "../core.h"
+#include "../pinmux.h"
+
+struct lx2160a_pmux_func {
+	const char *name;
+	u8 val;
+};
+
+struct lx2160a_pmux_group {
+	const char *name;
+	u8 rcwsr; /* 12..14 */
+	u8 shift;
+	u8 width;
+	const struct lx2160a_pmux_func *funcs;
+	u8 nfuncs;
+};
+
+#define FUNC(_name, _val)	{ .name = _name, .val = _val }
+#define GROUP(_name, _rcwsr, _shift, _width, _funcs)			\
+	{								\
+		.name = _name, .rcwsr = _rcwsr,				\
+		.shift = _shift, .width = _width,			\
+		.funcs = _funcs, .nfuncs = ARRAY_SIZE(_funcs),		\
+	}
+
+static const struct lx2160a_pmux_func iic2_funcs[] = {
+	FUNC("i2c", 0), FUNC("gpio", 1), FUNC("flextimer", 2), FUNC("sdhc", 6),
+};
+
+static const struct lx2160a_pmux_func iic3_funcs[] = {
+	FUNC("i2c", 0), FUNC("gpio", 1), FUNC("can", 2), FUNC("evt", 6),
+};
+
+static const struct lx2160a_pmux_func iic5_funcs[] = {
+	FUNC("i2c", 0), FUNC("gpio", 1), FUNC("sdhc-clk", 2), FUNC("spi", 3),
+};
+
+static const struct lx2160a_pmux_func iic6_funcs[] = {
+	FUNC("i2c", 0), FUNC("gpio", 1), FUNC("sdhc-clk", 2),
+};
+
+static const struct lx2160a_pmux_func xspi1_funcs[] = {
+	FUNC("flexspi", 0), FUNC("gpio", 1),
+};
+
+static const struct lx2160a_pmux_func sdhc1_base_funcs[] = {
+	FUNC("sdhc", 0), FUNC("gpio", 1), FUNC("spi", 2), FUNC("sdhc-spi", 3),
+	FUNC("sdhc-data4", 4),
+};
+
+static const struct lx2160a_pmux_func sdhc1_dir_funcs[] = {
+	FUNC("sdhc", 0), FUNC("gpio", 1), FUNC("spi", 3), FUNC("sdhc-data", 4),
+};
+
+static const struct lx2160a_pmux_func sdhc2_data74_funcs[] = {
+	FUNC("sdhc", 0), FUNC("gpio", 1), FUNC("i2c", 2), FUNC("flexspi", 6),
+};
+
+static const struct lx2160a_pmux_func sdhc2_base_funcs[] = {
+	FUNC("sdhc", 0), FUNC("gpio", 1), FUNC("spi", 2), FUNC("flexspi", 6),
+};
+
+static const struct lx2160a_pmux_func uart_funcs[] = {
+	FUNC("uart", 0), FUNC("gpio", 1),
+};
+
+static const struct lx2160a_pmux_func uart1_rtscts_funcs[] = {
+	FUNC("uart", 0), FUNC("gpio", 1), FUNC("uart3", 2),
+};
+
+static const struct lx2160a_pmux_func uart2_rtscts_funcs[] = {
+	FUNC("uart", 0), FUNC("gpio", 1), FUNC("uart4", 2),
+};
+
+static const struct lx2160a_pmux_func irq_funcs[] = {
+	FUNC("irq", 0), FUNC("gpio", 1),
+};
+
+static const struct lx2160a_pmux_func irq_flextimer_funcs[] = {
+	FUNC("irq", 0), FUNC("gpio", 1), FUNC("flextimer", 2),
+};
+
+static const struct lx2160a_pmux_func evt_funcs[] = {
+	FUNC("evt", 0), FUNC("gpio", 1), FUNC("flextimer", 2),
+};
+
+static const struct lx2160a_pmux_func clk_out_funcs[] = {
+	FUNC("gpio", 1), FUNC("flextimer", 2),
+};
+
+static const struct lx2160a_pmux_func asleep_funcs[] = {
+	FUNC("asleep", 0), FUNC("gpio", 1), FUNC("evt", 2),
+};
+
+static const struct lx2160a_pmux_func reset_req_funcs[] = {
+	FUNC("reset-req", 0), FUNC("gpio", 1),
+};
+
+static const struct lx2160a_pmux_func iic1_funcs[] = {
+	FUNC("i2c", 0), FUNC("gpio", 1),
+};
+
+static const struct lx2160a_pmux_group lx2160a_pmux_groups[] = {
+	/* RCWSR12 */
+	GROUP("iic2", 12, 0, 3, iic2_funcs),
+	GROUP("iic3", 12, 3, 3, iic3_funcs),
+	GROUP("iic4", 12, 6, 3, iic3_funcs),
+	GROUP("iic5", 12, 9, 3, iic5_funcs),
+	GROUP("iic6", 12, 12, 3, iic6_funcs),
+	GROUP("xspi1-data74", 12, 15, 3, xspi1_funcs),
+	GROUP("xspi1-data30", 12, 18, 3, xspi1_funcs),
+	GROUP("xspi1-base", 12, 21, 3, xspi1_funcs),
+	GROUP("sdhc1-base", 12, 24, 3, sdhc1_base_funcs),
+	GROUP("sdhc1-dir", 12, 27, 3, sdhc1_dir_funcs),
+	/* RCWSR13 */
+	GROUP("sdhc2-data74", 13, 0, 3, sdhc2_data74_funcs),
+	GROUP("sdhc2-base", 13, 3, 3, sdhc2_base_funcs),
+	GROUP("uart1-soutsin", 13, 6, 3, uart_funcs),
+	GROUP("uart1-rtscts", 13, 9, 3, uart1_rtscts_funcs),
+	GROUP("uart2-soutsin", 13, 12, 3, uart_funcs),
+	GROUP("uart2-rtscts", 13, 15, 3, uart2_rtscts_funcs),
+	GROUP("irq11-8", 13, 18, 3, irq_funcs),
+	GROUP("irq7-4", 13, 21, 3, irq_flextimer_funcs),
+	GROUP("irq3-0", 13, 24, 3, irq_flextimer_funcs),
+	GROUP("evt4-3", 13, 27, 3, evt_funcs),
+	/* RCWSR14 */
+	GROUP("evt2-0", 14, 0, 3, evt_funcs),
+	GROUP("clk-out", 14, 3, 3, clk_out_funcs),
+	GROUP("asleep", 14, 6, 3, asleep_funcs),
+	GROUP("reset-req", 14, 9, 1, reset_req_funcs),
+	GROUP("iic1", 14, 10, 1, iic1_funcs),
+};
+
+struct lx2160a_pmux {
+	struct device *dev;
+	struct pinctrl_dev *pctl;
+	struct pinctrl_desc desc;
+	struct pinctrl_pin_desc pins[ARRAY_SIZE(lx2160a_pmux_groups)];
+};
+
+static u32 lx2160a_pmux_group_mask(const struct lx2160a_pmux_group *group)
+{
+	return GENMASK(group->shift + group->width - 1, group->shift);
+}
+
+static void lx2160a_pmux_pin_dbg_show(struct pinctrl_dev *pctldev,
+				      struct seq_file *s, unsigned int pin)
+{
+	const struct lx2160a_pmux_group *group = &lx2160a_pmux_groups[pin];
+	unsigned int i;
+	u32 val;
+
+	if (fsl_guts_rcw_read(group->rcwsr, &val))
+		return;
+
+	val = (val & lx2160a_pmux_group_mask(group)) >> group->shift;
+	for (i = 0; i < group->nfuncs; i++) {
+		if (group->funcs[i].val == val) {
+			seq_puts(s, group->funcs[i].name);
+			return;
+		}
+	}
+	seq_printf(s, "0x%x", val);
+}
+
+static const struct pinctrl_ops lx2160a_pmux_pctlops = {
+	.get_groups_count = pinctrl_generic_get_group_count,
+	.get_group_name = pinctrl_generic_get_group_name,
+	.get_group_pins = pinctrl_generic_get_group_pins,
+	.pin_dbg_show = lx2160a_pmux_pin_dbg_show,
+	.dt_node_to_map = pinconf_generic_dt_node_to_map_group,
+	.dt_free_map = pinconf_generic_dt_free_map,
+};
+
+static int lx2160a_pmux_set_mux(struct pinctrl_dev *pctldev,
+				unsigned int fsel, unsigned int gsel)
+{
+	struct lx2160a_pmux *pmux = pinctrl_dev_get_drvdata(pctldev);
+	const struct function_desc *func;
+	const struct lx2160a_pmux_group *group;
+	const struct group_desc *grp;
+	unsigned int i;
+
+	func = pinmux_generic_get_function(pctldev, fsel);
+	grp = pinctrl_generic_get_group(pctldev, gsel);
+	if (!func || !grp)
+		return -EINVAL;
+	group = grp->data;
+
+	for (i = 0; i < group->nfuncs; i++) {
+		if (!strcmp(group->funcs[i].name, func->func->name))
+			break;
+	}
+	if (i == group->nfuncs) {
+		dev_err(pmux->dev, "%s has no %s function\n",
+			group->name, func->func->name);
+		return -EINVAL;
+	}
+
+	return fsl_guts_rcw_override(group->rcwsr,
+				     group->funcs[i].val << group->shift,
+				     lx2160a_pmux_group_mask(group));
+}
+
+static const struct pinmux_ops lx2160a_pmux_pmxops = {
+	.get_functions_count = pinmux_generic_get_function_count,
+	.get_function_name = pinmux_generic_get_function_name,
+	.get_function_groups = pinmux_generic_get_function_groups,
+	.set_mux = lx2160a_pmux_set_mux,
+	.strict = true,
+};
+
+static int lx2160a_pmux_add_functions(struct lx2160a_pmux *pmux)
+{
+	const struct lx2160a_pmux_group *group;
+	const char **groups;
+	unsigned int i, j, k, n;
+	int ret;
+
+	for (i = 0; i < ARRAY_SIZE(lx2160a_pmux_groups); i++) {
+		group = &lx2160a_pmux_groups[i];
+		for (j = 0; j < group->nfuncs; j++) {
+			const char *name = group->funcs[j].name;
+			bool seen = false;
+
+			/* already added from an earlier group? */
+			for (k = 0; k < i && !seen; k++) {
+				const struct lx2160a_pmux_group *g =
+					&lx2160a_pmux_groups[k];
+				unsigned int l;
+
+				for (l = 0; l < g->nfuncs; l++)
+					if (!strcmp(g->funcs[l].name, name))
+						seen = true;
+			}
+			if (seen)
+				continue;
+
+			groups = devm_kcalloc(pmux->dev,
+					      ARRAY_SIZE(lx2160a_pmux_groups),
+					      sizeof(*groups), GFP_KERNEL);
+			if (!groups)
+				return -ENOMEM;
+			n = 0;
+			for (k = i; k < ARRAY_SIZE(lx2160a_pmux_groups); k++) {
+				const struct lx2160a_pmux_group *g =
+					&lx2160a_pmux_groups[k];
+				unsigned int l;
+
+				for (l = 0; l < g->nfuncs; l++)
+					if (!strcmp(g->funcs[l].name, name))
+						groups[n++] = g->name;
+			}
+			ret = pinmux_generic_add_function(pmux->pctl, name,
+							  groups, n, NULL);
+			if (ret < 0)
+				return ret;
+		}
+	}
+
+	return 0;
+}
+
+static int lx2160a_pmux_probe(struct platform_device *pdev)
+{
+	struct device *dev = &pdev->dev;
+	struct lx2160a_pmux *pmux;
+	unsigned int i;
+	u32 val;
+	int ret;
+
+	/* The override needs the DCSR view of DCFG, mapped by fsl-guts */
+	if (!fsl_guts_rcw_override_supported())
+		return dev_err_probe(dev, -ENODEV,
+				     "no RCW override through fsl-guts: the dcfg node needs its DCSR reg\n");
+
+	pmux = devm_kzalloc(dev, sizeof(*pmux), GFP_KERNEL);
+	if (!pmux)
+		return -ENOMEM;
+	pmux->dev = dev;
+
+	for (i = 0; i < ARRAY_SIZE(lx2160a_pmux_groups); i++) {
+		pmux->pins[i].number = i;
+		pmux->pins[i].name = lx2160a_pmux_groups[i].name;
+	}
+	pmux->desc.name = dev_name(dev);
+	pmux->desc.pins = pmux->pins;
+	pmux->desc.npins = ARRAY_SIZE(pmux->pins);
+	pmux->desc.pctlops = &lx2160a_pmux_pctlops;
+	pmux->desc.pmxops = &lx2160a_pmux_pmxops;
+	pmux->desc.owner = THIS_MODULE;
+
+	ret = devm_pinctrl_register_and_init(dev, &pmux->desc, pmux,
+					     &pmux->pctl);
+	if (ret)
+		return dev_err_probe(dev, ret, "pinctrl registration failed\n");
+
+	for (i = 0; i < ARRAY_SIZE(lx2160a_pmux_groups); i++) {
+		ret = pinctrl_generic_add_group(pmux->pctl,
+						lx2160a_pmux_groups[i].name,
+						&pmux->pins[i].number, 1,
+						(void *)&lx2160a_pmux_groups[i]);
+		if (ret < 0)
+			return ret;
+	}
+
+	ret = lx2160a_pmux_add_functions(pmux);
+	if (ret)
+		return ret;
+
+	for (i = 12; i <= 14; i++) {
+		fsl_guts_rcw_read(i, &val);
+		dev_dbg(dev, "RCWSR%u = 0x%08x\n", i, val);
+	}
+
+	return pinctrl_enable(pmux->pctl);
+}
+
+static const struct of_device_id lx2160a_pmux_of_match[] = {
+	{ .compatible = "fsl,lx2160a-rcw-pinmux" },
+	{ }
+};
+MODULE_DEVICE_TABLE(of, lx2160a_pmux_of_match);
+
+static struct platform_driver lx2160a_pmux_driver = {
+	.driver = {
+		.name = "lx2160a-rcw-pinmux",
+		.of_match_table = lx2160a_pmux_of_match,
+	},
+	.probe = lx2160a_pmux_probe,
+};
+module_platform_driver(lx2160a_pmux_driver);
+
+MODULE_AUTHOR("Vincent Jardin <vjardin@free.fr>");
+MODULE_DESCRIPTION("NXP LX2160A RCW pad-mux driver");
+MODULE_LICENSE("GPL");
+MODULE_IMPORT_NS("FSL_GUTS");

-- 
2.43.0

