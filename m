From: Alireza Haghdoost <haghdoost@uber.com>
Date: Tue, 24 Nov 2026 11:28:26 -0800
Subject: [PATCH v9 3/7] perf symbols: Add lazy symbol names
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261124-perf-symbol-memory-send-v9-3-56f298185eae@uber.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=18212; i=haghdoost@uber.com;
 h=from:subject:message-id; bh=jUMSMcsB3HlA36FCJlMKsZ6sK5rn5Voi7CrTvUxez5A=;
 b=owEBiQJ2/ZANAwAIAVNlBDxl2ALYAcsmYgBrBeWFtAQ1fcHPey17ttYkU0PdUh0bQFID4PYYI
 JeJr56PJ22JAk8EAAEIADkWIQS5+sFL3gX/8PrA0S1TZQQ8ZdgC2AUCawXlhRsUgAAAAAAEAA5t
 YW51MiwyLjUrMS4xMiwwLDMACgkQU2UEPGXYAtidmRAAn5Cci0hIBWB0I7RtKhfgl4RKPw0WntY
 77uAmBVzqHAtIJu30pF7rTsu3AmgtWWp3lKjg2Nxtf4c4K9o+HXapHY/Ea8RfDk+0F3RbH+Plbh
 Cmtcib2lUZsSiwd41pQMgh2WL+SiCZ1x3s+XnHNuBDx0+Z6j1XIGd+867qzHMJs92wg2f7RasIT
 ZKEhVxtaJgNuuj7hFC4v3Pb+eWZbB9HTkuhNGfxNFpjynEvoWopqHBVfC8EoyvGVcJWxLYOwtT6
 b1MqxiLzeEEUW2IwVe14a7jjAAKX9lx79er1vjijO1+Mg7qs+Jlcn9QK1PYoL5YPaf+rlGfzSrC
 rDNHLI1ZQGbdajkMhOlHjLFlfaiMfbRaozisFoMtqc3is5v85I04XGHBXjpI5r+2oQAhRm6ED+Z
 bkkxgE7BL8uJ7D2NdZV+VM7/l+PVERBidcsTUFKKQq6Rn/AhMJ/QnNf8Nk6ZZqkUZsgjVsGYpuV
 7w2kId6c4c1UtSxRFZ7sUTF1uO3HHUnT6Lgib0N4Yjq4sRYNKH9gkwwToeTOjGI4cNCTVlXkMf7
 hWmGOx7PJgZM9163ld/moQum3kqINTOfi6jBOg2rY8l3mMtRCm1X6XD6WmQCwxLTd0kOmpSsrSZ
 UrRzpi5Pqva2cuomcyi9jZOsEejmPa32iTNX5ONAMAwbwphx7gJs=
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

The address lookups load the name of the symbol they return. The walks
over all symbols of a DSO and the lookups by name get the symbols from
dso__named_symbols(), which loads every name the first time. The loader
will mark a DSO that has lazy names as pending. dso__named_symbols()
loads them and marks the DSO eager, also when the DSO is not loaded yet,
so that a load racing with a walk, as in perf top, adds no symbols
without names.

Names are read under the DSO lock with pread() from the symbol table
file, which is open only while perf reads them, and demangled as at
load time. The file name is built again and opened in perf's mount
namespace, so the loader must create lazy names only for a file that it
opened there by that name. If another thread loaded them first, perf
does not open the file. A name that cannot be read becomes "[unknown]",
and address lookups do not return that symbol.
SYMBOL_FLAG_NAME_ALLOCATED marks a loaded name, which is freed with the
symbol. The ELF loader looks symbols up with symbols__find(), so that it
does not read names while it loads the symbols.

No functional change, since no symbol has a lazy name yet.

Signed-off-by: Alireza Haghdoost <haghdoost@uber.com>
---
 tools/perf/ui/browsers/map.c     |   2 +-
 tools/perf/util/dso.h            |  28 +++++++++-
 tools/perf/util/symbol-elf.c     |  89 +++++++++++++++++++++++++++++++-
 tools/perf/util/symbol-minimal.c |   6 +++
 tools/perf/util/symbol.c         | 108 +++++++++++++++++++++++++++++++++++----
 tools/perf/util/symbol.h         |  28 ++++++++--
 tools/perf/util/symbol_conf.h    |   1 +
 7 files changed, 245 insertions(+), 17 deletions(-)

diff --git a/tools/perf/ui/browsers/map.c b/tools/perf/ui/browsers/map.c
index 51a71b20947f..7e63954d65a3 100644
--- a/tools/perf/ui/browsers/map.c
+++ b/tools/perf/ui/browsers/map.c
@@ -108,7 +108,7 @@ static int map_browser__run(struct map_browser *browser)
 
 int map__browse(struct map *map)
 {
-	struct symbols *symbols = dso__symbols(map__dso(map));
+	struct symbols *symbols = dso__named_symbols(map__dso(map));
 	struct map_browser mb = {
 		.b = {
 			.refresh = ui_browser__argv_refresh,
diff --git a/tools/perf/util/dso.h b/tools/perf/util/dso.h
index 63c1b7d6f6f8..ebd8230b9895 100644
--- a/tools/perf/util/dso.h
+++ b/tools/perf/util/dso.h
@@ -154,6 +154,15 @@ enum dso_swap_type {
 	DSO_SWAP__YES,
 };
 
+enum dso_lazy_names {
+	/* No symbol has a lazy name. */
+	DSO_LAZY_NAMES__NONE,
+	/* Some symbol names are not loaded yet. */
+	DSO_LAZY_NAMES__PENDING,
+	/* All names were needed once, so later loads read names eagerly. */
+	DSO_LAZY_NAMES__EAGER,
+};
+
 enum dso_data_status {
 	DSO_DATA_STATUS_ERROR	= -1,
 	DSO_DATA_STATUS_UNKNOWN	= 0,
@@ -344,6 +353,8 @@ DECLARE_RC_STRUCT(dso) {
 	u8		 bintype_searched:1;
 	u8		 debuginfo_searched:1;
 	bool		 loaded;
+	/* Under the DSO lock. */
+	enum dso_lazy_names lazy_names;
 	u8		 rel;
 	char		 name[];
 };
@@ -360,10 +371,10 @@ int dso_id__cmp(const struct dso_id *a, const struct dso_id *b);
  * @data: opaque data pointer passed to @cb
  */
 #define dso__for_each_symbol(dso, cb, data)	\
-	symbols__visit(dso__symbols(dso), cb, data)
+	symbols__visit(dso__named_symbols(dso), cb, data)
 
 #define dso__for_each_symbol_by_name(dso, cb, data)	\
-	symbols__visit_by_name(dso__symbols(dso), cb, data)
+	symbols__visit_by_name(dso__named_symbols(dso), cb, data)
 
 static inline void *dso__a2l(const struct dso *dso)
 {
@@ -602,6 +613,16 @@ static inline void dso__set_loaded(struct dso *dso)
 	RC_CHK_ACCESS(dso)->loaded = true;
 }
 
+static inline enum dso_lazy_names dso__lazy_names(const struct dso *dso)
+{
+	return RC_CHK_ACCESS(dso)->lazy_names;
+}
+
+static inline void dso__set_lazy_names(struct dso *dso, enum dso_lazy_names lazy_names)
+{
+	RC_CHK_ACCESS(dso)->lazy_names = lazy_names;
+}
+
 static inline struct mutex *dso__lock(struct dso *dso)
 	__returns_ctx_lock(&RC_CHK_ACCESS(dso)->lock)
 {
@@ -792,6 +813,9 @@ char *dso__filename_with_chroot(const struct dso *dso, const char *filename);
 
 bool dso__sorted_by_name(const struct dso *dso);
 void dso__sort_by_name(struct dso *dso);
+struct symbols *dso__named_symbols(struct dso *dso);
+void dso__load_symbol_names(struct dso *dso, struct symbol **syms, size_t nr)
+	__must_hold(dso__lock(dso));
 
 int dso__swap_init(struct dso *dso, unsigned char eidata);
 
diff --git a/tools/perf/util/symbol-elf.c b/tools/perf/util/symbol-elf.c
index bda0b92ada24..4b9deea65b09 100644
--- a/tools/perf/util/symbol-elf.c
+++ b/tools/perf/util/symbol-elf.c
@@ -460,7 +460,7 @@ static bool get_ifunc_name(Elf *elf, struct dso *dso, GElf_Ehdr *ehdr,
 
 	addr -= phdr.p_vaddr - phdr.p_offset;
 
-	sym = dso__find_symbol_nocache(dso, addr);
+	sym = symbols__find(dso__symbols(dso), addr);
 
 	/* Expecting the address to be an IFUNC or IFUNC alias */
 	if (!sym || sym->start != addr ||
@@ -742,7 +742,7 @@ int dso__synthesize_plt_symbols(struct dso *dso, struct symsrc *ss)
 	 * by symbols__fixup_end() to overlap .plt. Truncate it before adding
 	 * a symbol for .plt header.
 	 */
-	f = dso__find_symbol_nocache(dso, shdr_plt.sh_offset);
+	f = symbols__find(dso__symbols(dso), shdr_plt.sh_offset);
 	if (f && f->start < shdr_plt.sh_offset && f->end > shdr_plt.sh_offset)
 		f->end = shdr_plt.sh_offset;
 
@@ -1631,6 +1631,91 @@ static int dso__process_kernel_symbol(struct dso *dso, struct map *map,
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
+ * A name that cannot be read becomes "[unknown]". The file name is built
+ * again and opened in perf's mount namespace, so lazy names must only be
+ * created for a symbol table file that perf opened there by that name.
+ */
+void dso__load_symbol_names(struct dso *dso, struct symbol **syms, size_t nr)
+{
+	char *filename;
+	bool decomp;
+	int fd = -1;
+	size_t i;
+
+	/* Another thread can load the names before the caller takes the lock. */
+	for (i = 0; i < nr && !symbol__needs_lazy_name(syms[i]); i++)
+		;
+	if (i == nr)
+		return;
+
+	filename = dso__get_filename(dso, "", &decomp, dso__symtab_type(dso));
+	if (filename)
+		fd = open(filename, O_RDONLY | O_CLOEXEC);
+	if (fd >= 0) {
+		read_symbol_names(dso, fd, syms, nr);
+		close(fd);
+	} else {
+		pr_debug("%s: cannot open the symbol table file\n", dso__long_name(dso));
+	}
+	if (filename)
+		dso__put_filename(dso, filename, decomp);
+
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
index 25efc05c2c7a..e1310f950d3d 100644
--- a/tools/perf/util/symbol.c
+++ b/tools/perf/util/symbol.c
@@ -618,10 +618,10 @@ void symbols__fixup_end(struct symbols *symbols, bool is_kallsyms)
 	up_write(&symbols->lock);
 }
 
-struct symbol *symbol__new(u64 start, u64 len, u8 binding, u8 type, const char *name)
+static struct symbol *symbol__alloc(u64 start, u64 len, u8 binding, u8 type,
+				    u16 flags, size_t name_size)
 {
-	size_t namelen = strlen(name) + 1;
-	struct symbol *sym = calloc(1, sizeof(*sym) + namelen);
+	struct symbol *sym = calloc(1, sizeof(*sym) + name_size);
 
 	if (sym == NULL)
 		return NULL;
@@ -629,7 +629,18 @@ struct symbol *symbol__new(u64 start, u64 len, u8 binding, u8 type, const char *
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
@@ -640,10 +651,42 @@ struct symbol *symbol__new(u64 start, u64 len, u8 binding, u8 type, const char *
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
+static const char unknown_name[] = "[unknown]";
+
+/* @sym takes ownership of @name. */
+void symbol__set_loaded_name(struct symbol *sym, char *name)
+{
+	sym->namelen = strlen(name);
+	sym->name = name;
+	if (name != unknown_name)
+		atomic_fetch_or_explicit(&sym->flags, SYMBOL_FLAG_NAME_ALLOCATED,
+					 memory_order_relaxed);
+	atomic_fetch_and_explicit(&sym->flags, ~SYMBOL_FLAG_LAZY_NAME,
+				  memory_order_release);
+}
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
+	if (atomic_load_explicit(&sym->flags, memory_order_relaxed) &
+	    SYMBOL_FLAG_NAME_ALLOCATED)
+		free(sym->name);
 	symbol__annotation_delete(sym);
 	free(sym);
 }
@@ -773,7 +816,7 @@ static struct symbol *symbols__find_range(struct symbol **arr, unsigned int cnt,
  * Binary search @symbols->symbols for a symbol covering @ip. Lazily sorts
  * @symbols under @symbols->lock if unsorted.
  */
-static struct symbol *symbols__find(struct symbols *symbols, u64 ip)
+struct symbol *symbols__find(struct symbols *symbols, u64 ip)
 {
 	struct symbol *res;
 
@@ -950,14 +993,28 @@ void dso__delete_symbol(struct dso *dso, struct symbol *sym)
 	up_write(&symbols->lock);
 }
 
+static struct symbol *dso__resolve_symbol_name(struct dso *dso, struct symbol *sym)
+{
+	if (!symbol_conf.lazy_load_symbols)
+		return sym;
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
-	return symbols__find(dso__symbols(dso), addr);
+	return dso__resolve_symbol_name(dso, symbols__find(dso__symbols(dso), addr));
 }
 
 struct symbol *dso__find_symbol_nocache(struct dso *dso, u64 addr)
 {
-	return symbols__find(dso__symbols(dso), addr);
+	return dso__resolve_symbol_name(dso, symbols__find(dso__symbols(dso), addr));
 }
 
 struct symbol *dso__next_symbol_by_name(struct dso *dso, size_t *idx)
@@ -991,7 +1048,7 @@ struct symbol *dso__find_symbol_by_name(struct dso *dso, const char *name, size_
 		*idx = SIZE_MAX;
 	if (!dso)
 		return NULL;
-	symbols = dso__symbols(dso);
+	symbols = dso__named_symbols(dso);
 	if (!symbols__sort_by_name_read_lock(symbols)) {
 		s = symbols__find_by_name(symbols->symbols_by_name,
 					  symbols->num_by_name,
@@ -1005,10 +1062,43 @@ struct symbol *dso__find_symbol_by_name(struct dso *dso, const char *name, size_
 	return s;
 }
 
-void dso__sort_by_name(struct dso *dso)
+/*
+ * Lazy names exist only in userspace DSOs. Checking that first avoids taking
+ * the DSO lock, which the callers that walk kernel symbols may hold.
+ */
+static bool dso__may_have_lazy_names(struct dso *dso)
+{
+	return symbol_conf.lazy_load_symbols && !dso__kernel(dso);
+}
+
+/*
+ * Symbols whose name cannot be read are named "[unknown]" rather than
+ * deleted, since address lookups can return them without the DSO lock.
+ *
+ * The DSO is marked eager even if it is not loaded yet, so that a load
+ * racing with the caller's walk does not add symbols without names.
+ */
+struct symbols *dso__named_symbols(struct dso *dso)
 {
 	struct symbols *symbols = dso__symbols(dso);
 
+	if (dso__may_have_lazy_names(dso)) {
+		mutex_lock(dso__lock(dso));
+		if (dso__lazy_names(dso) == DSO_LAZY_NAMES__PENDING) {
+			down_read(&symbols->lock);
+			dso__load_symbol_names(dso, symbols->symbols, symbols->cnt);
+			up_read(&symbols->lock);
+		}
+		dso__set_lazy_names(dso, DSO_LAZY_NAMES__EAGER);
+		mutex_unlock(dso__lock(dso));
+	}
+	return symbols;
+}
+
+void dso__sort_by_name(struct dso *dso)
+{
+	struct symbols *symbols = dso__named_symbols(dso);
+
 	down_read(&symbols->lock);
 	if (!symbols->sorted_by_name) {
 		up_read(&symbols->lock);
diff --git a/tools/perf/util/symbol.h b/tools/perf/util/symbol.h
index 8abf6ec05bd6..64fdf402d219 100644
--- a/tools/perf/util/symbol.h
+++ b/tools/perf/util/symbol.h
@@ -79,8 +79,16 @@ enum symbol_idle_kind {
 #define SYMBOL_FLAG_INLINED         (1 << 11)
 #define SYMBOL_FLAG_ANNOTATE2       (1 << 12)
 #define SYMBOL_FLAG_IFUNC_ALIAS     (1 << 13)
+#define SYMBOL_FLAG_LAZY_NAME       (1 << 14)
+#define SYMBOL_FLAG_NAME_ALLOCATED  (1 << 15)
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
 	/** Range of symbol [start, end). */
@@ -91,8 +99,12 @@ struct symbol {
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
 
 /**
@@ -132,6 +144,13 @@ void symbols__exit(struct symbols *symbols);
 void symbols__delete(struct symbols *symbols);
 void symbols__sort_read_lock(struct symbols *symbols) __acquires_shared(&symbols->lock);
 
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
@@ -252,6 +271,9 @@ void symbol__elf_init(void);
 int symbol__annotation_init(void);
 
 struct symbol *symbol__new(u64 start, u64 len, u8 binding, u8 type, const char *name);
+struct symbol *symbol__new_lazy(u64 start, u64 len, u8 binding, u8 type, u64 name_off);
+void symbol__set_loaded_name(struct symbol *sym, char *name);
+void symbol__set_unknown_name(struct symbol *sym);
 size_t __symbol__fprintf_symname_offs(const struct symbol *sym,
 				      const struct addr_location *al,
 				      bool unknown_as_addr,
@@ -282,10 +304,10 @@ int dso__load_bfd_symbols(struct dso *dso, const char *debugfile);
 int dso__load_sym(struct dso *dso, struct map *map, struct symsrc *syms_ss,
 		  struct symsrc *runtime_ss, int kmodule);
 int dso__synthesize_plt_symbols(struct dso *dso, struct symsrc *ss);
-
 char *dso__demangle_sym(struct dso *dso, int kmodule, const char *elf_name);
 
 int symbols__insert(struct symbols *symbols, struct symbol *sym);
+struct symbol *symbols__find(struct symbols *symbols, u64 ip);
 void symbols__fixup_duplicate(struct symbols *symbols);
 void symbols__fixup_end(struct symbols *symbols, bool is_kallsyms);
 
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

