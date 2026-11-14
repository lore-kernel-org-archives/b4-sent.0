From: Alireza Haghdoost <haghdoost@uber.com>
Date: Fri, 13 Nov 2026 21:09:08 -0800
Subject: [PATCH v7 3/4] perf script: Add --lazy-load-symbols to load symbol
 names lazily
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261113-perf-symbol-memory-send-v7-3-d992eced9f9c@uber.com>
References: <20261113-perf-symbol-memory-send-v7-0-d992eced9f9c@uber.com>
In-Reply-To: <20261113-perf-symbol-memory-send-v7-0-d992eced9f9c@uber.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=29671; i=haghdoost@uber.com;
 h=from:subject:message-id; bh=UkuQ25cdqWe2K17QwgXdRskDAacCBQi46Gne0uJFpEs=;
 b=owEBiQJ2/ZANAwAIAVNlBDxl2ALYAcsmYgBq9+0lLozXeExmRyncezJohhoTuH6o8dy/PT7Ca
 YjkaNbCkIiJAk8EAAEIADkWIQS5+sFL3gX/8PrA0S1TZQQ8ZdgC2AUCavftJRsUgAAAAAAEAA5t
 YW51MiwyLjUrMS4xMiwwLDMACgkQU2UEPGXYAtiIuQ/9GqoUWdib5R66PmOyhrLc2mhEbDg+pp6
 5UcICtOa9oZSpC2G3KXyIxYrgUQ3L0Zn3gBV4suZdWuIedCMApedHE1Aao6zOjEGO+A83fBs8Oe
 r8gP6Q+lCrmJW4LUH2UL6Za1fCJ8u0iTh4ZUUcQq/eJHYh6qe8SR4IFyDoEsakcRR01LtgaqAQK
 F9kYYnWoy/FHYZLJQq568VwTyMbdKFtEQUxwptDcZxIjc2zxUZncIz2appOusO82u36l+3Bzd4l
 FPS6v5hMtIkz0eiProAr8tRW66ufC/KusYDB3aTKyHp7uCU3bI3uchU/Kp8qUFUyfFA8onrmPui
 PIkudu5LIhButY9Fh1hucuTSLWJfRfni/7T5U0TuIpvm/6PzjN8UcXZDgbpPHz1iDrFZzgYnS9Q
 gMQq+m1LKBJlxT6MoDugTs21OucV1oEbL0fd8ojpxEfSpUBOn72+lh2WOuF5sZ5LphPhGWqoMig
 h8b6tFldsAlyI3CEzWFf9W1QvfFodYEmU8nvi4PPAssgKY0s6h1NqnD0n4/aMtuCOdb109H2q0A
 xamwLEedMal24d0xdiW453Q8QKCN0kc4MfGz0KrNH1hRbZe7bL5PNqrXfkXbNXDMn/+2rKb7h2v
 JwGm/uCTTKXoPBKA3OAwrBl7f5qRb0TLzAMZT95f7oiR9atZIQaU=
X-Developer-Key: i=haghdoost@uber.com; a=openpgp;
 fpr=B9FAC14BDE05FFF0FAC0D12D5365043C65D802D8
X-Endpoint-Received: by B4 Relay for haghdoost@uber.com/default with auth_id=764
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch adds a --lazy-load-symbols option to perf script. With it,
perf reads the name of a userspace ELF symbol only when a lookup returns
that symbol. Eager loading stays the default.

perf script loads the whole ELF symbol table of every DSO that appears
in a sample and keeps every symbol, with its demangled name, until exit.
Most of those symbols are never sampled, and their names take most of
the memory. On a large profile this is the main memory cost of perf
script, and in a memory-limited cgroup it gets perf OOM-killed.

The loader still creates every symbol, so end fixup, duplicate
selection, PLT synthesis and IFUNC marking do not change. It stores the
file offset of each name instead of the name, in a union with the name
pointer, and SYMBOL_FLAG_LAZY_NAME tells which one is set. Lookups load
the name of the symbol they return, and code that walks all symbols of
a DSO gets them from dso__named_symbols(), which loads every name. Names
are read under the DSO lock with pread() from the symbol table file,
which is open only while perf reads them. A name that cannot be read
becomes "[unknown]", and address lookups do not return that symbol.

A few names are still read at load time: aliases that duplicate
selection can tell apart only by name, and IFUNC symbols, whose names
PLT synthesis uses. A .dynsym entry that copies a lazy .symtab symbol is
skipped, since duplicate selection would drop it anyway after reading
both names.

The offsets are only valid in the file that perf loaded. perf records
its device, inode, size and mtime, and checks them each time it opens
the file again. If the binary was replaced in the meantime, for example
by a deploy, or the path now resolves to another file because a mount
namespace went away, perf warns once and shows the remaining lazy
symbols of that DSO as "[unknown]" rather than print wrong names.

The kernel, modules, PPC64 .opd and .gnu_debugdata still load names
eagerly.

On a 45,073-sample callchain profile of a large C++ service (about 1M
symbols), lazy loading cuts max RSS from 327 MiB to 135 MiB and run
time from 2.9 to 1.3 seconds, with identical output.

Signed-off-by: Alireza Haghdoost <haghdoost@uber.com>
---
 tools/perf/Documentation/perf-script.txt |   9 +
 tools/perf/builtin-script.c              |   2 +
 tools/perf/ui/browsers/map.c             |   2 +-
 tools/perf/util/dso.c                    |   2 +-
 tools/perf/util/dso.h                    |  20 ++-
 tools/perf/util/symbol-elf.c             | 299 +++++++++++++++++++++++++++++--
 tools/perf/util/symbol-minimal.c         |   6 +
 tools/perf/util/symbol.c                 | 114 +++++++++++-
 tools/perf/util/symbol.h                 |  28 ++-
 tools/perf/util/symbol_conf.h            |   1 +
 10 files changed, 460 insertions(+), 23 deletions(-)

diff --git a/tools/perf/Documentation/perf-script.txt b/tools/perf/Documentation/perf-script.txt
index f0228e784ced..53b3b0fa830d 100644
--- a/tools/perf/Documentation/perf-script.txt
+++ b/tools/perf/Documentation/perf-script.txt
@@ -343,6 +343,15 @@ include::itrace.txt[]
 
         Default: 127
 
+--lazy-load-symbols::
+	Read and demangle userspace ELF symbol names only when perf needs
+	them. By default, perf reads every symbol name from each binary
+	referenced by a sample. This option reduces memory use and usually
+	improves performance when samples reference only a small fraction
+	of a large binary's symbols. The names are read while perf script
+	runs, so if a binary is replaced during the run, perf warns and
+	shows its symbols that are not read yet as unknown.
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
index d5f7382d4e13..04c77ef92317 100644
--- a/tools/perf/util/dso.h
+++ b/tools/perf/util/dso.h
@@ -282,6 +282,17 @@ struct dso_bpf_prog {
 	struct perf_env	*env;
 };
 
+/* The file that lazy symbol names are read from, as it was at load time. */
+struct dso_lazy_file {
+	u64		dev;
+	u64		ino;
+	u64		size;
+	u64		mtime_sec;
+	u64		mtime_nsec;
+	/* The file changed after the names were loaded. */
+	bool		rejected;
+};
+
 struct auxtrace_cache;
 
 DECLARE_RC_STRUCT(dso) {
@@ -321,6 +332,7 @@ DECLARE_RC_STRUCT(dso) {
 	struct dso_bpf_prog bpf_prog;
 	/* dso data file */
 	struct dso_data	 data;
+	struct dso_lazy_file lazy_file;
 	struct dso_id	 id;
 	unsigned int	 a2l_fails;
 	int		 comp;
@@ -369,7 +381,7 @@ int dso_id__cmp(const struct dso_id *a, const struct dso_id *b);
  * @n: the 'struct rb_node *' to use as a temporary storage
  */
 #define dso__for_each_symbol(dso, pos, n)	\
-	symbols__for_each_entry(dso__symbols(dso), pos, n)
+	symbols__for_each_entry(dso__named_symbols(dso), pos, n)
 
 static inline void *dso__a2l(const struct dso *dso)
 {
@@ -503,6 +515,11 @@ static inline struct dso_data *dso__data(struct dso *dso)
 	return &RC_CHK_ACCESS(dso)->data;
 }
 
+static inline struct dso_lazy_file *dso__lazy_file(struct dso *dso)
+{
+	return &RC_CHK_ACCESS(dso)->lazy_file;
+}
+
 static inline u64 dso__db_id(const struct dso *dso)
 {
 	return RC_CHK_ACCESS(dso)->db_id;
@@ -831,6 +848,7 @@ char *dso__filename_with_chroot(const struct dso *dso, const char *filename);
 bool dso__sorted_by_name(const struct dso *dso);
 void dso__set_sorted_by_name(struct dso *dso);
 void dso__sort_by_name(struct dso *dso);
+struct rb_root_cached *dso__named_symbols(struct dso *dso);
 
 int dso__swap_init(struct dso *dso, unsigned char eidata);
 
diff --git a/tools/perf/util/symbol-elf.c b/tools/perf/util/symbol-elf.c
index 98b6d7c73d23..7b7f06a882f6 100644
--- a/tools/perf/util/symbol-elf.c
+++ b/tools/perf/util/symbol-elf.c
@@ -6,6 +6,7 @@
 #include <string.h>
 #include <unistd.h>
 #include <inttypes.h>
+#include <sys/stat.h>
 
 #include "compress.h"
 #include "dso.h"
@@ -17,6 +18,7 @@
 #include "machine.h"
 #include "vdso.h"
 #include "debug.h"
+#include "namespaces.h"
 #include "util/copyfile.h"
 #include <linux/ctype.h>
 #include <linux/kernel.h>
@@ -350,7 +352,7 @@ static bool get_ifunc_name(Elf *elf, struct dso *dso, GElf_Ehdr *ehdr,
 
 	addr -= phdr.p_vaddr - phdr.p_offset;
 
-	sym = dso__find_symbol_nocache(dso, addr);
+	sym = symbols__find(dso__symbols(dso), addr);
 
 	/* Expecting the address to be an IFUNC or IFUNC alias */
 	if (!sym || sym->start != addr ||
@@ -631,7 +633,7 @@ int dso__synthesize_plt_symbols(struct dso *dso, struct symsrc *ss)
 	 * by symbols__fixup_end() to overlap .plt. Truncate it before adding
 	 * a symbol for .plt header.
 	 */
-	f = dso__find_symbol_nocache(dso, shdr_plt.sh_offset);
+	f = symbols__find(dso__symbols(dso), shdr_plt.sh_offset);
 	if (f && f->start < shdr_plt.sh_offset && f->end > shdr_plt.sh_offset)
 		f->end = shdr_plt.sh_offset;
 
@@ -1518,6 +1520,231 @@ static int dso__process_kernel_symbol(struct dso *dso, struct map *map,
 	return 0;
 }
 
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
+		if (!symbol__needs_lazy_name(syms[i]))
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
+static int lazy_file__stat(struct dso_lazy_file *lf, int fd)
+{
+	struct stat st;
+
+	if (fstat(fd, &st))
+		return -1;
+	lf->dev = st.st_dev;
+	lf->ino = st.st_ino;
+	lf->size = st.st_size;
+	lf->mtime_sec = st.st_mtim.tv_sec;
+	lf->mtime_nsec = st.st_mtim.tv_nsec;
+	lf->rejected = false;
+	return 0;
+}
+
+/* The caller holds the DSO lock, as dso__load() does. */
+int dso__set_lazy_file(struct dso *dso, int fd)
+{
+	return lazy_file__stat(dso__lazy_file(dso), fd);
+}
+
+/*
+ * The name offsets are only valid in the file that dso__load() read. If @fd
+ * is another file, for example after the binary was replaced, reject it and
+ * every later read for @dso.
+ */
+static bool dso__lazy_file_ok(struct dso *dso, int fd, const char *name)
+{
+	struct dso_lazy_file *lf = dso__lazy_file(dso);
+	struct dso_lazy_file now;
+
+	if (!lazy_file__stat(&now, fd) && now.dev == lf->dev && now.ino == lf->ino &&
+	    now.size == lf->size && now.mtime_sec == lf->mtime_sec &&
+	    now.mtime_nsec == lf->mtime_nsec)
+		return true;
+	pr_warning("%s changed after its symbols were loaded, its symbol names are not shown\n",
+		   name);
+	lf->rejected = true;
+	return false;
+}
+
+/*
+ * A name that cannot be read becomes "[unknown]". The caller holds the
+ * DSO lock.
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
+	if (dso__lazy_file(dso)->rejected)
+		goto out_unknown;
+	if (!own_ns)
+		nsinfo__mountns_enter(dso__nsinfo(dso), &nsc);
+	name = dso__get_filename(dso, "", &decomp, type);
+	if (name)
+		fd = open(name, O_RDONLY | O_CLOEXEC);
+	if (!own_ns)
+		nsinfo__mountns_exit(&nsc);
+
+	if (fd >= 0) {
+		if (dso__lazy_file_ok(dso, fd, name))
+			load_symbol_names(dso, fd, syms, nr);
+		close(fd);
+	} else {
+		pr_debug("%s: cannot open the symbol table file\n", dso__long_name(dso));
+	}
+	if (name)
+		dso__put_filename(dso, name, decomp);
+out_unknown:
+	for (size_t i = 0; i < nr; i++) {
+		if (symbol__needs_lazy_name(syms[i]))
+			symbol__set_unknown_name(syms[i]);
+	}
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
+		    symbol__needs_lazy_name(s) && s->name_off < size &&
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
@@ -1535,9 +1762,19 @@ dso__load_sym_internal(struct dso *dso, struct map *map, struct symsrc *syms_ss,
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
@@ -1573,6 +1810,15 @@ dso__load_sym_internal(struct dso *dso, struct map *map, struct symsrc *syms_ss,
 	if (symstrs == NULL)
 		goto out_elf_end;
 
+	/*
+	 * Names are read with pread(), so the string table must be stored as
+	 * is, and later reads must find the same file.
+	 */
+	if (lazy_allowed && gelf_getshdr(sec, &strshdr) &&
+	    strshdr.sh_type == SHT_STRTAB && !(strshdr.sh_flags & SHF_COMPRESSED) &&
+	    !dso__set_lazy_file(dso, syms_ss->fd))
+		lazy_names = true;
+
 	sec_strndx = elf_getscn(runtime_ss->elf, runtime_ss->ehdr.e_shstrndx);
 	if (sec_strndx == NULL)
 		goto out_elf_end;
@@ -1774,14 +2020,36 @@ dso__load_sym_internal(struct dso *dso, struct map *map, struct symsrc *syms_ss,
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
 
@@ -1791,6 +2059,10 @@ dso__load_sym_internal(struct dso *dso, struct map *map, struct symsrc *syms_ss,
 		nr++;
 	}
 	dso__put(curr_dso);
+
+	if (lazy_names)
+		pr_debug("%s: %d %s symbols with lazy names\n", dso__long_name(dso),
+			 nr_lazy, dynsym ? ".dynsym" : ".symtab");
 	return nr;
 out_elf_end:
 	dso__put(curr_dso);
@@ -1860,9 +2132,16 @@ int dso__load_sym(struct dso *dso, struct map *map, struct symsrc *syms_ss,
 	if (nr > 0) {
 		struct kmap *kmap = dso__kernel(dso) ? map__kmap(map) : NULL;
 		struct maps *kmaps = kmap ? map__kmaps(map) : NULL;
+		/* Lazy names are only in syms_ss, never in the kernel or modules. */
+		bool lazy = symbol_conf.lazy_load_symbols && !dso__kernel(dso) && !kmodule;
 
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
index 02c077d7e2a6..eb44508115e3 100644
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
@@ -368,8 +379,37 @@ struct symbol *symbol__new(u64 start, u64 len, u8 binding, u8 type, const char *
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
+	if (!symbol__needs_lazy_name(sym) && sym->name != (char *)(sym + 1) &&
+	    sym->name != unknown_name)
+		free(sym->name);
 	if (symbol_conf.priv_size) {
 		if (symbol_conf.init_annotation) {
 			struct annotation *notes = symbol__annotation(sym);
@@ -463,7 +503,7 @@ void symbols__insert(struct rb_root_cached *symbols, struct symbol *sym)
 	__symbols__insert(symbols, sym);
 }
 
-static struct symbol *symbols__find(struct rb_root_cached *symbols, u64 ip)
+struct symbol *symbols__find(struct rb_root_cached *symbols, u64 ip)
 {
 	struct rb_node *n;
 
@@ -638,6 +678,18 @@ void dso__delete_symbol(struct dso *dso, struct symbol *sym)
 	dso__reset_find_symbol_cache(dso);
 }
 
+static struct symbol *dso__named_symbol(struct dso *dso, struct symbol *sym)
+{
+	if (sym && symbol__needs_lazy_name(sym)) {
+		mutex_lock(dso__lock(dso));
+		dso__load_symbol_names(dso, &sym, 1);
+		mutex_unlock(dso__lock(dso));
+	}
+	if (sym && sym->name == unknown_name)
+		return NULL;
+	return sym;
+}
+
 struct symbol *dso__find_symbol(struct dso *dso, u64 addr)
 {
 	if (dso__last_find_result_addr(dso) != addr || dso__last_find_result_symbol(dso) == NULL) {
@@ -645,22 +697,22 @@ struct symbol *dso__find_symbol(struct dso *dso, u64 addr)
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
@@ -692,12 +744,58 @@ struct symbol *dso__find_symbol_by_name(struct dso *dso, const char *name, size_
 	return s;
 }
 
+/*
+ * Do not delete the symbols whose name cannot be read, since address
+ * lookups search the tree without the DSO lock.
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
+			if (symbol__needs_lazy_name(pos))
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
index c8b94f54f0e6..68fbe3301c6e 100644
--- a/tools/perf/util/symbol.h
+++ b/tools/perf/util/symbol.h
@@ -78,9 +78,16 @@ enum symbol_idle_kind {
 #define SYMBOL_FLAG_INLINED         (1 << 11)
 #define SYMBOL_FLAG_ANNOTATE2       (1 << 12)
 #define SYMBOL_FLAG_IFUNC_ALIAS     (1 << 13)
+#define SYMBOL_FLAG_LAZY_NAME       (1 << 14)
 /**
  * A symtab entry. When allocated this may be preceded by an annotation (see
  * symbol__annotation) and/or a browser_index (see symbol__browser_index).
+ *
+ * The DSO lookups such as dso__find_symbol() load a lazy name before
+ * returning the symbol, and the address lookups return NULL if it cannot
+ * be read. Code that walks dso__symbols() directly must use
+ * dso__named_symbols() or not read the name of a symbol with
+ * SYMBOL_FLAG_LAZY_NAME.
  */
 struct symbol {
 	struct rb_node	rb_node;
@@ -92,13 +99,24 @@ struct symbol {
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
+static inline bool symbol__needs_lazy_name(const struct symbol *sym)
+{
+	return (atomic_load_explicit(&sym->flags, memory_order_acquire) &
+		SYMBOL_FLAG_LAZY_NAME) != 0;
+}
+
 static inline u8 symbol__type(const struct symbol *sym)
 {
 	return (atomic_load_explicit(&sym->flags, memory_order_relaxed) &
@@ -225,6 +243,9 @@ void symbol__elf_init(void);
 int symbol__annotation_init(void);
 
 struct symbol *symbol__new(u64 start, u64 len, u8 binding, u8 type, const char *name);
+struct symbol *symbol__new_lazy(u64 start, u64 len, u8 binding, u8 type, u64 name_off);
+void symbol__set_lazy_name(struct symbol *sym, char *name);
+void symbol__set_unknown_name(struct symbol *sym);
 size_t __symbol__fprintf_symname_offs(const struct symbol *sym,
 				      const struct addr_location *al,
 				      bool unknown_as_addr,
@@ -255,11 +276,14 @@ int dso__load_bfd_symbols(struct dso *dso, const char *debugfile);
 int dso__load_sym(struct dso *dso, struct map *map, struct symsrc *syms_ss,
 		  struct symsrc *runtime_ss, int kmodule);
 int dso__synthesize_plt_symbols(struct dso *dso, struct symsrc *ss);
+void dso__load_symbol_names(struct dso *dso, struct symbol **syms, size_t nr);
+int dso__set_lazy_file(struct dso *dso, int fd);
 
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

