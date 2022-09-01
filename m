From: Konstantin Ryabitsev <konstantin@linuxfoundation.org>
Date: Thu, 01 Sep 2022 15:29:06 -0400
Subject: [PATCH v5 21/21] x86: Add support for CONFIG_CFI_CLANG
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20220901-kcfi_support-v5-21-be2007d8da63@linuxfoundation.org>
References: <20220901-kcfi_support-v5-0-be2007d8da63@linuxfoundation.org>
In-Reply-To: <20220901-kcfi_support-v5-0-be2007d8da63@linuxfoundation.org>
To: mricon@kernel.org
X-Mailer: b4 0.10.0-dev-03aea
X-Developer-Signature: v=1; a=openpgp-sha256; l=10029;
 i=konstantin@linuxfoundation.org; h=from:subject:message-id;
 bh=IlyBvxcwvWSz/8N1+CeS34tsMgvyKxuP5YkcajGsp74=;
 b=owGbwMvMwCW27YjM47CUmTmMp9WSGJIF2X9zcSz4ZdAs/vuVVWqWV76B6IqEDIFJDBxnfmxRPqgr
 lt/TUcrCIMbFICumyFK2L3ZTUOFDD7n0HlOYOaxMIEMYuDgFYCLlkowMC15FPn66pb1Ou66+ZZdpg8
 FxywOfFvw4NW/asuczpt05zcfwz34e3887E7Vz/JLlnVcf+e4haGcswl4w4ZZjrseH6Ve7+QA=
X-Developer-Key: i=konstantin@linuxfoundation.org; a=openpgp;
 fpr=DE0E66E32F1FDD0902666B96E63EDCA9329DD07E
X-Endpoint-Received: by B4 Submission Endpoint for konstantin@linuxfoundation.org/default with auth_id=3
List-Id: B4 Web Endpoint Patches <b4-sent.feeds.kernel.org>

From: Sami Tolvanen <samitolvanen@google.com>

With CONFIG_CFI_CLANG, the compiler injects a type preamble immediately
before each function and a check to validate the target function type
before indirect calls:

  ; type preamble
  __cfi_function:
    mov <id>, %eax
  function:
    ...
  ; indirect call check
    mov     -<id>,%r10d
    add     -0x4(%r11),%r10d
    je      .Ltmp1
    ud2
  .Ltmp1:
    call    __x86_indirect_thunk_r11

Define the __CFI_TYPE helper macro for manually annotating indirectly
called assembly function with the identical premable, add error handling
code for the ud2 traps emitted for indirect call checks, and allow
CONFIG_CFI_CLANG to be selected on x86_64.

This produces the following oops on CFI failure (generated using lkdtm):

[   21.441706] CFI failure at lkdtm_indirect_call+0x16/0x20 [lkdtm]
(target: lkdtm_increment_int+0x0/0x10 [lkdtm]; expected type: 0x7e0c52a)
[   21.444579] invalid opcode: 0000 [#1] PREEMPT SMP NOPTI
[   21.445296] CPU: 0 PID: 132 Comm: sh Not tainted
5.19.0-rc8-00020-g9f27360e674c #1
[   21.445296] Hardware name: QEMU Standard PC (i440FX + PIIX, 1996),
BIOS rel-1.14.0-0-g155821a1990b-prebuilt.qemu.org 04/01/2014
[   21.445296] RIP: 0010:lkdtm_indirect_call+0x16/0x20 [lkdtm]
[   21.445296] Code: 52 1c c0 48 c7 c1 c5 50 1c c0 e9 25 48 2a cc 0f 1f
44 00 00 49 89 fb 48 c7 c7 50 b4 1c c0 41 ba 5b ad f3 81 45 03 53 f8
[   21.445296] RSP: 0018:ffffa9f9c02ffdc0 EFLAGS: 00000292
[   21.445296] RAX: 0000000000000027 RBX: ffffffffc01cb300 RCX: 385cbbd2e070a700
[   21.445296] RDX: 0000000000000000 RSI: c0000000ffffdfff RDI: ffffffffc01cb450
[   21.445296] RBP: 0000000000000006 R08: 0000000000000000 R09: ffffffff8d081610
[   21.445296] R10: 00000000bcc90825 R11: ffffffffc01c2fc0 R12: 0000000000000000
[   21.445296] R13: ffffa31b827a6000 R14: 0000000000000000 R15: 0000000000000002
[   21.445296] FS:  00007f08b42216a0(0000) GS:ffffa31b9f400000(0000)
knlGS:0000000000000000
[   21.445296] CS:  0010 DS: 0000 ES: 0000 CR0: 0000000080050033
[   21.445296] CR2: 0000000000c76678 CR3: 0000000001940000 CR4: 00000000000006f0
[   21.445296] Call Trace:
[   21.445296]  <TASK>
[   21.445296]  lkdtm_CFI_FORWARD_PROTO+0x30/0x50 [lkdtm]
[   21.445296]  direct_entry+0x12d/0x140 [lkdtm]
[   21.445296]  full_proxy_write+0x5d/0xb0
[   21.445296]  vfs_write+0x144/0x460
[   21.445296]  ? __x64_sys_wait4+0x5a/0xc0
[   21.445296]  ksys_write+0x69/0xd0
[   21.445296]  do_syscall_64+0x51/0xa0
[   21.445296]  entry_SYSCALL_64_after_hwframe+0x63/0xcd
[   21.445296] RIP: 0033:0x7f08b41a6fe1
[   21.445296] Code: be 07 00 00 00 41 89 c0 e8 7e ff ff ff 44 89 c7 89
04 24 e8 91 c6 02 00 8b 04 24 48 83 c4 68 c3 48 63 ff b8 01 00 00 03
[   21.445296] RSP: 002b:00007ffcdf65c2e8 EFLAGS: 00000246 ORIG_RAX: 0000000000000001
[   21.445296] RAX: ffffffffffffffda RBX: 00007f08b4221690 RCX: 00007f08b41a6fe1
[   21.445296] RDX: 0000000000000012 RSI: 0000000000c738f0 RDI: 0000000000000001
[   21.445296] RBP: 0000000000000001 R08: fefefefefefefeff R09: fefefefeffc5ff4e
[   21.445296] R10: 00007f08b42222b0 R11: 0000000000000246 R12: 0000000000c738f0
[   21.445296] R13: 0000000000000012 R14: 00007ffcdf65c401 R15: 0000000000c70450
[   21.445296]  </TASK>
[   21.445296] Modules linked in: lkdtm
[   21.445296] Dumping ftrace buffer:
[   21.445296]    (ftrace buffer empty)
[   21.471442] ---[ end trace 0000000000000000 ]---
[   21.471811] RIP: 0010:lkdtm_indirect_call+0x16/0x20 [lkdtm]
[   21.472467] Code: 52 1c c0 48 c7 c1 c5 50 1c c0 e9 25 48 2a cc 0f 1f
44 00 00 49 89 fb 48 c7 c7 50 b4 1c c0 41 ba 5b ad f3 81 45 03 53 f8
[   21.474400] RSP: 0018:ffffa9f9c02ffdc0 EFLAGS: 00000292
[   21.474735] RAX: 0000000000000027 RBX: ffffffffc01cb300 RCX: 385cbbd2e070a700
[   21.475664] RDX: 0000000000000000 RSI: c0000000ffffdfff RDI: ffffffffc01cb450
[   21.476471] RBP: 0000000000000006 R08: 0000000000000000 R09: ffffffff8d081610
[   21.477127] R10: 00000000bcc90825 R11: ffffffffc01c2fc0 R12: 0000000000000000
[   21.477959] R13: ffffa31b827a6000 R14: 0000000000000000 R15: 0000000000000002
[   21.478657] FS:  00007f08b42216a0(0000) GS:ffffa31b9f400000(0000)
knlGS:0000000000000000
[   21.479577] CS:  0010 DS: 0000 ES: 0000 CR0: 0000000080050033
[   21.480307] CR2: 0000000000c76678 CR3: 0000000001940000 CR4: 00000000000006f0
[   21.481460] Kernel panic - not syncing: Fatal exception

Signed-off-by: Sami Tolvanen <samitolvanen@google.com>
Reviewed-by: Kees Cook <keescook@chromium.org>
Tested-by: Kees Cook <keescook@chromium.org>

diff --git a/arch/x86/Kconfig b/arch/x86/Kconfig
index f9920f1341c8..1fe6a83dac05 100644
--- a/arch/x86/Kconfig
+++ b/arch/x86/Kconfig
@@ -107,6 +107,8 @@ config X86
 	select ARCH_SUPPORTS_PAGE_TABLE_CHECK	if X86_64
 	select ARCH_SUPPORTS_NUMA_BALANCING	if X86_64
 	select ARCH_SUPPORTS_KMAP_LOCAL_FORCE_MAP	if NR_CPUS <= 4096
+	select ARCH_SUPPORTS_CFI_CLANG		if X86_64
+	select ARCH_USES_CFI_TRAPS		if X86_64 && CFI_CLANG
 	select ARCH_SUPPORTS_LTO_CLANG
 	select ARCH_SUPPORTS_LTO_CLANG_THIN
 	select ARCH_USE_BUILTIN_BSWAP
diff --git a/arch/x86/include/asm/cfi.h b/arch/x86/include/asm/cfi.h
new file mode 100644
index 000000000000..58dacd90daef
--- /dev/null
+++ b/arch/x86/include/asm/cfi.h
@@ -0,0 +1,22 @@
+/* SPDX-License-Identifier: GPL-2.0 */
+#ifndef _ASM_X86_CFI_H
+#define _ASM_X86_CFI_H
+
+/*
+ * Clang Control Flow Integrity (CFI) support.
+ *
+ * Copyright (C) 2022 Google LLC
+ */
+
+#include <linux/cfi.h>
+
+#ifdef CONFIG_CFI_CLANG
+enum bug_trap_type handle_cfi_failure(struct pt_regs *regs);
+#else
+static inline enum bug_trap_type handle_cfi_failure(struct pt_regs *regs)
+{
+	return BUG_TRAP_TYPE_NONE;
+}
+#endif /* CONFIG_CFI_CLANG */
+
+#endif /* _ASM_X86_CFI_H */
diff --git a/arch/x86/include/asm/linkage.h b/arch/x86/include/asm/linkage.h
index 73ca20049835..ebfa05973312 100644
--- a/arch/x86/include/asm/linkage.h
+++ b/arch/x86/include/asm/linkage.h
@@ -29,6 +29,15 @@
 #endif
 #endif /* CONFIG_RETPOLINE */
 
+#ifdef CONFIG_CFI_CLANG
+#define __CFI_TYPE(name)					\
+	SYM_START(__cfi_##name, SYM_L_LOCAL, SYM_A_NONE)	\
+	.fill 11, 1, 0x90 ASM_NL				\
+	.byte 0xb8 ASM_NL					\
+	.long __kcfi_typeid_##name ASM_NL			\
+	SYM_FUNC_END(__cfi_##name)
+#endif
+
 #else /* __ASSEMBLY__ */
 
 #if defined(CONFIG_RETHUNK) && !defined(__DISABLE_EXPORTS) && !defined(BUILD_VDSO)
diff --git a/arch/x86/kernel/Makefile b/arch/x86/kernel/Makefile
index a20a5ebfacd7..1286a73ebdbc 100644
--- a/arch/x86/kernel/Makefile
+++ b/arch/x86/kernel/Makefile
@@ -139,6 +139,8 @@ obj-$(CONFIG_UNWINDER_GUESS)		+= unwind_guess.o
 
 obj-$(CONFIG_AMD_MEM_ENCRYPT)		+= sev.o
 
+obj-$(CONFIG_CFI_CLANG)			+= cfi.o
+
 ###
 # 64 bit specific files
 ifeq ($(CONFIG_X86_64),y)
diff --git a/arch/x86/kernel/cfi.c b/arch/x86/kernel/cfi.c
new file mode 100644
index 000000000000..e642c1af2678
--- /dev/null
+++ b/arch/x86/kernel/cfi.c
@@ -0,0 +1,85 @@
+// SPDX-License-Identifier: GPL-2.0
+/*
+ * Clang Control Flow Integrity (CFI) support.
+ *
+ * Copyright (C) 2022 Google LLC
+ */
+#include <asm/cfi.h>
+#include <asm/insn.h>
+#include <asm/insn-eval.h>
+
+/*
+ * Returns the target address and the expected type when regs->ip points
+ * to a compiler-generated CFI trap.
+ */
+static bool decode_cfi_insn(struct pt_regs *regs, unsigned long *target,
+			    u32 *type)
+{
+	char buffer[MAX_INSN_SIZE];
+	struct insn insn;
+	int offset = 0;
+
+	*target = *type = 0;
+
+	/*
+	 * The compiler generates the following instruction sequence
+	 * for indirect call checks:
+	 *
+	 *   movl    -<id>, %r10d       ; 6 bytes
+	 *   addl    -4(%reg), %r10d    ; 4 bytes
+	 *   je      .Ltmp1             ; 2 bytes
+	 *   ud2                        ; <- regs->ip
+	 *   .Ltmp1:
+	 *
+	 * We can decode the expected type and the target address from the
+	 * movl/addl instructions.
+	 */
+	if (copy_from_kernel_nofault(buffer, (void *)regs->ip - 12, MAX_INSN_SIZE))
+		return false;
+	if (insn_decode_kernel(&insn, &buffer[offset]))
+		return false;
+	if (insn.opcode.value != 0xBA)
+		return false;
+
+	*type = -(u32)insn.immediate.value;
+
+	if (copy_from_kernel_nofault(buffer, (void *)regs->ip - 6, MAX_INSN_SIZE))
+		return false;
+	if (insn_decode_kernel(&insn, &buffer[offset]))
+		return false;
+	if (insn.opcode.value != 0x3)
+		return false;
+
+	/* Read the target address from the register. */
+	offset = insn_get_modrm_rm_off(&insn, regs);
+	if (offset < 0)
+		return false;
+
+	*target = *(unsigned long *)((void *)regs + offset);
+
+	return true;
+}
+
+/*
+ * Checks if a ud2 trap is because of a CFI failure, and handles the trap
+ * if needed. Returns a bug_trap_type value similarly to report_bug.
+ */
+enum bug_trap_type handle_cfi_failure(struct pt_regs *regs)
+{
+	unsigned long target;
+	u32 type;
+
+	if (!is_cfi_trap(regs->ip))
+		return BUG_TRAP_TYPE_NONE;
+
+	if (!decode_cfi_insn(regs, &target, &type))
+		return report_cfi_failure_noaddr(regs, regs->ip);
+
+	return report_cfi_failure(regs, regs->ip, &target, type);
+}
+
+/*
+ * Ensure that __kcfi_typeid_ symbols are emitted for functions that may
+ * not be indirectly called with all configurations.
+ */
+__ADDRESSABLE(memcpy)
diff --git a/arch/x86/kernel/traps.c b/arch/x86/kernel/traps.c
index d62b2cb85cea..178015a820f0 100644
--- a/arch/x86/kernel/traps.c
+++ b/arch/x86/kernel/traps.c
@@ -63,6 +63,7 @@
 #include <asm/insn-eval.h>
 #include <asm/vdso.h>
 #include <asm/tdx.h>
+#include <asm/cfi.h>
 
 #ifdef CONFIG_X86_64
 #include <asm/x86_init.h>
@@ -313,7 +314,8 @@ static noinstr bool handle_bug(struct pt_regs *regs)
 	 */
 	if (regs->flags & X86_EFLAGS_IF)
 		raw_local_irq_enable();
-	if (report_bug(regs->ip, regs) == BUG_TRAP_TYPE_WARN) {
+	if (report_bug(regs->ip, regs) == BUG_TRAP_TYPE_WARN ||
+	    handle_cfi_failure(regs) == BUG_TRAP_TYPE_WARN) {
 		regs->ip += LEN_UD2;
 		handled = true;
 	}

-- 
b4 0.10.0-dev-03aea
