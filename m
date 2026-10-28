From: Alireza Haghdoost <haghdoost@uber.com>
Date: Wed, 28 Oct 2026 16:42:35 -0700
Subject: [PATCH v6 4/5] perf script: Add --lazy-load-symbols to load symbol
 names lazily
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261028-perf-symbol-memory-send-v6-4-7e90415f0101@uber.com>
References: <20261028-perf-symbol-memory-send-v6-0-7e90415f0101@uber.com>
In-Reply-To: <20261028-perf-symbol-memory-send-v6-0-7e90415f0101@uber.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=27282; i=haghdoost@uber.com;
 h=from:subject:message-id; bh=ChWB+zRFtnEwjvsLD0K+p5Aj5cdlnecBRzeMfZU2ZZk=;
 b=owEBiQJ2/ZANAwAIAVNlBDxl2ALYAcsmYgBq4oh3b2GNPFlQs1Bg+Sj9Q/d/NTCWdCeCEvRZA
 2e038dN6peJAk8EAAEIADkWIQS5+sFL3gX/8PrA0S1TZQQ8ZdgC2AUCauKIdxsUgAAAAAAEAA5t
 YW51MiwyLjUrMS4xMiwwLDMACgkQU2UEPGXYAtjWAw//en6aN32PvFp32x66vMzJL9ufJK8B+QP
 Vz3EnmJNwvdWqfE9OI/vTRvX4YDBLVPb9eOVMn77G8o3VBwfXumMwCPL4r7Q7IZSyvKUwyBIgCG
 Hy1SicUrrE/2VJuq8mx8svu4znwpjrM/1y7DJ7XLHNdtL6Vs0xRQDcGV+dDN1vlZjrVW5R8nfvM
 QKNKvFgvNBzXuwlzgs5METvWRZScd51orKQ3DBHf0JSeD+pH7CrkoExv8FJyZbHYlCfJrf9lKE/
 +AQpL2gD+bfK8KfyhRstxhUX+7hWOTWAbLFCxgarI4HBbYy+GoceAvk2u5oQsXGOjFho+rfdnwr
 Z9vgvaRIHLmiC6NOU5BiVmG1jZ0kOBvL83QoUZ6hDODkmpoWXVyeLHJnbr2JKsGztEbA1InTeX4
 +gQeA3ekc283LzbtOBazAS/PCqTBNz99Wn2gYCAyv5mdPvhMXamoPsGJ8Z0btPh1eHoFDV6K9KB
 7EfKufKaFHsK5LKvyywlZTnzJdSapRVOBkhJYRvWgcoYHLciFv63olWfZem2Ol7WlZYbcOqAW3o
 6yQw3XZ8m/7lWRblj+aCznVViXoztuhLjGSTuODsiiDT6Gi2uESHL+JDvDPgHB7wUO9Wl9RMObG
 bysD9K5q9O81YIIHFjQDfw0hcsmqZphVRcO49bPWMU+KdKh/1s+s=
X-Developer-Key: i=haghdoost@uber.com; a=openpgp;
 fpr=B9FAC14BDE05FFF0FAC0D12D5365043C65D802D8
X-Endpoint-Received: by B4 Relay for haghdoost@uber.com/default with auth_id=764
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch adds the --lazy-load-symbols option to perf script. With this
option, perf reads the name of a userspace ELF symbol only when a lookup
returns the symbol. Eager loading remains the default.

perf script loads the ELF symbol table of every DSO that appears in a
sample and keeps each symbol, with its demangled name, until exit. Most
of those symbols are never sampled, and their names take most of the
memory. On a large profile this makes symbol loading the main memory
cost of perf script, and in a memory-constrained cgroup an OOM kill.

With the option, the loader still creates every symbol, so end fixup,
duplicate selection, PLT synthesis and IFUNC marking work as before. But
it keeps the file offset of each name instead of copying and demangling
the name.

The name pointer and the offset share a union in struct symbol, and
SYMBOL_FLAG_LAZY_NAME says which one it holds. The dso__find_symbol*()
functions, dso__first_symbol() and dso__last_symbol() load the name of
the symbol they return, and code that walks the symbols of a DSO gets
them with dso__named_symbols(), which loads every name. So does
dso__sort_by_name() before it builds the name-sorted array. A symbol
whose name cannot be read is named "[unknown]" instead of being deleted,
since address lookups search the symbol tree without the DSO lock. Address
lookups return NULL for it, so perf script prints it as an address
without a symbol.

During loading, perf reads only the names that it needs:

- the names of aliases that duplicate selection can tell apart only by
  name,
- the names of IFUNC symbols, which PLT synthesis uses to name the
  IRELATIVE slots.

The loader also skips a .dynsym entry that copies a lazy .symtab symbol.
Duplicate selection would drop the entry, but only after it reads both
names, and most exported symbols are such copies.

Other names are read with pread() from the file that dso__get_filename()
returns for dso__symtab_type(). The file is open only while perf reads
the names, so no descriptor stays open per DSO.

The kernel, modules, PPC64 .opd and .gnu_debugdata, whose symbol table
is a temporary file, still load names eagerly.

On a perf script run over a 45,073-sample callchain profile of a large
C++ service, where eager loading creates about 1M symbols, lazy loading
reduces max RSS from 341 MiB to 154 MiB and time from 3.2 to 1.5
seconds, with identical output.

Signed-off-by: Alireza Haghdoost <haghdoost@uber.com>
---
 tools/perf/Documentation/perf-script.txt |   7 +
 tools/perf/builtin-script.c              |   2 +
 tools/perf/ui/browsers/map.c             |   2 +-
 tools/perf/util/dso.c                    |   2 +-
 tools/perf/util/dso.h                    |   3 +-
 tools/perf/util/symbol-elf.c             | 251 +++++++++++++++++++++++++++++--
 tools/perf/util/symbol-minimal.c         |   6 +
 tools/perf/util/symbol.c                 | 113 +++++++++++++-
 tools/perf/util/symbol.h                 |  29 +++-
 tools/perf/util/symbol_conf.h            |   1 +
 10 files changed, 393 insertions(+), 23 deletions(-)

diff --git a/tools/perf/Documentation/perf-script.txt b/tools/perf/Documentation/perf-script.txt
index f0228e784ced..57b3533e6c2a 100644
--- a/tools/perf/Documentation/perf-script.txt
+++ b/tools/perf/Documentation/perf-script.txt
@@ -343,6 +343,13 @@ include::itrace.txt[]
 
         Default: 127
 
+--lazy-load-symbols::
+	Read and demangle userspace ELF symbol names only when perf needs
+	them. By default, perf reads every symbol name from each binary
+	referenced by a sample. This option reduces memory use and usually
+	improves performance when samples reference only a small fraction
+	of a large binary's symbols.
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
diff --git a/tools/perf/ui/browsers/map.c b/tools/perf/ui/browsers/map.c
index 075a575cdc5d..ef8f75699a07 100644
--- a/tools/perf/ui/browsers/map.c
+++ b/tools/perf/ui/browsers/map.c
@@ -108,7 +108,7 @@ int map__browse(struct map *map)
 {
 	struct map_browser mb = {
 		.b = {
-			.entries = dso__symbols(map__dso(map)),
+			.entries = dso__named_symbols(map__dso(map)),
 			.refresh = ui_browser__rb_tree_refresh,
 			.seek	 = ui_browser__rb_tree_seek,
 			.write	 = map_browser__write,
diff --git a/tools/perf/util/dso.c b/tools/perf/util/dso.c
index ce98613868e7..f41abf442476 100644
--- a/tools/perf/util/dso.c
+++ b/tools/perf/util/dso.c
@@ -2013,7 +2013,7 @@ size_t dso__fprintf(struct dso *dso, FILE *fp)
 	ret += fprintf(fp, "%sloaded, ", dso__loaded(dso) ? "" : "NOT ");
 	ret += dso__fprintf_buildid(dso, fp);
 	ret += fprintf(fp, ")\n");
-	for (nd = rb_first_cached(dso__symbols(dso)); nd; nd = rb_next(nd)) {
+	for (nd = rb_first_cached(dso__named_symbols(dso)); nd; nd = rb_next(nd)) {
 		struct symbol *pos = rb_entry(nd, struct symbol, rb_node);
 		ret += symbol__fprintf(pos, fp);
 	}
diff --git a/tools/perf/util/dso.h b/tools/perf/util/dso.h
index 3329f417810c..4a60c883cc37 100644
--- a/tools/perf/util/dso.h
+++ b/tools/perf/util/dso.h
@@ -369,7 +369,7 @@ int dso_id__cmp(const struct dso_id *a, const struct dso_id *b);
  * @n: the 'struct rb_node *' to use as a temporary storage
  */
 #define dso__for_each_symbol(dso, pos, n)	\
-	symbols__for_each_entry(dso__symbols(dso), pos, n)
+	symbols__for_each_entry(dso__named_symbols(dso), pos, n)
 
 static inline void *dso__a2l(const struct dso *dso)
 {
@@ -831,6 +831,7 @@ char *dso__filename_with_chroot(const struct dso *dso, const char *filename);
 bool dso__sorted_by_name(const struct dso *dso);
 void dso__set_sorted_by_name(struct dso *dso);
 void dso__sort_by_name(struct dso *dso);
+struct rb_root_cached *dso__named_symbols(struct dso *dso);
 
 int dso__swap_init(struct dso *dso, unsigned char eidata);
 
diff --git a/tools/perf/util/symbol-elf.c b/tools/perf/util/symbol-elf.c
index 1e2716c6af45..bce6c6aef20c 100644
--- a/tools/perf/util/symbol-elf.c
+++ b/tools/perf/util/symbol-elf.c
@@ -17,6 +17,7 @@
 #include "machine.h"
 #include "vdso.h"
 #include "debug.h"
+#include "namespaces.h"
 #include "util/copyfile.h"
 #include <linux/ctype.h>
 #include <linux/kernel.h>
@@ -348,7 +349,7 @@ static bool get_ifunc_name(Elf *elf, struct dso *dso, GElf_Ehdr *ehdr,
 
 	addr -= phdr.p_vaddr - phdr.p_offset;
 
-	sym = dso__find_symbol_nocache(dso, addr);
+	sym = symbols__find(dso__symbols(dso), addr);
 
 	/* Expecting the address to be an IFUNC or IFUNC alias */
 	if (!sym || sym->start != addr ||
@@ -629,7 +630,7 @@ int dso__synthesize_plt_symbols(struct dso *dso, struct symsrc *ss)
 	 * by symbols__fixup_end() to overlap .plt. Truncate it before adding
 	 * a symbol for .plt header.
 	 */
-	f = dso__find_symbol_nocache(dso, shdr_plt.sh_offset);
+	f = symbols__find(dso__symbols(dso), shdr_plt.sh_offset);
 	if (f && f->start < shdr_plt.sh_offset && f->end > shdr_plt.sh_offset)
 		f->end = shdr_plt.sh_offset;
 
@@ -1516,6 +1517,190 @@ static int dso__process_kernel_symbol(struct dso *dso, struct map *map,
 	return 0;
 }
 
+static DEFINE_MUTEX(lazy_names_lock);
+
+static char *read_name_at(int fd, u64 off)
+{
+	char small[256], *buf = NULL, *tmp;
+	size_t size = sizeof(small);
+	ssize_t n = pread(fd, small, size, off);
+
+	if (n > 0 && memchr(small, '\0', n))
+		return strdup(small);
+
+	while (n == (ssize_t)size) {
+		size *= 2;
+		tmp = realloc(buf, size);
+		if (!tmp)
+			break;
+		buf = tmp;
+		n = pread(fd, buf, size, off);
+		if (n > 0 && memchr(buf, '\0', n))
+			return buf;
+	}
+	free(buf);
+	return NULL;
+}
+
+static int load_symbol_names(struct dso *dso, int fd, struct symbol **syms, size_t nr)
+{
+	int err = 0;
+
+	for (size_t i = 0; i < nr; i++) {
+		char *name, *demangled;
+
+		if (!symbol__has_lazy_name(syms[i]))
+			continue;
+		name = read_name_at(fd, syms[i]->name_off);
+		if (!name) {
+			pr_debug("%s: cannot read the symbol name at %#" PRIx64 "\n",
+				 dso__long_name(dso), syms[i]->name_off);
+			err = -1;
+			continue;
+		}
+		demangled = dso__demangle_sym(dso, /*kmodule=*/0, name);
+		if (demangled) {
+			free(name);
+			name = demangled;
+		}
+		symbol__set_lazy_name(syms[i], name);
+	}
+	return err;
+}
+
+/*
+ * Load the lazy names in @syms, which are symbols of @dso, from the file of
+ * dso__symtab_type(). A name that cannot be read becomes "[unknown]".
+ */
+void dso__load_symbol_names(struct dso *dso, struct symbol **syms, size_t nr)
+{
+	enum dso_binary_type type = dso__symtab_type(dso);
+	/* As in dso__load(), the build-id cache is in perf's mount namespace. */
+	bool own_ns = type == DSO_BINARY_TYPE__BUILD_ID_CACHE ||
+		      type == DSO_BINARY_TYPE__BUILD_ID_CACHE_DEBUGINFO;
+	struct nscookie nsc;
+	bool decomp;
+	char *name;
+	int fd = -1;
+
+	mutex_lock(&lazy_names_lock);
+	if (!own_ns)
+		nsinfo__mountns_enter(dso__nsinfo(dso), &nsc);
+	name = dso__get_filename(dso, "", &decomp, type);
+	if (name)
+		fd = open(name, O_RDONLY | O_CLOEXEC);
+	if (!own_ns)
+		nsinfo__mountns_exit(&nsc);
+
+	if (fd >= 0) {
+		load_symbol_names(dso, fd, syms, nr);
+		close(fd);
+	} else {
+		pr_debug("%s: cannot open the symbol table file\n", dso__long_name(dso));
+	}
+	if (name)
+		dso__put_filename(dso, name, decomp);
+	for (size_t i = 0; i < nr; i++) {
+		if (symbol__has_lazy_name(syms[i]))
+			symbol__set_unknown_name(syms[i]);
+	}
+	mutex_unlock(&lazy_names_lock);
+}
+
+/*
+ * Return the lazy symbol in @symbols that the .dynsym entry @sym named
+ * @name copies, with the same address, size, binding, type and name.
+ * symbols__fixup_duplicate() would keep that symbol and drop the copy.
+ */
+static struct symbol *lazy_dynsym_copy(struct rb_root_cached *symbols, Elf *elf,
+				       const GElf_Sym *sym, const char *name)
+{
+	struct rb_node *nd = symbols->rb_root.rb_node, *prev;
+	const char *image;
+	struct symbol *s;
+	size_t size;
+
+	if (!sym->st_size)
+		return NULL;
+	image = elf_rawfile(elf, &size);
+	if (!image)
+		return NULL;
+
+	while (nd) {
+		s = rb_entry(nd, struct symbol, rb_node);
+		if (sym->st_value < s->start)
+			nd = nd->rb_left;
+		else if (sym->st_value > s->start)
+			nd = nd->rb_right;
+		else
+			break;
+	}
+	if (!nd)
+		return NULL;
+	while ((prev = rb_prev(nd)) &&
+	       rb_entry(prev, struct symbol, rb_node)->start == sym->st_value)
+		nd = prev;
+
+	for (; nd; nd = rb_next(nd)) {
+		s = rb_entry(nd, struct symbol, rb_node);
+		if (s->start != sym->st_value)
+			break;
+		if (s->end == s->start + sym->st_size &&
+		    symbol__binding(s) == GELF_ST_BIND(sym->st_info) &&
+		    symbol__type(s) == GELF_ST_TYPE(sym->st_info) &&
+		    symbol__has_lazy_name(s) && s->name_off < size &&
+		    !strncmp(image + s->name_off, name, size - s->name_off))
+			return s;
+	}
+	return NULL;
+}
+
+/*
+ * symbols__fixup_duplicate() compares the names of symbols at the same
+ * address only when their size, type and binding tie. Load those names.
+ */
+static int dso__load_alias_names(struct dso *dso, int fd)
+{
+	struct rb_node *nd = rb_first_cached(dso__symbols(dso));
+
+	while (nd) {
+		struct symbol *first = rb_entry(nd, struct symbol, rb_node);
+		struct rb_node *end = rb_next(nd), *a, *b;
+
+		while (end && rb_entry(end, struct symbol, rb_node)->start == first->start)
+			end = rb_next(end);
+
+		for (a = nd; a != end; a = rb_next(a)) {
+			for (b = rb_next(a); b != end; b = rb_next(b)) {
+				struct symbol *pair[2] = {
+					rb_entry(a, struct symbol, rb_node),
+					rb_entry(b, struct symbol, rb_node),
+				};
+
+				if (symbol__choice_needs_names(pair[0], pair[1]) &&
+				    load_symbol_names(dso, fd, pair, 2))
+					return -1;
+			}
+		}
+		nd = end;
+	}
+	return 0;
+}
+
+/* PLT synthesis names IRELATIVE slots after IFUNC symbols. Load those names. */
+static int dso__load_ifunc_names(struct dso *dso, int fd)
+{
+	struct symbol *pos;
+	struct rb_node *nd;
+
+	symbols__for_each_entry(dso__symbols(dso), pos, nd) {
+		if ((symbol__type(pos) == STT_GNU_IFUNC || symbol__ifunc_alias(pos)) &&
+		    load_symbol_names(dso, fd, &pos, 1))
+			return -1;
+	}
+	return 0;
+}
+
 static int
 dso__load_sym_internal(struct dso *dso, struct map *map, struct symsrc *syms_ss,
 		       struct symsrc *runtime_ss, int kmodule, int dynsym)
@@ -1533,9 +1718,19 @@ dso__load_sym_internal(struct dso *dso, struct map *map, struct symsrc *syms_ss,
 	GElf_Sym sym;
 	Elf_Scn *sec, *sec_strndx;
 	Elf *elf;
-	int nr = 0;
+	int nr = 0, nr_lazy = 0;
 	bool remap_kernel = false, adjust_kernel_syms = false;
 	u64 max_text_sh_offset = 0;
+	/*
+	 * Names are read later from the file of dso__symtab_type(). The
+	 * .gnu_debugdata symbol table is a temporary file.
+	 */
+	bool lazy_allowed = symbol_conf.lazy_load_symbols && !dso__kernel(dso) &&
+			  !kmodule && syms_ss->type == dso__symtab_type(dso) &&
+			  syms_ss->type != DSO_BINARY_TYPE__GNU_DEBUGDATA &&
+			  !runtime_ss->opdsec;
+	bool lazy_names = false;
+	GElf_Shdr strshdr;
 
 	if (kmap && !kmaps)
 		return -1;
@@ -1571,6 +1766,11 @@ dso__load_sym_internal(struct dso *dso, struct map *map, struct symsrc *syms_ss,
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
@@ -1772,14 +1972,36 @@ dso__load_sym_internal(struct dso *dso, struct map *map, struct symsrc *syms_ss,
 			}
 		}
 
-		demangled = dso__demangle_sym(dso, kmodule, elf_name);
-		if (demangled != NULL)
-			elf_name = demangled;
+		/*
+		 * Most .dynsym entries are copies of .symtab symbols, which
+		 * duplicate selection would drop anyway. Skip them here, so
+		 * that perf does not read both names just to choose one.
+		 */
+		if (lazy_names && dynsym && !symbol_conf.allow_aliases) {
+			f = lazy_dynsym_copy(dso__symbols(curr_dso), elf, &sym, elf_name);
+			if (f) {
+				if (GELF_ST_TYPE(sym.st_info) == STT_GNU_IFUNC)
+					symbol__set_ifunc_alias(f, true);
+				continue;
+			}
+		}
 
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
 
@@ -1790,12 +2012,21 @@ dso__load_sym_internal(struct dso *dso, struct map *map, struct symsrc *syms_ss,
 	}
 	dso__put(curr_dso);
 
+	if (lazy_names)
+		pr_debug("%s: %d %s symbols with lazy names\n", dso__long_name(dso),
+			 nr_lazy, dynsym ? ".dynsym" : ".symtab");
+
 	/*
 	 * For misannotated, zeroed, ASM function sizes.
 	 */
 	if (nr > 0) {
 		symbols__fixup_end(dso__symbols(dso), false);
+		if (lazy_allowed && !symbol_conf.allow_aliases &&
+		    dso__load_alias_names(dso, syms_ss->fd))
+			return -1;
 		symbols__fixup_duplicate(dso__symbols(dso));
+		if (lazy_allowed && dso__load_ifunc_names(dso, syms_ss->fd))
+			return -1;
 		if (kmap) {
 			/*
 			 * We need to fixup this here too because we create new
diff --git a/tools/perf/util/symbol-minimal.c b/tools/perf/util/symbol-minimal.c
index 0a71d1463952..fa87c2d9de2a 100644
--- a/tools/perf/util/symbol-minimal.c
+++ b/tools/perf/util/symbol-minimal.c
@@ -330,6 +330,12 @@ enum dso_type dso__type_fd(int fd)
 	return DSO__TYPE_32BIT;
 }
 
+void dso__load_symbol_names(struct dso *dso __maybe_unused,
+			    struct symbol **syms __maybe_unused,
+			    size_t nr __maybe_unused)
+{
+}
+
 int dso__load_sym(struct dso *dso, struct map *map __maybe_unused,
 		  struct symsrc *ss,
 		  struct symsrc *runtime_ss __maybe_unused,
diff --git a/tools/perf/util/symbol.c b/tools/perf/util/symbol.c
index 02c077d7e2a6..4b5cde4d13be 100644
--- a/tools/perf/util/symbol.c
+++ b/tools/perf/util/symbol.c
@@ -338,9 +338,9 @@ void symbols__fixup_end(struct rb_root_cached *symbols, bool is_kallsyms)
 		curr->end = roundup(curr->start, 4096) + 4096;
 }
 
-struct symbol *symbol__new(u64 start, u64 len, u8 binding, u8 type, const char *name)
+static struct symbol *symbol__alloc(u64 start, u64 len, u8 binding, u8 type,
+				    u16 flags, size_t namelen)
 {
-	size_t namelen = strlen(name) + 1;
 	struct symbol *sym = calloc(1, (symbol_conf.priv_size +
 					sizeof(*sym) + namelen));
 	if (sym == NULL)
@@ -357,7 +357,18 @@ struct symbol *symbol__new(u64 start, u64 len, u8 binding, u8 type, const char *
 	sym->start   = start;
 	sym->end     = len ? start + len : start;
 	atomic_init(&sym->flags, (type << SYMBOL_FLAG_TYPE_SHIFT) |
-				 (binding << SYMBOL_FLAG_BINDING_SHIFT));
+				 (binding << SYMBOL_FLAG_BINDING_SHIFT) | flags);
+	return sym;
+}
+
+struct symbol *symbol__new(u64 start, u64 len, u8 binding, u8 type, const char *name)
+{
+	size_t namelen = strlen(name) + 1;
+	struct symbol *sym = symbol__alloc(start, len, binding, type, 0, namelen);
+
+	if (sym == NULL)
+		return NULL;
+
 	sym->namelen = namelen - 1;
 
 	pr_debug4("%s: %s %#" PRIx64 "-%#" PRIx64 "\n",
@@ -368,8 +379,38 @@ struct symbol *symbol__new(u64 start, u64 len, u8 binding, u8 type, const char *
 	return sym;
 }
 
+struct symbol *symbol__new_lazy(u64 start, u64 len, u8 binding, u8 type, u64 name_off)
+{
+	struct symbol *sym = symbol__alloc(start, len, binding, type,
+					   SYMBOL_FLAG_LAZY_NAME, 0);
+
+	if (sym)
+		sym->name_off = name_off;
+	return sym;
+}
+
+/* @sym takes ownership of @name. */
+void symbol__set_lazy_name(struct symbol *sym, char *name)
+{
+	sym->namelen = strlen(name);
+	sym->name = name;
+	atomic_fetch_and(&sym->flags, ~SYMBOL_FLAG_LAZY_NAME);
+}
+
+/* The name of the symbols whose lazy name cannot be read. */
+static const char unknown_name[] = "[unknown]";
+
+void symbol__set_unknown_name(struct symbol *sym)
+{
+	symbol__set_lazy_name(sym, (char *)unknown_name);
+}
+
 void symbol__delete(struct symbol *sym)
 {
+	/* A loaded lazy name is allocated apart from the symbol. */
+	if (!symbol__has_lazy_name(sym) && sym->name != (char *)(sym + 1) &&
+	    sym->name != unknown_name)
+		free(sym->name);
 	if (symbol_conf.priv_size) {
 		if (symbol_conf.init_annotation) {
 			struct annotation *notes = symbol__annotation(sym);
@@ -463,7 +504,7 @@ void symbols__insert(struct rb_root_cached *symbols, struct symbol *sym)
 	__symbols__insert(symbols, sym);
 }
 
-static struct symbol *symbols__find(struct rb_root_cached *symbols, u64 ip)
+struct symbol *symbols__find(struct rb_root_cached *symbols, u64 ip)
 {
 	struct rb_node *n;
 
@@ -638,6 +679,16 @@ void dso__delete_symbol(struct dso *dso, struct symbol *sym)
 	dso__reset_find_symbol_cache(dso);
 }
 
+/* Return @sym with its name loaded, or NULL if the name cannot be read. */
+static struct symbol *dso__named_symbol(struct dso *dso, struct symbol *sym)
+{
+	if (sym && symbol__has_lazy_name(sym))
+		dso__load_symbol_names(dso, &sym, 1);
+	if (sym && sym->name == unknown_name)
+		return NULL;
+	return sym;
+}
+
 struct symbol *dso__find_symbol(struct dso *dso, u64 addr)
 {
 	if (dso__last_find_result_addr(dso) != addr || dso__last_find_result_symbol(dso) == NULL) {
@@ -645,22 +696,22 @@ struct symbol *dso__find_symbol(struct dso *dso, u64 addr)
 		dso__set_last_find_result_symbol(dso, symbols__find(dso__symbols(dso), addr));
 	}
 
-	return dso__last_find_result_symbol(dso);
+	return dso__named_symbol(dso, dso__last_find_result_symbol(dso));
 }
 
 struct symbol *dso__find_symbol_nocache(struct dso *dso, u64 addr)
 {
-	return symbols__find(dso__symbols(dso), addr);
+	return dso__named_symbol(dso, symbols__find(dso__symbols(dso), addr));
 }
 
 struct symbol *dso__first_symbol(struct dso *dso)
 {
-	return symbols__first(dso__symbols(dso));
+	return symbols__first(dso__named_symbols(dso));
 }
 
 struct symbol *dso__last_symbol(struct dso *dso)
 {
-	return symbols__last(dso__symbols(dso));
+	return symbols__last(dso__named_symbols(dso));
 }
 
 struct symbol *dso__next_symbol(struct symbol *sym)
@@ -692,12 +743,58 @@ struct symbol *dso__find_symbol_by_name(struct dso *dso, const char *name, size_
 	return s;
 }
 
+/*
+ * Load every lazy name. Do not delete the symbols whose name cannot be
+ * read, since address lookups search the tree without the DSO lock.
+ */
+static void __dso__load_all_symbol_names(struct dso *dso)
+{
+	struct rb_node *nd = rb_first_cached(dso__symbols(dso));
+	struct symbol *batch[512];
+
+	while (nd) {
+		size_t nr = 0;
+
+		for (; nd && nr < ARRAY_SIZE(batch); nd = rb_next(nd)) {
+			struct symbol *pos = rb_entry(nd, struct symbol, rb_node);
+
+			if (symbol__has_lazy_name(pos))
+				batch[nr++] = pos;
+		}
+		if (nr)
+			dso__load_symbol_names(dso, batch, nr);
+	}
+}
+
+/*
+ * Lazy names exist only in userspace DSOs, and are all loaded once the DSO
+ * is sorted by name. Checking that first avoids taking the DSO lock, which
+ * the callers that walk kernel symbols may hold.
+ */
+static bool dso__may_have_lazy_names(struct dso *dso)
+{
+	return symbol_conf.lazy_load_symbols && !dso__kernel(dso) &&
+	       !dso__sorted_by_name(dso);
+}
+
+struct rb_root_cached *dso__named_symbols(struct dso *dso)
+{
+	if (dso__may_have_lazy_names(dso)) {
+		mutex_lock(dso__lock(dso));
+		__dso__load_all_symbol_names(dso);
+		mutex_unlock(dso__lock(dso));
+	}
+	return dso__symbols(dso);
+}
+
 void dso__sort_by_name(struct dso *dso)
 {
 	mutex_lock(dso__lock(dso));
 	if (!dso__sorted_by_name(dso)) {
 		size_t len = 0;
 
+		if (dso__may_have_lazy_names(dso))
+			__dso__load_all_symbol_names(dso);
 		dso__set_symbol_names(dso, symbols__sort_by_name(dso__symbols(dso), &len));
 		if (dso__symbol_names(dso)) {
 			dso__set_symbol_names_len(dso, len);
diff --git a/tools/perf/util/symbol.h b/tools/perf/util/symbol.h
index c231d8e4427c..5ab222b0655b 100644
--- a/tools/perf/util/symbol.h
+++ b/tools/perf/util/symbol.h
@@ -80,9 +80,18 @@ enum symbol_idle_kind {
 #define SYMBOL_FLAG_INLINED         (1 << 11)
 #define SYMBOL_FLAG_ANNOTATE2       (1 << 12)
 #define SYMBOL_FLAG_IFUNC_ALIAS     (1 << 13)
+#define SYMBOL_FLAG_LAZY_NAME       (1 << 14)
 /**
  * A symtab entry. When allocated this may be preceded by an annotation (see
  * symbol__annotation) and/or a browser_index (see symbol__browser_index).
+ *
+ * With symbol_conf.lazy_load_symbols, the ELF loader may create symbols
+ * with SYMBOL_FLAG_LAZY_NAME, whose name is still in the symbol table file.
+ * The functions that return a symbol of a DSO, such as dso__find_symbol(),
+ * load its name first, and dso__named_symbols() loads them all for code
+ * that walks the symbols. A symbol whose name cannot be read is named
+ * "[unknown]", and address lookups return NULL for it. Code that walks
+ * dso__symbols() directly must not read the name of a lazy symbol.
  */
 struct symbol {
 	struct rb_node	rb_node;
@@ -94,13 +103,24 @@ struct symbol {
 	_Atomic uint16_t flags;
 	/** Architecture specific. Unused except on PPC where it holds st_other. */
 	u8		arch_sym;
-	/** The name of length namelen associated with the symbol. */
-	char		*name;
+	union {
+		/** The name of length namelen associated with the symbol. */
+		char	*name;
+		/** File offset of the name while SYMBOL_FLAG_LAZY_NAME is set. */
+		u64	name_off;
+	};
 };
 
 void symbol__delete(struct symbol *sym);
 void symbols__delete(struct rb_root_cached *symbols);
 
+/* Pairs with the release in symbol__set_lazy_name(). */
+static inline bool symbol__has_lazy_name(const struct symbol *sym)
+{
+	return (atomic_load_explicit(&sym->flags, memory_order_acquire) &
+		SYMBOL_FLAG_LAZY_NAME) != 0;
+}
+
 static inline u8 symbol__type(const struct symbol *sym)
 {
 	return (atomic_load_explicit(&sym->flags, memory_order_relaxed) &
@@ -227,6 +247,9 @@ void symbol__elf_init(void);
 int symbol__annotation_init(void);
 
 struct symbol *symbol__new(u64 start, u64 len, u8 binding, u8 type, const char *name);
+struct symbol *symbol__new_lazy(u64 start, u64 len, u8 binding, u8 type, u64 name_off);
+void symbol__set_lazy_name(struct symbol *sym, char *name);
+void symbol__set_unknown_name(struct symbol *sym);
 size_t __symbol__fprintf_symname_offs(const struct symbol *sym,
 				      const struct addr_location *al,
 				      bool unknown_as_addr,
@@ -257,11 +280,13 @@ int dso__load_bfd_symbols(struct dso *dso, const char *debugfile);
 int dso__load_sym(struct dso *dso, struct map *map, struct symsrc *syms_ss,
 		  struct symsrc *runtime_ss, int kmodule);
 int dso__synthesize_plt_symbols(struct dso *dso, struct symsrc *ss);
+void dso__load_symbol_names(struct dso *dso, struct symbol **syms, size_t nr);
 
 char *dso__demangle_sym(struct dso *dso, int kmodule, const char *elf_name);
 
 void __symbols__insert(struct rb_root_cached *symbols, struct symbol *sym);
 void symbols__insert(struct rb_root_cached *symbols, struct symbol *sym);
+struct symbol *symbols__find(struct rb_root_cached *symbols, u64 ip);
 void symbols__fixup_duplicate(struct rb_root_cached *symbols);
 void symbols__fixup_end(struct rb_root_cached *symbols, bool is_kallsyms);
 
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

