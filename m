From: Fil Dunsky <filipp.dunsky@gmail.com>
Date: Wed, 30 Sep 2026 10:00:03 +0300
Subject: [PATCH RFC 04/10] ARM: cortina: Add support for the CS75xx SoC
 family
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260930-b4-cs75xx-v1-4-4617c4463529@gmail.com>
References: <20260930-b4-cs75xx-v1-0-4617c4463529@gmail.com>
In-Reply-To: <20260930-b4-cs75xx-v1-0-4617c4463529@gmail.com>
To: Arnd Bergmann <arnd@arndb.de>, Linus Walleij <linusw@kernel.org>, 
 Krzysztof Kozlowski <krzk@kernel.org>
Cc: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>, Russell King <linux@armlinux.org.uk>, 
 Alexandre Belloni <alexandre.belloni@bootlin.com>, 
 Drew Fustini <fustini@kernel.org>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 linux-arm-kernel@lists.infradead.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-serial@vger.kernel.org, 
 Fil Dunsky <filipp.dunsky@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790751600; l=5238;
 i=filipp.dunsky@gmail.com; s=20260930; h=from:subject:message-id;
 bh=2VKUQEfBSc+0ahjwi/i92F1YaqSibK36VZSvj1DRK5w=;
 b=fup57a2yUyKiuVJxQkaFzO0ILGqYuoWnst3gwfo+XeiwrFgtntFbeePEiIHnjxdMBiyi+dOLW
 AQc9iQY2ncEB/nKwU42xpwYMIOrMwzAvWNxp8CYz9HoYUfgbLIrhyMR
X-Developer-Key: i=filipp.dunsky@gmail.com; a=ed25519;
 pk=JAYP8e2rJ54DHOmhNtXud8rl1igAaAXoOHxtJmVXI1g=
X-Endpoint-Received: by B4 Relay for filipp.dunsky@gmail.com/20260930 with auth_id=1085
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Cortina Systems CS75xx ("Goldengate G2") are network processors
with two Cortex-A9 cores, an SCU, GIC, the Cortex-A9 global and private
timers and a PL310 L2 cache controller. The CS7542 is used, among others,
in the Securifi Almond+ router.

The generic DT machine is sufficient for the platform, so only the SMP
bring-up needs code: the bootloader parks the secondary core in a WFE
loop that polls a global software register, so boot it by writing the
physical address of secondary_startup to the register named by the
cpu-release-addr property and issuing SEV.

The CPU is a Cortex-A9 r2p1, so select the errata workarounds that apply
to that revision and can be enabled on a multiplatform kernel. The PL310
is r3p2 and needs none of the PL310 workarounds.

Signed-off-by: Fil Dunsky <filipp.dunsky@gmail.com>
---
 arch/arm/Kconfig                |  2 ++
 arch/arm/Makefile               |  1 +
 arch/arm/mach-cortina/Kconfig   | 18 +++++++++++
 arch/arm/mach-cortina/Makefile  |  2 ++
 arch/arm/mach-cortina/platsmp.c | 71 +++++++++++++++++++++++++++++++++++++++++
 5 files changed, 94 insertions(+)

diff --git a/arch/arm/Kconfig b/arch/arm/Kconfig
index 0cc289a7184..c4bfdc115ec 100644
--- a/arch/arm/Kconfig
+++ b/arch/arm/Kconfig
@@ -377,6 +377,8 @@ source "arch/arm/mach-berlin/Kconfig"
 
 source "arch/arm/mach-clps711x/Kconfig"
 
+source "arch/arm/mach-cortina/Kconfig"
+
 source "arch/arm/mach-davinci/Kconfig"
 
 source "arch/arm/mach-digicolor/Kconfig"
diff --git a/arch/arm/Makefile b/arch/arm/Makefile
index 573813ef5e7..f8a7090d047 100644
--- a/arch/arm/Makefile
+++ b/arch/arm/Makefile
@@ -181,6 +181,7 @@ machine-$(CONFIG_ARCH_AXXIA)		+= axxia
 machine-$(CONFIG_ARCH_BCM)		+= bcm
 machine-$(CONFIG_ARCH_BERLIN)		+= berlin
 machine-$(CONFIG_ARCH_CLPS711X)		+= clps711x
+machine-$(CONFIG_ARCH_CORTINA_CS75XX)	+= cortina
 machine-$(CONFIG_ARCH_DAVINCI)		+= davinci
 machine-$(CONFIG_ARCH_DIGICOLOR)	+= digicolor
 machine-$(CONFIG_ARCH_DOVE)		+= dove
diff --git a/arch/arm/mach-cortina/Kconfig b/arch/arm/mach-cortina/Kconfig
new file mode 100644
index 00000000000..9d2fc0e3de1
--- /dev/null
+++ b/arch/arm/mach-cortina/Kconfig
@@ -0,0 +1,18 @@
+# SPDX-License-Identifier: GPL-2.0-only
+config ARCH_CORTINA_CS75XX
+	bool "Cortina Systems CS75xx (Goldengate G2)"
+	depends on ARCH_MULTI_V7
+	select ARM_ERRATA_754322
+	select ARM_ERRATA_764369 if SMP
+	select ARM_GIC
+	select ARM_GLOBAL_TIMER
+	select CACHE_L2X0
+	select CLKSRC_ARM_GLOBAL_TIMER_SCHED_CLOCK
+	select HAVE_ARM_SCU if SMP
+	select HAVE_ARM_TWD if SMP
+	help
+	  Support for the Cortina Systems CS75xx (Goldengate G2) family of
+	  network processors, such as the CS7542 used in the Securifi
+	  Almond+ router. These SoCs have two Cortex-A9 cores with a PL310
+	  L2 cache controller, a packet processing engine, PCIe, NAND and
+	  the usual low speed peripherals.
diff --git a/arch/arm/mach-cortina/Makefile b/arch/arm/mach-cortina/Makefile
new file mode 100644
index 00000000000..b839201c980
--- /dev/null
+++ b/arch/arm/mach-cortina/Makefile
@@ -0,0 +1,2 @@
+# SPDX-License-Identifier: GPL-2.0-only
+obj-$(CONFIG_SMP)	+= platsmp.o
diff --git a/arch/arm/mach-cortina/platsmp.c b/arch/arm/mach-cortina/platsmp.c
new file mode 100644
index 00000000000..7cd23ee56be
--- /dev/null
+++ b/arch/arm/mach-cortina/platsmp.c
@@ -0,0 +1,71 @@
+// SPDX-License-Identifier: GPL-2.0-only
+/*
+ * SMP support for the Cortina Systems CS75xx SoCs
+ *
+ * The bootloader parks the secondary core in a WFE loop that polls a
+ * global software register and jumps to the address found there once it
+ * becomes non-zero. The register is described by the cpu-release-addr
+ * property of the secondary CPU node.
+ */
+
+#include <linux/io.h>
+#include <linux/of.h>
+#include <linux/of_address.h>
+#include <linux/smp.h>
+#include <asm/smp_plat.h>
+#include <asm/smp_scu.h>
+
+static int cs75xx_boot_secondary(unsigned int cpu, struct task_struct *idle)
+{
+	struct device_node *np;
+	void __iomem *release;
+	u64 addr;
+	int ret;
+
+	np = of_get_cpu_node(cpu, NULL);
+	if (!np)
+		return -ENODEV;
+
+	ret = of_property_read_u64(np, "cpu-release-addr", &addr);
+	of_node_put(np);
+	if (ret) {
+		pr_err("CPU%u: missing cpu-release-addr\n", cpu);
+		return ret;
+	}
+
+	release = ioremap(addr, sizeof(u32));
+	if (!release)
+		return -ENOMEM;
+
+	writel(__pa_symbol(secondary_startup), release);
+	iounmap(release);
+
+	/* The secondary core waits in WFE, wake it up */
+	dsb_sev();
+
+	return 0;
+}
+
+static void __init cs75xx_smp_prepare_cpus(unsigned int max_cpus)
+{
+	struct device_node *np;
+	void __iomem *scu_base;
+
+	np = of_find_compatible_node(NULL, NULL, "arm,cortex-a9-scu");
+	scu_base = of_iomap(np, 0);
+	of_node_put(np);
+	if (!scu_base) {
+		pr_err("failed to map SCU\n");
+		return;
+	}
+
+	scu_enable(scu_base);
+	iounmap(scu_base);
+}
+
+static const struct smp_operations cs75xx_smp_ops __initconst = {
+	.smp_prepare_cpus	= cs75xx_smp_prepare_cpus,
+	.smp_boot_secondary	= cs75xx_boot_secondary,
+};
+
+CPU_METHOD_OF_DECLARE(cs7542_smp, "cortina,cs7542-smp", &cs75xx_smp_ops);

-- 
2.53.0

