From: Charlie Jenkins <thecharlesjenkins@gmail.com>
Date: Tue, 07 Apr 2026 21:45:53 -0700
Subject: [PATCH 05/16] riscv: cfi: Use generated instruction headers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260407-riscv_insn_table-v1-5-54b4736a1e77@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1775623594; l=1198;
 i=thecharlesjenkins@gmail.com; s=2026030; h=from:subject:message-id;
 bh=7VtWsi3USdmOKI/2dEDNXqFzi/ps3TMNRy1rcPp7qHk=;
 b=JkxmJoFaOoNr0y+eRwrfHP/YVmhcaiaertrKCpDjsoy0DwxP6yT3ArS34g7gxriu71lUt6wJu
 sXZ75QzbZgxBRrvJ4GepZR6ZFBcdh4hHjhKCA2FKx39bKP08q1sye4y
X-Developer-Key: i=thecharlesjenkins@gmail.com; a=ed25519;
 pk=vpF2USrG+aB6CTbSt34rzJKsAVe/l+GAXo1IomCMETk=
X-Endpoint-Received: by B4 Relay for thecharlesjenkins@gmail.com/2026030 with auth_id=663
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Migrate the code that is decoding cfi instructions to use the generated
instruction headers.

Signed-off-by: Charlie Jenkins <thecharlesjenkins@gmail.com>

---

This function generates the same assembly as before.
---
 arch/riscv/kernel/cfi.c | 6 +++---
 1 file changed, 3 insertions(+), 3 deletions(-)

diff --git a/arch/riscv/kernel/cfi.c b/arch/riscv/kernel/cfi.c
index 6ec9dbd7292e..e38d5f863747 100644
--- a/arch/riscv/kernel/cfi.c
+++ b/arch/riscv/kernel/cfi.c
@@ -40,16 +40,16 @@ static bool decode_cfi_insn(struct pt_regs *regs, unsigned long *target,
 	if (!riscv_insn_is_beq(insn))
 		return false;
 
-	*type = (u32)regs_ptr[RV_EXTRACT_RS1_REG(insn)];
+	*type = (u32)regs_ptr[riscv_insn_beq_extract_xs1(insn)];
 
 	if (get_kernel_nofault(insn, (void *)regs->epc) ||
 	    get_kernel_nofault(insn, (void *)regs->epc + GET_INSN_LENGTH(insn)))
 		return false;
 
 	if (riscv_insn_is_jalr(insn))
-		rs1_num = RV_EXTRACT_RS1_REG(insn);
+		rs1_num = riscv_insn_jalr_extract_xs1(insn);
 	else if (riscv_insn_is_c_jalr(insn))
-		rs1_num = RVC_EXTRACT_C2_RS1_REG(insn);
+		rs1_num = riscv_insn_c_jalr_extract_xs1(insn);
 	else
 		return false;
 

-- 
2.52.0

