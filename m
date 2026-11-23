From: Fil Dunsky <filipp.dunsky@gmail.com>
Date: Mon, 23 Nov 2026 21:43:31 +0300
Subject: [PATCH 3/8] clk: Add CS7542 PCIe gates and resets
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261123-b4-cs7542-pcie-v1-3-4cde5201d404@gmail.com>
References: <20261123-b4-cs7542-pcie-v1-0-4cde5201d404@gmail.com>
In-Reply-To: <20261123-b4-cs7542-pcie-v1-0-4cde5201d404@gmail.com>
To: Manivannan Sadhasivam <mani@kernel.org>, 
 Stephen Boyd <sboyd@kernel.org>, Vinod Koul <vkoul@kernel.org>
Cc: Jingoo Han <jingoohan1@gmail.com>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 Krzysztof Wilczynski <kwilczynski@kernel.org>, 
 Rob Herring <robh@kernel.org>, Bjorn Helgaas <bhelgaas@google.com>, 
 Brian Masney <bmasney+clk@redhat.com>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Philipp Zabel <p.zabel@pengutronix.de>, 
 linux-pci@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-clk@vger.kernel.org, linux-phy@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795459409; l=6867;
 i=filipp.dunsky@gmail.com; s=20260930; h=from:subject:message-id;
 bh=IQ3oYOkjhHmvjI099J9lb0QbUnLsKlUN+CsHrOCPogE=;
 b=bBrX5NDk5ovSGT+tLFaV3zfxL6wseB3LnVHHNP2SUFSz95ISHr57Dpw2LjCtsKecVU+I9kmDx
 UQjG/nzmimsB4na7FHqEBMZhC34rIaABbK1hTYE7RVDGeTgD95cMzDU
X-Developer-Key: i=filipp.dunsky@gmail.com; a=ed25519;
 pk=JAYP8e2rJ54DHOmhNtXud8rl1igAaAXoOHxtJmVXI1g=
X-Endpoint-Received: by B4 Relay for filipp.dunsky@gmail.com/20260930 with auth_id=1085
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Use the shared global regmap for controller gates at bits 10, 12 and 14
and block resets at bits 6 through 8. Keep the AXI reset-disable bit and
SATA gates intact. Expose independent gate-only clocks and exclusive
reset controls with the vendor reset pulse timing.

Signed-off-by: Fil Dunsky <filipp.dunsky@gmail.com>
---
 drivers/clk/Kconfig           |  11 +++
 drivers/clk/Makefile          |   2 +
 drivers/clk/clk-cs7542-pcie.c | 168 ++++++++++++++++++++++++++++++++++++++++++
 3 files changed, 181 insertions(+)

diff --git a/drivers/clk/Kconfig b/drivers/clk/Kconfig
index 47b5265fe..4abd81260 100644
--- a/drivers/clk/Kconfig
+++ b/drivers/clk/Kconfig
@@ -605,4 +605,15 @@ config CLK_DIVIDER_KUNIT_TEST
 	help
 	  Kunit test for the clk-divider type.
 
+config COMMON_CLK_CS7542_PCIE
+	tristate "Cortina Systems CS7542 PCIe control"
+	depends on OF && HAS_IOMEM
+	select MFD_SYSCON
+	select RESET_CONTROLLER
+	help
+	  Enable the three PCIe clock gates and controller resets in the
+	  CS7542 global control block. Shared registers use the parent syscon.
+	  The clocks provide gating only, without a source frequency.
+	  The module is called clk-cs7542-pcie.
+
 endif
diff --git a/drivers/clk/Makefile b/drivers/clk/Makefile
index 16b1168c8..8ebb794d0 100644
--- a/drivers/clk/Makefile
+++ b/drivers/clk/Makefile
@@ -187,3 +187,5 @@ obj-y					+= xilinx/
 obj-$(CONFIG_COMMON_CLK_ZTE)		+= zte/
 obj-$(CONFIG_ARCH_ZYNQ)			+= zynq/
 obj-$(CONFIG_COMMON_CLK_ZYNQMP)         += zynqmp/
+
+obj-$(CONFIG_COMMON_CLK_CS7542_PCIE) += clk-cs7542-pcie.o
diff --git a/drivers/clk/clk-cs7542-pcie.c b/drivers/clk/clk-cs7542-pcie.c
new file mode 100644
index 000000000..c39977a25
--- /dev/null
+++ b/drivers/clk/clk-cs7542-pcie.c
@@ -0,0 +1,168 @@
+// SPDX-License-Identifier: GPL-2.0-only
+/* Cortina Systems CS7542 PCIe clock gates and controller resets. */
+#include <linux/clk-provider.h>
+#include <linux/delay.h>
+#include <linux/mfd/syscon.h>
+#include <linux/module.h>
+#include <linux/of.h>
+#include <linux/platform_device.h>
+#include <linux/regmap.h>
+#include <linux/reset-controller.h>
+
+#define CS7542_PORTS	3
+#define GLOBAL_RESET	0x04
+#define GLOBAL_CONFIG	0x10
+
+struct cs7542_gate {
+	struct clk_hw hw;
+	struct regmap *map;
+	u32 mask;
+};
+
+struct cs7542_control {
+	struct reset_controller_dev rcdev;
+	struct regmap *map;
+	struct cs7542_gate gates[CS7542_PORTS];
+	struct clk_hw_onecell_data *clks;
+};
+
+static int cs7542_gate_prepare(struct clk_hw *hw)
+{
+	struct cs7542_gate *gate = container_of(hw, struct cs7542_gate, hw);
+
+	return regmap_update_bits(gate->map, GLOBAL_CONFIG, gate->mask, gate->mask);
+}
+
+static void cs7542_gate_unprepare(struct clk_hw *hw)
+{
+	struct cs7542_gate *gate = container_of(hw, struct cs7542_gate, hw);
+
+	regmap_update_bits(gate->map, GLOBAL_CONFIG, gate->mask, 0);
+}
+
+static int cs7542_gate_is_prepared(struct clk_hw *hw)
+{
+	struct cs7542_gate *gate = container_of(hw, struct cs7542_gate, hw);
+	unsigned int value;
+	int ret;
+
+	ret = regmap_read(gate->map, GLOBAL_CONFIG, &value);
+	return ret ? ret : !!(value & gate->mask);
+}
+
+static const struct clk_ops cs7542_gate_ops = {
+	.prepare = cs7542_gate_prepare,
+	.unprepare = cs7542_gate_unprepare,
+	.is_prepared = cs7542_gate_is_prepared,
+};
+
+static int cs7542_reset_update(struct reset_controller_dev *rcdev,
+			       unsigned long id, bool assert)
+{
+	struct cs7542_control *ctl = container_of(rcdev, struct cs7542_control, rcdev);
+	u32 mask = BIT(6 + id);
+
+	return regmap_update_bits(ctl->map, GLOBAL_RESET, mask, assert ? mask : 0);
+}
+
+static int cs7542_reset_assert(struct reset_controller_dev *rcdev, unsigned long id)
+{
+	return cs7542_reset_update(rcdev, id, true);
+}
+
+static int cs7542_reset_deassert(struct reset_controller_dev *rcdev, unsigned long id)
+{
+	return cs7542_reset_update(rcdev, id, false);
+}
+
+static int cs7542_reset_status(struct reset_controller_dev *rcdev, unsigned long id)
+{
+	struct cs7542_control *ctl = container_of(rcdev, struct cs7542_control, rcdev);
+	unsigned int value;
+	int ret;
+
+	ret = regmap_read(ctl->map, GLOBAL_RESET, &value);
+	return ret ? ret : !!(value & BIT(6 + id));
+}
+
+static int cs7542_reset_pulse(struct reset_controller_dev *rcdev, unsigned long id)
+{
+	int ret;
+
+	ret = cs7542_reset_assert(rcdev, id);
+	if (ret)
+		return ret;
+	usleep_range(10000, 12000);
+	ret = cs7542_reset_deassert(rcdev, id);
+	if (ret)
+		return ret;
+	usleep_range(10000, 12000);
+	return 0;
+}
+
+static const struct reset_control_ops cs7542_reset_ops = {
+	.assert = cs7542_reset_assert,
+	.deassert = cs7542_reset_deassert,
+	.status = cs7542_reset_status,
+	.reset = cs7542_reset_pulse,
+};
+
+static int cs7542_control_probe(struct platform_device *pdev)
+{
+	struct device *dev = &pdev->dev;
+	struct cs7542_control *ctl;
+	int ret, i;
+
+	ctl = devm_kzalloc(dev, sizeof(*ctl), GFP_KERNEL);
+	if (!ctl)
+		return -ENOMEM;
+	ctl->map = syscon_node_to_regmap(dev->of_node->parent);
+	if (IS_ERR(ctl->map))
+		return dev_err_probe(dev, PTR_ERR(ctl->map), "global register map\n");
+	ctl->clks = devm_kzalloc(dev, struct_size(ctl->clks, hws, CS7542_PORTS), GFP_KERNEL);
+	if (!ctl->clks)
+		return -ENOMEM;
+	ctl->clks->num = CS7542_PORTS;
+	for (i = 0; i < CS7542_PORTS; i++) {
+		struct cs7542_gate *gate = &ctl->gates[i];
+		struct clk_init_data init = { .ops = &cs7542_gate_ops };
+
+		init.name = devm_kasprintf(dev, GFP_KERNEL, "%s.pcie%d", dev_name(dev), i);
+		if (!init.name)
+			return -ENOMEM;
+		/* Gate-only controls: no source frequency is described or assumed. */
+		gate->map = ctl->map;
+		gate->mask = BIT(10 + 2 * i);
+		gate->hw.init = &init;
+		ret = devm_clk_hw_register(dev, &gate->hw);
+		if (ret)
+			return dev_err_probe(dev, ret, "clock gate %d\n", i);
+		ctl->clks->hws[i] = &gate->hw;
+	}
+	ret = devm_of_clk_add_hw_provider(dev, of_clk_hw_onecell_get, ctl->clks);
+	if (ret)
+		return ret;
+	ctl->rcdev.owner = THIS_MODULE;
+	ctl->rcdev.ops = &cs7542_reset_ops;
+	ctl->rcdev.of_node = dev->of_node;
+	ctl->rcdev.nr_resets = CS7542_PORTS;
+	return devm_reset_controller_register(dev, &ctl->rcdev);
+}
+
+static const struct of_device_id cs7542_control_match[] = {
+	{ .compatible = "cortina,cs7542-pcie-control" },
+	{ }
+};
+MODULE_DEVICE_TABLE(of, cs7542_control_match);
+
+static struct platform_driver cs7542_control_driver = {
+	.probe = cs7542_control_probe,
+	.driver = {
+		.name = "cs7542-pcie-control",
+		.of_match_table = cs7542_control_match,
+	},
+};
+module_platform_driver(cs7542_control_driver);
+
+MODULE_DESCRIPTION("Cortina Systems CS7542 PCIe clock gates and resets");
+MODULE_LICENSE("GPL");

-- 
2.53.0

