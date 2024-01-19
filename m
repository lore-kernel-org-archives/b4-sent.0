From: Yang Xiwen <forbidden405@outlook.com>
Date: Fri, 19 Jan 2024 12:24:28 +0800
Subject: [PATCH] wdt: add HiSilicon watchdog driver support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240119-b4-wdt-v1-1-b117901385d7@outlook.com>
X-B4-Tracking: v=1; b=H4sIAHv5qWUC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIxMDQ0NL3SQT3fKUEt0UU8PUJOPEVDOjZEsloOKCotS0zAqwQdGxtbUAmvW
 lUVgAAAA=
To: Stefan Roese <sr@denx.de>
Cc: David Yang <mmyangfl@gmail.com>, u-boot@lists.denx.de, 
 Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1705638268; l=6751;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=J7OZzpBCcAKp4e6kKPvlWBuQmgxpe0gSMju9TlFEDF0=;
 b=PhTcA1Kg2sBu2B4O53aEjYqbqZrIarGLPhkHB8UxzJf3md3JRXkxte7IE5NVtrOrPN1ptvgrA
 dVkppHAeZY/DWugKC4aitajOJf3+DBbkLJIQYBKgce6sdLtDf6Ou6dw
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This watchdog core is found on many HiSilicon SoCs. Add support for it.

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
 drivers/watchdog/Kconfig    |  10 +++
 drivers/watchdog/Makefile   |   1 +
 drivers/watchdog/hisi_wdt.c | 196 ++++++++++++++++++++++++++++++++++++++++++++
 3 files changed, 207 insertions(+)

diff --git a/drivers/watchdog/Kconfig b/drivers/watchdog/Kconfig
index 569726119c..ddf44f63d2 100644
--- a/drivers/watchdog/Kconfig
+++ b/drivers/watchdog/Kconfig
@@ -32,6 +32,7 @@ config WATCHDOG_TIMEOUT_MSECS
 	default 16000 if ARCH_SUNXI
 	default 5376 if ULP_WATCHDOG
 	default 15000 if ARCH_BCM283X
+	range 500 180000 if ARCH_HISI
 	default 60000
 	help
 	  Watchdog timeout in msec
@@ -171,6 +172,15 @@ config WDT_GPIO
 	  doc/device-tree-bindings/watchdog/gpio-wdt.txt for
 	  information on how to describe the watchdog in device tree.
 
+config WDT_HISI
+	bool "HiSilicon watchdog timer support"
+	depends on WDT
+	depends on CLK && DM_RESET
+	imply WATCHDOG
+	help
+	  Select this to enable HiSilicon watchdog timer.
+	  Currently supports Hi3798MV200 only.
+
 config WDT_MAX6370
 	bool "MAX6370 watchdog timer support"
 	depends on WDT
diff --git a/drivers/watchdog/Makefile b/drivers/watchdog/Makefile
index 5520d3d9ae..3436aa6389 100644
--- a/drivers/watchdog/Makefile
+++ b/drivers/watchdog/Makefile
@@ -30,6 +30,7 @@ obj-$(CONFIG_WDT_ORION) += orion_wdt.o
 obj-$(CONFIG_WDT_CDNS) += cdns_wdt.o
 obj-$(CONFIG_WDT_FTWDT010) += ftwdt010_wdt.o
 obj-$(CONFIG_WDT_GPIO) += gpio_wdt.o
+obj-$(CONFIG_WDT_HISI) += hisi_wdt.o
 obj-$(CONFIG_WDT_MAX6370) += max6370_wdt.o
 obj-$(CONFIG_WDT_MCF) += mcf_wdt.o
 obj-$(CONFIG_WDT_MESON_GXBB) += meson_gxbb_wdt.o
diff --git a/drivers/watchdog/hisi_wdt.c b/drivers/watchdog/hisi_wdt.c
new file mode 100644
index 0000000000..5be9e90865
--- /dev/null
+++ b/drivers/watchdog/hisi_wdt.c
@@ -0,0 +1,196 @@
+// SPDX-License-Identifier: GPL-2.0-or-later
+/*
+ * Watchdog driver for HiSilicon SoCs
+ *
+ * Copyright 2024 (r) Yang Xiwen <forbidden405@outlook.com>
+ */
+
+#include <clk.h>
+#include <errno.h>
+#include <log.h>
+#include <reset.h>
+#include <wdt.h>
+#include <dm/device_compat.h>
+#include <dm/device.h>
+#include <dm/lists.h>
+#include <dm/read.h>
+#include <linux/delay.h>
+#include <linux/math64.h>
+#include <linux/types.h>
+
+/* CONTROL register definitions */
+#define HISI_WDG_RES_EN	BIT(1)
+#define HISI_WDG_INT_EN	BIT(0)
+
+/* RIS(Raw Interrupt Status) register definitions */
+#define HISI_WDG_RIS	BIT(0)
+
+/* MIS(Masked Interrupt Status) register definitions*/
+#define HISI_WDG_MIS	BIT(0)
+
+/* LOCK register magic */
+// Write this value to unlock watchdog
+#define HISI_WDG_LOCK_MAGIC	0x1ACCE551
+// Read values
+#define HISI_WDG_LOCK_WA	0x0
+#define HISI_WDG_LOCK_RO	0x1
+
+struct hisi_wdg_reg {
+	u32 load; // 0x0000
+	u32 value; // 0x0004
+	u32 control; // 0x0008
+	u32 intclr; // 0x000c
+	u32 ris; // 0x0010
+	u32 mis; // 0x0014
+	u32 reserved[762]; // 0x0018
+	u32 lock; // 0x0c00
+};
+
+struct hisi_wdt_priv {
+	struct hisi_wdg_reg __iomem *reg;
+	struct clk *clk;
+	struct reset_ctl *rst;
+};
+
+static inline void hisi_wdt_unlock(struct hisi_wdg_reg __iomem *reg)
+{
+	reg->lock = HISI_WDG_LOCK_MAGIC;
+}
+
+static inline void hisi_wdt_lock(struct hisi_wdg_reg __iomem *reg)
+{
+	// Any value other than HISI_WDG_LOCK_MAGIC would lock the registers
+	reg->lock = 0;
+}
+
+static int hisi_wdt_start(struct udevice *dev, u64 timeout_ms, ulong flags)
+{
+	struct hisi_wdt_priv *priv = dev_get_priv(dev);
+	u64 rate;
+	u64 val;
+
+	rate = clk_get_rate(priv->clk);
+
+	/* This may overflow */
+	val = mul_u64_u32_div(timeout_ms, rate, 1000);
+	if (val > UINT32_MAX) {
+		dev_warn(dev, "timeout_ms too large, using maximum.\n");
+		val = UINT32_MAX;
+	}
+
+	hisi_wdt_unlock(priv->reg);
+
+	priv->reg->load = (u32) val;
+	priv->reg->control |= (HISI_WDG_RES_EN | HISI_WDG_INT_EN);
+
+	hisi_wdt_lock(priv->reg);
+
+	return 0;
+}
+
+static int hisi_wdt_stop(struct udevice *dev)
+{
+	struct hisi_wdt_priv *priv = dev_get_priv(dev);
+
+	hisi_wdt_unlock(priv->reg);
+	// disabling interrupt also disables counting
+	priv->reg->control &= ~HISI_WDG_INT_EN;
+
+	hisi_wdt_lock(priv->reg);
+
+	return 0;
+}
+
+static int hisi_wdt_reset(struct udevice *dev)
+{
+	struct hisi_wdt_priv *priv = dev_get_priv(dev);
+
+	hisi_wdt_unlock(priv->reg);
+
+	// any value written to INTCLR would result a counter reload
+	priv->reg->intclr = 0;
+
+	hisi_wdt_lock(priv->reg);
+
+	return 0;
+}
+
+static int hisi_wdt_expire_now(struct udevice *dev, ulong flags)
+{
+	return hisi_wdt_start(dev, 1, flags);
+}
+
+static const struct wdt_ops hisi_wdt_ops = {
+	.start		= hisi_wdt_start,
+	.stop		= hisi_wdt_stop,
+	.reset		= hisi_wdt_reset,
+	.expire_now	= hisi_wdt_expire_now,
+};
+
+static int hisi_wdt_probe(struct udevice *dev)
+{
+	struct hisi_wdt_priv *priv = dev_get_priv(dev);
+	int ret;
+
+	ret = clk_prepare_enable(priv->clk);
+	if (ret) {
+		dev_err(dev, "failed to enable clk: %d\n", ret);
+		return log_msg_ret("clk", ret);
+	}
+
+	ret = reset_assert(priv->rst);
+	if (ret) {
+		dev_err(dev, "failed to assert reset: %d\n", ret);
+		return log_msg_ret("rst", ret);
+	}
+
+	udelay(10);
+
+	ret = reset_deassert(priv->rst);
+	if (ret) {
+		dev_err(dev, "failed to deassert reset: %d\n", ret);
+		return log_msg_ret("rst", ret);
+	}
+
+	return 0;
+}
+
+static int hisi_wdt_of_to_plat(struct udevice *dev)
+{
+	struct hisi_wdt_priv *priv = dev_get_priv(dev);
+
+	priv->reg = dev_remap_addr(dev);
+	if (!priv->reg) {
+		dev_err(dev, "failed to remap\n");
+		return log_msg_ret("wdt", -EINVAL);
+	}
+
+	priv->clk = devm_clk_get(dev, NULL);
+	if (IS_ERR(priv->clk)) {
+		dev_err(dev, "failed to get clk: %ld\n", PTR_ERR(priv->clk));
+		return log_msg_ret("wdt", PTR_ERR(priv->clk));
+	}
+
+	priv->rst = devm_reset_control_get(dev, NULL);
+	if (IS_ERR(priv->rst)) {
+		dev_err(dev, "failed to get rst: %ld\n", PTR_ERR(priv->rst));
+		return log_msg_ret("wdt", PTR_ERR(priv->rst));
+	}
+
+	return 0;
+}
+
+static const struct udevice_id hisi_wdt_ids[] = {
+	{ .compatible = "hisilicon,wdt" },
+	{ /* sentinel */ }
+};
+
+U_BOOT_DRIVER(hisi_wdt) = {
+	.name		= "hisilicon_wdt",
+	.id		= UCLASS_WDT,
+	.of_match	= hisi_wdt_ids,
+	.of_to_plat	= hisi_wdt_of_to_plat,
+	.probe		= hisi_wdt_probe,
+	.priv_auto	= sizeof(struct hisi_wdt_priv),
+	.ops		= &hisi_wdt_ops,
+};

---
base-commit: 842c5b501be7fe23f618788002c5e81fd56ac382
change-id: 20240119-b4-wdt-d51eb3ae62c9

Best regards,
-- 
Yang Xiwen <forbidden405@outlook.com>

