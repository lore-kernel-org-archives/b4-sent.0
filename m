From: Aleksa Paunovic <aleksa.paunovic@htecgroup.com>
Date: Wed, 24 Sep 2025 13:10:38 +0200
Subject: [PATCH RESEND v6 2/2] riscv: Allow for riscv-clock to pick up mmio
 address.
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250924-riscv-time-mmio-v6-2-9c6158a14b37@htecgroup.com>
References: <20250924-riscv-time-mmio-v6-0-9c6158a14b37@htecgroup.com>
In-Reply-To: <20250924-riscv-time-mmio-v6-0-9c6158a14b37@htecgroup.com>
To: Daniel Lezcano <daniel.lezcano@linaro.org>, 
 Thomas Gleixner <tglx@linutronix.de>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Paul Walmsley <paul.walmsley@sifive.com>, 
 Palmer Dabbelt <palmer@dabbelt.com>, Albert Ou <aou@eecs.berkeley.edu>, 
 Alexandre Ghiti <alex@ghiti.fr>
Cc: linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-riscv@lists.infradead.org, 
 Djordje Todorovic <djordje.todorovic@htecgroup.com>, 
 Aleksa Paunovic <aleksa.paunovic@htecgroup.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1758712265; l=9241;
 i=aleksa.paunovic@htecgroup.com; s=20250806; h=from:subject:message-id;
 bh=UCk+odaPh5M8tm0gjN0a88ikEvJbr/kzBQOSfhNUx/o=;
 b=513/kOpE5RfkSTU3FeP2yy48aEa2nICQcg8IXvREOUURfH3MZTi0+pq9K+NR+lT2SfPADIdcV
 RR3qGBJd9u0AJr9TNzEjY/jNYZPdkPbJsVZ2XAv1qO3Fdk5oXI/5TIS
X-Developer-Key: i=aleksa.paunovic@htecgroup.com; a=ed25519;
 pk=Dn4KMnDdgyhlXJNspQQrlHJ04i7/irG29p2H27Avd+8=
X-Endpoint-Received: by B4 Relay for aleksa.paunovic@htecgroup.com/20250806 with auth_id=476
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Allow faster rdtime access via GCR.U mtime shadow register on RISC-V
devices. This feature can be enabled by setting GCRU_TIME_MMIO
during configuration.
Reformat the clint timer to use the same mechanism if RISCV_M_MODE is set.

Signed-off-by: Aleksa Paunovic <aleksa.paunovic@htecgroup.com>
---
 arch/riscv/include/asm/clint.h    | 26 ----------------
 arch/riscv/include/asm/timex.h    | 63 ++++++++++++++++++++++-----------------
 drivers/clocksource/Kconfig       | 12 ++++++++
 drivers/clocksource/timer-clint.c | 20 ++++++-------
 drivers/clocksource/timer-riscv.c | 34 +++++++++++++++++++++
 5 files changed, 90 insertions(+), 65 deletions(-)

diff --git a/arch/riscv/include/asm/clint.h b/arch/riscv/include/asm/clint.h
deleted file mode 100644
index 0789fd37b40ae06a11f0b5cc0f01dba591b4cf16..0000000000000000000000000000000000000000
--- a/arch/riscv/include/asm/clint.h
+++ /dev/null
@@ -1,26 +0,0 @@
-/* SPDX-License-Identifier: GPL-2.0-only */
-/*
- * Copyright (C) 2020 Google, Inc
- */
-
-#ifndef _ASM_RISCV_CLINT_H
-#define _ASM_RISCV_CLINT_H
-
-#include <linux/types.h>
-#include <asm/mmio.h>
-
-#ifdef CONFIG_RISCV_M_MODE
-/*
- * This lives in the CLINT driver, but is accessed directly by timex.h to avoid
- * any overhead when accessing the MMIO timer.
- *
- * The ISA defines mtime as a 64-bit memory-mapped register that increments at
- * a constant frequency, but it doesn't define some other constraints we depend
- * on (most notably ordering constraints, but also some simpler stuff like the
- * memory layout).  Thus, this is called "clint_time_val" instead of something
- * like "riscv_mtime", to signify that these non-ISA assumptions must hold.
- */
-extern u64 __iomem *clint_time_val;
-#endif
-
-#endif
diff --git a/arch/riscv/include/asm/timex.h b/arch/riscv/include/asm/timex.h
index a06697846e69521caceac2ae4d4e040d227d2ae7..fc8e18ad628e6d68bf9703688f42e76e1cd45559 100644
--- a/arch/riscv/include/asm/timex.h
+++ b/arch/riscv/include/asm/timex.h
@@ -7,31 +7,25 @@
 #define _ASM_RISCV_TIMEX_H
 
 #include <asm/csr.h>
+#include <asm/mmio.h>
+
+#include <linux/jump_label.h>
 
 typedef unsigned long cycles_t;
 
-#ifdef CONFIG_RISCV_M_MODE
+/*
+ * Used for directly accessing MMIO timers. For now
+ * this includes the M-mode clint timer and the GCR.U mtime shadow copy.
+ */
+extern u64 __iomem *riscv_time_val;
 
-#include <asm/clint.h>
+extern cycles_t (*get_cycles_ptr)(void);
+extern u32 (*get_cycles_hi_ptr)(void);
 
-#ifdef CONFIG_64BIT
-static inline cycles_t get_cycles(void)
-{
-	return readq_relaxed(clint_time_val);
-}
-#else /* !CONFIG_64BIT */
-static inline u32 get_cycles(void)
-{
-	return readl_relaxed(((u32 *)clint_time_val));
-}
-#define get_cycles get_cycles
+#define get_cycles get_cycles_ptr
+#define get_cycles_hi get_cycles_hi_ptr
 
-static inline u32 get_cycles_hi(void)
-{
-	return readl_relaxed(((u32 *)clint_time_val) + 1);
-}
-#define get_cycles_hi get_cycles_hi
-#endif /* CONFIG_64BIT */
+#ifdef CONFIG_RISCV_M_MODE
 
 /*
  * Much like MIPS, we may not have a viable counter to use at an early point
@@ -40,34 +34,47 @@ static inline u32 get_cycles_hi(void)
  */
 static inline unsigned long random_get_entropy(void)
 {
-	if (unlikely(clint_time_val == NULL))
+	if (unlikely(riscv_time_val == NULL))
 		return random_get_entropy_fallback();
 	return get_cycles();
 }
+
 #define random_get_entropy()	random_get_entropy()
+#endif
 
-#else /* CONFIG_RISCV_M_MODE */
+#ifdef CONFIG_64BIT
+static inline cycles_t __maybe_unused mmio_get_cycles(void)
+{
+	return readq_relaxed(riscv_time_val);
+}
+#else /* !CONFIG_64BIT */
+static inline cycles_t __maybe_unused mmio_get_cycles(void)
+{
+	return readl_relaxed(((u32 __iomem *)riscv_time_val));
+}
+#endif /* CONFIG_64BIT */
 
-static inline cycles_t get_cycles(void)
+static inline cycles_t __maybe_unused get_cycles_csr(void)
 {
 	return csr_read(CSR_TIME);
 }
-#define get_cycles get_cycles
 
-static inline u32 get_cycles_hi(void)
+static inline u32 __maybe_unused mmio_get_cycles_hi(void)
 {
-	return csr_read(CSR_TIMEH);
+	return readl_relaxed(((u32 __iomem *)riscv_time_val) + 1);
 }
-#define get_cycles_hi get_cycles_hi
 
-#endif /* !CONFIG_RISCV_M_MODE */
+static inline u32 __maybe_unused get_cycles_hi_csr(void)
+{
+	return csr_read(CSR_TIMEH);
+}
 
 #ifdef CONFIG_64BIT
 static inline u64 get_cycles64(void)
 {
 	return get_cycles();
 }
-#else /* CONFIG_64BIT */
+#else /* !CONFIG_64BIT */
 static inline u64 get_cycles64(void)
 {
 	u32 hi, lo;
diff --git a/drivers/clocksource/Kconfig b/drivers/clocksource/Kconfig
index 645f517a1ac26d0c12d4b2b46591321ddf6e20b3..fbe4d0d6183ea24f557ce692b8c18e88dcf58155 100644
--- a/drivers/clocksource/Kconfig
+++ b/drivers/clocksource/Kconfig
@@ -669,6 +669,18 @@ config CLINT_TIMER
 	  This option enables the CLINT timer for RISC-V systems.  The CLINT
 	  driver is usually used for NoMMU RISC-V systems.
 
+config GCRU_TIME_MMIO
+	bool "GCR.U timer support for RISC-V platforms"
+	depends on !RISCV_M_MODE && RISCV && RISCV_TIMER
+	default n
+	help
+        Access GCR.U shadow copy of the RISC-V mtime register
+        on platforms that provide a compatible device, instead of
+        reading the time CSR. Since reading the time CSR
+        traps to M mode on certain platforms, this may be more efficient.
+
+        If you don't know what to do here, say n.
+
 config CSKY_MP_TIMER
 	bool "SMP Timer for the C-SKY platform" if COMPILE_TEST
 	depends on CSKY
diff --git a/drivers/clocksource/timer-clint.c b/drivers/clocksource/timer-clint.c
index 0bdd9d7ec545839109cf82ad36632889f5b2d2ef..d6ab794741a6b59227827323017a7e6ff830963c 100644
--- a/drivers/clocksource/timer-clint.c
+++ b/drivers/clocksource/timer-clint.c
@@ -24,10 +24,6 @@
 #include <linux/smp.h>
 #include <linux/timex.h>
 
-#ifndef CONFIG_RISCV_M_MODE
-#include <asm/clint.h>
-#endif
-
 #define CLINT_IPI_OFF		0
 #define CLINT_TIMER_CMP_OFF	0x4000
 #define CLINT_TIMER_VAL_OFF	0xbff8
@@ -41,8 +37,14 @@ static unsigned long clint_timer_freq;
 static unsigned int clint_timer_irq;
 
 #ifdef CONFIG_RISCV_M_MODE
-u64 __iomem *clint_time_val;
-EXPORT_SYMBOL(clint_time_val);
+u64 __iomem *riscv_time_val __ro_after_init;
+EXPORT_SYMBOL(riscv_time_val);
+
+cycles_t (*get_cycles_ptr)(void) = mmio_get_cycles;
+EXPORT_SYMBOL(get_cycles_ptr);
+
+u32 (*get_cycles_hi_ptr)(void) = mmio_get_cycles_hi;
+EXPORT_SYMBOL(get_cycles_hi_ptr);
 #endif
 
 #ifdef CONFIG_SMP
@@ -218,11 +220,7 @@ static int __init clint_timer_init_dt(struct device_node *np)
 	clint_timer_freq = riscv_timebase;
 
 #ifdef CONFIG_RISCV_M_MODE
-	/*
-	 * Yes, that's an odd naming scheme.  time_val is public, but hopefully
-	 * will die in favor of something cleaner.
-	 */
-	clint_time_val = clint_timer_val;
+	riscv_time_val = clint_timer_val;
 #endif
 
 	pr_info("%pOFP: timer running at %ld Hz\n", np, clint_timer_freq);
diff --git a/drivers/clocksource/timer-riscv.c b/drivers/clocksource/timer-riscv.c
index 4d7cf338824a3b21461c2756a002236dedc48f5f..dcef6f2afd382711559326c419e09630386df7e2 100644
--- a/drivers/clocksource/timer-riscv.c
+++ b/drivers/clocksource/timer-riscv.c
@@ -22,6 +22,7 @@
 #include <linux/io-64-nonatomic-lo-hi.h>
 #include <linux/interrupt.h>
 #include <linux/of_irq.h>
+#include <linux/of_address.h>
 #include <linux/limits.h>
 #include <clocksource/timer-riscv.h>
 #include <asm/smp.h>
@@ -32,6 +33,15 @@
 static DEFINE_STATIC_KEY_FALSE(riscv_sstc_available);
 static bool riscv_timer_cannot_wake_cpu;
 
+u64 __iomem *riscv_time_val __ro_after_init;
+EXPORT_SYMBOL(riscv_time_val);
+
+cycles_t (*get_cycles_ptr)(void) = get_cycles_csr;
+EXPORT_SYMBOL(get_cycles_ptr);
+
+u32 (*get_cycles_hi_ptr)(void) = get_cycles_hi_csr;
+EXPORT_SYMBOL(get_cycles_hi_ptr);
+
 static void riscv_clock_event_stop(void)
 {
 	if (static_branch_likely(&riscv_sstc_available)) {
@@ -209,6 +219,11 @@ static int __init riscv_timer_init_dt(struct device_node *n)
 	int cpuid, error;
 	unsigned long hartid;
 	struct device_node *child;
+#if defined(CONFIG_GCRU_TIME_MMIO)
+	u64 mmio_addr;
+	u64 mmio_size;
+	struct device_node *gcru;
+#endif
 
 	error = riscv_of_processor_hartid(n, &hartid);
 	if (error < 0) {
@@ -226,6 +241,25 @@ static int __init riscv_timer_init_dt(struct device_node *n)
 	if (cpuid != smp_processor_id())
 		return 0;
 
+#if defined(CONFIG_GCRU_TIME_MMIO)
+	gcru = of_find_compatible_node(NULL, NULL, "mips,p8700-gcru");
+	if (gcru) {
+		if (!of_property_read_reg(gcru, 0, &mmio_addr, &mmio_size)) {
+			riscv_time_val = ioremap((long)mmio_addr, mmio_size);
+			if (riscv_time_val) {
+				pr_info("Using mmio time register at 0x%llx\n",
+					mmio_addr);
+				get_cycles_ptr = &mmio_get_cycles;
+				get_cycles_hi_ptr = &mmio_get_cycles_hi;
+			} else {
+				pr_warn("Unable to use mmio time at 0x%llx\n",
+					mmio_addr);
+			}
+			of_node_put(gcru);
+		}
+	}
+#endif
+
 	child = of_find_compatible_node(NULL, NULL, "riscv,timer");
 	if (child) {
 		riscv_timer_cannot_wake_cpu = of_property_read_bool(child,

-- 
2.43.0

