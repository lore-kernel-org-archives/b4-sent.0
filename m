From: Aleksa Paunovic <aleksa.paunovic@htecgroup.com>
Date: Mon, 08 Jun 2026 16:41:01 +0200
Subject: [PATCH v2] riscv: Add ERRATA_MIPS_P8700_WFI to replace WFI with
 mips.pause
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260608-p8700-wfi-v2-1-77efc7459f3d@htecgroup.com>
X-B4-Tracking: v=1; b=H4sIAHzUJmoC/03Myw6CMBCF4Vchs3bMTBW5rHwPw0JLC7OQNi2ih
 vTdrbhx+Z+cfCtEE8REaIsVglkkiptyqF0BerxOg0Hpc4MidaIjl+jrigifVrCh+nDjvq56pSD
 /fTBWXpt16XKPEmcX3hu98Hf9KSXzn7IwMlLTZInJaqvO42z0ENzD77W7Q5dS+gAFwGdrpgAAA
 A==
X-Change-ID: 20260415-p8700-wfi-9083b1d87d22
To: Paul Walmsley <pjw@kernel.org>, Palmer Dabbelt <palmer@dabbelt.com>, 
 Albert Ou <aou@eecs.berkeley.edu>, Alexandre Ghiti <alex@ghiti.fr>, 
 "Maciej W. Rozycki" <macro@orcam.me.uk>
Cc: linux-riscv@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Djordje Todorovic <djordje.todorovic@htecgroup.com>, 
 Aleksa Paunovic <aleksa.paunovic@htecgroup.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780929704; l=7253;
 i=aleksa.paunovic@htecgroup.com; s=20250806; h=from:subject:message-id;
 bh=zCLTb5HA1rPpJ7SrjtUrP3jfqZwsfTac3qvc6g6eOQQ=;
 b=y1Yu6d9m1SdDDrmVFZ9o3L5SDPWoHd0m2WvoeNbwEVkihtYG7YySZnEDGimY9Mkp+vGLvGHWS
 Ig0PAg6GtGzD4UyAs1+hIB0kqcO/UeO+Shw0sNh7VO+grXfhqJiNCo+
X-Developer-Key: i=aleksa.paunovic@htecgroup.com; a=ed25519;
 pk=Dn4KMnDdgyhlXJNspQQrlHJ04i7/irG29p2H27Avd+8=
X-Endpoint-Received: by B4 Relay for aleksa.paunovic@htecgroup.com/20250806 with auth_id=476
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Djordje Todorovic <djordje.todorovic@htecgroup.com>

The MIPS P8700 has bugs with the WFI instruction. This errata
uses the RISC-V alternatives framework to patch all WFI
instructions with the MIPS P8700 pause opcode (0x00501013)
at runtime when running on P8700 hardware.

Two call sites are patched:
 - arch/riscv/kernel/head.S: secondary hart parking loop
 - arch/riscv/include/asm/processor.h: wait_for_interrupt()

Signed-off-by: Djordje Todorovic <djordje.todorovic@htecgroup.com>
Signed-off-by: Aleksa Paunovic <aleksa.paunovic@htecgroup.com>
---
This patch was tested on QEMU configured with eight P8700 harts,
as well as on the MIPS Boston board, configured with a single P8700 CPU.
Errata application was tested by disassembling with GDB on QEMU
and inserting an illegal instruction on the Boston board.
Correctness was tested with a combination of kselftests
and torture tests (rcu, locktorture), along with coremark testing.
---
Changes in v2:
- Replace .insn with .4byte in ALT_WFI macro
- Add explanatory comments
- Link to v1: https://lore.kernel.org/r/20260511-p8700-wfi-v1-1-099b1d10fcf2@htecgroup.com
---
 arch/riscv/Kconfig.errata                    | 11 ++++++++++
 arch/riscv/errata/mips/errata.c              | 14 ++++++++++++
 arch/riscv/include/asm/errata_list.h         | 33 ++++++++++++++++++++++++++++
 arch/riscv/include/asm/errata_list_vendors.h |  5 +++--
 arch/riscv/include/asm/processor.h           |  3 ++-
 arch/riscv/kernel/head.S                     |  4 +++-
 6 files changed, 66 insertions(+), 4 deletions(-)

diff --git a/arch/riscv/Kconfig.errata b/arch/riscv/Kconfig.errata
index 3c945d086c7d0266b685f9506d58b0662af071c4..cc75e6f70513d08afeedf650b14dba83eea84632 100644
--- a/arch/riscv/Kconfig.errata
+++ b/arch/riscv/Kconfig.errata
@@ -44,6 +44,17 @@ config ERRATA_MIPS_P8700_PAUSE_OPCODE
 
 	   If you are not using the P8700 processor, say n.
 
+config ERRATA_MIPS_P8700_WFI
+	bool "Replace WFI with mips.pause for MIPS P8700"
+	depends on ERRATA_MIPS && 64BIT
+	default n
+	help
+	   The RISCV MIPS P8700 has bugs with the WFI instruction.
+	   This errata replaces all WFI instructions with the MIPS
+	   P8700 pause opcode to avoid these issues.
+
+	   If you are not using the P8700 processor, say n.
+
 config ERRATA_SIFIVE
 	bool "SiFive errata"
 	depends on RISCV_ALTERNATIVE
diff --git a/arch/riscv/errata/mips/errata.c b/arch/riscv/errata/mips/errata.c
index e984a8152208c34690f89d8101571b097485c360..67b59f8c1708ea8b7a040f7939e111b8f30e6a75 100644
--- a/arch/riscv/errata/mips/errata.c
+++ b/arch/riscv/errata/mips/errata.c
@@ -23,6 +23,17 @@ static inline bool errata_probe_pause(void)
 	return true;
 }
 
+static inline bool errata_probe_wfi(void)
+{
+	if (!IS_ENABLED(CONFIG_ERRATA_MIPS_P8700_WFI))
+		return false;
+
+	if (!riscv_isa_vendor_extension_available(MIPS_VENDOR_ID, XMIPSEXECTL))
+		return false;
+
+	return true;
+}
+
 static u32 mips_errata_probe(void)
 {
 	u32 cpu_req_errata = 0;
@@ -30,6 +41,9 @@ static u32 mips_errata_probe(void)
 	if (errata_probe_pause())
 		cpu_req_errata |= BIT(ERRATA_MIPS_P8700_PAUSE_OPCODE);
 
+	if (errata_probe_wfi())
+		cpu_req_errata |= BIT(ERRATA_MIPS_P8700_WFI);
+
 	return cpu_req_errata;
 }
 
diff --git a/arch/riscv/include/asm/errata_list.h b/arch/riscv/include/asm/errata_list.h
index 6694b5ccdcf85cfe7e767ea4de981b34f2b17b04..5c936882c42a90bac2bf40369a795d067a86d31d 100644
--- a/arch/riscv/include/asm/errata_list.h
+++ b/arch/riscv/include/asm/errata_list.h
@@ -25,6 +25,16 @@ ALTERNATIVE(__stringify(RISCV_PTR do_page_fault),			\
 	    __stringify(RISCV_PTR sifive_cip_453_page_fault_trp),	\
 	    SIFIVE_VENDOR_ID, ERRATA_SIFIVE_CIP_453,			\
 	    CONFIG_ERRATA_SIFIVE_CIP_453)
+
+#ifdef CONFIG_ERRATA_MIPS_P8700_WFI
+#define ALT_WFI								\
+ALTERNATIVE("wfi; .rept 7; nop; .endr;",				\
+	".rept 8; .4byte 0x00501013; .endr;", MIPS_VENDOR_ID,		\
+	ERRATA_MIPS_P8700_WFI, CONFIG_ERRATA_MIPS_P8700_WFI)
+#else
+#define ALT_WFI	wfi
+#endif
+
 #else /* !__ASSEMBLER__ */
 
 #define ALT_SFENCE_VMA_ASID(asid)					\
@@ -53,6 +63,29 @@ asm(ALTERNATIVE(	\
 	: /* no inputs */	\
 	: "memory")
 
+#ifdef CONFIG_ERRATA_MIPS_P8700_WFI
+/*
+ * A WFI instruction after a mispredicted branch can result in erroneous address translation
+ * on the MIPS P8700.
+ * The number of MIPS_PAUSE instructions required was determined by measuring
+ * Coremark performance on a one-core, two-hart configuration.
+ */
+#define ALT_RISCV_WFI()										\
+asm volatile(ALTERNATIVE(									\
+		"wfi\n" /* Original RISC-V wfi insn */						\
+		__nops(7),									\
+		".rept 8;" MIPS_PAUSE ".endr;\n", /* Replacement: mips.pause for P8700 */	\
+		MIPS_VENDOR_ID, /* Vendor ID to match */					\
+		ERRATA_MIPS_P8700_WFI, /* patch_id */						\
+		CONFIG_ERRATA_MIPS_P8700_WFI)							\
+		: /* no outputs */								\
+		: /* no inputs */								\
+		: "memory")
+#else
+#define ALT_RISCV_WFI()		\
+	__asm__ __volatile__ ("wfi")
+#endif
+
 /*
  * _val is marked as "will be overwritten", so need to set it to 0
  * in the default case.
diff --git a/arch/riscv/include/asm/errata_list_vendors.h b/arch/riscv/include/asm/errata_list_vendors.h
index ec7eba3734371a2d8b68fbd4cbd88a8e7135a413..4505317a6b949be602f507547fc9cd495c923e32 100644
--- a/arch/riscv/include/asm/errata_list_vendors.h
+++ b/arch/riscv/include/asm/errata_list_vendors.h
@@ -22,8 +22,9 @@
 #endif
 
 #ifdef CONFIG_ERRATA_MIPS
-#define	ERRATA_MIPS_P8700_PAUSE_OPCODE 0
-#define	ERRATA_MIPS_NUMBER 1
+#define ERRATA_MIPS_P8700_PAUSE_OPCODE 0
+#define ERRATA_MIPS_P8700_WFI 1
+#define ERRATA_MIPS_NUMBER 2
 #endif
 
 #endif /* ASM_ERRATA_LIST_VENDORS_H */
diff --git a/arch/riscv/include/asm/processor.h b/arch/riscv/include/asm/processor.h
index 4c3dd94d0f63844fecc32a7e2c1a184113ee49d9..ae4faed371c16ba33f31373561de03e89d35d04c 100644
--- a/arch/riscv/include/asm/processor.h
+++ b/arch/riscv/include/asm/processor.h
@@ -17,6 +17,7 @@
 #include <asm/alternative-macros.h>
 #include <asm/hwcap.h>
 #include <asm/usercfi.h>
+#include <asm/errata_list.h>
 
 #define arch_get_mmap_end(addr, len, flags)			\
 ({								\
@@ -176,7 +177,7 @@ extern unsigned long __get_wchan(struct task_struct *p);
 
 static inline void wait_for_interrupt(void)
 {
-	__asm__ __volatile__ ("wfi");
+	ALT_RISCV_WFI();
 }
 
 extern phys_addr_t dma32_phys_limit;
diff --git a/arch/riscv/kernel/head.S b/arch/riscv/kernel/head.S
index 9c99c5ad6fe8a32e24c8ce7e0badd63469d2c387..14935e8eec2639844c45bd37db29db74fee38a22 100644
--- a/arch/riscv/kernel/head.S
+++ b/arch/riscv/kernel/head.S
@@ -16,6 +16,8 @@
 #include <asm/scs.h>
 #include <asm/xip_fixup.h>
 #include <asm/usercfi.h>
+#include <asm/alternative.h>
+#include <asm/errata_list.h>
 #include "efi-header.S"
 
 __HEAD
@@ -196,7 +198,7 @@ secondary_start_sbi:
 	 *  - receive an early trap, before setup_trap_vector finished
 	 *  - fail in smp_callin(), as a successful one wouldn't return
 	 */
-	wfi
+	ALT_WFI
 	j .Lsecondary_park
 
 .align 2

---
base-commit: c369299895a591d96745d6492d4888259b004a9e
change-id: 20260415-p8700-wfi-9083b1d87d22

Best regards,
-- 
Aleksa Paunovic <aleksa.paunovic@htecgroup.com>

