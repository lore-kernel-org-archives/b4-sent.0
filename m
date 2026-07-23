From: Luca Lauro <famlauro93l@gmail.com>
Date: Thu, 23 Jul 2026 15:57:39 +0200
Subject: [PATCH 01/19] ARM: mvebu: add board support for Netgear RN102
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260723-rn102-rn104-series-v1-1-7698d25df866@gmail.com>
References: <20260723-rn102-rn104-series-v1-0-7698d25df866@gmail.com>
In-Reply-To: <20260723-rn102-rn104-series-v1-0-7698d25df866@gmail.com>
To: Sascha Hauer <s.hauer@pengutronix.de>, 
 "open list:BAREBOX" <barebox@lists.infradead.org>
Cc: Luca Lauro <famlauro93l@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784815061; l=10418;
 i=famlauro93l@gmail.com; s=20260723; h=from:subject:message-id;
 bh=BWQBXZQdp0klKTicbyqCw6vp3ul2YoDCrDw/uvc3jOA=;
 b=tEflh5ihrR65lwlvFag1WVmdKauUqdvNlwpu4b587/KdRyqn8nt+9RwvFeJOed4F2u0i3wX/r
 SFLHh6rINiUDktS4JTOQbEvqnOQ9nnXLVLCrtJHWzmXHv4nmNRKK9Qi
X-Developer-Key: i=famlauro93l@gmail.com; a=ed25519;
 pk=OAJlcD69ugQCl99Vy6w+Aeu+ZUb1IVGcz1Ijxo6Ch78=
X-Endpoint-Received: by B4 Relay for famlauro93l@gmail.com/20260723 with auth_id=892
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

---
 arch/arm/boards/Makefile               |   1 +
 arch/arm/boards/netgear-rn102/Makefile |   4 +
 arch/arm/boards/netgear-rn102/board.c  | 243 +++++++++++++++++++++++++++++++++
 rebuild-series.sh                      |  39 ++++++
 4 files changed, 287 insertions(+)

diff --git a/arch/arm/boards/Makefile b/arch/arm/boards/Makefile
index dd2f2c324e..aca1b45a81 100644
--- a/arch/arm/boards/Makefile
+++ b/arch/arm/boards/Makefile
@@ -64,6 +64,7 @@ obj-$(CONFIG_MACH_MARVELL_ARMADA_XP_DB)		+= marvell-armada-xp-db/
 obj-$(CONFIG_MACH_MX23EVK)			+= freescale-mx23-evk/
 obj-$(CONFIG_MACH_MX28EVK)			+= freescale-mx28-evk/
 obj-$(CONFIG_MACH_MYIRTECH_X335X)		+= myirtech-x335x/
+obj-$(CONFIG_MACH_NETGEAR_RN102)		+= netgear-rn102/
 obj-$(CONFIG_MACH_NETGEAR_RN104)		+= netgear-rn104/
 obj-$(CONFIG_MACH_NETGEAR_RN2120)		+= netgear-rn2120/
 obj-$(CONFIG_MACH_NVIDIA_BEAVER)		+= nvidia-beaver/
diff --git a/arch/arm/boards/netgear-rn102/Makefile b/arch/arm/boards/netgear-rn102/Makefile
new file mode 100644
index 0000000000..da63d2625f
--- /dev/null
+++ b/arch/arm/boards/netgear-rn102/Makefile
@@ -0,0 +1,4 @@
+# SPDX-License-Identifier: GPL-2.0-only
+
+obj-y += board.o
+lwl-y += lowlevel.o
diff --git a/arch/arm/boards/netgear-rn102/board.c b/arch/arm/boards/netgear-rn102/board.c
new file mode 100644
index 0000000000..c6673e9356
--- /dev/null
+++ b/arch/arm/boards/netgear-rn102/board.c
@@ -0,0 +1,243 @@
+// SPDX-License-Identifier: GPL-2.0-only
+
+#include <common.h>
+#include <init.h>
+#include <gpio.h>
+#include <driver.h>
+#include <linux/device.h>
+#include <linux/mbus.h>
+#include <mach/mvebu/armada-370-xp-regs.h>
+#include <bbu.h>
+
+/*
+ *  Early GPIO0 MMIO
+ *
+ * GPIO driver arrives too late for the disks to be
+ * ready in time for AHCI driver probe.
+ * So we use GPIO0 direct access for:
+ *   - reading disk presence monitoring pins
+ *   - enable powerup for bays that detect disk presence
+ *   - display bay status with dedicated LEDs
+ */
+#define GPIO0_BASE           (ARMADA_370_XP_INT_REGS_BASE + 0x18100)
+#define GPIO_OUT             0x00
+#define GPIO_OUT_EN          0x04
+#define GPIO_BLINK_EN        0x08
+#define GPIO_IN              0x10
+#define GPIO_BLINK_CNT_SEL   0x20
+#define GPIO_BLINK_CNT_A_ON  0xc0
+#define GPIO_BLINK_CNT_A_OFF 0xc4
+
+static inline void gpio0_set_output(int pin)
+{
+    u32 v = readl(GPIO0_BASE + GPIO_OUT_EN);
+
+    v &= ~(1 << pin);
+    writel(v, GPIO0_BASE + GPIO_OUT_EN);
+}
+
+static inline void gpio0_set_input(int pin)
+{
+    u32 v = readl(GPIO0_BASE + GPIO_OUT_EN);
+
+    v |= (1 << pin);
+    writel(v, GPIO0_BASE + GPIO_OUT_EN);
+}
+
+static inline void gpio0_write(int pin, int val)
+{
+    u32 v = readl(GPIO0_BASE + GPIO_OUT);
+
+    if (val)
+        v |= (1 << pin);
+    else
+        v &= ~(1 << pin);
+
+    writel(v, GPIO0_BASE + GPIO_OUT);
+}
+
+static inline int gpio0_read(int pin)
+{
+    return !!(readl(GPIO0_BASE + GPIO_IN) & (1 << pin));
+}
+
+static void gpio0_blink(int pin, int on_ms, int off_ms)
+{
+    u32 v;
+
+    gpio0_set_output(pin);
+
+    /* set blink counter A on and off time in core clok cycles */
+    writel(10*on_ms, GPIO0_BASE + GPIO_BLINK_CNT_A_ON);
+    writel(10*off_ms, GPIO0_BASE + GPIO_BLINK_CNT_A_OFF);
+
+    /* use blink counter A for selected pin */
+    v = readl(GPIO0_BASE + GPIO_BLINK_CNT_SEL);
+    v &= ~(1 << pin);
+    writel(v, GPIO0_BASE + GPIO_BLINK_CNT_SEL);
+
+    /* enable blink for selected pin */
+    v = readl(GPIO0_BASE + GPIO_BLINK_EN);
+    v |= (1 << pin);
+    writel(v, GPIO0_BASE + GPIO_BLINK_EN);
+}
+
+static void gpio0_blink_disable(int pin)
+{
+    u32 v;
+
+    v = readl(GPIO0_BASE + GPIO_BLINK_EN);
+    v &= ~(1 << pin);
+    writel(v, GPIO0_BASE + GPIO_BLINK_EN);
+}
+
+/* HDD bays description */
+
+enum disk_state {
+    DISK_ABSENT = 0,
+    DISK_PRESENT,
+    DISK_READY,
+};
+
+struct rn102_disk_bay {
+    int gpio_detect;        /* input, active-low */
+    int gpio_power;         /* output */
+    int gpio_led;           /* output, active-low */
+    enum disk_state state;
+};
+
+#define RN102_NUM_DISK_BAYS 2
+
+static struct rn102_disk_bay rn102_bays[RN102_NUM_DISK_BAYS] = {
+    { 12, 13, 15, DISK_ABSENT }, /* Bay 1, default to disk absent */
+    { 10, 11, 14, DISK_ABSENT }, /* Bay 2, default to disk absent */
+};
+
+static void setup_bays(void) {
+    pr_info("Early disk power-on...\n");
+
+    for (int i = 0; i < RN102_NUM_DISK_BAYS; i++) {
+        int present;
+
+        gpio0_set_input(rn102_bays[i].gpio_detect);
+        present = (gpio0_read(rn102_bays[i].gpio_detect) == 0);
+
+        gpio0_set_output(rn102_bays[i].gpio_power);
+
+        if (present) {
+            pr_info("Bay %d: disk detected, powering on\n", i + 1);
+            gpio0_blink(rn102_bays[i].gpio_led, 500, 500);
+            gpio0_write(rn102_bays[i].gpio_power, 1);
+            rn102_bays[i].state = DISK_PRESENT;
+        } else {
+            pr_info("Bay %d empty\n", i + 1);
+            gpio0_write(rn102_bays[i].gpio_led, 0);
+            gpio0_write(rn102_bays[i].gpio_power, 0);
+            rn102_bays[i].state = DISK_ABSENT;
+        }
+    }
+}
+
+/*
+ * After waiting for present disks spinup,
+ * we ask explicitly for corresponding ATA devices probe.
+ */
+static void init_disks(void) {
+    pr_info("Waiting for disks spinup...\n");
+    mdelay(8000);
+
+    pr_info("Detecting ATA devices:\n");
+    for (int i = 0; i < RN102_NUM_DISK_BAYS; i++) {
+        char name[8];
+        struct device *dev;
+
+        if (rn102_bays[i].state != DISK_PRESENT) {
+            gpio0_write(rn102_bays[i].gpio_power, 0);
+            gpio0_blink_disable(rn102_bays[i].gpio_led);
+            gpio0_write(rn102_bays[i].gpio_led, 0);
+            continue;
+        }
+
+        snprintf(name, sizeof(name), "ata%d", i);
+
+        dev = get_device_by_name(name);
+        if (!dev) {
+            pr_warn("%s not found\n", name);
+            gpio0_write(rn102_bays[i].gpio_power, 0);
+            gpio0_blink(rn102_bays[i].gpio_led, 1000, 1000);
+            continue;
+        }
+
+        pr_info("Connecting %s to disk %d\n", name, i + 1);
+        device_detect(dev);
+        gpio0_blink_disable(rn102_bays[i].gpio_led);
+        gpio0_write(rn102_bays[i].gpio_led, 1);
+        rn102_bays[i].state = DISK_READY;
+    }
+}
+
+/*
+ *  USB0 → DRAM MBUS windows
+ *
+ * frontal USB 2.0 port of RN102 is connected to the SoC usb0.
+ * Here we enable MBUS windows toward all the DRAM using
+ * informations already gathered by mvebu_mbus_dram_info().
+ */
+// #define USB0_BRIDGE_BASE   (ARMADA_370_XP_USB_BASE + 0x300)
+// #define USB_WIN_CTRL(n)    (USB0_BRIDGE_BASE + 0x20 + (n) * 0x10)
+// #define USB_WIN_BASE(n)    (USB0_BRIDGE_BASE + 0x24 + (n) * 0x10)
+
+static void setup_usb0(void) {
+    // /* Window0: 512MB @ 0x00000000 */
+    // writel(0x00000000, USB_WIN_BASE(0));
+    // writel(0x1FFF0E01, USB_WIN_CTRL(0));
+
+    // /* Window1: 512MB @ 0xB0000000 (placeholder) */
+    // writel(0xB0000000, USB_WIN_BASE(1));
+    // writel(0x1FFE841, USB_WIN_CTRL(1));
+
+    writel(0x2, 0xf1051404);    /* enable force suspend */
+    u32 pwr = readl(0xf1051400);
+    pwr &= ~BIT(2);
+    writel(pwr, 0xf1051400);    /* force SUSPENDM=0 */
+}
+
+
+/* Early init: setup specific hardware without blocking initialization. */
+static int rn102_early_poweron(void)
+{
+    writel(0xC6, 0xf1020228); /* CFU configuration */
+    setup_usb0();
+    setup_bays();
+
+    return 0;
+}
+postcore_initcall(rn102_early_poweron);
+
+static int rn102_init(void)
+{
+    init_disks();
+
+    return 0;
+}
+device_initcall(rn102_init);
+
+
+/* BareBox Update handlers */
+static int rn102_register_bbu(void)
+{
+    bbu_register_std_file_update("bootloader", 0,
+                     "/dev/nand0.bootloader",
+                     filetype_kwbimage_v1);
+
+    bbu_register_std_file_update("kernel", 0,
+                     "/dev/nand0.kernel",
+                     filetype_arm_zimage);
+
+    bbu_register_std_file_update("minirootfs", 0,
+                     "/dev/nand0.minirootfs",
+                     filetype_gzip);
+
+    return 0;
+}
+late_initcall(rn102_register_bbu);
diff --git a/rebuild-series.sh b/rebuild-series.sh
new file mode 100755
index 0000000000..aad99bc296
--- /dev/null
+++ b/rebuild-series.sh
@@ -0,0 +1,39 @@
+#!/bin/bash
+set -e
+
+# Torna al punto base
+git checkout v2026.01.0
+git branch -D rn102-rn104-series 2>/dev/null || true
+git checkout -b rn102-rn104-series
+
+# Applica ogni patch e crea commit
+apply_patch() {
+    PATCH="$1"
+    MSG="$2"
+    echo "Applying $PATCH..."
+    git apply "$PATCH"
+    git add -A
+    git commit -m "$MSG"
+}
+
+apply_patch 0001-*.patch "ARM: mvebu: add board support for Netgear RN102"
+apply_patch 0002-*.patch "ARM: mvebu: add lowlevel support for Netgear RN102"
+apply_patch 0003-*.patch "ARM: dts: add barebox device tree for Netgear RN102"
+apply_patch 0004-*.patch "ARM: dts: update RN102 Linux DTS"
+apply_patch 0005-*.patch "ARM: mvebu: add Kconfig entry for Netgear RN102"
+apply_patch 0006-*.patch "ARM: mvebu: add RN102 image support"
+apply_patch 0007-*.patch "ARM: mvebu: enable RN102 in mvebu_defconfig"
+apply_patch 0008-*.patch "ARM: mvebu: rn104: placeholder bay management"
+apply_patch 0009-*.patch "ARM: mvebu: add lowlevel support for Netgear RN104"
+apply_patch 0010-*.patch "ARM: dts: update RN104 Linux DTS"
+apply_patch 0011-*.patch "ARM: mvebu: adapt RN104 image support"
+apply_patch 0012-*.patch "ARM: mvebu: rename PUTC_LL to MVEBU_PUTC_LL"
+apply_patch 0013-*.patch "drivers: fan: add fan framework and API"
+apply_patch 0014-*.patch "commands: add fan control command"
+apply_patch 0015-*.patch "commands: integrate fan command into Kconfig and Makefile"
+apply_patch 0016-*.patch "usb: ehci: add Marvell EHCI host controller driver"
+apply_patch 0017-*.patch "usb: ehci: minor fixes for Marvell compatibility"
+apply_patch 0018-*.patch "ata: ahci: fixes and updates for Marvell SATA controller"
+apply_patch 0019-*.patch "drivers: integrate USB/AHCI changes"
+
+echo "Serie ricostruita con successo!"

-- 
2.47.3

