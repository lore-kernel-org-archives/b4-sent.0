From: Charlie Jenkins <thecharlesjenkins@gmail.com>
Date: Sun, 21 Jun 2026 21:01:33 -0700
Subject: [PATCH v2 15/16] riscv: kexec: Use generated instruction headers
 for kexec relocations
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260621-riscv_insn_table-v2-15-7f0810ee2274@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1782100900; l=3956;
 i=thecharlesjenkins@gmail.com; s=20260605; h=from:subject:message-id;
 bh=34NvWLgWZxGAYVZyLbG0y/AhPlMD8oyGVqDaoGR9FaA=;
 b=73oWRUSsUA63aBLh5aeeP1uBW0bkXVvGwGaKJQy8ByudyAPuWhlTVvefxgdyBFbz+UXbFtzj1
 Z4J9xE+jYUTBKnAAz9ATR4LhKqKS5YnB487lPHmDq6aeXb/IKPwyXxO
X-Developer-Key: i=thecharlesjenkins@gmail.com; a=ed25519;
 pk=ajnnRQ98PIdwKp4HeMkq9U32okYbnh6Zb4G3o5XXvkg=
X-Endpoint-Received: by B4 Relay for thecharlesjenkins@gmail.com/20260605 with auth_id=810
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Migrate the kexec relocation code to use the generated instruction
headers instead of the hand-written instruction composition functions.

Signed-off-by: Charlie Jenkins <thecharlesjenkins@gmail.com>

---

This was again tested by brute forcing all possible inputs to the value
fed into the immediates.
---
 arch/riscv/kernel/machine_kexec_file.c | 55 ++++++++++++----------------------
 1 file changed, 19 insertions(+), 36 deletions(-)

diff --git a/arch/riscv/kernel/machine_kexec_file.c b/arch/riscv/kernel/machine_kexec_file.c
index 54e2d9552e93..cad40e4afd86 100644
--- a/arch/riscv/kernel/machine_kexec_file.c
+++ b/arch/riscv/kernel/machine_kexec_file.c
@@ -116,32 +116,6 @@ static char *setup_kdump_cmdline(struct kimage *image, char *cmdline,
 	(((x) + (RISCV_IMM_REACH >> 1)) & ~(RISCV_IMM_REACH - 1))
 #define RISCV_CONST_LOW_PART(x) ((x) - RISCV_CONST_HIGH_PART(x))
 
-#define ENCODE_ITYPE_IMM(x) \
-	(RV_X(x, 0, 12) << 20)
-#define ENCODE_BTYPE_IMM(x) \
-	((RV_X(x, 1, 4) << 8) | (RV_X(x, 5, 6) << 25) | \
-	(RV_X(x, 11, 1) << 7) | (RV_X(x, 12, 1) << 31))
-#define ENCODE_UTYPE_IMM(x) \
-	(RV_X(x, 12, 20) << 12)
-#define ENCODE_JTYPE_IMM(x) \
-	((RV_X(x, 1, 10) << 21) | (RV_X(x, 11, 1) << 20) | \
-	(RV_X(x, 12, 8) << 12) | (RV_X(x, 20, 1) << 31))
-#define ENCODE_CBTYPE_IMM(x) \
-	((RV_X(x, 1, 2) << 3) | (RV_X(x, 3, 2) << 10) | (RV_X(x, 5, 1) << 2) | \
-	(RV_X(x, 6, 2) << 5) | (RV_X(x, 8, 1) << 12))
-#define ENCODE_CJTYPE_IMM(x) \
-	((RV_X(x, 1, 3) << 3) | (RV_X(x, 4, 1) << 11) | (RV_X(x, 5, 1) << 2) | \
-	(RV_X(x, 6, 1) << 7) | (RV_X(x, 7, 1) << 6) | (RV_X(x, 8, 2) << 9) | \
-	(RV_X(x, 10, 1) << 8) | (RV_X(x, 11, 1) << 12))
-#define ENCODE_UJTYPE_IMM(x) \
-	(ENCODE_UTYPE_IMM(RISCV_CONST_HIGH_PART(x)) | \
-	(ENCODE_ITYPE_IMM(RISCV_CONST_LOW_PART(x)) << 32))
-#define ENCODE_UITYPE_IMM(x) \
-	(ENCODE_UTYPE_IMM(x) | (ENCODE_ITYPE_IMM(x) << 32))
-
-#define CLEAN_IMM(type, x) \
-	((~ENCODE_##type##_IMM((uint64_t)(-1))) & (x))
-
 int arch_kexec_apply_relocations_add(struct purgatory_info *pi,
 				     Elf_Shdr *section,
 				     const Elf_Shdr *relsec,
@@ -197,12 +171,14 @@ int arch_kexec_apply_relocations_add(struct purgatory_info *pi,
 
 		switch (r_type) {
 		case R_RISCV_BRANCH:
-			*(u32 *)loc = CLEAN_IMM(BTYPE, *(u32 *)loc) |
-				 ENCODE_BTYPE_IMM(val - addr);
+			/*
+			 * For simplicity, use beq as represenative of all
+			 * branches (they all have the same imm encoding)
+			 */
+			riscv_insn_beq_insert_imm((u32 *)loc, val - addr);
 			break;
 		case R_RISCV_JAL:
-			*(u32 *)loc = CLEAN_IMM(JTYPE, *(u32 *)loc) |
-				 ENCODE_JTYPE_IMM(val - addr);
+			riscv_insn_jal_insert_imm((u32 *)loc, val  - addr);
 			break;
 		/*
 		 * With no R_RISCV_PCREL_LO12_S, R_RISCV_PCREL_LO12_I
@@ -213,16 +189,23 @@ int arch_kexec_apply_relocations_add(struct purgatory_info *pi,
 		case R_RISCV_PCREL_HI20:
 		case R_RISCV_CALL_PLT:
 		case R_RISCV_CALL:
-			*(u64 *)loc = CLEAN_IMM(UITYPE, *(u64 *)loc) |
-				 ENCODE_UJTYPE_IMM(val - addr);
+			riscv_insn_auipc_insert_imm((u32 *)loc, RISCV_CONST_HIGH_PART(val - addr));
+			riscv_insn_jalr_insert_imm((u32 *)loc + 1,
+						   RISCV_CONST_LOW_PART(val - addr));
 			break;
 		case R_RISCV_RVC_BRANCH:
-			*(u32 *)loc = CLEAN_IMM(CBTYPE, *(u32 *)loc) |
-				 ENCODE_CBTYPE_IMM(val - addr);
+			/*
+			 * For simplicity, use c.beqz as represenative of all
+			 * compressed branches (they all have the same imm encoding)
+			 */
+			riscv_insn_c_beqz_insert_imm((u16 *)loc, val - addr);
 			break;
 		case R_RISCV_RVC_JUMP:
-			*(u32 *)loc = CLEAN_IMM(CJTYPE, *(u32 *)loc) |
-				 ENCODE_CJTYPE_IMM(val - addr);
+			/*
+			 * For simplicity, use c.j as represenative of all
+			 * compressed jumps (they all have the same imm encoding)
+			 */
+			riscv_insn_c_j_insert_imm((u16 *)loc, val - addr);
 			break;
 		case R_RISCV_ADD16:
 			*(u16 *)loc += val;

-- 
2.54.0

