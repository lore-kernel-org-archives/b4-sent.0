From: Luca Lauro <famlauro93l@gmail.com>
Date: Thu, 23 Jul 2026 15:57:46 +0200
Subject: [PATCH 08/19] ARM: mvebu: rn104: placeholder bay management
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260723-rn102-rn104-series-v1-8-7698d25df866@gmail.com>
References: <20260723-rn102-rn104-series-v1-0-7698d25df866@gmail.com>
In-Reply-To: <20260723-rn102-rn104-series-v1-0-7698d25df866@gmail.com>
To: Sascha Hauer <s.hauer@pengutronix.de>, 
 "open list:BAREBOX" <barebox@lists.infradead.org>
Cc: Luca Lauro <famlauro93l@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784815061; l=5527;
 i=famlauro93l@gmail.com; s=20260723; h=from:subject:message-id;
 bh=W+nIYf1o4gTEJWFmsn17mard2L4LohcW4pOMRz5iulA=;
 b=QIv6wmTVHWkBGMZhkTqGZx1/UDA/Yvy3GWnhk/lpS1eBl3QdfxtnHCIXto+FiB+s2KleoSoL8
 D6Lff4HgJKtDiGlKMgFIRU8cb0BCzB1ryXrLCCJf8mOPP2fOaJ9jFHz
X-Developer-Key: i=famlauro93l@gmail.com; a=ed25519;
 pk=OAJlcD69ugQCl99Vy6w+Aeu+ZUb1IVGcz1Ijxo6Ch78=
X-Endpoint-Received: by B4 Relay for famlauro93l@gmail.com/20260723 with auth_id=892
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

---
 arch/arm/boards/netgear-rn104/board.c | 193 ++++++++++++++++++++++++++++++++++
 1 file changed, 193 insertions(+)

diff --git a/arch/arm/boards/netgear-rn104/board.c b/arch/arm/boards/netgear-rn104/board.c
new file mode 100644
index 0000000000..29c112ec9e
--- /dev/null
+++ b/arch/arm/boards/netgear-rn104/board.c
@@ -0,0 +1,193 @@
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
+struct rn104_disk_bay {
+    int gpio_detect;        /* input, active-low */
+    int gpio_power;         /* output */
+    int gpio_led;           /* output, active-low */
+    enum disk_state state;
+};
+
+#define rn104_NUM_DISK_BAYS 1
+
+static struct rn104_disk_bay rn104_bays[rn104_NUM_DISK_BAYS] = {
+    { -1, -1, -1, DISK_ABSENT }, /* placeholder */
+};
+
+static void setup_bays(void)
+{
+    pr_info("RN104: bay management not implemented (PCA9554-based)\n");
+}
+
+/*
+ * After waiting for present disks spinup,
+ * we ask explicitly for corresponding ATA devices probe.
+ */
+static void init_disks(void)
+{
+    pr_info("RN104: disk spin-up logic not implemented\n");
+}
+
+/*
+ *  USB0 → DRAM MBUS windows
+ *
+ * frontal USB 2.0 port of rn104 is connected to the SoC usb0.
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
+static int rn104_early_poweron(void)
+{
+    writel(0xC6, 0xf1020228); /* CFU configuration */
+    setup_usb0();
+    setup_bays();
+
+    return 0;
+}
+postcore_initcall(rn104_early_poweron);
+
+static int rn104_init(void)
+{
+    init_disks();
+
+    return 0;
+}
+device_initcall(rn104_init);
+
+
+/* BareBox Update handlers */
+static int rn104_register_bbu(void)
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
+late_initcall(rn104_register_bbu);

-- 
2.47.3

