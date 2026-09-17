From: Aleksa Paunovic <aleksa.paunovic@htecgroup.com>
Date: Thu, 17 Sep 2026 17:06:39 +0200
Subject: [PATCH v3] riscv: Add ERRATA_MIPS_P8700_WFI to replace WFI with
 mips.pause
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260917-p8700-wfi-v3-1-ada4b0584712@htecgroup.com>
X-B4-Tracking: v=1; b=H4sIAP4BrGoC/12PQW7DIBBFr2KxLtGATcBWVOUeURcYDzFSHVwgt
 FGUuxfblZp2+Ue8x/93EjE4jKSr7iRgdtH5Swn1S0XMqC9npG4omXDge2iYoLOSAPTTOtqCqns
 2KDlwTsr7OaB1X6vr9Fby6GLy4baqM1uum0Uw9mTJjDIKbVtMDKyx/DgmNOfgr/PO+Ikspsx/6
 T2oZ5oXWkq0RjaitfXwn35sxQJ+XMu2tLUjE8ao121ddVi1isGPFnV4v9He+7R1E6bRGtQgAOx
 f++uyutcRaQmTS12V5a6mwdTl38c3JO3WFlsBAAA=
X-Change-ID: 20260415-p8700-wfi-9083b1d87d22
To: Paul Walmsley <pjw@kernel.org>, Palmer Dabbelt <palmer@dabbelt.com>, 
 Albert Ou <aou@eecs.berkeley.edu>, Alexandre Ghiti <alex@ghiti.fr>, 
 "Maciej W. Rozycki" <macro@orcam.me.uk>
Cc: linux-riscv@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Djordje Todorovic <djordje.todorovic@htecgroup.com>, 
 Aleksa Paunovic <aleksa.paunovic@htecgroup.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789657607; l=8514;
 i=aleksa.paunovic@htecgroup.com; s=20250806; h=from:subject:message-id;
 bh=n0m09g/GIUzyP9cpXaZLszGSi2479dLawQiQ5FMQ/B0=;
 b=9EQhNV70uI3AeYCwTKNiw70eH5fxlScnkdc8BUwsJf/+gNz2Xus7IHLr9P5N0U6TrGhSZmMFV
 tbgzon/sn+LAhKPWlgKQQ9uRH4eQL0kmfswnK1E4PYF/Bhml7r3nneK
X-Developer-Key: i=aleksa.paunovic@htecgroup.com; a=ed25519;
 pk=Dn4KMnDdgyhlXJNspQQrlHJ04i7/irG29p2H27Avd+8=
X-Endpoint-Received: by B4 Relay for aleksa.paunovic@htecgroup.com/20250806 with auth_id=476
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Djordje Todorovic <djordje.todorovic@htecgroup.com>

The MIPS P8700 has bugs with the WFI instruction. A WFI instruction
after a mispredicted branch can result in erroneous address
translation on the MIPS P8700. MIPS has not published an erratum
for this.

The workaround uses the RISC-V alternatives framework to patch all WFI
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

This patch depends on 'riscv: Add support for early boot errata application on
MIPS chips' [1].

Links:
[1] https://lore.kernel.org/linux-riscv/20260810-p8700-early-boot-v1-1-5c4aa08d500f@htecgroup.com/
---
Changes in v3:
- Rebase onto the early boot patch (linked in [1])
- Expand the errata comment with additional information about PAUSE instruction latency.
- Link to v2: https://lore.kernel.org/r/20260608-p8700-wfi-v2-1-77efc7459f3d@htecgroup.com

Changes in v2:
- Replace .insn with .4byte in ALT_WFI macro
- Add explanatory comments
- Link to v1: https://lore.kernel.org/r/20260511-p8700-wfi-v1-1-099b1d10fcf2@htecgroup.com
---
 arch/riscv/Kconfig.errata                    | 11 +++++++++
 arch/riscv/errata/mips/errata.c              | 17 +++++++++++++
 arch/riscv/include/asm/errata_list.h         | 37 ++++++++++++++++++++++++++++
 arch/riscv/include/asm/errata_list_vendors.h |  5 ++--
 arch/riscv/include/asm/processor.h           |  3 ++-
 arch/riscv/kernel/head.S                     |  4 ++-
 6 files changed, 73 insertions(+), 4 deletions(-)

diff --git a/arch/riscv/Kconfig.errata b/arch/riscv/Kconfig.errata
index 45f3a4a7c9e234e1dc95ff4595a91922ce6176d1..7e7f784a6194bc3c4cdab5fde559e4f37f784dc2 100644
--- a/arch/riscv/Kconfig.errata
+++ b/arch/riscv/Kconfig.errata
@@ -45,6 +45,17 @@ config ERRATA_MIPS_P8700_PAUSE_OPCODE
 
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
index ac9a12d0a30c9d2bf5d4920d5f6e9d2ed22fe0e5..6e715552745011d0b719d78199290490e19d6d2f 100644
--- a/arch/riscv/errata/mips/errata.c
+++ b/arch/riscv/errata/mips/errata.c
@@ -27,6 +27,20 @@ static inline bool errata_probe_pause(unsigned int stage)
 	return true;
 }
 
+static inline bool errata_probe_wfi(unsigned int stage)
+{
+	if (!IS_ENABLED(CONFIG_ERRATA_MIPS_P8700_WFI))
+		return false;
+
+	if (!riscv_isa_vendor_extension_available(MIPS_VENDOR_ID, XMIPSEXECTL))
+		return false;
+
+	if (stage == RISCV_ALTERNATIVES_EARLY_BOOT)
+		return false;
+
+	return true;
+}
+
 static u32 mips_errata_probe(unsigned int stage)
 {
 	u32 cpu_req_errata = 0;
@@ -34,6 +48,9 @@ static u32 mips_errata_probe(unsigned int stage)
 	if (errata_probe_pause(stage))
 		cpu_req_errata |= BIT(ERRATA_MIPS_P8700_PAUSE_OPCODE);
 
+	if (errata_probe_wfi(stage))
+		cpu_req_errata |= BIT(ERRATA_MIPS_P8700_WFI);
+
 	return cpu_req_errata;
 }
 
diff --git a/arch/riscv/include/asm/errata_list.h b/arch/riscv/include/asm/errata_list.h
index 6694b5ccdcf85cfe7e767ea4de981b34f2b17b04..6fdb445c0f45430e5bdd9a8e1382c6f63efe6323 100644
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
@@ -53,6 +63,33 @@ asm(ALTERNATIVE(	\
 	: /* no inputs */	\
 	: "memory")
 
+#ifdef CONFIG_ERRATA_MIPS_P8700_WFI
+/*
+ * A WFI instruction after a mispredicted branch can result in erroneous address translation
+ * on the MIPS P8700.
+ * The number of MIPS_PAUSE instructions required was determined by measuring
+ * Coremark performance on a one-core, two-hart configuration. Eight PAUSE instructions matched
+ * the latency of a single WFI instruction.
+ * Usually, the maximum number of cycles per PAUSE instruction is 63. Exceptionally, if the hart's
+ * LR reservation bit is set, the maximum number of cycles is extended to 255
+ * (and the hart is woken up once it is cleared). This case should not affect the patched sites.
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
index 812517b2cec1350f741849c1c56a35027321ef50..c65c2314206d7d958a1e52cd81b18a8142a6e1a8 100644
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
index f6a8ca49e6277c39b634b3b7d5c248ffa1a0b310..1631fd6bc786b81c9c63e5e38217108ddbde47cd 100644
--- a/arch/riscv/kernel/head.S
+++ b/arch/riscv/kernel/head.S
@@ -15,6 +15,8 @@
 #include <asm/image.h>
 #include <asm/scs.h>
 #include <asm/usercfi.h>
+#include <asm/alternative.h>
+#include <asm/errata_list.h>
 #include "efi-header.S"
 
 __HEAD
@@ -189,7 +191,7 @@ secondary_start_sbi:
 	 *  - receive an early trap, before setup_trap_vector finished
 	 *  - fail in smp_callin(), as a successful one wouldn't return
 	 */
-	wfi
+	ALT_WFI
 	j .Lsecondary_park
 
 .align 2

---
base-commit: c2cd463d6ee7d55a3ec0719d93c49ff99022d58f
change-id: 20260415-p8700-wfi-9083b1d87d22
prerequisite-message-id: <20260810-p8700-early-boot-v1-1-5c4aa08d500f@htecgroup.com>
prerequisite-patch-id: d530f62a25369e72a6ead97617c437b1fca1b276

Best regards,
-- 
Aleksa Paunovic <aleksa.paunovic@htecgroup.com>

