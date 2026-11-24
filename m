From: Alireza Haghdoost <haghdoost@uber.com>
Date: Tue, 24 Nov 2026 11:28:27 -0800
Subject: [PATCH v9 4/7] perf script: Add --lazy-load-symbols to load symbol
 names lazily
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261124-perf-symbol-memory-send-v9-4-56f298185eae@uber.com>
References: <20261124-perf-symbol-memory-send-v9-0-56f298185eae@uber.com>
In-Reply-To: <20261124-perf-symbol-memory-send-v9-0-56f298185eae@uber.com>
To: Peter Zijlstra <peterz@infradead.org>, Ingo Molnar <mingo@redhat.com>, 
 Arnaldo Carvalho de Melo <acme@kernel.org>, 
 Namhyung Kim <namhyung@kernel.org>, Mark Rutland <mark.rutland@arm.com>, 
 Alexander Shishkin <alexander.shishkin@linux.intel.com>, 
 Jiri Olsa <jolsa@kernel.org>, Ian Rogers <irogers@google.com>, 
 Adrian Hunter <adrian.hunter@intel.com>, 
 James Clark <james.clark@linaro.org>
Cc: linux-perf-users@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Alireza Haghdoost <haghdoost@uber.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=12189; i=haghdoost@uber.com;
 h=from:subject:message-id; bh=Fn6dWh25fM8XeseMoNRZqQkumfr1Wuap1WkEd0py2V8=;
 b=owEBiQJ2/ZANAwAIAVNlBDxl2ALYAcsmYgBrBeWFG00fSOUmfHinzrEEQT1V8j6j73nP5Wq8Y
 9lUVGfepceJAk8EAAEIADkWIQS5+sFL3gX/8PrA0S1TZQQ8ZdgC2AUCawXlhRsUgAAAAAAEAA5t
 YW51MiwyLjUrMS4xMiwwLDMACgkQU2UEPGXYAthbww//fZz54ktL7XIgOyDjtmcHc7dVyloYfrP
 ulS+ODG/EJDGVBkZzAjJd7xZqaPqypEokQMpTDm9QBFf9JTZGBtv822Zb3yhA1fJB0UoWKTCXeh
 LUhAEy1ggNNbnfiGcOTSFvOtPi2aHqEW4KqUMAx1omMKNhRDgULP3WOTA6pcvSPZCTqTyhYXl6B
 57v6743c439Ht086XGO10KE9dYdhiDYFCChEPvSiF6hEfhSsHaP8vZNRvzA0TTkVTxbTCvvlGKM
 wXkA5Xa5boB1P+uAU/UZz2n/VK5Jzr6Azo3Dq80eIqDNYsqocfbmHfKQwenbtjxayKeiIDRKbJJ
 kZUii6eXSSooGQc4huiyuydJo5afelNE6CXNDTCuKCnyIlA/ARBFQ6zaYqXANkmAZLdZUowSPRu
 J7Afvyjrf4333IdGOLe3XaIUpF2kXSm5Q2mQDIvWJNQyPa8r4K15Bcx1TNHey3e+L1K+MS+sCMp
 2pGJuhRGnT0URIScUrvEjVJDa7XsL9KELI51L/Tznq1rTlEeD/FyTmwz3tVUxtvFWF4AdG/Qdbg
 hc0NKfH+0wBUg5cfhjLzw02hj4daT9tc6N1Z6SjWyvLjCm88ImaIg1z5/EvRWovTx1v2GoJpbQd
 R07mx+j8M1Khp3mBJazNtU+b/Qk3a58T/25k1egwArELvmns2DrE=
X-Developer-Key: i=haghdoost@uber.com; a=openpgp;
 fpr=B9FAC14BDE05FFF0FAC0D12D5365043C65D802D8
X-Endpoint-Received: by B4 Relay for haghdoost@uber.com/default with auth_id=764
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch adds a --lazy-load-symbols option to perf script. With it,
the ELF loader creates userspace .symtab and .dynsym symbols with lazy
names, and perf reads a name only when a lookup returns that symbol.
Eager loading stays the default.

perf script loads the whole ELF symbol table of every DSO that appears
in a sample and keeps every symbol, with its demangled name, until exit.
Most of those symbols are never sampled, and their names take most of
the memory. On a large profile this is the main memory cost of perf
script, and in a memory-limited cgroup it gets perf OOM-killed.

On a 45,073-sample callchain profile of a large C++ service (about 1M
symbols), lazy loading cuts max RSS from 315 MiB to 164 MiB, with
identical output. It saves little run time, 1.97 seconds against 2.26,
because one of the binaries exports most of its symbols, and duplicate
selection reads the names of each .dynsym copy and of the .symtab
symbol that it copies.

The loader still creates every symbol, so end fixup, duplicate
selection, PLT synthesis and IFUNC marking do not change. It uses lazy
names only if the string table is stored as is in the symbol table file,
since names are read from it with pread().

A few names are still read at load time: aliases that duplicate
selection can tell apart only by name, such as the .dynsym copies of
.symtab symbols, and IFUNC symbols, whose names PLT synthesis uses.

The names are read from the symbol table file while perf script runs,
at the offsets it had at load time. So the output is the same as with
eager loading as long as the file does not change in the meantime,
which is rare.

The kernel, modules, PPC64 .opd and .gnu_debugdata still load names
eagerly. So does a binary of a process in another mount namespace
unless it is read from the build-id cache, since names are read in
perf's own namespace: not every perf top thread can switch namespaces.
So does a file that dso__load() found through its chroot fallback,
since perf may not find that file again by the name it builds.

Signed-off-by: Alireza Haghdoost <haghdoost@uber.com>
---
 tools/perf/Documentation/perf-script.txt |   9 +++
 tools/perf/builtin-script.c              |   2 +
 tools/perf/util/symbol-elf.c             | 129 ++++++++++++++++++++++++++++---
 tools/perf/util/symbol.c                 |   3 +
 tools/perf/util/symsrc.h                 |   2 +
 5 files changed, 134 insertions(+), 11 deletions(-)

diff --git a/tools/perf/Documentation/perf-script.txt b/tools/perf/Documentation/perf-script.txt
index f0228e784ced..844167017521 100644
--- a/tools/perf/Documentation/perf-script.txt
+++ b/tools/perf/Documentation/perf-script.txt
@@ -343,6 +343,15 @@ include::itrace.txt[]
 
         Default: 127
 
+--lazy-load-symbols::
+	Read and demangle userspace ELF symbol names only when perf needs
+	them. By default, perf reads every symbol name from each binary
+	referenced by a sample. This option reduces memory use when samples
+	reference only a small fraction of a large binary's symbols. The
+	names are read from the binaries while perf script runs, so the
+	binaries must not change in the meantime. If a binary cannot be
+	opened when a name is needed, perf shows that symbol as unknown.
+
 --ns::
 	Use 9 decimal places when displaying time (i.e. show the nanoseconds)
 
diff --git a/tools/perf/builtin-script.c b/tools/perf/builtin-script.c
index b6691ebb1b4e..88aaf9cfd132 100644
--- a/tools/perf/builtin-script.c
+++ b/tools/perf/builtin-script.c
@@ -4287,6 +4287,8 @@ int cmd_script(int argc, const char **argv)
 		     "Set the maximum stack depth when parsing the callchain, "
 		     "anything beyond the specified depth will be ignored. "
 		     "Default: kernel.perf_event_max_stack or " __stringify(PERF_MAX_STACK_DEPTH)),
+	OPT_BOOLEAN(0, "lazy-load-symbols", &symbol_conf.lazy_load_symbols,
+		    "Read symbol names only when they are needed"),
 	OPT_BOOLEAN(0, "reltime", &reltime, "Show time stamps relative to start"),
 	OPT_BOOLEAN(0, "deltatime", &deltatime, "Show time stamps relative to previous event"),
 	OPT_BOOLEAN('I', "show-info", &show_full_info,
diff --git a/tools/perf/util/symbol-elf.c b/tools/perf/util/symbol-elf.c
index 4b9deea65b09..e623fb04cfba 100644
--- a/tools/perf/util/symbol-elf.c
+++ b/tools/perf/util/symbol-elf.c
@@ -12,6 +12,7 @@
 #include "libbfd.h"
 #include "map.h"
 #include "maps.h"
+#include "namespaces.h"
 #include "symbol.h"
 #include "symsrc.h"
 #include "machine.h"
@@ -1396,6 +1397,7 @@ int symsrc__init(struct symsrc *ss, struct dso *dso, const char *name,
 	ss->fd     = fd;
 	ss->ehdr   = ehdr;
 	ss->type   = type;
+	ss->chroot = false;
 
 	return 0;
 
@@ -1716,6 +1718,70 @@ void dso__load_symbol_names(struct dso *dso, struct symbol **syms, size_t nr)
 	}
 }
 
+/*
+ * symbols__fixup_duplicate() compares the names of symbols at the same
+ * address only when their size, type and binding tie. Load those names.
+ */
+static int dso__load_alias_names(struct dso *dso, int fd)
+{
+	struct symbols *symbols = dso__symbols(dso);
+	unsigned int i, end, a, b;
+	int err = 0;
+
+	symbols__sort_read_lock(symbols);
+	for (i = 0; i < symbols->cnt && !err; i = end) {
+		for (end = i + 1; end < symbols->cnt &&
+		     symbols->symbols[end]->start == symbols->symbols[i]->start; end++)
+			;
+		for (a = i; a < end && !err; a++) {
+			for (b = a + 1; b < end && !err; b++) {
+				struct symbol *pair[2] = {
+					symbols->symbols[a], symbols->symbols[b]
+				};
+
+				if (symbol__choice_needs_names(pair[0], pair[1]))
+					err = read_symbol_names(dso, fd, pair, 2);
+			}
+		}
+	}
+	up_read(&symbols->lock);
+	return err;
+}
+
+/* PLT synthesis names IRELATIVE slots after IFUNC symbols. Load those names. */
+static int dso__load_ifunc_names(struct dso *dso, int fd)
+{
+	struct symbols *symbols = dso__symbols(dso);
+	int err = 0;
+
+	symbols__sort_read_lock(symbols);
+	for (unsigned int i = 0; i < symbols->cnt && !err; i++) {
+		struct symbol *pos = symbols->symbols[i];
+
+		if (symbol__type(pos) == STT_GNU_IFUNC || symbol__ifunc_alias(pos))
+			err = read_symbol_names(dso, fd, &pos, 1);
+	}
+	up_read(&symbols->lock);
+	return err;
+}
+
+/*
+ * dso__load_symbol_names() builds the file name again and opens it in perf's
+ * mount namespace. At load time, perf opened the same file there if it is in
+ * the build-id cache or if the DSO needs no namespace switch, unless perf
+ * found it through the chroot fallback.
+ */
+static bool dso__can_reopen_symtab(struct dso *dso, struct symsrc *ss)
+{
+	struct nsinfo *nsi = dso__nsinfo(dso);
+
+	if (ss->chroot)
+		return false;
+	return (ss->type == DSO_BINARY_TYPE__BUILD_ID_CACHE ||
+		ss->type == DSO_BINARY_TYPE__BUILD_ID_CACHE_DEBUGINFO ||
+		!nsi || !nsinfo__need_setns(nsi));
+}
+
 static int
 dso__load_sym_internal(struct dso *dso, struct map *map, struct symsrc *syms_ss,
 		       struct symsrc *runtime_ss, int kmodule, int dynsym)
@@ -1733,11 +1799,23 @@ dso__load_sym_internal(struct dso *dso, struct map *map, struct symsrc *syms_ss,
 	GElf_Sym sym;
 	Elf_Scn *sec, *sec_strndx;
 	Elf *elf;
-	int nr = 0;
+	int nr = 0, nr_lazy = 0;
 	bool remap_kernel = false, adjust_kernel_syms = false;
 	u64 max_text_sh_offset = 0;
 	struct elf_phdr_cache phdr_cache = {};
 	struct elf_sec_cache_entry sec_cache[ELF_SEC_CACHE_SIZE];
+	/*
+	 * Names are read later from the file of dso__symtab_type(). The
+	 * .gnu_debugdata symbol table is a temporary file.
+	 */
+	bool lazy_allowed = (symbol_conf.lazy_load_symbols && !dso__kernel(dso) &&
+			     dso__lazy_names(dso) != DSO_LAZY_NAMES__EAGER &&
+			     syms_ss->type == dso__symtab_type(dso) &&
+			     syms_ss->type != DSO_BINARY_TYPE__GNU_DEBUGDATA &&
+			     dso__can_reopen_symtab(dso, syms_ss) &&
+			     !runtime_ss->opdsec);
+	bool lazy_names = false;
+	GElf_Shdr strshdr;
 
 	if (kmap && !kmaps)
 		return -1;
@@ -1773,6 +1851,11 @@ dso__load_sym_internal(struct dso *dso, struct map *map, struct symsrc *syms_ss,
 	if (symstrs == NULL)
 		goto out_elf_end;
 
+	/* Names are read with pread(), so the string table must be stored as is. */
+	if (lazy_allowed && gelf_getshdr(sec, &strshdr) &&
+	    strshdr.sh_type == SHT_STRTAB && !(strshdr.sh_flags & SHF_COMPRESSED))
+		lazy_names = true;
+
 	sec_strndx = elf_getscn(runtime_ss->elf, runtime_ss->ehdr.e_shstrndx);
 	if (sec_strndx == NULL)
 		goto out_elf_end;
@@ -2011,16 +2094,24 @@ dso__load_sym_internal(struct dso *dso, struct map *map, struct symsrc *syms_ss,
 			}
 		}
 
-		if (!elf_name)
-			elf_name = elf_sym__name(&sym, symstrs);
-		demangled = dso__demangle_sym(dso, kmodule, elf_name);
-		if (demangled != NULL)
-			elf_name = demangled;
-
-		f = symbol__new(sym.st_value, sym.st_size,
-				GELF_ST_BIND(sym.st_info),
-				GELF_ST_TYPE(sym.st_info), elf_name);
-		free(demangled);
+		if (lazy_names && sym.st_name < strshdr.sh_size) {
+			f = symbol__new_lazy(sym.st_value, sym.st_size,
+					     GELF_ST_BIND(sym.st_info),
+					     GELF_ST_TYPE(sym.st_info),
+					     strshdr.sh_offset + sym.st_name);
+			nr_lazy++;
+		} else {
+			if (!elf_name)
+				elf_name = elf_sym__name(&sym, symstrs);
+			demangled = dso__demangle_sym(dso, kmodule, elf_name);
+			if (demangled != NULL)
+				elf_name = demangled;
+
+			f = symbol__new(sym.st_value, sym.st_size,
+					GELF_ST_BIND(sym.st_info),
+					GELF_ST_TYPE(sym.st_info), elf_name);
+			free(demangled);
+		}
 		if (!f)
 			goto out_elf_end;
 
@@ -2032,10 +2123,19 @@ dso__load_sym_internal(struct dso *dso, struct map *map, struct symsrc *syms_ss,
 	}
 	dso__put(curr_dso);
 	elf_phdr_cache__exit(&phdr_cache);
+
+	if (nr_lazy) {
+		dso__set_lazy_names(dso, DSO_LAZY_NAMES__PENDING);
+		pr_debug2("%s: %d %s symbols with lazy names\n", dso__long_name(dso),
+			  nr_lazy, dynsym ? ".dynsym" : ".symtab");
+	}
 	return nr;
 out_elf_end:
 	dso__put(curr_dso);
 	elf_phdr_cache__exit(&phdr_cache);
+	/* The symbols inserted before the error stay in the DSO. */
+	if (nr_lazy)
+		dso__set_lazy_names(dso, DSO_LAZY_NAMES__PENDING);
 	return -1;
 }
 
@@ -2102,9 +2202,16 @@ int dso__load_sym(struct dso *dso, struct map *map, struct symsrc *syms_ss,
 	if (nr > 0) {
 		struct kmap *kmap = dso__kernel(dso) ? map__kmap(map) : NULL;
 		struct maps *kmaps = kmap ? map__kmaps(map) : NULL;
+		/* Lazy names are only in syms_ss. */
+		bool lazy = (dso__lazy_names(dso) == DSO_LAZY_NAMES__PENDING);
 
 		symbols__fixup_end(dso__symbols(dso), false);
+		if (lazy && !symbol_conf.allow_aliases &&
+		    dso__load_alias_names(dso, syms_ss->fd))
+			return -1;
 		symbols__fixup_duplicate(dso__symbols(dso));
+		if (lazy && dso__load_ifunc_names(dso, syms_ss->fd))
+			return -1;
 		if (kmap) {
 			/*
 			 * We need to fixup this here too because we create new
diff --git a/tools/perf/util/symbol.c b/tools/perf/util/symbol.c
index e1310f950d3d..d6a841dadcad 100644
--- a/tools/perf/util/symbol.c
+++ b/tools/perf/util/symbol.c
@@ -2394,6 +2394,7 @@ int dso__load(struct dso *dso, struct map *map)
 		bool next_slot = false;
 		bool is_reg;
 		bool nsexit;
+		bool chroot = false;
 		int bfdrc = -1;
 		int sirc = -1;
 
@@ -2419,6 +2420,7 @@ int dso__load(struct dso *dso, struct map *map)
 				is_reg = is_regular_file(new_name);
 				strlcpy(name, new_name, PATH_MAX);
 				free(new_name);
+				chroot = true;
 			}
 		}
 
@@ -2440,6 +2442,7 @@ int dso__load(struct dso *dso, struct map *map)
 
 		if (!is_reg || sirc < 0)
 			continue;
+		ss->chroot = chroot;
 
 		if (!syms_ss && symsrc__has_symtab(ss)) {
 			syms_ss = ss;
diff --git a/tools/perf/util/symsrc.h b/tools/perf/util/symsrc.h
index edf82028c9e6..94f51dfaef64 100644
--- a/tools/perf/util/symsrc.h
+++ b/tools/perf/util/symsrc.h
@@ -16,6 +16,8 @@ struct symsrc {
 	char		     *name;
 	int		     fd;
 	enum dso_binary_type type;
+	/* Found through the chroot fallback of dso__load(). */
+	bool		     chroot;
 
 #ifdef HAVE_LIBELF_SUPPORT
 	Elf		     *elf;

-- 
Git-157)

