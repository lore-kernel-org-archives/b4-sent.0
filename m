From: Johan Jonker <jbx6244@gmail.com>
Date: Tue, 13 Oct 2026 18:20:49 +0200
Subject: [PATCH v2] ARM: rockchip: smp: enable secondary rk3066a/rk3188
 CPUs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261013-cpu-v2-v2-1-fe3bbc9edd33@gmail.com>
X-B4-Tracking: v=1; b=H4sIAGBazmoC/x2NQQqDMBAAvyJ7diGJGGq/Ujwk6abuwVR2qwji3
 xs9DjMwBygJk8KzOUBoY+VvqeDaBtIUyoeQ35XBGeetsR2mZcXNYfRDjtRb/7Ad1DgGJYwSSpq
 ufA76I7nEIpR5vw+v8Tz/JekG5XEAAAA=
To: Russell King <linux@armlinux.org.uk>, Heiko Stuebner <heiko@sntech.de>
Cc: linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Johan Jonker <jbx6244@gmail.com>
X-Mailer: b4 0.12.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791908467; l=7171;
 i=jbx6244@gmail.com; s=20260824; h=from:subject:message-id;
 bh=TOd8kf5U59z0fbWNbtTzfLXZRq7A+S8BMcAJBPeNlig=;
 b=FIum5UyKRKnfUX7R7ElIVsKMSnUwPji/54UVS1ZPtpJ29ldzfNAHvYJSnat4iF12xUHcV3uHG
 VFyOkHgKt2oDUNdmfvGh8i+Z2FkGLxGkqfU3TiZrnNkPobYB9ocqqGl
X-Developer-Key: i=jbx6244@gmail.com; a=ed25519;
 pk=MK5Flx1ndjAF0uwXdNm8VvvoghD4KWCNd2hQE8QGyl0=
X-Endpoint-Received: by B4 Relay for jbx6244@gmail.com/20260824 with auth_id=971
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Early Rockchip SoCs like rk3066a and rk3188 had boot loaders
that remapped the boot ROM and the internal memory. Currently
U-boot makes use of a common board file without remapping
resulting in the secondary CPUs power up hanging in a wait loop.

Make the various boot loader methods work by:

* add code that disables remapping on both rk3066 and rk3188
* change to use the same boot ROM path for all socs in rockchip_boot_secondary()
* drop the rockchip_smp_prepare_sram() part

Signed-off-by: Johan Jonker <jbx6244@gmail.com>
---
 arch/arm/mach-rockchip/Makefile  |   2 +-
 arch/arm/mach-rockchip/core.h    |  10 ----
 arch/arm/mach-rockchip/headsmp.S |  16 ------
 arch/arm/mach-rockchip/platsmp.c | 105 +++++++++++++++------------------------
 4 files changed, 42 insertions(+), 91 deletions(-)

diff --git a/arch/arm/mach-rockchip/Makefile b/arch/arm/mach-rockchip/Makefile
index 62596d5deb88..d05123a7b711 100644
--- a/arch/arm/mach-rockchip/Makefile
+++ b/arch/arm/mach-rockchip/Makefile
@@ -3,4 +3,4 @@ CFLAGS_platsmp.o := -march=armv7-a
 
 obj-$(CONFIG_ARCH_ROCKCHIP) += rockchip.o
 obj-$(CONFIG_PM_SLEEP) += pm.o sleep.o
-obj-$(CONFIG_SMP) += headsmp.o platsmp.o
+obj-$(CONFIG_SMP) += platsmp.o
diff --git a/arch/arm/mach-rockchip/core.h b/arch/arm/mach-rockchip/core.h
deleted file mode 100644
index fabcaa66607c..000000000000
--- a/arch/arm/mach-rockchip/core.h
+++ /dev/null
@@ -1,10 +0,0 @@
-/* SPDX-License-Identifier: GPL-2.0-or-later */
-/*
- * Copyright (c) 2013 MundoReader S.L.
- * Author: Heiko Stuebner <heiko@sntech.de>
- */
-
-extern char rockchip_secondary_trampoline;
-extern char rockchip_secondary_trampoline_end;
-
-extern unsigned long rockchip_boot_fn;
diff --git a/arch/arm/mach-rockchip/headsmp.S b/arch/arm/mach-rockchip/headsmp.S
deleted file mode 100644
index 37a7ea524a16..000000000000
--- a/arch/arm/mach-rockchip/headsmp.S
+++ /dev/null
@@ -1,16 +0,0 @@
-/* SPDX-License-Identifier: GPL-2.0-or-later */
-/*
- * Copyright (c) 2013 MundoReader S.L.
- * Author: Heiko Stuebner <heiko@sntech.de>
- */
-#include <linux/linkage.h>
-#include <linux/init.h>
-
-ENTRY(rockchip_secondary_trampoline)
-	ldr	pc, 1f
-ENDPROC(rockchip_secondary_trampoline)
-	.globl	rockchip_boot_fn
-rockchip_boot_fn:
-1:	.space	4
-
-ENTRY(rockchip_secondary_trampoline_end)
diff --git a/arch/arm/mach-rockchip/platsmp.c b/arch/arm/mach-rockchip/platsmp.c
index f659d894bfae..ece17e9cbaca 100644
--- a/arch/arm/mach-rockchip/platsmp.c
+++ b/arch/arm/mach-rockchip/platsmp.c
@@ -21,17 +21,21 @@
 #include <asm/smp_plat.h>
 #include <asm/mach/map.h>
 
-#include "core.h"
-
 static void __iomem *scu_base_addr;
 static void __iomem *sram_base_addr;
 static int ncores;
 
+#define RK3066_GRF_SOC_CON0	0x0150
+#define RK3188_GRF_SOC_CON0	0x00a0
+
+#define NOC_REMAP		BIT(12)
+
 #define PMU_PWRDN_CON		0x08
 #define PMU_PWRDN_ST		0x0c
 
 #define PMU_PWRDN_SCU		4
 
+static struct regmap *grf;
 static struct regmap *pmu;
 static int has_pmu = true;
 static struct reset_control *cpu_rstc[4];
@@ -133,66 +137,21 @@ static int rockchip_boot_secondary(unsigned int cpu, struct task_struct *idle)
 	if (ret < 0)
 		return ret;
 
-	if (read_cpuid_part() != ARM_CPU_PART_CORTEX_A9) {
-		/*
-		 * We communicate with the bootrom to active the cpus other
-		 * than cpu0, after a blob of initialize code, they will
-		 * stay at wfe state, once they are activated, they will check
-		 * the mailbox:
-		 * sram_base_addr + 4: 0xdeadbeaf
-		 * sram_base_addr + 8: start address for pc
-		 * The cpu0 need to wait the other cpus other than cpu0 entering
-		 * the wfe state.The wait time is affected by many aspects.
-		 * (e.g: cpu frequency, bootrom frequency, sram frequency, ...)
-		 */
-		mdelay(1); /* ensure the cpus other than cpu0 to startup */
-
-		writel(__pa_symbol(secondary_startup), sram_base_addr + 8);
-		writel(0xDEADBEAF, sram_base_addr + 4);
-		dsb_sev();
-	}
-
-	return 0;
-}
-
-/**
- * rockchip_smp_prepare_sram - populate necessary sram block
- * Starting cores execute the code residing at the start of the on-chip sram
- * after power-on. Therefore make sure, this sram region is reserved and
- * big enough. After this check, copy the trampoline code that directs the
- * core to the real startup code in ram into the sram-region.
- * @node: mmio-sram device node
- */
-static int __init rockchip_smp_prepare_sram(struct device_node *node)
-{
-	unsigned int trampoline_sz = &rockchip_secondary_trampoline_end -
-					    &rockchip_secondary_trampoline;
-	struct resource res;
-	unsigned int rsize;
-	int ret;
-
-	ret = of_address_to_resource(node, 0, &res);
-	if (ret < 0) {
-		pr_err("%s: could not get address for node %pOF\n",
-		       __func__, node);
-		return ret;
-	}
-
-	rsize = resource_size(&res);
-	if (rsize < trampoline_sz) {
-		pr_err("%s: reserved block with size 0x%x is too small for trampoline size 0x%x\n",
-		       __func__, rsize, trampoline_sz);
-		return -EINVAL;
-	}
-
-	/* set the boot function for the sram code */
-	rockchip_boot_fn = __pa_symbol(secondary_startup);
-
-	/* copy the trampoline to sram, that runs during startup of the core */
-	memcpy_toio(sram_base_addr, &rockchip_secondary_trampoline, trampoline_sz);
-	flush_cache_all();
-	outer_clean_range(0, trampoline_sz);
-
+	/*
+	* We communicate with the bootrom to active the cpus other
+	* than cpu0, after a blob of initialize code, they will
+	* stay at wfe state, once they are activated, they will check
+	* the mailbox:
+	* sram_base_addr + 4: 0xdeadbeaf
+	* sram_base_addr + 8: start address for pc
+	* The cpu0 need to wait the other cpus other than cpu0 entering
+	* the wfe state.The wait time is affected by many aspects.
+	* (e.g: cpu frequency, bootrom frequency, sram frequency, ...)
+	*/
+	mdelay(1); /* ensure the cpus other than cpu0 to startup */
+
+	writel(__pa_symbol(secondary_startup), sram_base_addr + 8);
+	writel(0xDEADBEAF, sram_base_addr + 4);
 	dsb_sev();
 
 	return 0;
@@ -320,9 +279,27 @@ static void __init rockchip_smp_prepare_cpus(unsigned int max_cpus)
 	for (i = 1; i < ncores; i++)
 		pmu_set_power_domain(0 + i, false);
 
+	/* Make sure that the remap function is disabled */
 	if (read_cpuid_part() == ARM_CPU_PART_CORTEX_A9) {
-		if (rockchip_smp_prepare_sram(node)) {
-			of_node_put(node);
+		unsigned int reg;
+		int ret;
+
+		if (of_machine_is_compatible("rockchip,rk3066a")) {
+			reg = RK3066_GRF_SOC_CON0;
+			grf = syscon_regmap_lookup_by_compatible("rockchip,rk3066-grf");
+		} else {
+			reg = RK3188_GRF_SOC_CON0;
+			grf = syscon_regmap_lookup_by_compatible("rockchip,rk3188-grf");
+		}
+
+		if (IS_ERR(grf)) {
+			pr_err("%s: could not find grf dt node\n", __func__);
+			return;
+		}
+
+		ret = regmap_update_bits(grf, reg, NOC_REMAP, 0);
+		if (ret < 0) {
+			pr_err("%s: could not update remap function\n", __func__);
 			return;
 		}
 	}

---
base-commit: 9d80aa4617b32f5054c5aa471d06b66704854935
change-id: 20261013-cpu-v2-b69fbe516813

Best regards,
-- 
Johan Jonker <jbx6244@gmail.com>

