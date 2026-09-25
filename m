From: Alireza Haghdoost <haghdoost@uber.com>
Date: Fri, 25 Sep 2026 12:09:42 -0700
Subject: [PATCH v3 5/6] perf script: Add --lazy-load-symbols for lazy
 symbol loading
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260925-perf-symbol-memory-send-v3-5-3e4e234c363b@uber.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=32727; i=haghdoost@uber.com;
 h=from:subject:message-id; bh=s4Wr76ePfIJnC4jl7Q6SXqvyJWjs0/xgyfJgEEP18Sg=;
 b=owEBiQJ2/ZANAwAIAVNlBDxl2ALYAcsmYgBqtshED2Pt8Hd8CDIwxCzjlnUSUJ/CBBIaUdJCD
 Gu5xZ7PKeOJAk8EAAEIADkWIQS5+sFL3gX/8PrA0S1TZQQ8ZdgC2AUCarbIRBsUgAAAAAAEAA5t
 YW51MiwyLjUrMS4xMiwwLDMACgkQU2UEPGXYAthb5g//TMOl3TgCXpuH9sJzS7Xx3UgWpn/e9pX
 ErjLd0CXzT8XxRLQ+llA1doSyiVj0SdbVYW+H3OuIJCL0q7RgUbqAmC76/uSiM9qEiJv8FS3w2v
 tqePZ6aYwdtwyaYo7Jo6tPFUXMOlM54r5QMiFRvKhKanQGp8YndWn2QQdoTam9XTuesrQCArGpw
 Ph4jG0lLBPx1KYanCWr4lRCTgvfJAh6TLkUEwmsDnOqKBsWuMz6Sx2S/tbg6rYhFlx+Vs788OQ9
 1NFprE7esdDfiI6bqHF2GkqWSW1gnFXupO3YcUjZpwsko4MWQKDIGfw9Z9TtHXPPe1rFua028F1
 igvh6zECeygDwYrHFFBG0e5/WMRvp8VuhUblQiJI74Lz/X7C+V1EUVK8nQgkMPry+jkv+i1TafL
 91H2cVXVDU8WjpGszxG8/Wd/mBzc5Zk5qUw7a0ktxojW3ya7C5Zk9fbUJa7ZDMQPppRFcvk5UaZ
 +fvYjbzQUY2mbkrLHb4p46Mo6XweEB3HEaos4HysrCBueXcIrN12yRWQdpzLSnH+ScdJtqmzXoy
 f/9V6M2fC+Z22Y8RmhoTq1zoj/E1t5aqWz+59gLwWp0beZbo/h4QIfTrwqzjwyHGoPdaYkeu+g8
 2bSxNFRrcfH873wc4EF1Pzn5Cv2xHynghNaMtOr64Z22fQzNA8wQ=
X-Developer-Key: i=haghdoost@uber.com; a=openpgp;
 fpr=B9FAC14BDE05FFF0FAC0D12D5365043C65D802D8
X-Endpoint-Received: by B4 Relay for haghdoost@uber.com/default with auth_id=764
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

perf script eagerly materializes eligible symbols from every DSO
encountered in samples. On a production fixture, it loaded about 765k
symbols to resolve about 45k distinct (DSO, symbol) frames, exceeding the
memory available in a memory-constrained cgroup.

This patch adds --lazy-load-symbols for userspace ELF DSOs. It builds a
compact sorted index, resolves sampled addresses by binary search, reads
symbol names through a private data-source DSO, and caches resolved symbols
in the existing rb-tree. The private DSO uses the normal DSO data cache, so
the exact split-debuginfo source can be reopened after descriptor eviction.
If the source cannot be read during preflight, perf discards the index and
eagerly loads that DSO instead.

On the same fixture, peak RssAnon drops from 265 MiB to 39 MiB and wall
time from 3.1 seconds to 1.85 seconds. Memory optimizations usually cost
time; this one does not because lazy loading skips many unnecessary
calloc() calls and demangling operations.

Lazy loading is most effective when samples reference only a small
fraction of the available symbols, such as profiles spanning many large
DSOs. It still builds an index proportional to the total symbol count.
Eager loading remains available for dense symbol coverage or cases
requiring its broader ELF and architecture support.

This does not claim full parity with the eager loader. Lazy loading
supports the common userspace ELF symtab/dynsym case; .gnu_debugdata and
PPC64 .opd continue through the eager loader.

Materialization is serialized with the DSO lock. Name lookups materialize
the remaining index before constructing the name-sorted array. Lazy loading
shares eager duplicate and IFUNC selection, and clips ranges that cross
.plt before synthesizing PLT symbols.

In lazy mode, address lookups always take the DSO lock. Name lookups also
free the index before the name-sorted array is built, even when the
symbol budget stops materialization early, so a DSO with a name array
never changes again. When no PT_LOAD covers a symbol, it falls back to
the section header as the eager loader does, using the runtime section
for NOBITS sections of a debuginfo file.

Signed-off-by: Alireza Haghdoost <haghdoost@uber.com>
---
 tools/perf/Documentation/perf-script.txt |  16 +
 tools/perf/builtin-script.c              |   2 +
 tools/perf/util/dso.c                    |  17 +
 tools/perf/util/dso.h                    |  45 +++
 tools/perf/util/map.c                    |  19 +-
 tools/perf/util/symbol-elf.c             | 662 +++++++++++++++++++++++++++++++
 tools/perf/util/symbol-minimal.c         |  16 +
 tools/perf/util/symbol.c                 |   9 +
 tools/perf/util/symbol_conf.h            |   1 +
 9 files changed, 786 insertions(+), 1 deletion(-)

diff --git a/tools/perf/Documentation/perf-script.txt b/tools/perf/Documentation/perf-script.txt
index 217167a2e56b..615c3ba1aab6 100644
--- a/tools/perf/Documentation/perf-script.txt
+++ b/tools/perf/Documentation/perf-script.txt
@@ -412,6 +412,21 @@ include::itrace.txt[]
 
         Default: 127
 
+--lazy-load-symbols::
+	Resolve symbols lazily instead of eagerly loading the full
+	symbol table of every DSO that appears in a sample. A compact
+	sorted index is built per DSO and only the addresses that appear
+	in samples are materialized into symbols, with names read from the
+	file's string table through the DSO data cache at lookup time. This
+	sharply reduces memory (and usually time) for profiles of large
+	binaries where only a small fraction of the symbol table is
+	referenced. This applies only to userspace ELF DSOs; kernel DSOs and
+	modules always load eagerly. Operations that look up a symbol by name
+	materialize the remainder of that DSO's index first to preserve
+	name-lookup behavior.
+	Output may differ from the default loader for some targets
+	(e.g. PPC64 .opd or .gnu_debugdata). Default: off.
+
 --max-symbol-bytes::
 	Limit the bytes held in struct symbol allocations for DSOs on the
 	libelf symbol-loader path: userspace DSOs, vmlinux-as-ELF, and kernel
@@ -420,6 +435,7 @@ include::itrace.txt[]
 	size with a B/K/M/G suffix (e.g. 128M). When the budget is exceeded,
 	the ELF loader stops adding symbols; addresses not covered by symbols
 	already loaded are then printed as [unknown]. A warning is printed.
+	With --lazy-load-symbols, the lazy symbol index is also counted.
 	Default: 0 (unlimited).
 
 --ns::
diff --git a/tools/perf/builtin-script.c b/tools/perf/builtin-script.c
index 6c459ce6f433..f7b8b5f03ef4 100644
--- a/tools/perf/builtin-script.c
+++ b/tools/perf/builtin-script.c
@@ -4252,6 +4252,8 @@ int cmd_script(int argc, const char **argv)
 	OPT_CALLBACK(0, "max-symbol-bytes", &symbol_conf.max_symbol_bytes,
 		     "size", "Limit bytes for ELF struct symbol (e.g. 128M; 0=unlimited)",
 		     parse_max_symbol_bytes),
+	OPT_BOOLEAN(0, "lazy-load-symbols", &symbol_conf.lazy_load_symbols,
+		    "Resolve symbols lazily instead of loading full symtabs"),
 	OPT_BOOLEAN(0, "reltime", &reltime, "Show time stamps relative to start"),
 	OPT_BOOLEAN(0, "deltatime", &deltatime, "Show time stamps relative to previous event"),
 	OPT_BOOLEAN('I', "show-info", &show_full_info,
diff --git a/tools/perf/util/dso.c b/tools/perf/util/dso.c
index c88b2a771832..9cbde0a7977e 100644
--- a/tools/perf/util/dso.c
+++ b/tools/perf/util/dso.c
@@ -1704,6 +1704,20 @@ void dso__set_sorted_by_name(struct dso *dso)
 	RC_CHK_ACCESS(dso)->sorted_by_name = true;
 }
 
+void dso__free_ondemand(struct dso *dso)
+{
+	struct dso_ondemand *od = RC_CHK_ACCESS(dso)->ondemand;
+
+	if (!od)
+		return;
+	RC_CHK_ACCESS(dso)->ondemand = NULL;
+	free(od->sorted);
+	symbol__unaccount_bytes(od->nr_alloc * sizeof(*od->sorted));
+	dso__data_close(od->data_dso);
+	dso__put(od->data_dso);
+	free(od);
+}
+
 struct dso *dso__new_id(const char *name, const struct dso_id *id)
 {
 	RC_STRUCT(dso) *dso = zalloc(sizeof(*dso) + strlen(name) + 1);
@@ -1785,6 +1799,9 @@ void dso__delete(struct dso *dso)
 
 	dso__data_close(dso);
 	auxtrace_cache__free(RC_CHK_ACCESS(dso)->auxtrace_cache);
+	mutex_lock(dso__lock(dso));
+	dso__free_ondemand(dso);
+	mutex_unlock(dso__lock(dso));
 	dso_cache__free(dso);
 	zfree(&RC_CHK_ACCESS(dso)->data.path);
 	dso__free_a2l(dso);
diff --git a/tools/perf/util/dso.h b/tools/perf/util/dso.h
index ff2c91e9a2b9..6e6c2c7f13a8 100644
--- a/tools/perf/util/dso.h
+++ b/tools/perf/util/dso.h
@@ -283,6 +283,27 @@ struct dso_bpf_prog {
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
+
+struct dso_ondemand {
+	struct dso	*data_dso;
+	u64		 strtab_offset;
+	u64		 strtab_size;
+	struct sym_idx	*sorted;
+	u32		 nr_sorted;
+	u32		 nr_alloc;
+};
+
 struct auxtrace_cache;
 
 DECLARE_RC_STRUCT(dso) {
@@ -314,6 +335,7 @@ DECLARE_RC_STRUCT(dso) {
 	char		 *symsrc_filename;
 	struct nsinfo	*nsinfo;
 	struct auxtrace_cache *auxtrace_cache;
+	struct dso_ondemand *ondemand;
 	union { /* Tool specific area */
 		void	 *priv;
 		u64	 db_id;
@@ -466,6 +488,16 @@ static inline void dso__set_auxtrace_cache(struct dso *dso, struct auxtrace_cach
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
@@ -838,6 +870,19 @@ int dso__read_binary_type_filename(const struct dso *dso, enum dso_binary_type t
 				   const char *root_dir, char *filename, size_t size);
 bool is_kernel_module(const char *pathname, int cpumode);
 bool dso__needs_decompress(struct dso *dso);
+struct symbol *dso__find_symbol_ondemand(struct dso *dso, u64 addr)
+	EXCLUSIVE_LOCKS_REQUIRED(dso__lock(dso));
+struct symbol *dso__find_symbol_ondemand_exact(struct dso *dso, u64 addr)
+	EXCLUSIVE_LOCKS_REQUIRED(dso__lock(dso));
+void dso__materialize_symbols_ondemand(struct dso *dso)
+	EXCLUSIVE_LOCKS_REQUIRED(dso__lock(dso));
+const char *dso__read_ondemand_symbol_name(struct dso *data_dso,
+					   u64 strtab_offset, u64 strtab_size,
+					   u64 name_off, char *buf,
+					   size_t buflen, char **to_free,
+					   unsigned int *nr_reads);
+void dso__free_ondemand(struct dso *dso)
+	EXCLUSIVE_LOCKS_REQUIRED(dso__lock(dso));
 int dso__decompress_kmodule_fd(struct dso *dso, const char *name);
 int dso__decompress_kmodule_path(struct dso *dso, const char *name,
 				 char *pathname, size_t len);
diff --git a/tools/perf/util/map.c b/tools/perf/util/map.c
index 41cdddc987ee..d0fff55eab92 100644
--- a/tools/perf/util/map.c
+++ b/tools/perf/util/map.c
@@ -382,10 +382,27 @@ int map__load(struct map *map)
 
 struct symbol *map__find_symbol(struct map *map, u64 addr)
 {
+	struct dso *dso;
+	struct symbol *sym;
+
 	if (map__load(map) < 0)
 		return NULL;
 
-	return dso__find_symbol(map__dso(map), addr);
+	dso = map__dso(map);
+	if (!symbol_conf.lazy_load_symbols)
+		return dso__find_symbol(dso, addr);
+
+	/*
+	 * A lazily loaded DSO inserts symbols into its rb-tree on lookup and
+	 * drops its index once fully materialized. Look up and materialize
+	 * under the DSO lock so readers never race with either change.
+	 */
+	mutex_lock(dso__lock(dso));
+	sym = dso__find_symbol(dso, addr);
+	if (!sym)
+		sym = dso__find_symbol_ondemand(dso, addr);
+	mutex_unlock(dso__lock(dso));
+	return sym;
 }
 
 struct symbol *map__find_symbol_by_name_idx(struct map *map, const char *name, size_t *idx)
diff --git a/tools/perf/util/symbol-elf.c b/tools/perf/util/symbol-elf.c
index 2f7ea1499cbf..bb859bafece1 100644
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
@@ -334,6 +336,7 @@ static bool addend_may_be_ifunc(GElf_Ehdr *ehdr, struct rel_info *ri)
 
 static bool get_ifunc_name(Elf *elf, struct dso *dso, GElf_Ehdr *ehdr,
 			   struct rel_info *ri, char *buf, size_t buf_sz)
+	EXCLUSIVE_LOCKS_REQUIRED(dso__lock(dso))
 {
 	u64 addr = ri->rela.r_addend;
 	struct symbol *sym;
@@ -348,6 +351,8 @@ static bool get_ifunc_name(Elf *elf, struct dso *dso, GElf_Ehdr *ehdr,
 	addr -= phdr.p_vaddr - phdr.p_offset;
 
 	sym = dso__find_symbol_nocache(dso, addr);
+	if (!sym && dso__ondemand(dso))
+		sym = dso__find_symbol_ondemand_exact(dso, addr);
 
 	/* Expecting the address to be an IFUNC or IFUNC alias */
 	if (!sym || sym->start != addr ||
@@ -608,6 +613,26 @@ static int dso__synthesize_plt_got_symbols(struct dso *dso, Elf *elf,
 	return err;
 }
 
+static u32 sym_idx__lower_bound(const struct dso_ondemand *od, u64 addr);
+
+static void dso__clip_ondemand_symbols_at(struct dso *dso, u64 addr)
+{
+	struct dso_ondemand *od = dso__ondemand(dso);
+	u32 lo, i;
+
+	if (!od)
+		return;
+
+	lo = sym_idx__lower_bound(od, addr);
+	if (!lo)
+		return;
+
+	for (i = 0; i < lo; i++) {
+		if (od->sorted[i].end > addr)
+			od->sorted[i].end = addr;
+	}
+}
+
 /*
  * We need to check if we have a .dynsym, so that we can handle the
  * .plt, synthesizing its symbols, that aren't on the symtabs (be it
@@ -616,6 +641,7 @@ static int dso__synthesize_plt_got_symbols(struct dso *dso, Elf *elf,
  * have the PLT data stripped out (shdr_rel_plt.sh_type == SHT_NOBITS).
  */
 int dso__synthesize_plt_symbols(struct dso *dso, struct symsrc *ss)
+	EXCLUSIVE_LOCKS_REQUIRED(dso__lock(dso))
 {
 	uint32_t idx;
 	GElf_Sym sym;
@@ -639,6 +665,13 @@ int dso__synthesize_plt_symbols(struct dso *dso, struct symsrc *ss)
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
@@ -1544,6 +1577,607 @@ static int dso__process_kernel_symbol(struct dso *dso, struct map *map,
 	return 0;
 }
 
+static int cmp_sym_idx(const void *a, const void *b)
+{
+	const struct sym_idx *sa = a, *sb = b;
+
+	if (sa->start != sb->start)
+		return sa->start < sb->start ? -1 : 1;
+	/*
+	 * qsort is not stable. During sorting name_off temporarily holds
+	 * the fill ordinal, preserving eager's symtab insertion order for
+	 * equal-start aliases. It is restored to st_name afterwards.
+	 */
+	if (sa->name_off != sb->name_off)
+		return sa->name_off < sb->name_off ? -1 : 1;
+	return 0;
+}
+
+/*
+ * Return the first entry whose start is not less than @addr. ISO C bsearch()
+ * does not provide an insertion point or guarantee the first equal entry, so
+ * clipping and exact-start alias lookup use this helper.
+ */
+static u32 sym_idx__lower_bound(const struct dso_ondemand *od, u64 addr)
+{
+	u32 lo = 0, hi = od->nr_sorted;
+
+	while (lo < hi) {
+		u32 mid = lo + (hi - lo) / 2;
+
+		if (od->sorted[mid].start < addr)
+			lo = mid + 1;
+		else
+			hi = mid;
+	}
+	return lo;
+}
+
+static int cmp_addr_to_sym_idx(const void *key, const void *entry)
+{
+	u64 addr = *(const u64 *)key;
+	const struct sym_idx *idx = entry;
+
+	if (addr < idx->start)
+		return -1;
+	if (addr >= idx->end)
+		return 1;
+	return 0;
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
+ * Keep one index entry per start address, choosing among aliases with the
+ * same policy as symbols__fixup_duplicate(). Mark a survivor whose group
+ * contained an IFUNC, then shrink the index. Returns the new entry count.
+ */
+static u32 dso_ondemand__dedup_aliases(struct dso *dso, struct dso_ondemand *od,
+				       Elf *elf, size_t strtab_idx, u32 count)
+{
+	struct sym_idx *sorted = od->sorted, *shrunk;
+	u32 i, j, out = 0;
+
+	for (i = 0; i < count; i = j) {
+		struct symbol_candidate best, cand;
+		bool has_ifunc = sorted[i].type == STT_GNU_IFUNC;
+		char *best_demangled = NULL, *demangled;
+		const char *name;
+		u32 best_idx = i;
+
+		name = elf_strptr(elf, strtab_idx, sorted[i].name_off);
+		if (name) {
+			best_demangled = dso__demangle_sym(dso, 0, name);
+			if (best_demangled)
+				name = best_demangled;
+		}
+		sym_idx__candidate(&sorted[i], name, &best);
+
+		for (j = i + 1; j < count && sorted[j].start == sorted[i].start; j++) {
+			has_ifunc |= sorted[j].type == STT_GNU_IFUNC;
+			name = elf_strptr(elf, strtab_idx, sorted[j].name_off);
+			if (!best.name || !name)
+				continue;
+
+			demangled = dso__demangle_sym(dso, 0, name);
+			if (demangled)
+				name = demangled;
+			sym_idx__candidate(&sorted[j], name, &cand);
+
+			if (symbol__choose_best(&best, &cand) == SYMBOL_B) {
+				free(best_demangled);
+				best_demangled = demangled;
+				best = cand;
+				best_idx = j;
+			} else {
+				free(demangled);
+			}
+		}
+		free(best_demangled);
+
+		sorted[out] = sorted[best_idx];
+		if (has_ifunc && sorted[out].type != STT_GNU_IFUNC)
+			sorted[out].flags |= SYM_IDX_FLAG_IFUNC_ALIAS;
+		out++;
+	}
+
+	if (out < count) {
+		shrunk = realloc(sorted, out * sizeof(*sorted));
+		if (shrunk) {
+			od->sorted = shrunk;
+			symbol__unaccount_bytes((od->nr_alloc - out) * sizeof(*sorted));
+			od->nr_alloc = out;
+		}
+	}
+	return out;
+}
+
+static int dso__build_ondemand_index(struct dso *dso, struct symsrc *syms_ss,
+				     struct symsrc *runtime_ss,
+				     int dynsym)
+{
+	struct dso_ondemand *od;
+	Elf *elf = syms_ss->elf;
+	GElf_Ehdr ehdr = syms_ss->ehdr;
+	GElf_Shdr shdr;
+	GElf_Shdr strshdr;
+	Elf_Scn *strscn, *sec_strndx;
+	Elf_Data *syms;
+	GElf_Sym sym;
+	Elf_Data *secstrs = NULL;
+	size_t i, index_bytes, reservation_peak;
+	u32 count = 0, j;
+	u32 *name_offsets;
+	u64 nr_entries, strtab_offset;
+	u64 probe_off;
+	u8 probe;
+
+	/*
+	 * GNU debugdata is backed by a temporary decompressed fd rather than a
+	 * reopenable source path. Keep using the eager loader for that case.
+	 */
+	if (syms_ss->type == DSO_BINARY_TYPE__GNU_DEBUGDATA)
+		return 0;
+
+	if (dynsym)
+		shdr = syms_ss->dynshdr;
+	else
+		shdr = syms_ss->symshdr;
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
+	strtab_offset = strshdr.sh_offset;
+
+	/*
+	 * Section name string table, used to match the eager path's
+	 * elf_sec__filter() (text/data section check for STT_NOTYPE labels).
+	 */
+	sec_strndx = elf_getscn(elf, ehdr.e_shstrndx);
+	if (sec_strndx)
+		secstrs = elf_getdata(sec_strndx, NULL);
+
+	for (i = 0; i < nr_entries; i++) {
+		if (!gelf_getsym(syms, i, &sym))
+			continue;
+		if (ondemand_sym_ok(elf, secstrs, &sym, shdr.sh_link,
+				    ehdr.e_machine))
+			count++;
+	}
+
+	if (!count)
+		return 0;
+	if (check_mul_overflow((size_t)count, sizeof(*od->sorted),
+			       &index_bytes))
+		return -EOVERFLOW;
+
+	/*
+	 * Account the index against the symbol memory budget: at 24
+	 * bytes/symbol it is the dominant on-demand cost and must count
+	 * toward --max-symbol-bytes just like struct symbol allocations do.
+	 */
+	if (!symbol__try_account_bytes(index_bytes)) {
+		symbol_budget_warning();
+		return 0;
+	}
+	reservation_peak = symbol__bytes_used();
+
+	od = zalloc(sizeof(*od));
+	if (!od) {
+		symbol__unaccount_bytes(index_bytes);
+		return -1;
+	}
+
+	od->sorted = zalloc(index_bytes);
+	if (!od->sorted) {
+		symbol__unaccount_bytes(index_bytes);
+		free(od);
+		return -1;
+	}
+	od->nr_alloc = count;
+	name_offsets = malloc(count * sizeof(*name_offsets));
+	if (!name_offsets) {
+		symbol__unaccount_bytes(index_bytes);
+		free(od->sorted);
+		free(od);
+		return -1;
+	}
+
+	j = 0;
+	for (i = 0; i < nr_entries; i++) {
+		u64 adjusted;
+		GElf_Phdr phdr;
+
+		if (!gelf_getsym(syms, i, &sym))
+			continue;
+		if (!ondemand_sym_ok(elf, secstrs, &sym, shdr.sh_link,
+				     ehdr.e_machine))
+			continue;
+
+		adjusted = sym.st_value;
+
+		if ((ehdr.e_machine == EM_ARM) &&
+		    (GELF_ST_TYPE(sym.st_info) == STT_FUNC) &&
+		    (adjusted & 1))
+			--adjusted;
+
+		if (elf_read_program_header(runtime_ss->elf, adjusted,
+					    &phdr) == 0) {
+			adjusted -= phdr.p_vaddr - phdr.p_offset;
+		} else {
+			Elf_Scn *sym_sec = elf_getscn(elf, sym.st_shndx);
+			GElf_Shdr sym_shdr;
+
+			if (sym_sec && gelf_getshdr(sym_sec, &sym_shdr)) {
+				/*
+				 * A NOBITS section in a debuginfo file has an
+				 * invalid sh_offset; use the runtime section.
+				 */
+				if (sym_shdr.sh_type == SHT_NOBITS) {
+					sym_sec = elf_getscn(runtime_ss->elf,
+							     sym.st_shndx);
+					if (!sym_sec ||
+					    !gelf_getshdr(sym_sec, &sym_shdr))
+						continue;
+				}
+				adjusted -= sym_shdr.sh_addr - sym_shdr.sh_offset;
+			}
+		}
+
+		od->sorted[j].start = adjusted;
+		od->sorted[j].end = sym.st_size;
+		name_offsets[j] = sym.st_name;
+		od->sorted[j].name_off = j;
+		od->sorted[j].binding = GELF_ST_BIND(sym.st_info);
+		od->sorted[j].type = GELF_ST_TYPE(sym.st_info);
+		j++;
+	}
+	count = j;
+	if (!count) {
+		symbol__unaccount_bytes(index_bytes);
+		free(name_offsets);
+		free(od->sorted);
+		free(od);
+		return 0;
+	}
+
+	qsort(od->sorted, count, sizeof(*od->sorted), cmp_sym_idx);
+	for (i = 0; i < count; i++)
+		od->sorted[i].name_off = name_offsets[od->sorted[i].name_off];
+	free(name_offsets);
+
+	for (i = 0; i < count; i++) {
+		u64 size = od->sorted[i].end;
+
+		if (size > 0)
+			od->sorted[i].end = od->sorted[i].start + size;
+		else if (i + 1 < count)
+			od->sorted[i].end = od->sorted[i + 1].start;
+		else
+			od->sorted[i].end = roundup(od->sorted[i].start, 4096) + 4096;
+	}
+
+	if (!symbol_conf.allow_aliases)
+		count = dso_ondemand__dedup_aliases(dso, od, elf, shdr.sh_link, count);
+
+	if (!symbol_conf.allow_aliases) {
+		for (i = 0; i + 1 < count; i++) {
+			if (od->sorted[i].end > od->sorted[i + 1].start)
+				od->sorted[i].end = od->sorted[i + 1].start;
+		}
+	}
+
+	od->data_dso = dso__new(syms_ss->name);
+	if (!od->data_dso ||
+	    dso__data_set_path(od->data_dso, syms_ss->name) < 0)
+		goto out_decline_source;
+	dso__set_binary_type(od->data_dso, DSO_BINARY_TYPE__SYSTEM_PATH_DSO);
+	dso__set_nsinfo(od->data_dso, nsinfo__get(dso__nsinfo(dso)));
+
+	if (od->sorted[0].name_off >= strshdr.sh_size)
+		goto out_decline_source;
+	if (check_add_overflow(strtab_offset,
+			       (u64)od->sorted[0].name_off, &probe_off))
+		goto out_decline_source;
+	if (dso__data_read_offset(od->data_dso, NULL, probe_off, &probe, 1) != 1)
+		goto out_decline_source;
+
+	od->strtab_offset = strtab_offset;
+	od->strtab_size = strshdr.sh_size;
+	od->nr_sorted = count;
+
+	dso__set_ondemand(dso, od);
+
+	pr_debug("%s: on-demand index: %u symbols (%zu bytes, %zu bytes total) budget=%zu\n",
+		 dso__long_name(dso), count,
+		 od->nr_alloc * sizeof(*od->sorted), symbol__bytes_used(),
+		 reservation_peak);
+
+	return 1;
+
+out_decline_source:
+	if (od->data_dso) {
+		dso__data_close(od->data_dso);
+		dso__put(od->data_dso);
+	}
+	symbol__unaccount_bytes(od->nr_alloc * sizeof(*od->sorted));
+	free(od->sorted);
+	free(od);
+	return 0;
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
+static struct symbol *dso__materialize_symbol_ondemand(struct dso *dso, u32 pos,
+						       bool *budget_exceeded)
+	EXCLUSIVE_LOCKS_REQUIRED(dso__lock(dso))
+{
+	struct dso_ondemand *od = dso__ondemand(dso);
+	struct sym_idx *idx = &od->sorted[pos];
+	const char *name;
+	char namebuf[1024];
+	char *name_heap = NULL;
+	char *demangled;
+	struct symbol *s = NULL;
+
+	*budget_exceeded = false;
+
+	if (symbol_conf.max_symbol_bytes &&
+	    symbol__bytes_used() >= symbol_conf.max_symbol_bytes) {
+		symbol_budget_warning();
+		*budget_exceeded = true;
+		return NULL;
+	}
+
+	name = dso__read_ondemand_symbol_name(od->data_dso, od->strtab_offset,
+					      od->strtab_size, idx->name_off,
+					      namebuf, sizeof(namebuf),
+					      &name_heap, NULL);
+	if (!name)
+		return NULL;
+
+	demangled = dso__demangle_sym(dso, 0, name);
+	if (demangled)
+		name = demangled;
+
+	s = symbol__new_bounded(idx->start, idx->end - idx->start,
+				idx->binding, idx->type, name, budget_exceeded);
+	free(demangled);
+	free(name_heap);
+	if (!s) {
+		if (*budget_exceeded)
+			symbol_budget_warning();
+		return NULL;
+	}
+
+	if (idx->flags & SYM_IDX_FLAG_IFUNC_ALIAS)
+		symbol__set_ifunc_alias(s, true);
+	__symbols__insert(dso__symbols(dso), s);
+	idx->flags |= SYM_IDX_FLAG_MATERIALIZED;
+	return s;
+}
+
+static struct symbol *dso__lookup_symbol_ondemand(struct dso *dso, u32 pos)
+	EXCLUSIVE_LOCKS_REQUIRED(dso__lock(dso))
+{
+	bool budget_exceeded;
+
+	return dso__materialize_symbol_ondemand(dso, pos, &budget_exceeded);
+}
+
+void dso__materialize_symbols_ondemand(struct dso *dso)
+{
+	struct dso_ondemand *od = dso__ondemand(dso);
+	bool budget_exceeded;
+	u32 i;
+
+	if (!od)
+		return;
+	for (i = 0; i < od->nr_sorted; i++) {
+		if (od->sorted[i].flags & SYM_IDX_FLAG_MATERIALIZED)
+			continue;
+		if (!dso__materialize_symbol_ondemand(dso, i, &budget_exceeded) &&
+		    budget_exceeded)
+			break;
+	}
+	dso__free_ondemand(dso);
+}
+
+struct symbol *dso__find_symbol_ondemand(struct dso *dso, u64 addr)
+{
+	struct dso_ondemand *od = dso__ondemand(dso);
+	const struct sym_idx *idx;
+	u32 lo, hi, mid;
+
+	if (!od || !od->sorted || !od->data_dso)
+		return NULL;
+
+	if (!symbol_conf.allow_aliases) {
+		idx = bsearch(&addr, od->sorted, od->nr_sorted,
+			      sizeof(*od->sorted), cmp_addr_to_sym_idx);
+		return idx ? dso__lookup_symbol_ondemand(dso, idx - od->sorted) : NULL;
+	}
+
+	lo = 0;
+	hi = od->nr_sorted;
+	while (lo < hi) {
+		mid = (lo + hi) / 2;
+		if (addr < od->sorted[mid].start)
+			hi = mid;
+		else if (addr >= od->sorted[mid].end)
+			lo = mid + 1;
+		else
+			return dso__lookup_symbol_ondemand(dso, mid);
+	}
+	return NULL;
+}
+
+struct symbol *dso__find_symbol_ondemand_exact(struct dso *dso, u64 addr)
+{
+	struct dso_ondemand *od = dso__ondemand(dso);
+	u32 lo, mid;
+
+	if (!od || !od->sorted || !od->data_dso)
+		return NULL;
+
+	lo = sym_idx__lower_bound(od, addr);
+	if (lo >= od->nr_sorted || od->sorted[lo].start != addr)
+		return NULL;
+	for (mid = lo; mid < od->nr_sorted &&
+	     od->sorted[mid].start == addr; mid++) {
+		if (od->sorted[mid].type == STT_GNU_IFUNC ||
+		    od->sorted[mid].flags & SYM_IDX_FLAG_IFUNC_ALIAS)
+			return dso__lookup_symbol_ondemand(dso, mid);
+	}
+	return dso__lookup_symbol_ondemand(dso, lo);
+}
+
 static int
 dso__load_sym_internal(struct dso *dso, struct map *map, struct symsrc *syms_ss,
 		       struct symsrc *runtime_ss, int kmodule, int dynsym)
@@ -1656,6 +2290,34 @@ dso__load_sym_internal(struct dso *dso, struct map *map, struct symsrc *syms_ss,
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
+		if (!dynsym && syms_ss->symtab)
+			oret = dso__build_ondemand_index(dso, syms_ss,
+							 runtime_ss, 0);
+		else if (dynsym && !dso__ondemand(dso) && syms_ss->dynsym)
+			oret = dso__build_ondemand_index(dso, syms_ss,
+							 runtime_ss, 1);
+
+		/*
+		 * On hard error, propagate it.  If an index was built, the
+		 * DSO resolves on demand; skip the eager loop below.  If the
+		 * build declined (oret == 0, no index -- e.g. no usable
+		 * symbols, or no reopenable data source), continue with the eager
+		 * loop so the DSO still gets symbols.
+		 */
+		if (oret < 0)
+			return oret;
+		if (dso__ondemand(dso))
+			return 1;
+	}
+
 	curr_dso = dso__get(dso);
 	elf_symtab__for_each_symbol(syms, nr_syms, idx, sym) {
 		struct symbol *f;
diff --git a/tools/perf/util/symbol-minimal.c b/tools/perf/util/symbol-minimal.c
index 0a71d1463952..b932ced5f878 100644
--- a/tools/perf/util/symbol-minimal.c
+++ b/tools/perf/util/symbol-minimal.c
@@ -373,6 +373,22 @@ void symbol__elf_init(void)
 {
 }
 
+struct symbol *dso__find_symbol_ondemand(struct dso *dso __maybe_unused,
+					 u64 addr __maybe_unused)
+{
+	return NULL;
+}
+
+struct symbol *dso__find_symbol_ondemand_exact(struct dso *dso __maybe_unused,
+					       u64 addr __maybe_unused)
+{
+	return NULL;
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
index cf92a7604a67..d234f7c29cb2 100644
--- a/tools/perf/util/symbol.c
+++ b/tools/perf/util/symbol.c
@@ -773,6 +773,7 @@ void dso__sort_by_name(struct dso *dso)
 	if (!dso__sorted_by_name(dso)) {
 		size_t len = 0;
 
+		dso__materialize_symbols_ondemand(dso);
 		dso__set_symbol_names(dso, symbols__sort_by_name(dso__symbols(dso), &len));
 		if (dso__symbol_names(dso)) {
 			dso__set_symbol_names_len(dso, len);
@@ -2019,11 +2020,19 @@ int dso__load(struct dso *dso, struct map *map)
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
index 30cbc53cbcd0..763d158bc611 100644
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

