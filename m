From: Charlie Jenkins <thecharlesjenkins@gmail.com>
Date: Sun, 21 Jun 2026 21:01:28 -0700
Subject: [PATCH v2 10/16] KVM: riscv: selftests: Add mmio test
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260621-riscv_insn_table-v2-10-7f0810ee2274@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1782100900; l=7221;
 i=thecharlesjenkins@gmail.com; s=20260605; h=from:subject:message-id;
 bh=nCg2zsUhW9tVCXwueee6U43Tp4lvMvAC4x/Uj6w1DKc=;
 b=FiX8G4yh2kmXn5pRN+SXywegB4kTjVIWJ6CUVfln9IvG8p5Z0j49ic/ko/Q6oCDElSlvSzUMQ
 yGr78gl5jtACmSIhKleRZqcsS7hOJnL88KBuW01ZcepJnD6n0cykO4M
X-Developer-Key: i=thecharlesjenkins@gmail.com; a=ed25519;
 pk=ajnnRQ98PIdwKp4HeMkq9U32okYbnh6Zb4G3o5XXvkg=
X-Endpoint-Received: by B4 Relay for thecharlesjenkins@gmail.com/20260605 with auth_id=810
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Use the test KVM device to validate that reads and writes to a device
are properly emulated by KVM. This test checks all load and store
instructions that are emulated by KVM.

Signed-off-by: Charlie Jenkins <thecharlesjenkins@gmail.com>
---
 tools/testing/selftests/kvm/Makefile.kvm      |   1 +
 tools/testing/selftests/kvm/riscv/mmio_test.c | 184 ++++++++++++++++++++++++++
 2 files changed, 185 insertions(+)

diff --git a/tools/testing/selftests/kvm/Makefile.kvm b/tools/testing/selftests/kvm/Makefile.kvm
index 9118a5a51b89..07a5fc2bf67c 100644
--- a/tools/testing/selftests/kvm/Makefile.kvm
+++ b/tools/testing/selftests/kvm/Makefile.kvm
@@ -214,6 +214,7 @@ TEST_GEN_PROGS_s390 += mmu_stress_test
 TEST_GEN_PROGS_riscv = $(TEST_GEN_PROGS_COMMON)
 TEST_GEN_PROGS_riscv += riscv/sbi_pmu_test
 TEST_GEN_PROGS_riscv += riscv/ebreak_test
+TEST_GEN_PROGS_riscv += riscv/mmio_test
 TEST_GEN_PROGS_riscv += access_tracking_perf_test
 TEST_GEN_PROGS_riscv += arch_timer
 TEST_GEN_PROGS_riscv += coalesced_io_test
diff --git a/tools/testing/selftests/kvm/riscv/mmio_test.c b/tools/testing/selftests/kvm/riscv/mmio_test.c
new file mode 100644
index 000000000000..9726860a269a
--- /dev/null
+++ b/tools/testing/selftests/kvm/riscv/mmio_test.c
@@ -0,0 +1,184 @@
+// SPDX-License-Identifier: GPL-2.0-only
+/*
+ * mmio_test.c - Tests the mmio functionality.
+ */
+#include "kvm_util.h"
+#include "ucall_common.h"
+
+#define MMIO_TEST_REGION 0x20000000
+
+#define test_standard_read(len, instruction, name, options)					\
+static void test_##name(void)									\
+{												\
+	unsigned long mmio_result, reference_result;						\
+	/* Configure the MMIO to return 0xff for each byte to check sign extension */		\
+	unsigned long reference = ((unsigned long)-1 >> ((sizeof(long) - len) * 8));		\
+	*((unsigned long *)MMIO_TEST_REGION) = reference;					\
+	/* Check that reads through MMIO are equivalent to standard reads. */			\
+	asm volatile (										\
+		".option push\n"								\
+		options										\
+		#instruction "	%[mmio_res], 0(%[region])\n"					\
+		#instruction "	%[ref_res], 0(%[ref])\n"					\
+		".option pop\n"									\
+		: [mmio_res] "=&cr" (mmio_result), [ref_res] "=&cr" (reference_result)		\
+		: [region] "cr" (MMIO_TEST_REGION), [ref] "cr" (&reference)			\
+	);											\
+	GUEST_ASSERT_EQ(mmio_result, reference_result);						\
+	GUEST_DONE();										\
+}
+
+#define test_sp_read(len, instruction, name)							\
+static void test_##name(void)									\
+{												\
+	unsigned long mmio_result, reference_result;						\
+	unsigned long tmp;									\
+	/* Configure the MMIO to return 0xff for each byte to check sign extension */		\
+	unsigned long reference = ((unsigned long)-1 >> ((sizeof(long) - len) * 8));		\
+	*(((unsigned long *)MMIO_TEST_REGION)) = reference;					\
+	/* Check that reads through MMIO are equivalent to standard reads. */			\
+	asm volatile (										\
+		"mv	%[tmp], sp\n"								\
+		"mv	sp, %[region]\n"							\
+		".option push\n"								\
+		".option arch,+c\n"								\
+		#instruction "	%[mmio_res], 0(sp)\n"						\
+		"mv	sp, %[ref]\n"								\
+		#instruction "	%[ref_res], 0(sp)\n"						\
+		".option pop\n"									\
+		"mv	sp, %[tmp]\n"								\
+		: [mmio_res]  "=&cr" (mmio_result), [ref_res] "=&cr" (reference_result),	\
+		  [tmp] "=&r" (tmp)								\
+		: [region] "r" (MMIO_TEST_REGION), [ref] "cr" (&reference)			\
+	);											\
+	GUEST_ASSERT_EQ(mmio_result, reference_result);						\
+	GUEST_DONE();										\
+}
+
+test_standard_read(1, lb, lb, "")
+test_standard_read(1, lbu, lbu, "")
+test_standard_read(4, lw, lw, "")
+test_standard_read(4, c.lw, c_lw, ".option arch,+c\n")
+test_sp_read(4, c.lwsp, c_lwsp)
+
+#if __riscv_xlen == 64
+test_standard_read(2, lh, lh, "")
+test_standard_read(2, lhu, lhu, "")
+test_standard_read(4, lwu, lwu, "")
+test_standard_read(8, ld, ld, "")
+test_standard_read(8, c.ld, c_ld, ".option arch,+c\n")
+test_sp_read(8, c.ldsp, c_ldsp)
+#endif
+
+#define test_standard_write(len, write, read, name, options)					\
+static void test_##name(void)									\
+{												\
+	unsigned long result;									\
+	unsigned long reference = (0x55555555UL >> ((sizeof(long) - len) * 8));			\
+	/* Check that we can write and then read the same value. */				\
+	asm volatile (										\
+		".option push\n"								\
+		options										\
+		#write "	%[ref], 0(%[region])\n"						\
+		#read "		%[res], 0(%[region])\n"						\
+		".option pop\n"									\
+		: [res] "=&cr" (result)								\
+		: [region] "cr" (MMIO_TEST_REGION), [ref] "cr" (reference)			\
+	);											\
+	GUEST_ASSERT_EQ(result, reference);							\
+	GUEST_DONE();										\
+}
+
+#define test_sp_write(len, write, read, name)							\
+static void test_##name(void)									\
+{												\
+	unsigned long result;									\
+	unsigned long tmp;									\
+	unsigned long reference = (0x55555555UL >> ((sizeof(long) - len) * 8));			\
+	/* Check that we can write and then read the same value. */				\
+	asm volatile (										\
+		"mv	%[tmp], sp\n"								\
+		"mv	sp, %[region]\n"							\
+		".option push\n"								\
+		".option arch,+c\n"								\
+		#write "	%[ref], 0(sp)\n"						\
+		#read "		%[res], 0(sp)\n"						\
+		".option pop\n"									\
+		"mv	sp, %[tmp]\n"								\
+		: [res] "=&cr" (result), [tmp] "=&r" (tmp)					\
+		: [region] "cr" (MMIO_TEST_REGION), [ref] "cr" (reference)			\
+	);											\
+	GUEST_ASSERT_EQ(result, reference);							\
+	GUEST_DONE();										\
+}
+
+test_standard_write(1, sb, lb, sb, "")
+test_standard_write(2, sh, lh, sh, "")
+test_standard_write(4, sw, lw, sw, "")
+test_standard_write(4, c.sw, c.lw, c_sw, ".option arch,+c\n")
+test_sp_write(4, c.swsp, c.lwsp, c_swsp)
+
+#if __riscv_xlen == 64
+test_standard_write(8, sd, ld, sd, "")
+test_standard_write(8, c.sd, c.ld, c_sd, ".option arch,+c\n")
+#endif
+
+static void run(void *guest_code, char *instruction)
+{
+	struct ucall uc;
+	struct kvm_vm *vm;
+	struct kvm_vcpu *vcpu;
+
+	vm = vm_create_with_one_vcpu(&vcpu, guest_code);
+	kvm_create_device(vm, KVM_DEV_TYPE_TEST);
+
+	virt_map(vm, (unsigned long)MMIO_TEST_REGION, MMIO_TEST_REGION, 1);
+
+	vcpu_run(vcpu);
+
+	TEST_ASSERT(get_ucall(vcpu, &uc) == UCALL_DONE,
+		    "MMIO with instruction '%s' failed: '%s'", instruction,
+		    uc.buffer);
+
+	kvm_vm_free(vm);
+}
+
+void test_mmio_read_sign_extension(void)
+{
+	run(test_lb, "lb");
+	run(test_lbu, "lbu");
+	run(test_lw, "lw");
+	run(test_c_lw, "c.lw");
+	run(test_c_lwsp, "c.lwsp");
+
+#if __riscv_xlen == 64
+	run(test_lh, "lh");
+	run(test_lhu, "lhu");
+	run(test_lwu, "lwu");
+	run(test_ld, "ld");
+	run(test_c_ld, "c.ld");
+	run(test_c_ldsp, "c.ldsp");
+#endif
+}
+
+void test_mmio_write(void)
+{
+	run(test_sb, "sb");
+	run(test_sh, "sh");
+	run(test_sw, "sw");
+	run(test_c_sw, "c.sw");
+	run(test_c_swsp, "c.swsp");
+
+#if __riscv_xlen == 64
+	run(test_sd, "sd");
+	run(test_c_sd, "c.sd");
+#endif
+}
+
+int main(void)
+{
+	test_mmio_read_sign_extension();
+	test_mmio_write();
+
+	return 0;
+}

-- 
2.54.0

