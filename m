From: Charlie Jenkins <thecharlesjenkins@gmail.com>
Date: Sun, 21 Jun 2026 21:01:22 -0700
Subject: [PATCH v2 04/16] riscv: Add kprobes instruction simulation KUnit
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260621-riscv_insn_table-v2-4-7f0810ee2274@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1782100900; l=11557;
 i=thecharlesjenkins@gmail.com; s=20260605; h=from:subject:message-id;
 bh=+jKWnHeDczH8xoiHIK3Lygi5Gw6AxgY9uMrA5zkeP54=;
 b=eBbrfi0UK3lHu/X+8/rzc81EDyRBf+eKcjHqg9HPWAjCsF8mvuP6WWEhWNSllFspkQrO4MQPC
 TTyzd5JsR9hBbtO1kzgTASbBmrlASY1HJ7/W8B4x4h5EVE/sw3/WLDK
X-Developer-Key: i=thecharlesjenkins@gmail.com; a=ed25519;
 pk=ajnnRQ98PIdwKp4HeMkq9U32okYbnh6Zb4G3o5XXvkg=
X-Endpoint-Received: by B4 Relay for thecharlesjenkins@gmail.com/20260605 with auth_id=810
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This KUnit iterates through all 32-bit integers and validates that the
simulation code for kprobes simulates properly. These tests are very
slow so they are gated behind a new kconfig option
CONFIG_RISCV_KPROBES_SIMULATE_KUNIT.

Signed-off-by: Charlie Jenkins <thecharlesjenkins@gmail.com>
---
 arch/riscv/kernel/tests/Kconfig.debug              |  13 ++
 arch/riscv/kernel/tests/kprobes/Makefile           |   2 +
 .../kernel/tests/kprobes/test-kprobes-simulate.c   | 250 +++++++++++++++++++++
 arch/riscv/kernel/tests/kprobes/test-kprobes.h     |   6 +
 4 files changed, 271 insertions(+)

diff --git a/arch/riscv/kernel/tests/Kconfig.debug b/arch/riscv/kernel/tests/Kconfig.debug
index 40f8dafffa0a..9eda8938ec15 100644
--- a/arch/riscv/kernel/tests/Kconfig.debug
+++ b/arch/riscv/kernel/tests/Kconfig.debug
@@ -42,6 +42,19 @@ config RISCV_KPROBES_KUNIT
 
          If unsure, say N.
 
+config RISCV_KPROBES_SIMULATE_KUNIT
+       tristate "KUnit test for riscv kprobes instruction simulation" if !KUNIT_ALL_TESTS
+       depends on KUNIT
+       depends on KPROBES
+       default KUNIT_ALL_TESTS
+       help
+         Enable testing for riscv kprobes instruction simulation. Useful for
+         riscv and/or kprobes development. The test verifies that kprobes
+         instruction simulation properly simulates the instructions. These tests
+         are very slow.
+
+         If unsure, say N.
+
 endif # RUNTIME_TESTING_MENU
 
 endmenu # "arch/riscv/kernel runtime Testing"
diff --git a/arch/riscv/kernel/tests/kprobes/Makefile b/arch/riscv/kernel/tests/kprobes/Makefile
index df7256f62313..34db6044e87f 100644
--- a/arch/riscv/kernel/tests/kprobes/Makefile
+++ b/arch/riscv/kernel/tests/kprobes/Makefile
@@ -1,3 +1,5 @@
 obj-$(CONFIG_RISCV_KPROBES_KUNIT) += kprobes_riscv_kunit.o
+obj-$(CONFIG_RISCV_KPROBES_SIMULATE_KUNIT) += kprobes_simulate_riscv_kunit.o
 
 kprobes_riscv_kunit-objs := test-kprobes.o test-kprobes-asm.o
+kprobes_simulate_riscv_kunit-objs := test-kprobes-simulate.o
diff --git a/arch/riscv/kernel/tests/kprobes/test-kprobes-simulate.c b/arch/riscv/kernel/tests/kprobes/test-kprobes-simulate.c
new file mode 100644
index 000000000000..d82706685823
--- /dev/null
+++ b/arch/riscv/kernel/tests/kprobes/test-kprobes-simulate.c
@@ -0,0 +1,250 @@
+// SPDX-License-Identifier: GPL-2.0+
+
+#include <linux/kernel.h>
+#include <linux/kprobes.h>
+#include <kunit/test.h>
+
+#include "../../probes/simulate-insn.h"
+
+#include <asm/insn.h>
+#include <asm/text-patching.h>
+
+static void test_kprobe_simulate_riscv(struct kunit *test)
+{
+	unsigned int addr = 0xdeadbeef;
+	unsigned int i = 0;
+
+	do {
+		struct pt_regs regs = { 0 };
+
+		if (riscv_insn_is_jal(i)) {
+			s32 offset = riscv_insn_jal_extract_imm(i);
+			u32 xd_index = riscv_insn_jal_extract_xd(i);
+
+			simulate_jal(i, addr, &regs);
+
+			KUNIT_EXPECT_EQ_MSG(test, regs.epc, addr + offset,
+					    "jal instruction (0x%x) incorrectly simulated", i);
+
+			if (xd_index)
+				KUNIT_EXPECT_EQ_MSG(
+					test,
+					riscv_insn_reg_get_val((unsigned long *)&regs, xd_index),
+					addr + 4, "jal instruction (0x%x) incorrectly simulated",
+					i);
+		}
+		if (riscv_insn_is_jalr(i)) {
+			unsigned long reg_addr = 0xffff;
+			s32 offset = riscv_insn_jalr_extract_imm(i);
+			u32 rd_index = riscv_insn_jalr_extract_xd(i);
+			u32 rs1_index = riscv_insn_jalr_extract_xs1(i);
+
+			if (rs1_index)
+				riscv_insn_reg_set_val((unsigned long *)&regs, rs1_index, reg_addr);
+			else
+				reg_addr = 0;
+
+			simulate_jalr(i, addr, &regs);
+
+			KUNIT_EXPECT_EQ_MSG(test, regs.epc, (reg_addr + offset) & ~1,
+					    "jalr instruction (0x%x) incorrectly simulated", i);
+
+			if (rd_index)
+				KUNIT_EXPECT_EQ_MSG(
+					test,
+					riscv_insn_reg_get_val((unsigned long *)&regs, rd_index),
+					addr + 4, "jalr instruction (0x%x) incorrectly simulated",
+					i);
+		} else if (riscv_insn_is_auipc(i)) {
+			s32 offset = riscv_insn_auipc_extract_imm(i);
+			u32 rd_index = riscv_insn_auipc_extract_xd(i);
+
+			simulate_auipc(i, addr, &regs);
+
+			KUNIT_EXPECT_EQ_MSG(test, regs.epc, addr + 4,
+					    "auipc instruction (0x%x) incorrectly simulated", i);
+
+			if (rd_index)
+				KUNIT_EXPECT_EQ_MSG(
+					test,
+					riscv_insn_reg_get_val((unsigned long *)&regs, rd_index),
+					(unsigned long)addr + offset,
+					"auipc instruction (0x%x) incorrectly simulated", i);
+		} else if (riscv_insn_is_beq(i)) {
+			s32 offset = riscv_insn_beq_extract_imm(i);
+			u32 rs1_index = riscv_insn_beq_extract_xs1(i);
+			u32 rs2_index = riscv_insn_beq_extract_xs2(i);
+
+			simulate_beq(i, addr, &regs);
+
+			if (riscv_insn_reg_get_val((unsigned long *)&regs, rs1_index) ==
+			    riscv_insn_reg_get_val((unsigned long *)&regs, rs2_index)) {
+				KUNIT_EXPECT_EQ_MSG(test, regs.epc, addr + offset,
+						    "beq instruction (0x%x) incorrectly simulated",
+						    i);
+			} else {
+				KUNIT_EXPECT_EQ_MSG(test, regs.epc, addr + 4,
+						    "beq instruction (0x%x) incorrectly simulated",
+						    i);
+			}
+		} else if (riscv_insn_is_bne(i)) {
+			s32 offset = riscv_insn_bne_extract_imm(i);
+			u32 rs1_index = riscv_insn_bne_extract_xs1(i);
+			u32 rs2_index = riscv_insn_bne_extract_xs2(i);
+
+			simulate_bne(i, addr, &regs);
+
+			if (riscv_insn_reg_get_val((unsigned long *)&regs, rs1_index) !=
+			    riscv_insn_reg_get_val((unsigned long *)&regs, rs2_index)) {
+				KUNIT_EXPECT_EQ_MSG(test, regs.epc, addr + offset,
+						    "bne instruction (0x%x) incorrectly simulated",
+						    i);
+			} else {
+				KUNIT_EXPECT_EQ_MSG(test, regs.epc, addr + 4,
+						    "bne instruction (0x%x) incorrectly simulated",
+						    i);
+			}
+		} else if (riscv_insn_is_blt(i)) {
+			s32 offset = riscv_insn_blt_extract_imm(i);
+			u32 rs1_index = riscv_insn_blt_extract_xs1(i);
+			u32 rs2_index = riscv_insn_blt_extract_xs2(i);
+
+			simulate_blt(i, addr, &regs);
+
+			if ((long)riscv_insn_reg_get_val((unsigned long *)&regs, rs1_index) <
+			    (long)riscv_insn_reg_get_val((unsigned long *)&regs, rs2_index)) {
+				KUNIT_EXPECT_EQ_MSG(test, regs.epc, addr + offset,
+						    "blt instruction (0x%x) incorrectly simulated",
+						    i);
+			} else {
+				KUNIT_EXPECT_EQ_MSG(test, regs.epc, addr + 4,
+						    "blt instruction (0x%x) incorrectly simulated",
+						    i);
+			}
+		} else if (riscv_insn_is_bge(i)) {
+			s32 offset = riscv_insn_bge_extract_imm(i);
+			u32 rs1_index = riscv_insn_bge_extract_xs1(i);
+			u32 rs2_index = riscv_insn_bge_extract_xs2(i);
+
+			simulate_bge(i, addr, &regs);
+
+			if ((long)riscv_insn_reg_get_val((unsigned long *)&regs, rs1_index) >=
+			    (long)riscv_insn_reg_get_val((unsigned long *)&regs, rs2_index)) {
+				KUNIT_EXPECT_EQ_MSG(test, regs.epc, addr + offset,
+						    "bge instruction (0x%x) incorrectly simulated",
+						    i);
+			} else {
+				KUNIT_EXPECT_EQ_MSG(test, regs.epc, addr + 4,
+						    "bge instruction (0x%x) incorrectly simulated",
+						    i);
+			}
+		} else if (riscv_insn_is_bltu(i)) {
+			s32 offset = riscv_insn_bltu_extract_imm(i);
+			u32 rs1_index = riscv_insn_bltu_extract_xs1(i);
+			u32 rs2_index = riscv_insn_bltu_extract_xs2(i);
+
+			simulate_bltu(i, addr, &regs);
+
+			if (riscv_insn_reg_get_val((unsigned long *)&regs, rs1_index) <
+			    riscv_insn_reg_get_val((unsigned long *)&regs, rs2_index)) {
+				KUNIT_EXPECT_EQ_MSG(test, regs.epc, addr + offset,
+						    "bltu instruction (0x%x) incorrectly simulated",
+						    i);
+			} else {
+				KUNIT_EXPECT_EQ_MSG(test, regs.epc, addr + 4,
+						    "bltu instruction (0x%x) incorrectly simulated",
+						    i);
+			}
+		} else if (riscv_insn_is_bgeu(i)) {
+			s32 offset = riscv_insn_bgeu_extract_imm(i);
+			u32 rs1_index = riscv_insn_bgeu_extract_xs1(i);
+			u32 rs2_index = riscv_insn_bgeu_extract_xs2(i);
+
+			simulate_bgeu(i, addr, &regs);
+
+			if (riscv_insn_reg_get_val((unsigned long *)&regs, rs1_index) >=
+			    riscv_insn_reg_get_val((unsigned long *)&regs, rs2_index)) {
+				KUNIT_EXPECT_EQ_MSG(test, regs.epc, addr + offset,
+						    "bgeu instruction (0x%x) incorrectly simulated",
+						    i);
+			} else {
+				KUNIT_EXPECT_EQ_MSG(test, regs.epc, addr + 4,
+						    "bgeu instruction (0x%x) incorrectly simulated",
+						    i);
+			}
+		} else if (riscv_insn_is_c_j(i)) {
+			s32 offset = riscv_insn_c_j_extract_imm(i);
+
+			simulate_c_j(i, addr, &regs);
+
+			KUNIT_EXPECT_EQ_MSG(test, regs.epc, addr + offset,
+					    "c.j instruction (0x%x) incorrectly simulated", i);
+		} else if (riscv_insn_is_c_jr(i)) {
+			u32 rs1_index = riscv_insn_c_jr_extract_xs1(i);
+
+			simulate_c_jr(i, addr, &regs);
+
+			KUNIT_EXPECT_EQ_MSG(test, regs.epc,
+					    riscv_insn_reg_get_val((unsigned long *)&regs,
+								   rs1_index),
+					    "c.jr instruction (0x%x) incorrectly simulated", i);
+		} else if (riscv_insn_is_c_jalr(i)) {
+			unsigned long reg_addr = 0xffff;
+			u32 rs1_index = riscv_insn_c_jalr_extract_xs1(i);
+
+			if (rs1_index)
+				riscv_insn_reg_set_val((unsigned long *)&regs, rs1_index, reg_addr);
+			else
+				reg_addr = 0;
+
+			simulate_c_jalr(i, addr, &regs);
+
+			KUNIT_EXPECT_EQ_MSG(test, regs.epc, reg_addr,
+					    "c.jalr instruction (0x%x) incorrectly simulated", i);
+
+			KUNIT_EXPECT_EQ_MSG(test, regs.ra, addr + 2,
+					    "c.jalr instruction (0x%x) incorrectly simulated", i);
+		} else if (riscv_insn_is_c_bnez(i)) {
+			u32 offset;
+			u32 rs1_index = riscv_insn_c_bnez_extract_xs1(i);
+
+			simulate_c_bnez(i, addr, &regs);
+
+			if (riscv_insn_reg_get_val((unsigned long *)&regs, rs1_index + 8) != 0)
+				offset = riscv_insn_c_bnez_extract_imm(i);
+			else
+				offset = 2;
+
+			KUNIT_EXPECT_EQ_MSG(test, regs.epc, addr + offset,
+					    "c.bnez instruction (0x%x) incorrectly simulated", i);
+		} else if (riscv_insn_is_c_beqz(i)) {
+			u32 offset;
+			u32 rs1_index = riscv_insn_c_beqz_extract_xs1(i);
+
+			simulate_c_beqz(i, addr, &regs);
+
+			if (riscv_insn_reg_get_val((unsigned long *)&regs, rs1_index + 8) == 0)
+				offset = riscv_insn_c_beqz_extract_imm(i);
+			else
+				offset = 2;
+
+			KUNIT_EXPECT_EQ_MSG(test, regs.epc, addr + offset,
+					    "c.beqz instruction (0x%x) incorrectly simulated", i);
+		}
+	} while (++i > 0);
+}
+
+static struct kunit_case kprobes_simulate_testcases[] = {
+	KUNIT_CASE_SLOW(test_kprobe_simulate_riscv),
+	{}
+};
+
+static struct kunit_suite kprobes_simulate_test_suite = {
+	.name = "kprobes_simulate_riscv",
+	.test_cases = kprobes_simulate_testcases,
+};
+
+kunit_test_suites(&kprobes_simulate_test_suite);
+
+MODULE_LICENSE("GPL");
+MODULE_DESCRIPTION("KUnit test for riscv kprobes instruction simulatation");
diff --git a/arch/riscv/kernel/tests/kprobes/test-kprobes.h b/arch/riscv/kernel/tests/kprobes/test-kprobes.h
index 537f44aa9d3f..7a672de8f130 100644
--- a/arch/riscv/kernel/tests/kprobes/test-kprobes.h
+++ b/arch/riscv/kernel/tests/kprobes/test-kprobes.h
@@ -19,6 +19,12 @@ extern void *test_kprobes_addresses[];
 /* array of functions that return KPROBE_TEST_MAGIC */
 extern long (*test_kprobes_functions[])(void);
 
+void test_kprobes_arbitrary(void);
+
+extern unsigned int *test_kprobes_arbitrary_addr;
+
+extern unsigned int *test_kprobes_c_bnez_addr1;
+
 #endif /* __ASSEMBLER__ */
 
 #endif /* TEST_KPROBES_H */

-- 
2.54.0

