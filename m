From: Charlie Jenkins <thecharlesjenkins@gmail.com>
Date: Sun, 21 Jun 2026 21:01:20 -0700
Subject: [PATCH v2 02/16] riscv: alternatives: Use generated instruction
 headers for patching code
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260621-riscv_insn_table-v2-2-7f0810ee2274@gmail.com>
References: <20260621-riscv_insn_table-v2-0-7f0810ee2274@gmail.com>
In-Reply-To: <20260621-riscv_insn_table-v2-0-7f0810ee2274@gmail.com>
To: Paul Walmsley <pjw@kernel.org>, Palmer Dabbelt <palmer@dabbelt.com>, 
 Nam Cao <namcao@linutronix.de>, Alexandre Ghiti <alex@ghiti.fr>, 
 Anup Patel <anup@brainfault.org>, Atish Patra <atish.patra@linux.dev>, 
 Conor Dooley <conor@kernel.org>, Paolo Bonzini <pbonzini@redhat.com>, 
 Andrew Morton <akpm@linux-foundation.org>, Shuah Khan <shuah@kernel.org>, 
 =?utf-8?q?Radim_Kr=C4=8Dm=C3=A1=C5=99?= <radim.krcmar@oss.qualcomm.com>
Cc: linux-riscv@lists.infradead.org, linux-kernel@vger.kernel.org, 
 kvm@vger.kernel.org, kvm-riscv@lists.infradead.org, 
 linux-kselftest@vger.kernel.org, 
 Charlie Jenkins <thecharlesjenkins@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1782100900; l=7576;
 i=thecharlesjenkins@gmail.com; s=20260605; h=from:subject:message-id;
 bh=qT7TaAXs9xJHwiZtIc+DhKQ0DUJ/foDaC5z2Xsev0Gc=;
 b=/u85iHT70EYTXXRqfcVxuy+eKwFcv1Sm2g06wLEvHak3vEGteG8Ldc7KcaqMfE6OBxJ7lA1lT
 3pl0ydafEiwCvE6sFXti2/uSXa2yef6V//ebUsmR2dpfwpT6liIzDX7
X-Developer-Key: i=thecharlesjenkins@gmail.com; a=ed25519;
 pk=ajnnRQ98PIdwKp4HeMkq9U32okYbnh6Zb4G3o5XXvkg=
X-Endpoint-Received: by B4 Relay for thecharlesjenkins@gmail.com/20260605 with auth_id=810
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Migrate the alternatives patching code to use the generated instruction
headers instead of the hand-written instruction composition functions.

Signed-off-by: Charlie Jenkins <thecharlesjenkins@gmail.com>

---

These function expansions are very simple and almost expand to the same
thing in the new and old version. The main difference is
riscv_insn_auipc_extract_imm() in the new version expands to:

((_insn >> 12 & GENMASK(19, 0)) << 12)

while it expands to the following in the old version:

((_insn >> 0) & GENMASK(31, 12))

These are the same thing, but GCC is unable to properly optimize the
second one so the first one ends up using almost half as many
instructions. With this finding and other similar examples, I made
the generated headers construct in the first way to help GCC optimize
all of these functions.

Brute force can also be checked with this code:

void check_auipc_jalr() {
	for (unsigned int auipc = 0; auipc < ((1ULL << 12) - 1); auipc++) {
		for (unsigned int jalr = 0; jalr < ((1ULL << 20) - 1); jalr++) {
			unsigned int auipc_t=riscv_insn_auipc(auipc, 0), jalr_t=riscv_insn_jalr(jalr, 0, 0), auipc_t2=riscv_insn_auipc(auipc, 0), jalr_t2=riscv_insn_jalr(jalr, 0, 0);
			riscv_alternative_fix_auipc_jalr(&auipc_t, &jalr_t, 0);
			riscv_alternative_fix_auipc_jalr2(&auipc_t2, &jalr_t2, 0);

			if (auipc_t != auipc_t2) {
				printf("auipcs don't match %u, %u: %u != %u\n", auipc, jalr, auipc_t, auipc_t2);
				return;
			}

			if (jalr_t != jalr_t2) {
				printf("jalrs don't match %u: %u != %u\n", i, jalr_t, jalr_t2);
			}
		}
	}
}
---
 arch/riscv/include/asm/insn.h   | 74 -----------------------------------------
 arch/riscv/kernel/alternative.c | 23 +++++++++----
 2 files changed, 17 insertions(+), 80 deletions(-)

diff --git a/arch/riscv/include/asm/insn.h b/arch/riscv/include/asm/insn.h
index d562b2b40ba1..d0e137f9bcd7 100644
--- a/arch/riscv/include/asm/insn.h
+++ b/arch/riscv/include/asm/insn.h
@@ -514,78 +514,4 @@ static __always_inline bool riscv_insn_is_branch(u32 code)
 
 #define RVV_EXTRACT_VL_VS_WIDTH(x) RVFDQ_EXTRACT_FL_FS_WIDTH(x)
 
-/*
- * Get the immediate from a J-type instruction.
- *
- * @insn: instruction to process
- * Return: immediate
- */
-static inline s32 riscv_insn_extract_jtype_imm(u32 insn)
-{
-	return RV_EXTRACT_JTYPE_IMM(insn);
-}
-
-/*
- * Update a J-type instruction with an immediate value.
- *
- * @insn: pointer to the jtype instruction
- * @imm: the immediate to insert into the instruction
- */
-static inline void riscv_insn_insert_jtype_imm(u32 *insn, s32 imm)
-{
-	/* drop the old IMMs, all jal IMM bits sit at 31:12 */
-	*insn &= ~GENMASK(31, 12);
-	*insn |= (RV_X_MASK(imm, RV_J_IMM_10_1_OFF, RV_J_IMM_10_1_MASK) << RV_J_IMM_10_1_OPOFF) |
-		 (RV_X_MASK(imm, RV_J_IMM_11_OFF, RV_J_IMM_11_MASK) << RV_J_IMM_11_OPOFF) |
-		 (RV_X_MASK(imm, RV_J_IMM_19_12_OFF, RV_J_IMM_19_12_MASK) << RV_J_IMM_19_12_OPOFF) |
-		 (RV_X_MASK(imm, RV_J_IMM_SIGN_OFF, 1) << RV_J_IMM_SIGN_OPOFF);
-}
-
-/*
- * Put together one immediate from a U-type and I-type instruction pair.
- *
- * The U-type contains an upper immediate, meaning bits[31:12] with [11:0]
- * being zero, while the I-type contains a 12bit immediate.
- * Combined these can encode larger 32bit values and are used for example
- * in auipc + jalr pairs to allow larger jumps.
- *
- * @utype_insn: instruction containing the upper immediate
- * @itype_insn: instruction
- * Return: combined immediate
- */
-static inline s32 riscv_insn_extract_utype_itype_imm(u32 utype_insn, u32 itype_insn)
-{
-	s32 imm;
-
-	imm = RV_EXTRACT_UTYPE_IMM(utype_insn);
-	imm += RV_EXTRACT_ITYPE_IMM(itype_insn);
-
-	return imm;
-}
-
-/*
- * Update a set of two instructions (U-type + I-type) with an immediate value.
- *
- * Used for example in auipc+jalrs pairs the U-type instructions contains
- * a 20bit upper immediate representing bits[31:12], while the I-type
- * instruction contains a 12bit immediate representing bits[11:0].
- *
- * This also takes into account that both separate immediates are
- * considered as signed values, so if the I-type immediate becomes
- * negative (BIT(11) set) the U-type part gets adjusted.
- *
- * @utype_insn: pointer to the utype instruction of the pair
- * @itype_insn: pointer to the itype instruction of the pair
- * @imm: the immediate to insert into the two instructions
- */
-static inline void riscv_insn_insert_utype_itype_imm(u32 *utype_insn, u32 *itype_insn, s32 imm)
-{
-	/* drop possible old IMM values */
-	*utype_insn &= ~(RV_U_IMM_31_12_MASK);
-	*itype_insn &= ~(RV_I_IMM_11_0_MASK << RV_I_IMM_11_0_OPOFF);
-
-	/* add the adapted IMMs */
-	*utype_insn |= (imm & RV_U_IMM_31_12_MASK) + ((imm & BIT(11)) << 1);
-	*itype_insn |= ((imm & RV_I_IMM_11_0_MASK) << RV_I_IMM_11_0_OPOFF);
-}
 #endif /* _ASM_RISCV_INSN_H */
diff --git a/arch/riscv/kernel/alternative.c b/arch/riscv/kernel/alternative.c
index 7642704c7f18..b26a90eb65cc 100644
--- a/arch/riscv/kernel/alternative.c
+++ b/arch/riscv/kernel/alternative.c
@@ -11,6 +11,7 @@
 #include <linux/cpu.h>
 #include <linux/uaccess.h>
 #include <asm/alternative.h>
+#include <asm/insn.h>
 #include <asm/module.h>
 #include <asm/sections.h>
 #include <asm/vdso.h>
@@ -78,14 +79,24 @@ static void riscv_alternative_fix_auipc_jalr(void *ptr, u32 auipc_insn,
 					     u32 jalr_insn, int patch_offset)
 {
 	u32 call[2] = { auipc_insn, jalr_insn };
+	u32 auipc_imm;
 	s32 imm;
 
 	/* get and adjust new target address */
-	imm = riscv_insn_extract_utype_itype_imm(auipc_insn, jalr_insn);
+	imm = riscv_insn_auipc_extract_imm(auipc_insn) + riscv_insn_jalr_extract_imm(jalr_insn);
 	imm -= patch_offset;
 
+	/*
+	 * When the 32-bit immediate is split across auipc and jalr, the
+	 * constructed immediates need to be treated as individually sign
+	 * extended numbers. Add the sign bit of the lower 12 bits to the upper
+	 * 20 bits to undo the bleeding of the sign.
+	 */
+	auipc_imm = imm + (BIT(11) << 1);
+
 	/* update instructions */
-	riscv_insn_insert_utype_itype_imm(&call[0], &call[1], imm);
+	riscv_insn_auipc_insert_imm(&call[0], auipc_imm);
+	riscv_insn_jalr_insert_imm(&call[1], imm);
 
 	/* patch the call place again */
 	patch_text_nosync(ptr, call, sizeof(u32) * 2);
@@ -96,11 +107,11 @@ static void riscv_alternative_fix_jal(void *ptr, u32 jal_insn, int patch_offset)
 	s32 imm;
 
 	/* get and adjust new target address */
-	imm = riscv_insn_extract_jtype_imm(jal_insn);
+	imm = riscv_insn_jal_extract_imm(jal_insn);
 	imm -= patch_offset;
 
 	/* update instruction */
-	riscv_insn_insert_jtype_imm(&jal_insn, imm);
+	riscv_insn_jal_insert_imm(&jal_insn, imm);
 
 	/* patch the call place again */
 	patch_text_nosync(ptr, &jal_insn, sizeof(u32));
@@ -127,7 +138,7 @@ void riscv_alternative_fix_offsets(void *alt_ptr, unsigned int len,
 				continue;
 
 			/* if instruction pair is a call, it will use the ra register */
-			if (RV_EXTRACT_RD_REG(insn) != 1)
+			if (riscv_insn_jalr_extract_xd(insn) != 1)
 				continue;
 
 			riscv_alternative_fix_auipc_jalr(alt_ptr + i * sizeof(u32),
@@ -136,7 +147,7 @@ void riscv_alternative_fix_offsets(void *alt_ptr, unsigned int len,
 		}
 
 		if (riscv_insn_is_jal(insn)) {
-			s32 imm = riscv_insn_extract_jtype_imm(insn);
+			s32 imm = riscv_insn_jal_extract_imm(insn);
 
 			/* Don't modify jumps inside the alternative block */
 			if ((alt_ptr + i * sizeof(u32) + imm) >= alt_ptr &&

-- 
2.54.0

