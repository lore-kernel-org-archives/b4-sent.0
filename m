From: Konstantin Ryabitsev <konstantin@linuxfoundation.org>
Date: Thu, 01 Sep 2022 15:28:55 -0400
Subject: [PATCH v5 10/21] arm64: Add CFI error handling
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20220901-kcfi_support-v5-10-be2007d8da63@linuxfoundation.org>
References: <20220901-kcfi_support-v5-0-be2007d8da63@linuxfoundation.org>
In-Reply-To: <20220901-kcfi_support-v5-0-be2007d8da63@linuxfoundation.org>
To: mricon@kernel.org
X-Mailer: b4 0.10.0-dev-03aea
X-Developer-Signature: v=1; a=openpgp-sha256; l=6394;
 i=konstantin@linuxfoundation.org; h=from:subject:message-id;
 bh=oHKwwLqOGeU2r27sHdyiX09fvv8+eV3KiXtYFQFWabk=;
 b=owGbwMvMwCW27YjM47CUmTmMp9WSGJIF2X8VnrybPePOeT7RfLmDxZXN7G57BbOn72YJm7/Ug229
 tHpWRykLgxgXg6yYIkvZvthNQYUPPeTSe0xh5rAygQxh4OIUgIkobGZk+Hk9Wmt51ISGByppGt5v9D
 Rer+P6I3Vuhvf5+dqhIg/3bWVkmKF/L4tDxHleh6ag7OOV3zI0mp/oTmr7t3yd7MkdVkkfmQE=
X-Developer-Key: i=konstantin@linuxfoundation.org; a=openpgp;
 fpr=DE0E66E32F1FDD0902666B96E63EDCA9329DD07E
X-Endpoint-Received: by B4 Submission Endpoint for konstantin@linuxfoundation.org/default with auth_id=3
List-Id: B4 Web Endpoint Patches <b4-sent.feeds.kernel.org>

From: Sami Tolvanen <samitolvanen@google.com>

With -fsanitize=kcfi, CFI always traps. Add arm64 support for handling CFI
failures. The registers containing the target address and the expected type
are encoded in the first ten bits of the ESR as follows:

 - 0-4: n, where the register Xn contains the target address
 - 5-9: m, where the register Wm contains the type hash

This produces the following oops on CFI failure (generated using lkdtm):

[   21.885179] CFI failure at lkdtm_indirect_call+0x2c/0x44 [lkdtm]
(target: lkdtm_increment_int+0x0/0x1c [lkdtm]; expected type: 0x7e0c52a)
[   21.886593] Internal error: Oops - CFI: 0 [#1] PREEMPT SMP
[   21.891060] Modules linked in: lkdtm
[   21.893363] CPU: 0 PID: 151 Comm: sh Not tainted
5.19.0-rc1-00021-g852f4e48dbab #1
[   21.895560] Hardware name: linux,dummy-virt (DT)
[   21.896543] pstate: 80400009 (Nzcv daif +PAN -UAO -TCO -DIT -SSBS BTYPE=--)
[   21.897583] pc : lkdtm_indirect_call+0x2c/0x44 [lkdtm]
[   21.898551] lr : lkdtm_CFI_FORWARD_PROTO+0x3c/0x6c [lkdtm]
[   21.899520] sp : ffff8000083a3c50
[   21.900191] x29: ffff8000083a3c50 x28: ffff0000027e0ec0 x27: 0000000000000000
[   21.902453] x26: 0000000000000000 x25: ffffc2aa3d07e7b0 x24: 0000000000000002
[   21.903736] x23: ffffc2aa3d079088 x22: ffffc2aa3d07e7b0 x21: ffff000003379000
[   21.905062] x20: ffff8000083a3dc0 x19: 0000000000000012 x18: 0000000000000000
[   21.906371] x17: 000000007e0c52a5 x16: 000000003ad55aca x15: ffffc2aa60d92138
[   21.907662] x14: ffffffffffffffff x13: 2e2e2e2065707974 x12: 0000000000000018
[   21.909775] x11: ffffc2aa62322b88 x10: ffffc2aa62322aa0 x9 : c7e305fb5195d200
[   21.911898] x8 : ffffc2aa3d077e20 x7 : 6d20676e696c6c61 x6 : 43203a6d74646b6c
[   21.913108] x5 : ffffc2aa6266c9df x4 : ffffc2aa6266c9e1 x3 : ffff8000083a3968
[   21.914358] x2 : 80000000fffff122 x1 : 00000000fffff122 x0 : ffffc2aa3d07e8f8
[   21.915827] Call trace:
[   21.916375]  lkdtm_indirect_call+0x2c/0x44 [lkdtm]
[   21.918060]  lkdtm_CFI_FORWARD_PROTO+0x3c/0x6c [lkdtm]
[   21.919030]  lkdtm_do_action+0x34/0x4c [lkdtm]
[   21.919920]  direct_entry+0x170/0x1ac [lkdtm]
[   21.920772]  full_proxy_write+0x84/0x104
[   21.921759]  vfs_write+0x188/0x3d8
[   21.922387]  ksys_write+0x78/0xe8
[   21.922986]  __arm64_sys_write+0x1c/0x2c
[   21.923696]  invoke_syscall+0x58/0x134
[   21.924554]  el0_svc_common+0xb4/0xf4
[   21.925603]  do_el0_svc+0x2c/0xb4
[   21.926563]  el0_svc+0x2c/0x7c
[   21.927147]  el0t_64_sync_handler+0x84/0xf0
[   21.927985]  el0t_64_sync+0x18c/0x190
[   21.929133] Code: 728a54b1 72afc191 6b11021f 54000040 (d4304500)
[   21.930690] ---[ end trace 0000000000000000 ]---
[   21.930971] Kernel panic - not syncing: Oops - CFI: Fatal exception

Suggested-by: Mark Rutland <mark.rutland@arm.com>
Signed-off-by: Sami Tolvanen <samitolvanen@google.com>
Reviewed-by: Kees Cook <keescook@chromium.org>
Tested-by: Kees Cook <keescook@chromium.org>

diff --git a/arch/arm64/include/asm/brk-imm.h b/arch/arm64/include/asm/brk-imm.h
index ec7720dbe2c8..6e000113e508 100644
--- a/arch/arm64/include/asm/brk-imm.h
+++ b/arch/arm64/include/asm/brk-imm.h
@@ -17,6 +17,7 @@
  * 0x401: for compile time BRK instruction
  * 0x800: kernel-mode BUG() and WARN() traps
  * 0x9xx: tag-based KASAN trap (allowed values 0x900 - 0x9ff)
+ * 0x8xxx: Control-Flow Integrity traps
  */
 #define KPROBES_BRK_IMM			0x004
 #define UPROBES_BRK_IMM			0x005
@@ -28,4 +29,9 @@
 #define KASAN_BRK_IMM			0x900
 #define KASAN_BRK_MASK			0x0ff
 
+#define CFI_BRK_IMM_TARGET		GENMASK(4, 0)
+#define CFI_BRK_IMM_TYPE		GENMASK(9, 5)
+#define CFI_BRK_IMM_BASE		0x8000
+#define CFI_BRK_IMM_MASK		(CFI_BRK_IMM_TARGET | CFI_BRK_IMM_TYPE)
+
 #endif
diff --git a/arch/arm64/kernel/traps.c b/arch/arm64/kernel/traps.c
index b7fed33981f7..3c026da95bbc 100644
--- a/arch/arm64/kernel/traps.c
+++ b/arch/arm64/kernel/traps.c
@@ -26,6 +26,7 @@
 #include <linux/syscalls.h>
 #include <linux/mm_types.h>
 #include <linux/kasan.h>
+#include <linux/cfi.h>
 
 #include <asm/atomic.h>
 #include <asm/bug.h>
@@ -991,6 +992,38 @@ static struct break_hook bug_break_hook = {
 	.imm = BUG_BRK_IMM,
 };
 
+#ifdef CONFIG_CFI_CLANG
+static int cfi_handler(struct pt_regs *regs, unsigned long esr)
+{
+	unsigned long target;
+	u32 type;
+
+	target = pt_regs_read_reg(regs, FIELD_GET(CFI_BRK_IMM_TARGET, esr));
+	type = (u32)pt_regs_read_reg(regs, FIELD_GET(CFI_BRK_IMM_TYPE, esr));
+
+	switch (report_cfi_failure(regs, regs->pc, &target, type)) {
+	case BUG_TRAP_TYPE_BUG:
+		die("Oops - CFI", regs, 0);
+		break;
+
+	case BUG_TRAP_TYPE_WARN:
+		break;
+
+	default:
+		return DBG_HOOK_ERROR;
+	}
+
+	arm64_skip_faulting_instruction(regs, AARCH64_INSN_SIZE);
+	return DBG_HOOK_HANDLED;
+}
+
+static struct break_hook cfi_break_hook = {
+	.fn = cfi_handler,
+	.imm = CFI_BRK_IMM_BASE,
+	.mask = CFI_BRK_IMM_MASK,
+};
+#endif /* CONFIG_CFI_CLANG */
+
 static int reserved_fault_handler(struct pt_regs *regs, unsigned long esr)
 {
 	pr_err("%s generated an invalid instruction at %pS!\n",
@@ -1052,6 +1085,9 @@ static struct break_hook kasan_break_hook = {
 };
 #endif
 
+
+#define esr_comment(esr) ((esr) & ESR_ELx_BRK64_ISS_COMMENT_MASK)
+
 /*
  * Initial handler for AArch64 BRK exceptions
  * This handler only used until debug_traps_init().
@@ -1059,10 +1095,12 @@ static struct break_hook kasan_break_hook = {
 int __init early_brk64(unsigned long addr, unsigned long esr,
 		struct pt_regs *regs)
 {
+#ifdef CONFIG_CFI_CLANG
+	if ((esr_comment(esr) & ~CFI_BRK_IMM_MASK) == CFI_BRK_IMM_BASE)
+		return cfi_handler(regs, esr) != DBG_HOOK_HANDLED;
+#endif
 #ifdef CONFIG_KASAN_SW_TAGS
-	unsigned long comment = esr & ESR_ELx_BRK64_ISS_COMMENT_MASK;
-
-	if ((comment & ~KASAN_BRK_MASK) == KASAN_BRK_IMM)
+	if ((esr_comment(esr) & ~KASAN_BRK_MASK) == KASAN_BRK_IMM)
 		return kasan_handler(regs, esr) != DBG_HOOK_HANDLED;
 #endif
 	return bug_handler(regs, esr) != DBG_HOOK_HANDLED;
@@ -1071,6 +1109,9 @@ int __init early_brk64(unsigned long addr, unsigned long esr,
 void __init trap_init(void)
 {
 	register_kernel_break_hook(&bug_break_hook);
+#ifdef CONFIG_CFI_CLANG
+	register_kernel_break_hook(&cfi_break_hook);
+#endif
 	register_kernel_break_hook(&fault_break_hook);
 #ifdef CONFIG_KASAN_SW_TAGS
 	register_kernel_break_hook(&kasan_break_hook);

-- 
b4 0.10.0-dev-03aea
