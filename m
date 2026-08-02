From: Luca Lauro <famlauro93l@gmail.com>
Date: Sun, 02 Aug 2026 15:16:19 +0200
Subject: [PATCH v3 03/15] ARM: mvebu: improve Netgear RN104 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260802-rn102-rn104-series-v3-3-f7685a279fb5@gmail.com>
References: <20260802-rn102-rn104-series-v3-0-f7685a279fb5@gmail.com>
In-Reply-To: <20260802-rn102-rn104-series-v3-0-f7685a279fb5@gmail.com>
To: Sascha Hauer <s.hauer@pengutronix.de>, 
 "open list:BAREBOX" <barebox@lists.infradead.org>
Cc: Luca Lauro <famlauro93l@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785676613; l=10060;
 i=famlauro93l@gmail.com; s=20260723; h=from:subject:message-id;
 bh=XPd36CUsStQSgF05mjak6vcj6T2/j6eVUCgpyVAhdKM=;
 b=YwLLedShw34nDSMtx1OmEMYg4+WtO5vcyS/yg53NXmtFfAiqBK5cxy0vVIrQrlimMpcIBMRtt
 6BGLv+bcHW3D8tcJhxpklWtzm28f8uSTF2WOF75lv9mWccwM1cgzAAQ
X-Developer-Key: i=famlauro93l@gmail.com; a=ed25519;
 pk=OAJlcD69ugQCl99Vy6w+Aeu+ZUb1IVGcz1Ijxo6Ch78=
X-Endpoint-Received: by B4 Relay for famlauro93l@gmail.com/20260723 with auth_id=892
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This updates full support for the Netgear ReadyNAS 104, including:

 - board driver matching on "netgear,rn104"
 - bay management placeholder
 - lowlevel initialization
 - barebox overlay with environment, state backend and
 	NAND partition layout
 - image support

Signed-off-by: Luca Lauro <famlauro93l@gmail.com>
---
 arch/arm/boards/netgear-rn104/Makefile   |   1 +
 arch/arm/boards/netgear-rn104/board.c    | 182 +++++++++++++++++++++++++++++++
 arch/arm/boards/netgear-rn104/lowlevel.c |  37 ++++++-
 arch/arm/dts/armada-370-rn104-bb.dts     |  73 ++++++++++++-
 images/Makefile.mvebu                    |   3 +-
 5 files changed, 286 insertions(+), 10 deletions(-)

diff --git a/arch/arm/boards/netgear-rn104/Makefile b/arch/arm/boards/netgear-rn104/Makefile
index 458f520900..da63d2625f 100644
--- a/arch/arm/boards/netgear-rn104/Makefile
+++ b/arch/arm/boards/netgear-rn104/Makefile
@@ -1,3 +1,4 @@
 # SPDX-License-Identifier: GPL-2.0-only
 
+obj-y += board.o
 lwl-y += lowlevel.o
diff --git a/arch/arm/boards/netgear-rn104/board.c b/arch/arm/boards/netgear-rn104/board.c
new file mode 100644
index 0000000000..7a3ed1f16b
--- /dev/null
+++ b/arch/arm/boards/netgear-rn104/board.c
@@ -0,0 +1,182 @@
+// SPDX-License-Identifier: GPL-2.0-only
+
+#include <common.h>
+#include <init.h>
+#include <gpio.h>
+#include <driver.h>
+#include <of.h>
+#include <linux/device.h>
+#include <linux/mbus.h>
+#include <mach/mvebu/armada-370-xp-regs.h>
+#include <bbu.h>
+
+/*
+ * RN104 bay management is PCA9554-based and currently unimplemented.
+ * Placeholder logic is kept for future extension.
+ */
+
+#define GPIO0_BASE				(ARMADA_370_XP_INT_REGS_BASE + 0x18100)
+#define GPIO_OUT				0x00
+#define GPIO_OUT_EN				0x04
+#define GPIO_BLINK_EN			0x08
+#define GPIO_IN					0x10
+#define GPIO_BLINK_CNT_SEL		0x20
+#define GPIO_BLINK_CNT_A_ON		0xc0
+#define GPIO_BLINK_CNT_A_OFF	0xc4
+
+static inline void gpio0_set_output(int pin)
+{
+	u32 v = readl(GPIO0_BASE + GPIO_OUT_EN);
+
+	v &= ~(1 << pin);
+	writel(v, GPIO0_BASE + GPIO_OUT_EN);
+}
+
+static inline void gpio0_set_input(int pin)
+{
+	u32 v = readl(GPIO0_BASE + GPIO_OUT_EN);
+
+	v |= (1 << pin);
+	writel(v, GPIO0_BASE + GPIO_OUT_EN);
+}
+
+static inline void gpio0_write(int pin, int val)
+{
+	u32 v = readl(GPIO0_BASE + GPIO_OUT);
+
+	if (val)
+		v |= (1 << pin);
+	else
+		v &= ~(1 << pin);
+
+	writel(v, GPIO0_BASE + GPIO_OUT);
+}
+
+static inline int gpio0_read(int pin)
+{
+	return !!(readl(GPIO0_BASE + GPIO_IN) & (1 << pin));
+}
+
+static void gpio0_blink(int pin, int on_ms, int off_ms)
+{
+	u32 v;
+
+	gpio0_set_output(pin);
+
+	/* set blink counter A on and off time in core clok cycles */
+	writel(10 * on_ms, GPIO0_BASE + GPIO_BLINK_CNT_A_ON);
+	writel(10 * off_ms, GPIO0_BASE + GPIO_BLINK_CNT_A_OFF);
+
+	/* use blink counter A for selected pin */
+	v = readl(GPIO0_BASE + GPIO_BLINK_CNT_SEL);
+	v &= ~(1 << pin);
+	writel(v, GPIO0_BASE + GPIO_BLINK_CNT_SEL);
+
+	/* enable blink for selected pin */
+	v = readl(GPIO0_BASE + GPIO_BLINK_EN);
+	v |= (1 << pin);
+	writel(v, GPIO0_BASE + GPIO_BLINK_EN);
+}
+
+static void gpio0_blink_disable(int pin)
+{
+	u32 v;
+
+	v = readl(GPIO0_BASE + GPIO_BLINK_EN);
+	v &= ~(1 << pin);
+	writel(v, GPIO0_BASE + GPIO_BLINK_EN);
+}
+
+/* HDD bays description */
+
+enum disk_state {
+	DISK_ABSENT = 0,
+	DISK_PRESENT,
+	DISK_READY,
+};
+
+struct rn104_disk_bay {
+	int gpio_detect;	/* input, active-low */
+	int gpio_power;		/* output */
+	int gpio_led;		/* output, active-low */
+	enum disk_state state;
+};
+
+#define RN104_NUM_DISK_BAYS 2
+
+static struct rn104_disk_bay rn104_bays[RN104_NUM_DISK_BAYS] = {
+	{ -1, -1, -1, DISK_ABSENT }, /* placeholder */
+};
+
+static void setup_bays(void)
+{
+	pr_info("RN104: bay management not implemented (PCA9554-based)\n");
+}
+
+static void init_disks(void)
+{
+	pr_info("RN104: disk spin-up logic not implemented\n");
+}
+
+/*
+ *  USB0 → DRAM MBUS windows
+ *
+ * frontal USB 2.0 port of RN104 is connected to the SoC usb0.
+ * Here we enable MBUS windows toward all the DRAM using
+ * informations already gathered by mvebu_mbus_dram_info().
+ *
+ * NOTE: Armada 370-XP EHCI controller shows instability when the periodic
+ * schedule is enabled.
+ */
+static void setup_usb0(void)
+{
+	writel(0x2, 0xf1051404);	/* enable force suspend */
+	u32 pwr = readl(0xf1051400);
+	pwr &= ~BIT(2);
+	writel(pwr, 0xf1051400);	/* force SUSPENDM=0 */
+}
+
+/*
+ * RN104 board driver
+ *
+ * Preferred pattern: board-specific code as a platform driver
+ * matching on the root DT node ("netgear,rn104").
+ */
+static int rn104_probe(struct device *dev)
+{
+	/* CFU configuration */
+	writel(0xC6, 0xf1020228);
+
+	setup_usb0();
+	setup_bays();
+	init_disks();
+
+	/* Barebox Update handlers */
+	bbu_register_std_file_update("bootloader", 0,
+					 "/dev/nand0.bootloader",
+					 filetype_kwbimage_v1);
+
+	bbu_register_std_file_update("kernel", 0,
+					 "/dev/nand0.kernel",
+					 filetype_arm_zimage);
+
+	bbu_register_std_file_update("minirootfs", 0,
+					 "/dev/nand0.minirootfs",
+					 filetype_gzip);
+
+	return 0;
+}
+
+static const struct of_device_id rn104_of_match[] = {
+	{ .compatible = "netgear,rn104" },
+	{ }
+};
+MODULE_DEVICE_TABLE(of, rn104_of_match);
+
+static struct driver rn104_driver = {
+	.name = "rn104",
+	.probe = rn104_probe,
+	.of_match_table = rn104_of_match,
+};
+
+coredevice_platform_driver(rn104_board_driver);
diff --git a/arch/arm/boards/netgear-rn104/lowlevel.c b/arch/arm/boards/netgear-rn104/lowlevel.c
index e693d13993..2d2c097bfc 100644
--- a/arch/arm/boards/netgear-rn104/lowlevel.c
+++ b/arch/arm/boards/netgear-rn104/lowlevel.c
@@ -1,16 +1,39 @@
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
 ENTRY_FUNCTION_MVEBU(start_netgear_rn104, r0, r1, r2)
 {
 	void *fdt;
@@ -20,5 +43,7 @@ ENTRY_FUNCTION_MVEBU(start_netgear_rn104, r0, r1, r2)
 	fdt = __dtb_armada_370_rn104_bb_start +
 		get_runtime_offset();
 
-	armada_370_xp_barebox_entry(fdt);
+	mvebu_remap_registers();
+	barebox_arm_entry(0, armada_370_xp_memory_find(), fdt);
+	// armada_370_xp_barebox_entry(fdt);
 }
diff --git a/arch/arm/dts/armada-370-rn104-bb.dts b/arch/arm/dts/armada-370-rn104-bb.dts
index b786ef350a..a2bb47ba8c 100644
--- a/arch/arm/dts/armada-370-rn104-bb.dts
+++ b/arch/arm/dts/armada-370-rn104-bb.dts
@@ -5,9 +5,78 @@
 #include "arm/marvell/armada-370-netgear-rn104.dts"
 
 / {
-	barebox,disable-deep-probe;
-
 	chosen {
 		stdout-path = &uart0;
 	};
+
+	aliases {
+		state = &state_nand;
+	};
+
+	/* configure nand partition to store barebox environment */
+	environment {
+		compatible = "barebox,environment";
+		device-path = &nand_controller, "partname:environment";
+	};
+
+	/* configure nand partition to store barebox-state backend */
+	state_nand: nand_state_memory {
+		#address-cells = <1>;
+		#size-cells = <1>;
+		compatible = "barebox,state";
+		magic = <0xab67421f>;
+		backend-type = "raw";
+		backend = <&backend_state_nand>;
+		backend-storage-type = "circular";
+		backend-stridesize = <32>;
+
+		variable@0 {
+			reg = <0x0 0x1>;
+			type = "uint8";
+			default = <0x1>;
+		};
+	};
+};
+
+&nand_controller {
+	compatible = "marvell,armada370-nand", "marvell,pxa3xx-nand";
+	status = "okay";
+
+	nand-rb = <0>;
+	marvell,nand-keep-config;
+	nand-on-flash-bbt;
+
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
+			reg = <0x0 0x400000>;
+		};
+
+		partition@400000 {
+			label = "environment";
+			reg = <0x400000 0x80000>;
+		};
+
+		backend_state_nand: partition@480000 {
+			label = "state";
+			reg = <0x480000 0x80000>;
+		};
+
+		partition@500000 {
+			label = "kernel";
+			reg = <0x500000 0x1400000>;
+		};
+
+		partition@1900000 {
+			label = "minirootfs";
+			reg = <0x1900000 0x6000000>;
+		};
+	};
 };
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

