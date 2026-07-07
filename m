From: Miao Wang <shankerwangmiao@gmail.com>
Date: Wed, 08 Jul 2026 05:16:31 +0800
Subject: [PATCH RFC v2 7/7] mfd: ls2kbmc: Capture the reset event of BMC
 through GPIO
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260708-ls2kbmc-mod-v2-7-2afdd1741766@gmail.com>
References: <20260708-ls2kbmc-mod-v2-0-2afdd1741766@gmail.com>
In-Reply-To: <20260708-ls2kbmc-mod-v2-0-2afdd1741766@gmail.com>
To: Binbin Zhou <zhoubinbin@loongson.cn>, 
 Chong Qiao <qiaochong@loongson.cn>, Lee Jones <lee@kernel.org>, 
 Huacai Chen <chenhuacai@kernel.org>, Corey Minyard <corey@minyard.net>, 
 Linus Walleij <linusw@kernel.org>, Bartosz Golaszewski <brgl@kernel.org>
Cc: Xi Ruoyao <xry111@xry111.site>, WANG Xuerui <kernel@xen0n.name>, 
 Yinbo Zhu <zhuyinbo@loongson.cn>, Jiaxun Yang <jiaxun.yang@flygoat.com>, 
 mfd@lists.linux.dev, linux-kernel@vger.kernel.org, 
 linux-gpio@vger.kernel.org, openipmi-developer@lists.sourceforge.net, 
 Miao Wang <shankerwangmiao@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=8673;
 i=shankerwangmiao@gmail.com; s=20250715; h=from:subject:message-id;
 bh=2IJJRz2d8DgY3uiccKWKVOZwC9ehklvxyPgs1XhNrv0=;
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBqTWy2lqzUrkjnKfUuCEqFKy2EVYSDPhViKkzHO
 NnUIqVofE2JAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCak1stgAKCRCwMePKe/7Z
 bjZMD/9WeBCrfl6Ka9VOGa0Y57xfy/Ut7343qJB//6Dh9fFtHBMqe9UbfGPUiTAVmOT7YuPeSoK
 FfybhY6GKSeiH5IHVMXqt+1B4boIe4TVmd0mVPINTH4N+guzlnVyLGO3g4tHmGPNZ52pm/Cq+VL
 g+BcR2UGXjqiYBGaxXeyXahECD5a4HUnHyorps9jH3u3Bn6rXSmoVEYoMpZCqDbBKGyf/OMVE7I
 1LoSxQV3icOkHENbRqRjTf8YQOirJfuPtJl0r8vXyitYzgU1jU3XUsD0TD8brmKJQ1K69i96PvV
 YXxlwM8H9T8TKvUn6ukNGIenepwxgq6VWX9AFUVYM57ED4gPeEdLzghaRuwWSKHeRe87AalN9nA
 UnMJdaKBxxa1ayrc5VuMcZ5Y4oel72l0csJY3K/9Gsbg7W8pM3yGx+9c5F1iCbbcFBylxgZ+Ck4
 uDMwx7abcVRo6zeTXeAUnYmvkBbC0FpP6xR8crsWNquZCON80hS0p84ekfW0F7NnxE0uSAu2TnG
 U+Kt0wsERrJ8qGDiIiGicevEQjujEmlO1nB9UTVmVdG5vpUZ8aceUwMZAthgrXHNTLr24VkKLVe
 bxHsOH9BkIWJH0zHe/o2VeHcyaKzd17jbFcu4Vvok9ck1KVcT30nHimKmyCOxjC5kxMGSUYk4D8
 xUhI80UJfIUiD1Q==
X-Developer-Key: i=shankerwangmiao@gmail.com; a=openpgp;
 fpr=6FAEFF06B7D212A774C60BFDFA0D166D6632EF4A
X-Endpoint-Received: by B4 Relay for shankerwangmiao@gmail.com/20250715 with auth_id=462
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The reset event of BMC is captured through GPIO. However, this driver
bypasses the GPIO framework and directly accesses the GPIO controller
through the fixed address. When the same GPIO controller is also
exposed through ACPI and probed by the corresponding GPIO driver,
there would be a conflict between the two drivers.

This patch will try to find the GPIO through declared GPIO pin in the
_CRS resources of the ACPI node. If no such delaration is found, the
driver will fall back to search for the correct GPIO controller and pin
according to the fixed address and pin number. A possible DSDT
declaration for the GPIO pin might be as follows:

    Device (BMC0) {
        Name (_ADR, ...) // Match the PCI address of the BMC device
        // \_SB.GPO1 is the ACPI path of the GPIO controller
        Name (_CRS, ResourceTemplate () {
            GpioInt (Edge, ActiveLow, Exclusive, PullNone, 0,
                     "\\_SB.GPO1", 0) {
                14 // 14 is the GPIO pin number
            }
    }

Signed-off-by: Miao Wang <shankerwangmiao@gmail.com>
---
 drivers/mfd/ls2k-bmc-core.c | 162 +++++++++++++++++++++++++++++++-------------
 1 file changed, 115 insertions(+), 47 deletions(-)

diff --git a/drivers/mfd/ls2k-bmc-core.c b/drivers/mfd/ls2k-bmc-core.c
index f87224105b3720cca97dcef089dad63fe57bc8c2..7187b2dfddc3acfb9fdf3cb3b4675299928dd03a 100644
--- a/drivers/mfd/ls2k-bmc-core.c
+++ b/drivers/mfd/ls2k-bmc-core.c
@@ -26,6 +26,9 @@
 #include <linux/stop_machine.h>
 #include <linux/vt_kern.h>
 #include <linux/console.h>
+#include <linux/gpio/consumer.h>
+#include <linux/gpio/driver.h>
+#include <linux/gpio.h>
 
 /* LS2K BMC resources */
 #define LS2K_DISPLAY_RES_START		(SZ_16M + SZ_2M)
@@ -81,18 +84,6 @@
 
 #define PCI_REG_STRIDE			0x4
 
-#define LS2K_BMC_RESET_GPIO		14
-#define LOONGSON_GPIO_REG_BASE		0x1FE00500
-#define LOONGSON_GPIO_REG_SIZE		0x18
-#define LOONGSON_GPIO_OEN		0x0
-#define LOONGSON_GPIO_FUNC		0x4
-#define LOONGSON_GPIO_INTPOL		0x10
-#define LOONGSON_GPIO_INTEN		0x14
-
-#define LOONGSON_IO_INT_BASE		16
-#define LS2K_BMC_RESET_GPIO_INT_VEC	(LS2K_BMC_RESET_GPIO % 8)
-#define LS2K_BMC_RESET_GPIO_GSI		(LOONGSON_IO_INT_BASE + LS2K_BMC_RESET_GPIO_INT_VEC)
-
 enum {
 	LS2K_BMC_DISPLAY,
 	LS2K_BMC_IPMI0,
@@ -186,6 +177,7 @@ struct ls2k_bmc_ddata {
 	struct work_struct bmc_reset_work;
 	struct ls2k_bmc_pci_data bmc_pci_data;
 	struct ls2k_bmc_bridge_pci_data bridge_pci_data;
+	struct gpio_desc *reset_gpio;
 };
 
 static bool ls2k_bmc_bar0_addr_is_set(struct pci_dev *pdev)
@@ -334,6 +326,22 @@ static irqreturn_t ls2k_bmc_interrupt(int irq, void *arg)
 	return IRQ_HANDLED;
 }
 
+static irqreturn_t ls2k_bmc_gpio_interrupt(int irq, void *arg)
+{
+	struct ls2k_bmc_ddata *ddata = arg;
+
+	int val = gpiod_get_raw_value(ddata->reset_gpio);
+
+	/*
+	 * The GPIO is active low, so when the value is 0,
+	 * it indicates a reset event.
+	 */
+	if (val == 0)
+		return ls2k_bmc_interrupt(irq, arg);
+
+	return IRQ_NONE;
+}
+
 /*
  * Saves the BMC parent device (LS7A) and its own PCI configuration space registers
  * that need to be restored after BMC reset.
@@ -375,6 +383,79 @@ static void ls2k_bmc_save_pci_data(struct pci_dev *pdev, struct ls2k_bmc_ddata *
 	pci_read_config_dword(pdev, PCI_INTERRUPT_LINE, &ddata->bmc_pci_data.interrupt_line);
 }
 
+static int ls2k_bmc_gpiochip_find(struct gpio_chip *gc, const void *data)
+{
+	struct acpi_device *adev;
+	struct list_head resource_list;
+	struct resource_entry *rentry;
+	struct fwnode_handle *fwnode = gc->fwnode ?: gc->parent ? gc->parent->fwnode : NULL;
+	phys_addr_t start_addr = (phys_addr_t) data;
+	int ret, found = 0;
+
+	if (!is_acpi_node(fwnode))
+		goto out;
+
+	adev = to_acpi_device_node(fwnode);
+	if (!adev)
+		goto out;
+
+	INIT_LIST_HEAD(&resource_list);
+
+	ret = acpi_dev_get_memory_resources(adev, &resource_list);
+	if (ret < 0)
+		goto out;
+	rentry = list_first_entry_or_null(&resource_list, struct resource_entry, node);
+	if (!rentry)
+		goto free_resource_list;
+	if (rentry->res->start == start_addr)
+		found = 1;
+
+free_resource_list:
+	acpi_dev_free_resource_list(&resource_list);
+out:
+	return found;
+}
+
+static struct gpio_desc *ls2k_bmc_find_gpio(struct ls2k_bmc_ddata *ddata)
+{
+	/*
+	 * In conventional way, the GPIO should be obtained through ACPI or
+	 * device tree. However, when the information is not available,
+	 * we should find the GPIO according to the convention of the server
+	 * boards with LS2K BMC, the gpio signal relelecting the reset event
+	 * of the BMC should be connected to pin 14 of the GPIO input of
+	 * the first CPU node. The address of that GPIO controller is fixed.
+	 */
+	static const phys_addr_t LOONGSON_GPIO_REG_BASE = 0x1FE00500;
+	static const unsigned int LS2K_BMC_RESET_GPIO = 14;
+	struct gpio_desc *desc;
+	unsigned int legacy_gpio;
+	int ret;
+	struct gpio_device *gdev __free(gpio_device_put) = NULL;
+
+	dev_dbg(ddata->dev, "Searching for GPIO chip at address %pa\n", &LOONGSON_GPIO_REG_BASE);
+
+	gdev = gpio_device_find((void *)LOONGSON_GPIO_REG_BASE, ls2k_bmc_gpiochip_find);
+
+	if (!gdev) {
+		dev_dbg(ddata->dev, "cannot find GPIO chip at address %pa, deferring\n",
+			&LOONGSON_GPIO_REG_BASE);
+		return ERR_PTR(-EPROBE_DEFER);
+	}
+
+	desc = gpio_device_get_desc(gdev, LS2K_BMC_RESET_GPIO);
+	if (IS_ERR(desc))
+		return desc;
+
+	// XXX: might be better to use gpiod_request()
+	legacy_gpio = desc_to_gpio(desc);
+	ret = devm_gpio_request_one(ddata->dev, legacy_gpio, GPIOF_IN, dev_name(ddata->dev));
+	if (ret < 0)
+		return ERR_PTR(ret);
+
+	return gpio_to_desc(legacy_gpio);
+}
+
 static void ls2k_bmc_cancel_wq(void *data)
 {
 	struct ls2k_bmc_ddata *ddata = data;
@@ -384,8 +465,7 @@ static void ls2k_bmc_cancel_wq(void *data)
 static int ls2k_bmc_init(struct ls2k_bmc_ddata *ddata)
 {
 	struct pci_dev *pdev = to_pci_dev(ddata->dev);
-	void __iomem *gpio_base;
-	int gpio_irq, ret, val;
+	int gpio_irq, ret;
 
 	ls2k_bmc_save_pci_data(pdev, ddata);
 
@@ -400,44 +480,32 @@ static int ls2k_bmc_init(struct ls2k_bmc_ddata *ddata)
 		return ret;
 	}
 
-	gpio_base = ioremap(LOONGSON_GPIO_REG_BASE, LOONGSON_GPIO_REG_SIZE);
-	if (!gpio_base)
-		return -ENOMEM;
-
-	/* Disable GPIO output */
-	val = readl(gpio_base + LOONGSON_GPIO_OEN);
-	writel(val | BIT(LS2K_BMC_RESET_GPIO), gpio_base + LOONGSON_GPIO_OEN);
-
-	/* Enable GPIO functionality */
-	val = readl(gpio_base + LOONGSON_GPIO_FUNC);
-	writel(val & ~BIT(LS2K_BMC_RESET_GPIO), gpio_base + LOONGSON_GPIO_FUNC);
-
-	/* Set GPIO interrupts to low-level active */
-	val = readl(gpio_base + LOONGSON_GPIO_INTPOL);
-	writel(val & ~BIT(LS2K_BMC_RESET_GPIO), gpio_base + LOONGSON_GPIO_INTPOL);
-
-	/* Enable GPIO interrupts */
-	val = readl(gpio_base + LOONGSON_GPIO_INTEN);
-	writel(val | BIT(LS2K_BMC_RESET_GPIO), gpio_base + LOONGSON_GPIO_INTEN);
+	ddata->reset_gpio = devm_gpiod_get_index_optional(&pdev->dev, NULL, 0, GPIOD_IN);
+	if (IS_ERR(ddata->reset_gpio)) {
+		ret = PTR_ERR(ddata->reset_gpio);
+		ddata->reset_gpio = NULL;
+		return dev_err_probe(ddata->dev, ret, "Failed to get reset GPIO\n");
+	}
+	if (ddata->reset_gpio == NULL) {
+		ddata->reset_gpio = ls2k_bmc_find_gpio(ddata);
+		if (IS_ERR(ddata->reset_gpio)) {
+			ret = PTR_ERR(ddata->reset_gpio);
+			ddata->reset_gpio = NULL;
+			return dev_err_probe(ddata->dev, ret, "Failed to find reset GPIO\n");
+		}
+	}
 
-	iounmap(gpio_base);
+	gpio_irq = gpiod_to_irq(ddata->reset_gpio);
 
-	/*
-	 * Since gpio_chip->to_irq is not implemented in the Loongson-3 GPIO driver,
-	 * acpi_register_gsi() is used to obtain the GPIO IRQ. The GPIO interrupt is a
-	 * watchdog interrupt that is triggered when the BMC resets.
-	 */
-	gpio_irq = acpi_register_gsi(NULL, LS2K_BMC_RESET_GPIO_GSI, ACPI_EDGE_SENSITIVE,
-				     ACPI_ACTIVE_LOW);
 	if (gpio_irq < 0)
-		return gpio_irq;
+		return dev_err_probe(ddata->dev, gpio_irq, "Failed to get GPIO IRQ\n");
 
-	ret = devm_request_irq(ddata->dev, gpio_irq, ls2k_bmc_interrupt,
-			       IRQF_SHARED | IRQF_TRIGGER_FALLING, "ls2kbmc gpio", ddata);
-	if (ret)
-		dev_err(ddata->dev, "Failed to request LS2KBMC GPIO IRQ %d.\n", gpio_irq);
+	ret = devm_request_irq(&pdev->dev, gpio_irq, ls2k_bmc_gpio_interrupt,
+			       IRQF_SHARED | IRQF_TRIGGER_FALLING, "ls2kbmc reset", ddata);
+
+	if (ret != 0)
+		return dev_err_probe(ddata->dev, ret, "Failed to request GPIO IRQ %d.\n", gpio_irq);
 
-	acpi_unregister_gsi(LS2K_BMC_RESET_GPIO_GSI);
 	return ret;
 }
 

-- 
2.49.0

