From: Luca Lauro <famlauro93l@gmail.com>
Date: Tue, 28 Jul 2026 19:43:13 +0200
Subject: [PATCH v2 01/10] ARM: mvebu: add Netgear RN102 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260728-rn102-rn104-series-v2-1-ae31f55b7bc8@gmail.com>
References: <20260728-rn102-rn104-series-v2-0-ae31f55b7bc8@gmail.com>
In-Reply-To: <20260728-rn102-rn104-series-v2-0-ae31f55b7bc8@gmail.com>
To: Sascha Hauer <s.hauer@pengutronix.de>, 
 "open list:BAREBOX" <barebox@lists.infradead.org>
Cc: Luca Lauro <famlauro93l@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785260594; l=19341;
 i=famlauro93l@gmail.com; s=20260723; h=from:subject:message-id;
 bh=EyWDW7KGj7gyd7qvDgWkK/GSEM9J6ucZhwlzyPJawgc=;
 b=zMVLRr3T7unhFJ5aNp+1u/lYQSMCc6Bh7NfXO1n/L7QZrM1VzH0VPm2HCpAvwSl1GNgLb3As3
 jhq/nJD7ek7CvIxgpOkR5j3MNdh+N9wRMtiSf/aMY8XXRfmFkYq+VZw
X-Developer-Key: i=famlauro93l@gmail.com; a=ed25519;
 pk=OAJlcD69ugQCl99Vy6w+Aeu+ZUb1IVGcz1Ijxo6Ch78=
X-Endpoint-Received: by B4 Relay for famlauro93l@gmail.com/20260723 with auth_id=892
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This adds full support for the Netgear ReadyNAS 102, including:

 - board driver matching on "netgear,rn102"
 - lowlevel initialization
 - barebox device tree
 - barebox overlay with environment and state backend
 - NAND partition layout
 - Kconfig entry
 - image support

Signed-off-by: Luca Lauro <famlauro93l@gmail.com>
---
 arch/arm/boards/Makefile                         |   1 +
 arch/arm/boards/netgear-rn102/Makefile           |   4 +
 arch/arm/boards/netgear-rn102/board.c            | 243 +++++++++++++++++++++++
 arch/arm/boards/netgear-rn102/lowlevel.c         |  58 ++++++
 arch/arm/dts/Makefile                            |   1 +
 arch/arm/dts/armada-370-rn102-bb.dts             |  80 ++++++++
 arch/arm/mach-mvebu/Kconfig                      |   4 +
 dts/src/arm/marvell/armada-370-netgear-rn102.dts | 114 +++++++----
 images/Makefile.mvebu                            |  10 +
 9 files changed, 472 insertions(+), 43 deletions(-)

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
diff --git a/arch/arm/boards/netgear-rn102/lowlevel.c b/arch/arm/boards/netgear-rn102/lowlevel.c
new file mode 100644
index 0000000000..af856b0710
--- /dev/null
+++ b/arch/arm/boards/netgear-rn102/lowlevel.c
@@ -0,0 +1,58 @@
+// SPDX-License-Identifier: GPL-2.0-only
+
+#include <common.h>
+#include <asm/barebox-arm.h>
+#include <mach/mvebu/lowlevel.h>
+#include <mach/mvebu/barebox-arm-head.h>
+#include <mach/mvebu/armada-370-xp-regs.h>
+
+extern char __dtb_armada_370_rn102_bb_start[];
+
+#define INTERNAL_REG_BASE_ADDR	0x20080
+
+static __always_inline void mvebu_remap_registers(void)
+{
+	void __iomem *base = mvebu_get_initial_int_reg_base();
+
+	writel(MVEBU_REMAP_INT_REG_BASE, base + INTERNAL_REG_BASE_ADDR);
+}
+
+/*
+ * NOTE:
+ * armada_370_xp_barebox_entry() cannot be used here because the
+ * upstream SDRAM size detection for Armada 370-XP misinterprets
+ * the DDR_SIZE_CSn registers on this board and reports an incorrect
+ * memory size (256MB instead of 512MB on RN102).
+ *
+ * Until the generic detection code is fixed, we compute the SDRAM
+ * size manually using the DDR_SIZE_CSn values.
+ */
+static unsigned long armada_370_xp_memory_find(void)
+{
+	unsigned long mem_size = 0;
+
+	for (int cs = 0; cs < 4; cs++) {
+		u32 ctrl = readl(ARMADA_370_XP_SDRAM_BASE + DDR_SIZE_CSn(cs));
+
+		/* Skip non-enabled CS */
+		if ((ctrl & DDR_SIZE_ENABLED) != DDR_SIZE_ENABLED)
+			continue;
+
+		mem_size += (ctrl | ~DDR_SIZE_MASK) + 1;
+	}
+
+	return mem_size;
+}
+
+ENTRY_FUNCTION_MVEBU(start_netgear_rn102, r0, r1, r2)
+{
+    void *fdt;
+
+    arm_cpu_lowlevel_init();
+	
+	fdt = __dtb_armada_370_rn102_bb_start +
+		get_runtime_offset();
+
+	mvebu_remap_registers();
+	barebox_arm_entry(0, armada_370_xp_memory_find(), fdt);
+}
diff --git a/arch/arm/dts/Makefile b/arch/arm/dts/Makefile
index a84e09e388..5d1b21b615 100644
--- a/arch/arm/dts/Makefile
+++ b/arch/arm/dts/Makefile
@@ -51,6 +51,7 @@ lwl-$(CONFIG_MACH_MARVELL_ARMADA_XP_GP) += armada-xp-gp-bb.dtb.o
 lwl-$(CONFIG_MACH_MARVELL_ARMADA_XP_DB) += armada-xp-db-bb.dtb.o
 lwl-$(CONFIG_MACH_MX28EVK) += imx28-evk.dtb.o
 lwl-$(CONFIG_MACH_MYIRTECH_X335X) += am335x-myirtech-myd.dtb.o am335x-myirtech-myd-mlo.dtb.o
+lwl-$(CONFIG_MACH_NETGEAR_RN102) += armada-370-rn102-bb.dtb.o
 lwl-$(CONFIG_MACH_NETGEAR_RN104) += armada-370-rn104-bb.dtb.o
 lwl-$(CONFIG_MACH_NETGEAR_RN2120) += armada-xp-rn2120-bb.dtb.o
 lwl-$(CONFIG_MACH_NITROGEN6) += imx6q-nitrogen6x.dtb.o imx6dl-nitrogen6x.dtb.o imx6qp-nitrogen6_max.dtb.o
diff --git a/arch/arm/dts/armada-370-rn102-bb.dts b/arch/arm/dts/armada-370-rn102-bb.dts
new file mode 100644
index 0000000000..d82d4cd6ef
--- /dev/null
+++ b/arch/arm/dts/armada-370-rn102-bb.dts
@@ -0,0 +1,80 @@
+/*
+ * Barebox specific DT overlay for Netgear ReadyNAS 102
+ */
+
+#include "arm/marvell/armada-370-netgear-rn102.dts"
+
+/ {
+    chosen {
+        stdout-path = &uart0;
+    };
+
+    aliases {
+        state = &state_nand;
+    };
+
+    environment {
+        compatible = "barebox,environment";
+        device-path = &nand_controller, "partname:environment";
+    };
+
+    state_nand: nand_state_memory {
+        #address-cells = <1>;
+        #size-cells = <1>;
+        compatible = "barebox,state";
+        magic = <0xab67421f>;
+        backend-type = "raw";
+        backend = <&backend_state_nand>;
+        backend-storage-type = "circular";
+        backend-stridesize = <32>;
+
+        variable@0 {
+            reg = <0x0 0x1>;
+            type = "uint8";
+            default = <0x1>;
+        };
+    };
+};
+
+&nand_controller {
+    compatible = "marvell,armada370-nand", "marvell,pxa3xx-nand";
+    status = "okay";
+
+    nand-rb = <0>;
+    marvell,nand-keep-config;
+    nand-on-flash-bbt;
+
+    nand-ecc-strength = <4>;
+    nand-ecc-step-size = <512>;
+
+    partitions {
+        compatible = "fixed-partitions";
+        #address-cells = <1>;
+        #size-cells = <1>;
+
+        partition@0 {
+            label = "bootloader";
+            reg = <0x0 0x400000>;
+        };
+
+        partition@400000 {
+            label = "environment";
+            reg = <0x400000 0x80000>;
+        };
+
+        backend_state_nand: partition@480000 {
+            label = "state";
+            reg = <0x480000 0x80000>;
+        };
+
+        partition@500000 {
+            label = "kernel";
+            reg = <0x500000 0x1400000>;
+        };
+
+        partition@1900000 {
+            label = "minirootfs";
+            reg = <0x1900000 0x6000000>;
+        };
+    };
+};
diff --git a/arch/arm/mach-mvebu/Kconfig b/arch/arm/mach-mvebu/Kconfig
index ed1302af65..046d539656 100644
--- a/arch/arm/mach-mvebu/Kconfig
+++ b/arch/arm/mach-mvebu/Kconfig
@@ -37,6 +37,10 @@ config MACH_GLOBALSCALE_MIRABOX
 	bool "Globalscale Mirabox"
 	select ARCH_ARMADA_370
 
+config MACH_NETGEAR_RN102
+	bool "Netgear ReadyNAS 102"
+	select ARCH_ARMADA_370
+
 config MACH_NETGEAR_RN104
 	bool "Netgear ReadyNAS 104"
 	select ARCH_ARMADA_370
diff --git a/dts/src/arm/marvell/armada-370-netgear-rn102.dts b/dts/src/arm/marvell/armada-370-netgear-rn102.dts
index 079b37cf14..f1bad2a233 100644
--- a/dts/src/arm/marvell/armada-370-netgear-rn102.dts
+++ b/dts/src/arm/marvell/armada-370-netgear-rn102.dts
@@ -15,6 +15,10 @@ / {
 	model = "NETGEAR ReadyNAS 102";
 	compatible = "netgear,readynas-102", "marvell,armada370", "marvell,armada-370-xp";
 
+	aliases {
+		state = &state_nand;
+    };
+
 	chosen {
 		stdout-path = "serial0:115200n8";
 	};
@@ -54,7 +58,7 @@ ethernet@74000 {
 				phy-mode = "rgmii-id";
 			};
 
-			usb@50000 {
+            usb@50000 {
 				status = "okay";
 			};
 
@@ -153,10 +157,35 @@ backup-button {
 
 	gpio-poweroff {
 		compatible = "gpio-poweroff";
-		pinctrl-0 = <&poweroff>;
+		pinctrl-0 = <&poweroff_pin>;
 		pinctrl-names = "default";
 		gpios = <&gpio0 8 GPIO_ACTIVE_LOW>;
 	};
+
+	/* configure nand partition to store barebox environment */
+	environment {
+      compatible = "barebox,environment";
+      device-path = &nand_controller, "partname:environment";
+	};
+
+	/* configure nand partition to store barebox-state backend */
+	state_nand: nand_state_memory {
+        #address-cells = <1>;
+        #size-cells = <1>;
+        compatible = "barebox,state";
+        magic = <0xab67421f>;
+        backend-type = "raw";
+        backend = <&backend_state_nand>;
+        backend-storage-type = "circular";
+		backend-stridesize = <32>;
+
+        
+        variable@0 {
+                reg = <0x0 0x1>;
+                type ="uint8";
+                default = <0x1>;
+        };
+	};
 };
 
 &pciec {
@@ -219,58 +248,57 @@ reset_button_pin: reset-button-pin {
 		marvell,function = "gpio";
 	};
 
-	poweroff: poweroff {
+	poweroff_pin: poweroff-pin {
 		marvell,pins = "mpp8";
 		marvell,function = "gpio";
 	};
 };
 
 &nand_controller {
+	compatible = "marvell,armada370-nand", "marvell,pxa3xx-nand";
 	status = "okay";
 
-	nand@0 {
-		reg = <0>;
-		label = "pxa3xx_nand-0";
-		nand-rb = <0>;
-		marvell,nand-keep-config;
-		nand-on-flash-bbt;
-
-		/* Use Hardware BCH ECC */
-		nand-ecc-strength = <4>;
-		nand-ecc-step-size = <512>;
-
-		partitions {
-			compatible = "fixed-partitions";
-			#address-cells = <1>;
-			#size-cells = <1>;
-
-			partition@0 {
-				label = "u-boot";
-				reg = <0x0000000 0x180000>;  /* 1.5MB */
-				read-only;
-			};
+	label = <&nand_controller>;
+	nand-rb = <0>;
+	marvell,nand-keep-config;
+	nand-on-flash-bbt;
+	
+	/* Use Hardware BCH ECC */
+	nand-ecc-strength = <4>;
+	nand-ecc-step-size = <512>;
+
+	partitions {
+		compatible = "fixed-partitions";
+		#address-cells = <1>;
+		#size-cells = <1>;
+		
+		partition@0 {
+			label = "bootloader";
+			reg = <0x0 0x400000>;		 /* 4MB */
+			//read-only;
+		};
 
-			partition@180000 {
-				label = "u-boot-env";
-				reg = <0x180000 0x20000>;    /* 128KB */
-				read-only;
-			};
+		partition@0x400000 {
+			label = "environment";
+			reg = <0x400000 0x80000>;    /* 0.5MB */
+			//read-only;
+		};
 
-			partition@200000 {
-				label = "uImage";
-				reg = <0x0200000 0x600000>;    /* 6MB */
-			};
+		backend_state_nand: partition@0x480000 {
+			label = "state";
+			reg = <0x480000 0x80000>;    /* 0.5MB */
+		};
 
-			partition@800000 {
-				label = "minirootfs";
-				reg = <0x0800000 0x400000>;    /* 4MB */
-			};
+		partition@0x500000 {
+			label = "kernel";
+			reg = <0x500000 0x1400000>;    /* 20MB */
+		};
 
-			/* Last MB is for the BBT, i.e. not writable */
-			partition@c00000 {
-				label = "ubifs";
-				reg = <0x0c00000 0x7400000>; /* 116MB */
-			};
+		partition@0x1900000 {
+			label = "minirootfs";
+			reg = <0x1900000 0x6000000>;    /* 100MB */
 		};
+
+		/* Last MB is for the BBT, i.e. not writable */
 	};
-};
+};
\ No newline at end of file
diff --git a/images/Makefile.mvebu b/images/Makefile.mvebu
index 7c918cb9f1..1741f0e9a5 100644
--- a/images/Makefile.mvebu
+++ b/images/Makefile.mvebu
@@ -27,6 +27,16 @@ image-$(CONFIG_MACH_GLOBALSCALE_MIRABOX) += barebox-globalscale-mirabox.img
 FILE_barebox-globalscale-mirabox-2nd.img = start_globalscale_mirabox.pblb
 image-$(CONFIG_MACH_GLOBALSCALE_MIRABOX) += barebox-globalscale-mirabox-2nd.img
 
+BOOTSRC_start_netgear_rn102.pblb.mvebu1img = nand
+BINHDR_start_netgear_rn102.pblb.mvebu1img = $(board)/netgear-rn102/binary.0
+FLAGS_start_netgear_rn102.pblb.mvebu1img = -B 0x20000:1 -d 0x0 -e 0x0
+FILE_barebox-netgear-rn102.img = start_netgear_rn102.pblb.mvebu1img
+pblb-$(CONFIG_MACH_NETGEAR_RN102) += start_netgear_rn102
+image-$(CONFIG_MACH_NETGEAR_RN102) += barebox-netgear-rn102.img
+
+FILE_barebox-netgear-rn102-2nd.img = start_netgear_rn102.pblb
+image-$(CONFIG_MACH_NETGEAR_RN102) += barebox-netgear-rn102-2nd.img
+
 FLAGS_start_netgear_rn104.pblb.mvebu1img = -d 0x600000 -e 0x6e0000
 BOOTSRC_start_netgear_rn104.pblb.mvebu1img = nand
 BINHDR_start_netgear_rn104.pblb.mvebu1img = $(board)/netgear-rn104/binary.0

-- 
2.47.3

