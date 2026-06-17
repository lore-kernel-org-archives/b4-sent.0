From: Roman Vivchar <rva333@protonmail.com>
Date: Wed, 17 Jun 2026 12:48:45 +0300
Subject: [PATCH v2 2/4] nvmem: add mt6323 PMIC EFUSE driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260617-mt6323-nvmem-v2-2-4f30e36aa0f4@protonmail.com>
References: <20260617-mt6323-nvmem-v2-0-4f30e36aa0f4@protonmail.com>
In-Reply-To: <20260617-mt6323-nvmem-v2-0-4f30e36aa0f4@protonmail.com>
To: Sen Chu <sen.chu@mediatek.com>, Sean Wang <sean.wang@mediatek.com>, 
 Macpaul Lin <macpaul.lin@mediatek.com>, Lee Jones <lee@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Srinivas Kandagatla <srini@kernel.org>, 
 Roman Vivchar <rva333@protonmail.com>
Cc: Andy Shevchenko <andy@kernel.org>, linux-pm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-mediatek@lists.infradead.org, 
 Ben Grisdale <bengris32@protonmail.ch>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781689724; l=4979;
 i=rva333@protonmail.com; s=20260510; h=from:subject:message-id;
 bh=tkBAxojAoEByrsK5PQU5GP0ZOJ2PR63Ob95LjbJ70jA=;
 b=ex0wL7M4aG72M9OCkqFihMxqsMdY3sPNbDEXcgcKPUG9x6MkG4sA+j3oMM2sIHqYRuR6IEfFY
 2qCp+LoV7E+BV4lEBIO67gV6X4qsVtmhd3Q1h2hLgyPqmxZjvq8/IAW
X-Developer-Key: i=rva333@protonmail.com; a=ed25519;
 pk=zww/nWjBGoQ4POXCG0BV6fx2iuXK6jx77rsKPA5YK5Y=
X-Endpoint-Received: by B4 Relay for rva333@protonmail.com/20260510 with auth_id=777
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support for the EFUSE controller found in the Mediatek MT6323 PMIC.
The MT6323 EFUSE stores 24 bytes of hardware-related data, such as
thermal sensor calibration values.

Tested-by: Ben Grisdale <bengris32@protonmail.ch> # Amazon Echo Dot (2nd Generation)
Reviewed-by: Andy Shevchenko <andy@kernel.org>
Signed-off-by: Roman Vivchar <rva333@protonmail.com>
---
 MAINTAINERS                  |  5 +++
 drivers/nvmem/Kconfig        | 11 ++++++
 drivers/nvmem/Makefile       |  2 ++
 drivers/nvmem/mt6323-efuse.c | 85 ++++++++++++++++++++++++++++++++++++++++++++
 4 files changed, 103 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index d1cc0e12fe1f..910360f148c4 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -16256,6 +16256,11 @@ S:	Maintained
 F:	Documentation/devicetree/bindings/mmc/mtk-sd.yaml
 F:	drivers/mmc/host/mtk-sd.c
 
+MEDIATEK MT6323 PMIC NVMEM DRIVER
+M:	Roman Vivchar <rva333@protonmail.com>
+S:	Maintained
+F:	drivers/nvmem/mt6323-efuse.c
+
 MEDIATEK MT6735 CLOCK & RESET DRIVERS
 M:	Yassine Oudjana <y.oudjana@protonmail.com>
 L:	linux-clk@vger.kernel.org
diff --git a/drivers/nvmem/Kconfig b/drivers/nvmem/Kconfig
index 74ddbd0f79b0..db248a3c4e87 100644
--- a/drivers/nvmem/Kconfig
+++ b/drivers/nvmem/Kconfig
@@ -227,6 +227,17 @@ config NVMEM_MTK_EFUSE
 	  This driver can also be built as a module. If so, the module
 	  will be called efuse-mtk.
 
+config NVMEM_MT6323_EFUSE
+	tristate "Mediatek MT6323 PMIC EFUSE support"
+	depends on ARCH_MEDIATEK || COMPILE_TEST
+	depends on MFD_MT6397
+	help
+	  This is a driver to access hardware related data like sensor
+	  calibration, etc.
+
+	  This driver can also be built as a module. If so, the module
+	  will be called efuse-mt6323.
+
 config NVMEM_MXS_OCOTP
 	tristate "Freescale MXS On-Chip OTP Memory Support"
 	depends on ARCH_MXS || COMPILE_TEST
diff --git a/drivers/nvmem/Makefile b/drivers/nvmem/Makefile
index 7252b8ec88d4..0e2b73f42b25 100644
--- a/drivers/nvmem/Makefile
+++ b/drivers/nvmem/Makefile
@@ -48,6 +48,8 @@ obj-$(CONFIG_NVMEM_MICROCHIP_OTPC)	+= nvmem-microchip-otpc.o
 nvmem-microchip-otpc-y			:= microchip-otpc.o
 obj-$(CONFIG_NVMEM_MTK_EFUSE)		+= nvmem_mtk-efuse.o
 nvmem_mtk-efuse-y			:= mtk-efuse.o
+obj-$(CONFIG_NVMEM_MT6323_EFUSE)		+= nvmem_mt6323-efuse.o
+nvmem_mt6323-efuse-y			:= mt6323-efuse.o
 obj-$(CONFIG_NVMEM_MXS_OCOTP)		+= nvmem-mxs-ocotp.o
 nvmem-mxs-ocotp-y			:= mxs-ocotp.o
 obj-$(CONFIG_NVMEM_NINTENDO_OTP)	+= nvmem-nintendo-otp.o
diff --git a/drivers/nvmem/mt6323-efuse.c b/drivers/nvmem/mt6323-efuse.c
new file mode 100644
index 000000000000..7a0ce4c7f565
--- /dev/null
+++ b/drivers/nvmem/mt6323-efuse.c
@@ -0,0 +1,85 @@
+// SPDX-License-Identifier: GPL-2.0+
+/*
+ * Copyright (c) 2026 Roman Vivchar <rva333@protonmail.com>
+ */
+
+#include <linux/err.h>
+#include <linux/mod_devicetable.h>
+#include <linux/module.h>
+#include <linux/nvmem-provider.h>
+#include <linux/platform_device.h>
+#include <linux/regmap.h>
+#include <linux/types.h>
+
+#include <linux/mfd/mt6323/registers.h>
+
+#define MT6323_EFUSE_DOUT_BASE	MT6323_EFUSE_DOUT_0_15
+#define MT6323_EFUSE_SIZE	24
+
+static int mt6323_efuse_read(void *context, unsigned int offset, void *val,
+			     size_t bytes)
+{
+	struct regmap *map = context;
+	u16 *buf = val;
+	u32 tmp;
+	int ret;
+
+	/*
+	 * A manual loop using regmap_read is required because PWRAP is not
+	 * a continuous MMIO space, but rather a FSM that doesn't implement the
+	 * necessary read callback for the regmap_read_raw and regmap_read_bulk
+	 * functions.
+	 */
+	for (size_t i = 0; i < bytes; i += sizeof(*buf)) {
+		ret = regmap_read(map, MT6323_EFUSE_DOUT_BASE + offset + i, &tmp);
+		if (ret)
+			return ret;
+
+		*buf++ = tmp;
+	}
+
+	return 0;
+}
+
+static int mt6323_efuse_probe(struct platform_device *pdev)
+{
+	struct device *dev = &pdev->dev;
+	struct nvmem_config config = {
+		.name = "mt6323-efuse",
+		.stride = 2,
+		.word_size = 2,
+		.size = MT6323_EFUSE_SIZE,
+		.reg_read = mt6323_efuse_read,
+	};
+	struct nvmem_device *nvmem;
+	struct regmap *regmap;
+
+	/* efuse -> mfd -> pwrap */
+	regmap = dev_get_regmap(dev->parent->parent, NULL);
+	if (!regmap)
+		return dev_err_probe(dev, -ENODEV, "failed to get regmap\n");
+
+	config.dev = dev;
+	config.priv = regmap;
+
+	nvmem = devm_nvmem_register(dev, &config);
+	return PTR_ERR_OR_ZERO(nvmem);
+}
+
+static const struct of_device_id mt6323_efuse_of_match[] = {
+	{ .compatible = "mediatek,mt6323-efuse" },
+	{ }
+};
+MODULE_DEVICE_TABLE(of, mt6323_efuse_of_match);
+
+static struct platform_driver mt6323_efuse_driver = {
+	.probe = mt6323_efuse_probe,
+	.driver = {
+		.name = "mt6323-efuse",
+		.of_match_table = mt6323_efuse_of_match,
+	},
+};
+module_platform_driver(mt6323_efuse_driver);
+
+MODULE_DESCRIPTION("MediaTek MT6323 PMIC EFUSE driver");
+MODULE_LICENSE("GPL");

-- 
2.54.0

