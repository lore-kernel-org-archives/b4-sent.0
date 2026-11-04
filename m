From: Joseph Telaak <joseph@telaak.dev>
Date: Wed, 04 Nov 2026 02:21:53 -0500
Subject: [PATCH 2/2] phy: siflower: Add SF19A2890 USB 2.0 PHY driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261104-sf19a2890-usb-phy-v1-2-db0cad937614@telaak.dev>
References: <20261104-sf19a2890-usb-phy-v1-0-db0cad937614@telaak.dev>
In-Reply-To: <20261104-sf19a2890-usb-phy-v1-0-db0cad937614@telaak.dev>
To: Vinod Koul <vkoul@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Manivannan Sadhasivam <mani@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Philipp Zabel <p.zabel@pengutronix.de>
Cc: Chuanhong Guo <gch981213@gmail.com>, linux-mips@vger.kernel.org, 
 linux-phy@lists.infradead.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Joseph Telaak <joseph@telaak.dev>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793776918; l=6750;
 i=joseph@telaak.dev; s=20261104; h=from:subject:message-id;
 bh=55sjfweFDl3DG/Y6urUkTYcKNznJpA6dYN0tn3GpR60=;
 b=fBCGjzUkgrhO5V0MSgDZavQVMJosq7wf7j6vJZc3dSEWh8cyjWVRUkp7kWfTq+V2kGKxAF4yj
 gploIT2HsfeBbYHKLst8Z/GapSmTymX/USDsbzbBTE991U0KrihAAz2
X-Developer-Key: i=joseph@telaak.dev; a=ed25519;
 pk=oQI+UfddlZ0wK2ac4WKOGNjUl1ZEN8j9ZVFSqEDoNP0=
X-Endpoint-Received: by B4 Relay for joseph@telaak.dev/20261104 with auth_id=1404
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Chuanhong Guo <gch981213@gmail.com>

Add a driver for the USB 2.0 PHY of the Siflower SF19A2890. Powering it
on enables its reference clock, releases its two resets and takes it
out of sleep.

Signed-off-by: Chuanhong Guo <gch981213@gmail.com>
[jt: from Chuanhong's siflower-7.1 branch, the SF19A2890 PHY only; reset
 names "por" and "phy", dev_err_probe() for the resets, drop the unused
 includes and drvdata, Kconfig dependencies and help, commit message,
 subject]
Signed-off-by: Joseph Telaak <joseph@telaak.dev>
---
 drivers/phy/Kconfig                      |   1 +
 drivers/phy/Makefile                     |   1 +
 drivers/phy/siflower/Kconfig             |  12 +++
 drivers/phy/siflower/Makefile            |   2 +
 drivers/phy/siflower/phy-sf19a2890-usb.c | 143 +++++++++++++++++++++++++++++++
 5 files changed, 159 insertions(+)

diff --git a/drivers/phy/Kconfig b/drivers/phy/Kconfig
index 105fbe408..8ba351e23 100644
--- a/drivers/phy/Kconfig
+++ b/drivers/phy/Kconfig
@@ -194,6 +194,7 @@ source "drivers/phy/realtek/Kconfig"
 source "drivers/phy/renesas/Kconfig"
 source "drivers/phy/rockchip/Kconfig"
 source "drivers/phy/samsung/Kconfig"
+source "drivers/phy/siflower/Kconfig"
 source "drivers/phy/socionext/Kconfig"
 source "drivers/phy/sophgo/Kconfig"
 source "drivers/phy/spacemit/Kconfig"
diff --git a/drivers/phy/Makefile b/drivers/phy/Makefile
index c6dd02003..8c917c4c5 100644
--- a/drivers/phy/Makefile
+++ b/drivers/phy/Makefile
@@ -46,6 +46,7 @@ obj-$(CONFIG_GENERIC_PHY)		+= allwinner/	\
 					   renesas/	\
 					   rockchip/	\
 					   samsung/	\
+					   siflower/	\
 					   socionext/	\
 					   sophgo/	\
 					   spacemit/	\
diff --git a/drivers/phy/siflower/Kconfig b/drivers/phy/siflower/Kconfig
new file mode 100644
index 000000000..5ae1f83d1
--- /dev/null
+++ b/drivers/phy/siflower/Kconfig
@@ -0,0 +1,12 @@
+# SPDX-License-Identifier: GPL-2.0-only
+
+config PHY_SF19A2890_USB
+	tristate "Siflower SF19A2890 USB 2.0 PHY driver"
+	depends on MACH_SIFLOWER_MIPS || COMPILE_TEST
+	depends on OF
+	select GENERIC_PHY
+	help
+	  Enable this to support the USB 2.0 PHY of the Siflower SF19A2890,
+	  used by its DWC2 controller. Its reference clock and its resets
+	  come from the USB block's clock and reset manager.
+	  Say M or Y if the kernel is to run on this SoC.
diff --git a/drivers/phy/siflower/Makefile b/drivers/phy/siflower/Makefile
new file mode 100644
index 000000000..a12383193
--- /dev/null
+++ b/drivers/phy/siflower/Makefile
@@ -0,0 +1,2 @@
+# SPDX-License-Identifier: GPL-2.0-only
+obj-$(CONFIG_PHY_SF19A2890_USB)	+= phy-sf19a2890-usb.o
diff --git a/drivers/phy/siflower/phy-sf19a2890-usb.c b/drivers/phy/siflower/phy-sf19a2890-usb.c
new file mode 100644
index 000000000..115e38b8c
--- /dev/null
+++ b/drivers/phy/siflower/phy-sf19a2890-usb.c
@@ -0,0 +1,143 @@
+// SPDX-License-Identifier: GPL-2.0
+
+#include <linux/clk.h>
+#include <linux/io.h>
+#include <linux/module.h>
+#include <linux/of.h>
+#include <linux/phy/phy.h>
+#include <linux/platform_device.h>
+#include <linux/reset.h>
+
+#define USB_SLEEPM 0x4
+
+struct sf19a2890_usb_phy {
+	struct device *dev;
+	struct clk *phy_clk;
+	struct reset_control *usb_phy_rst;
+	struct reset_control *power_on_rst;
+	void __iomem *base;
+};
+
+static int sf19a2890_usb_phy_power_on(struct phy *phy)
+{
+	struct sf19a2890_usb_phy *p_phy = phy_get_drvdata(phy);
+	int ret;
+
+	ret = clk_prepare_enable(p_phy->phy_clk);
+	if (ret < 0) {
+		dev_err(p_phy->dev, "Failed to enable PHY clock: %d\n", ret);
+		return ret;
+	}
+
+	ret = reset_control_deassert(p_phy->usb_phy_rst);
+	if (ret)
+		goto err1;
+
+	ret = reset_control_deassert(p_phy->power_on_rst);
+	if (ret)
+		goto err2;
+
+	writel(1, p_phy->base + USB_SLEEPM);
+	return 0;
+err2:
+	reset_control_assert(p_phy->usb_phy_rst);
+err1:
+	clk_disable_unprepare(p_phy->phy_clk);
+	return ret;
+}
+
+static int sf19a2890_usb_phy_power_off(struct phy *phy)
+{
+	struct sf19a2890_usb_phy *p_phy = phy_get_drvdata(phy);
+
+	writel(0, p_phy->base + USB_SLEEPM);
+	reset_control_assert(p_phy->power_on_rst);
+	reset_control_assert(p_phy->usb_phy_rst);
+	clk_disable_unprepare(p_phy->phy_clk);
+	return 0;
+}
+
+static const struct phy_ops sf19a2890_usb_phy_ops = {
+	.power_on = sf19a2890_usb_phy_power_on,
+	.power_off = sf19a2890_usb_phy_power_off,
+	.owner = THIS_MODULE,
+};
+
+static int sf19a2890_usb_phy_probe(struct platform_device *pdev)
+{
+	struct sf19a2890_usb_phy *p_phy;
+	struct phy_provider *provider;
+	struct phy *phy;
+	int ret;
+
+	p_phy = devm_kzalloc(&pdev->dev, sizeof(*p_phy), GFP_KERNEL);
+	if (!p_phy)
+		return -ENOMEM;
+
+	p_phy->dev = &pdev->dev;
+
+	p_phy->base = devm_platform_ioremap_resource(pdev, 0);
+	if (IS_ERR(p_phy->base))
+		return PTR_ERR(p_phy->base);
+
+	p_phy->phy_clk = devm_clk_get(p_phy->dev, NULL);
+	if (IS_ERR(p_phy->phy_clk))
+		return dev_err_probe(p_phy->dev, PTR_ERR(p_phy->phy_clk),
+				     "failed to get usb phy clock\n");
+
+	p_phy->power_on_rst =
+		devm_reset_control_get_exclusive(&pdev->dev, "por");
+	if (IS_ERR(p_phy->power_on_rst))
+		return dev_err_probe(p_phy->dev, PTR_ERR(p_phy->power_on_rst),
+				     "failed to get power-on reset\n");
+
+	ret = reset_control_assert(p_phy->power_on_rst);
+	if (ret)
+		return ret;
+
+	p_phy->usb_phy_rst =
+		devm_reset_control_get_exclusive(&pdev->dev, "phy");
+	if (IS_ERR(p_phy->usb_phy_rst))
+		return dev_err_probe(p_phy->dev, PTR_ERR(p_phy->usb_phy_rst),
+				     "failed to get PHY reset\n");
+
+	ret = reset_control_assert(p_phy->usb_phy_rst);
+	if (ret)
+		return ret;
+
+	phy = devm_phy_create(p_phy->dev, NULL, &sf19a2890_usb_phy_ops);
+	if (IS_ERR(phy))
+		return dev_err_probe(p_phy->dev, PTR_ERR(phy),
+				     "Failed to create PHY\n");
+
+	phy_set_drvdata(phy, p_phy);
+
+	provider =
+		devm_of_phy_provider_register(p_phy->dev, of_phy_simple_xlate);
+	if (IS_ERR(provider))
+		return dev_err_probe(p_phy->dev, PTR_ERR(provider),
+				     "Failed to register PHY provider\n");
+
+	return 0;
+}
+
+static const struct of_device_id sf19a2890_usb_phy_of_match[] = {
+	{
+		.compatible = "siflower,sf19a2890-usb-phy",
+	},
+	{ }
+};
+MODULE_DEVICE_TABLE(of, sf19a2890_usb_phy_of_match);
+
+static struct platform_driver sf19a2890_usb_phy_driver = {
+	.probe		= sf19a2890_usb_phy_probe,
+	.driver		= {
+		.name	= "sf19a2890-usb-phy",
+		.of_match_table = sf19a2890_usb_phy_of_match,
+	},
+};
+module_platform_driver(sf19a2890_usb_phy_driver);
+
+MODULE_AUTHOR("Ziying Wu <ziying.wu@siflower.com.cn>");
+MODULE_DESCRIPTION("Siflower SF19A2890 USB2.0 PHY driver");
+MODULE_LICENSE("GPL");

-- 
Git-155)

