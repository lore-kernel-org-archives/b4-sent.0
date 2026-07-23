From: Aleksa Paunovic <aleksa.paunovic@htecgroup.com>
Date: Thu, 23 Jul 2026 17:51:53 +0200
Subject: [PATCH v4] riscv: Use Zalrsc extension to implement atomic
 functions
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260723-p8700-zalrsc-v4-1-59c21b252e29@htecgroup.com>
X-B4-Tracking: v=1; b=H4sIAJg4YmoC/1XOQQ6CMBCF4auYri0pbaXginsYFqVMoREomSJRC
 Xe3YFy4mvyL+fJWEgAdBHI9rQRhccH5MYY8n4jp9NgCdU1swhm/MJVKOuWKMfrWPQZDrcgLWYN
 kDctIfJkQrHse3K2KbdEPdO4Q9A+RKY9Qvt9EZIormlKN7q57X7aDdn1i/LBTnQuzx9cxbBE7+
 N1QsPR/wyIiASaTVtc1sEKU3QymRf+YDqvatu0DTfR2BucAAAA=
X-Change-ID: 20250714-p8700-zalrsc-f3894be40d06
To: Paul Walmsley <paul.walmsley@sifive.com>, 
 Palmer Dabbelt <palmer@dabbelt.com>, Albert Ou <aou@eecs.berkeley.edu>, 
 Alexandre Ghiti <alex@ghiti.fr>, Will Deacon <will@kernel.org>, 
 Peter Zijlstra <peterz@infradead.org>, Mark Rutland <mark.rutland@arm.com>, 
 Yury Norov <yury.norov@gmail.com>, 
 Djordje Todorovic <djordje.todorovic@htecgroup.com>, 
 Rasmus Villemoes <linux@rasmusvillemoes.dk>, 
 Charlie Jenkins <charlie@rivosinc.com>, Conor Dooley <conor@kernel.org>, 
 Jessica Clarke <jrtc27@jrtc27.com>, 
 Samuel Holland <samuel.holland@sifive.com>, Paul Walmsley <pjw@kernel.org>, 
 Boqun Feng <boqun@kernel.org>, Gary Guo <gary@garyguo.net>, 
 Boqun Feng <boqun@kernel.org>
Cc: linux-riscv@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Chao-ying Fu <cfu@mips.com>, Aleksandar Rikalo <arikalo@gmail.com>, 
 Aleksa Paunovic <aleksa.paunovic@htecgroup.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784821924; l=21204;
 i=aleksa.paunovic@htecgroup.com; s=20250806; h=from:subject:message-id;
 bh=+DWkluktD3VNDFd8BtI8O5tItR1NAnOaQo2tLoiiQG4=;
 b=LL0nF85G8h6wKLupANxls1NiwoeJZkSw8ZybZ/xkBTEqAfCSFcilUHtRr9l+PhNjIg9UEVZlV
 dAq72kGrY2KBrMXLIe90fmww4E3a9AX8S4ZYak6np7ij/hC1nbE4bTD
X-Developer-Key: i=aleksa.paunovic@htecgroup.com; a=ed25519;
 pk=Dn4KMnDdgyhlXJNspQQrlHJ04i7/irG29p2H27Avd+8=
X-Endpoint-Received: by B4 Relay for aleksa.paunovic@htecgroup.com/20250806 with auth_id=476
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Chao-ying Fu <cfu@mips.com>

MIPS P8700 does not natively support Zaamo instructions.
They are emulated with Zalrsc extension instructions instead [1].
Since the emulation is implemented through M-mode traps in the SBI
layer, it is best to avoid using these instructions wherever possible on
the P8700.

Implement kernel atomic operations using LR/SC sequences only.
This is achieved by using the errata mechanism, with minimal
interference on other cores.

Signed-off-by: Chao-ying Fu <cfu@mips.com>
Signed-off-by: Aleksandar Rikalo <arikalo@gmail.com>
Co-developed-by: Aleksa Paunovic <aleksa.paunovic@htecgroup.com>
Signed-off-by: Aleksa Paunovic <aleksa.paunovic@htecgroup.com>

[1] https://mips.com/wp-content/uploads/2026/03/MIPS_P8700_P8700-F_Programmers_Reference_Guide_Rev1.86_2-17-2026.pdf

---
The patch was tested on QEMU configured to emulate an eight-hart MIPS P8700 CPU.
Testing done since v3: futex kselftests and perf futex tests. These tests caught the issues described below.
The same tests were executed on the Boston board with a single-hart P8700 core.

Since the main issue was with an incorrectly written erratum, it shouldn't affect Vladimir's version [1].
However, since chips supporting only one part of the A extension are rare, we believe it might be
better to address this using the alternative mechanism, instead of demanding that the wider community
relax the A extension requirement.

Changes in v4:
- The amo part of the ALT_TEST_AND_OP_BIT_ORD erratum erroneously hardcoded zero as the destination register.
  This is fixed in v4.
- futex.h was missing the ANDN case.
- Link to v3: https://lore.kernel.org/r/20250901-p8700-zalrsc-v3-1-ec64fabbe093@htecgroup.com

Changes in v3:
- Use alternatives to replace AMO instructions with LR/SC
- Rebase on Alexandre Ghiti's "for-next" branch.
- Link to v2: https://lore.kernel.org/linux-riscv/20241225082412.36727-1-arikalo@gmail.com/

Links:
[1] https://lore.kernel.org/linux-riscv/20260120-lrsc-only-v2-0-a522e640d27d@mobileye.com/

Signed-off-by: Aleksa Paunovic <aleksa.paunovic@htecgroup.com>
---
 arch/riscv/Kconfig.errata                    |  11 ++
 arch/riscv/errata/mips/errata.c              |  13 +-
 arch/riscv/include/asm/atomic.h              |  29 ++--
 arch/riscv/include/asm/bitops.h              |  28 ++--
 arch/riscv/include/asm/cmpxchg.h             |   9 +-
 arch/riscv/include/asm/errata_list.h         | 215 +++++++++++++++++++++++++++
 arch/riscv/include/asm/errata_list_vendors.h |   3 +-
 arch/riscv/include/asm/futex.h               |  40 ++---
 arch/riscv/kernel/entry.S                    |  10 +-
 9 files changed, 290 insertions(+), 68 deletions(-)

diff --git a/arch/riscv/Kconfig.errata b/arch/riscv/Kconfig.errata
index 3c945d086c7d0266b685f9506d58b0662af071c4..cd5bd5e8eb395418c3ad103dbd836c775b7fd901 100644
--- a/arch/riscv/Kconfig.errata
+++ b/arch/riscv/Kconfig.errata
@@ -44,6 +44,17 @@ config ERRATA_MIPS_P8700_PAUSE_OPCODE
 
 	   If you are not using the P8700 processor, say n.
 
+config ERRATA_MIPS_P8700_AMO_ZALRSC
+	bool "Replace AMO instructions with LR/SC on MIPS P8700"
+	depends on ERRATA_MIPS && 64BIT
+	default n
+	help
+	   The MIPS P8700 does not implement the full A extension,
+	   implementing only Zalrsc. Enabling this will replace
+	   all AMO instructions with LR/SC instructions on the P8700.
+
+	   If you are not using the P8700 processor, say n.
+
 config ERRATA_SIFIVE
 	bool "SiFive errata"
 	depends on RISCV_ALTERNATIVE
diff --git a/arch/riscv/errata/mips/errata.c b/arch/riscv/errata/mips/errata.c
index e984a8152208c34690f89d8101571b097485c360..08c5efd58bf242d3831957f91f6338ef49f61238 100644
--- a/arch/riscv/errata/mips/errata.c
+++ b/arch/riscv/errata/mips/errata.c
@@ -23,13 +23,22 @@ static inline bool errata_probe_pause(void)
 	return true;
 }
 
-static u32 mips_errata_probe(void)
+static inline bool errata_probe_zalrsc(unsigned long archid)
+{
+	return archid == 0x8000000000000201;
+}
+
+static u32 mips_errata_probe(unsigned long archid)
 {
 	u32 cpu_req_errata = 0;
 
 	if (errata_probe_pause())
 		cpu_req_errata |= BIT(ERRATA_MIPS_P8700_PAUSE_OPCODE);
 
+	if (errata_probe_zalrsc(archid))
+		cpu_req_errata |= BIT(ERRATA_MIPS_P8700_ZALRSC);
+
+
 	return cpu_req_errata;
 }
 
@@ -38,7 +47,7 @@ void mips_errata_patch_func(struct alt_entry *begin, struct alt_entry *end,
 			    unsigned int stage)
 {
 	struct alt_entry *alt;
-	u32 cpu_req_errata = mips_errata_probe();
+	u32 cpu_req_errata = mips_errata_probe(archid);
 	u32 tmp;
 
 	BUILD_BUG_ON(ERRATA_MIPS_NUMBER >= RISCV_VENDOR_EXT_ALTERNATIVES_BASE);
diff --git a/arch/riscv/include/asm/atomic.h b/arch/riscv/include/asm/atomic.h
index 3f33dc54f94b2e14cb4270dbd0493625fbb977bd..9f848ec1705ff1afc6342e53965fab82309f9fe2 100644
--- a/arch/riscv/include/asm/atomic.h
+++ b/arch/riscv/include/asm/atomic.h
@@ -54,12 +54,9 @@ static __always_inline void arch_atomic64_set(atomic64_t *v, s64 i)
 static __always_inline							\
 void arch_atomic##prefix##_##op(c_type i, atomic##prefix##_t *v)	\
 {									\
-	__asm__ __volatile__ (						\
-		"	amo" #asm_op "." #asm_type " zero, %1, %0"	\
-		: "+A" (v->counter)					\
-		: "r" (I)						\
-		: "memory");						\
-}									\
+	register __maybe_unused c_type ret, temp;			\
+	ALT_ATOMIC_OP(asm_op, I, asm_type, v, ret, temp);		\
+}
 
 #ifdef CONFIG_GENERIC_ATOMIC64
 #define ATOMIC_OPS(op, asm_op, I)					\
@@ -89,24 +86,16 @@ static __always_inline							\
 c_type arch_atomic##prefix##_fetch_##op##_relaxed(c_type i,		\
 					     atomic##prefix##_t *v)	\
 {									\
-	register c_type ret;						\
-	__asm__ __volatile__ (						\
-		"	amo" #asm_op "." #asm_type " %1, %2, %0"	\
-		: "+A" (v->counter), "=r" (ret)				\
-		: "r" (I)						\
-		: "memory");						\
+	register __maybe_unused c_type ret, temp;			\
+	ALT_ATOMIC_FETCH_OP_RELAXED(asm_op, I, asm_type, v, ret, temp);	\
 	return ret;							\
 }									\
 static __always_inline							\
 c_type arch_atomic##prefix##_fetch_##op(c_type i, atomic##prefix##_t *v)	\
-{									\
-	register c_type ret;						\
-	__asm__ __volatile__ (						\
-		"	amo" #asm_op "." #asm_type ".aqrl  %1, %2, %0"	\
-		: "+A" (v->counter), "=r" (ret)				\
-		: "r" (I)						\
-		: "memory");						\
-	return ret;							\
+{										\
+	register __maybe_unused c_type ret, temp;				\
+	ALT_ATOMIC_FETCH_OP(asm_op, I, asm_type, v, ret, temp);			\
+	return ret;								\
 }
 
 #define ATOMIC_OP_RETURN(op, asm_op, c_op, I, asm_type, c_type, prefix)	\
diff --git a/arch/riscv/include/asm/bitops.h b/arch/riscv/include/asm/bitops.h
index 3c1a15be54d804d7f609d8f4033710970f7b215f..caf8048c29f34182ee0740e836a1305c450b68f4 100644
--- a/arch/riscv/include/asm/bitops.h
+++ b/arch/riscv/include/asm/bitops.h
@@ -170,30 +170,27 @@ static __always_inline int variable_fls(unsigned int x)
 
 #if (BITS_PER_LONG == 64)
 #define __AMO(op)	"amo" #op ".d"
+#define __LR	"lr.d"
+#define __SC	"sc.d"
 #elif (BITS_PER_LONG == 32)
 #define __AMO(op)	"amo" #op ".w"
+#define __LR	"lr.w"
+#define __SC	"sc.w"
 #else
 #error "Unexpected BITS_PER_LONG"
 #endif
 
 #define __test_and_op_bit_ord(op, mod, nr, addr, ord)		\
 ({								\
-	unsigned long __res, __mask;				\
+	__maybe_unused unsigned long __res, __mask, __temp;				\
 	__mask = BIT_MASK(nr);					\
-	__asm__ __volatile__ (					\
-		__AMO(op) #ord " %0, %2, %1"			\
-		: "=r" (__res), "+A" (addr[BIT_WORD(nr)])	\
-		: "r" (mod(__mask))				\
-		: "memory");					\
+	ALT_TEST_AND_OP_BIT_ORD(op, mod, nr, addr, ord, __res, __mask, __temp);	 \
 	((__res & __mask) != 0);				\
 })
 
 #define __op_bit_ord(op, mod, nr, addr, ord)			\
-	__asm__ __volatile__ (					\
-		__AMO(op) #ord " zero, %1, %0"			\
-		: "+A" (addr[BIT_WORD(nr)])			\
-		: "r" (mod(BIT_MASK(nr)))			\
-		: "memory");
+	__maybe_unused unsigned long __res, __temp;				\
+	ALT_OP_BIT_ORD(op, mod, nr, addr, ord, __res, __temp);
 
 #define __test_and_op_bit(op, mod, nr, addr) 			\
 	__test_and_op_bit_ord(op, mod, nr, addr, .aqrl)
@@ -337,12 +334,9 @@ static __always_inline void arch___clear_bit_unlock(
 static __always_inline bool arch_xor_unlock_is_negative_byte(unsigned long mask,
 		volatile unsigned long *addr)
 {
-	unsigned long res;
-	__asm__ __volatile__ (
-		__AMO(xor) ".rl %0, %2, %1"
-		: "=r" (res), "+A" (*addr)
-		: "r" (__NOP(mask))
-		: "memory");
+	__maybe_unused unsigned long res, temp;
+
+	ALT_ARCH_XOR_UNLOCK(mask, addr, res, temp);
 	return (res & BIT(7)) != 0;
 }
 
diff --git a/arch/riscv/include/asm/cmpxchg.h b/arch/riscv/include/asm/cmpxchg.h
index 8712cf9c69dcb3690058c60e60481fc4c3ffea06..21035ebe0e9193c1793ddc5488346fcb04d3ff3a 100644
--- a/arch/riscv/include/asm/cmpxchg.h
+++ b/arch/riscv/include/asm/cmpxchg.h
@@ -56,13 +56,8 @@
 
 #define __arch_xchg(sfx, prepend, append, r, p, n)			\
 ({									\
-	__asm__ __volatile__ (						\
-		prepend							\
-		"	amoswap" sfx " %0, %2, %1\n"			\
-		append							\
-		: "=r" (r), "+A" (*(p))					\
-		: "r" (n)						\
-		: "memory");						\
+	__typeof__(*(__ptr)) __maybe_unused temp;					\
+	ALT_ARCH_XCHG(sfx, prepend, append, r, p, n, temp);	\
 })
 
 #define _arch_xchg(ptr, new, sc_sfx, swap_sfx, prepend,			\
diff --git a/arch/riscv/include/asm/errata_list.h b/arch/riscv/include/asm/errata_list.h
index 6694b5ccdcf85cfe7e767ea4de981b34f2b17b04..76c2f2a0f3b53f5507ecb2680d302679b3f97c69 100644
--- a/arch/riscv/include/asm/errata_list.h
+++ b/arch/riscv/include/asm/errata_list.h
@@ -25,6 +25,7 @@ ALTERNATIVE(__stringify(RISCV_PTR do_page_fault),			\
 	    __stringify(RISCV_PTR sifive_cip_453_page_fault_trp),	\
 	    SIFIVE_VENDOR_ID, ERRATA_SIFIVE_CIP_453,			\
 	    CONFIG_ERRATA_SIFIVE_CIP_453)
+
 #else /* !__ASSEMBLER__ */
 
 #define ALT_SFENCE_VMA_ASID(asid)					\
@@ -53,6 +54,220 @@ asm(ALTERNATIVE(	\
 	: /* no inputs */	\
 	: "memory")
 
+#ifdef CONFIG_ERRATA_MIPS_P8700_AMO_ZALRSC
+#define ALT_ATOMIC_OP(asm_op, I, asm_type, v, ret, temp)		\
+asm(ALTERNATIVE(							\
+		"	amo" #asm_op "." #asm_type " zero, %3, %0\n"	\
+		__nops(3),						\
+		"1:	lr." #asm_type " %1, %0\n"			\
+		"	" #asm_op " %2, %1, %3\n"			\
+		"	sc." #asm_type " %2, %2, %0\n"			\
+		"	bnez %2, 1b\n",					\
+		MIPS_VENDOR_ID,						\
+		ERRATA_MIPS_P8700_ZALRSC,				\
+		CONFIG_ERRATA_MIPS_P8700_AMO_ZALRSC)			\
+	: "+A" (v->counter), "=&r" (ret), "=&r" (temp)			\
+	: "r" (I)							\
+	: "memory")
+
+#define ALT_ATOMIC_FETCH_OP_RELAXED(asm_op, I, asm_type, v, ret, temp)	\
+asm(ALTERNATIVE(							\
+		"	amo" #asm_op "." #asm_type " %1, %3, %0\n"	\
+		__nops(3),						\
+		"1:	lr." #asm_type " %1, %0\n"			\
+		"	" #asm_op " %2, %1, %3\n"			\
+		"	sc." #asm_type " %2, %2, %0\n"			\
+		"	bnez %2, 1b\n",					\
+		MIPS_VENDOR_ID,						\
+		ERRATA_MIPS_P8700_ZALRSC,				\
+		CONFIG_ERRATA_MIPS_P8700_AMO_ZALRSC)			\
+	: "+A" (v->counter), "=&r" (ret), "=&r" (temp)			\
+	: "r" (I)							\
+	: "memory")
+
+#define ALT_ATOMIC_FETCH_OP(asm_op, I, asm_type, v, ret, temp)		\
+asm(ALTERNATIVE(							\
+		"	amo" #asm_op "." #asm_type ".aqrl  %1, %3, %0\n"\
+		__nops(3),						\
+		"1:	lr." #asm_type ".aqrl %1, %0\n"			\
+		"	" #asm_op " %2, %1, %3\n"			\
+		"	sc." #asm_type ".aqrl %2, %2, %0\n"		\
+		"	bnez %2, 1b\n",					\
+		MIPS_VENDOR_ID,						\
+		ERRATA_MIPS_P8700_ZALRSC,				\
+		CONFIG_ERRATA_MIPS_P8700_AMO_ZALRSC)			\
+	: "+A" (v->counter), "=&r" (ret), "=&r" (temp)			\
+	: "r" (I)							\
+	: "memory")
+/* BITOPS.h */
+#define ALT_TEST_AND_OP_BIT_ORD(op, mod, nr, addr, ord, __res, __mask, __temp)	\
+asm(ALTERNATIVE(								\
+		__AMO(op) #ord " %0, %3, %1\n"					\
+		__nops(3),							\
+		"1: " __LR #ord " %0, %1\n"					\
+		#op " %2, %0, %3\n"						\
+		__SC #ord " %2, %2, %1\n"					\
+		"bnez %2, 1b\n",						\
+		MIPS_VENDOR_ID,							\
+		ERRATA_MIPS_P8700_ZALRSC,					\
+		CONFIG_ERRATA_MIPS_P8700_AMO_ZALRSC)				\
+	: "=&r" (__res), "+A" (addr[BIT_WORD(nr)]), "=&r" (__temp)		\
+	: "r" (mod(__mask))							\
+	: "memory")
+
+#define ALT_OP_BIT_ORD(op, mod, nr, addr, ord, __res, __temp)		\
+asm(ALTERNATIVE(							\
+		__AMO(op) #ord " zero, %3, %1\n"			\
+		__nops(3),						\
+		"1: " __LR #ord " %0, %1\n"				\
+		#op " %2, %0, %3\n"					\
+		__SC #ord " %2, %2, %1\n"				\
+		"bnez %2, 1b\n",					\
+		MIPS_VENDOR_ID,						\
+		ERRATA_MIPS_P8700_ZALRSC,				\
+		CONFIG_ERRATA_MIPS_P8700_AMO_ZALRSC)			\
+	: "=&r" (__res), "+A" (addr[BIT_WORD(nr)]), "=&r" (__temp)	\
+	: "r" (mod(BIT_MASK(nr)))					\
+	: "memory")
+
+#define ALT_ARCH_XOR_UNLOCK(mask, addr, __res, __temp)	\
+asm(ALTERNATIVE(					\
+		__AMO(xor) ".rl %0, %3, %1\n"		\
+		__nops(3),				\
+		"1: " __LR ".rl %0, %1\n"		\
+		"xor %2, %0, %3\n"			\
+		__SC ".rl %2, %2, %1\n"			\
+		"bnez %2, 1b\n",			\
+		MIPS_VENDOR_ID,				\
+		ERRATA_MIPS_P8700_ZALRSC,		\
+		CONFIG_ERRATA_MIPS_P8700_AMO_ZALRSC)	\
+	: "=&r" (__res), "+A" (*addr), "=&r" (__temp)	\
+	: "r" (__NOP(mask))				\
+	: "memory")
+
+#define ALT_ARCH_XCHG(sfx, prepend, append, r, p, n, temp)	\
+asm(ALTERNATIVE(						\
+		prepend						\
+		"	amoswap" sfx " %0, %3, %1\n"		\
+	    __nops(2)						\
+		append,						\
+		prepend						\
+		"1:	lr" sfx " %0, %1\n"			\
+		"	sc" sfx " %2, %3, %1\n"			\
+		"	bnez %2, 1b\n"				\
+		append,						\
+		MIPS_VENDOR_ID,					\
+		ERRATA_MIPS_P8700_ZALRSC,			\
+		CONFIG_ERRATA_MIPS_P8700_AMO_ZALRSC)		\
+	: "=&r" (r), "+A" (*(p)), "=&r" (temp)			\
+	: "r" (n)						\
+	: "memory")
+
+/* FUTEX.H */
+#define ALT_FUTEX_ATOMIC_OP(insn, ret, oldval, uaddr, oparg, temp)	\
+asm(ALTERNATIVE(							\
+		"1: amo" #insn ".w.aqrl %[ov],%z[op],%[u]\n"		\
+		__nops(3)						\
+		"2:\n"							\
+		_ASM_EXTABLE_UACCESS_ERR(1b, 2b, %[r]),			\
+		"1:	lr.w.aqrl %[ov], %[u]\n"			\
+		"	" #insn" %[t], %[ov], %z[op]\n"			\
+		"	sc.w.aqrl %[t], %[t], %[u]\n"			\
+		"	bnez %[t], 1b\n"				\
+		"2:\n"							\
+		_ASM_EXTABLE_UACCESS_ERR(1b, 2b, %[r]),			\
+		MIPS_VENDOR_ID,						\
+		ERRATA_MIPS_P8700_ZALRSC,				\
+		CONFIG_ERRATA_MIPS_P8700_AMO_ZALRSC)			\
+	: [r] "+r" (ret), [ov] "=&r" (oldval),				\
+	  [t] "=&r" (temp), [u] "+m" (*uaddr)				\
+	: [op] "Jr" (oparg)						\
+	: "memory")
+
+#define ALT_FUTEX_ATOMIC_SWAP(ret, oldval, uaddr, oparg, temp)	\
+asm(ALTERNATIVE(						\
+		"1: amoswap.w.aqrl %[ov],%z[op],%[u]\n"		\
+		__nops(3)					\
+		"2:\n"						\
+		_ASM_EXTABLE_UACCESS_ERR(1b, 2b, %[r]),		\
+		"1:	lr.w.aqrl %[ov], %[u]\n"		\
+		"	mv %[t], %z[op]\n"			\
+		"	sc.w.aqrl %[t], %[t], %[u]\n"		\
+		"	bnez %[t], 1b\n"			\
+		"2:\n"						\
+		_ASM_EXTABLE_UACCESS_ERR(1b, 2b, %[r]),		\
+		MIPS_VENDOR_ID,					\
+		ERRATA_MIPS_P8700_ZALRSC,			\
+		CONFIG_ERRATA_MIPS_P8700_AMO_ZALRSC)		\
+	: [r] "+r" (ret), [ov] "=&r" (oldval),			\
+	  [t] "=&r" (temp), [u] "+m" (*uaddr)			\
+	: [op] "Jr" (oparg)					\
+	: "memory")
+
+#else
+#define ALT_ATOMIC_OP(asm_op, I, asm_type, v, ret, temp)	\
+asm("amo" #asm_op "." #asm_type " zero, %1, %0"			\
+	: "+A" (v->counter)					\
+	: "r" (I)						\
+	: "memory")
+
+#define ALT_ATOMIC_FETCH_OP_RELAXED(asm_op, I, asm_type, v, ret, temp)	\
+asm("amo" #asm_op "." #asm_type " %1, %2, %0"				\
+	: "+A" (v->counter), "=r" (ret)					\
+	: "r" (I)							\
+	: "memory")
+
+#define ALT_ATOMIC_FETCH_OP(asm_op, I, asm_type, v, ret, temp)	\
+asm("amo" #asm_op "." #asm_type ".aqrl %1, %2, %0"		\
+	: "+A" (v->counter), "=r" (ret)				\
+	: "r" (I)						\
+	: "memory")
+
+#define ALT_TEST_AND_OP_BIT_ORD(op, mod, nr, addr, ord, __res, __mask, __temp)	\
+asm(__AMO(op) #ord " %0, %2, %1"						\
+	: "=r" (__res), "+A" (addr[BIT_WORD(nr)])				\
+	: "r" (mod(__mask))							\
+	: "memory")
+
+#define ALT_OP_BIT_ORD(op, mod, nr, addr, ord, __res, __temp)	\
+asm(__AMO(op) #ord " zero, %1, %0"				\
+	: "+A" (addr[BIT_WORD(nr)])				\
+	: "r" (mod(BIT_MASK(nr)))				\
+	: "memory")
+
+#define ALT_ARCH_XOR_UNLOCK(mask, addr, __res, __temp)	\
+asm(__AMO(xor) ".rl %0, %2, %1"				\
+	: "=r" (res), "+A" (*addr)			\
+	: "r" (__NOP(mask))				\
+	: "memory")
+
+#define ALT_ARCH_XCHG(sfx, prepend, append, r, p, n, temp)	\
+asm(prepend							\
+	"	amoswap" sfx " %0, %2, %1\n"			\
+	append							\
+	: "=r" (r), "+A" (*(p))					\
+	: "r" (n)						\
+	: "memory")
+
+#define ALT_FUTEX_ATOMIC_OP(insn, ret, oldval, uaddr, oparg, temp)	\
+asm("1: amo" #insn ".w.aqrl %[ov],%z[op],%[u]\n"			\
+	"2:\n"								\
+	_ASM_EXTABLE_UACCESS_ERR(1b, 2b, %[r])				\
+	: [r] "+r" (ret), [ov] "=&r" (oldval),				\
+	  [u] "+m" (*uaddr)						\
+	: [op] "Jr" (oparg)						\
+	: "memory")
+
+#define ALT_FUTEX_ATOMIC_SWAP(ret, oldval, uaddr, oparg, temp)  \
+asm("1: amoswap.w.aqrl %[ov],%z[op],%[u]\n"			\
+	"2:\n"							\
+	_ASM_EXTABLE_UACCESS_ERR(1b, 2b, %[r])			\
+	: [r] "+r" (ret), [ov] "=&r" (oldval),			\
+	  [u] "+m" (*uaddr)					\
+	: [op] "Jr" (oparg)					\
+	: "memory")
+#endif
+
 /*
  * _val is marked as "will be overwritten", so need to set it to 0
  * in the default case.
diff --git a/arch/riscv/include/asm/errata_list_vendors.h b/arch/riscv/include/asm/errata_list_vendors.h
index ec7eba3734371a2d8b68fbd4cbd88a8e7135a413..d47a98ab93d12ce1f6ae44449f80bb703987e985 100644
--- a/arch/riscv/include/asm/errata_list_vendors.h
+++ b/arch/riscv/include/asm/errata_list_vendors.h
@@ -23,7 +23,8 @@
 
 #ifdef CONFIG_ERRATA_MIPS
 #define	ERRATA_MIPS_P8700_PAUSE_OPCODE 0
-#define	ERRATA_MIPS_NUMBER 1
+#define	ERRATA_MIPS_P8700_ZALRSC 1
+#define	ERRATA_MIPS_NUMBER 2
 #endif
 
 #endif /* ASM_ERRATA_LIST_VENDORS_H */
diff --git a/arch/riscv/include/asm/futex.h b/arch/riscv/include/asm/futex.h
index 90c86b115e008a1fb08f3da64382fb4a64d9cc2f..bc3e8c0586410d1fc3a1a7d35b7775f9c339719f 100644
--- a/arch/riscv/include/asm/futex.h
+++ b/arch/riscv/include/asm/futex.h
@@ -12,6 +12,7 @@
 #include <linux/errno.h>
 #include <asm/asm.h>
 #include <asm/asm-extable.h>
+#include <asm/errata_list.h>
 
 /* We don't even really need the extable code, but for now keep it simple */
 #ifndef CONFIG_MMU
@@ -19,48 +20,47 @@
 #define __disable_user_access()		do { } while (0)
 #endif
 
-#define __futex_atomic_op(insn, ret, oldval, uaddr, oparg)	\
+#define __futex_atomic_op(insn, ret, oldval, uaddr, oparg, temp)	\
 {								\
 	__enable_user_access();					\
-	__asm__ __volatile__ (					\
-	"1:	" insn "				\n"	\
-	"2:						\n"	\
-	_ASM_EXTABLE_UACCESS_ERR(1b, 2b, %[r])			\
-	: [r] "+r" (ret), [ov] "=&r" (oldval),			\
-	  [u] "+m" (*uaddr)					\
-	: [op] "Jr" (oparg)					\
-	: "memory");						\
+	ALT_FUTEX_ATOMIC_OP(insn, ret, oldval, uaddr, oparg, temp);	\
+	__disable_user_access();				\
+}
+
+#define __futex_atomic_swap(ret, oldval, uaddr, oparg, temp)	\
+{								\
+	__enable_user_access();					\
+	ALT_FUTEX_ATOMIC_SWAP(ret, oldval, uaddr, oparg, temp);	\
 	__disable_user_access();				\
 }
 
 static inline int
 arch_futex_atomic_op_inuser(int op, int oparg, int *oval, u32 __user *uaddr)
 {
-	int oldval = 0, ret = 0;
+	int __maybe_unused oldval = 0, ret = 0, temp = 0;
 
 	if (!access_ok(uaddr, sizeof(u32)))
 		return -EFAULT;
 
 	switch (op) {
 	case FUTEX_OP_SET:
-		__futex_atomic_op("amoswap.w.aqrl %[ov],%z[op],%[u]",
-				  ret, oldval, uaddr, oparg);
+		__futex_atomic_swap(ret, oldval, uaddr, oparg, temp);
 		break;
 	case FUTEX_OP_ADD:
-		__futex_atomic_op("amoadd.w.aqrl %[ov],%z[op],%[u]",
-				  ret, oldval, uaddr, oparg);
+		__futex_atomic_op(add,
+				  ret, oldval, uaddr, oparg, temp);
 		break;
 	case FUTEX_OP_OR:
-		__futex_atomic_op("amoor.w.aqrl %[ov],%z[op],%[u]",
-				  ret, oldval, uaddr, oparg);
+		__futex_atomic_op(or,
+				  ret, oldval, uaddr, oparg, temp);
 		break;
 	case FUTEX_OP_ANDN:
-		__futex_atomic_op("amoand.w.aqrl %[ov],%z[op],%[u]",
-				  ret, oldval, uaddr, ~oparg);
+		__futex_atomic_op(and,
+				  ret, oldval, uaddr, ~oparg, temp);
 		break;
 	case FUTEX_OP_XOR:
-		__futex_atomic_op("amoxor.w.aqrl %[ov],%z[op],%[u]",
-				  ret, oldval, uaddr, oparg);
+		__futex_atomic_op(xor,
+				  ret, oldval, uaddr, oparg, temp);
 		break;
 	default:
 		ret = -ENOSYS;
diff --git a/arch/riscv/kernel/entry.S b/arch/riscv/kernel/entry.S
index 60eb221296a604694c5f936d0c23c637dc44298e..8a7f9cb57f8450fd04107e2b57096c41bcefb722 100644
--- a/arch/riscv/kernel/entry.S
+++ b/arch/riscv/kernel/entry.S
@@ -73,7 +73,15 @@
 	beq	a2, zero, .Lnew_vmalloc_restore_context
 
 	/* Atomically reset the current cpu bit in new_vmalloc */
-	amoxor.d	a0, a1, (a0)
+	ALTERNATIVE("amoxor.d a0, a1, (a0);	\
+				.rept 3; nop; .endr;",
+				"1: lr.d a2, (a0);	\
+				xor a2, a2, a1;	\
+				sc.d a2, a2, (a0);	\
+				bnez a2, 1b;",
+				MIPS_VENDOR_ID,
+				ERRATA_MIPS_P8700_ZALRSC,
+            CONFIG_ERRATA_MIPS_P8700_AMO_ZALRSC)
 
 	/* Only emit a sfence.vma if the uarch caches invalid entries */
 	ALTERNATIVE("sfence.vma", "nop", 0, RISCV_ISA_EXT_SVVPTC, 1)

---
base-commit: c369299895a591d96745d6492d4888259b004a9e
change-id: 20250714-p8700-zalrsc-f3894be40d06

Best regards,
-- 
Aleksa Paunovic <aleksa.paunovic@htecgroup.com>

