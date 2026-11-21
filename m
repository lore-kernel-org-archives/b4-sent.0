From: Yuugo Yoneda <yogo.0917.sabu@gmail.com>
Date: Sat, 21 Nov 2026 21:43:20 +0900
Subject: [PATCH RFC v2 10/13] mmc: sdhci-at550: add SiRF AT550
 programmed-I/O host driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261121-at550-rfc-v1-v2-10-b0309d0789b2@gmail.com>
References: <20261121-at550-rfc-v1-v2-0-b0309d0789b2@gmail.com>
In-Reply-To: <20261121-at550-rfc-v1-v2-0-b0309d0789b2@gmail.com>
To: linux-arm-kernel@lists.infradead.org, devicetree@vger.kernel.org
Cc: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Thomas Gleixner <tglx@kernel.org>, 
 Radu Rendec <radu@rendec.net>, Daniel Lezcano <daniel.lezcano@kernel.org>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>, Ulf Hansson <ulfh@kernel.org>, 
 Adrian Hunter <adrian.hunter@intel.com>, Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>, Russell King <linux@armlinux.org.uk>, 
 Arnd Bergmann <arnd@arndb.de>, 
 Alexandre Belloni <alexandre.belloni@bootlin.com>, 
 Linus Walleij <linusw@kernel.org>, Drew Fustini <fustini@kernel.org>, 
 linux-kernel@vger.kernel.org, linux-input@vger.kernel.org, 
 linux-mmc@vger.kernel.org, linux-doc@vger.kernel.org, soc@lists.linux.dev
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795264991; l=3700;
 i=yogo.0917.sabu@gmail.com; s=ypl514-20261117; h=from:subject:message-id;
 bh=lLUcutGX6X4e7Y1C/cRp2+SQBhJ32ubOSzrRcMWPbOc=;
 b=v8DAdauk7XLOkFUVJ5JH3CmGSOAkceaCiwFKutb1k7uQ9l4PY0RQREgAM4lgKeBksqHFm2+o7
 QP3rzsSg6sgDz6tj2AXVG7CNK+hfpsO5ZCqcczyCS2U96T5fAH0Z2di
X-Developer-Key: i=yogo.0917.sabu@gmail.com; a=ed25519;
 pk=TIQ8Tk4xQrxyn8rmk3GI2f5qg/kO6g2KZm7YOOyBHeg=
X-Endpoint-Received: by B4 Relay for yogo.0917.sabu@gmail.com/ypl514-20261117 with auth_id=1550
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a platform SDHCI host driver for the SiRF AT550 using programmed
I/O, as CPU-to-controller DMA address translation is not yet validated.

Use sdhci_pltfm_init() with default platform ops and
sdhci_pltfm_remove(), leaving bus width, clock limits, and
card-discovery constraints to the device tree.

Signed-off-by: Yuugo Yoneda <yogo.0917.sabu@gmail.com>
---
 MAINTAINERS                    |  1 +
 drivers/mmc/host/Kconfig       | 10 +++++++++
 drivers/mmc/host/Makefile      |  2 ++
 drivers/mmc/host/sdhci-at550.c | 51 ++++++++++++++++++++++++++++++++++++++++++
 4 files changed, 64 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index 1164152dc..9d02a79a2 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -25858,6 +25858,7 @@ F:	Documentation/devicetree/bindings/timer/sirf,at550-timer.yaml
 F:	drivers/clocksource/timer-at550.c
 F:	drivers/input/touchscreen/at550-ts.c
 F:	drivers/irqchip/irq-at550.c
+F:	drivers/mmc/host/sdhci-at550.c
 
 SIS 190 ETHERNET DRIVER
 M:	Francois Romieu <romieu@fr.zoreil.com>
diff --git a/drivers/mmc/host/Kconfig b/drivers/mmc/host/Kconfig
index 79bfc425e..72e7c279a 100644
--- a/drivers/mmc/host/Kconfig
+++ b/drivers/mmc/host/Kconfig
@@ -1125,3 +1125,13 @@ config MMC_LITEX
 	  module will be called litex_mmc.
 
 	  If unsure, say N.
+
+config MMC_SDHCI_AT550
+	tristate "SiRF AT550 SDHCI host"
+	depends on MMC_SDHCI_PLTFM && OF
+	help
+	  Say Y to enable the AT550 removable SD host using programmed I/O.
+	  Firmware must configure the peripheral clock and pin multiplexing.
+	  DMA address translation is not supported by this initial driver.
+	  Card discovery and bus frequency are configured by the device tree.
+	  To build as a module, choose M; it will be called sdhci-at550.
diff --git a/drivers/mmc/host/Makefile b/drivers/mmc/host/Makefile
index fd043afab..6f7b0dd14 100644
--- a/drivers/mmc/host/Makefile
+++ b/drivers/mmc/host/Makefile
@@ -115,3 +115,5 @@ endif
 
 obj-$(CONFIG_MMC_SDHCI_XENON)	+= sdhci-xenon-driver.o
 sdhci-xenon-driver-y		+= sdhci-xenon.o sdhci-xenon-phy.o
+
+obj-$(CONFIG_MMC_SDHCI_AT550) += sdhci-at550.o
diff --git a/drivers/mmc/host/sdhci-at550.c b/drivers/mmc/host/sdhci-at550.c
new file mode 100644
index 000000000..11c9de0c9
--- /dev/null
+++ b/drivers/mmc/host/sdhci-at550.c
@@ -0,0 +1,51 @@
+// SPDX-License-Identifier: GPL-2.0-only
+/* Standard SDHCI PIO only: do not assume CPU/PCI DMA address equivalence. */
+#include <linux/mmc/host.h>
+#include <linux/mod_devicetable.h>
+#include <linux/module.h>
+#include <linux/platform_device.h>
+
+#include "sdhci-pltfm.h"
+
+static const struct sdhci_pltfm_data at550_sdhci_data = {
+	.quirks = SDHCI_QUIRK_BROKEN_DMA | SDHCI_QUIRK_BROKEN_ADMA,
+	.quirks2 = SDHCI_QUIRK2_NO_1_8_V,
+};
+
+static int at550_sdhci_probe(struct platform_device *pdev)
+{
+	struct sdhci_host *host;
+	int ret;
+
+	host = sdhci_pltfm_init(pdev, &at550_sdhci_data, 0);
+	if (IS_ERR(host))
+		return PTR_ERR(host);
+
+	ret = mmc_of_parse(host->mmc);
+	if (ret)
+		return ret;
+
+	sdhci_get_property(pdev);
+
+	return sdhci_add_host(host);
+}
+
+static const struct of_device_id at550_sdhci_of_match[] = {
+	{ .compatible = "sirf,at550-sdhci" },
+	{ }
+};
+MODULE_DEVICE_TABLE(of, at550_sdhci_of_match);
+
+static struct platform_driver at550_sdhci_driver = {
+	.probe = at550_sdhci_probe,
+	.remove = sdhci_pltfm_remove,
+	.driver = {
+		.name = "sdhci-at550",
+		.of_match_table = at550_sdhci_of_match,
+		.pm = &sdhci_pltfm_pmops,
+	},
+};
+module_platform_driver(at550_sdhci_driver);
+
+MODULE_DESCRIPTION("SiRF AT550 SDHCI PIO host");
+MODULE_LICENSE("GPL");

-- 
2.56.0

