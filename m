From: Charlie Jenkins <thecharlesjenkins@gmail.com>
Date: Tue, 07 Apr 2026 21:45:51 -0700
Subject: [PATCH 03/16] riscv: kgdb: Use generated instruction headers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260407-riscv_insn_table-v1-3-54b4736a1e77@gmail.com>
References: <20260407-riscv_insn_table-v1-0-54b4736a1e77@gmail.com>
In-Reply-To: <20260407-riscv_insn_table-v1-0-54b4736a1e77@gmail.com>
To: Paul Walmsley <pjw@kernel.org>, Palmer Dabbelt <palmer@dabbelt.com>, 
 Alexandre Ghiti <alex@ghiti.fr>, Anup Patel <anup@brainfault.org>, 
 Atish Patra <atish.patra@linux.dev>, Conor Dooley <conor@kernel.org>, 
 Paolo Bonzini <pbonzini@redhat.com>, 
 Andrew Morton <akpm@linux-foundation.org>, Shuah Khan <shuah@kernel.org>
Cc: linux-riscv@lists.infradead.org, linux-kernel@vger.kernel.org, 
 kvm@vger.kernel.org, kvm-riscv@lists.infradead.org, 
 linux-kselftest@vger.kernel.org, 
 Charlie Jenkins <thecharlesjenkins@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1775623594; l=7745;
 i=thecharlesjenkins@gmail.com; s=2026030; h=from:subject:message-id;
 bh=wLizDAcF3npqRdFIpBhaPhxXS6KiGYMhVbuxqiXTwRk=;
 b=ULkzl8mpC5vn084DwHwkXEygvEG8yVKFDX4RkJnxoCg2v5M1nwXI5/2tKWLCId8vNwihiojjR
 qy7/I6NRim+AGHMDsTRwrA8Glh20aIIJLuZCJ2UZKbKLgEYdkWmgRCu
X-Developer-Key: i=thecharlesjenkins@gmail.com; a=ed25519;
 pk=vpF2USrG+aB6CTbSt34rzJKsAVe/l+GAXo1IomCMETk=
X-Endpoint-Received: by B4 Relay for thecharlesjenkins@gmail.com/2026030 with auth_id=663
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Migrate the code that is decoding instructions for the use of kgdb
single stepping to use the generated instruction headers instead of the
hand-written instruction functions.

Signed-off-by: Charlie Jenkins <thecharlesjenkins@gmail.com>

---

I tested this again by comparing the original get_step_address()
function with this new version and input all possible 32 bit numbers and
checked that the next_addr was the same in every case.

This is the code I used:

void check_step()
{
	for (unsigned long opcode = 0; opcode < ((1ULL << 32) - 1); opcode++) {
		unsigned long next_addr, next_addr2;
		get_step_address(opcode, &next_addr);
		get_step_address2(opcode, &next_addr2);
		if (next_addr != next_addr2) {
			printf("opcode: %lu -> %lu != %lu\n", opcode, next_addr, next_addr2);
		}
	}
}
---
 arch/riscv/include/asm/insn.h |  21 +++++++++
 arch/riscv/kernel/kgdb.c      | 102 ++++++++++++++++--------------------------
 2 files changed, 60 insertions(+), 63 deletions(-)

diff --git a/arch/riscv/include/asm/insn.h b/arch/riscv/include/asm/insn.h
index d0e137f9bcd7..c808e1e15192 100644
--- a/arch/riscv/include/asm/insn.h
+++ b/arch/riscv/include/asm/insn.h
@@ -514,4 +514,25 @@ static __always_inline bool riscv_insn_is_branch(u32 code)
 
 #define RVV_EXTRACT_VL_VS_WIDTH(x) RVFDQ_EXTRACT_FL_FS_WIDTH(x)
 
+static inline unsigned long riscv_insn_reg_get_val(unsigned long *regs, u32 index)
+{
+	/* register 0 is always 0 and not stored in the register struct */
+	return index ? *(regs + index) : 0;
+}
+
+#define riscv_insn_branch(_insn, regs_ptr, _opcode, _pc, _comparison, type)     \
+	({                                                                      \
+		unsigned long _ret;                                             \
+		if ((type)riscv_insn_reg_get_val(                               \
+			    regs_ptr,                                           \
+			    riscv_insn_##_insn##_extract_xs1(_opcode))          \
+			    _comparison(type) riscv_insn_reg_get_val(           \
+				    regs_ptr,                                   \
+				    riscv_insn_##_insn##_extract_xs2(_opcode))) \
+			_ret = riscv_insn_##_insn##_extract_imm(_opcode);       \
+		else                                                            \
+			_ret = _pc + 4;                                         \
+		_ret;                                                           \
+	})
+
 #endif /* _ASM_RISCV_INSN_H */
diff --git a/arch/riscv/kernel/kgdb.c b/arch/riscv/kernel/kgdb.c
index 15fec5d1e6de..dd878ba6b47e 100644
--- a/arch/riscv/kernel/kgdb.c
+++ b/arch/riscv/kernel/kgdb.c
@@ -23,97 +23,73 @@ enum {
 static unsigned long stepped_address;
 static unsigned int stepped_opcode;
 
-static int decode_register_index(unsigned long opcode, int offset)
-{
-	return (opcode >> offset) & 0x1F;
-}
-
-static int decode_register_index_short(unsigned long opcode, int offset)
-{
-	return ((opcode >> offset) & 0x7) + 8;
-}
-
-/* Calculate the new address for after a step */
 static int get_step_address(struct pt_regs *regs, unsigned long *next_addr)
 {
 	unsigned long pc = regs->epc;
 	unsigned long *regs_ptr = (unsigned long *)regs;
-	unsigned int rs1_num, rs2_num;
+	unsigned int rs1_num;
 	int op_code;
 
 	if (get_kernel_nofault(op_code, (void *)pc))
 		return -EINVAL;
+
 	if ((op_code & __INSN_LENGTH_MASK) != __INSN_LENGTH_GE_32) {
-		if (riscv_insn_is_c_jalr(op_code) ||
-		    riscv_insn_is_c_jr(op_code)) {
-			rs1_num = decode_register_index(op_code, RVC_C2_RS1_OPOFF);
-			*next_addr = regs_ptr[rs1_num];
-		} else if (riscv_insn_is_c_j(op_code) ||
-			   riscv_insn_is_c_jal(op_code)) {
-			*next_addr = RVC_EXTRACT_JTYPE_IMM(op_code) + pc;
+		if (riscv_insn_is_c_jalr(op_code)) {
+			*next_addr = regs_ptr[riscv_insn_c_jalr_extract_xs1(op_code)];
+		} else if (riscv_insn_is_c_jr(op_code)) {
+			*next_addr = regs_ptr[riscv_insn_c_jr_extract_xs1(op_code)];
+		} else if (riscv_insn_is_c_j(op_code)) {
+			*next_addr = riscv_insn_c_j_extract_imm(op_code) + pc;
+		} else if (riscv_insn_is_c_jal(op_code)) {
+			*next_addr = riscv_insn_c_jal_extract_imm(op_code) + pc;
 		} else if (riscv_insn_is_c_beqz(op_code)) {
-			rs1_num = decode_register_index_short(op_code,
-							      RVC_C1_RS1_OPOFF);
-			if (!rs1_num || regs_ptr[rs1_num] == 0)
-				*next_addr = RVC_EXTRACT_BTYPE_IMM(op_code) + pc;
+			rs1_num = riscv_insn_c_beqz_extract_xs1(op_code);
+			if (regs_ptr[8 + rs1_num] == 0)
+				*next_addr = riscv_insn_c_beqz_extract_imm(op_code) + pc;
 			else
 				*next_addr = pc + 2;
 		} else if (riscv_insn_is_c_bnez(op_code)) {
-			rs1_num =
-			    decode_register_index_short(op_code, RVC_C1_RS1_OPOFF);
-			if (rs1_num && regs_ptr[rs1_num] != 0)
-				*next_addr = RVC_EXTRACT_BTYPE_IMM(op_code) + pc;
+			rs1_num = riscv_insn_c_bnez_extract_xs1(op_code);
+			if (regs_ptr[8 + rs1_num] != 0)
+				*next_addr = riscv_insn_c_bnez_extract_imm(op_code) + pc;
 			else
 				*next_addr = pc + 2;
 		} else {
 			*next_addr = pc + 2;
 		}
 	} else {
-		if ((op_code & __INSN_OPCODE_MASK) == __INSN_BRANCH_OPCODE) {
-			bool result = false;
-			long imm = RV_EXTRACT_BTYPE_IMM(op_code);
-			unsigned long rs1_val = 0, rs2_val = 0;
-
-			rs1_num = decode_register_index(op_code, RVG_RS1_OPOFF);
-			rs2_num = decode_register_index(op_code, RVG_RS2_OPOFF);
-			if (rs1_num)
-				rs1_val = regs_ptr[rs1_num];
-			if (rs2_num)
-				rs2_val = regs_ptr[rs2_num];
-
-			if (riscv_insn_is_beq(op_code))
-				result = (rs1_val == rs2_val) ? true : false;
-			else if (riscv_insn_is_bne(op_code))
-				result = (rs1_val != rs2_val) ? true : false;
-			else if (riscv_insn_is_blt(op_code))
-				result =
-				    ((long)rs1_val <
-				     (long)rs2_val) ? true : false;
-			else if (riscv_insn_is_bge(op_code))
-				result =
-				    ((long)rs1_val >=
-				     (long)rs2_val) ? true : false;
-			else if (riscv_insn_is_bltu(op_code))
-				result = (rs1_val < rs2_val) ? true : false;
-			else if (riscv_insn_is_bgeu(op_code))
-				result = (rs1_val >= rs2_val) ? true : false;
-			if (result)
-				*next_addr = imm + pc;
-			else
-				*next_addr = pc + 4;
+		if (riscv_insn_is_beq(op_code)) {
+			*next_addr = riscv_insn_branch(beq, regs_ptr, op_code,
+						       pc, ==, unsigned long);
+		} else if (riscv_insn_is_bne(op_code)) {
+			*next_addr = riscv_insn_branch(bne, regs_ptr, op_code,
+						       pc, !=, unsigned long);
+		} else if (riscv_insn_is_blt(op_code)) {
+			*next_addr = riscv_insn_branch(blt, regs_ptr, op_code,
+						       pc, <, long);
+		} else if (riscv_insn_is_bge(op_code)) {
+			*next_addr = riscv_insn_branch(bge, regs_ptr, op_code,
+						       pc, >=, long);
+		} else if (riscv_insn_is_bltu(op_code)) {
+			*next_addr = riscv_insn_branch(bltu, regs_ptr, op_code,
+						       pc, <, unsigned long);
+		} else if (riscv_insn_is_bgeu(op_code)) {
+			*next_addr = riscv_insn_branch(bgeu, regs_ptr, op_code,
+						       pc, >=, unsigned long);
 		} else if (riscv_insn_is_jal(op_code)) {
-			*next_addr = RV_EXTRACT_JTYPE_IMM(op_code) + pc;
+			*next_addr = riscv_insn_jal_extract_imm(op_code) + pc;
 		} else if (riscv_insn_is_jalr(op_code)) {
-			rs1_num = decode_register_index(op_code, RVG_RS1_OPOFF);
+			rs1_num = riscv_insn_jalr_extract_xs1(op_code);
 			if (rs1_num)
-				*next_addr = ((unsigned long *)regs)[rs1_num];
-			*next_addr += RV_EXTRACT_ITYPE_IMM(op_code);
+				*next_addr = regs_ptr[rs1_num];
+			*next_addr += riscv_insn_jalr_extract_imm(op_code);
 		} else if (riscv_insn_is_sret(op_code)) {
 			*next_addr = pc;
 		} else {
 			*next_addr = pc + 4;
 		}
 	}
+
 	return 0;
 }
 

-- 
2.52.0

