From: Lawrence Lin <deduce@gmail.com>
Date: Sat, 03 Oct 2026 11:27:10 -0500
Subject: [PATCH] ftrace: Avoid quadratic symbol lookups in
 ftrace_module_enable()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261003-ftrace-mod-bsearch-v1-1-92e2fd2d80ff@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQ6CMBBG4auQWTtJKRaMVzEuSvmBIRHMDBoTw
 t2tsvwW721kUIHRtdhI8RaTZc4oTwWlMc4DWLps8s7XpXMV96vGBH4sHbeGqGnkUJ3jpQ6+AQL
 l8Kno5fOf3u6H7dVOSOvvRPv+BYB4eHF2AAAA
X-Change-ID: 20261003-ftrace-mod-bsearch-534a86527ee5
To: Steven Rostedt <rostedt@goodmis.org>, 
 Masami Hiramatsu <mhiramat@kernel.org>, Mark Rutland <mark.rutland@arm.com>, 
 Mathieu Desnoyers <mathieu.desnoyers@efficios.com>
Cc: Petr Pavlu <petr.pavlu@suse.com>, linux-modules@vger.kernel.org, 
 Stanislaw Gruszka <stf_xl@wp.pl>, linux-kernel@vger.kernel.org, 
 linux-trace-kernel@vger.kernel.org, Lawrence Lin <deduce@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791044829; l=8694;
 i=deduce@gmail.com; s=default; h=from:subject:message-id;
 bh=VNnLgJUKJ7lFwhFtPA6FsMT52qOV2kVtmjhNwuYT/s8=;
 b=wvDOC5G4qKnZQ0Cra34A94gJ0jvk3ihF7MC1BfYbIznaE9dXPzf0gFoS0528q80WOovPMwTJu
 4sgLAqR3dh2A3n1S20dmM+/pWZbIYozoQGsjY87Dm7/Aw7966u1lUhQ
X-Developer-Key: i=deduce@gmail.com; a=ed25519;
 pk=Ws6hmG/zoco3lMoykbeaYjo9S7a6sDddQY8EALjp9cM=
X-Endpoint-Received: by B4 Relay for deduce@gmail.com/default with auth_id=1106
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Since commit b39181f7c690 ("ftrace: Add FTRACE_MCOUNT_MAX_OFFSET to avoid
adding weak function"), ftrace_module_enable() calls test_for_valid_rec()
for every ftrace record of a module being loaded. test_for_valid_rec()
resolves the record address with kallsyms_lookup(), and for a module
address find_kallsyms_symbol() scans the whole symbol table of the module.
Loading a module therefore costs O(records * symbols), all of it under
ftrace_lock.

For large drivers this dominates module load time. amdgpu.ko has 16821
ftrace records and about 67000 defined symbols. On a Ryzen 3 3200U
(x86_64, v7.2.5, amdgpu loaded from the initramfs), amdgpu finishes
initializing 6.2 s into boot without this patch and 1.8 s with it, and
the kernel part of boot reported by systemd-analyze drops from 6.87 s to
2.47 s (four boots each). Loading radeon and nouveau, which have no
hardware on that machine, goes from 170 ms to 87 ms and from 520 ms to
145 ms. Commit 4099b98203d6 ("ftrace: Fix softlockup in
ftrace_module_enable") already had to add a cond_resched() to this loop
because of amdgpu.

Instead of one lookup per record, collect the addresses of the module's
symbols once, using the same filters as find_kallsyms_symbol(), sort them
into a temporary array, and binary search it for each record. A record is
valid when the closest symbol at or below its address lies in the same
module memory region and no more than FTRACE_MCOUNT_MAX_OFFSET below it,
which is exactly what test_for_valid_rec() checks. If the array cannot be
allocated, the per-record lookup is used as before.

An earlier attempt [1] sorted the module symbol table itself to speed up
every lookup. Its review pointed out that livepatch relocations index into
that table, that the sort is not stable for aliases, and that data
symbols and weak functions need care. This change leaves the symbol table
untouched and only compares addresses, applying the same filters as
find_kallsyms_symbol(), so none of these apply.

[1] https://lore.kernel.org/all/20260327110005.16499-2-stf_xl@wp.pl/

Fixes: b39181f7c690 ("ftrace: Add FTRACE_MCOUNT_MAX_OFFSET to avoid adding weak function")
Assisted-by: Claude:claude-opus-5-5
Signed-off-by: Lawrence Lin <deduce@gmail.com>
---
Tested on x86_64 (Ryzen 3 3200U, amdgpu):

- v7.2.5, with and without the patch, same config: the boot numbers
  above, and an identical available_filter_functions (85769 entries,
  16821 of them in amdgpu).
- v7.3-rc5 with a debug build that runs test_for_valid_rec() and the new
  check side by side for every record: 141 modules loaded at boot plus
  the selftest modules, and no record on which the two disagree.
- v7.3-rc5, with and without the patch: the ftrace selftests (159
  passed, 0 failed, the same unresolved and xfail cases on both), all
  eight livepatch selftests, samples/livepatch loaded, disabled and
  unloaded, and FTRACE_STARTUP_TEST.
- ftrace.o builds without warnings at W=1 for x86_64 (KALLSYMS_ALL=y
  and =n, MODULES=n, LIVEPATCH=y), ppc64le, and arm64, which does not
  define FTRACE_MCOUNT_MAX_OFFSET and keeps the existing path.

Not tested: running on powerpc, the other architecture that defines
FTRACE_MCOUNT_MAX_OFFSET, and building 32-bit powerpc (the cross
toolchain used here could not enable the function tracer).

This follows Petr's suggestion of a separate sorted array from the
review of [1], kept local to ftrace. Stanislaw, Cc'd as the author of
that series.
---
 kernel/trace/ftrace.c | 127 +++++++++++++++++++++++++++++++++++++++++++++++++-
 1 file changed, 126 insertions(+), 1 deletion(-)

diff --git a/kernel/trace/ftrace.c b/kernel/trace/ftrace.c
index 673a54fdf392..36c97c605fb5 100644
--- a/kernel/trace/ftrace.c
+++ b/kernel/trace/ftrace.c
@@ -18,6 +18,7 @@
 #include <linux/clocksource.h>
 #include <linux/sched/task.h>
 #include <linux/kallsyms.h>
+#include <linux/module_symbol.h>
 #include <linux/security.h>
 #include <linux/seq_file.h>
 #include <linux/tracefs.h>
@@ -4385,6 +4386,109 @@ static int test_for_valid_rec(struct dyn_ftrace *rec)
 	return 1;
 }
 
+#if defined(CONFIG_MODULES) && defined(CONFIG_KALLSYMS)
+#define FTRACE_MOD_SYMS
+/*
+ * test_for_valid_rec() resolves an address with kallsyms_lookup(), which
+ * scans the whole symbol table of a module. Calling it for every record of
+ * a module being loaded costs O(records * symbols): several seconds for a
+ * driver as large as amdgpu, all of it under ftrace_lock. Sort the symbol
+ * addresses of the module once instead and binary search them. The module
+ * symbol table itself is left untouched, as livepatch relies on its order.
+ */
+struct ftrace_mod_syms {
+	unsigned long *addrs;
+	unsigned int nr;
+};
+
+static int ftrace_cmp_addr(const void *a, const void *b)
+{
+	unsigned long x = *(const unsigned long *)a;
+	unsigned long y = *(const unsigned long *)b;
+
+	return x < y ? -1 : x > y;
+}
+
+/* Collect the symbols find_kallsyms_symbol() would consider. */
+static void ftrace_mod_syms_init(struct ftrace_mod_syms *syms,
+				 struct module *mod)
+{
+	/* A coming module cannot have its kallsyms replaced under us. */
+	struct mod_kallsyms *kallsyms = rcu_dereference_raw(mod->kallsyms);
+	unsigned int i;
+
+	syms->nr = 0;
+	syms->addrs = kvmalloc_array(kallsyms->num_symtab,
+				     sizeof(*syms->addrs), GFP_KERNEL);
+	if (!syms->addrs)
+		return;
+
+	for (i = 1; i < kallsyms->num_symtab; i++) {
+		const Elf_Sym *sym = &kallsyms->symtab[i];
+		const char *name = kallsyms->strtab + sym->st_name;
+
+		if (sym->st_shndx == SHN_UNDEF || *name == '\0' ||
+		    is_mapping_symbol(name))
+			continue;
+		syms->addrs[syms->nr++] = kallsyms_symbol_value(sym);
+	}
+
+	sort(syms->addrs, syms->nr, sizeof(*syms->addrs), ftrace_cmp_addr, NULL);
+}
+
+/* Same answer as test_for_valid_rec(), using the sorted addresses. */
+static int test_for_valid_mod_rec(struct ftrace_mod_syms *syms,
+				  struct module *mod, struct dyn_ftrace *rec)
+{
+	unsigned long ip = rec->ip, base, best;
+	unsigned int lo = 0, hi = syms->nr, mid;
+	struct module_memory *mod_mem = NULL;
+
+	if (!syms->addrs)
+		return test_for_valid_rec(rec);
+
+	for_each_mod_mem_type(type) {
+#ifndef CONFIG_KALLSYMS_ALL
+		if (!mod_mem_type_is_text(type))
+			continue;
+#endif
+		if (within_module_mem_type(ip, mod, type)) {
+			mod_mem = &mod->mem[type];
+			break;
+		}
+	}
+	if (!mod_mem)
+		goto invalid;
+	base = (unsigned long)mod_mem->base;
+
+	/* Find the last symbol at or below ip. */
+	while (lo < hi) {
+		mid = lo + (hi - lo) / 2;
+		if (syms->addrs[mid] <= ip)
+			lo = mid + 1;
+		else
+			hi = mid;
+	}
+	if (!lo)
+		goto invalid;
+	best = syms->addrs[lo - 1];
+
+	/* Weak functions can cause invalid addresses */
+	if (best < base || ip - best > FTRACE_MCOUNT_MAX_OFFSET)
+		goto invalid;
+	return 1;
+
+invalid:
+	rec->flags |= FTRACE_FL_DISABLED;
+	return 0;
+}
+
+static void ftrace_mod_syms_free(struct ftrace_mod_syms *syms)
+{
+	kvfree(syms->addrs);
+}
+#endif
+
 static struct workqueue_struct *ftrace_check_wq __initdata;
 static struct work_struct ftrace_check_work __initdata;
 
@@ -8010,11 +8114,30 @@ void ftrace_release_mod(struct module *mod)
 	}
 }
 
+#ifndef FTRACE_MOD_SYMS
+struct ftrace_mod_syms { };
+
+static inline void ftrace_mod_syms_init(struct ftrace_mod_syms *syms,
+					struct module *mod) { }
+
+static inline int test_for_valid_mod_rec(struct ftrace_mod_syms *syms,
+					 struct module *mod,
+					 struct dyn_ftrace *rec)
+{
+	return test_for_valid_rec(rec);
+}
+
+static inline void ftrace_mod_syms_free(struct ftrace_mod_syms *syms) { }
+#endif
+
 void ftrace_module_enable(struct module *mod)
 {
+	struct ftrace_mod_syms syms;
 	struct dyn_ftrace *rec;
 	struct ftrace_page *pg;
 
+	ftrace_mod_syms_init(&syms, mod);
+
 	mutex_lock(&ftrace_lock);
 
 	if (ftrace_disabled)
@@ -8050,7 +8173,7 @@ void ftrace_module_enable(struct module *mod)
 		cond_resched();
 
 		/* Weak functions should still be ignored */
-		if (!test_for_valid_rec(rec)) {
+		if (!test_for_valid_mod_rec(&syms, mod, rec)) {
 			/* Clear all other flags. Should not be enabled anyway */
 			rec->flags = FTRACE_FL_DISABLED;
 			continue;
@@ -8087,6 +8210,8 @@ void ftrace_module_enable(struct module *mod)
  out_unlock:
 	mutex_unlock(&ftrace_lock);
 
+	ftrace_mod_syms_free(&syms);
+
 	process_cached_mods(mod->name);
 }
 

---
base-commit: e767a4ea70a3992c37ed604157d32f0dfbf9b1e3
change-id: 20261003-ftrace-mod-bsearch-534a86527ee5

Best regards,
--  
Lawrence Lin <deduce@gmail.com>

