From: Fil Dunsky <filipp.dunsky@gmail.com>
Date: Sat, 14 Nov 2026 16:41:09 +0300
Subject: [PATCH v7 04/10] ARM: goldengate: Add support for the CS75xx SoC
 family
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261114-b4-cs75xx-v7-4-8f17f38821b4@gmail.com>
References: <20261114-b4-cs75xx-v7-0-8f17f38821b4@gmail.com>
In-Reply-To: <20261114-b4-cs75xx-v7-0-8f17f38821b4@gmail.com>
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
 Jason Li <jason.li@cortina-access.com>, 
 Fil Dunsky <filipp.dunsky@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794663665; l=6100;
 i=filipp.dunsky@gmail.com; s=20260930; h=from:subject:message-id;
 bh=rWpdHlk3LciKT/N7XptR2+H0C4Am+e/uwLuWsLiX5+M=;
 b=3tuQG1F6cfsadWuV1Fku6kPlcyjgzeB/DAi55h9GJ3Cq3ROIYmJsns5BUZ9m5KCU1pgSMcKm9
 OpbO+UDVUicAo+vWNFYvEqB8Y93bifcJE9T3J0+YWjOihBEXHd86Bk3
X-Developer-Key: i=filipp.dunsky@gmail.com; a=ed25519;
 pk=JAYP8e2rJ54DHOmhNtXud8rl1igAaAXoOHxtJmVXI1g=
X-Endpoint-Received: by B4 Relay for filipp.dunsky@gmail.com/20260930 with auth_id=1085
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Cortina Systems CS75xx ("Goldengate G2") are network processors
with two Cortex-A9 cores, an SCU, GIC, the Cortex-A9 global and private
timers and a PL310 L2 cache controller. The family includes at least
the CS7522 and the CS7542; the CS7542 is used, among others, in the
Securifi Almond+ router.

Apart from the vendor this has little in common with the Cortina
Systems Gemini (SL3516/CS3516) supported by mach-gemini: Gemini is a
single ARMv4 FA526 with Faraday peripherals (FTINTC010, FTTMR010,
FTGPIO010, a 16550 UART) built for ARCH_MULTI_V4, while the CS75xx is
an ARMv7 MPCore whose UART, GPIO, interrupt controller and NAND
controller are different blocks. It therefore gets its own directory,
named after the Goldengate codename like in the vendor kernel. The
Kconfig symbol, ARCH_CORTINA_ACCESS, covers the whole family and is
named after Cortina Access, which last sold these chips and also makes
the newer 64-bit parts.

The generic DT machine is sufficient for the platform, so only the SMP
bring-up needs code: the bootloader parks the secondary core in a WFI
loop that polls a global software register, so boot it by writing the
physical address of secondary_startup to the register named by the
cpu-release-addr property and sending it a wakeup IPI.

The CPU is a Cortex-A9 r2p1, so select the errata workarounds that apply
to that revision and can be enabled on a multiplatform kernel. The PL310
is r3p1-50rel0 (CACHE_ID 0x410000c7), select the workaround for its
erratum 769419 as well.

Signed-off-by: Fil Dunsky <filipp.dunsky@gmail.com>
---
 arch/arm/Kconfig                   |  2 ++
 arch/arm/Makefile                  |  1 +
 arch/arm/mach-goldengate/Kconfig   | 19 ++++++++++
 arch/arm/mach-goldengate/Makefile  |  2 ++
 arch/arm/mach-goldengate/platsmp.c | 72 ++++++++++++++++++++++++++++++++++++++
 5 files changed, 96 insertions(+)

diff --git a/arch/arm/Kconfig b/arch/arm/Kconfig
index 0cc289a71..87ff65256 100644
--- a/arch/arm/Kconfig
+++ b/arch/arm/Kconfig
@@ -391,6 +391,8 @@ source "arch/arm/mach-footbridge/Kconfig"
 
 source "arch/arm/mach-gemini/Kconfig"
 
+source "arch/arm/mach-goldengate/Kconfig"
+
 source "arch/arm/mach-highbank/Kconfig"
 
 source "arch/arm/mach-hisi/Kconfig"
diff --git a/arch/arm/Makefile b/arch/arm/Makefile
index 573813ef5..21d7a443c 100644
--- a/arch/arm/Makefile
+++ b/arch/arm/Makefile
@@ -187,6 +187,7 @@ machine-$(CONFIG_ARCH_DOVE)		+= dove
 machine-$(CONFIG_ARCH_EXYNOS)		+= exynos
 machine-$(CONFIG_ARCH_FOOTBRIDGE)	+= footbridge
 machine-$(CONFIG_ARCH_GEMINI)		+= gemini
+machine-$(CONFIG_ARCH_CORTINA_ACCESS)	+= goldengate
 machine-$(CONFIG_ARCH_HIGHBANK)		+= highbank
 machine-$(CONFIG_ARCH_HISI)		+= hisi
 machine-$(CONFIG_ARCH_IXP4XX)		+= ixp4xx
diff --git a/arch/arm/mach-goldengate/Kconfig b/arch/arm/mach-goldengate/Kconfig
new file mode 100644
index 000000000..302e24841
--- /dev/null
+++ b/arch/arm/mach-goldengate/Kconfig
@@ -0,0 +1,19 @@
+# SPDX-License-Identifier: GPL-2.0-only
+config ARCH_CORTINA_ACCESS
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
+	select PL310_ERRATA_769419
+	help
+	  Support for the Cortina Systems CS75xx (Goldengate G2) family of
+	  network processors, such as the CS7542 used in the Securifi
+	  Almond+ router. These SoCs have two Cortex-A9 cores with a PL310
+	  L2 cache controller, a packet processing engine, PCIe, NAND and
+	  the usual low speed peripherals.
diff --git a/arch/arm/mach-goldengate/Makefile b/arch/arm/mach-goldengate/Makefile
new file mode 100644
index 000000000..b839201c9
--- /dev/null
+++ b/arch/arm/mach-goldengate/Makefile
@@ -0,0 +1,2 @@
+# SPDX-License-Identifier: GPL-2.0-only
+obj-$(CONFIG_SMP)	+= platsmp.o
diff --git a/arch/arm/mach-goldengate/platsmp.c b/arch/arm/mach-goldengate/platsmp.c
new file mode 100644
index 000000000..d9285297b
--- /dev/null
+++ b/arch/arm/mach-goldengate/platsmp.c
@@ -0,0 +1,72 @@
+// SPDX-License-Identifier: GPL-2.0-only
+/*
+ * SMP support for the Cortina Systems CS75xx SoCs
+ *
+ * The bootloader parks the secondary core in a WFI loop that polls a
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
+	/* The secondary core waits in WFI, wake it up */
+	dsb_sev();
+	arch_send_wakeup_ipi_mask(cpumask_of(cpu));
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

