From: Konstantin Ryabitsev <konstantin@linuxfoundation.org>
Date: Thu, 01 Sep 2022 15:28:50 -0400
Subject: [PATCH v5 05/21] cfi: Switch to -fsanitize=kcfi
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20220901-kcfi_support-v5-5-be2007d8da63@linuxfoundation.org>
References: <20220901-kcfi_support-v5-0-be2007d8da63@linuxfoundation.org>
In-Reply-To: <20220901-kcfi_support-v5-0-be2007d8da63@linuxfoundation.org>
To: mricon@kernel.org
X-Mailer: b4 0.10.0-dev-03aea
X-Developer-Signature: v=1; a=openpgp-sha256; l=15279;
 i=konstantin@linuxfoundation.org; h=from:subject:message-id;
 bh=TlVlFQzXdCZAv0uXQe7K5Y6zxy0MaN9W+HlwzI0Y5io=;
 b=owGbwMvMwCW27YjM47CUmTmMp9WSGJIF2X9tefFERCDYfXPzExdn1k/hntv6rR5qtTHvYGL47rT5
 l/ezjlIWBjEuBlkxRZayfbGbggofesil95jCzGFlAhnCwMUpABOplGX4Z7HPfJGBTqvexpY9CvGs0u
 qqDJ8+CSlaft9cUbtgHrthP8P/kkYdP9HVv6ZZBHSc5/c79SduqbrVpacnZsmeqvLxdeBnBQA=
X-Developer-Key: i=konstantin@linuxfoundation.org; a=openpgp;
 fpr=DE0E66E32F1FDD0902666B96E63EDCA9329DD07E
X-Endpoint-Received: by B4 Submission Endpoint for konstantin@linuxfoundation.org/default with auth_id=3
List-Id: B4 Web Endpoint Patches <b4-sent.feeds.kernel.org>

From: Sami Tolvanen <samitolvanen@google.com>

Switch from Clang's original forward-edge control-flow integrity
implementation to -fsanitize=kcfi, which is better suited for the
kernel, as it doesn't require LTO, doesn't use a jump table that
requires altering function references, and won't break cross-module
function address equality.

Signed-off-by: Sami Tolvanen <samitolvanen@google.com>
Reviewed-by: Kees Cook <keescook@chromium.org>
Tested-by: Kees Cook <keescook@chromium.org>

diff --git a/Makefile b/Makefile
index 952d354069a4..eec147f5572c 100644
--- a/Makefile
+++ b/Makefile
@@ -921,18 +921,7 @@ export CC_FLAGS_LTO
 endif
 
 ifdef CONFIG_CFI_CLANG
-CC_FLAGS_CFI	:= -fsanitize=cfi \
-		   -fsanitize-cfi-cross-dso \
-		   -fno-sanitize-cfi-canonical-jump-tables \
-		   -fno-sanitize-trap=cfi \
-		   -fno-sanitize-blacklist
-
-ifdef CONFIG_CFI_PERMISSIVE
-CC_FLAGS_CFI	+= -fsanitize-recover=cfi
-endif
-
-# If LTO flags are filtered out, we must also filter out CFI.
-CC_FLAGS_LTO	+= $(CC_FLAGS_CFI)
+CC_FLAGS_CFI	:= -fsanitize=kcfi
 KBUILD_CFLAGS	+= $(CC_FLAGS_CFI)
 export CC_FLAGS_CFI
 endif
diff --git a/arch/Kconfig b/arch/Kconfig
index 5fd875e18c99..1c1eca0c0019 100644
--- a/arch/Kconfig
+++ b/arch/Kconfig
@@ -738,11 +738,13 @@ config ARCH_SUPPORTS_CFI_CLANG
 	  An architecture should select this option if it can support Clang's
 	  Control-Flow Integrity (CFI) checking.
 
+config ARCH_USES_CFI_TRAPS
+	bool
+
 config CFI_CLANG
 	bool "Use Clang's Control Flow Integrity (CFI)"
-	depends on LTO_CLANG && ARCH_SUPPORTS_CFI_CLANG
-	depends on CLANG_VERSION >= 140000
-	select KALLSYMS
+	depends on ARCH_SUPPORTS_CFI_CLANG
+	depends on $(cc-option,-fsanitize=kcfi)
 	help
 	  This option enables Clang’s forward-edge Control Flow Integrity
 	  (CFI) checking, where the compiler injects a runtime check to each
diff --git a/include/asm-generic/vmlinux.lds.h b/include/asm-generic/vmlinux.lds.h
index 7515a465ec03..7501edfce11e 100644
--- a/include/asm-generic/vmlinux.lds.h
+++ b/include/asm-generic/vmlinux.lds.h
@@ -421,6 +421,22 @@
 	__end_ro_after_init = .;
 #endif
 
+/*
+ * .kcfi_traps contains a list KCFI trap locations.
+ */
+#ifndef KCFI_TRAPS
+#ifdef CONFIG_ARCH_USES_CFI_TRAPS
+#define KCFI_TRAPS							\
+	__kcfi_traps : AT(ADDR(__kcfi_traps) - LOAD_OFFSET) {		\
+		__start___kcfi_traps = .;				\
+		KEEP(*(.kcfi_traps))					\
+		__stop___kcfi_traps = .;				\
+	}
+#else
+#define KCFI_TRAPS
+#endif
+#endif
+
 /*
  * Read only Data
  */
@@ -529,6 +545,8 @@
 		__stop___modver = .;					\
 	}								\
 									\
+	KCFI_TRAPS							\
+									\
 	RO_EXCEPTION_TABLE						\
 	NOTES								\
 	BTF								\
@@ -537,21 +555,6 @@
 	__end_rodata = .;
 
 
-/*
- * .text..L.cfi.jumptable.* contain Control-Flow Integrity (CFI)
- * jump table entries.
- */
-#ifdef CONFIG_CFI_CLANG
-#define TEXT_CFI_JT							\
-		. = ALIGN(PMD_SIZE);					\
-		__cfi_jt_start = .;					\
-		*(.text..L.cfi.jumptable .text..L.cfi.jumptable.*)	\
-		. = ALIGN(PMD_SIZE);					\
-		__cfi_jt_end = .;
-#else
-#define TEXT_CFI_JT
-#endif
-
 /*
  * Non-instrumentable text section
  */
@@ -579,7 +582,6 @@
 		*(.text..refcount)					\
 		*(.ref.text)						\
 		*(.text.asan.* .text.tsan.*)				\
-		TEXT_CFI_JT						\
 	MEM_KEEP(init.text*)						\
 	MEM_KEEP(exit.text*)						\
 
@@ -1008,8 +1010,7 @@
  * keep any .init_array.* sections.
  * https://bugs.llvm.org/show_bug.cgi?id=46478
  */
-#if defined(CONFIG_GCOV_KERNEL) || defined(CONFIG_KASAN_GENERIC) || defined(CONFIG_KCSAN) || \
-	defined(CONFIG_CFI_CLANG)
+#if defined(CONFIG_GCOV_KERNEL) || defined(CONFIG_KASAN_GENERIC) || defined(CONFIG_KCSAN)
 # ifdef CONFIG_CONSTRUCTORS
 #  define SANITIZER_DISCARDS						\
 	*(.eh_frame)
diff --git a/include/linux/cfi.h b/include/linux/cfi.h
index 2cdbc0fbd0ab..5e134f4ce8b7 100644
--- a/include/linux/cfi.h
+++ b/include/linux/cfi.h
@@ -2,17 +2,38 @@
 /*
  * Clang Control Flow Integrity (CFI) support.
  *
- * Copyright (C) 2021 Google LLC
+ * Copyright (C) 2022 Google LLC
  */
 #ifndef _LINUX_CFI_H
 #define _LINUX_CFI_H
 
+#include <linux/bug.h>
+#include <linux/module.h>
+
 #ifdef CONFIG_CFI_CLANG
-typedef void (*cfi_check_fn)(uint64_t id, void *ptr, void *diag);
+enum bug_trap_type report_cfi_failure(struct pt_regs *regs, unsigned long addr,
+				      unsigned long *target, u32 type);
 
-/* Compiler-generated function in each module, and the kernel */
-extern void __cfi_check(uint64_t id, void *ptr, void *diag);
+static inline enum bug_trap_type report_cfi_failure_noaddr(struct pt_regs *regs,
+							   unsigned long addr)
+{
+	return report_cfi_failure(regs, addr, NULL, 0);
+}
 
+#ifdef CONFIG_ARCH_USES_CFI_TRAPS
+bool is_cfi_trap(unsigned long addr);
+#endif
 #endif /* CONFIG_CFI_CLANG */
 
+#ifdef CONFIG_MODULES
+#ifdef CONFIG_ARCH_USES_CFI_TRAPS
+void module_cfi_finalize(const Elf_Ehdr *hdr, const Elf_Shdr *sechdrs,
+			 struct module *mod);
+#else
+static inline void module_cfi_finalize(const Elf_Ehdr *hdr,
+				       const Elf_Shdr *sechdrs,
+				       struct module *mod) {}
+#endif /* CONFIG_ARCH_USES_CFI_TRAPS */
+#endif /* CONFIG_MODULES */
+
 #endif /* _LINUX_CFI_H */
diff --git a/include/linux/compiler-clang.h b/include/linux/compiler-clang.h
index c84fec767445..42e55579d649 100644
--- a/include/linux/compiler-clang.h
+++ b/include/linux/compiler-clang.h
@@ -66,17 +66,9 @@
 # define __noscs	__attribute__((__no_sanitize__("shadow-call-stack")))
 #endif
 
-#define __nocfi		__attribute__((__no_sanitize__("cfi")))
-#define __cficanonical	__attribute__((__cfi_canonical_jump_table__))
-
-#if defined(CONFIG_CFI_CLANG)
-/*
- * With CONFIG_CFI_CLANG, the compiler replaces function address
- * references with the address of the function's CFI jump table
- * entry. The function_nocfi macro always returns the address of the
- * actual function instead.
- */
-#define function_nocfi(x)	__builtin_function_start(x)
+#if __has_feature(kcfi)
+/* Disable CFI checking inside a function. */
+#define __nocfi		__attribute__((__no_sanitize__("kcfi")))
 #endif
 
 /*
diff --git a/include/linux/module.h b/include/linux/module.h
index 8937b020ec04..ec61fb53979a 100644
--- a/include/linux/module.h
+++ b/include/linux/module.h
@@ -27,7 +27,6 @@
 #include <linux/tracepoint-defs.h>
 #include <linux/srcu.h>
 #include <linux/static_call_types.h>
-#include <linux/cfi.h>
 
 #include <linux/percpu.h>
 #include <asm/module.h>
@@ -387,8 +386,9 @@ struct module {
 	const s32 *crcs;
 	unsigned int num_syms;
 
-#ifdef CONFIG_CFI_CLANG
-	cfi_check_fn cfi_check;
+#ifdef CONFIG_ARCH_USES_CFI_TRAPS
+	s32 *kcfi_traps;
+	s32 *kcfi_traps_end;
 #endif
 
 	/* Kernel parameters. */
diff --git a/kernel/cfi.c b/kernel/cfi.c
index e8bc1b370edc..08caad776717 100644
--- a/kernel/cfi.c
+++ b/kernel/cfi.c
@@ -1,105 +1,101 @@
 // SPDX-License-Identifier: GPL-2.0
 /*
- * Clang Control Flow Integrity (CFI) error and slowpath handling.
+ * Clang Control Flow Integrity (CFI) error handling.
  *
- * Copyright (C) 2021 Google LLC
+ * Copyright (C) 2022 Google LLC
  */
 
-#include <linux/hardirq.h>
-#include <linux/kallsyms.h>
-#include <linux/module.h>
-#include <linux/mutex.h>
-#include <linux/printk.h>
-#include <linux/ratelimit.h>
-#include <linux/rcupdate.h>
-#include <linux/vmalloc.h>
-#include <asm/cacheflush.h>
-#include <asm/set_memory.h>
-
-/* Compiler-defined handler names */
-#ifdef CONFIG_CFI_PERMISSIVE
-#define cfi_failure_handler	__ubsan_handle_cfi_check_fail
-#else
-#define cfi_failure_handler	__ubsan_handle_cfi_check_fail_abort
-#endif
-
-static inline void handle_cfi_failure(void *ptr)
+#include <linux/cfi.h>
+
+enum bug_trap_type report_cfi_failure(struct pt_regs *regs, unsigned long addr,
+				      unsigned long *target, u32 type)
 {
-	if (IS_ENABLED(CONFIG_CFI_PERMISSIVE))
-		WARN_RATELIMIT(1, "CFI failure (target: %pS):\n", ptr);
+	if (target)
+		pr_err("CFI failure at %pS (target: %pS; expected type: 0x%08x)\n",
+		       (void *)addr, (void *)*target, type);
 	else
-		panic("CFI failure (target: %pS)\n", ptr);
+		pr_err("CFI failure at %pS (no target information)\n",
+		       (void *)addr);
+
+	if (IS_ENABLED(CONFIG_CFI_PERMISSIVE)) {
+		__warn(NULL, 0, (void *)addr, 0, regs, NULL);
+		return BUG_TRAP_TYPE_WARN;
+	}
+
+	return BUG_TRAP_TYPE_BUG;
 }
 
-#ifdef CONFIG_MODULES
+#ifdef CONFIG_ARCH_USES_CFI_TRAPS
+static inline unsigned long trap_address(s32 *p)
+{
+	return (unsigned long)((long)p + (long)*p);
+}
 
-static inline cfi_check_fn find_module_check_fn(unsigned long ptr)
+static bool is_trap(unsigned long addr, s32 *start, s32 *end)
 {
-	cfi_check_fn fn = NULL;
-	struct module *mod;
+	s32 *p;
 
-	rcu_read_lock_sched_notrace();
-	mod = __module_address(ptr);
-	if (mod)
-		fn = mod->cfi_check;
-	rcu_read_unlock_sched_notrace();
+	for (p = start; p < end; ++p) {
+		if (trap_address(p) == addr)
+			return true;
+	}
 
-	return fn;
+	return false;
 }
 
-static inline cfi_check_fn find_check_fn(unsigned long ptr)
+#ifdef CONFIG_MODULES
+/* Populates `kcfi_trap(_end)?` fields in `struct module`. */
+void module_cfi_finalize(const Elf_Ehdr *hdr, const Elf_Shdr *sechdrs,
+			 struct module *mod)
 {
-	cfi_check_fn fn = NULL;
-	unsigned long flags;
-	bool rcu_idle;
-
-	if (is_kernel_text(ptr))
-		return __cfi_check;
-
-	/*
-	 * Indirect call checks can happen when RCU is not watching. Both
-	 * the shadow and __module_address use RCU, so we need to wake it
-	 * up if necessary.
-	 */
-	rcu_idle = !rcu_is_watching();
-	if (rcu_idle) {
-		local_irq_save(flags);
-		ct_irq_enter();
-	}
+	char *secstrings;
+	unsigned int i;
 
-	fn = find_module_check_fn(ptr);
+	mod->kcfi_traps = NULL;
+	mod->kcfi_traps_end = NULL;
 
-	if (rcu_idle) {
-		ct_irq_exit();
-		local_irq_restore(flags);
-	}
+	secstrings = (char *)hdr + sechdrs[hdr->e_shstrndx].sh_offset;
+
+	for (i = 1; i < hdr->e_shnum; i++) {
+		if (strcmp(secstrings + sechdrs[i].sh_name, "__kcfi_traps"))
+			continue;
 
-	return fn;
+		mod->kcfi_traps = (s32 *)sechdrs[i].sh_addr;
+		mod->kcfi_traps_end = (s32 *)(sechdrs[i].sh_addr + sechdrs[i].sh_size);
+		break;
+	}
 }
 
-void __cfi_slowpath_diag(uint64_t id, void *ptr, void *diag)
+static bool is_module_cfi_trap(unsigned long addr)
 {
-	cfi_check_fn fn = find_check_fn((unsigned long)ptr);
+	struct module *mod;
+	bool found = false;
 
-	if (likely(fn))
-		fn(id, ptr, diag);
-	else /* Don't allow unchecked modules */
-		handle_cfi_failure(ptr);
-}
-EXPORT_SYMBOL(__cfi_slowpath_diag);
+	rcu_read_lock_sched_notrace();
 
-#else /* !CONFIG_MODULES */
+	mod = __module_address(addr);
+	if (mod)
+		found = is_trap(addr, mod->kcfi_traps, mod->kcfi_traps_end);
 
-void __cfi_slowpath_diag(uint64_t id, void *ptr, void *diag)
+	rcu_read_unlock_sched_notrace();
+
+	return found;
+}
+#else /* CONFIG_MODULES */
+static inline bool is_module_cfi_trap(unsigned long addr)
 {
-	handle_cfi_failure(ptr); /* No modules */
+	return false;
 }
-EXPORT_SYMBOL(__cfi_slowpath_diag);
-
 #endif /* CONFIG_MODULES */
 
-void cfi_failure_handler(void *data, void *ptr, void *vtable)
+extern s32 __start___kcfi_traps[];
+extern s32 __stop___kcfi_traps[];
+
+bool is_cfi_trap(unsigned long addr)
 {
-	handle_cfi_failure(ptr);
+	if (is_trap(addr, __start___kcfi_traps, __stop___kcfi_traps))
+		return true;
+
+	return is_module_cfi_trap(addr);
 }
-EXPORT_SYMBOL(cfi_failure_handler);
+#endif /* CONFIG_ARCH_USES_CFI_TRAPS */
diff --git a/kernel/module/main.c b/kernel/module/main.c
index 0228f44b58e5..70c0b2c6fef8 100644
--- a/kernel/module/main.c
+++ b/kernel/module/main.c
@@ -53,6 +53,7 @@
 #include <linux/bsearch.h>
 #include <linux/dynamic_debug.h>
 #include <linux/audit.h>
+#include <linux/cfi.h>
 #include <uapi/linux/module.h>
 #include "internal.h"
 
@@ -2597,8 +2598,9 @@ static int complete_formation(struct module *mod, struct load_info *info)
 	if (err < 0)
 		goto out;
 
-	/* This relies on module_mutex for list integrity. */
+	/* These rely on module_mutex for list integrity. */
 	module_bug_finalize(info->hdr, info->sechdrs, mod);
+	module_cfi_finalize(info->hdr, info->sechdrs, mod);
 
 	if (module_check_misalignment(mod))
 		goto out_misaligned;
@@ -2660,8 +2662,6 @@ static int unknown_module_param_cb(char *param, char *val, const char *modname,
 	return 0;
 }
 
-static void cfi_init(struct module *mod);
-
 /*
  * Allocate and load the module: note that size of section 0 is always
  * zero, and we rely on this for optional sections.
@@ -2791,9 +2791,6 @@ static int load_module(struct load_info *info, const char __user *uargs,
 
 	flush_module_icache(mod);
 
-	/* Setup CFI for the module. */
-	cfi_init(mod);
-
 	/* Now copy in args */
 	mod->args = strndup_user(uargs, ~0UL >> 1);
 	if (IS_ERR(mod->args)) {
@@ -2955,32 +2952,6 @@ static inline int within(unsigned long addr, void *start, unsigned long size)
 	return ((void *)addr >= start && (void *)addr < start + size);
 }
 
-static void cfi_init(struct module *mod)
-{
-#ifdef CONFIG_CFI_CLANG
-	initcall_t *init;
-#ifdef CONFIG_MODULE_UNLOAD
-	exitcall_t *exit;
-#endif
-
-	rcu_read_lock_sched();
-	mod->cfi_check = (cfi_check_fn)
-		find_kallsyms_symbol_value(mod, "__cfi_check");
-	init = (initcall_t *)
-		find_kallsyms_symbol_value(mod, "__cfi_jt_init_module");
-	/* Fix init/exit functions to point to the CFI jump table */
-	if (init)
-		mod->init = *init;
-#ifdef CONFIG_MODULE_UNLOAD
-	exit = (exitcall_t *)
-		find_kallsyms_symbol_value(mod, "__cfi_jt_cleanup_module");
-	if (exit)
-		mod->exit = *exit;
-#endif
-	rcu_read_unlock_sched();
-#endif
-}
-
 /* Keep in sync with MODULE_FLAGS_BUF_SIZE !!! */
 char *module_flags(struct module *mod, char *buf, bool show_state)
 {
diff --git a/scripts/module.lds.S b/scripts/module.lds.S
index 3a3aa2354ed8..da4bddd26171 100644
--- a/scripts/module.lds.S
+++ b/scripts/module.lds.S
@@ -3,20 +3,10 @@
  * Archs are free to supply their own linker scripts.  ld will
  * combine them automatically.
  */
-#ifdef CONFIG_CFI_CLANG
-# include <asm/page.h>
-# define ALIGN_CFI 		ALIGN(PAGE_SIZE)
-# define SANITIZER_DISCARDS	*(.eh_frame)
-#else
-# define ALIGN_CFI
-# define SANITIZER_DISCARDS
-#endif
-
 SECTIONS {
 	/DISCARD/ : {
 		*(.discard)
 		*(.discard.*)
-		SANITIZER_DISCARDS
 	}
 
 	__ksymtab		0 : { *(SORT(___ksymtab+*)) }
@@ -33,6 +23,10 @@ SECTIONS {
 
 	__patchable_function_entries : { *(__patchable_function_entries) }
 
+#ifdef CONFIG_ARCH_USES_CFI_TRAPS
+	__kcfi_traps 		: { KEEP(*(.kcfi_traps)) }
+#endif
+
 #ifdef CONFIG_LTO_CLANG
 	/*
 	 * With CONFIG_LTO_CLANG, LLD always enables -fdata-sections and
@@ -53,15 +47,6 @@ SECTIONS {
 		*(.rodata .rodata.[0-9a-zA-Z_]*)
 		*(.rodata..L*)
 	}
-
-	/*
-	 * With CONFIG_CFI_CLANG, we assume __cfi_check is at the beginning
-	 * of the .text section, and is aligned to PAGE_SIZE.
-	 */
-	.text : ALIGN_CFI {
-		*(.text.__cfi_check)
-		*(.text .text.[0-9a-zA-Z_]* .text..L.cfi*)
-	}
 #endif
 }
 

-- 
b4 0.10.0-dev-03aea
