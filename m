From: Luca Lauro <famlauro93l@gmail.com>
Date: Sun, 02 Aug 2026 15:16:17 +0200
Subject: [PATCH v3 01/15] ARM: mvebu: add Netgear RN102 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260802-rn102-rn104-series-v3-1-f7685a279fb5@gmail.com>
References: <20260802-rn102-rn104-series-v3-0-f7685a279fb5@gmail.com>
In-Reply-To: <20260802-rn102-rn104-series-v3-0-f7685a279fb5@gmail.com>
To: Sascha Hauer <s.hauer@pengutronix.de>, 
 "open list:BAREBOX" <barebox@lists.infradead.org>
Cc: Luca Lauro <famlauro93l@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785676613; l=14270;
 i=famlauro93l@gmail.com; s=20260723; h=from:subject:message-id;
 bh=X/+jFLZh2E5+EH6zg5sljVPI/gw/u0/KNOJJ3jxC5kc=;
 b=aBzav8lr+fpMJ37Bcir5aT1BzlVFsC5wAA8JXw1bSDdCeasy7xWeYVAKhQFgP0jYmIbj460Vm
 GZDDWAEyRLDDzgCtqqroqReWqMobC7p3G9eqzS49AdApg+xujT/vRlj
X-Developer-Key: i=famlauro93l@gmail.com; a=ed25519;
 pk=OAJlcD69ugQCl99Vy6w+Aeu+ZUb1IVGcz1Ijxo6Ch78=
X-Endpoint-Received: by B4 Relay for famlauro93l@gmail.com/20260723 with auth_id=892
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This adds full support for the Netgear ReadyNAS 102, including:

 - board driver matching on "netgear,rn102"
 - lowlevel initialization
 - barebox overlay with environment, state backend and
	NAND partition layout
 - Kconfig entry
 - image support

Signed-off-by: Luca Lauro <famlauro93l@gmail.com>
---
 arch/arm/boards/Makefile                 |   1 +
 arch/arm/boards/netgear-rn102/Makefile   |   4 +
 arch/arm/boards/netgear-rn102/board.c    | 243 +++++++++++++++++++++++++++++++
 arch/arm/boards/netgear-rn102/lowlevel.c |  58 ++++++++
 arch/arm/dts/Makefile                    |   1 +
 arch/arm/dts/armada-370-rn102-bb.dts     |  82 +++++++++++
 arch/arm/mach-mvebu/Kconfig              |   4 +
 images/Makefile.mvebu                    |  10 ++
 8 files changed, 403 insertions(+)

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
index 0000000000..dba3d11518
--- /dev/null
+++ b/arch/arm/boards/netgear-rn102/board.c
@@ -0,0 +1,243 @@
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
+ *  Early GPIO0 MMIO
+ *
+ * GPIO driver arrives too late for the disks to be
+ * ready in time for AHCI driver probe.
+ * So we use GPIO0 direct access for:
+ *   - reading disk presence monitoring pins
+ *   - enable powerup for bays that detect disk presence
+ *   - display bay status with dedicated LEDs
+ */
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
+struct rn102_disk_bay {
+	int gpio_detect;		/* input, active-low */
+	int gpio_power;		 	/* output */
+	int gpio_led;		   	/* output, active-low */
+	enum disk_state state;
+};
+
+#define RN102_NUM_DISK_BAYS 2
+
+static struct rn102_disk_bay rn102_bays[RN102_NUM_DISK_BAYS] = {
+	{ 12, 13, 15, DISK_ABSENT }, /* Bay 1, default to disk absent */
+	{ 10, 11, 14, DISK_ABSENT }, /* Bay 2, default to disk absent */
+};
+
+static void setup_bays(void)
+{
+	pr_info("Early disk power-on...\n");
+
+	for (int i = 0; i < RN102_NUM_DISK_BAYS; i++) {
+		int present;
+
+		gpio0_set_input(rn102_bays[i].gpio_detect);
+		present = (gpio0_read(rn102_bays[i].gpio_detect) == 0);
+
+		gpio0_set_output(rn102_bays[i].gpio_power);
+
+		if (present) {
+			pr_info("Bay %d: disk detected, powering on\n", i + 1);
+			gpio0_blink(rn102_bays[i].gpio_led, 500, 500);
+			gpio0_write(rn102_bays[i].gpio_power, 1);
+			rn102_bays[i].state = DISK_PRESENT;
+		} else {
+			pr_info("Bay %d empty\n", i + 1);
+			gpio0_write(rn102_bays[i].gpio_led, 0);
+			gpio0_write(rn102_bays[i].gpio_power, 0);
+			rn102_bays[i].state = DISK_ABSENT;
+		}
+	}
+}
+
+/*
+ * After waiting for present disks spinup,
+ * we ask explicitly for corresponding ATA devices probe.
+ */
+static void init_disks(void)
+{
+	pr_info("Waiting for disks spinup...\n");
+	mdelay(8000);
+
+	pr_info("Detecting ATA devices:\n");
+	for (int i = 0; i < RN102_NUM_DISK_BAYS; i++) {
+		char name[8];
+		struct device *dev;
+
+		if (rn102_bays[i].state != DISK_PRESENT) {
+			gpio0_write(rn102_bays[i].gpio_power, 0);
+			gpio0_blink_disable(rn102_bays[i].gpio_led);
+			gpio0_write(rn102_bays[i].gpio_led, 0);
+			continue;
+		}
+
+		snprintf(name, sizeof(name), "ata%d", i);
+
+		dev = get_device_by_name(name);
+		if (!dev) {
+			pr_warn("%s not found\n", name);
+			gpio0_write(rn102_bays[i].gpio_power, 0);
+			gpio0_blink(rn102_bays[i].gpio_led, 1000, 1000);
+			continue;
+		}
+
+		pr_info("Connecting %s to disk %d\n", name, i + 1);
+		device_detect(dev);
+		gpio0_blink_disable(rn102_bays[i].gpio_led);
+		gpio0_write(rn102_bays[i].gpio_led, 1);
+		rn102_bays[i].state = DISK_READY;
+	}
+}
+
+/*
+ *  USB0 → DRAM MBUS windows
+ *
+ * frontal USB 2.0 port of RN102 is connected to the SoC usb0.
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
+ * RN102 board driver
+ *
+ * Preferred pattern: board-specific code as a platform driver
+ * matching on the root DT node ("netgear,rn102").
+ */
+static int rn102_probe(struct device *dev)
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
+static const struct of_device_id rn102_of_match[] = {
+	{ .compatible = "netgear,rn102" },
+	{ }
+};
+MODULE_DEVICE_TABLE(of, rn102_of_match);
+
+static struct driver rn102_driver = {
+	.name = "rn102",
+	.probe = rn102_probe,
+	.of_match_table = rn102_of_match,
+};
+
+device_platform_driver(rn102_driver);
diff --git a/arch/arm/boards/netgear-rn102/lowlevel.c b/arch/arm/boards/netgear-rn102/lowlevel.c
new file mode 100644
index 0000000000..c1680cee82
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
+	void *fdt;
+
+	arm_cpu_lowlevel_init();
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
index 0000000000..47064cb11a
--- /dev/null
+++ b/arch/arm/dts/armada-370-rn102-bb.dts
@@ -0,0 +1,82 @@
+/*
+ * Barebox specific DT overlay for Netgear ReadyNAS 102
+ */
+
+#include "arm/marvell/armada-370-netgear-rn102.dts"
+
+/ {
+	chosen {
+		stdout-path = &uart0;
+	};
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

