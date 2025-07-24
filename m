From: Aleksa Paunovic <aleksa.paunovic@htecgroup.com>
Date: Thu, 24 Jul 2025 17:23:31 +0200
Subject: [PATCH v5 7/7] riscv: errata: Fix the PAUSE Opcode for MIPS P8700
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250724-p8700-pause-v5-7-a6cbbe1c3412@htecgroup.com>
References: <20250724-p8700-pause-v5-0-a6cbbe1c3412@htecgroup.com>
In-Reply-To: <20250724-p8700-pause-v5-0-a6cbbe1c3412@htecgroup.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Paul Walmsley <paul.walmsley@sifive.com>, 
 Palmer Dabbelt <palmer@dabbelt.com>, Albert Ou <aou@eecs.berkeley.edu>, 
 Alexandre Ghiti <alex@ghiti.fr>, Jonathan Corbet <corbet@lwn.net>
Cc: Palmer Dabbelt <palmer@sifive.com>, Conor Dooley <conor@kernel.org>, 
 Djordje Todorovic <djordje.todorovic@htecgroup.com>, 
 devicetree@vger.kernel.org, linux-riscv@lists.infradead.org, 
 linux-kernel@vger.kernel.org, linux-doc@vger.kernel.org, 
 Aleksa Paunovic <aleksa.paunovic@htecgroup.com>, 
 Aleksandar Rikalo <arikalo@gmail.com>, 
 Raj Vishwanathan4 <rvishwanathan@mips.com>, 
 Alexandre Ghiti <alexghiti@rivosinc.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1753370612; l=10604;
 i=aleksa.paunovic@htecgroup.com; s=20250514; h=from:subject:message-id;
 bh=ec9KHfCdvJydLARTt0talwBD+mHGsJuBleTVx2zquUg=;
 b=WMTAsU0dQRUaD7Gfro+7hCxjIapJvTChI4LrjtPBTO6xlAe9f5QZlQD6EiEL3wEIXQ6745sZC
 Hi0Bi+jeYMDC1Pgd9CfOCfts6ZBnYQZnqnkqJXSoG3K2S6+dcetgsrL
X-Developer-Key: i=aleksa.paunovic@htecgroup.com; a=ed25519;
 pk=gFVSVYLKAgJiS5qCnDyUMGOFuczv8C6o0UmRs+fgisA=
X-Endpoint-Received: by B4 Relay for aleksa.paunovic@htecgroup.com/20250514 with auth_id=403
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Djordje Todorovic <djordje.todorovic@htecgroup.com>

Add ERRATA_MIPS and ERRATA_MIPS_P8700_PAUSE_OPCODE configs.
Handle errata for the MIPS PAUSE instruction.

Signed-off-by: Djordje Todorovic <djordje.todorovic@htecgroup.com>
Signed-off-by: Aleksandar Rikalo <arikalo@gmail.com>
Signed-off-by: Raj Vishwanathan4 <rvishwanathan@mips.com>
Signed-off-by: Aleksa Paunovic <aleksa.paunovic@htecgroup.com>
Reviewed-by: Alexandre Ghiti <alexghiti@rivosinc.com>
---
 arch/riscv/Kconfig.errata                    | 23 ++++++++++
 arch/riscv/errata/Makefile                   |  1 +
 arch/riscv/errata/mips/Makefile              |  5 +++
 arch/riscv/errata/mips/errata.c              | 67 ++++++++++++++++++++++++++++
 arch/riscv/include/asm/alternative.h         |  3 ++
 arch/riscv/include/asm/cmpxchg.h             |  3 +-
 arch/riscv/include/asm/errata_list.h         | 13 +++++-
 arch/riscv/include/asm/errata_list_vendors.h |  5 +++
 arch/riscv/include/asm/vdso/processor.h      |  3 +-
 arch/riscv/include/asm/vendorid_list.h       |  1 +
 arch/riscv/kernel/alternative.c              |  5 +++
 arch/riscv/mm/init.c                         |  1 +
 12 files changed, 127 insertions(+), 3 deletions(-)

diff --git a/arch/riscv/Kconfig.errata b/arch/riscv/Kconfig.errata
index d2c982ba5373041a2d680f7fd5bced6d98357bdd..ac64123433e717d3cd4a6d107f1328d27297f9cc 100644
--- a/arch/riscv/Kconfig.errata
+++ b/arch/riscv/Kconfig.errata
@@ -21,6 +21,29 @@ config ERRATA_ANDES_CMO
 
 	  If you don't know what to do here, say "Y".
 
+config ERRATA_MIPS
+	bool "MIPS errata"
+	depends on RISCV_ALTERNATIVE
+	help
+	  All MIPS errata Kconfig depend on this Kconfig. Disabling
+	  this Kconfig will disable all MIPS errata. Please say "Y"
+	  here if your platform uses MIPS CPU cores.
+
+	  Otherwise, please say "N" here to avoid unnecessary overhead.
+
+config ERRATA_MIPS_P8700_PAUSE_OPCODE
+	bool "Fix the PAUSE Opcode for MIPS P8700"
+	depends on ERRATA_MIPS && 64BIT
+	default n
+	help
+	   The RISCV MIPS P8700 uses a different opcode for PAUSE.
+	   It is a 'hint' encoding of the SLLI instruction,
+	   with rd=0, rs1=0 and imm=5. It will behave as a NOP
+	   instruction if no additional behavior beyond that of
+	   SLLI is implemented.
+
+	   If you are not using the P8700 processor, say n.
+
 config ERRATA_SIFIVE
 	bool "SiFive errata"
 	depends on RISCV_ALTERNATIVE
diff --git a/arch/riscv/errata/Makefile b/arch/riscv/errata/Makefile
index bc6c77ba837d2da4c98dabab18083d27f46629c7..02a7a3335b1d557933e04cd6d0cf7bf4260b8c40 100644
--- a/arch/riscv/errata/Makefile
+++ b/arch/riscv/errata/Makefile
@@ -13,5 +13,6 @@ endif
 endif
 
 obj-$(CONFIG_ERRATA_ANDES) += andes/
+obj-$(CONFIG_ERRATA_MIPS) += mips/
 obj-$(CONFIG_ERRATA_SIFIVE) += sifive/
 obj-$(CONFIG_ERRATA_THEAD) += thead/
diff --git a/arch/riscv/errata/mips/Makefile b/arch/riscv/errata/mips/Makefile
new file mode 100644
index 0000000000000000000000000000000000000000..6278c389b801ee6e54e808c80e6e236c026329c7
--- /dev/null
+++ b/arch/riscv/errata/mips/Makefile
@@ -0,0 +1,5 @@
+ifdef CONFIG_RISCV_ALTERNATIVE_EARLY
+CFLAGS_errata.o := -mcmodel=medany
+endif
+
+obj-y += errata.o
diff --git a/arch/riscv/errata/mips/errata.c b/arch/riscv/errata/mips/errata.c
new file mode 100644
index 0000000000000000000000000000000000000000..e984a8152208c34690f89d8101571b097485c360
--- /dev/null
+++ b/arch/riscv/errata/mips/errata.c
@@ -0,0 +1,67 @@
+// SPDX-License-Identifier: GPL-2.0-only
+/*
+ * Copyright (C) 2025 MIPS.
+ */
+
+#include <linux/memory.h>
+#include <linux/module.h>
+#include <asm/text-patching.h>
+#include <asm/alternative.h>
+#include <asm/errata_list.h>
+#include <asm/vendorid_list.h>
+#include <asm/vendor_extensions.h>
+#include <asm/vendor_extensions/mips.h>
+
+static inline bool errata_probe_pause(void)
+{
+	if (!IS_ENABLED(CONFIG_ERRATA_MIPS_P8700_PAUSE_OPCODE))
+		return false;
+
+	if (!riscv_isa_vendor_extension_available(MIPS_VENDOR_ID, XMIPSEXECTL))
+		return false;
+
+	return true;
+}
+
+static u32 mips_errata_probe(void)
+{
+	u32 cpu_req_errata = 0;
+
+	if (errata_probe_pause())
+		cpu_req_errata |= BIT(ERRATA_MIPS_P8700_PAUSE_OPCODE);
+
+	return cpu_req_errata;
+}
+
+void mips_errata_patch_func(struct alt_entry *begin, struct alt_entry *end,
+			    unsigned long archid, unsigned long impid,
+			    unsigned int stage)
+{
+	struct alt_entry *alt;
+	u32 cpu_req_errata = mips_errata_probe();
+	u32 tmp;
+
+	BUILD_BUG_ON(ERRATA_MIPS_NUMBER >= RISCV_VENDOR_EXT_ALTERNATIVES_BASE);
+
+	if (stage == RISCV_ALTERNATIVES_EARLY_BOOT)
+		return;
+
+	for (alt = begin; alt < end; alt++) {
+		if (alt->vendor_id != MIPS_VENDOR_ID)
+			continue;
+
+		if (alt->patch_id >= ERRATA_MIPS_NUMBER) {
+			WARN(1, "MIPS errata id:%d not in kernel errata list\n",
+			     alt->patch_id);
+			continue;
+		}
+
+		tmp = (1U << alt->patch_id);
+		if (cpu_req_errata && tmp) {
+			mutex_lock(&text_mutex);
+			patch_text_nosync(ALT_OLD_PTR(alt), ALT_ALT_PTR(alt),
+					  alt->alt_len);
+			mutex_unlock(&text_mutex);
+		}
+	}
+}
diff --git a/arch/riscv/include/asm/alternative.h b/arch/riscv/include/asm/alternative.h
index 0e95539ba451ba55abb15ee4a26b6125c9d0261a..82eabf9a117a864a473a3c916b67bd91d1309671 100644
--- a/arch/riscv/include/asm/alternative.h
+++ b/arch/riscv/include/asm/alternative.h
@@ -48,6 +48,9 @@ struct alt_entry {
 void andes_errata_patch_func(struct alt_entry *begin, struct alt_entry *end,
 			     unsigned long archid, unsigned long impid,
 			     unsigned int stage);
+void mips_errata_patch_func(struct alt_entry *begin, struct alt_entry *end,
+			      unsigned long archid, unsigned long impid,
+			      unsigned int stage);
 void sifive_errata_patch_func(struct alt_entry *begin, struct alt_entry *end,
 			      unsigned long archid, unsigned long impid,
 			      unsigned int stage);
diff --git a/arch/riscv/include/asm/cmpxchg.h b/arch/riscv/include/asm/cmpxchg.h
index 0b749e7102162477432f7cf9a34768fbdf2e8cc7..80bd52363c68690f33bfd54e0cc40399cd60b57b 100644
--- a/arch/riscv/include/asm/cmpxchg.h
+++ b/arch/riscv/include/asm/cmpxchg.h
@@ -14,6 +14,7 @@
 #include <asm/insn-def.h>
 #include <asm/cpufeature-macros.h>
 #include <asm/processor.h>
+#include <asm/errata_list.h>
 
 #define __arch_xchg_masked(sc_sfx, swap_sfx, prepend, sc_append,		\
 			   swap_append, r, p, n)				\
@@ -438,7 +439,7 @@ static __always_inline void __cmpwait(volatile void *ptr,
 	return;
 
 no_zawrs:
-	asm volatile(RISCV_PAUSE : : : "memory");
+	ALT_RISCV_PAUSE();
 }
 
 #define __cmpwait_relaxed(ptr, val) \
diff --git a/arch/riscv/include/asm/errata_list.h b/arch/riscv/include/asm/errata_list.h
index a2481f14b68d56b3435d160793699002a45472eb..6694b5ccdcf85cfe7e767ea4de981b34f2b17b04 100644
--- a/arch/riscv/include/asm/errata_list.h
+++ b/arch/riscv/include/asm/errata_list.h
@@ -5,12 +5,12 @@
 #ifndef ASM_ERRATA_LIST_H
 #define ASM_ERRATA_LIST_H
 
-#include <asm/alternative.h>
 #include <asm/csr.h>
 #include <asm/insn-def.h>
 #include <asm/hwcap.h>
 #include <asm/vendorid_list.h>
 #include <asm/errata_list_vendors.h>
+#include <asm/vendor_extensions/mips.h>
 
 #ifdef __ASSEMBLER__
 
@@ -42,6 +42,17 @@ asm(ALTERNATIVE("sfence.vma %0, %1", "sfence.vma", SIFIVE_VENDOR_ID,	\
 		ERRATA_SIFIVE_CIP_1200, CONFIG_ERRATA_SIFIVE_CIP_1200)	\
 		: : "r" (addr), "r" (asid) : "memory")
 
+#define ALT_RISCV_PAUSE()					\
+asm(ALTERNATIVE(	\
+		RISCV_PAUSE, /* Original RISC‑V pause insn */	\
+		MIPS_PAUSE, /* Replacement for MIPS P8700 */	\
+		MIPS_VENDOR_ID, /* Vendor ID to match */	\
+		ERRATA_MIPS_P8700_PAUSE_OPCODE, /* patch_id */	\
+		CONFIG_ERRATA_MIPS_P8700_PAUSE_OPCODE)	\
+	: /* no outputs */	\
+	: /* no inputs */	\
+	: "memory")
+
 /*
  * _val is marked as "will be overwritten", so need to set it to 0
  * in the default case.
diff --git a/arch/riscv/include/asm/errata_list_vendors.h b/arch/riscv/include/asm/errata_list_vendors.h
index a7473cb8874d62b26ae5c6a2c06144b922e24efe..9739a70ed69984ba4fc5f51a4967a58c4b02613a 100644
--- a/arch/riscv/include/asm/errata_list_vendors.h
+++ b/arch/riscv/include/asm/errata_list_vendors.h
@@ -22,4 +22,9 @@
 #define	ERRATA_THEAD_NUMBER 4
 #endif
 
+#ifdef CONFIG_ERRATA_MIPS
+#define	ERRATA_MIPS_P8700_PAUSE_OPCODE 0
+#define	ERRATA_MIPS_NUMBER 1
+#endif
+
 #endif
diff --git a/arch/riscv/include/asm/vdso/processor.h b/arch/riscv/include/asm/vdso/processor.h
index 98fb44336c055f1c60899cb25c99f2416184c466..c42f95dc8811d8a949898f7338151dcc4e987372 100644
--- a/arch/riscv/include/asm/vdso/processor.h
+++ b/arch/riscv/include/asm/vdso/processor.h
@@ -5,6 +5,7 @@
 #ifndef __ASSEMBLER__
 
 #include <asm/barrier.h>
+#include <asm/errata_list.h>
 #include <asm/insn-def.h>
 
 static inline void cpu_relax(void)
@@ -19,7 +20,7 @@ static inline void cpu_relax(void)
 	 * Reduce instruction retirement.
 	 * This assumes the PC changes.
 	 */
-	__asm__ __volatile__ (RISCV_PAUSE);
+	ALT_RISCV_PAUSE();
 	barrier();
 }
 
diff --git a/arch/riscv/include/asm/vendorid_list.h b/arch/riscv/include/asm/vendorid_list.h
index a5150cdf34d87f01baf6d3ef843bc2d6d8d54095..3b09874d7a6dfb8f8aa45b0be41c20711d539e78 100644
--- a/arch/riscv/include/asm/vendorid_list.h
+++ b/arch/riscv/include/asm/vendorid_list.h
@@ -9,5 +9,6 @@
 #define MICROCHIP_VENDOR_ID	0x029
 #define SIFIVE_VENDOR_ID	0x489
 #define THEAD_VENDOR_ID		0x5b7
+#define MIPS_VENDOR_ID		0x722
 
 #endif
diff --git a/arch/riscv/kernel/alternative.c b/arch/riscv/kernel/alternative.c
index 7eb3cb1215c62130c63a72fc650cddff6bae62af..7642704c7f1841f67fc23738063f22b4ecf58194 100644
--- a/arch/riscv/kernel/alternative.c
+++ b/arch/riscv/kernel/alternative.c
@@ -47,6 +47,11 @@ static void riscv_fill_cpu_mfr_info(struct cpu_manufacturer_info_t *cpu_mfr_info
 		cpu_mfr_info->patch_func = andes_errata_patch_func;
 		break;
 #endif
+#ifdef CONFIG_ERRATA_MIPS
+	case MIPS_VENDOR_ID:
+		cpu_mfr_info->patch_func = mips_errata_patch_func;
+		break;
+#endif
 #ifdef CONFIG_ERRATA_SIFIVE
 	case SIFIVE_VENDOR_ID:
 		cpu_mfr_info->patch_func = sifive_errata_patch_func;
diff --git a/arch/riscv/mm/init.c b/arch/riscv/mm/init.c
index 8d0374d7ce8ed72320f58e4cea212d0e2bce8fd4..3c2293bdfbccfde21c44497504c66fc4017f45a9 100644
--- a/arch/riscv/mm/init.c
+++ b/arch/riscv/mm/init.c
@@ -23,6 +23,7 @@
 #include <linux/kfence.h>
 #include <linux/execmem.h>
 
+#include <asm/alternative.h>
 #include <asm/fixmap.h>
 #include <asm/io.h>
 #include <asm/kasan.h>

-- 
2.34.1

