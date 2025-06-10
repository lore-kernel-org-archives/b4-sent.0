From: Sven Peter <sven@kernel.org>
Date: Tue, 10 Jun 2025 15:29:48 +0000
Subject: [PATCH v7 07/10] power: reset: macsmc-reboot: Add driver for
 rebooting via Apple SMC
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250610-smc-6-15-v7-7-556cafd771d3@kernel.org>
References: <20250610-smc-6-15-v7-0-556cafd771d3@kernel.org>
In-Reply-To: <20250610-smc-6-15-v7-0-556cafd771d3@kernel.org>
To: Sven Peter <sven@kernel.org>, Janne Grunau <j@jannau.net>, 
 Alyssa Rosenzweig <alyssa@rosenzweig.io>, Neal Gompa <neal@gompa.dev>, 
 Hector Martin <marcan@marcan.st>, Linus Walleij <linus.walleij@linaro.org>, 
 Bartosz Golaszewski <brgl@bgdev.pl>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Sebastian Reichel <sre@kernel.org>, 
 Lee Jones <lee@kernel.org>, Marc Zyngier <maz@kernel.org>, 
 "Russell King (Oracle)" <rmk+kernel@armlinux.org.uk>
Cc: asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 linux-gpio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-pm@vger.kernel.org, 
 Sebastian Reichel <sebastian.reichel@collabora.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=11424; i=sven@kernel.org;
 h=from:subject:message-id; bh=Pph3bVuy3ad/rZIuRUzym6r/zApadkRqVHhHAKz+yZs=;
 b=owGbwMvMwCHmIlirolUq95LxtFoSQ4aHf8XaiVZ3U740fw2T/13zvst5j+TiJskmizvVMlVvd
 /htE1/SUcrCIMbBICumyLJ9v73pk4dvBJduuvQeZg4rE8gQBi5OAZiISjHDf69XSTvEEkXbHj5r
 r5ikctGyJpQ1I5axr3SrwxXmnw5VSYwMTxz5o34q79nKsKWTuYZhtznv5Ir0svkWbfd5elW7r5b
 yAAA=
X-Developer-Key: i=sven@kernel.org; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@kernel.org/default with auth_id=407
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Hector Martin <marcan@marcan.st>

This driver implements the reboot/shutdown support exposed by the SMC
on Apple Silicon machines, such as Apple M1 Macs.

Signed-off-by: Hector Martin <marcan@marcan.st>
Reviewed-by: Alyssa Rosenzweig <alyssa@rosenzweig.io>
Reviewed-by: Neal Gompa <neal@gompa.dev>
Reviewed-by: Sebastian Reichel <sebastian.reichel@collabora.com>
Signed-off-by: Sven Peter <sven@kernel.org>
---
 MAINTAINERS                         |   1 +
 drivers/power/reset/Kconfig         |   9 ++
 drivers/power/reset/Makefile        |   1 +
 drivers/power/reset/macsmc-reboot.c | 290 ++++++++++++++++++++++++++++++++++++
 4 files changed, 301 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index 4c1977d0af7c99aaef38a89e5d7eb32f42c4565f..9a3f273c557fbb24fe8b6f77d9df3c026b898e7a 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -2370,6 +2370,7 @@ F:	drivers/nvme/host/apple.c
 F:	drivers/nvmem/apple-efuses.c
 F:	drivers/nvmem/apple-spmi-nvmem.c
 F:	drivers/pinctrl/pinctrl-apple-gpio.c
+F:	drivers/power/reset/macsmc-reboot.c
 F:	drivers/pwm/pwm-apple.c
 F:	drivers/soc/apple/*
 F:	drivers/spi/spi-apple.c
diff --git a/drivers/power/reset/Kconfig b/drivers/power/reset/Kconfig
index e71f0af4e378c1d0e5a73bdf0b52262976fff190..733d812621599dadffb8303b6b95150c228f6426 100644
--- a/drivers/power/reset/Kconfig
+++ b/drivers/power/reset/Kconfig
@@ -128,6 +128,15 @@ config POWER_RESET_LINKSTATION
 
 	  Say Y here if you have a Buffalo LinkStation LS421D/E.
 
+config POWER_RESET_MACSMC
+	tristate "Apple SMC reset/power-off driver"
+	depends on MFD_MACSMC
+	help
+	  This driver supports reset and power-off on Apple Mac machines
+	  that implement this functionality via the SMC.
+
+	  Say Y here if you have an Apple Silicon Mac.
+
 config POWER_RESET_MSM
 	bool "Qualcomm MSM power-off driver"
 	depends on ARCH_QCOM
diff --git a/drivers/power/reset/Makefile b/drivers/power/reset/Makefile
index 1b9b63a1a8731b765c0010e02543083dd184ee6c..b7c2b5940be9971548a5527384d1931abff11c4c 100644
--- a/drivers/power/reset/Makefile
+++ b/drivers/power/reset/Makefile
@@ -13,6 +13,7 @@ obj-$(CONFIG_POWER_RESET_GPIO) += gpio-poweroff.o
 obj-$(CONFIG_POWER_RESET_GPIO_RESTART) += gpio-restart.o
 obj-$(CONFIG_POWER_RESET_HISI) += hisi-reboot.o
 obj-$(CONFIG_POWER_RESET_LINKSTATION) += linkstation-poweroff.o
+obj-$(CONFIG_POWER_RESET_MACSMC) += macsmc-reboot.o
 obj-$(CONFIG_POWER_RESET_MSM) += msm-poweroff.o
 obj-$(CONFIG_POWER_RESET_MT6323) += mt6323-poweroff.o
 obj-$(CONFIG_POWER_RESET_QCOM_PON) += qcom-pon.o
diff --git a/drivers/power/reset/macsmc-reboot.c b/drivers/power/reset/macsmc-reboot.c
new file mode 100644
index 0000000000000000000000000000000000000000..e9702acdd366b053ce7a032bb09f636ac5c02444
--- /dev/null
+++ b/drivers/power/reset/macsmc-reboot.c
@@ -0,0 +1,290 @@
+// SPDX-License-Identifier: GPL-2.0-only OR MIT
+/*
+ * Apple SMC Reboot/Poweroff Handler
+ * Copyright The Asahi Linux Contributors
+ */
+
+#include <linux/delay.h>
+#include <linux/mfd/core.h>
+#include <linux/mfd/macsmc.h>
+#include <linux/mod_devicetable.h>
+#include <linux/module.h>
+#include <linux/nvmem-consumer.h>
+#include <linux/platform_device.h>
+#include <linux/reboot.h>
+#include <linux/slab.h>
+
+struct macsmc_reboot_nvmem {
+	struct nvmem_cell *shutdown_flag;
+	struct nvmem_cell *boot_stage;
+	struct nvmem_cell *boot_error_count;
+	struct nvmem_cell *panic_count;
+};
+
+static const char * const nvmem_names[] = {
+	"shutdown_flag",
+	"boot_stage",
+	"boot_error_count",
+	"panic_count",
+};
+
+enum boot_stage {
+	BOOT_STAGE_SHUTDOWN		= 0x00, /* Clean shutdown */
+	BOOT_STAGE_IBOOT_DONE		= 0x2f, /* Last stage of bootloader */
+	BOOT_STAGE_KERNEL_STARTED	= 0x30, /* Normal OS booting */
+};
+
+struct macsmc_reboot {
+	struct device *dev;
+	struct apple_smc *smc;
+	struct notifier_block reboot_notify;
+
+	union {
+		struct macsmc_reboot_nvmem nvm;
+		struct nvmem_cell *nvm_cells[ARRAY_SIZE(nvmem_names)];
+	};
+};
+
+/* Helpers to read/write a u8 given a struct nvmem_cell */
+static int nvmem_cell_get_u8(struct nvmem_cell *cell)
+{
+	size_t len;
+	void *bfr;
+	u8 val;
+
+	bfr = nvmem_cell_read(cell, &len);
+	if (IS_ERR(bfr))
+		return PTR_ERR(bfr);
+
+	if (len < 1) {
+		kfree(bfr);
+		return -EINVAL;
+	}
+
+	val = *(u8 *)bfr;
+	kfree(bfr);
+	return val;
+}
+
+static int nvmem_cell_set_u8(struct nvmem_cell *cell, u8 val)
+{
+	return nvmem_cell_write(cell, &val, sizeof(val));
+}
+
+/*
+ * SMC 'MBSE' key actions:
+ *
+ * 'offw' - shutdown warning
+ * 'slpw' - sleep warning
+ * 'rest' - restart warning
+ * 'off1' - shutdown (needs PMU bit set to stay on)
+ * 'susp' - suspend
+ * 'phra' - restart ("PE Halt Restart Action"?)
+ * 'panb' - panic beginning
+ * 'pane' - panic end
+ */
+
+static int macsmc_prepare_atomic(struct sys_off_data *data)
+{
+	struct macsmc_reboot *reboot = data->cb_data;
+
+	dev_info(reboot->dev, "Preparing SMC for atomic mode\n");
+
+	apple_smc_enter_atomic(reboot->smc);
+	return NOTIFY_OK;
+}
+
+static int macsmc_power_off(struct sys_off_data *data)
+{
+	struct macsmc_reboot *reboot = data->cb_data;
+
+	dev_info(reboot->dev, "Issuing power off (off1)\n");
+
+	if (apple_smc_write_u32_atomic(reboot->smc, SMC_KEY(MBSE), SMC_KEY(off1)) < 0) {
+		dev_err(reboot->dev, "Failed to issue MBSE = off1 (power_off)\n");
+	} else {
+		mdelay(100);
+		WARN_ONCE(1, "Unable to power off system\n");
+	}
+
+	return NOTIFY_OK;
+}
+
+static int macsmc_restart(struct sys_off_data *data)
+{
+	struct macsmc_reboot *reboot = data->cb_data;
+
+	dev_info(reboot->dev, "Issuing restart (phra)\n");
+
+	if (apple_smc_write_u32_atomic(reboot->smc, SMC_KEY(MBSE), SMC_KEY(phra)) < 0) {
+		dev_err(reboot->dev, "Failed to issue MBSE = phra (restart)\n");
+	} else {
+		mdelay(100);
+		WARN_ONCE(1, "Unable to restart system\n");
+	}
+
+	return NOTIFY_OK;
+}
+
+static int macsmc_reboot_notify(struct notifier_block *this, unsigned long action, void *data)
+{
+	struct macsmc_reboot *reboot = container_of(this, struct macsmc_reboot, reboot_notify);
+	u8 shutdown_flag;
+	u32 val;
+
+	switch (action) {
+	case SYS_RESTART:
+		val = SMC_KEY(rest);
+		shutdown_flag = 0;
+		break;
+	case SYS_POWER_OFF:
+		val = SMC_KEY(offw);
+		shutdown_flag = 1;
+		break;
+	default:
+		return NOTIFY_DONE;
+	}
+
+	dev_info(reboot->dev, "Preparing for reboot (%p4ch)\n", &val);
+
+	/* On the Mac Mini, this will turn off the LED for power off */
+	if (apple_smc_write_u32(reboot->smc, SMC_KEY(MBSE), val) < 0)
+		dev_err(reboot->dev, "Failed to issue MBSE = %p4ch (reboot_prepare)\n", &val);
+
+	/* Set the boot_stage to 0, which means we're doing a clean shutdown/reboot. */
+	if (reboot->nvm.boot_stage &&
+	    nvmem_cell_set_u8(reboot->nvm.boot_stage, BOOT_STAGE_SHUTDOWN) < 0)
+		dev_err(reboot->dev, "Failed to write boot_stage\n");
+
+	/*
+	 * Set the PMU flag to actually reboot into the off state.
+	 * Without this, the device will just reboot. We make it optional in case it is no longer
+	 * necessary on newer hardware.
+	 */
+	if (reboot->nvm.shutdown_flag &&
+	    nvmem_cell_set_u8(reboot->nvm.shutdown_flag, shutdown_flag) < 0)
+		dev_err(reboot->dev, "Failed to write shutdown_flag\n");
+
+	return NOTIFY_OK;
+}
+
+static void macsmc_power_init_error_counts(struct macsmc_reboot *reboot)
+{
+	int boot_error_count, panic_count;
+
+	if (!reboot->nvm.boot_error_count || !reboot->nvm.panic_count)
+		return;
+
+	boot_error_count = nvmem_cell_get_u8(reboot->nvm.boot_error_count);
+	if (boot_error_count < 0) {
+		dev_err(reboot->dev, "Failed to read boot_error_count (%d)\n", boot_error_count);
+		return;
+	}
+
+	panic_count = nvmem_cell_get_u8(reboot->nvm.panic_count);
+	if (panic_count < 0) {
+		dev_err(reboot->dev, "Failed to read panic_count (%d)\n", panic_count);
+		return;
+	}
+
+	if (!boot_error_count && !panic_count)
+		return;
+
+	dev_warn(reboot->dev, "PMU logged %d boot error(s) and %d panic(s)\n",
+		 boot_error_count, panic_count);
+
+	if (nvmem_cell_set_u8(reboot->nvm.panic_count, 0) < 0)
+		dev_err(reboot->dev, "Failed to reset panic_count\n");
+	if (nvmem_cell_set_u8(reboot->nvm.boot_error_count, 0) < 0)
+		dev_err(reboot->dev, "Failed to reset boot_error_count\n");
+}
+
+static int macsmc_reboot_probe(struct platform_device *pdev)
+{
+	struct apple_smc *smc = dev_get_drvdata(pdev->dev.parent);
+	struct macsmc_reboot *reboot;
+	int ret, i;
+
+	reboot = devm_kzalloc(&pdev->dev, sizeof(*reboot), GFP_KERNEL);
+	if (!reboot)
+		return -ENOMEM;
+
+	reboot->dev = &pdev->dev;
+	reboot->smc = smc;
+
+	platform_set_drvdata(pdev, reboot);
+
+	for (i = 0; i < ARRAY_SIZE(nvmem_names); i++) {
+		struct nvmem_cell *cell;
+
+		cell = devm_nvmem_cell_get(&pdev->dev,
+					   nvmem_names[i]);
+		if (IS_ERR(cell)) {
+			if (PTR_ERR(cell) == -EPROBE_DEFER)
+				return -EPROBE_DEFER;
+			dev_warn(&pdev->dev, "Missing NVMEM cell %s (%ld)\n",
+				 nvmem_names[i], PTR_ERR(cell));
+			/* Non fatal, we'll deal with it */
+			cell = NULL;
+		}
+		reboot->nvm_cells[i] = cell;
+	}
+
+	/* Set the boot_stage to indicate we're running the OS kernel */
+	if (reboot->nvm.boot_stage &&
+	    nvmem_cell_set_u8(reboot->nvm.boot_stage, BOOT_STAGE_KERNEL_STARTED) < 0)
+		dev_err(reboot->dev, "Failed to write boot_stage\n");
+
+	/* Display and clear the error counts */
+	macsmc_power_init_error_counts(reboot);
+
+	reboot->reboot_notify.notifier_call = macsmc_reboot_notify;
+
+	ret = devm_register_sys_off_handler(&pdev->dev, SYS_OFF_MODE_POWER_OFF_PREPARE,
+					    SYS_OFF_PRIO_HIGH, macsmc_prepare_atomic, reboot);
+	if (ret)
+		return dev_err_probe(&pdev->dev, ret,
+				     "Failed to register power-off prepare handler\n");
+	ret = devm_register_sys_off_handler(&pdev->dev, SYS_OFF_MODE_POWER_OFF, SYS_OFF_PRIO_HIGH,
+					    macsmc_power_off, reboot);
+	if (ret)
+		return dev_err_probe(&pdev->dev, ret,
+				     "Failed to register power-off handler\n");
+
+	ret = devm_register_sys_off_handler(&pdev->dev, SYS_OFF_MODE_RESTART_PREPARE,
+					    SYS_OFF_PRIO_HIGH, macsmc_prepare_atomic, reboot);
+	if (ret)
+		return dev_err_probe(&pdev->dev, ret,
+				     "Failed to register restart prepare handler\n");
+	ret = devm_register_sys_off_handler(&pdev->dev, SYS_OFF_MODE_RESTART, SYS_OFF_PRIO_HIGH,
+					    macsmc_restart, reboot);
+	if (ret)
+		return dev_err_probe(&pdev->dev, ret, "Failed to register restart handler\n");
+
+	ret = devm_register_reboot_notifier(&pdev->dev, &reboot->reboot_notify);
+	if (ret)
+		return dev_err_probe(&pdev->dev, ret, "Failed to register reboot notifier\n");
+
+	dev_info(&pdev->dev, "Handling reboot and poweroff requests via SMC\n");
+
+	return 0;
+}
+
+static const struct of_device_id macsmc_reboot_of_table[] = {
+	{ .compatible = "apple,smc-reboot", },
+	{}
+};
+MODULE_DEVICE_TABLE(of, macsmc_reboot_of_table);
+
+static struct platform_driver macsmc_reboot_driver = {
+	.driver = {
+		.name = "macsmc-reboot",
+		.of_match_table = macsmc_reboot_of_table,
+	},
+	.probe = macsmc_reboot_probe,
+};
+module_platform_driver(macsmc_reboot_driver);
+
+MODULE_LICENSE("Dual MIT/GPL");
+MODULE_DESCRIPTION("Apple SMC reboot/poweroff driver");
+MODULE_AUTHOR("Hector Martin <marcan@marcan.st>");

-- 
2.34.1

