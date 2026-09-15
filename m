From: Alireza Haghdoost <haghdoost@uber.com>
Date: Tue, 15 Sep 2026 11:42:45 -0700
Subject: [PATCH 3/4] perf script: Add --lazy-load-symbols for lazy symbol
 loading
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260915-perf-symbol-memory-send-v1-3-1d3360e21f07@uber.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=30218; i=haghdoost@uber.com;
 h=from:subject:message-id; bh=jFw7sO3kz+mVtLHYUiqXROYZ+zzT3PvEnh/L5HxR6dw=;
 b=owEBiQJ2/ZANAwAIAVNlBDxl2ALYAcsmYgBqqZHO7Z0FCJQBWilgLzF4Fay7UG35dYku1GVXZ
 Fm2O1BqQU+JAk8EAAEIADkWIQS5+sFL3gX/8PrA0S1TZQQ8ZdgC2AUCaqmRzhsUgAAAAAAEAA5t
 YW51MiwyLjUrMS4xMiwwLDMACgkQU2UEPGXYAtjZTg//TyRXHPQ6ge6PPUyRtqCKRzt2ITBfOHw
 CtDBTsNWDq1ukdvZgzR0BnfAaNiiTizi6+mL6G8fNQz1d6IwKeT8OfoXOsxNoJqEOJWCf7c5Mll
 fhWDHI8jBuYHoB8a61noZQyOvnlwSFu/H+lpr7IBSZEpL/0NyAJiMCVDsfdtEG9ujcXROob2G/6
 esMIR/Fg7cs9iaVPPqU4Ery+vpNW6Xzv3yHllXJqJSCqUHWVo+DgGz4Cg5jc3l1ah/uoo89y5Jn
 dBlaPJDDAynAZpq6MvT/WhaFgCxR11B8zpE5tQPnBZSv8bfD9h5A68bTblx3cZNBGD1ndSizaTm
 ATtRuwjYovKuABqKsZ5pofC7vVAm5ZlvIqertBEEWzaQtyPsgggWODSI8xQuuYn9ydxPgscQu3j
 1W5Z9UviKZiD5zx12jj4ME8Hwg+XxXJm6f4pWTmH8goakCUaw3ki1tSWM8J2PqvyafoWe1HWg6Q
 4XQElAFWPf95Xcwjhxs1CqIRZzBRbhE1WJJNUuccXZxHJAlM1u1NlxPiLtaR8mf4RsKUa2TV0Z2
 atqxQhHXQu8NtsVFWKC4acHV/5rz/H6MJGvNy/o1w0i+a06boUG2VsTBbzaNs2cfpl+P3F8zx/u
 wEiljYyTDIiUPxeueYENqBumB/y1vGJTCEzgFtBkAt6JQR3BuQxY=
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
symbol names with pread(), and caches resolved symbols in the existing
rb-tree. Lazy lookup retains one CLOEXEC file descriptor per indexed DSO.
If the descriptor cannot be retained, perf discards the index and eagerly
loads that DSO instead.

On the same fixture, peak RssAnon drops from 265 MiB to 39 MiB and wall
time from 3.1 seconds to 1.85 seconds. Memory optimizations usually cost
time; this one does not because lazy loading skips many unnecessary
calloc() calls and demangling operations. Output was byte-identical on
the tested x86-64 workloads and an aarch64 capture.

Lazy loading is most effective when samples reference only a small
fraction of the available symbols, such as profiles spanning many large
DSOs. It still builds an index proportional to the total symbol count.
Eager loading remains available for dense symbol coverage or cases
requiring its broader ELF and architecture support.

This does not claim full parity with the eager loader. Lazy loading
supports the common userspace ELF symtab/dynsym case, with these known
differences:

  - .gnu_debugdata merging and PPC64 .opd are not handled.
  - SHT_NOBITS re-reading, IFUNC PLT naming, and exact-tie alias ordering
    are unreachable or output-equivalent on x86-64.

Signed-off-by: Alireza Haghdoost <haghdoost@uber.com>
Assisted-by: Kimi:K3
---
 tools/perf/builtin-script.c      |   4 +-
 tools/perf/util/dso.c            |  10 +
 tools/perf/util/dso.h            |  29 ++
 tools/perf/util/map.c            |   9 +-
 tools/perf/util/symbol-elf.c     | 560 ++++++++++++++++++++++++++++++++++++++-
 tools/perf/util/symbol-minimal.c |  11 +
 tools/perf/util/symbol.c         |  58 ++--
 tools/perf/util/symbol.h         |   4 +
 tools/perf/util/symbol_conf.h    |   1 +
 9 files changed, 664 insertions(+), 22 deletions(-)

diff --git a/tools/perf/builtin-script.c b/tools/perf/builtin-script.c
index 50fa6ca6455a..81e56378d3d2 100644
--- a/tools/perf/builtin-script.c
+++ b/tools/perf/builtin-script.c
@@ -4037,7 +4037,7 @@ static int parse_callret_trace(const struct option *opt __maybe_unused,
 }
 
 static int parse_max_symbol_bytes(const struct option *opt,
-				  const char *str, int unset)
+				const char *str, int unset)
 {
 	unsigned long *max_bytes = (unsigned long *)opt->value;
 	static struct parse_tag size_tags[] = {
@@ -4166,6 +4166,8 @@ int cmd_script(int argc, const char **argv)
 	OPT_CALLBACK(0, "max-symbol-bytes", &symbol_conf.max_symbol_bytes,
 		     "size", "Limit bytes for ELF struct symbol (e.g. 128M; 0=unlimited)",
 		     parse_max_symbol_bytes),
+	OPT_BOOLEAN(0, "lazy-load-symbols", &symbol_conf.lazy_load_symbols,
+		    "Resolve symbols lazily instead of loading full symtabs"),
 	OPT_BOOLEAN(0, "reltime", &reltime, "Show time stamps relative to start"),
 	OPT_BOOLEAN(0, "deltatime", &deltatime, "Show time stamps relative to previous event"),
 	OPT_BOOLEAN('I', "show-info", &show_full_info,
diff --git a/tools/perf/util/dso.c b/tools/perf/util/dso.c
index 42bfe30a3b51..196cd27e79e2 100644
--- a/tools/perf/util/dso.c
+++ b/tools/perf/util/dso.c
@@ -1755,6 +1755,16 @@ void dso__delete(struct dso *dso)
 
 	dso__data_close(dso);
 	auxtrace_cache__free(RC_CHK_ACCESS(dso)->auxtrace_cache);
+	if (RC_CHK_ACCESS(dso)->ondemand) {
+		struct dso_ondemand *od = RC_CHK_ACCESS(dso)->ondemand;
+
+		free(od->sorted);
+		symbol__unaccount_bytes(od->nr_alloc * sizeof(struct sym_idx));
+		if (od->fd >= 0)
+			close(od->fd);
+		free(od);
+		RC_CHK_ACCESS(dso)->ondemand = NULL;
+	}
 	dso_cache__free(dso);
 	dso__free_a2l(dso);
 	dso__free_libdw(dso);
diff --git a/tools/perf/util/dso.h b/tools/perf/util/dso.h
index 55c4aaa53c38..50c4d64e5081 100644
--- a/tools/perf/util/dso.h
+++ b/tools/perf/util/dso.h
@@ -282,6 +282,23 @@ struct dso_bpf_prog {
 	struct perf_env	*env;
 };
 
+struct sym_idx {
+	u64	start;	/* adjusted st_value (same space as sym->start) */
+	u64	end;	/* start + st_size, or next start if st_size==0 */
+	u32	name_off; /* symbol's st_name: offset into the strtab */
+	u8	binding;
+	u8	type;
+};
+
+struct dso_ondemand {
+	int		 fd;		/* kept open for pread */
+	u64		 strtab_offset;	/* file offset of strtab section */
+	u64		 strtab_size;
+	struct sym_idx	*sorted;
+	u32		 nr_sorted;	/* deduped count */
+	u32		 nr_alloc;	/* allocated count, for accounting */
+};
+
 struct auxtrace_cache;
 
 DECLARE_RC_STRUCT(dso) {
@@ -308,6 +325,7 @@ DECLARE_RC_STRUCT(dso) {
 	char		 *symsrc_filename;
 	struct nsinfo	*nsinfo;
 	struct auxtrace_cache *auxtrace_cache;
+	struct dso_ondemand *ondemand;
 	union { /* Tool specific area */
 		void	 *priv;
 		u64	 db_id;
@@ -448,6 +466,16 @@ static inline void dso__set_auxtrace_cache(struct dso *dso, struct auxtrace_cach
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
@@ -823,6 +851,7 @@ int dso__read_binary_type_filename(const struct dso *dso, enum dso_binary_type t
 				   const char *root_dir, char *filename, size_t size);
 bool is_kernel_module(const char *pathname, int cpumode);
 bool dso__needs_decompress(struct dso *dso);
+struct symbol *dso__find_symbol_ondemand(struct dso *dso, u64 addr);
 int dso__decompress_kmodule_fd(struct dso *dso, const char *name);
 int dso__decompress_kmodule_path(struct dso *dso, const char *name,
 				 char *pathname, size_t len);
diff --git a/tools/perf/util/map.c b/tools/perf/util/map.c
index 41cdddc987ee..68ffa01c9f9e 100644
--- a/tools/perf/util/map.c
+++ b/tools/perf/util/map.c
@@ -382,10 +382,17 @@ int map__load(struct map *map)
 
 struct symbol *map__find_symbol(struct map *map, u64 addr)
 {
+	struct dso *dso;
+	struct symbol *sym;
+
 	if (map__load(map) < 0)
 		return NULL;
 
-	return dso__find_symbol(map__dso(map), addr);
+	dso = map__dso(map);
+	sym = dso__find_symbol(dso, addr);
+	if (!sym && dso__ondemand(dso))
+		sym = dso__find_symbol_ondemand(dso, addr);
+	return sym;
 }
 
 struct symbol *map__find_symbol_by_name_idx(struct map *map, const char *name, size_t *idx)
diff --git a/tools/perf/util/symbol-elf.c b/tools/perf/util/symbol-elf.c
index 914e42d21f70..e4d77e46e883 100644
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
@@ -600,6 +601,32 @@ static int dso__synthesize_plt_got_symbols(struct dso *dso, Elf *elf,
  * And always look at the original dso, not at debuginfo packages, that
  * have the PLT data stripped out (shdr_rel_plt.sh_type == SHT_NOBITS).
  */
+static void dso__clip_ondemand_symbols_at(struct dso *dso, u64 addr)
+{
+	struct dso_ondemand *od = dso__ondemand(dso);
+	struct sym_idx *sym;
+	u32 lo = 0, hi, mid;
+
+	if (!od)
+		return;
+
+	hi = od->nr_sorted;
+	while (lo < hi) {
+		mid = (lo + hi) / 2;
+		if (od->sorted[mid].start < addr)
+			lo = mid + 1;
+		else
+			hi = mid;
+	}
+
+	if (!lo)
+		return;
+
+	sym = &od->sorted[lo - 1];
+	if (sym->end > addr)
+		sym->end = addr;
+}
+
 int dso__synthesize_plt_symbols(struct dso *dso, struct symsrc *ss)
 {
 	uint32_t idx;
@@ -623,6 +650,8 @@ int dso__synthesize_plt_symbols(struct dso *dso, struct symsrc *ss)
 	if (!elf_section_by_name(elf, &ehdr, &shdr_plt, ".plt", NULL))
 		return 0;
 
+	dso__clip_ondemand_symbols_at(dso, shdr_plt.sh_offset);
+
 	/*
 	 * A symbol from a previous section (e.g. .init) can have been expanded
 	 * by symbols__fixup_end() to overlap .plt. Truncate it before adding
@@ -1515,6 +1544,504 @@ static int dso__process_kernel_symbol(struct dso *dso, struct map *map,
 	return 0;
 }
 
+/*
+ * On-demand symbol loading: build a sorted in-memory index of
+ * (adjusted_start, end, name strtab offset, binding, type) from the ELF
+ * symtab, then resolve individual addresses via binary search.  Symbol
+ * names are read from the file's string table with pread() at lookup
+ * time, so the steady-state footprint is only the index itself, not
+ * the full set of struct symbol allocations.
+ */
+
+static void symbol_budget_warning(void)
+{
+	pr_warning_once("perf: symbol memory budget exceeded (%lu bytes), "
+			"remaining symbols will be [unknown]\n",
+			symbol_conf.max_symbol_bytes);
+}
+
+static int cmp_sym_idx(const void *a, const void *b)
+{
+	const struct sym_idx *sa = a, *sb = b;
+
+	if (sa->start != sb->start)
+		return sa->start < sb->start ? -1 : 1;
+	/*
+	 * qsort is not stable, so make the order total: tiebreak on
+	 * name_off (the symbol's st_name, a strtab offset) so that an
+	 * exact start tie keeps a deterministic first entry regardless of
+	 * how qsort permutes equal-start aliases.
+	 *
+	 * Note: st_name is a strtab offset, not a symtab index, and the two
+	 * are not monotonic -- so on an exact heuristic tie this is
+	 * deterministic but NOT necessarily eager's symtab order (eager
+	 * falls to arch__choose_best_symbol -> SYMBOL_A, i.e. insertion
+	 * order).  See "Known divergences" in the commit message.
+	 */
+	if (sa->name_off != sb->name_off)
+		return sa->name_off < sb->name_off ? -1 : 1;
+	return 0;
+}
+
+/*
+ * Return true if a symbol should be included in the on-demand index.
+ * This mirrors the filter used by the eager dso__load_sym_internal()
+ * loop: functions, objects and IFUNCs, plus STT_NOTYPE "labels" in
+ * text/data sections, all restricted to SHF_ALLOC sections.
+ */
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
+	size_t i;
+	u32 count = 0, j;
+	u64 nr_entries, strtab_offset;
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
+	/*
+	 * File offset of the string table linked from the symbol table.
+	 * Symbol names are pread() from the file at lookup time, so we
+	 * only need the offset and size here, not the strings themselves.
+	 */
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
+	/* Count symbols that pass the filter (same filter as fill below) */
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
+	if (count > SIZE_MAX / sizeof(*od->sorted))
+		return -EOVERFLOW;
+
+	/*
+	 * Account the index against the symbol memory budget: at 24
+	 * bytes/symbol it is the dominant on-demand cost and must count
+	 * toward --max-symbol-bytes just like struct symbol allocations do.
+	 */
+	if (symbol_conf.max_symbol_bytes &&
+	    symbol__bytes_used() + count * sizeof(struct sym_idx) >
+	    symbol_conf.max_symbol_bytes) {
+		symbol_budget_warning();
+		return 0; /* fall back to the eager loader's per-symbol budget */
+	}
+
+	od = zalloc(sizeof(*od));
+	if (!od)
+		return -1;
+
+	od->sorted = malloc(count * sizeof(*od->sorted));
+	if (!od->sorted) {
+		free(od);
+		return -1;
+	}
+	od->nr_alloc = count;	/* allocated; the deduped count may shrink */
+
+	/* Fill the index with adjusted addresses */
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
+		/* ARM Thumb bit fix (same as eager path, FUNC only) */
+		if ((ehdr.e_machine == EM_ARM) &&
+		    (GELF_ST_TYPE(sym.st_info) == STT_FUNC) &&
+		    (adjusted & 1))
+			--adjusted;
+
+		/*
+		 * Program header adjustment, identical to the eager loop:
+		 * read the PT_LOAD containing the symbol from the runtime
+		 * ELF (the debug-info file may have zeroed p_offset), and
+		 * fall back to the section-header bias when no program
+		 * header matches -- exactly what the eager path does when
+		 * elf_read_program_header fails.
+		 */
+		if (elf_read_program_header(runtime_ss->elf, adjusted,
+					    &phdr) == 0) {
+			adjusted -= phdr.p_vaddr - phdr.p_offset;
+		} else {
+			Elf_Scn *sym_sec = elf_getscn(elf, sym.st_shndx);
+			GElf_Shdr sym_shdr;
+
+			if (sym_sec && gelf_getshdr(sym_sec, &sym_shdr))
+				adjusted -= sym_shdr.sh_addr - sym_shdr.sh_offset;
+		}
+
+		od->sorted[j].start = adjusted;
+		od->sorted[j].end = sym.st_size; /* st_size for now, converted later */
+		od->sorted[j].name_off = sym.st_name; /* strtab-relative */
+		od->sorted[j].binding = GELF_ST_BIND(sym.st_info);
+		od->sorted[j].type = GELF_ST_TYPE(sym.st_info);
+		j++;
+	}
+
+	/* Sort by adjusted start address */
+	qsort(od->sorted, count, sizeof(*od->sorted), cmp_sym_idx);
+
+	/* Alias dedup: keep only the best symbol for each start address */
+	if (!symbol_conf.allow_aliases) {
+		u32 out = 0;
+
+		for (i = 0; i < count; i++) {
+			u32 best = i;
+			const char *na = NULL, *nb;
+			char *da = NULL, *db;
+
+			/* name_off is the strtab index (st_name) */
+			na = elf_strptr(elf, shdr.sh_link,
+					od->sorted[best].name_off);
+			if (na) {
+				da = dso__demangle_sym(dso, 0, na);
+				if (da)
+					na = da;
+			}
+
+			/* Find the best among all entries with this start */
+			for (j = i + 1; j < count &&
+			     od->sorted[j].start == od->sorted[i].start; j++) {
+				nb = elf_strptr(elf, shdr.sh_link,
+						od->sorted[j].name_off);
+				if (!na || !nb)
+					continue;
+
+				/* Demangle for comparison, matching eager path */
+				db = dso__demangle_sym(dso, 0, nb);
+				if (db)
+					nb = db;
+
+				/* od->sorted[].end holds st_size at this point */
+				if (choose_best_symbol_raw(
+					    od->sorted[best].end,
+					    od->sorted[best].type,
+					    od->sorted[best].binding, na,
+					    od->sorted[j].end,
+					    od->sorted[j].type,
+					    od->sorted[j].binding, nb) == SYMBOL_B) {
+					best = j;
+					free(da);
+					da = db;
+					na = nb;
+				} else {
+					free(db);
+				}
+			}
+
+			free(da);
+			od->sorted[out++] = od->sorted[best];
+			i = j - 1; /* skip past all aliases of this start */
+		}
+
+		if (out < count) {
+			struct sym_idx *shrunk;
+
+			shrunk = realloc(od->sorted, out * sizeof(*od->sorted));
+			if (shrunk) {
+				od->sorted = shrunk;
+				od->nr_alloc = out;
+			}
+		}
+		count = out;
+	}
+
+	/* Convert st_size to end addresses */
+	for (i = 0; i < count; i++) {
+		u64 size = od->sorted[i].end; /* was st_size */
+
+		if (size > 0)
+			od->sorted[i].end = od->sorted[i].start + size;
+		else if (i + 1 < count)
+			od->sorted[i].end = od->sorted[i + 1].start;
+		else
+			/* Match symbols__fixup_end's last-symbol formula. */
+			od->sorted[i].end = roundup(od->sorted[i].start, 4096) + 4096;
+	}
+
+	/*
+	 * Keep a private fd open for pread() of symbol names.  Dup with
+	 * O_CLOEXEC so children don't inherit it, and so that
+	 * symsrc__destroy() can close the original regardless of whether
+	 * it is a real file or a temporary debugdata extraction.
+	 *
+	 * If the dup fails (e.g. fd exhaustion), decline by returning 0
+	 * without setting the index: the caller falls back to the eager
+	 * loader so the DSO still gets symbols rather than going symbol-less.
+	 */
+	od->fd = fcntl(syms_ss->fd, F_DUPFD_CLOEXEC, 0);
+	if (od->fd < 0) {
+		free(od->sorted);
+		free(od);
+		return 0;
+	}
+	od->strtab_offset = strtab_offset;
+	od->strtab_size = strshdr.sh_size;
+	od->nr_sorted = count;
+
+	symbol__account_bytes(od->nr_alloc * sizeof(*od->sorted));
+
+	dso__set_ondemand(dso, od);
+
+	pr_debug("%s: on-demand index: %u symbols\n",
+		 dso__long_name(dso), count);
+
+	return 1;
+}
+
+/*
+ * Read a NUL-terminated symbol name from the file's string table at
+ * file offset @off.  The fast path uses a stack buffer; if the NUL is
+ * not found within it (names can exceed 1 KiB for template-heavy C++
+ * mangled names), grow a heap buffer geometrically from 4 KiB, doubling
+ * until the terminator is found or the strtab is exhausted.  This keeps
+ * a single long name cheap even when it sits near the start of a large
+ * (tens of MB) strtab, while bounding a corrupt/missing terminator by
+ * the remaining strtab size.
+ *
+ * Returns a pointer to the name (either @buf or a heap allocation) and
+ * sets *@to_free to the buffer that must be free()d (NULL for @buf).
+ * Returns NULL on read error or if no NUL terminator exists within the
+ * strtab bounds.
+ */
+static const char *ondemand_read_name(int fd, u64 strtab_offset,
+				      u64 strtab_size, u64 name_off,
+				      char *buf, size_t buflen,
+				      char **to_free)
+{
+	ssize_t n;
+	u64 remain;
+	u64 file_off;
+	size_t cap;
+
+	*to_free = NULL;
+
+	/* name_off is strtab-relative (the symbol's st_name). */
+	if (name_off >= strtab_size)
+		return NULL;
+	file_off = strtab_offset + name_off;
+	remain = strtab_size - name_off;
+
+	/*
+	 * Fast path: stack buffer, expect the name to fit.  Cap at the
+	 * remaining strtab so a missing terminator can't read past the
+	 * section into adjacent file data.
+	 */
+	n = pread(fd, buf, min((u64)(buflen - 1), remain), file_off);
+	if (n <= 0)
+		return NULL;
+	buf[n] = '\0';
+	if (memchr(buf, '\0', n))
+		return buf;
+
+	/*
+	 * Slow path: the name is longer than buflen.  Grow a heap buffer
+	 * geometrically, doubling until the terminator appears, so a long
+	 * name costs O(name length), not O(remaining strtab size).
+	 */
+	cap = 4096;
+	for (;;) {
+		char *tmp;
+		size_t want = cap;
+
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
+		n = pread(fd, *to_free, want, file_off);
+		if (n <= 0) {
+			free(*to_free);
+			*to_free = NULL;
+			return NULL;
+		}
+		(*to_free)[n] = '\0';
+
+		if (memchr(*to_free, '\0', n))
+			return *to_free;
+
+		/*
+		 * Read the whole remaining strtab (or hit EOF) with no
+		 * terminator: corrupt file, bail instead of re-reading.
+		 */
+		if (want >= remain || (u64)n >= remain)
+			break;
+
+		/* Avoid size_t overflow on absurdly large strtabs. */
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
+struct symbol *dso__find_symbol_ondemand(struct dso *dso, u64 addr)
+{
+	struct dso_ondemand *od = dso__ondemand(dso);
+	u32 lo, hi, mid;
+	const char *name;
+	char namebuf[1024];
+	char *name_heap = NULL;
+	char *demangled;
+	struct symbol *s = NULL;
+
+	if (!od || !od->sorted || od->fd < 0)
+		return NULL;
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
+			goto found;
+	}
+
+	/* Not found */
+	return NULL;
+
+found:
+	/*
+	 * Check the budget before doing any name I/O or demangling, so an
+	 * over-budget DSO stops paying pread+demangle on every later miss.
+	 */
+	if (symbol_conf.max_symbol_bytes &&
+	    symbol__bytes_used() >= symbol_conf.max_symbol_bytes) {
+		symbol_budget_warning();
+		return NULL;
+	}
+
+	name = ondemand_read_name(od->fd, od->strtab_offset, od->strtab_size,
+				  od->sorted[mid].name_off,
+				  namebuf, sizeof(namebuf), &name_heap);
+	if (!name)
+		return NULL;
+
+	demangled = dso__demangle_sym(dso, 0, name);
+	if (demangled)
+		name = demangled;
+
+	s = symbol__new(od->sorted[mid].start,
+			od->sorted[mid].end - od->sorted[mid].start,
+			od->sorted[mid].binding,
+			od->sorted[mid].type, name);
+	free(demangled);
+	free(name_heap);
+	if (s)
+		__symbols__insert(dso__symbols(dso), s);
+	return s;
+}
+
 static int
 dso__load_sym_internal(struct dso *dso, struct map *map, struct symsrc *syms_ss,
 		       struct symsrc *runtime_ss, int kmodule, int dynsym)
@@ -1626,6 +2153,35 @@ dso__load_sym_internal(struct dso *dso, struct map *map, struct symsrc *syms_ss,
 	if (kmodule && adjust_kernel_syms)
 		max_text_sh_offset = max_text_section(runtime_ss->elf, &runtime_ss->ehdr);
 
+	/*
+	 * On-demand mode: build a sorted index and resolve symbols
+	 * per-address instead of loading the entire symtab.
+	 * Only for userspace ELF DSOs.
+	 */
+	if (symbol_conf.lazy_load_symbols && !dso__kernel(dso) && !kmodule) {
+		int oret = 0;
+
+		/* Use symtab if available, fall back to dynsym (e.g. vdso) */
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
+		 * symbols, or fd duplication failed), continue with the eager
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
@@ -1636,9 +2192,7 @@ dso__load_sym_internal(struct dso *dso, struct map *map, struct symsrc *syms_ss,
 		bool used_opd = false;
 		if (symbol_conf.max_symbol_bytes &&
 		    symbol__bytes_used() >= symbol_conf.max_symbol_bytes) {
-			pr_warning_once("perf: symbol memory budget exceeded (%lu bytes), "
-					"remaining symbols will be [unknown]\n",
-					symbol_conf.max_symbol_bytes);
+			symbol_budget_warning();
 			break;
 		}
 
diff --git a/tools/perf/util/symbol-minimal.c b/tools/perf/util/symbol-minimal.c
index 0a71d1463952..1a7088389d62 100644
--- a/tools/perf/util/symbol-minimal.c
+++ b/tools/perf/util/symbol-minimal.c
@@ -373,6 +373,17 @@ void symbol__elf_init(void)
 {
 }
 
+/*
+ * Without libelf there is no on-demand index to resolve against; the
+ * DSO can never be in on-demand mode, so this is only reached when a
+ * caller ignores the NULL from dso__ondemand().
+ */
+struct symbol *dso__find_symbol_ondemand(struct dso *dso __maybe_unused,
+					 u64 addr __maybe_unused)
+{
+	return NULL;
+}
+
 bool filename__has_section(const char *filename __maybe_unused, const char *sec __maybe_unused)
 {
 	return false;
diff --git a/tools/perf/util/symbol.c b/tools/perf/util/symbol.c
index 62a4f91c2f5d..7e90f3c11832 100644
--- a/tools/perf/util/symbol.c
+++ b/tools/perf/util/symbol.c
@@ -155,60 +155,76 @@ int __weak arch__choose_best_symbol(struct symbol *syma,
 	return SYMBOL_A;
 }
 
-static int choose_best_symbol(struct symbol *syma, struct symbol *symb)
+int choose_best_symbol_raw(u64 a_size, u8 a_type, u8 a_binding,
+			   const char *a_name,
+			   u64 b_size, u8 b_type, u8 b_binding,
+			   const char *b_name)
 {
 	s64 a;
 	s64 b;
 	size_t na, nb;
 
 	/* Prefer a symbol with non zero length */
-	a = syma->end - syma->start;
-	b = symb->end - symb->start;
-	if ((b == 0) && (a > 0))
+	if ((b_size == 0) && (a_size > 0))
 		return SYMBOL_A;
-	else if ((a == 0) && (b > 0))
+	else if ((a_size == 0) && (b_size > 0))
 		return SYMBOL_B;
 
-	if (symbol__type(syma) != symbol__type(symb)) {
-		if (symbol__type(syma) == STT_NOTYPE)
+	if (a_type != b_type) {
+		if (a_type == STT_NOTYPE)
 			return SYMBOL_B;
-		if (symbol__type(symb) == STT_NOTYPE)
+		if (b_type == STT_NOTYPE)
 			return SYMBOL_A;
 	}
 
 	/* Prefer a non weak symbol over a weak one */
-	a = symbol__binding(syma) == STB_WEAK;
-	b = symbol__binding(symb) == STB_WEAK;
+	a = a_binding == STB_WEAK;
+	b = b_binding == STB_WEAK;
 	if (b && !a)
 		return SYMBOL_A;
 	if (a && !b)
 		return SYMBOL_B;
 
 	/* Prefer a global symbol over a non global one */
-	a = symbol__binding(syma) == STB_GLOBAL;
-	b = symbol__binding(symb) == STB_GLOBAL;
+	a = a_binding == STB_GLOBAL;
+	b = b_binding == STB_GLOBAL;
 	if (a && !b)
 		return SYMBOL_A;
 	if (b && !a)
 		return SYMBOL_B;
 
 	/* Prefer a symbol with less underscores */
-	a = prefix_underscores_count(syma->name);
-	b = prefix_underscores_count(symb->name);
+	a = prefix_underscores_count(a_name);
+	b = prefix_underscores_count(b_name);
 	if (b > a)
 		return SYMBOL_A;
 	else if (a > b)
 		return SYMBOL_B;
 
 	/* Choose the symbol with the longest name */
-	na = strlen(syma->name);
-	nb = strlen(symb->name);
+	na = strlen(a_name);
+	nb = strlen(b_name);
 	if (na > nb)
 		return SYMBOL_A;
 	else if (na < nb)
 		return SYMBOL_B;
 
-	return arch__choose_best_symbol(syma, symb);
+	/* All heuristics tied: let the caller decide (arch hook, etc.) */
+	return -1;
+}
+
+static int choose_best_symbol(struct symbol *syma, struct symbol *symb)
+{
+	int ret;
+
+	ret = choose_best_symbol_raw(syma->end - syma->start,
+				     symbol__type(syma), symbol__binding(syma), syma->name,
+				     symb->end - symb->start,
+				     symbol__type(symb), symbol__binding(symb), symb->name);
+	if (ret < 0)
+		return arch__choose_best_symbol(syma, symb);
+
+	return ret;
 }
 
 void symbols__fixup_duplicate(struct rb_root_cached *symbols)
@@ -1940,11 +1956,19 @@ int dso__load(struct dso *dso, struct map *map)
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
diff --git a/tools/perf/util/symbol.h b/tools/perf/util/symbol.h
index 0d5d3792aac1..db1b662988e3 100644
--- a/tools/perf/util/symbol.h
+++ b/tools/perf/util/symbol.h
@@ -231,6 +231,10 @@ struct symbol *symbol__new(u64 start, u64 len, u8 binding, u8 type, const char *
 size_t symbol__bytes_used(void);
 void symbol__account_bytes(size_t bytes);
 void symbol__unaccount_bytes(size_t bytes);
+int choose_best_symbol_raw(u64 a_size, u8 a_type, u8 a_binding,
+			   const char *a_name,
+			   u64 b_size, u8 b_type, u8 b_binding,
+			   const char *b_name);
 size_t __symbol__fprintf_symname_offs(const struct symbol *sym,
 				      const struct addr_location *al,
 				      bool unknown_as_addr,
diff --git a/tools/perf/util/symbol_conf.h b/tools/perf/util/symbol_conf.h
index 6a16c5badd5e..0f8d044eba20 100644
--- a/tools/perf/util/symbol_conf.h
+++ b/tools/perf/util/symbol_conf.h
@@ -74,6 +74,7 @@ struct symbol_conf {
 			no_buildid_mmap2,
 			guest_code,
 			lazy_load_kernel_maps,
+			lazy_load_symbols,
 			keep_exited_threads,
 			annotate_data_member,
 			annotate_data_sample,

-- 
Git-155)

