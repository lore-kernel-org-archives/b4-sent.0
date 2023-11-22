From: Nikita Shubin <nikita.shubin@maquefel.me>
Date: Wed, 22 Nov 2023 11:59:45 +0300
Subject: [PATCH v5 07/39] soc: Add SoC driver for Cirrus ep93xx
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20231122-ep93xx-v5-7-d59a76d5df29@maquefel.me>
References: <20231122-ep93xx-v5-0-d59a76d5df29@maquefel.me>
In-Reply-To: <20231122-ep93xx-v5-0-d59a76d5df29@maquefel.me>
To: Conor Dooley <conor.dooley@microchip.com>, 
 Joel Stanley <joel@jms.id.au>, Ulf Hansson <ulf.hansson@linaro.org>, 
 Linus Walleij <linus.walleij@linaro.org>, 
 Nikita Shubin <nikita.shubin@maquefel.me>, 
 Huisong Li <lihuisong@huawei.com>, 
 =?utf-8?q?Jonathan_Neusch=C3=A4fer?= <j.neuschaefer@gmx.net>, 
 Walker Chen <walker.chen@starfivetech.com>, Arnd Bergmann <arnd@arndb.de>, 
 Emil Renner Berthing <kernel@esmil.dk>, 
 Alexander Sverdlin <alexander.sverdlin@gmail.com>
Cc: Hal Feng <hal.feng@starfivetech.com>, linux-kernel@vger.kernel.org, 
 Alexander Sverdlin <alexander.sverdlin@gmail.com>
X-Mailer: b4 0.13-dev-e3e53
X-Developer-Signature: v=1; a=ed25519-sha256; t=1700643671; l=9535;
 i=nikita.shubin@maquefel.me; s=20230718; h=from:subject:message-id;
 bh=492Hz1SLrKJT3wrDoldgmUFnxDuoicaeq4JYJHEpza0=;
 b=FL4Xy2kCiYoVgtaTYR3NKH1VrdDE0Ys3YNcn+QPhr/tE5o1m8tN31NIEqj7TvncjJjOGoZKDpvRC
 dM6N73eoC4wjKfXIKWZ6l+8PRSfCZuzsrGn8/VpuZgji9hB+y9ve
X-Developer-Key: i=nikita.shubin@maquefel.me; a=ed25519;
 pk=vqf5YIUJ7BJv3EJFaNNxWZgGuMgDH6rwufTLflwU9ac=
X-Endpoint-Received: by B4 Relay for nikita.shubin@maquefel.me/20230718 with auth_id=65
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add an SoC driver for the ep93xx. Currently there is only one thing
not fitting into any other framework, and that is the swlock setting.

Used for clock settings, pinctrl and restart.

Signed-off-by: Nikita Shubin <nikita.shubin@maquefel.me>
Tested-by: Alexander Sverdlin <alexander.sverdlin@gmail.com>
Acked-by: Alexander Sverdlin <alexander.sverdlin@gmail.com>
Reviewed-by: Linus Walleij <linus.walleij@linaro.org>
---
 drivers/soc/Kconfig             |   1 +
 drivers/soc/Makefile            |   1 +
 drivers/soc/cirrus/Kconfig      |  13 +++
 drivers/soc/cirrus/Makefile     |   2 +
 drivers/soc/cirrus/soc-ep93xx.c | 247 ++++++++++++++++++++++++++++++++++++++++
 5 files changed, 264 insertions(+)

diff --git a/drivers/soc/Kconfig b/drivers/soc/Kconfig
index 10a9ff84ff41..47692deb68e4 100644
--- a/drivers/soc/Kconfig
+++ b/drivers/soc/Kconfig
@@ -7,6 +7,7 @@ source "drivers/soc/aspeed/Kconfig"
 source "drivers/soc/atmel/Kconfig"
 source "drivers/soc/bcm/Kconfig"
 source "drivers/soc/canaan/Kconfig"
+source "drivers/soc/cirrus/Kconfig"
 source "drivers/soc/fsl/Kconfig"
 source "drivers/soc/fujitsu/Kconfig"
 source "drivers/soc/hisilicon/Kconfig"
diff --git a/drivers/soc/Makefile b/drivers/soc/Makefile
index 0706a27d13be..6bfd520c325a 100644
--- a/drivers/soc/Makefile
+++ b/drivers/soc/Makefile
@@ -8,6 +8,7 @@ obj-y				+= aspeed/
 obj-$(CONFIG_ARCH_AT91)		+= atmel/
 obj-y				+= bcm/
 obj-$(CONFIG_SOC_CANAAN)	+= canaan/
+obj-$(CONFIG_EP93XX_SOC)        += cirrus/
 obj-$(CONFIG_ARCH_DOVE)		+= dove/
 obj-$(CONFIG_MACH_DOVE)		+= dove/
 obj-y				+= fsl/
diff --git a/drivers/soc/cirrus/Kconfig b/drivers/soc/cirrus/Kconfig
new file mode 100644
index 000000000000..fea3c3c82be0
--- /dev/null
+++ b/drivers/soc/cirrus/Kconfig
@@ -0,0 +1,13 @@
+# SPDX-License-Identifier: GPL-2.0
+
+if ARCH_EP93XX
+
+config EP93XX_SOC
+	bool "Cirrus EP93xx chips SoC"
+	select SOC_BUS
+	select AUXILIARY_BUS
+	default y if !EP93XX_SOC_COMMON
+	help
+	  Support SoC for Cirrus EP93xx chips.
+
+endif
diff --git a/drivers/soc/cirrus/Makefile b/drivers/soc/cirrus/Makefile
new file mode 100644
index 000000000000..ed6752844c6f
--- /dev/null
+++ b/drivers/soc/cirrus/Makefile
@@ -0,0 +1,2 @@
+# SPDX-License-Identifier: GPL-2.0
+obj-y	+= soc-ep93xx.o
diff --git a/drivers/soc/cirrus/soc-ep93xx.c b/drivers/soc/cirrus/soc-ep93xx.c
new file mode 100644
index 000000000000..47211ac1e64f
--- /dev/null
+++ b/drivers/soc/cirrus/soc-ep93xx.c
@@ -0,0 +1,247 @@
+// SPDX-License-Identifier: GPL-2.0+
+/*
+ * SoC driver for Cirrus EP93xx chips.
+ * Copyright (C) 2022 Nikita Shubin <nikita.shubin@maquefel.me>
+ *
+ * Based on a rewrite of arch/arm/mach-ep93xx/core.c
+ * Copyright (C) 2006 Lennert Buytenhek <buytenh@wantstofly.org>
+ * Copyright (C) 2007 Herbert Valerio Riedel <hvr@gnu.org>
+ *
+ * Thanks go to Michael Burian and Ray Lehtiniemi for their key
+ * role in the ep93xx Linux community
+ */
+
+#include <linux/bits.h>
+#include <linux/init.h>
+#include <linux/kernel.h>
+#include <linux/mfd/syscon.h>
+#include <linux/of.h>
+#include <linux/of_fdt.h>
+#include <linux/platform_device.h>
+#include <linux/regmap.h>
+#include <linux/slab.h>
+#include <linux/sys_soc.h>
+#include <linux/soc/cirrus/ep93xx.h>
+
+
+#define EP93XX_SYSCON_DEVCFG		0x80
+
+#define EP93XX_SWLOCK_MAGICK		0xaa
+#define EP93XX_SYSCON_SWLOCK		0xc0
+#define EP93XX_SYSCON_SYSCFG		0x9c
+#define EP93XX_SYSCON_SYSCFG_REV_MASK	GENMASK(31, 28)
+#define EP93XX_SYSCON_SYSCFG_REV_SHIFT	28
+
+struct ep93xx_map_info {
+	spinlock_t lock;
+	void __iomem *base;
+	struct regmap *map;
+};
+
+/*
+ * EP93xx System Controller software locked register write
+ *
+ * Logic safeguards are included to condition the control signals for
+ * power connection to the matrix to prevent part damage. In addition, a
+ * software lock register is included that must be written with 0xAA
+ * before each register write to change the values of the four switch
+ * matrix control registers.
+ */
+static void ep93xx_regmap_write(struct regmap *map, spinlock_t *lock,
+				 unsigned int reg, unsigned int val)
+{
+	unsigned long flags;
+
+	spin_lock_irqsave(lock, flags);
+
+	regmap_write(map, EP93XX_SYSCON_SWLOCK, EP93XX_SWLOCK_MAGICK);
+	regmap_write(map, reg, val);
+
+	spin_unlock_irqrestore(lock, flags);
+}
+
+static void ep93xx_regmap_update_bits(struct regmap *map, spinlock_t *lock,
+				      unsigned int reg, unsigned int mask,
+				      unsigned int val)
+{
+	unsigned long flags;
+
+	spin_lock_irqsave(lock, flags);
+
+	regmap_write(map, EP93XX_SYSCON_SWLOCK, EP93XX_SWLOCK_MAGICK);
+	/* force write is required to clear swlock if is no changes are made */
+	regmap_update_bits_base(map, reg, mask, val, NULL, false, true);
+
+	spin_unlock_irqrestore(lock, flags);
+}
+
+static void ep93xx_unregister_adev(void *_adev)
+{
+	struct auxiliary_device *adev = _adev;
+
+	auxiliary_device_delete(adev);
+	auxiliary_device_uninit(adev);
+}
+
+static void ep93xx_adev_release(struct device *dev)
+{
+	struct auxiliary_device *adev = to_auxiliary_dev(dev);
+
+	kfree(adev);
+}
+
+static struct auxiliary_device *ep93xx_adev_alloc(struct device *parent, const char *name,
+						  struct ep93xx_map_info *info)
+{
+	struct ep93xx_regmap_adev *rdev;
+	struct auxiliary_device *adev;
+	int ret;
+
+	rdev = kzalloc(sizeof(*rdev), GFP_KERNEL);
+	if (!rdev)
+		return ERR_PTR(-ENOMEM);
+
+	rdev->map = info->map;
+	rdev->base = info->base;
+	rdev->lock = &info->lock;
+	rdev->write = ep93xx_regmap_write;
+	rdev->update_bits = ep93xx_regmap_update_bits;
+
+	adev = &rdev->adev;
+	adev->name = name;
+	adev->dev.parent = parent;
+	adev->dev.release = ep93xx_adev_release;
+
+	ret = auxiliary_device_init(adev);
+	if (ret) {
+		kfree(adev);
+		return ERR_PTR(ret);
+	}
+
+	return adev;
+}
+
+static int ep93xx_controller_register(struct device *parent, const char *name,
+				      struct ep93xx_map_info *info)
+{
+	struct auxiliary_device *adev;
+	int ret;
+
+	adev = ep93xx_adev_alloc(parent, name, info);
+	if (IS_ERR(adev))
+		return PTR_ERR(adev);
+
+	ret = auxiliary_device_add(adev);
+	if (ret) {
+		auxiliary_device_uninit(adev);
+		return ret;
+	}
+
+	return devm_add_action_or_reset(parent, ep93xx_unregister_adev, adev);
+}
+
+static unsigned int __init ep93xx_soc_revision(struct regmap *map)
+{
+	unsigned int val;
+
+	regmap_read(map, EP93XX_SYSCON_SYSCFG, &val);
+	val &= EP93XX_SYSCON_SYSCFG_REV_MASK;
+	val >>= EP93XX_SYSCON_SYSCFG_REV_SHIFT;
+	return val;
+}
+
+static const char __init *ep93xx_get_soc_rev(struct regmap *map)
+{
+	switch (ep93xx_soc_revision(map)) {
+	case EP93XX_CHIP_REV_D0:
+		return "D0";
+	case EP93XX_CHIP_REV_D1:
+		return "D1";
+	case EP93XX_CHIP_REV_E0:
+		return "E0";
+	case EP93XX_CHIP_REV_E1:
+		return "E1";
+	case EP93XX_CHIP_REV_E2:
+		return "E2";
+	default:
+		return "unknown";
+	}
+}
+const char *pinctrl_names[] = {
+	"pinctrl-ep9301",	/* EP93XX_9301_SOC */
+	"pinctrl-ep9307",	/* EP93XX_9307_SOC */
+	"pinctrl-ep9312"	/* EP93XX_9312_SOC */
+};
+
+static int __init ep93xx_syscon_probe(struct platform_device *pdev)
+{
+	enum ep93xx_soc_model model = (int)of_device_get_match_data(&pdev->dev);
+	struct ep93xx_map_info *map_info;
+	struct soc_device_attribute *attrs;
+	struct soc_device *soc_dev;
+	struct device *dev = &pdev->dev;
+	struct regmap *map;
+	void __iomem *base;
+	int ret;
+
+	map = device_node_to_regmap(dev->of_node);
+	if (IS_ERR(map))
+		return PTR_ERR(map);
+
+	base = devm_platform_ioremap_resource(pdev, 0);
+	if (IS_ERR(base))
+		return PTR_ERR(base);
+
+	attrs = devm_kzalloc(dev, sizeof(*attrs), GFP_KERNEL);
+	if (!attrs)
+		return -ENOMEM;
+
+	attrs->machine = of_flat_dt_get_machine_name();
+	attrs->family = "Cirrus Logic EP93xx";
+	attrs->revision = ep93xx_get_soc_rev(map);
+
+	soc_dev = soc_device_register(attrs);
+	if (IS_ERR(soc_dev))
+		return PTR_ERR(soc_dev);
+
+	map_info = devm_kzalloc(dev, sizeof(*map_info), GFP_KERNEL);
+	if (!map_info)
+		return -ENOMEM;
+
+	spin_lock_init(&map_info->lock);
+	map_info->map = map;
+	map_info->base = base;
+
+	ret = ep93xx_controller_register(dev, pinctrl_names[model], map_info);
+	if (ret)
+		dev_err(dev, "registering pinctrl controller failed\n");
+
+	ret = ep93xx_controller_register(dev, "clk-ep93xx", map_info);
+	if (ret)
+		dev_err(dev, "registering clock controller failed\n");
+
+	ret = ep93xx_controller_register(dev, "reset-ep93xx", map_info);
+	if (ret)
+		dev_err(dev, "registering reset controller failed\n");
+
+	dev_info(dev, "EP93xx SoC revision %s\n", attrs->revision);
+
+	return 0;
+}
+
+static const struct of_device_id ep9301_syscon_of_device_ids[] = {
+	{ .compatible	= "cirrus,ep9301-syscon", .data = (void *)EP93XX_9301_SOC },
+	{ .compatible	= "cirrus,ep9302-syscon", .data = (void *)EP93XX_9301_SOC },
+	{ .compatible	= "cirrus,ep9307-syscon", .data = (void *)EP93XX_9307_SOC },
+	{ .compatible	= "cirrus,ep9312-syscon", .data = (void *)EP93XX_9312_SOC },
+	{ .compatible	= "cirrus,ep9315-syscon", .data = (void *)EP93XX_9312_SOC },
+	{ /* sentinel */ }
+};
+
+static struct platform_driver ep9301_syscon_driver = {
+	.driver = {
+		.name = "ep9301-syscon",
+		.of_match_table = ep9301_syscon_of_device_ids,
+	},
+};
+builtin_platform_driver_probe(ep9301_syscon_driver, ep93xx_syscon_probe);

-- 
2.41.0

