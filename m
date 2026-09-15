From: Alireza Haghdoost <haghdoost@uber.com>
Date: Tue, 15 Sep 2026 11:42:44 -0700
Subject: [PATCH 2/4] perf script: Add --max-symbol-bytes to bound ELF
 symbol memory
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260915-perf-symbol-memory-send-v1-2-1d3360e21f07@uber.com>
References: <20260915-perf-symbol-memory-send-v1-0-1d3360e21f07@uber.com>
In-Reply-To: <20260915-perf-symbol-memory-send-v1-0-1d3360e21f07@uber.com>
To: Peter Zijlstra <peterz@infradead.org>, Ingo Molnar <mingo@redhat.com>, 
 Arnaldo Carvalho de Melo <acme@kernel.org>, 
 Namhyung Kim <namhyung@kernel.org>, Mark Rutland <mark.rutland@arm.com>, 
 Alexander Shishkin <alexander.shishkin@linux.intel.com>, 
 Jiri Olsa <jolsa@kernel.org>, Ian Rogers <irogers@google.com>, 
 Adrian Hunter <adrian.hunter@intel.com>, 
 James Clark <james.clark@linaro.org>, Andrii Nakryiko <andriin@fb.com>, 
 Alexei Starovoitov <ast@kernel.org>
Cc: linux-perf-users@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Alireza Haghdoost <haghdoost@uber.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=7050; i=haghdoost@uber.com;
 h=from:subject:message-id; bh=ROWk7pABVt3iw22u/peSOyqFXvN2NxseymMNxuWT3tI=;
 b=owEBiQJ2/ZANAwAIAVNlBDxl2ALYAcsmYgBqqZHNdWMtxhEN9pZYvvKe+/n1ivHsf4/ShMTJa
 n4K/RQOvjGJAk8EAAEIADkWIQS5+sFL3gX/8PrA0S1TZQQ8ZdgC2AUCaqmRzRsUgAAAAAAEAA5t
 YW51MiwyLjUrMS4xMiwwLDMACgkQU2UEPGXYAthPvg/+IpzFsdAxb8DYmCgISsUuFMJMTXyoMj5
 n52tfl7YV4Q/RWnRo10Wnlj4gusYSHdxKc4iN1YD7R2zIhGP1y7xkRr+gWphVZPxeAthql8gG/9
 W7FS7UkuHYHtcOBZ0aG6WLXQmVTrwMt63M3Ne2uIYyt6/Q9YOeWeJ9LLAFXou/D2zDQ3mMLAUUl
 d+FhdI47Aux5QUiIeXDXUaR7p3wdLDBAMZ1W/j52h7gdQJSKoDvTSmi9OfWsPUSZBrSJwOttzNz
 EptE8AV7ee0NtQnAEZoiiegwtajZ4m3Jh6DhO1jTpB5M+FDi9G+DpU+wvkeEmaPXlcpV1tUIw26
 4zO3KiAm0yF/xgUGhZoWG1BUrKYtWRZlwNHtSHWExfWMc9t7hK12FSa/IETNtsNXm3+iuFyx6Ud
 +qvDFSjfSc+14Fxs+oVN6Fq2PRdHEIidEvsDPfkGwfpOGTiwSsznDaRHWzP4vaYBvTdannC/vRL
 p6zDo8LvxNMIyfEygy+X3dBP+S4eX1eFf6yGblcNzwYjP/kYRULJSm5VSKVa592hLuZzvgWMkwE
 Us1VI2dEkiwcfXSR91KuaCnK2LWLzR9cI+7HfhvtdJXCrQVRu71zRYtY9PdNOKD3SyHs1EghoTa
 xY9VOkbg598Zxiw+p7fIntm6NoSeDZPiFJTwxQp4WFMzsrCC2I10=
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
once, and lets unresolved addresses appear as [unknown].
This allows users to bound the memory footprint upfront and explicitly
choose between complete symbolization and avoiding unbounded host memory
pressure. perf record already provides a similar --max-size option to
bound disk usage.

The counter includes every symbol__new() allocation, but this patch
enforces the limit only in the ELF loader, which is the source of the
unbounded memory growth addressed here. In this path, reaching the limit
can safely produce [unknown] symbols. Other loaders currently treat a
failed symbol allocation as an error. Capping those paths would therefore
require separate changes whose complexity may outweigh the potential
memory savings.

Sizes require a B/K/M/G suffix. Zero, the default, means unlimited.

Signed-off-by: Alireza Haghdoost <haghdoost@uber.com>
Assisted-by: Kimi:K3
---
 tools/perf/builtin-script.c   | 31 +++++++++++++++++++++++++++++++
 tools/perf/util/symbol-elf.c  |  7 +++++++
 tools/perf/util/symbol.c      | 29 +++++++++++++++++++++++++++--
 tools/perf/util/symbol.h      |  3 +++
 tools/perf/util/symbol_conf.h |  1 +
 5 files changed, 69 insertions(+), 2 deletions(-)

diff --git a/tools/perf/builtin-script.c b/tools/perf/builtin-script.c
index ad8ca08ceb5f..50fa6ca6455a 100644
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
@@ -4035,6 +4036,33 @@ static int parse_callret_trace(const struct option *opt __maybe_unused,
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
+
+	if (unset) {
+		*max_bytes = 0;
+		return 0;
+	}
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
@@ -4135,6 +4163,9 @@ int cmd_script(int argc, const char **argv)
 		     "Set the maximum stack depth when parsing the callchain, "
 		     "anything beyond the specified depth will be ignored. "
 		     "Default: kernel.perf_event_max_stack or " __stringify(PERF_MAX_STACK_DEPTH)),
+	OPT_CALLBACK(0, "max-symbol-bytes", &symbol_conf.max_symbol_bytes,
+		     "size", "Limit bytes for ELF struct symbol (e.g. 128M; 0=unlimited)",
+		     parse_max_symbol_bytes),
 	OPT_BOOLEAN(0, "reltime", &reltime, "Show time stamps relative to start"),
 	OPT_BOOLEAN(0, "deltatime", &deltatime, "Show time stamps relative to previous event"),
 	OPT_BOOLEAN('I', "show-info", &show_full_info,
diff --git a/tools/perf/util/symbol-elf.c b/tools/perf/util/symbol-elf.c
index e955c3feddcd..914e42d21f70 100644
--- a/tools/perf/util/symbol-elf.c
+++ b/tools/perf/util/symbol-elf.c
@@ -1634,6 +1634,13 @@ dso__load_sym_internal(struct dso *dso, struct map *map, struct symsrc *syms_ss,
 		int is_label = elf_sym__is_label(&sym);
 		const char *section_name;
 		bool used_opd = false;
+		if (symbol_conf.max_symbol_bytes &&
+		    symbol__bytes_used() >= symbol_conf.max_symbol_bytes) {
+			pr_warning_once("perf: symbol memory budget exceeded (%lu bytes), "
+					"remaining symbols will be [unknown]\n",
+					symbol_conf.max_symbol_bytes);
+			break;
+		}
 
 		if (!is_label && !elf_sym__filter(&sym))
 			continue;
diff --git a/tools/perf/util/symbol.c b/tools/perf/util/symbol.c
index 3587ad243159..62a4f91c2f5d 100644
--- a/tools/perf/util/symbol.c
+++ b/tools/perf/util/symbol.c
@@ -310,14 +310,35 @@ void symbols__fixup_end(struct rb_root_cached *symbols, bool is_kallsyms)
 		curr->end = roundup(curr->start, 4096) + 4096;
 }
 
+static size_t symbol_bytes_used;
+
+size_t symbol__bytes_used(void)
+{
+	return symbol_bytes_used;
+}
+
+void symbol__account_bytes(size_t bytes)
+{
+	symbol_bytes_used += bytes;
+}
+
+void symbol__unaccount_bytes(size_t bytes)
+{
+	symbol_bytes_used -= bytes;
+}
+
 struct symbol *symbol__new(u64 start, u64 len, u8 binding, u8 type, const char *name)
 {
 	size_t namelen = strlen(name) + 1;
-	struct symbol *sym = calloc(1, (symbol_conf.priv_size +
-					sizeof(*sym) + namelen));
+	size_t alloc_size = symbol_conf.priv_size + sizeof(struct symbol) + namelen;
+	struct symbol *sym;
+
+	sym = calloc(1, alloc_size);
 	if (sym == NULL)
 		return NULL;
 
+	symbol__account_bytes(alloc_size);
+
 	if (symbol_conf.priv_size) {
 		if (symbol_conf.init_annotation) {
 			struct annotation *notes = (void *)sym;
@@ -341,6 +362,9 @@ struct symbol *symbol__new(u64 start, u64 len, u8 binding, u8 type, const char *
 
 void symbol__delete(struct symbol *sym)
 {
+	size_t alloc_size = symbol_conf.priv_size + sizeof(struct symbol) +
+			    sym->namelen + 1;
+
 	if (symbol_conf.priv_size) {
 		if (symbol_conf.init_annotation) {
 			struct annotation *notes = symbol__annotation(sym);
@@ -348,6 +372,7 @@ void symbol__delete(struct symbol *sym)
 			annotation__exit(notes);
 		}
 	}
+	symbol__unaccount_bytes(alloc_size);
 	free(((void *)sym) - symbol_conf.priv_size);
 }
 
diff --git a/tools/perf/util/symbol.h b/tools/perf/util/symbol.h
index e5cef16b240d..0d5d3792aac1 100644
--- a/tools/perf/util/symbol.h
+++ b/tools/perf/util/symbol.h
@@ -228,6 +228,9 @@ void symbol__elf_init(void);
 int symbol__annotation_init(void);
 
 struct symbol *symbol__new(u64 start, u64 len, u8 binding, u8 type, const char *name);
+size_t symbol__bytes_used(void);
+void symbol__account_bytes(size_t bytes);
+void symbol__unaccount_bytes(size_t bytes);
 size_t __symbol__fprintf_symname_offs(const struct symbol *sym,
 				      const struct addr_location *al,
 				      bool unknown_as_addr,
diff --git a/tools/perf/util/symbol_conf.h b/tools/perf/util/symbol_conf.h
index 71f60081a85b..6a16c5badd5e 100644
--- a/tools/perf/util/symbol_conf.h
+++ b/tools/perf/util/symbol_conf.h
@@ -120,6 +120,7 @@ struct symbol_conf {
 	int		pad_output_len_dso;
 	int		group_sort_idx;
 	int		addr_range;
+	unsigned long	max_symbol_bytes;
 	DECLARE_BITMAP(parallelism_filter, MAX_NR_CPUS + 1);
 };
 

-- 
Git-155)

