From: Hunter Laux <hunterlaux@gmail.com>
Date: Mon, 09 Nov 2026 20:34:30 -0700
Subject: [PATCH] MIPS: Support TLBINV operating on the whole MMU
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261109-mips-tlbinvf-v1-1-a6d2eb7c8ffd@gmail.com>
X-B4-Tracking: v=1; b=H4sIAMaQ8moC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDQwNL3dzMgmLdkpykzLyyNF0zU6OkVAtTM7MkwxQloJaCotS0zAqwcdG
 xtbUAnE1S914AAAA=
To: Thomas Bogendoerfer <tsbogend@alpha.franken.de>
Cc: Paul Cercueil <paul@crapouillou.net>, linux-mips@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Hunter Laux <hunterlaux@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794281676; l=4874;
 i=hunterlaux@gmail.com; s=20261109; h=from:subject:message-id;
 bh=7zG0ouhkFmv8BZte32qjH+t8nLTySmqybuLXdxnz7fc=;
 b=6oQNAzVgVlwd0Yng2MSx+UBDZZXMlr/u7w2YcO/KufQ+iPNHDCZovoXMOq54NIKclnen+Te7M
 WY2nxJSjCudDMnV30Wxb78kXDU6h7v7xJfMWThbiy6cf2RxBO7LPtd2
X-Developer-Key: i=hunterlaux@gmail.com; a=ed25519;
 pk=Z5VTsE4CAwditt0CNeG+rpPk7xDUVh+oHWDZlNNm8FI=
X-Endpoint-Received: by B4 Relay for hunterlaux@gmail.com/20261109 with auth_id=1476
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Config4.IE = 3 means the TLBINV and TLBINVF instructions walk the whole
MMU in hardware: a single TLBINVF invalidates every non-wired entry, in
the VTLB and every FTLB set. Only IE = 2, where software must issue one
per FTLB set, is recognised, so such CPUs are treated as having no
TLBINV.

The Ingenic X2600 reports IE = 3 and has an FTLB. Without TLBINV,
r4k_tlb_uniquify() runs and, assuming FTLB parts have EHINV, writes
VPNs into FTLB entries of the wrong set; the boot hangs there.

Recognise IE = 3, and flush the whole TLB with a single TLBINVF on such
CPUs.

Tested on an Ingenic X2600 (Flashforge Adventurer 5X).

Assisted-by: Claude:claude-opus-5-5
Signed-off-by: Hunter Laux <hunterlaux@gmail.com>
---
Recognise Config4.IE = 3; fixes a boot hang on the Ingenic X2600.
---
 arch/mips/include/asm/cpu-features.h |  3 +++
 arch/mips/include/asm/cpu.h          |  1 +
 arch/mips/include/asm/mipsregs.h     |  1 +
 arch/mips/kernel/cpu-probe.c         |  8 +++++++-
 arch/mips/mm/tlb-r4k.c               | 22 ++++++++++++----------
 5 files changed, 24 insertions(+), 11 deletions(-)

diff --git a/arch/mips/include/asm/cpu-features.h b/arch/mips/include/asm/cpu-features.h
index 3f11e5218e..33e8588781 100644
--- a/arch/mips/include/asm/cpu-features.h
+++ b/arch/mips/include/asm/cpu-features.h
@@ -80,6 +80,9 @@
 #ifndef cpu_has_tlbinv
 #define cpu_has_tlbinv		__opt(MIPS_CPU_TLBINV)
 #endif
+#ifndef cpu_has_tlbinv_mmu
+#define cpu_has_tlbinv_mmu	__opt(MIPS_CPU_TLBINV_MMU)
+#endif
 #ifndef cpu_has_segments
 #define cpu_has_segments	__opt(MIPS_CPU_SEGMENTS)
 #endif
diff --git a/arch/mips/include/asm/cpu.h b/arch/mips/include/asm/cpu.h
index 0fd9f9bbd2..26b2563c78 100644
--- a/arch/mips/include/asm/cpu.h
+++ b/arch/mips/include/asm/cpu.h
@@ -360,6 +360,7 @@ enum cpu_type_enum {
 #define MIPS_CPU_4KEX		BIT_ULL( 1)	/* "R4K" exception model */
 #define MIPS_CPU_3K_CACHE	BIT_ULL( 2)	/* R3000-style caches */
 #define MIPS_CPU_4K_CACHE	BIT_ULL( 3)	/* R4000-style caches */
+#define MIPS_CPU_TLBINV_MMU	BIT_ULL(4)	/* TLBINV[F] act on the whole MMU */
 #define MIPS_CPU_FPU		BIT_ULL( 5)	/* CPU has FPU */
 #define MIPS_CPU_32FPR		BIT_ULL( 6)	/* 32 dbl. prec. FP registers */
 #define MIPS_CPU_COUNTER	BIT_ULL( 7)	/* Cycle count/compare */
diff --git a/arch/mips/include/asm/mipsregs.h b/arch/mips/include/asm/mipsregs.h
index 12a095dbf9..ba2ff442eb 100644
--- a/arch/mips/include/asm/mipsregs.h
+++ b/arch/mips/include/asm/mipsregs.h
@@ -809,6 +809,7 @@
 #define MIPS_CONF4_AE		(_ULCAST_(1) << 28)
 #define MIPS_CONF4_IE		(_ULCAST_(3) << 29)
 #define MIPS_CONF4_TLBINV	(_ULCAST_(2) << 29)
+#define MIPS_CONF4_TLBINV_MMU	(_ULCAST_(3) << 29)
 
 #define MIPS_CONF5_NF		(_ULCAST_(1) << 0)
 #define MIPS_CONF5_UFR		(_ULCAST_(1) << 2)
diff --git a/arch/mips/kernel/cpu-probe.c b/arch/mips/kernel/cpu-probe.c
index 489612ed9d..59d2b452ad 100644
--- a/arch/mips/kernel/cpu-probe.c
+++ b/arch/mips/kernel/cpu-probe.c
@@ -569,8 +569,14 @@ static inline unsigned int decode_config4(struct cpuinfo_mips *c)
 	config4 = read_c0_config4();
 
 	if (cpu_has_tlb) {
-		if (((config4 & MIPS_CONF4_IE) >> 29) == 2)
+		switch (config4 & MIPS_CONF4_IE) {
+		case MIPS_CONF4_TLBINV_MMU:
+			c->options |= MIPS_CPU_TLBINV_MMU;
+			fallthrough;
+		case MIPS_CONF4_TLBINV:
 			c->options |= MIPS_CPU_TLBINV;
+			break;
+		}
 
 		/*
 		 * R6 has dropped the MMUExtDef field from config4.
diff --git a/arch/mips/mm/tlb-r4k.c b/arch/mips/mm/tlb-r4k.c
index 78bafa317f..2154819c63 100644
--- a/arch/mips/mm/tlb-r4k.c
+++ b/arch/mips/mm/tlb-r4k.c
@@ -75,19 +75,21 @@ void local_flush_tlb_all(void)
 	 * If there are any wired entries, fall back to iterating
 	 */
 	if (cpu_has_tlbinv && !entry) {
-		if (current_cpu_data.tlbsizevtlb) {
+		if (current_cpu_data.tlbsizevtlb || cpu_has_tlbinv_mmu) {
 			write_c0_index(0);
 			mtc0_tlbw_hazard();
-			tlbinvf();  /* invalidate VTLB */
+			tlbinvf();  /* invalidate VTLB (or the whole MMU) */
 		}
-		ftlbhighset = current_cpu_data.tlbsizevtlb +
-			current_cpu_data.tlbsizeftlbsets;
-		for (entry = current_cpu_data.tlbsizevtlb;
-		     entry < ftlbhighset;
-		     entry++) {
-			write_c0_index(entry);
-			mtc0_tlbw_hazard();
-			tlbinvf();  /* invalidate one FTLB set */
+		if (!cpu_has_tlbinv_mmu) {
+			ftlbhighset = current_cpu_data.tlbsizevtlb +
+				current_cpu_data.tlbsizeftlbsets;
+			for (entry = current_cpu_data.tlbsizevtlb;
+			     entry < ftlbhighset;
+			     entry++) {
+				write_c0_index(entry);
+				mtc0_tlbw_hazard();
+				tlbinvf();  /* invalidate one FTLB set */
+			}
 		}
 	} else {
 		while (entry < current_cpu_data.tlbsize) {

---
base-commit: b3dfbde62cf1981c4638939c159dfd087b7a72e9
change-id: 20261109-mips-tlbinvf-652be8566b1d

Best regards,
-- 
Hunter Laux <hunterlaux@gmail.com>

