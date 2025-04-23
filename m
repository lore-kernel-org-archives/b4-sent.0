From: Sasha Finkelstein <fnkl.kernel@gmail.com>
Date: Wed, 23 Apr 2025 19:55:14 +0200
Subject: [PATCH v3 2/3] nvmem: Add apple-spmi-nvmem driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250423-spmi-nvmem-v3-2-2985aa722ddc@gmail.com>
References: <20250423-spmi-nvmem-v3-0-2985aa722ddc@gmail.com>
In-Reply-To: <20250423-spmi-nvmem-v3-0-2985aa722ddc@gmail.com>
To: Sven Peter <sven@svenpeter.dev>, Janne Grunau <j@jannau.net>, 
 Alyssa Rosenzweig <alyssa@rosenzweig.io>, Neal Gompa <neal@gompa.dev>, 
 Srinivas Kandagatla <srinivas.kandagatla@linaro.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Sasha Finkelstein <fnkl.kernel@gmail.com>, Hector Martin <marcan@marcan.st>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1745430928; l=4524;
 i=fnkl.kernel@gmail.com; s=20241124; h=from:subject:message-id;
 bh=E0YgVY1kIyVeZiBL29ovgAQLgKsalQU9HAAOahuulyE=;
 b=Tw30Fla+GgRpLdqYeL9wnOiZbN1TCxK6IbF+3fR4dTb6FPo9nn33vTQQplSMNy7iXthYDT0TZ
 1GidhyhO98QDClW2fzV4wid0Y6gG9uVUPvR4soMhNW0KLz1EhJgTTwA
X-Developer-Key: i=fnkl.kernel@gmail.com; a=ed25519;
 pk=aSkp1PdZ+eF4jpMO6oLvz/YfT5XkBUneWwyhQrOgmsU=
X-Endpoint-Received: by B4 Relay for fnkl.kernel@gmail.com/20241124 with auth_id=283
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Hector Martin <marcan@marcan.st>

Add a driver for a series of SPMI-attached PMICs present on Apple devices

Reviewed-by: Neal Gompa <neal@gompa.dev>
Reviewed-by: Alyssa Rosenzweig <alyssa@rosenzweig.io>
Signed-off-by: Hector Martin <marcan@marcan.st>
Co-developed-by: Sasha Finkelstein <fnkl.kernel@gmail.com>
Signed-off-by: Sasha Finkelstein <fnkl.kernel@gmail.com>
---
 MAINTAINERS                      |  1 +
 drivers/nvmem/Kconfig            | 13 +++++++++
 drivers/nvmem/Makefile           |  2 ++
 drivers/nvmem/apple-spmi-nvmem.c | 62 ++++++++++++++++++++++++++++++++++++++++
 4 files changed, 78 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index f462545c54c55d4bdc22651e07a4c8e155e83016..c9f5ac1eb2458a0206ffe0767cc6ed129172e78f 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -2298,6 +2298,7 @@ F:	drivers/iommu/io-pgtable-dart.c
 F:	drivers/irqchip/irq-apple-aic.c
 F:	drivers/nvme/host/apple.c
 F:	drivers/nvmem/apple-efuses.c
+F:	drivers/nvmem/apple-spmi-nvmem.c
 F:	drivers/pinctrl/pinctrl-apple-gpio.c
 F:	drivers/pwm/pwm-apple.c
 F:	drivers/soc/apple/*
diff --git a/drivers/nvmem/Kconfig b/drivers/nvmem/Kconfig
index 8671b7c974b933e147154bb40b5d41b5730518d2..ae4afbd8293c64ea0a3a632c7172f5496545b12c 100644
--- a/drivers/nvmem/Kconfig
+++ b/drivers/nvmem/Kconfig
@@ -40,6 +40,19 @@ config NVMEM_APPLE_EFUSES
 	  This driver can also be built as a module. If so, the module will
 	  be called nvmem-apple-efuses.
 
+config NVMEM_APPLE_SPMI
+	tristate "Apple SPMI NVMEM"
+	depends on ARCH_APPLE || COMPILE_TEST
+	depends on SPMI
+	select REGMAP_SPMI
+	help
+	  Say y here to build a driver to expose NVMEM cells for a set of power
+	  and RTC-related settings on a SPMI-attached PMIC present on Apple
+	  devices, such as Apple Silicon Macs.
+
+	  This driver can also be built as a module. If so, the module
+	  will be called apple-nvmem-spmi.
+
 config NVMEM_BCM_OCOTP
 	tristate "Broadcom On-Chip OTP Controller support"
 	depends on ARCH_BCM_IPROC || COMPILE_TEST
diff --git a/drivers/nvmem/Makefile b/drivers/nvmem/Makefile
index 5b77bbb6488bf89bfb305750a1cbf4a6731a0a58..89a3c252c2c8dad9ed7bc6ac9841f63ff85c00d5 100644
--- a/drivers/nvmem/Makefile
+++ b/drivers/nvmem/Makefile
@@ -12,6 +12,8 @@ obj-y				+= layouts/
 # Devices
 obj-$(CONFIG_NVMEM_APPLE_EFUSES)	+= nvmem-apple-efuses.o
 nvmem-apple-efuses-y 			:= apple-efuses.o
+obj-$(CONFIG_NVMEM_APPLE_SPMI)		+= apple_nvmem_spmi.o
+apple_nvmem_spmi-y			:= apple-spmi-nvmem.o
 obj-$(CONFIG_NVMEM_BCM_OCOTP)		+= nvmem-bcm-ocotp.o
 nvmem-bcm-ocotp-y			:= bcm-ocotp.o
 obj-$(CONFIG_NVMEM_BRCM_NVRAM)		+= nvmem_brcm_nvram.o
diff --git a/drivers/nvmem/apple-spmi-nvmem.c b/drivers/nvmem/apple-spmi-nvmem.c
new file mode 100644
index 0000000000000000000000000000000000000000..88614005d5ce1dc2d1cafcb89ac66d8376ffcc96
--- /dev/null
+++ b/drivers/nvmem/apple-spmi-nvmem.c
@@ -0,0 +1,62 @@
+// SPDX-License-Identifier: GPL-2.0-only OR MIT
+/*
+ * Apple SPMI NVMEM driver
+ *
+ * Copyright The Asahi Linux Contributors
+ */
+
+#include <linux/kernel.h>
+#include <linux/module.h>
+#include <linux/nvmem-provider.h>
+#include <linux/of.h>
+#include <linux/spmi.h>
+#include <linux/regmap.h>
+
+static const struct regmap_config apple_spmi_regmap_config = {
+	.reg_bits	= 16,
+	.val_bits	= 8,
+	.max_register	= 0xffff,
+};
+
+static int apple_spmi_nvmem_probe(struct spmi_device *sdev)
+{
+	struct regmap *regmap;
+	struct nvmem_config nvmem_cfg = {
+		.dev = &sdev->dev,
+		.name = "spmi_nvmem",
+		.id = NVMEM_DEVID_AUTO,
+		.word_size = 1,
+		.stride = 1,
+		.size = 0xffff,
+		.reg_read = (void *)regmap_bulk_read,
+		.reg_write = (void *)regmap_bulk_write,
+	};
+
+	regmap = devm_regmap_init_spmi_ext(sdev, &apple_spmi_regmap_config);
+	if (IS_ERR(regmap))
+		return PTR_ERR(regmap);
+
+	nvmem_cfg.priv = regmap;
+
+	return PTR_ERR_OR_ZERO(devm_nvmem_register(&sdev->dev, &nvmem_cfg));
+}
+
+static const struct of_device_id apple_spmi_nvmem_id_table[] = {
+	{ .compatible = "apple,spmi-nvmem" },
+	{ },
+};
+MODULE_DEVICE_TABLE(of, apple_spmi_nvmem_id_table);
+
+static struct spmi_driver apple_spmi_nvmem_driver = {
+	.probe = apple_spmi_nvmem_probe,
+	.driver = {
+		.name = "apple-spmi-nvmem",
+		.of_match_table	= apple_spmi_nvmem_id_table,
+	},
+};
+
+module_spmi_driver(apple_spmi_nvmem_driver);
+
+MODULE_LICENSE("Dual MIT/GPL");
+MODULE_AUTHOR("Hector Martin <marcan@marcan.st>");
+MODULE_DESCRIPTION("Apple SPMI NVMEM driver");

-- 
2.49.0

