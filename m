From: Dang Huynh <dang.huynh@mainlining.org>
Date: Wed, 17 Sep 2025 03:25:12 +0700
Subject: [PATCH 15/25] power: reset: Add basic power reset driver for
 RDA8810PL
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250917-rda8810pl-drivers-v1-15-9ca9184ca977@mainlining.org>
References: <20250917-rda8810pl-drivers-v1-0-9ca9184ca977@mainlining.org>
In-Reply-To: <20250917-rda8810pl-drivers-v1-0-9ca9184ca977@mainlining.org>
To: Manivannan Sadhasivam <mani@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Linus Walleij <linus.walleij@linaro.org>, 
 Bartosz Golaszewski <brgl@bgdev.pl>, 
 Alexandre Belloni <alexandre.belloni@bootlin.com>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Philipp Zabel <p.zabel@pengutronix.de>, 
 Sebastian Reichel <sre@kernel.org>, Vinod Koul <vkoul@kernel.org>, 
 Kees Cook <kees@kernel.org>, "Gustavo A. R. Silva" <gustavoars@kernel.org>, 
 Ulf Hansson <ulf.hansson@linaro.org>
Cc: linux-arm-kernel@lists.infradead.org, linux-unisoc@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-gpio@vger.kernel.org, linux-rtc@vger.kernel.org, 
 linux-clk@vger.kernel.org, linux-pm@vger.kernel.org, 
 dmaengine@vger.kernel.org, linux-hardening@vger.kernel.org, 
 linux-mmc@vger.kernel.org, Dang Huynh <dang.huynh@mainlining.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1758054322; l=4260;
 i=dang.huynh@mainlining.org; s=20250917; h=from:subject:message-id;
 bh=HFlkcuGoP8mh0AtLbkenNjV8o+UREGJUxRrmMlpYY+8=;
 b=tDnwi027u0ZztdCHk9SEr/lKN0wXoeRqVTLuHk786MC7CkCmAPImsXjgN/ULbHg//6qHti8x6
 8cGQKoU4pBQCo0nPOwWFQeuoR0ZX1cppWJGWEFpFHKUyjOi/YBYx5Y2
X-Developer-Key: i=dang.huynh@mainlining.org; a=ed25519;
 pk=RyzH4CL4YU/ItXYUurA51EVBidfx4lIy8/E4EKRJCUk=
X-Endpoint-Received: by B4 Relay for dang.huynh@mainlining.org/20250917 with auth_id=526
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This basic driver can only reboot, powering off requires the modem
firmware which we don't have yet.

Signed-off-by: Dang Huynh <dang.huynh@mainlining.org>
---
 MAINTAINERS                      |  6 +++++
 drivers/power/reset/Kconfig      |  9 +++++++
 drivers/power/reset/Makefile     |  1 +
 drivers/power/reset/rda-reboot.c | 58 ++++++++++++++++++++++++++++++++++++++++
 4 files changed, 74 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index cbe2ab8af6dcd40dd1456d9df55673dace3c87b2..5ec24d8657bffb55c160947a930980e428c6a6b7 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -21399,6 +21399,12 @@ S:	Maintained
 F:	Documentation/devicetree/bindings/clock/rda,8810pl-apsyscon.yaml
 F:	drivers/clk/rda/clk-rda8810.c
 
+RDA MICRO MODEM RESET DRIVER
+M:	Dang Huynh <dang.huynh@mainlining.org>
+S:	Maintained
+F:	Documentation/devicetree/bindings/power/reset/rda,md-reset.yaml
+F:	drivers/power/reset/rda-reboot.c
+
 RDA MICRO REAL TIME CLOCK DRIVER
 M:	Dang Huynh <dang.huynh@mainlining.org>
 S:	Maintained
diff --git a/drivers/power/reset/Kconfig b/drivers/power/reset/Kconfig
index 77ea3129c70806929f3c248667db42f05f5f1d27..de9b1afb94d14a5d23286ddb302af4107d649c12 100644
--- a/drivers/power/reset/Kconfig
+++ b/drivers/power/reset/Kconfig
@@ -205,6 +205,15 @@ config POWER_RESET_QNAP
 
 	  Say Y if you have a QNAP NAS.
 
+config POWER_RESET_RDA
+	bool "RDA Micro Reset Driver"
+	depends on ARCH_RDA
+	help
+	  This driver supports soft resetting RDA Micro boards by writing
+	  magic values to the modem register.
+
+	  Say Y if you have a board with RDA Micro SoC.
+
 config POWER_RESET_REGULATOR
 	bool "Regulator subsystem power-off driver"
 	depends on OF && REGULATOR
diff --git a/drivers/power/reset/Makefile b/drivers/power/reset/Makefile
index b7c2b5940be9971548a5527384d1931abff11c4c..14371230410dad2852489160f4fc23d8fd087d6e 100644
--- a/drivers/power/reset/Makefile
+++ b/drivers/power/reset/Makefile
@@ -22,6 +22,7 @@ obj-$(CONFIG_POWER_RESET_ODROID_GO_ULTRA_POWEROFF) += odroid-go-ultra-poweroff.o
 obj-$(CONFIG_POWER_RESET_PIIX4_POWEROFF) += piix4-poweroff.o
 obj-$(CONFIG_POWER_RESET_LTC2952) += ltc2952-poweroff.o
 obj-$(CONFIG_POWER_RESET_QNAP) += qnap-poweroff.o
+obj-$(CONFIG_POWER_RESET_RDA) += rda-reboot.o
 obj-$(CONFIG_POWER_RESET_REGULATOR) += regulator-poweroff.o
 obj-$(CONFIG_POWER_RESET_RESTART) += restart-poweroff.o
 obj-$(CONFIG_POWER_RESET_ST) += st-poweroff.o
diff --git a/drivers/power/reset/rda-reboot.c b/drivers/power/reset/rda-reboot.c
new file mode 100644
index 0000000000000000000000000000000000000000..d87b063ba67d847f8e869e50a6c01427b2866889
--- /dev/null
+++ b/drivers/power/reset/rda-reboot.c
@@ -0,0 +1,58 @@
+// SPDX-License-Identifier: GPL-2.0-only
+/*
+ * Copyright (c) 2025, Dang Huynh <dang.huynh@mainlining.org>
+ *
+ * Based on drivers/power/reset/msm-poweroff.c:
+ * Copyright (c) 2013, The Linux Foundation. All rights reserved.
+ */
+
+#include <linux/err.h>
+#include <linux/init.h>
+#include <linux/kernel.h>
+#include <linux/io.h>
+#include <linux/of.h>
+#include <linux/platform_device.h>
+#include <linux/module.h>
+#include <linux/reboot.h>
+#include <linux/pm.h>
+#include <linux/mfd/syscon.h>
+
+static void __iomem *rda_md_sysctrl;
+
+static int do_rda_reboot(struct sys_off_data *data)
+{
+	/* unprotect md registers */
+	writel(0x00A50001, rda_md_sysctrl);
+
+	/* reset all */
+	writel(0x80000000, rda_md_sysctrl + 4);
+
+	return NOTIFY_DONE;
+}
+
+static int rda_reboot_probe(struct platform_device *pdev)
+{
+	rda_md_sysctrl = devm_platform_ioremap_resource(pdev, 0);
+	if (IS_ERR(rda_md_sysctrl))
+		return PTR_ERR(rda_md_sysctrl);
+
+	devm_register_sys_off_handler(&pdev->dev, SYS_OFF_MODE_RESTART,
+				      128, do_rda_reboot, NULL);
+
+	return 0;
+}
+
+static const struct of_device_id of_rda_reboot_match[] = {
+	{ .compatible = "rda,md-reset", },
+	{},
+};
+MODULE_DEVICE_TABLE(of, of_rda_reboot_match);
+
+static struct platform_driver rda_reboot_driver = {
+	.probe = rda_reboot_probe,
+	.driver = {
+		.name = "rda-reboot",
+		.of_match_table = of_match_ptr(of_rda_reboot_match),
+	},
+};
+builtin_platform_driver(rda_reboot_driver);

-- 
2.51.0

