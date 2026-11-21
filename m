From: Alireza Haghdoost <haghdoost@uber.com>
Date: Sat, 21 Nov 2026 08:41:03 -0800
Subject: [PATCH v8 3/7] perf symbols: Add lazy symbol names
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261121-perf-symbol-memory-send-v8-3-370561cbb5a7@uber.com>
References: <20261121-perf-symbol-memory-send-v8-0-370561cbb5a7@uber.com>
In-Reply-To: <20261121-perf-symbol-memory-send-v8-0-370561cbb5a7@uber.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=17587; i=haghdoost@uber.com;
 h=from:subject:message-id; bh=f3dV/bRpi8/Yw18Z0rjbfVNGY8Lfyd3iQ7tOQn4qxcY=;
 b=owEBiQJ2/ZANAwAIAVNlBDxl2ALYAcsmYgBrAcmuXnGBTcOwihMs0tBrIn19kr03XcgCdXKYE
 fTo1r2hgK6JAk8EAAEIADkWIQS5+sFL3gX/8PrA0S1TZQQ8ZdgC2AUCawHJrhsUgAAAAAAEAA5t
 YW51MiwyLjUrMS4xMiwwLDMACgkQU2UEPGXYAthasg/+M/u9CaevEZHgCiCiPMWKhh2OEMDcA41
 9HDGsJsLZ9XouPhXEAb1ePonHhrj59PDKkV9o8LEXz81zcI7kkKOHuxE3ln2IAHRdyzwBc8FhGi
 E7knGCdCpbWQVT3L1E7K8p3Y/eOEau0lGHiCtk5EB6P9tRyDUOBjYFH1t+NmZ8Vzeiu1Hv166W9
 IZ/mqu7mpqbRMIu9B9HKUbWVSkB7jBRa6a4o1ad1y35JCNPPBO0XDthCi/JwPjv2azAWubRRBYL
 OSJSdJgUe4QCE0NBWWM5crG1P/+0WWGq7wisc94mN1mQEfJImdUj7DzTIQwU4AB/LzOgZX2SD3V
 43AFrB3K/FJW2yKnLg1SHmG6zFBRoerygxUpSeC0ZA7VII6y84YB/PFpgmJ+Uh63dqaFsiDAPVq
 Pj20zdGCo8nkL9iI0i4m8LlneLMrDlxh9KoII+Smrq3yS2IfXlCBc1atycjr+UiVEqrLuiPKrsM
 cNkZ9CJesZnksZ80ylvuC76dMR6q+rGzz+8pf1o2Exo2m2pbElVIXG+j0WFSOJRyFf+wgDI+pDa
 nsHvwFAW+B3+qVO44QmXDxZVU/N2xVbAz4AEuUhdjvkZpqVIeVc1xKyLrNWQ8Ai1enRUFow+ROH
 aKZ7TvZ90cIsMgfqci6rIAy26fhnm3wQtjWSgxO4zo6YxXRNuPbM=
X-Developer-Key: i=haghdoost@uber.com; a=openpgp;
 fpr=B9FAC14BDE05FFF0FAC0D12D5365043C65D802D8
X-Endpoint-Received: by B4 Relay for haghdoost@uber.com/default with auth_id=764
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch lets a symbol be created without its name, so that perf reads
the name lazily only when it needs it and does not waste RSS memory
holding symbol names that are never sampled. symbol__new_lazy() stores
the file offset of the name instead, in a union with the name pointer,
and SYMBOL_FLAG_LAZY_NAME tells which one is set. This is a preparatory
change for a later patch in this series, which adds --lazy-load-symbols
to the ELF loader.

The DSO lookups load the name of the symbol they return, and code that
walks all symbols of a DSO gets them from dso__named_symbols(), which
loads every name. Names are read under the DSO lock with pread() from
the symbol table file, which is open only while perf reads them, and
demangled as at load time. If another thread loaded them first, perf
does not open the file. A name that cannot be read becomes
"[unknown]", and address lookups do not return that symbol. The ELF
loader looks symbols up with symbols__find(), so that it does not read
names while it loads the symbols.

No functional change, since no symbol has a lazy name yet.

Signed-off-by: Alireza Haghdoost <haghdoost@uber.com>
---
 tools/perf/ui/browsers/map.c     |   2 +-
 tools/perf/util/dso.c            |   2 +-
 tools/perf/util/dso.h            |   3 +-
 tools/perf/util/symbol-elf.c     |  97 ++++++++++++++++++++++++++++++++-
 tools/perf/util/symbol-minimal.c |   6 +++
 tools/perf/util/symbol.c         | 114 ++++++++++++++++++++++++++++++++++++---
 tools/perf/util/symbol.h         |  27 +++++++++-
 tools/perf/util/symbol_conf.h    |   1 +
 8 files changed, 237 insertions(+), 15 deletions(-)

diff --git a/tools/perf/ui/browsers/map.c b/tools/perf/ui/browsers/map.c
index be7390156edd..b7ae2ad4126f 100644
--- a/tools/perf/ui/browsers/map.c
+++ b/tools/perf/ui/browsers/map.c
@@ -111,7 +111,7 @@ int map__browse(struct map *map)
 {
 	struct map_browser mb = {
 		.b = {
-			.entries = dso__symbols(map__dso(map)),
+			.entries = dso__named_symbols(map__dso(map)),
 			.refresh = ui_browser__rb_tree_refresh,
 			.seek	 = ui_browser__rb_tree_seek,
 			.write	 = map_browser__write,
diff --git a/tools/perf/util/dso.c b/tools/perf/util/dso.c
index e46cd614eb21..881603d78b4b 100644
--- a/tools/perf/util/dso.c
+++ b/tools/perf/util/dso.c
@@ -2021,7 +2021,7 @@ size_t dso__fprintf(struct dso *dso, FILE *fp)
 	ret += fprintf(fp, "%sloaded, ", dso__loaded(dso) ? "" : "NOT ");
 	ret += dso__fprintf_buildid(dso, fp);
 	ret += fprintf(fp, ")\n");
-	for (nd = rb_first_cached(dso__symbols(dso)); nd; nd = rb_next(nd)) {
+	for (nd = rb_first_cached(dso__named_symbols(dso)); nd; nd = rb_next(nd)) {
 		struct symbol *pos = rb_entry(nd, struct symbol, rb_node);
 		ret += symbol__fprintf(pos, fp);
 	}
diff --git a/tools/perf/util/dso.h b/tools/perf/util/dso.h
index d5f7382d4e13..10eac0b31b7d 100644
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
index 2b7f9e30916d..82d6a76176d2 100644
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
@@ -460,7 +461,7 @@ static bool get_ifunc_name(Elf *elf, struct dso *dso, GElf_Ehdr *ehdr,
 
 	addr -= phdr.p_vaddr - phdr.p_offset;
 
-	sym = dso__find_symbol_nocache(dso, addr);
+	sym = symbols__find(dso__symbols(dso), addr);
 
 	/* Expecting the address to be an IFUNC or IFUNC alias */
 	if (!sym || sym->start != addr ||
@@ -741,7 +742,7 @@ int dso__synthesize_plt_symbols(struct dso *dso, struct symsrc *ss)
 	 * by symbols__fixup_end() to overlap .plt. Truncate it before adding
 	 * a symbol for .plt header.
 	 */
-	f = dso__find_symbol_nocache(dso, shdr_plt.sh_offset);
+	f = symbols__find(dso__symbols(dso), shdr_plt.sh_offset);
 	if (f && f->start < shdr_plt.sh_offset && f->end > shdr_plt.sh_offset)
 		f->end = shdr_plt.sh_offset;
 
@@ -1628,6 +1629,98 @@ static int dso__process_kernel_symbol(struct dso *dso, struct map *map,
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
+static int read_symbol_names(struct dso *dso, int fd, struct symbol **syms, size_t nr)
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
+		symbol__set_loaded_name(syms[i], name);
+	}
+	return err;
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
+	size_t i;
+
+	/* Another thread can load the names before the caller takes the lock. */
+	for (i = 0; i < nr && !symbol__needs_lazy_name(syms[i]); i++)
+		;
+	if (i == nr)
+		return;
+	if (!own_ns)
+		nsinfo__mountns_enter(dso__nsinfo(dso), &nsc);
+	name = dso__get_filename(dso, "", &decomp, type);
+	if (name)
+		fd = open(name, O_RDONLY | O_CLOEXEC);
+	if (!own_ns)
+		nsinfo__mountns_exit(&nsc);
+
+	if (fd >= 0) {
+		read_symbol_names(dso, fd, syms, nr);
+		close(fd);
+	} else {
+		pr_debug("%s: cannot open the symbol table file\n", dso__long_name(dso));
+	}
+	if (name)
+		dso__put_filename(dso, name, decomp);
+	for (i = 0; i < nr; i++) {
+		if (symbol__needs_lazy_name(syms[i]))
+			symbol__set_unknown_name(syms[i]);
+	}
+}
+
 static int
 dso__load_sym_internal(struct dso *dso, struct map *map, struct symsrc *syms_ss,
 		       struct symsrc *runtime_ss, int kmodule, int dynsym)
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
index ad4bf7685293..f4dd630aa10f 100644
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
 	struct symbol *sym = calloc(1, sizeof(*sym) + namelen);
 
 	if (sym == NULL)
@@ -349,7 +349,18 @@ struct symbol *symbol__new(u64 start, u64 len, u8 binding, u8 type, const char *
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
@@ -360,10 +371,39 @@ struct symbol *symbol__new(u64 start, u64 len, u8 binding, u8 type, const char *
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
+void symbol__set_loaded_name(struct symbol *sym, char *name)
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
+	symbol__set_loaded_name(sym, (char *)unknown_name);
+}
+
 void symbol__delete(struct symbol *sym)
 {
 	if (!sym)
 		return;
+	/* A loaded lazy name is allocated apart from the symbol. */
+	if (!symbol__needs_lazy_name(sym) && sym->name != (char *)(sym + 1) &&
+	    sym->name != unknown_name)
+		free(sym->name);
 	symbol__annotation_delete(sym);
 	free(sym);
 }
@@ -451,7 +491,7 @@ void symbols__insert(struct rb_root_cached *symbols, struct symbol *sym)
 	__symbols__insert(symbols, sym);
 }
 
-static struct symbol *symbols__find(struct rb_root_cached *symbols, u64 ip)
+struct symbol *symbols__find(struct rb_root_cached *symbols, u64 ip)
 {
 	struct rb_node *n;
 
@@ -626,6 +666,18 @@ void dso__delete_symbol(struct dso *dso, struct symbol *sym)
 	dso__reset_find_symbol_cache(dso);
 }
 
+static struct symbol *dso__resolve_symbol_name(struct dso *dso, struct symbol *sym)
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
@@ -633,22 +685,22 @@ struct symbol *dso__find_symbol(struct dso *dso, u64 addr)
 		dso__set_last_find_result_symbol(dso, symbols__find(dso__symbols(dso), addr));
 	}
 
-	return dso__last_find_result_symbol(dso);
+	return dso__resolve_symbol_name(dso, dso__last_find_result_symbol(dso));
 }
 
 struct symbol *dso__find_symbol_nocache(struct dso *dso, u64 addr)
 {
-	return symbols__find(dso__symbols(dso), addr);
+	return dso__resolve_symbol_name(dso, symbols__find(dso__symbols(dso), addr));
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
@@ -680,12 +732,58 @@ struct symbol *dso__find_symbol_by_name(struct dso *dso, const char *name, size_
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
+ * Lazy names exist only in userspace DSOs. Checking that first avoids taking
+ * the DSO lock, which the callers that walk kernel symbols may hold.
+ */
+static bool dso__may_have_lazy_names(struct dso *dso)
+{
+	return symbol_conf.lazy_load_symbols && !dso__kernel(dso);
+}
+
+struct rb_root_cached *dso__named_symbols(struct dso *dso)
+{
+	if (dso__may_have_lazy_names(dso)) {
+		mutex_lock(dso__lock(dso));
+		/* All names are loaded once the DSO is sorted by name. */
+		if (!dso__sorted_by_name(dso))
+			__dso__load_all_symbol_names(dso);
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
index a449c170d834..d690cb1d021c 100644
--- a/tools/perf/util/symbol.h
+++ b/tools/perf/util/symbol.h
@@ -78,8 +78,15 @@ enum symbol_idle_kind {
 #define SYMBOL_FLAG_INLINED         (1 << 11)
 #define SYMBOL_FLAG_ANNOTATE2       (1 << 12)
 #define SYMBOL_FLAG_IFUNC_ALIAS     (1 << 13)
+#define SYMBOL_FLAG_LAZY_NAME       (1 << 14)
 /**
  * A symtab entry.
+ *
+ * The DSO lookups such as dso__find_symbol() load a lazy name before
+ * returning the symbol, and the address lookups return NULL if it cannot
+ * be read. Code that walks dso__symbols() directly must use
+ * dso__named_symbols() or not read the name of a symbol with
+ * SYMBOL_FLAG_LAZY_NAME.
  */
 struct symbol {
 	struct rb_node	rb_node;
@@ -91,13 +98,24 @@ struct symbol {
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
 
+/* Pairs with the release in symbol__set_loaded_name(). */
+static inline bool symbol__needs_lazy_name(const struct symbol *sym)
+{
+	return (atomic_load_explicit(&sym->flags, memory_order_acquire) &
+		SYMBOL_FLAG_LAZY_NAME) != 0;
+}
+
 static inline u8 symbol__type(const struct symbol *sym)
 {
 	return (atomic_load_explicit(&sym->flags, memory_order_relaxed) &
@@ -219,6 +237,9 @@ void symbol__elf_init(void);
 int symbol__annotation_init(void);
 
 struct symbol *symbol__new(u64 start, u64 len, u8 binding, u8 type, const char *name);
+struct symbol *symbol__new_lazy(u64 start, u64 len, u8 binding, u8 type, u64 name_off);
+void symbol__set_loaded_name(struct symbol *sym, char *name);
+void symbol__set_unknown_name(struct symbol *sym);
 size_t __symbol__fprintf_symname_offs(const struct symbol *sym,
 				      const struct addr_location *al,
 				      bool unknown_as_addr,
@@ -249,11 +270,13 @@ int dso__load_bfd_symbols(struct dso *dso, const char *debugfile);
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
index aaa7148c3ac1..f47482072625 100644
--- a/tools/perf/util/symbol_conf.h
+++ b/tools/perf/util/symbol_conf.h
@@ -76,6 +76,7 @@ struct symbol_conf {
 			no_buildid_mmap2,
 			guest_code,
 			lazy_load_kernel_maps,
+			lazy_load_symbols,
 			keep_exited_threads,
 			annotate_data_member,
 			annotate_data_sample,

-- 
Git-157)

