From: Luca Lauro <famlauro93l@gmail.com>
Date: Tue, 28 Jul 2026 19:43:15 +0200
Subject: [PATCH v2 03/10] ARM: mvebu: add Netgear RN104 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260728-rn102-rn104-series-v2-3-ae31f55b7bc8@gmail.com>
References: <20260728-rn102-rn104-series-v2-0-ae31f55b7bc8@gmail.com>
In-Reply-To: <20260728-rn102-rn104-series-v2-0-ae31f55b7bc8@gmail.com>
To: Sascha Hauer <s.hauer@pengutronix.de>, 
 "open list:BAREBOX" <barebox@lists.infradead.org>
Cc: Luca Lauro <famlauro93l@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785260594; l=17395;
 i=famlauro93l@gmail.com; s=20260723; h=from:subject:message-id;
 bh=6KxqNyXDneqTZJDagLqg8+hk7OuEXQ6I5ZOiDuSmHos=;
 b=21gMIYmw0suAGZUA+3H3x6OZcSZtGKELHhmN1ZyPWzlDTmULJF+AgzFqoC5ox2BfRkNfxwmi8
 mCTHw8tyPp+Bjs+1/EGDM2wqspzQZ9eWDAFvlai31xZOh37zc5NaLNT
X-Developer-Key: i=famlauro93l@gmail.com; a=ed25519;
 pk=OAJlcD69ugQCl99Vy6w+Aeu+ZUb1IVGcz1Ijxo6Ch78=
X-Endpoint-Received: by B4 Relay for famlauro93l@gmail.com/20260723 with auth_id=892
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This updates full support for the Netgear ReadyNAS 104, including:

 - board driver matching on "netgear,rn104"
 - bay management placeholder
 - lowlevel initialization
 - barebox device tree
 - barebox overlay with environment and state backend
 - NAND partition layout
 - image support

Signed-off-by: Luca Lauro <famlauro93l@gmail.com>
---
 arch/arm/boards/netgear-rn104/board.c            | 193 +++++++++++++++++++++++
 arch/arm/boards/netgear-rn104/lowlevel.c         |  43 +++--
 arch/arm/dts/armada-370-rn104-bb.dts             |  75 ++++++++-
 dts/src/arm/marvell/armada-370-netgear-rn104.dts | 173 ++++++++++++--------
 images/Makefile.mvebu                            |   3 +-
 5 files changed, 403 insertions(+), 84 deletions(-)

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
diff --git a/arch/arm/boards/netgear-rn104/lowlevel.c b/arch/arm/boards/netgear-rn104/lowlevel.c
index e693d13993..4fb5b6432b 100644
--- a/arch/arm/boards/netgear-rn104/lowlevel.c
+++ b/arch/arm/boards/netgear-rn104/lowlevel.c
@@ -1,24 +1,49 @@
 // SPDX-License-Identifier: GPL-2.0-only
 
-/*
- * Copyright (C) 2014  Uwe Kleine-Koenig <uwe@kleine-koenig.org>
- */
-
 #include <common.h>
 #include <asm/barebox-arm.h>
-#include <mach/mvebu/barebox-arm-head.h>
 #include <mach/mvebu/lowlevel.h>
+#include <mach/mvebu/barebox-arm-head.h>
+#include <mach/mvebu/armada-370-xp-regs.h>
 
 extern char __dtb_armada_370_rn104_bb_start[];
 
-ENTRY_FUNCTION_MVEBU(start_netgear_rn104, r0, r1, r2)
+#define INTERNAL_REG_BASE_ADDR	0x20080
+
+static __always_inline void mvebu_remap_registers(void)
+{
+	void __iomem *base = mvebu_get_initial_int_reg_base();
+
+	writel(MVEBU_REMAP_INT_REG_BASE, base + INTERNAL_REG_BASE_ADDR);
+}
+
+static unsigned long armada_370_xp_memory_find(void)
 {
-	void *fdt;
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
 
-	arm_cpu_lowlevel_init();
+	return mem_size;
+}
+
+ENTRY_FUNCTION_MVEBU(start_netgear_rn104, r0, r1, r2)
+{
+    void *fdt;
 
+    arm_cpu_lowlevel_init();
+	
 	fdt = __dtb_armada_370_rn104_bb_start +
 		get_runtime_offset();
 
-	armada_370_xp_barebox_entry(fdt);
+	mvebu_remap_registers();
+	barebox_arm_entry(0, armada_370_xp_memory_find(), fdt);
+	// armada_370_xp_barebox_entry(fdt);
 }
diff --git a/arch/arm/dts/armada-370-rn104-bb.dts b/arch/arm/dts/armada-370-rn104-bb.dts
index b786ef350a..2649ede4f4 100644
--- a/arch/arm/dts/armada-370-rn104-bb.dts
+++ b/arch/arm/dts/armada-370-rn104-bb.dts
@@ -5,9 +5,76 @@
 #include "arm/marvell/armada-370-netgear-rn104.dts"
 
 / {
-	barebox,disable-deep-probe;
+    chosen {
+        stdout-path = &uart0;
+    };
 
-	chosen {
-		stdout-path = &uart0;
-	};
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
 };
diff --git a/dts/src/arm/marvell/armada-370-netgear-rn104.dts b/dts/src/arm/marvell/armada-370-netgear-rn104.dts
index d752ac1d7b..d7cc0549f4 100644
--- a/dts/src/arm/marvell/armada-370-netgear-rn104.dts
+++ b/dts/src/arm/marvell/armada-370-netgear-rn104.dts
@@ -15,6 +15,10 @@ / {
 	model = "NETGEAR ReadyNAS 104";
 	compatible = "netgear,readynas-104", "marvell,armada370", "marvell,armada-370-xp";
 
+	aliases {
+		state = &state_nand;
+    };
+
 	chosen {
 		stdout-path = "serial0:115200n8";
 	};
@@ -40,6 +44,12 @@ serial@12000 {
 				status = "okay";
 			};
 
+			/* eSATA interface */
+			sata@a0000 {
+				nr-ports = <1>;
+				status = "okay";
+			};
+
 			ethernet@70000 {
 				pinctrl-0 = <&ge0_rgmii_pins>;
 				pinctrl-names = "default";
@@ -103,15 +113,10 @@ g762_clk: g762-oscillator {
 
 	gpio-leds {
 		compatible = "gpio-leds";
-		pinctrl-0 = <&backup_led_pin &power_led_pin>;
+		pinctrl-0 = <&power_led_pin
+			     &backup_led_pin>;
 		pinctrl-names = "default";
 
-		blue-backup-led {
-			label = "rn104:blue:backup";
-			gpios = <&gpio1 31 GPIO_ACTIVE_HIGH>;
-			default-state = "off";
-		};
-
 		blue-power-led {
 			label = "rn104:blue:pwr";
 			gpios = <&gpio2 0 GPIO_ACTIVE_LOW>;
@@ -141,6 +146,12 @@ blue-sata4-led {
 			gpios = <&pca9554 3 GPIO_ACTIVE_LOW>;
 			default-state = "off";
 		};
+
+		blue-backup-led {
+			label = "rn104:blue:backup";
+			gpios = <&gpio1 31 GPIO_ACTIVE_HIGH>;
+			default-state = "off";
+		};
 	};
 
 	auxdisplay {
@@ -159,17 +170,11 @@ auxdisplay {
 
 	gpio-keys {
 		compatible = "gpio-keys";
-		pinctrl-0 = <&backup_button_pin
-			     &power_button_pin
-			     &reset_button_pin>;
+		pinctrl-0 = <&power_button_pin
+			     &reset_button_pin
+			     &backup_button_pin>;
 		pinctrl-names = "default";
 
-		backup-button {
-			label = "Backup Button";
-			linux,code = <KEY_COPY>;
-			gpios = <&gpio1 20 GPIO_ACTIVE_LOW>;
-		};
-
 		power-button {
 			label = "Power Button";
 			linux,code = <KEY_POWER>;
@@ -181,6 +186,12 @@ reset-button {
 			linux,code = <KEY_RESTART>;
 			gpios = <&gpio2 1 GPIO_ACTIVE_LOW>;
 		};
+
+		backup-button {
+			label = "Backup Button";
+			linux,code = <KEY_COPY>;
+			gpios = <&gpio1 20 GPIO_ACTIVE_LOW>;
+		};
 	};
 
 	gpio-poweroff {
@@ -189,18 +200,43 @@ gpio-poweroff {
 		pinctrl-names = "default";
 		gpios = <&gpio1 28 GPIO_ACTIVE_LOW>;
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
 	status = "okay";
 
-	/* Connected to FL1009 USB 3.0 controller */
+	/* Connected to Marvell 88SE9170 SATA controller */
 	pcie@1,0 {
 		/* Port 0, Lane 0 */
 		status = "okay";
 	};
 
-	/* Connected to Marvell 88SE9215 SATA controller */
+	/* Connected to FL1009 USB 3.0 controller */
 	pcie@2,0 {
 		/* Port 1, Lane 0 */
 		status = "okay";
@@ -220,8 +256,13 @@ phy1: ethernet-phy@1 { /* Marvell 88E1318 */
 };
 
 &pinctrl {
-	poweroff: poweroff {
-		marvell,pins = "mpp60";
+	power_led_pin: power-led-pin {
+		marvell,pins = "mpp64";
+		marvell,function = "gpio";
+	};
+
+	backup_led_pin: backup-led-pin {
+		marvell,pins = "mpp63";
 		marvell,function = "gpio";
 	};
 
@@ -235,68 +276,62 @@ power_button_pin: power-button-pin {
 		marvell,function = "gpio";
 	};
 
-	backup_led_pin: backup-led-pin {
-		marvell,pins = "mpp63";
-		marvell,function = "gpio";
-	};
-
-	power_led_pin: power-led-pin {
-		marvell,pins = "mpp64";
+	reset_button_pin: reset-button-pin {
+		marvell,pins = "mpp65";
 		marvell,function = "gpio";
 	};
 
-	reset_button_pin: reset-button-pin {
-		marvell,pins = "mpp65";
+	poweroff_pin: poweroff-pin {
+		marvell,pins = "mpp60";
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
 
-			partition@180000 {
-				label = "u-boot-env";
-				reg = <0x180000 0x20000>;    /* 128KB */
-				read-only;
-			};
+	/* Use Hardware BCH ECC */
+	nand-ecc-strength = <4>;
+	nand-ecc-step-size = <512>;
 
-			partition@200000 {
-				label = "uImage";
-				reg = <0x0200000 0x600000>;    /* 6MB */
-			};
+	partitions {
+		compatible = "fixed-partitions";
+		#address-cells = <1>;
+		#size-cells = <1>;
 
-			partition@800000 {
-				label = "minirootfs";
-				reg = <0x0800000 0x400000>;    /* 4MB */
-			};
+		partition@0 {
+			label = "bootloader";
+			reg = <0x0 0x400000>;		 /* 4MB */
+			//read-only;
+		};
 
-			/* Last MB is for the BBT, i.e. not writable */
-			partition@c00000 {
-				label = "ubifs";
-				reg = <0x0c00000 0x7400000>; /* 116MB */
-			};
+		partition@0x400000 {
+			label = "environment";
+			reg = <0x400000 0x80000>;    /* 0.5MB */
+			//read-only;
 		};
+
+		backend_state_nand: partition@0x480000 {
+			label = "state";
+			reg = <0x480000 0x80000>;    /* 0.5MB */
+		};
+
+		partition@0x500000 {
+			label = "kernel";
+			reg = <0x500000 0x1400000>;    /* 20MB */
+		};
+
+		partition@0x1900000 {
+			label = "minirootfs";
+			reg = <0x1900000 0x6000000>;    /* 100MB */
+		};
+
+		/* Last MB is for the BBT, i.e. not writable */
 	};
-};
+};
\ No newline at end of file
diff --git a/images/Makefile.mvebu b/images/Makefile.mvebu
index 1741f0e9a5..106a302cfa 100644
--- a/images/Makefile.mvebu
+++ b/images/Makefile.mvebu
@@ -37,10 +37,9 @@ image-$(CONFIG_MACH_NETGEAR_RN102) += barebox-netgear-rn102.img
 FILE_barebox-netgear-rn102-2nd.img = start_netgear_rn102.pblb
 image-$(CONFIG_MACH_NETGEAR_RN102) += barebox-netgear-rn102-2nd.img
 
-FLAGS_start_netgear_rn104.pblb.mvebu1img = -d 0x600000 -e 0x6e0000
 BOOTSRC_start_netgear_rn104.pblb.mvebu1img = nand
 BINHDR_start_netgear_rn104.pblb.mvebu1img = $(board)/netgear-rn104/binary.0
-FLAGS_start_netgear_rn104.pblb.mvebu1img = -B 0x20000:1
+FLAGS_start_netgear_rn104.pblb.mvebu1img = -B 0x20000:1 -d 0x0 -e 0x0
 FILE_barebox-netgear-rn104.img = start_netgear_rn104.pblb.mvebu1img
 pblb-$(CONFIG_MACH_NETGEAR_RN104) += start_netgear_rn104
 image-$(CONFIG_MACH_NETGEAR_RN104) += barebox-netgear-rn104.img

-- 
2.47.3

