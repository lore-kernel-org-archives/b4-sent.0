From: Alireza Haghdoost <haghdoost@uber.com>
Date: Fri, 02 Oct 2026 11:45:36 -0700
Subject: [PATCH v4 4/5] perf script: Add --lazy-load-symbols for lazy
 symbol loading
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261002-perf-symbol-memory-send-v4-4-0a592bb2539e@uber.com>
References: <20261002-perf-symbol-memory-send-v4-0-0a592bb2539e@uber.com>
In-Reply-To: <20261002-perf-symbol-memory-send-v4-0-0a592bb2539e@uber.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=40305; i=haghdoost@uber.com;
 h=from:subject:message-id; bh=+EFWcRNsJf2erwY0XT4UA0rglQQMDrP5YUxoyeb2SVA=;
 b=owEBiQJ2/ZANAwAIAVNlBDxl2ALYAcsmYgBqv/vlTn7e1OU91JRvFAbPQXgzlsp/0KoT7aUd8
 xTPIWbAm2OJAk8EAAEIADkWIQS5+sFL3gX/8PrA0S1TZQQ8ZdgC2AUCar/75RsUgAAAAAAEAA5t
 YW51MiwyLjUrMS4xMiwwLDMACgkQU2UEPGXYAtinDBAAhhsTUGE+ias+xKnveg7xd5EdmeFwWbm
 4uSlcG2Fwy9xkBpx6oG3ulmiNjuV7LQAk6ewQZIzM72QJHTroyQTqGICfYenaL0ibnMA5mgWzlg
 RpVcFcb72WEMYAPlGOvc0fwglt6quO0rmPDbZLtcUSTnvgpXxIfnIDR5z9tCKA2Foa0oHCy1xgJ
 LZgU134Tz4DQVwNMisjxOZ22MCgptm8JhWrLX+vKrvwq5+6LVnyGKg9chgzO7eIIHzexwaI18ea
 nGyq1PGyqx+pkQmzv3ovkcSGAgwadYYw554e5gHj9YIFZfpF7IKz9v52yVWtqlKVXX8cH+EZ2Lr
 64koxoqcJyki6yvO8cBV3gFBFbU4uhXGUzeW+FaeZjZlJDy+4KhF3WcvwhjjZlQLmIQQ+G7r5tV
 cDfLn8fmmlaWi9dSgjrVN8yq/AVnNxbcoTgS4e9l2wKL2AkJ6GAIPQ0kWgFoH+0oU4jOZifSNwb
 ePYKQpGC4I6X0QVv/wwXD4KBLeq7eNmqJOzWQGi/RfJWjZFu/I7oC3p371/GYhYNBMw4Cwslkhy
 DXt7nzXCRLSxgwzeRBODyIxmzD/ulqeptfsJbOQSlNpJDQYAeq+UxrdxpPkLxcPaOTEFbxcOZm9
 y4z7VL7Wz1o7FrWJmkagtATzekQyWXMk47FXv+0ohAoGWNP3XxsE=
X-Developer-Key: i=haghdoost@uber.com; a=openpgp;
 fpr=B9FAC14BDE05FFF0FAC0D12D5365043C65D802D8
X-Endpoint-Received: by B4 Relay for haghdoost@uber.com/default with auth_id=764
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

perf script eagerly materializes eligible symbols from every DSO
encountered in samples and keeps them in an rb-tree until exit.
Most of those symbols are never sampled. On a large profile this
turns symbol loading into the main memory cost of perf script, and in a
memory-constrained cgroup into an OOM kill.

This patch adds --lazy-load-symbols for userspace ELF DSOs. It builds a
compact address-sorted index and materializes ordinary struct symbols on
demand. Names are read and demangled from the exact ELF source through
the existing DSO data cache; resolved symbols are then inserted into the
DSO's existing rb-tree.

struct symbol is unchanged. Each index entry holds only the address range,
binding, type and the ELF string-table offset of the name. When a sample
hits an entry, perf reads and demangles the name and creates a normal
struct symbol with the name embedded, so code outside the loader never
sees an unresolved name.

On a 120-second cgroup profile of a production database service (54k
samples across 11 DSOs), lazy mode reduces peak RssAnon from 314 MiB to
80 MiB and wall time from 4.49 to 3.75 seconds, with identical output.
Memory optimizations usually cost time; this one does not because lazy
loading skips many unnecessary calloc() calls and demangling operations.

Lazy loading is most effective when samples reference only a small
fraction of the available symbols, such as profiles spanning many large
DSOs. It still builds an index proportional to the total symbol count.
Eager loading remains available for dense symbol coverage or cases
requiring its broader ELF and architecture support.

This does not claim full parity with the eager loader. Lazy loading
supports the common userspace ELF symtab/dynsym case; .gnu_debugdata and
PPC64 .opd continue through the eager loader.

To match eager loading, perf first completes zero-sized symbol ranges
and selects among same-address aliases in .symtab. It then adds .dynsym
and repeats those steps on the combined index, preserving symbols found
only in .dynsym. A .dynsym entry that duplicates a .symtab entry is
omitted because eager duplicate selection would discard it; this
prevents binaries that export most of .symtab through .dynsym from
nearly doubling the index during construction.

Lazy loading uses the same duplicate and IFUNC selection as eager
loading and clips ranges that cross .plt before synthesizing PLT
symbols. PLT synthesis itself is unchanged. For nested ranges, lookups
return the innermost symbol containing the address.

Lazy lookups hold the DSO lock while searching the index and inserting
symbols, but release it before reading names because the DSO data cache
takes its global lock before DSO locks. Reads from one index are
serialized because cache-page lookups are otherwise lockless. Before
building the existing name-sorted symbol array, perf materializes the
entire lazy index and detaches it from the DSO. A detached index remains
alive until its last reader finishes, ensuring that no symbols are added
after the name-sorted array is built.

Signed-off-by: Alireza Haghdoost <haghdoost@uber.com>
---
 tools/perf/Documentation/perf-script.txt |   9 +
 tools/perf/builtin-script.c              |   2 +
 tools/perf/util/dso.c                    |  24 +
 tools/perf/util/dso.h                    |  59 ++
 tools/perf/util/map.c                    |   7 +-
 tools/perf/util/symbol-elf.c             | 926 +++++++++++++++++++++++++++++++
 tools/perf/util/symbol-minimal.c         |   9 +
 tools/perf/util/symbol.c                 |   9 +
 tools/perf/util/symbol_conf.h            |   1 +
 9 files changed, 1045 insertions(+), 1 deletion(-)

diff --git a/tools/perf/Documentation/perf-script.txt b/tools/perf/Documentation/perf-script.txt
index f0228e784ced..7ef4642803da 100644
--- a/tools/perf/Documentation/perf-script.txt
+++ b/tools/perf/Documentation/perf-script.txt
@@ -343,6 +343,15 @@ include::itrace.txt[]
 
         Default: 127
 
+--lazy-load-symbols::
+	Resolve symbols lazily instead of eagerly loading the full
+	symbol table of every DSO that appears in a sample. This sharply
+	reduces memory (and usually time) for profiles of large binaries
+	where only a small fraction of the symbol table is referenced. This
+	applies only to userspace ELF DSOs; kernel DSOs, modules, PPC64 DSOs
+	with an .opd section and DSOs whose symbols come from .gnu_debugdata
+	always load eagerly.
+
 --ns::
 	Use 9 decimal places when displaying time (i.e. show the nanoseconds)
 
diff --git a/tools/perf/builtin-script.c b/tools/perf/builtin-script.c
index b6691ebb1b4e..404f5a080d45 100644
--- a/tools/perf/builtin-script.c
+++ b/tools/perf/builtin-script.c
@@ -4287,6 +4287,8 @@ int cmd_script(int argc, const char **argv)
 		     "Set the maximum stack depth when parsing the callchain, "
 		     "anything beyond the specified depth will be ignored. "
 		     "Default: kernel.perf_event_max_stack or " __stringify(PERF_MAX_STACK_DEPTH)),
+	OPT_BOOLEAN(0, "lazy-load-symbols", &symbol_conf.lazy_load_symbols,
+		    "Resolve symbols lazily instead of loading full symtabs"),
 	OPT_BOOLEAN(0, "reltime", &reltime, "Show time stamps relative to start"),
 	OPT_BOOLEAN(0, "deltatime", &deltatime, "Show time stamps relative to previous event"),
 	OPT_BOOLEAN('I', "show-info", &show_full_info,
diff --git a/tools/perf/util/dso.c b/tools/perf/util/dso.c
index 5c4872810ada..d6d2d2ce4157 100644
--- a/tools/perf/util/dso.c
+++ b/tools/perf/util/dso.c
@@ -1721,6 +1721,29 @@ void dso__set_sorted_by_name(struct dso *dso)
 	RC_CHK_ACCESS(dso)->sorted_by_name = true;
 }
 
+struct dso_ondemand *dso_ondemand__new(void)
+{
+	struct dso_ondemand *od = zalloc(sizeof(*od));
+
+	if (od)
+		mutex_init(&od->read_lock);
+	return od;
+}
+
+void dso_ondemand__free(struct dso_ondemand *od)
+{
+	if (!od)
+		return;
+	mutex_destroy(&od->read_lock);
+	free(od->sorted);
+	free(od->outer);
+	if (od->data_dso) {
+		dso__data_close(od->data_dso);
+		dso__put(od->data_dso);
+	}
+	free(od);
+}
+
 struct dso *dso__new_id(const char *name, const struct dso_id *id)
 {
 	RC_STRUCT(dso) *dso = zalloc(sizeof(*dso) + strlen(name) + 1);
@@ -1803,6 +1826,7 @@ void dso__delete(struct dso *dso)
 
 	dso__data_close(dso);
 	auxtrace_cache__free(RC_CHK_ACCESS(dso)->auxtrace_cache);
+	dso_ondemand__free(RC_CHK_ACCESS(dso)->ondemand);
 	dso_cache__free(dso);
 	zfree(&RC_CHK_ACCESS(dso)->data.path);
 	dso__free_a2l(dso);
diff --git a/tools/perf/util/dso.h b/tools/perf/util/dso.h
index 7bcd5ec0c312..6bc43d97278f 100644
--- a/tools/perf/util/dso.h
+++ b/tools/perf/util/dso.h
@@ -283,6 +283,43 @@ struct dso_bpf_prog {
 	struct perf_env	*env;
 };
 
+struct sym_idx {
+	u64	start;
+	u64	end;
+	u32	name_off;
+	u8	binding;
+	u8	type;
+	u8	flags;
+};
+
+#define SYM_IDX_FLAG_IFUNC_ALIAS	(1 << 0)
+#define SYM_IDX_FLAG_MATERIALIZED	(1 << 1)
+#define SYM_IDX_FLAG_DYNSTR		(1 << 2)
+
+#define SYM_IDX_NONE			UINT32_MAX
+
+struct sym_idx_strtab {
+	u64	offset;
+	u64	size;
+};
+
+struct dso_ondemand {
+	struct dso		*data_dso;
+	/* Indexed by whether SYM_IDX_FLAG_DYNSTR is set. */
+	struct sym_idx_strtab	strtab[2];
+	struct sym_idx		*sorted;
+	/*
+	 * Only allocated if some ranges overlap: for each entry, the nearest
+	 * earlier entry that ends after it, or SYM_IDX_NONE.
+	 */
+	u32			*outer;
+	u32			nr_sorted;
+	/* Lookups reading a name without the DSO lock; see sym_idx_ref. */
+	u32			nr_readers;
+	/* The DSO data cache looks up pages without a lock. */
+	struct mutex		read_lock;
+};
+
 struct auxtrace_cache;
 
 DECLARE_RC_STRUCT(dso) {
@@ -314,6 +351,7 @@ DECLARE_RC_STRUCT(dso) {
 	char		 *symsrc_filename;
 	struct nsinfo	*nsinfo;
 	struct auxtrace_cache *auxtrace_cache;
+	struct dso_ondemand *ondemand;
 	union { /* Tool specific area */
 		void	 *priv;
 		u64	 db_id;
@@ -473,6 +511,16 @@ static inline void dso__set_auxtrace_cache(struct dso *dso, struct auxtrace_cach
 	RC_CHK_ACCESS(dso)->auxtrace_cache = cache;
 }
 
+static inline struct dso_ondemand *dso__ondemand(struct dso *dso)
+{
+	return RC_CHK_ACCESS(dso)->ondemand;
+}
+
+static inline void dso__set_ondemand(struct dso *dso, struct dso_ondemand *od)
+{
+	RC_CHK_ACCESS(dso)->ondemand = od;
+}
+
 static inline struct dso_bpf_prog *dso__bpf_prog(struct dso *dso)
 {
 	return &RC_CHK_ACCESS(dso)->bpf_prog;
@@ -849,6 +897,17 @@ char *dso__get_filename(struct dso *dso, const char *root_dir, bool *decomp,
 void dso__put_filename(struct dso *dso, char *filename, bool decomp);
 bool is_kernel_module(const char *pathname, int cpumode);
 bool dso__needs_decompress(struct dso *dso);
+struct symbol *dso__find_symbol_ondemand(struct dso *dso, u64 addr)
+	LOCKS_EXCLUDED(dso__lock(dso));
+void dso__materialize_symbols_ondemand(struct dso *dso)
+	LOCKS_EXCLUDED(dso__lock(dso));
+const char *dso__read_ondemand_symbol_name(struct dso *data_dso,
+					   u64 strtab_offset, u64 strtab_size,
+					   u64 name_off, char *buf,
+					   size_t buflen, char **to_free,
+					   unsigned int *nr_reads);
+struct dso_ondemand *dso_ondemand__new(void);
+void dso_ondemand__free(struct dso_ondemand *od);
 int dso__decompress_kmodule_fd(struct dso *dso, const char *name);
 int dso__decompress_kmodule_path(struct dso *dso, const char *name,
 				 char *pathname, size_t len);
diff --git a/tools/perf/util/map.c b/tools/perf/util/map.c
index 41cdddc987ee..ee46a31d4067 100644
--- a/tools/perf/util/map.c
+++ b/tools/perf/util/map.c
@@ -382,10 +382,15 @@ int map__load(struct map *map)
 
 struct symbol *map__find_symbol(struct map *map, u64 addr)
 {
+	struct dso *dso;
+
 	if (map__load(map) < 0)
 		return NULL;
 
-	return dso__find_symbol(map__dso(map), addr);
+	dso = map__dso(map);
+	if (symbol_conf.lazy_load_symbols)
+		return dso__find_symbol_ondemand(dso, addr);
+	return dso__find_symbol(dso, addr);
 }
 
 struct symbol *map__find_symbol_by_name_idx(struct map *map, const char *name, size_t *idx)
diff --git a/tools/perf/util/symbol-elf.c b/tools/perf/util/symbol-elf.c
index e955c3feddcd..27218803969a 100644
--- a/tools/perf/util/symbol-elf.c
+++ b/tools/perf/util/symbol-elf.c
@@ -2,6 +2,7 @@
 #include <fcntl.h>
 #include <stdio.h>
 #include <errno.h>
+#include <stdint.h>
 #include <stdlib.h>
 #include <string.h>
 #include <unistd.h>
@@ -12,6 +13,7 @@
 #include "libbfd.h"
 #include "map.h"
 #include "maps.h"
+#include "namespaces.h"
 #include "symbol.h"
 #include "symsrc.h"
 #include "machine.h"
@@ -593,6 +595,8 @@ static int dso__synthesize_plt_got_symbols(struct dso *dso, Elf *elf,
 	return err;
 }
 
+static void dso__clip_ondemand_symbols_at(struct dso *dso, u64 addr);
+
 /*
  * We need to check if we have a .dynsym, so that we can handle the
  * .plt, synthesizing its symbols, that aren't on the symtabs (be it
@@ -623,6 +627,13 @@ int dso__synthesize_plt_symbols(struct dso *dso, struct symsrc *ss)
 	if (!elf_section_by_name(elf, &ehdr, &shdr_plt, ".plt", NULL))
 		return 0;
 
+	/*
+	 * Zero-sized or oversized ELF symbols can have been extended across
+	 * .plt. Clip the index first so lookups cannot attribute PLT addresses
+	 * to a preceding symbol before the synthesized PLT symbols are added.
+	 */
+	dso__clip_ondemand_symbols_at(dso, shdr_plt.sh_offset);
+
 	/*
 	 * A symbol from a previous section (e.g. .init) can have been expanded
 	 * by symbols__fixup_end() to overlap .plt. Truncate it before adding
@@ -1515,6 +1526,898 @@ static int dso__process_kernel_symbol(struct dso *dso, struct map *map,
 	return 0;
 }
 
+static int cmp_sym_idx(const void *a, const void *b)
+{
+	const struct sym_idx *sa = a, *sb = b;
+
+	if (sa->start != sb->start)
+		return sa->start < sb->start ? -1 : 1;
+	/*
+	 * qsort is not stable. While sorting, name_off holds the entry's
+	 * position, preserving eager's insertion order for equal-start
+	 * aliases. sym_idx__sort() restores the name offsets afterwards.
+	 */
+	if (sa->name_off != sb->name_off)
+		return sa->name_off < sb->name_off ? -1 : 1;
+	return 0;
+}
+
+static int sym_idx__sort(struct sym_idx *entries, u32 nr)
+{
+	u32 *name_offs, i;
+
+	if (!nr)
+		return 0;
+	name_offs = malloc(nr * sizeof(*name_offs));
+	if (!name_offs)
+		return -ENOMEM;
+	for (i = 0; i < nr; i++) {
+		name_offs[i] = entries[i].name_off;
+		entries[i].name_off = i;
+	}
+	qsort(entries, nr, sizeof(*entries), cmp_sym_idx);
+	for (i = 0; i < nr; i++)
+		entries[i].name_off = name_offs[entries[i].name_off];
+	free(name_offs);
+	return 0;
+}
+
+/* Return the first entry whose start is not less than @addr. */
+static u32 sym_idx__lower_bound(const struct sym_idx *sorted, u32 nr, u64 addr)
+{
+	u32 lo = 0, hi = nr;
+
+	while (lo < hi) {
+		u32 mid = lo + (hi - lo) / 2;
+
+		if (sorted[mid].start < addr)
+			lo = mid + 1;
+		else
+			hi = mid;
+	}
+	return lo;
+}
+
+/* Return the number of entries starting at or before @addr. */
+static u32 sym_idx__upper_bound(const struct dso_ondemand *od, u64 addr)
+{
+	u32 lo = 0, hi = od->nr_sorted;
+
+	while (lo < hi) {
+		u32 mid = lo + (hi - lo) / 2;
+
+		if (od->sorted[mid].start <= addr)
+			lo = mid + 1;
+		else
+			hi = mid;
+	}
+	return lo;
+}
+
+/*
+ * Return the innermost entry containing @addr, i.e. the last-starting one.
+ * Only the last entry starting at or before @addr can contain it unless
+ * ranges overlap. An earlier entry containing @addr ends after every entry
+ * that does not, so following the outer links, each to the nearest earlier
+ * entry that ends later, reaches the innermost one first.
+ */
+static u32 sym_idx__find(const struct dso_ondemand *od, u64 addr)
+{
+	u32 pos = sym_idx__upper_bound(od, addr);
+
+	if (!pos)
+		return SYM_IDX_NONE;
+	pos--;
+	while (pos != SYM_IDX_NONE && od->sorted[pos].end <= addr)
+		pos = od->outer ? od->outer[pos] : SYM_IDX_NONE;
+	return pos;
+}
+
+/*
+ * Allocate the outer links if any ranges overlap, and (re)compute them if
+ * they exist. Recomputing in place cannot fail.
+ */
+static int dso_ondemand__link_overlaps(struct dso_ondemand *od)
+{
+	u32 i, j;
+
+	if (!od->outer) {
+		for (i = 0; i + 1 < od->nr_sorted; i++) {
+			if (od->sorted[i].end > od->sorted[i + 1].start)
+				break;
+		}
+		if (i + 1 >= od->nr_sorted)
+			return 0;
+		od->outer = malloc(od->nr_sorted * sizeof(*od->outer));
+		if (!od->outer)
+			return -ENOMEM;
+	}
+	for (i = 0; i < od->nr_sorted; i++) {
+		j = i ? i - 1 : SYM_IDX_NONE;
+		while (j != SYM_IDX_NONE && od->sorted[j].end <= od->sorted[i].end)
+			j = od->outer[j];
+		od->outer[i] = j;
+	}
+	return 0;
+}
+
+static struct symbol *symbols__find_start(struct rb_root_cached *symbols, u64 start)
+{
+	struct rb_node *n = symbols->rb_root.rb_node;
+
+	while (n) {
+		struct symbol *s = rb_entry(n, struct symbol, rb_node);
+
+		if (start < s->start)
+			n = n->rb_left;
+		else if (start > s->start)
+			n = n->rb_right;
+		else
+			return s;
+	}
+	return NULL;
+}
+
+static void dso__clip_ondemand_symbols_at(struct dso *dso, u64 addr)
+{
+	struct dso_ondemand *od = dso__ondemand(dso);
+	u32 lo, i;
+
+	if (!od)
+		return;
+
+	lo = sym_idx__lower_bound(od->sorted, od->nr_sorted, addr);
+	for (i = 0; i < lo; i++) {
+		struct sym_idx *idx = &od->sorted[i];
+		struct symbol *sym;
+
+		if (idx->end <= addr)
+			continue;
+		idx->end = addr;
+		if (!(idx->flags & SYM_IDX_FLAG_MATERIALIZED))
+			continue;
+		sym = symbols__find_start(dso__symbols(dso), idx->start);
+		if (sym && sym->end > addr)
+			sym->end = addr;
+	}
+	if (od->outer)
+		dso_ondemand__link_overlaps(od);
+}
+
+static bool ondemand_sym_ok(Elf *elf, Elf_Data *secstrs,
+			    const GElf_Sym *sym, u32 sh_link,
+			    uint16_t e_machine)
+{
+	Elf_Scn *sym_sec;
+	GElf_Shdr sym_shdr;
+	int is_label = elf_sym__is_label(sym);
+	const char *name;
+
+	if (!is_label && !elf_sym__filter((GElf_Sym *)sym))
+		return false;
+
+	if (sym->st_shndx == SHN_ABS)
+		return false;
+
+	sym_sec = elf_getscn(elf, sym->st_shndx);
+	if (!sym_sec)
+		return false;
+	if (!gelf_getshdr(sym_sec, &sym_shdr))
+		return false;
+	if (!(sym_shdr.sh_flags & SHF_ALLOC))
+		return false;
+
+	if (is_label && (!secstrs || !elf_sec__filter(&sym_shdr, secstrs)))
+		return false;
+
+	name = elf_strptr(elf, sh_link, sym->st_name);
+	if (!name)
+		return false;
+
+	/*
+	 * Reject ARM/AArch64/RISC-V "mapping symbols" ($a/$d/$t/$x), as
+	 * the eager loop does.  They are zero-size STT_NOTYPE labels in
+	 * allocated sections that would otherwise be indexed and fill
+	 * forward over real functions, misattributing everything after
+	 * them.
+	 */
+	if (e_machine == EM_ARM || e_machine == EM_AARCH64) {
+		if (name[0] == '$' && strchr("adtx", name[1]) &&
+		    (name[2] == '\0' || name[2] == '.'))
+			return false;
+	}
+	if (e_machine == EM_RISCV) {
+		if (name[0] == '$' && strchr("dx", name[1]))
+			return false;
+	}
+
+	return true;
+}
+
+static const char *sym_idx__elf_name(Elf *elf, const size_t *strndx,
+				     const struct sym_idx *idx)
+{
+	return elf_strptr(elf, strndx[!!(idx->flags & SYM_IDX_FLAG_DYNSTR)],
+			  idx->name_off);
+}
+
+static void sym_idx__candidate(const struct sym_idx *idx, const char *name,
+			       struct symbol_candidate *c)
+{
+	c->size = idx->end - idx->start;
+	c->name = name;
+	c->type = idx->type;
+	c->binding = idx->binding;
+}
+
+/*
+ * Keep one entry per start address, choosing among aliases and marking IFUNC
+ * aliases with the same policy as symbols__fixup_duplicate(). Returns the new
+ * entry count.
+ */
+static u32 sym_idx__dedup_aliases(struct dso *dso, Elf *elf,
+				  const size_t *strndx,
+				  struct sym_idx *sorted, u32 count)
+{
+	u32 i, j, k, out = 0;
+
+	for (i = 0; i < count; i = j) {
+		struct symbol_candidate best, cand;
+		char *best_demangled = NULL, *demangled;
+		const char *name;
+		u32 best_idx = i;
+		bool ifunc_alias;
+
+		j = i + 1;
+		while (j < count && sorted[j].start == sorted[i].start)
+			j++;
+		if (j == i + 1) {
+			sorted[out++] = sorted[i];
+			continue;
+		}
+
+		name = sym_idx__elf_name(elf, strndx, &sorted[i]);
+		if (name) {
+			best_demangled = dso__demangle_sym(dso, 0, name);
+			if (best_demangled)
+				name = best_demangled;
+		}
+		sym_idx__candidate(&sorted[i], name, &best);
+		ifunc_alias = sorted[i].flags & SYM_IDX_FLAG_IFUNC_ALIAS;
+
+		for (k = i + 1; k < j; k++) {
+			name = sym_idx__elf_name(elf, strndx, &sorted[k]);
+			if (!best.name || !name)
+				continue;
+
+			demangled = dso__demangle_sym(dso, 0, name);
+			if (demangled)
+				name = demangled;
+			sym_idx__candidate(&sorted[k], name, &cand);
+
+			if (symbol__choose_best(&best, &cand) == SYMBOL_B) {
+				ifunc_alias = (sorted[k].flags & SYM_IDX_FLAG_IFUNC_ALIAS) ||
+					      best.type == STT_GNU_IFUNC;
+				free(best_demangled);
+				best_demangled = demangled;
+				best = cand;
+				best_idx = k;
+			} else {
+				ifunc_alias |= cand.type == STT_GNU_IFUNC;
+				free(demangled);
+			}
+		}
+		free(best_demangled);
+
+		sorted[out] = sorted[best_idx];
+		sorted[out].flags &= ~SYM_IDX_FLAG_IFUNC_ALIAS;
+		if (ifunc_alias)
+			sorted[out].flags |= SYM_IDX_FLAG_IFUNC_ALIAS;
+		out++;
+	}
+	return out;
+}
+
+/*
+ * Whether .dynsym entry @idx is a copy of the .symtab entry at its start, so
+ * that symbols__fixup_duplicate() keeps the .symtab entry. Dropping copies
+ * here keeps a .dynsym that exports most of .symtab from doubling the
+ * index while it is built. The "SyS" check excludes the names on which
+ * arch__choose_best_symbol() does not keep the first of two equal symbols.
+ */
+static bool sym_idx__dynsym_copy(Elf *elf, const size_t *strndx,
+				 const struct sym_idx *symtab, u32 nr,
+				 const struct sym_idx *idx)
+{
+	u32 pos = sym_idx__lower_bound(symtab, nr, idx->start);
+	const struct sym_idx *orig = &symtab[pos];
+	const char *name, *orig_name;
+
+	if (symbol_conf.allow_aliases || pos == nr ||
+	    orig->start != idx->start || orig->end != idx->end ||
+	    idx->end == idx->start || orig->type != idx->type ||
+	    orig->binding != idx->binding)
+		return false;
+	name = sym_idx__elf_name(elf, strndx, idx);
+	orig_name = sym_idx__elf_name(elf, strndx, orig);
+	return name && orig_name && !strcmp(name, orig_name) &&
+	       !strstr(name, "SyS");
+}
+
+/*
+ * Fill @idx from @sym if the eager loader would load it, with end set to
+ * start + size. @symtab holds the fixed up .symtab entries when loading
+ * .dynsym.
+ */
+static bool sym_idx__from_sym(struct symsrc *syms_ss,
+			      struct symsrc *runtime_ss, Elf_Data *secstrs,
+			      bool dynsym, const struct sym_idx *symtab,
+			      u32 nr, const size_t *strndx,
+			      const GElf_Sym *sym, struct sym_idx *idx)
+{
+	Elf *elf = syms_ss->elf;
+	GElf_Shdr shdr = dynsym ? syms_ss->dynshdr : syms_ss->symshdr;
+	u16 e_machine = syms_ss->ehdr.e_machine;
+	u64 adjusted = sym->st_value;
+	GElf_Phdr phdr;
+
+	if (!ondemand_sym_ok(elf, secstrs, sym, shdr.sh_link, e_machine))
+		return false;
+
+	if (e_machine == EM_ARM && GELF_ST_TYPE(sym->st_info) == STT_FUNC &&
+	    (adjusted & 1))
+		--adjusted;
+
+	if (elf_read_program_header(runtime_ss->elf, adjusted, &phdr) == 0) {
+		adjusted -= phdr.p_vaddr - phdr.p_offset;
+	} else {
+		Elf_Scn *sym_sec = elf_getscn(elf, sym->st_shndx);
+		GElf_Shdr sym_shdr;
+
+		if (sym_sec && gelf_getshdr(sym_sec, &sym_shdr)) {
+			/*
+			 * A NOBITS section in a debuginfo file has an invalid
+			 * sh_offset; use the runtime section.
+			 */
+			if (sym_shdr.sh_type == SHT_NOBITS) {
+				sym_sec = elf_getscn(runtime_ss->elf,
+						     sym->st_shndx);
+				if (!sym_sec || !gelf_getshdr(sym_sec, &sym_shdr))
+					return false;
+			}
+			adjusted -= sym_shdr.sh_addr - sym_shdr.sh_offset;
+		}
+	}
+
+	*idx = (struct sym_idx) {
+		.start = adjusted,
+		.end = adjusted + sym->st_size,
+		.name_off = sym->st_name,
+		.binding = GELF_ST_BIND(sym->st_info),
+		.type = GELF_ST_TYPE(sym->st_info),
+		.flags = dynsym ? SYM_IDX_FLAG_DYNSTR : 0,
+	};
+	return !dynsym || !sym_idx__dynsym_copy(elf, strndx, symtab, nr, idx);
+}
+
+/*
+ * Append the eligible symbols of .dynsym or .symtab to *@entries and record
+ * the table's string table in @strtab and @strndx, indexed by @dynsym.
+ */
+static int sym_idx__add_table(struct symsrc *syms_ss, struct symsrc *runtime_ss,
+			      bool dynsym, struct sym_idx **entries, u32 *nr,
+			      struct sym_idx_strtab *strtab, size_t *strndx)
+{
+	Elf *elf = syms_ss->elf;
+	GElf_Ehdr *ehdr = &syms_ss->ehdr;
+	GElf_Shdr shdr = dynsym ? syms_ss->dynshdr : syms_ss->symshdr;
+	GElf_Shdr strshdr;
+	Elf_Scn *strscn, *sec_strndx;
+	Elf_Data *syms, *secstrs = NULL;
+	struct sym_idx *tmp, idx;
+	size_t i, bytes;
+	u64 nr_entries;
+	u32 count = 0, j;
+	GElf_Sym sym;
+
+	syms = elf_getdata(dynsym ? syms_ss->dynsym : syms_ss->symtab, NULL);
+	if (!syms)
+		return -1;
+
+	if (!shdr.sh_entsize)
+		return 0;
+
+	nr_entries = shdr.sh_size / shdr.sh_entsize;
+	if (nr_entries > UINT32_MAX)
+		return -EOVERFLOW;
+
+	strscn = elf_getscn(elf, shdr.sh_link);
+	if (!strscn || !gelf_getshdr(strscn, &strshdr))
+		return -1;
+	strndx[dynsym] = shdr.sh_link;
+
+	sec_strndx = elf_getscn(elf, ehdr->e_shstrndx);
+	if (sec_strndx)
+		secstrs = elf_getdata(sec_strndx, NULL);
+
+	for (i = 0; i < nr_entries; i++) {
+		if (gelf_getsym(syms, i, &sym) &&
+		    sym_idx__from_sym(syms_ss, runtime_ss, secstrs, dynsym,
+				      *entries, *nr, strndx, &sym, &idx))
+			count++;
+	}
+
+	if (!count)
+		return 0;
+	if (count > UINT32_MAX - *nr ||
+	    check_mul_overflow((size_t)(*nr + count), sizeof(**entries), &bytes))
+		return -EOVERFLOW;
+	tmp = realloc(*entries, bytes);
+	if (!tmp)
+		return -1;
+	*entries = tmp;
+
+	/*
+	 * The file may change between the two passes; never fill more entries
+	 * than the first pass counted.
+	 */
+	j = *nr;
+	for (i = 0; i < nr_entries && j < *nr + count; i++) {
+		if (!gelf_getsym(syms, i, &sym) ||
+		    !sym_idx__from_sym(syms_ss, runtime_ss, secstrs, dynsym,
+				       *entries, *nr, strndx, &sym, &idx))
+			continue;
+		tmp[j++] = idx;
+	}
+	*nr = j;
+	strtab[dynsym].offset = strshdr.sh_offset;
+	strtab[dynsym].size = strshdr.sh_size;
+	return 0;
+}
+
+/*
+ * Do what the eager loader does after inserting a table's symbols:
+ * symbols__fixup_end() extends zero-size symbols to the next start, then
+ * symbols__fixup_duplicate() drops aliases.
+ */
+static int sym_idx__fixup(struct dso *dso, Elf *elf, const size_t *strndx,
+			  struct sym_idx *entries, u32 *nr)
+{
+	int err = sym_idx__sort(entries, *nr);
+	u32 i;
+
+	if (err)
+		return err;
+	for (i = 0; i < *nr; i++) {
+		if (entries[i].end != entries[i].start)
+			continue;
+		if (i + 1 < *nr)
+			entries[i].end = entries[i + 1].start;
+		else
+			entries[i].end = roundup(entries[i].start, 4096) + 4096;
+	}
+	if (!symbol_conf.allow_aliases)
+		*nr = sym_idx__dedup_aliases(dso, elf, strndx, entries, *nr);
+	return 0;
+}
+
+static struct symbol *sym_idx__new_symbol(struct dso *dso,
+					  const struct sym_idx *idx,
+					  const char *name)
+{
+	char *demangled = dso__demangle_sym(dso, 0, name);
+	struct symbol *sym;
+
+	sym = symbol__new(idx->start, idx->end - idx->start, idx->binding,
+			  idx->type, demangled ?: name);
+	free(demangled);
+	if (sym && (idx->flags & SYM_IDX_FLAG_IFUNC_ALIAS))
+		symbol__set_ifunc_alias(sym, true);
+	return sym;
+}
+
+/*
+ * PLT synthesis names IRELATIVE slots after the IFUNC they resolve to, which
+ * it looks up in the rb-tree while dso__load() holds the DSO lock.
+ * Materialize IFUNCs now, with names from the ELF image, so that it finds
+ * them without reading names.
+ */
+static void sym_idx__materialize_ifuncs(struct dso *dso, Elf *elf,
+					const size_t *strndx)
+{
+	struct dso_ondemand *od = dso__ondemand(dso);
+	u32 i;
+
+	for (i = 0; i < od->nr_sorted; i++) {
+		struct sym_idx *idx = &od->sorted[i];
+		const char *name;
+		struct symbol *sym;
+
+		if (idx->type != STT_GNU_IFUNC &&
+		    !(idx->flags & SYM_IDX_FLAG_IFUNC_ALIAS))
+			continue;
+		name = sym_idx__elf_name(elf, strndx, idx);
+		sym = name ? sym_idx__new_symbol(dso, idx, name) : NULL;
+		if (!sym)
+			continue;
+		__symbols__insert(dso__symbols(dso), sym);
+		idx->flags |= SYM_IDX_FLAG_MATERIALIZED;
+	}
+}
+
+/*
+ * Check that @path can be reopened to read names. This runs under the DSO
+ * lock, so it opens the file directly: the DSO data cache takes its global
+ * lock before DSO locks.
+ */
+static bool dso_ondemand__source_readable(const struct dso_ondemand *od,
+					  const char *path)
+{
+	const struct sym_idx *idx = &od->sorted[0];
+	const struct sym_idx_strtab *strtab;
+	u64 off;
+	u8 probe;
+	bool ok;
+	int fd;
+
+	strtab = &od->strtab[!!(idx->flags & SYM_IDX_FLAG_DYNSTR)];
+	if (idx->name_off >= strtab->size ||
+	    check_add_overflow(strtab->offset, (u64)idx->name_off, &off) ||
+	    off > INT64_MAX)
+		return false;
+
+	fd = open(path, O_RDONLY | O_CLOEXEC);
+	if (fd < 0)
+		return false;
+	ok = pread(fd, &probe, 1, off) == 1;
+	close(fd);
+	return ok;
+}
+
+/*
+ * Index the symbols of .symtab, if @dynsym is zero, and .dynsym. Like
+ * dso__load_sym(), fix up .symtab first and then both tables together.
+ */
+static int dso__build_ondemand_index(struct dso *dso, struct symsrc *syms_ss,
+				     struct symsrc *runtime_ss,
+				     int dynsym)
+{
+	struct sym_idx_strtab strtab[2] = {};
+	struct sym_idx *entries = NULL, *shrunk;
+	struct dso_ondemand *od;
+	size_t strndx[2] = {};
+	u32 nr = 0, prev;
+	bool in_host_ns;
+	int i, err = 0;
+
+	/*
+	 * GNU debugdata is backed by a temporary decompressed fd rather than a
+	 * reopenable source path. Keep using the eager loader for that case,
+	 * including the runtime .dynsym that dso__load_sym() then loads with
+	 * the runtime file as @syms_ss, so that both are fixed up together.
+	 */
+	if (dso__symtab_type(dso) == DSO_BINARY_TYPE__GNU_DEBUGDATA)
+		return 0;
+
+	for (i = dynsym; i < 2; i++) {
+		if (!(i ? syms_ss->dynsym : syms_ss->symtab))
+			continue;
+		prev = nr;
+		err = sym_idx__add_table(syms_ss, runtime_ss, i, &entries, &nr,
+					 strtab, strndx);
+		if (!err && nr > prev)
+			err = sym_idx__fixup(dso, syms_ss->elf, strndx, entries, &nr);
+		if (err)
+			goto out_free;
+	}
+	if (!nr)
+		goto out_free;
+
+	shrunk = realloc(entries, nr * sizeof(*entries));
+	if (shrunk)
+		entries = shrunk;
+
+	od = dso_ondemand__new();
+	if (!od) {
+		err = -1;
+		goto out_free;
+	}
+	od->sorted = entries;
+	od->nr_sorted = nr;
+	memcpy(od->strtab, strtab, sizeof(strtab));
+	entries = NULL;
+	if (dso_ondemand__link_overlaps(od)) {
+		err = -1;
+		goto out_free_od;
+	}
+
+	/*
+	 * dso__load() has just opened build-id cache files from outside the
+	 * mount namespace of the DSO, so read names from them there too.
+	 * Other sources were opened in the namespace we are in now.
+	 */
+	in_host_ns = syms_ss->type == DSO_BINARY_TYPE__BUILD_ID_CACHE ||
+		     syms_ss->type == DSO_BINARY_TYPE__BUILD_ID_CACHE_DEBUGINFO;
+	if (!in_host_ns && !dso_ondemand__source_readable(od, syms_ss->name))
+		goto out_free_od;
+	od->data_dso = dso__new(syms_ss->name);
+	if (!od->data_dso ||
+	    dso__data_set_path(od->data_dso, syms_ss->name) < 0)
+		goto out_free_od;
+	dso__set_binary_type(od->data_dso, DSO_BINARY_TYPE__SYSTEM_PATH_DSO);
+	if (!in_host_ns)
+		dso__set_nsinfo(od->data_dso, nsinfo__get(dso__nsinfo(dso)));
+
+	dso__set_ondemand(dso, od);
+	sym_idx__materialize_ifuncs(dso, syms_ss->elf, strndx);
+
+	pr_debug("%s: on-demand index: %u symbols (%zu bytes)\n",
+		 dso__long_name(dso), nr,
+		 nr * (sizeof(*od->sorted) + (od->outer ? sizeof(*od->outer) : 0)));
+	return 1;
+
+out_free_od:
+	dso_ondemand__free(od);
+	return err;
+out_free:
+	free(entries);
+	return err;
+}
+
+const char *dso__read_ondemand_symbol_name(struct dso *data_dso,
+					   u64 strtab_offset, u64 strtab_size,
+					   u64 name_off, char *buf,
+					   size_t buflen, char **to_free,
+					   unsigned int *nr_reads)
+{
+	ssize_t n;
+	u64 remain;
+	u64 file_off;
+	size_t cap, want;
+
+	*to_free = NULL;
+
+	if (name_off >= strtab_size)
+		return NULL;
+	if (check_add_overflow(strtab_offset, name_off, &file_off))
+		return NULL;
+	remain = strtab_size - name_off;
+	if (nr_reads)
+		*nr_reads = 0;
+
+	want = min((u64)(buflen - 1), remain);
+	if (nr_reads)
+		(*nr_reads)++;
+	n = dso__data_read_offset(data_dso, NULL, file_off, (u8 *)buf, want);
+	if (n <= 0)
+		return NULL;
+	buf[n] = '\0';
+	if (memchr(buf, '\0', n))
+		return buf;
+	if ((size_t)n < want)
+		return NULL;
+
+	cap = 4096;
+	for (;;) {
+		char *tmp;
+
+		want = cap;
+		if (want > remain)
+			want = remain;
+		if (want == 0)
+			break;
+
+		tmp = *to_free ? realloc(*to_free, want + 1) : malloc(want + 1);
+		if (!tmp) {
+			free(*to_free);
+			*to_free = NULL;
+			return NULL;
+		}
+		*to_free = tmp;
+
+		if (nr_reads)
+			(*nr_reads)++;
+		n = dso__data_read_offset(data_dso, NULL, file_off,
+					  (u8 *)*to_free, want);
+		if (n <= 0) {
+			free(*to_free);
+			*to_free = NULL;
+			return NULL;
+		}
+		(*to_free)[n] = '\0';
+
+		if (memchr(*to_free, '\0', n))
+			return *to_free;
+		if ((size_t)n < want)
+			break;
+
+		if (want >= remain || (u64)n >= remain)
+			break;
+
+		if (cap > SIZE_MAX / 2)
+			break;
+		cap *= 2;
+	}
+
+	free(*to_free);
+	*to_free = NULL;
+	return NULL;
+}
+
+/*
+ * A snapshot of an index entry, so that its name can be read without the DSO
+ * lock: name reads go through the DSO data cache, which takes its global lock
+ * and then the lock of the DSO it opens. The index, and its data source, stay
+ * allocated until the last reader is done, even once detached from the DSO.
+ */
+struct sym_idx_ref {
+	struct dso_ondemand	*od;
+	struct sym_idx_strtab	strtab;
+	struct sym_idx		entry;
+	u32			pos;
+};
+
+static void dso_ondemand__get_ref(struct dso_ondemand *od, u32 pos,
+				  struct sym_idx_ref *ref)
+{
+	ref->od = od;
+	ref->entry = od->sorted[pos];
+	ref->strtab = od->strtab[!!(ref->entry.flags & SYM_IDX_FLAG_DYNSTR)];
+	ref->pos = pos;
+	od->nr_readers++;
+}
+
+/* Return the index to free if @ref was the last reader of a detached one. */
+static struct dso_ondemand *dso_ondemand__put_ref(struct dso *dso,
+						  const struct sym_idx_ref *ref)
+	EXCLUSIVE_LOCKS_REQUIRED(dso__lock(dso))
+{
+	struct dso_ondemand *od = ref->od;
+
+	if (--od->nr_readers || dso__ondemand(dso) == od)
+		return NULL;
+	return od;
+}
+
+static struct symbol *sym_idx_ref__read(struct dso *dso,
+					const struct sym_idx_ref *ref)
+	LOCKS_EXCLUDED(dso__lock(dso))
+{
+	char namebuf[1024];
+	char *name_heap;
+	const char *name;
+	struct symbol *sym;
+
+	mutex_lock(&ref->od->read_lock);
+	name = dso__read_ondemand_symbol_name(ref->od->data_dso, ref->strtab.offset,
+					      ref->strtab.size,
+					      ref->entry.name_off, namebuf,
+					      sizeof(namebuf), &name_heap, NULL);
+	mutex_unlock(&ref->od->read_lock);
+	if (!name)
+		return NULL;
+	sym = sym_idx__new_symbol(dso, &ref->entry, name);
+	free(name_heap);
+	return sym;
+}
+
+/*
+ * Insert @sym, read for @ref, unless the entry or the whole index was
+ * materialized meanwhile. Return the symbol the tree now has for the entry.
+ */
+static struct symbol *dso_ondemand__insert(struct dso *dso,
+					   const struct sym_idx_ref *ref,
+					   struct symbol *sym)
+	EXCLUSIVE_LOCKS_REQUIRED(dso__lock(dso))
+{
+	struct sym_idx *idx = &ref->od->sorted[ref->pos];
+
+	if (dso__ondemand(dso) != ref->od ||
+	    idx->flags & SYM_IDX_FLAG_MATERIALIZED) {
+		if (sym)
+			symbol__delete(sym);
+		return symbols__find_start(dso__symbols(dso), ref->entry.start);
+	}
+	if (sym) {
+		__symbols__insert(dso__symbols(dso), sym);
+		idx->flags |= SYM_IDX_FLAG_MATERIALIZED;
+	}
+	return sym;
+}
+
+static bool dso_ondemand__next_ref(struct dso *dso, u32 *pos,
+				   struct sym_idx_ref *ref)
+	EXCLUSIVE_LOCKS_REQUIRED(dso__lock(dso))
+{
+	struct dso_ondemand *od = dso__ondemand(dso);
+
+	if (!od)
+		return false;
+	while (*pos < od->nr_sorted &&
+	       (od->sorted[*pos].flags & SYM_IDX_FLAG_MATERIALIZED))
+		(*pos)++;
+	if (*pos >= od->nr_sorted)
+		return false;
+	dso_ondemand__get_ref(od, (*pos)++, ref);
+	return true;
+}
+
+void dso__materialize_symbols_ondemand(struct dso *dso)
+{
+	struct dso_ondemand *od;
+	struct sym_idx_ref ref;
+	u32 pos = 0, nr_failed = 0;
+	bool more;
+
+	if (!symbol_conf.lazy_load_symbols)
+		return;
+
+	for (;;) {
+		struct symbol *sym;
+
+		mutex_lock(dso__lock(dso));
+		more = dso_ondemand__next_ref(dso, &pos, &ref);
+		mutex_unlock(dso__lock(dso));
+		if (!more)
+			break;
+
+		sym = sym_idx_ref__read(dso, &ref);
+		if (!sym)
+			nr_failed++;
+		mutex_lock(dso__lock(dso));
+		dso_ondemand__insert(dso, &ref, sym);
+		od = dso_ondemand__put_ref(dso, &ref);
+		mutex_unlock(dso__lock(dso));
+		dso_ondemand__free(od);
+	}
+
+	/*
+	 * Detach the index before the caller builds the name-sorted array, so
+	 * that a DSO with that array never changes again.
+	 */
+	mutex_lock(dso__lock(dso));
+	od = dso__ondemand(dso);
+	dso__set_ondemand(dso, NULL);
+	if (od && od->nr_readers)
+		od = NULL;
+	mutex_unlock(dso__lock(dso));
+
+	if (nr_failed)
+		pr_debug("%s: cannot read %u lazily loaded symbol names\n",
+			 dso__long_name(dso), nr_failed);
+	dso_ondemand__free(od);
+}
+
+struct symbol *dso__find_symbol_ondemand(struct dso *dso, u64 addr)
+{
+	struct dso_ondemand *od;
+	struct sym_idx_ref ref;
+	struct symbol *sym;
+	u32 pos;
+
+	mutex_lock(dso__lock(dso));
+	od = dso__ondemand(dso);
+	pos = od ? sym_idx__find(od, addr) : SYM_IDX_NONE;
+	if (pos == SYM_IDX_NONE) {
+		/* Synthesized PLT symbols, or a fully materialized DSO. */
+		sym = dso__find_symbol(dso, addr);
+	} else if (od->sorted[pos].flags & SYM_IDX_FLAG_MATERIALIZED) {
+		sym = symbols__find_start(dso__symbols(dso), od->sorted[pos].start);
+	} else {
+		dso_ondemand__get_ref(od, pos, &ref);
+		mutex_unlock(dso__lock(dso));
+		sym = sym_idx_ref__read(dso, &ref);
+		mutex_lock(dso__lock(dso));
+		sym = dso_ondemand__insert(dso, &ref, sym);
+		od = dso_ondemand__put_ref(dso, &ref);
+		mutex_unlock(dso__lock(dso));
+		dso_ondemand__free(od);
+		return sym;
+	}
+	mutex_unlock(dso__lock(dso));
+	return sym;
+}
+
 static int
 dso__load_sym_internal(struct dso *dso, struct map *map, struct symsrc *syms_ss,
 		       struct symsrc *runtime_ss, int kmodule, int dynsym)
@@ -1626,6 +2529,29 @@ dso__load_sym_internal(struct dso *dso, struct map *map, struct symsrc *syms_ss,
 	if (kmodule && adjust_kernel_syms)
 		max_text_sh_offset = max_text_section(runtime_ss->elf, &runtime_ss->ehdr);
 
+	/*
+	 * PPC64 ELFv1 function symbols need the eager loop's .opd descriptor
+	 * translation. For symtabs, the selected and runtime sources can differ.
+	 */
+	if (symbol_conf.lazy_load_symbols && !dso__kernel(dso) && !kmodule &&
+	    !syms_ss->opdsec && (dynsym || !runtime_ss->opdsec)) {
+		int oret = 0;
+
+		/*
+		 * The index covers .symtab and .dynsym. If .symtab was
+		 * loaded eagerly, load .dynsym eagerly too.
+		 */
+		if (!dynsym || !syms_ss->symtab)
+			oret = dso__build_ondemand_index(dso, syms_ss,
+							 runtime_ss, dynsym);
+
+		if (oret < 0)
+			return oret;
+		/* If no index was built, load the DSO eagerly. */
+		if (dso__ondemand(dso))
+			return 1;
+	}
+
 	curr_dso = dso__get(dso);
 	elf_symtab__for_each_symbol(syms, nr_syms, idx, sym) {
 		struct symbol *f;
diff --git a/tools/perf/util/symbol-minimal.c b/tools/perf/util/symbol-minimal.c
index 0a71d1463952..848f4c37f881 100644
--- a/tools/perf/util/symbol-minimal.c
+++ b/tools/perf/util/symbol-minimal.c
@@ -373,6 +373,15 @@ void symbol__elf_init(void)
 {
 }
 
+struct symbol *dso__find_symbol_ondemand(struct dso *dso, u64 addr)
+{
+	return dso__find_symbol(dso, addr);
+}
+
+void dso__materialize_symbols_ondemand(struct dso *dso __maybe_unused)
+{
+}
+
 bool filename__has_section(const char *filename __maybe_unused, const char *sec __maybe_unused)
 {
 	return false;
diff --git a/tools/perf/util/symbol.c b/tools/perf/util/symbol.c
index f590b69f9f01..c1b8387df6e3 100644
--- a/tools/perf/util/symbol.c
+++ b/tools/perf/util/symbol.c
@@ -690,6 +690,7 @@ struct symbol *dso__find_symbol_by_name(struct dso *dso, const char *name, size_
 
 void dso__sort_by_name(struct dso *dso)
 {
+	dso__materialize_symbols_ondemand(dso);
 	mutex_lock(dso__lock(dso));
 	if (!dso__sorted_by_name(dso)) {
 		size_t len = 0;
@@ -1940,11 +1941,19 @@ int dso__load(struct dso *dso, struct map *map)
 		}
 
 #ifdef HAVE_LIBBFD_SUPPORT
+#ifdef HAVE_LIBELF_SUPPORT
+		if (is_reg && !symbol_conf.lazy_load_symbols)
+#else
 		if (is_reg)
+#endif
 			bfdrc = dso__load_bfd_symbols(dso, name);
 #endif
 		if (is_reg && bfdrc < 0)
 			sirc = symsrc__init(ss, dso, name, symtab_type);
+#if defined(HAVE_LIBBFD_SUPPORT) && defined(HAVE_LIBELF_SUPPORT)
+		if (is_reg && symbol_conf.lazy_load_symbols && sirc < 0)
+			bfdrc = dso__load_bfd_symbols(dso, name);
+#endif
 
 		if (nsexit)
 			nsinfo__mountns_enter(dso__nsinfo(dso), &nsc);
diff --git a/tools/perf/util/symbol_conf.h b/tools/perf/util/symbol_conf.h
index 37d35f42dcc1..434b6c51288b 100644
--- a/tools/perf/util/symbol_conf.h
+++ b/tools/perf/util/symbol_conf.h
@@ -77,6 +77,7 @@ struct symbol_conf {
 			no_buildid_mmap2,
 			guest_code,
 			lazy_load_kernel_maps,
+			lazy_load_symbols,
 			keep_exited_threads,
 			annotate_data_member,
 			annotate_data_sample,

-- 
Git-157)

