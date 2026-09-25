From: Alireza Haghdoost <haghdoost@uber.com>
Date: Fri, 25 Sep 2026 12:09:41 -0700
Subject: [PATCH v3 4/6] perf script: Add --max-symbol-bytes to bound ELF
 symbol memory
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260925-perf-symbol-memory-send-v3-4-3e4e234c363b@uber.com>
References: <20260925-perf-symbol-memory-send-v3-0-3e4e234c363b@uber.com>
In-Reply-To: <20260925-perf-symbol-memory-send-v3-0-3e4e234c363b@uber.com>
To: Peter Zijlstra <peterz@infradead.org>, Ingo Molnar <mingo@redhat.com>, 
 Arnaldo Carvalho de Melo <acme@kernel.org>, 
 Namhyung Kim <namhyung@kernel.org>, Mark Rutland <mark.rutland@arm.com>, 
 Alexander Shishkin <alexander.shishkin@linux.intel.com>, 
 Jiri Olsa <jolsa@kernel.org>, Ian Rogers <irogers@google.com>, 
 Adrian Hunter <adrian.hunter@intel.com>, 
 James Clark <james.clark@linaro.org>, Alexei Starovoitov <ast@kernel.org>, 
 Andrii Nakryiko <andriin@fb.com>
Cc: linux-perf-users@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Alireza Haghdoost <haghdoost@uber.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=19016; i=haghdoost@uber.com;
 h=from:subject:message-id; bh=Jkyk9nWS0QYXMJkKaDMS1BFwFF4HyPWGgUGCz08NHZM=;
 b=owEBiQJ2/ZANAwAIAVNlBDxl2ALYAcsmYgBqtshDU9OHmnXmxtyZBNSgUPVQZY4pGjNcByX2b
 6vQMgyE0bKJAk8EAAEIADkWIQS5+sFL3gX/8PrA0S1TZQQ8ZdgC2AUCarbIQxsUgAAAAAAEAA5t
 YW51MiwyLjUrMS4xMiwwLDMACgkQU2UEPGXYAtjf3A/+M6CN6yQEXnolKuSkUMzEMBchATNvO1s
 /sGNjF11Qwxf1Rr/Colb70tYZo3TsCem64bvO8W3KSCUQu2PEAeT248RtLjTYrk+ygx2lTURsOK
 bsNK+mbHO4ua2u0TlHQAa7rfYRdEGOCJJZLdxSTfWYUPntC8HXx6aurMX1miJggGmaDN0VWNveI
 pdHgQD+RQPWC8SUG+IYeC1B1L5Dlx3oLFdJboWC4UrXqiOyPAflPtizRKCfqgvEtB7x8NOtAUvv
 lB8/Yfu++3naaPEBjf2sTC8QSniNqiTGOPyO2xFP4TvBGYg7IbXgCTqo3Z1ApuKl1wqUSLaAPPN
 fc6Q0AjwL8wObaUsKtBvSEcGbkY19Q/jteb0g5cpSnM/BsY3uEZoRALUnNgaJnAAFsDqw+OInMq
 BWCB8Xjv1qh4KIYMhEZ/tGmIgsEPtbQGBRpIl01XioFA19o3FUjrL04s+0miPwGXFbrDx8PgrYT
 UsjCUXeGpmR7dREhZ4G4GmahYwWi1BPkBNm6EcpF9pd2MYhyh14e+VN82U3oh24snKDjtmAZU0G
 dtPgJTQAfqgekBfSKRAD7DMpYdyTJrQDkCidZkls6Rbnu24VMQpaCA+ZmJv1AD1zsbBIJXjVYwb
 k0m2nVjLPVYsgJXYGyMkhz+ancmcQPo0LReUuEuPHupjLQS0aL28=
X-Developer-Key: i=haghdoost@uber.com; a=openpgp;
 fpr=B9FAC14BDE05FFF0FAC0D12D5365043C65D802D8
X-Endpoint-Received: by B4 Relay for haghdoost@uber.com/default with auth_id=764
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

perf script eagerly materializes every ELF symbol into an rb-tree kept
until process exit. Large profiles can therefore consume substantial
anonymous memory, causing perf script to be OOM-killed or forcing the
kernel to reclaim memory from co-located workloads.

This patch adds --max-symbol-bytes to bound struct symbol allocations.
Once the budget is reached, the ELF loader stops loading symbols, warns
once, and lets unresolved addresses appear as [unknown]. This allows
users to bound the memory footprint upfront and explicitly choose between
complete symbolization and avoiding unbounded host memory pressure. perf
record already provides a similar --max-size option to bound disk usage.

The counter includes every symbol__new() allocation, but this patch
enforces the limit only in the ELF loader, which is the source of the
unbounded memory growth addressed here. In this path, reaching the limit
can safely produce [unknown] symbols. Other loaders currently treat a
failed symbol allocation as an error. Capping those paths would therefore
require separate changes whose complexity may outweigh the potential
memory savings.

The cap applies to userspace DSOs, vmlinux-as-ELF, and kernel modules.
Sizes require a B/K/M/G suffix, except that a bare 0 and the default mean
unlimited. Reservations are atomic so concurrent loaders cannot exceed the
limit, and partial zero-sized symbol ranges do not cover omitted
addresses. Allocation and free both charge the stored u16 name length, so
accounting stays balanced; names longer than U16_MAX are charged at the
truncated length.

Document the option with the code that introduces it and add a
concurrent-reservation test.

Signed-off-by: Alireza Haghdoost <haghdoost@uber.com>
---
 tools/perf/Documentation/perf-script.txt | 10 ++++
 tools/perf/builtin-script.c              | 42 ++++++++++++++
 tools/perf/tests/Build                   |  1 +
 tools/perf/tests/builtin-test.c          |  1 +
 tools/perf/tests/symbol-bytes.c          | 94 ++++++++++++++++++++++++++++++++
 tools/perf/tests/tests.h                 |  1 +
 tools/perf/util/symbol-elf.c             | 66 ++++++++++++++++++----
 tools/perf/util/symbol.c                 | 91 +++++++++++++++++++++++++++++--
 tools/perf/util/symbol.h                 |  6 ++
 tools/perf/util/symbol_conf.h            |  1 +
 10 files changed, 299 insertions(+), 14 deletions(-)

diff --git a/tools/perf/Documentation/perf-script.txt b/tools/perf/Documentation/perf-script.txt
index 200ea25891d8..217167a2e56b 100644
--- a/tools/perf/Documentation/perf-script.txt
+++ b/tools/perf/Documentation/perf-script.txt
@@ -412,6 +412,16 @@ include::itrace.txt[]
 
         Default: 127
 
+--max-symbol-bytes::
+	Limit the bytes held in struct symbol allocations for DSOs on the
+	libelf symbol-loader path: userspace DSOs, vmlinux-as-ELF, and kernel
+	modules. This is not a cap on all symbol memory or RSS: symbols from
+	kallsyms, JIT maps, and libbfd are counted but not capped. Accepts a
+	size with a B/K/M/G suffix (e.g. 128M). When the budget is exceeded,
+	the ELF loader stops adding symbols; addresses not covered by symbols
+	already loaded are then printed as [unknown]. A warning is printed.
+	Default: 0 (unlimited).
+
 --ns::
 	Use 9 decimal places when displaying time (i.e. show the nanoseconds)
 
diff --git a/tools/perf/builtin-script.c b/tools/perf/builtin-script.c
index 0174489d1c0f..6c459ce6f433 100644
--- a/tools/perf/builtin-script.c
+++ b/tools/perf/builtin-script.c
@@ -68,6 +68,7 @@
 #include "util/thread.h"
 #include "util/thread_map.h"
 #include "util/time-utils.h"
+#include "util/units.h"
 #include "util/tool.h"
 #include "util/trace-event.h"
 #include "util/unwind.h"
@@ -4110,6 +4111,44 @@ static int parse_callret_trace(const struct option *opt __maybe_unused,
 	return 0;
 }
 
+static int parse_max_symbol_bytes(const struct option *opt,
+				  const char *str, int unset)
+{
+	unsigned long *max_bytes = (unsigned long *)opt->value;
+	static struct parse_tag size_tags[] = {
+		{ .tag  = 'B', .mult = 1       },
+		{ .tag  = 'K', .mult = 1 << 10 },
+		{ .tag  = 'M', .mult = 1 << 20 },
+		{ .tag  = 'G', .mult = 1 << 30 },
+		{ .tag  = 0 },
+	};
+	unsigned long bytes;
+	size_t len;
+
+	if (unset) {
+		*max_bytes = 0;
+		return 0;
+	}
+
+	if (!strcmp(str, "0")) {
+		*max_bytes = 0;
+		return 0;
+	}
+
+	len = strlen(str);
+	if (len < 2 || !strchr("BKMG", str[len - 1]) ||
+	    strspn(str, "0123456789") != len - 1)
+		return -1;
+
+	bytes = parse_tag_value(str, size_tags);
+	if (bytes != (unsigned long)-1) {
+		*max_bytes = bytes;
+		return 0;
+	}
+
+	return -1;
+}
+
 int cmd_script(int argc, const char **argv)
 {
 	bool show_full_info = false;
@@ -4210,6 +4249,9 @@ int cmd_script(int argc, const char **argv)
 		     "Set the maximum stack depth when parsing the callchain, "
 		     "anything beyond the specified depth will be ignored. "
 		     "Default: kernel.perf_event_max_stack or " __stringify(PERF_MAX_STACK_DEPTH)),
+	OPT_CALLBACK(0, "max-symbol-bytes", &symbol_conf.max_symbol_bytes,
+		     "size", "Limit bytes for ELF struct symbol (e.g. 128M; 0=unlimited)",
+		     parse_max_symbol_bytes),
 	OPT_BOOLEAN(0, "reltime", &reltime, "Show time stamps relative to start"),
 	OPT_BOOLEAN(0, "deltatime", &deltatime, "Show time stamps relative to previous event"),
 	OPT_BOOLEAN('I', "show-info", &show_full_info,
diff --git a/tools/perf/tests/Build b/tools/perf/tests/Build
index 81c311b131b7..fe92bfdea724 100644
--- a/tools/perf/tests/Build
+++ b/tools/perf/tests/Build
@@ -67,6 +67,7 @@ perf-test-y += sigtrap.o
 perf-test-y += event_groups.o
 perf-test-y += hybrid-merge.o
 perf-test-y += symbols.o
+perf-test-y += symbol-bytes.o
 perf-test-y += util.o
 perf-test-y += hwmon_pmu.o
 perf-test-y += tool_pmu.o
diff --git a/tools/perf/tests/builtin-test.c b/tools/perf/tests/builtin-test.c
index d2f594921e25..45482a7a91d2 100644
--- a/tools/perf/tests/builtin-test.c
+++ b/tools/perf/tests/builtin-test.c
@@ -154,6 +154,7 @@ static struct test_suite *generic_tests[] = {
 	&suite__event_groups,
 	&suite__hybrid_merge,
 	&suite__symbols,
+	&suite__symbol_bytes,
 	&suite__util,
 	&suite__subcmd_help,
 	&suite__kallsyms_split,
diff --git a/tools/perf/tests/symbol-bytes.c b/tools/perf/tests/symbol-bytes.c
new file mode 100644
index 000000000000..d3055f5ed321
--- /dev/null
+++ b/tools/perf/tests/symbol-bytes.c
@@ -0,0 +1,94 @@
+// SPDX-License-Identifier: GPL-2.0
+#include <limits.h>
+#include <pthread.h>
+#include <stdint.h>
+
+#include "debug.h"
+#include "symbol.h"
+#include "symbol_conf.h"
+#include "tests.h"
+
+struct reserve_arg {
+	size_t bytes;
+	bool success;
+};
+
+static void *reserve_bytes(void *data)
+{
+	struct reserve_arg *arg = data;
+
+	arg->success = symbol__try_account_bytes(arg->bytes);
+	return NULL;
+}
+
+static int test__symbol_bytes_reservation(struct test_suite *test __maybe_unused,
+					  int subtest __maybe_unused)
+{
+	enum { NR_THREADS = 8, NR_ALLOWED = 4 };
+	const size_t reservation = 1024;
+	unsigned long saved_max = symbol_conf.max_symbol_bytes;
+	size_t baseline = symbol__bytes_used();
+	struct reserve_arg args[NR_THREADS];
+	pthread_t threads[NR_THREADS];
+	int created = 0, successful = 0;
+	int ret = TEST_FAIL;
+	int i;
+
+	if (baseline > ULONG_MAX - NR_ALLOWED * reservation)
+		return TEST_SKIP;
+
+	symbol_conf.max_symbol_bytes = baseline + NR_ALLOWED * reservation;
+	if (symbol__try_account_bytes(SIZE_MAX)) {
+		pr_debug("overflowing symbol reservation succeeded\n");
+		symbol__unaccount_bytes(SIZE_MAX);
+		goto out;
+	}
+
+	for (i = 0; i < NR_THREADS; i++) {
+		args[i].bytes = reservation;
+		args[i].success = false;
+		if (pthread_create(&threads[i], NULL, reserve_bytes, &args[i]))
+			goto out_join;
+		created++;
+	}
+
+out_join:
+	for (i = 0; i < created; i++)
+		pthread_join(threads[i], NULL);
+	for (i = 0; i < created; i++) {
+		if (args[i].success)
+			successful++;
+	}
+
+	if (created != NR_THREADS || successful != NR_ALLOWED) {
+		pr_debug("symbol reservation count: created %d, successful %d\n",
+			 created, successful);
+		goto out_release;
+	}
+	if (symbol__bytes_used() != baseline + NR_ALLOWED * reservation) {
+		pr_debug("symbol reservation exceeded configured budget\n");
+		goto out_release;
+	}
+	ret = TEST_OK;
+
+out_release:
+	for (i = 0; i < created; i++) {
+		if (args[i].success)
+			symbol__unaccount_bytes(args[i].bytes);
+	}
+out:
+	symbol_conf.max_symbol_bytes = saved_max;
+	if (symbol__bytes_used() != baseline)
+		ret = TEST_FAIL;
+	return ret;
+}
+
+static struct test_case tests__symbol_bytes[] = {
+	TEST_CASE("Concurrent strict reservations", symbol_bytes_reservation),
+	{ .name = NULL, }
+};
+
+struct test_suite suite__symbol_bytes = {
+	.desc = "Symbol memory accounting",
+	.test_cases = tests__symbol_bytes,
+};
diff --git a/tools/perf/tests/tests.h b/tools/perf/tests/tests.h
index 9c96f33483d1..4a53e063e73d 100644
--- a/tools/perf/tests/tests.h
+++ b/tools/perf/tests/tests.h
@@ -179,6 +179,7 @@ DECLARE_SUITE(sigtrap);
 DECLARE_SUITE(event_groups);
 DECLARE_SUITE(hybrid_merge);
 DECLARE_SUITE(symbols);
+DECLARE_SUITE(symbol_bytes);
 DECLARE_SUITE(util);
 DECLARE_SUITE(uncore_event_sorting);
 DECLARE_SUITE(subcmd_help);
diff --git a/tools/perf/util/symbol-elf.c b/tools/perf/util/symbol-elf.c
index e955c3feddcd..2f7ea1499cbf 100644
--- a/tools/perf/util/symbol-elf.c
+++ b/tools/perf/util/symbol-elf.c
@@ -561,6 +561,13 @@ static bool get_plt_got_name(GElf_Shdr *shdr, size_t i,
 	return result;
 }
 
+static void symbol_budget_warning(void)
+{
+	pr_warning_once("perf: symbol memory budget exceeded (%lu bytes), "
+			"remaining symbols will be [unknown]\n",
+			symbol_conf.max_symbol_bytes);
+}
+
 static int dso__synthesize_plt_got_symbols(struct dso *dso, Elf *elf,
 					   GElf_Ehdr *ehdr,
 					   char *buf, size_t buf_sz)
@@ -580,11 +587,19 @@ static int dso__synthesize_plt_got_symbols(struct dso *dso, Elf *elf,
 		get_rela_dyn_info(elf, ehdr, &di, scn);
 
 	for (i = 0; i < shdr.sh_size; i += shdr.sh_entsize) {
+		bool budget_exceeded;
+
 		if (!get_plt_got_name(&shdr, i, &di, buf, buf_sz))
 			snprintf(buf, buf_sz, "offset_%#" PRIx64 "@plt", (u64)shdr.sh_offset + i);
-		sym = symbol__new(shdr.sh_offset + i, shdr.sh_entsize, STB_GLOBAL, STT_FUNC, buf);
-		if (!sym)
+		sym = symbol__new_bounded(shdr.sh_offset + i, shdr.sh_entsize,
+					  STB_GLOBAL, STT_FUNC, buf, &budget_exceeded);
+		if (!sym) {
+			if (budget_exceeded) {
+				symbol_budget_warning();
+				err = 0;
+			}
 			goto out;
+		}
 		symbols__insert(dso__symbols(dso), sym);
 	}
 	err = 0;
@@ -615,6 +630,7 @@ int dso__synthesize_plt_symbols(struct dso *dso, struct symsrc *ss)
 	Elf *elf;
 	int nr = 0, err = -1;
 	struct rel_info ri = { .is_rela = false };
+	bool budget_exceeded;
 	bool lazy_plt;
 
 	elf = ss->elf;
@@ -636,9 +652,16 @@ int dso__synthesize_plt_symbols(struct dso *dso, struct symsrc *ss)
 		return 0;
 
 	/* Add a symbol for .plt header */
-	plt_sym = symbol__new(shdr_plt.sh_offset, plt_header_size, STB_GLOBAL, STT_FUNC, ".plt");
-	if (!plt_sym)
+	plt_sym = symbol__new_bounded(shdr_plt.sh_offset, plt_header_size,
+					  STB_GLOBAL, STT_FUNC, ".plt",
+					  &budget_exceeded);
+	if (!plt_sym) {
+		if (budget_exceeded) {
+			symbol_budget_warning();
+			return 0;
+		}
 		goto out_elf_end;
+	}
 	symbols__insert(dso__symbols(dso), plt_sym);
 
 	/* Only x86 has .plt.got */
@@ -756,9 +779,15 @@ int dso__synthesize_plt_symbols(struct dso *dso, struct symsrc *ss)
 				 "offset_%#" PRIx64 "@plt", plt_offset);
 		free(demangled);
 
-		f = symbol__new(plt_offset, plt_entry_size, STB_GLOBAL, STT_FUNC, sympltname);
-		if (!f)
+		f = symbol__new_bounded(plt_offset, plt_entry_size, STB_GLOBAL,
+					STT_FUNC, sympltname, &budget_exceeded);
+		if (!f) {
+			if (budget_exceeded) {
+				symbol_budget_warning();
+				err = 0;
+			}
 			goto out_elf_end;
+		}
 
 		plt_offset += plt_entry_size;
 		symbols__insert(dso__symbols(dso), f);
@@ -1534,6 +1563,7 @@ dso__load_sym_internal(struct dso *dso, struct map *map, struct symsrc *syms_ss,
 	Elf *elf;
 	int nr = 0;
 	bool remap_kernel = false, adjust_kernel_syms = false;
+	bool budget_truncated = false;
 	u64 max_text_sh_offset = 0;
 
 	if (kmap && !kmaps)
@@ -1633,8 +1663,16 @@ dso__load_sym_internal(struct dso *dso, struct map *map, struct symsrc *syms_ss,
 		char *demangled = NULL;
 		int is_label = elf_sym__is_label(&sym);
 		const char *section_name;
+		bool budget_exceeded = false;
 		bool used_opd = false;
 
+		if (symbol_conf.max_symbol_bytes &&
+		    symbol__bytes_used() >= symbol_conf.max_symbol_bytes) {
+			symbol_budget_warning();
+			budget_truncated = true;
+			break;
+		}
+
 		if (!is_label && !elf_sym__filter(&sym))
 			continue;
 
@@ -1775,10 +1813,17 @@ dso__load_sym_internal(struct dso *dso, struct map *map, struct symsrc *syms_ss,
 		if (demangled != NULL)
 			elf_name = demangled;
 
-		f = symbol__new(sym.st_value, sym.st_size,
-				GELF_ST_BIND(sym.st_info),
-				GELF_ST_TYPE(sym.st_info), elf_name);
+		f = symbol__new_bounded(sym.st_value, sym.st_size,
+					GELF_ST_BIND(sym.st_info),
+					GELF_ST_TYPE(sym.st_info), elf_name,
+					&budget_exceeded);
+		if (!f && budget_exceeded) {
+			symbol_budget_warning();
+			budget_truncated = true;
+		}
 		free(demangled);
+		if (!f && budget_truncated)
+			break;
 		if (!f)
 			goto out_elf_end;
 
@@ -1793,7 +1838,8 @@ dso__load_sym_internal(struct dso *dso, struct map *map, struct symsrc *syms_ss,
 	 * For misannotated, zeroed, ASM function sizes.
 	 */
 	if (nr > 0) {
-		symbols__fixup_end(dso__symbols(dso), false);
+		if (!budget_truncated)
+			symbols__fixup_end(dso__symbols(dso), false);
 		symbols__fixup_duplicate(dso__symbols(dso));
 		if (kmap) {
 			/*
diff --git a/tools/perf/util/symbol.c b/tools/perf/util/symbol.c
index 4b50250d07fa..cf92a7604a67 100644
--- a/tools/perf/util/symbol.c
+++ b/tools/perf/util/symbol.c
@@ -331,13 +331,82 @@ void symbols__fixup_end(struct rb_root_cached *symbols, bool is_kallsyms)
 		curr->end = roundup(curr->start, 4096) + 4096;
 }
 
-struct symbol *symbol__new(u64 start, u64 len, u8 binding, u8 type, const char *name)
+static _Atomic size_t symbol_bytes_used;
+
+size_t symbol__bytes_used(void)
+{
+	return atomic_load_explicit(&symbol_bytes_used, memory_order_relaxed);
+}
+
+void symbol__account_bytes(size_t bytes)
+{
+	atomic_fetch_add_explicit(&symbol_bytes_used, bytes, memory_order_relaxed);
+}
+
+bool symbol__try_account_bytes(size_t bytes)
+{
+	size_t old = symbol__bytes_used();
+
+	for (;;) {
+		if (old > SIZE_MAX - bytes)
+			return false;
+		if (symbol_conf.max_symbol_bytes &&
+		    (old > symbol_conf.max_symbol_bytes ||
+		     bytes > symbol_conf.max_symbol_bytes - old))
+			return false;
+		if (atomic_compare_exchange_weak_explicit(&symbol_bytes_used, &old, old + bytes,
+							  memory_order_relaxed,
+							  memory_order_relaxed))
+			return true;
+	}
+}
+
+void symbol__unaccount_bytes(size_t bytes)
+{
+	atomic_fetch_sub_explicit(&symbol_bytes_used, bytes, memory_order_relaxed);
+}
+
+/*
+ * Bytes charged for a symbol, derived from the stored u16 namelen so that
+ * allocation and deletion always charge the same amount. Names longer than
+ * U16_MAX are charged at the truncated length.
+ */
+static size_t symbol__charged_bytes(u16 namelen)
+{
+	return symbol_conf.priv_size + sizeof(struct symbol) + namelen + 1;
+}
+
+static struct symbol *__symbol__new(u64 start, u64 len, u8 binding, u8 type,
+				    const char *name, bool bounded,
+				    bool *budget_exceeded)
 {
 	size_t namelen = strlen(name) + 1;
-	struct symbol *sym = calloc(1, (symbol_conf.priv_size +
-					sizeof(*sym) + namelen));
-	if (sym == NULL)
+	size_t alloc_size, charged;
+	struct symbol *sym;
+
+	if (budget_exceeded)
+		*budget_exceeded = false;
+	if (namelen > SIZE_MAX - sizeof(*sym) ||
+	    symbol_conf.priv_size > SIZE_MAX - sizeof(*sym) - namelen)
+		return NULL;
+	alloc_size = symbol_conf.priv_size + sizeof(*sym) + namelen;
+	charged = symbol__charged_bytes(namelen - 1);
+
+	if (bounded && !symbol__try_account_bytes(charged)) {
+		if (budget_exceeded)
+			*budget_exceeded = true;
+		return NULL;
+	}
+
+	sym = calloc(1, alloc_size);
+	if (sym == NULL) {
+		if (bounded)
+			symbol__unaccount_bytes(charged);
 		return NULL;
+	}
+
+	if (!bounded)
+		symbol__account_bytes(charged);
 
 	if (symbol_conf.priv_size) {
 		if (symbol_conf.init_annotation) {
@@ -360,8 +429,21 @@ struct symbol *symbol__new(u64 start, u64 len, u8 binding, u8 type, const char *
 	return sym;
 }
 
+struct symbol *symbol__new(u64 start, u64 len, u8 binding, u8 type, const char *name)
+{
+	return __symbol__new(start, len, binding, type, name, false, NULL);
+}
+
+struct symbol *symbol__new_bounded(u64 start, u64 len, u8 binding, u8 type,
+				  const char *name, bool *budget_exceeded)
+{
+	return __symbol__new(start, len, binding, type, name, true, budget_exceeded);
+}
+
 void symbol__delete(struct symbol *sym)
 {
+	size_t charged = symbol__charged_bytes(sym->namelen);
+
 	if (symbol_conf.priv_size) {
 		if (symbol_conf.init_annotation) {
 			struct annotation *notes = symbol__annotation(sym);
@@ -369,6 +451,7 @@ void symbol__delete(struct symbol *sym)
 			annotation__exit(notes);
 		}
 	}
+	symbol__unaccount_bytes(charged);
 	free(((void *)sym) - symbol_conf.priv_size);
 }
 
diff --git a/tools/perf/util/symbol.h b/tools/perf/util/symbol.h
index b9fa722a9a14..de4ac1c51732 100644
--- a/tools/perf/util/symbol.h
+++ b/tools/perf/util/symbol.h
@@ -227,6 +227,12 @@ void symbol__elf_init(void);
 int symbol__annotation_init(void);
 
 struct symbol *symbol__new(u64 start, u64 len, u8 binding, u8 type, const char *name);
+struct symbol *symbol__new_bounded(u64 start, u64 len, u8 binding, u8 type,
+				  const char *name, bool *budget_exceeded);
+size_t symbol__bytes_used(void);
+void symbol__account_bytes(size_t bytes);
+bool symbol__try_account_bytes(size_t bytes);
+void symbol__unaccount_bytes(size_t bytes);
 size_t __symbol__fprintf_symname_offs(const struct symbol *sym,
 				      const struct addr_location *al,
 				      bool unknown_as_addr,
diff --git a/tools/perf/util/symbol_conf.h b/tools/perf/util/symbol_conf.h
index 37d35f42dcc1..30cbc53cbcd0 100644
--- a/tools/perf/util/symbol_conf.h
+++ b/tools/perf/util/symbol_conf.h
@@ -123,6 +123,7 @@ struct symbol_conf {
 	int		pad_output_len_dso;
 	int		group_sort_idx;
 	int		addr_range;
+	unsigned long	max_symbol_bytes;
 	DECLARE_BITMAP(parallelism_filter, MAX_NR_CPUS + 1);
 };
 

-- 
Git-157)

