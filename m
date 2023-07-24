From: Yang Xiwen <forbidden405@outlook.com>
Date: Tue, 25 Jul 2023 00:20:09 +0800
Subject: [PATCH 2/2] net: add hifemac_mdio MDIO bus driver for HiSilicon
 platform
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230725-wip-hisi_femac-trunk-v1-2-88469a170310@outlook.com>
References: <20230725-wip-hisi_femac-trunk-v1-0-88469a170310@outlook.com>
In-Reply-To: <20230725-wip-hisi_femac-trunk-v1-0-88469a170310@outlook.com>
To: Joe Hershberger <joe.hershberger@ni.com>, 
 Ramon Fried <rfried.dev@gmail.com>
Cc: Yisen Zhuang <yisen.zhuang@huawei.com>, 
 Salil Mehta <salil.mehta@huawei.com>, David Yang <mmyangfl@gmail.com>, 
 u-boot@lists.denx.de, Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1690215608; l=4568;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=4syExiz9un8re9MThVdbJUfNlN8n7QxQCeyhvkwV2UM=;
 b=yCPnFxILknnpaVCN4dg8uPXAJFE5DOTm79Lucxk/+IeOe38ZuOu2lQMOFp+cC5fvxL35+vDPA
 8Ssl1khjxDVAH6wX6oAZt9Lf7btRp02KRvPY8xIFZKo5iOKghrp6x8n
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

It adds the driver for the internal MDIO bus of HIFEMAC Ethernet
controller.  It's based on the mainstream linux driver.

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
 drivers/net/Kconfig        |   8 ++++
 drivers/net/Makefile       |   1 +
 drivers/net/hifemac_mdio.c | 116 +++++++++++++++++++++++++++++++++++++++++++++
 3 files changed, 125 insertions(+)

diff --git a/drivers/net/Kconfig b/drivers/net/Kconfig
index bc1d6e3905..5c5bfb1263 100644
--- a/drivers/net/Kconfig
+++ b/drivers/net/Kconfig
@@ -895,6 +895,14 @@ config HIFEMAC_ETH
 	  This driver supports HIFEMAC Ethernet controller found on
 	  HiSilicon SoCs.
 
+config HIFEMAC_MDIO
+	bool "HiSilicon Fast Ethernet Controller MDIO interface"
+	depends on DM_MDIO
+	select DM_CLK
+	help
+	  This driver supports the internal MDIO interface of HIFEMAC
+	  Ethernet controller.
+
 config HIGMACV300_ETH
 	bool "HiSilicon Gigabit Ethernet Controller"
 	select DM_RESET
diff --git a/drivers/net/Makefile b/drivers/net/Makefile
index de6bf1d014..b2d3da6934 100644
--- a/drivers/net/Makefile
+++ b/drivers/net/Makefile
@@ -46,6 +46,7 @@ obj-$(CONFIG_FTGMAC100) += ftgmac100.o
 obj-$(CONFIG_FTMAC100) += ftmac100.o
 obj-$(CONFIG_GMAC_ROCKCHIP) += gmac_rockchip.o
 obj-$(CONFIG_HIFEMAC_ETH) += hifemac.o
+obj-$(CONFIG_HIFEMAC_MDIO) += hifemac_mdio.o
 obj-$(CONFIG_HIGMACV300_ETH) += higmacv300.o
 obj-$(CONFIG_KS8851_MLL) += ks8851_mll.o
 obj-$(CONFIG_KSZ9477) += ksz9477.o
diff --git a/drivers/net/hifemac_mdio.c b/drivers/net/hifemac_mdio.c
new file mode 100644
index 0000000000..343c5f3a38
--- /dev/null
+++ b/drivers/net/hifemac_mdio.c
@@ -0,0 +1,116 @@
+// SPDX-License-Identifier: GPL-2.0+
+/*
+ * Hisilicon Fast Ethernet MDIO Bus Driver
+ *
+ * Copyright (c) 2016 HiSilicon Technologies Co., Ltd.
+ */
+
+#include <dm.h>
+#include <clk.h>
+#include <miiphy.h>
+#include <linux/io.h>
+#include <linux/iopoll.h>
+
+#define MDIO_RWCTRL		0x00
+#define MDIO_RO_DATA		0x04
+#define MDIO_WRITE		BIT(13)
+#define MDIO_RW_FINISH		BIT(15)
+#define BIT_PHY_ADDR_OFFSET	8
+#define BIT_WR_DATA_OFFSET	16
+
+struct hisi_femac_mdio_data {
+	struct clk *clk;
+	void __iomem *membase;
+};
+
+static int hisi_femac_mdio_wait_ready(struct hisi_femac_mdio_data *data)
+{
+	u32 val;
+
+	return readl_poll_timeout(data->membase + MDIO_RWCTRL,
+				  val, val & MDIO_RW_FINISH, 10000);
+}
+
+static int hisi_femac_mdio_read(struct udevice *dev, int addr, int devad, int reg)
+{
+	struct hisi_femac_mdio_data *data = dev_get_priv(dev);
+	int ret;
+
+	ret = hisi_femac_mdio_wait_ready(data);
+	if (ret)
+		return ret;
+
+	writel((addr << BIT_PHY_ADDR_OFFSET) | reg,
+	       data->membase + MDIO_RWCTRL);
+
+	ret = hisi_femac_mdio_wait_ready(data);
+	if (ret)
+		return ret;
+
+	return readl(data->membase + MDIO_RO_DATA) & 0xFFFF;
+}
+
+static int hisi_femac_mdio_write(struct udevice *dev, int addr, int devad, int reg, u16 val)
+{
+	struct hisi_femac_mdio_data *data = dev_get_priv(dev);
+	int ret;
+
+	ret = hisi_femac_mdio_wait_ready(data);
+	if (ret)
+		return ret;
+
+	writel(MDIO_WRITE | (val << BIT_WR_DATA_OFFSET) |
+	       (addr << BIT_PHY_ADDR_OFFSET) | reg,
+	       data->membase + MDIO_RWCTRL);
+
+	return hisi_femac_mdio_wait_ready(data);
+}
+
+static int hisi_femac_mdio_of_to_plat(struct udevice *dev)
+{
+	struct hisi_femac_mdio_data *data = dev_get_priv(dev);
+	int ret;
+
+	data->membase = dev_remap_addr(dev);
+	if (IS_ERR(data->membase)) {
+		ret = PTR_ERR(data->membase);
+		return log_msg_ret("Failed to remap base addr", ret);
+	}
+
+	// clk is optional
+	data->clk = devm_clk_get_optional(dev, NULL);
+
+	return 0;
+}
+
+static int hisi_femac_mdio_probe(struct udevice *dev)
+{
+	struct hisi_femac_mdio_data *data = dev_get_priv(dev);
+	int ret;
+
+	ret = clk_prepare_enable(data->clk);
+	if (ret)
+		return log_msg_ret("Failed to enable clk", ret);
+
+	return 0;
+}
+
+static const struct mdio_ops hisi_femac_mdio_ops = {
+	.read = hisi_femac_mdio_read,
+	.write = hisi_femac_mdio_write,
+};
+
+static const struct udevice_id hisi_femac_mdio_dt_ids[] = {
+	{ .compatible = "hisilicon,hisi-femac-mdio" },
+	{ }
+};
+
+U_BOOT_DRIVER(hisi_femac_mdio_driver) = {
+	.name = "hisi-femac-mdio",
+	.id = UCLASS_MDIO,
+	.of_match = hisi_femac_mdio_dt_ids,
+	.of_to_plat = hisi_femac_mdio_of_to_plat,
+	.probe = hisi_femac_mdio_probe,
+	.ops = &hisi_femac_mdio_ops,
+	.priv_auto = sizeof(struct hisi_femac_mdio_data),
+};

-- 
2.34.1

