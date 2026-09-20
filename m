From: Alireza Haghdoost <haghdoost@uber.com>
Date: Sat, 19 Sep 2026 19:33:58 -0700
Subject: [PATCH v2 3/4] perf script: Add --lazy-load-symbols for lazy
 symbol loading
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260919-perf-symbol-memory-send-v2-3-495b8f00ad7c@uber.com>
References: <20260919-perf-symbol-memory-send-v2-0-495b8f00ad7c@uber.com>
In-Reply-To: <20260919-perf-symbol-memory-send-v2-0-495b8f00ad7c@uber.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=47164; i=haghdoost@uber.com;
 h=from:subject:message-id; bh=rCbOKMTnLxkV5HKPcltZ+lN7k6HFlJymYSQgS/dh3XI=;
 b=owEBiQJ2/ZANAwAIAVNlBDxl2ALYAcsmYgBqr0Y3q8b5PLoUoWdR+RpE2GMtInFd9Ulb1rV2g
 LHwWK2YyNuJAk8EAAEIADkWIQS5+sFL3gX/8PrA0S1TZQQ8ZdgC2AUCaq9GNxsUgAAAAAAEAA5t
 YW51MiwyLjUrMS4xMiwwLDMACgkQU2UEPGXYAtj5+g/+KWoA2YR3wi5Irbccl6LUqs/yZQ9XdBe
 m4a/I/B/rBeAEf4dgfX0tjjT2JRwDPtZQj1atWED2FncMf88xVuVj1UpOO85lwLBNgY4ycXy0Bn
 6T+W6ZBvDaPsdIUWemhPhOwNmKZs7UJtascQqodMMqVXwlzFFLofCGQqr5YCCrmpAC3GqEqScI6
 jdVlWbQWFzSAOaPnq7LFGkfhjBjqDnNPpnqbknv8GtLvPzbUCUGFGOan/GWUQ0gVgr9/BybWSNH
 T+V3/sKVcuSCJbRanH4MDf6ucmYdS8gGud2N8a2KDh5zVHciZnIdgOGJ+iw9oDMXblPaw6a56NB
 3U7SFepyXxfTVR5VHv3uk662a7ojZaZ4iSQNXZN/YWW9gl6mXmR5AUCHqbDwyZkRMWLKxRv4Tbx
 mHDJjrtJw7mSHrxRuGaeJBFd2fdaiBgPRgHe6GbNJq6zTX75PdT8kF3CcP8l7KIcMgylPkDgQVK
 nEmB87wckB67HqA5QzxJP6L9nHcKRPChQcVPkLrEkrW4uwcENKXzdOdUDDWRGFc0NC3uHfI1E5P
 Nx4R7Zm3sX+NjYM9x/nMYVYvDYl0zAxCc+LIqfniHijfmJjPYGTy+R6FElWbzZSWAkz0EKf1IGI
 QHwCZ1GUKJgB3N+5qRiaOL4x1O9/Bc+ltjKjsH9lTWZfdGDSZx3Q=
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

Signed-off-by: Alireza Haghdoost <haghdoost@uber.com>
---
 tools/perf/Documentation/perf-script.txt    |  34 +-
 tools/perf/arch/powerpc/util/sym-handling.c |   5 +-
 tools/perf/builtin-script.c                 |   4 +-
 tools/perf/tests/symbol-bytes.c             | 139 ++++++
 tools/perf/util/dso.c                       |  63 ++-
 tools/perf/util/dso.h                       |  49 ++
 tools/perf/util/map.c                       |  30 +-
 tools/perf/util/symbol-elf.c                | 667 ++++++++++++++++++++++++++++
 tools/perf/util/symbol-minimal.c            |  17 +
 tools/perf/util/symbol.c                    |  58 ++-
 tools/perf/util/symbol.h                    |   6 +-
 tools/perf/util/symbol_conf.h               |   1 +
 12 files changed, 1029 insertions(+), 44 deletions(-)

diff --git a/tools/perf/Documentation/perf-script.txt b/tools/perf/Documentation/perf-script.txt
index 217167a2e56b..136d773778da 100644
--- a/tools/perf/Documentation/perf-script.txt
+++ b/tools/perf/Documentation/perf-script.txt
@@ -412,15 +412,33 @@ include::itrace.txt[]
 
         Default: 127
 
+--lazy-load-symbols::
+	Resolve symbols lazily instead of eagerly loading the full
+	symbol table of every DSO that appears in a sample. A compact
+	sorted index is built per DSO and only the addresses that appear
+	in samples are materialized into symbols, with names read from the
+	file's string table through the DSO data cache at lookup time. This
+	sharply reduces memory
+	(and usually time) for profiles of large binaries where only a
+	small fraction of the symbol table is referenced. This applies only
+	to userspace ELF DSOs; kernel DSOs and modules always load eagerly.
+	Operations that look up a symbol by name materialize the remainder
+	of that DSO's index first to preserve name-lookup behavior.
+	Output may differ from the default loader for some targets
+	(e.g. PPC64 .opd or .gnu_debugdata). Default: off.
+
 --max-symbol-bytes::
-	Limit the bytes held in struct symbol allocations for DSOs on the
-	libelf symbol-loader path: userspace DSOs, vmlinux-as-ELF, and kernel
-	modules. This is not a cap on all symbol memory or RSS: symbols from
-	kallsyms, JIT maps, and libbfd are counted but not capped. Accepts a
-	size with a B/K/M/G suffix (e.g. 128M). When the budget is exceeded,
-	the ELF loader stops adding symbols; addresses not covered by symbols
-	already loaded are then printed as [unknown]. A warning is printed.
-	Default: 0 (unlimited).
+	Limit the bytes held in struct symbol allocations (and, with
+	--lazy-load-symbols, the lazy index) for DSOs on the ELF symbol
+	loader path -- userspace DSOs plus vmlinux-as-ELF and kernel
+	modules. This is not a cap on all symbol memory or RSS: symbols
+	from kallsyms, JIT maps, and libbfd are counted but not capped.
+	Accepts a size with a B/K/M/G suffix (e.g. 128M).
+	When the budget is exceeded, the ELF loader stops adding symbols;
+	addresses not covered by the symbols already loaded are then printed
+	as [unknown]. A warning is printed. This is a safety net independent of
+	--lazy-load-symbols and can be used with or without it. Default: 0
+	(unlimited).
 
 --ns::
 	Use 9 decimal places when displaying time (i.e. show the nanoseconds)
diff --git a/tools/perf/arch/powerpc/util/sym-handling.c b/tools/perf/arch/powerpc/util/sym-handling.c
index 947bfad7aa59..ac8fc787e95d 100644
--- a/tools/perf/arch/powerpc/util/sym-handling.c
+++ b/tools/perf/arch/powerpc/util/sym-handling.c
@@ -10,10 +10,9 @@
 #include "probe-event.h"
 #include "probe-file.h"
 
-int arch__choose_best_symbol(struct symbol *syma,
-			     struct symbol *symb __maybe_unused)
+int arch__choose_best_symbol(const char *syma_name)
 {
-	char *sym = syma->name;
+	const char *sym = syma_name;
 
 #if !defined(_CALL_ELF) || _CALL_ELF != 2
 	/* Skip over any initial dot */
diff --git a/tools/perf/builtin-script.c b/tools/perf/builtin-script.c
index 017b39ed6a21..5bdf4a7895df 100644
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
@@ -4177,6 +4177,8 @@ int cmd_script(int argc, const char **argv)
 	OPT_CALLBACK(0, "max-symbol-bytes", &symbol_conf.max_symbol_bytes,
 		     "size", "Limit bytes for ELF struct symbol (e.g. 128M; 0=unlimited)",
 		     parse_max_symbol_bytes),
+	OPT_BOOLEAN(0, "lazy-load-symbols", &symbol_conf.lazy_load_symbols,
+		    "Resolve symbols lazily instead of loading full symtabs"),
 	OPT_BOOLEAN(0, "reltime", &reltime, "Show time stamps relative to start"),
 	OPT_BOOLEAN(0, "deltatime", &deltatime, "Show time stamps relative to previous event"),
 	OPT_BOOLEAN('I', "show-info", &show_full_info,
diff --git a/tools/perf/tests/symbol-bytes.c b/tools/perf/tests/symbol-bytes.c
index 4a4740daa5f5..e5e2e6b9db97 100644
--- a/tools/perf/tests/symbol-bytes.c
+++ b/tools/perf/tests/symbol-bytes.c
@@ -1,11 +1,17 @@
 // SPDX-License-Identifier: GPL-2.0
+#include <fcntl.h>
 #include <limits.h>
 #include <pthread.h>
 #include <stdint.h>
 #include <stdlib.h>
 #include <string.h>
+#include <unistd.h>
+#include <linux/kernel.h>
+#include <linux/zalloc.h>
 
 #include "debug.h"
+#include "dso.h"
+#include "map.h"
 #include "symbol.h"
 #include "symbol_conf.h"
 #include "tests.h"
@@ -131,9 +137,142 @@ static int test__symbol_bytes_reservation(struct test_suite *test __maybe_unused
 	return ret;
 }
 
+static int test__symbol_bytes_duplicate_selection(struct test_suite *test __maybe_unused,
+						  int subtest __maybe_unused)
+{
+	struct duplicate_case {
+		u64 a_size;
+		u8 a_type;
+		u8 a_binding;
+		const char *a_name;
+		u64 b_size;
+		u8 b_type;
+		u8 b_binding;
+		const char *b_name;
+		int expected;
+	} cases[] = {
+		{ 1, STT_FUNC, STB_GLOBAL, "a", 0, STT_FUNC, STB_GLOBAL, "b", SYMBOL_A },
+		{ 1, STT_NOTYPE, STB_GLOBAL, "a", 1, STT_FUNC, STB_GLOBAL, "b", SYMBOL_B },
+		{ 1, STT_FUNC, STB_WEAK, "a", 1, STT_FUNC, STB_GLOBAL, "b", SYMBOL_B },
+		{ 1, STT_FUNC, STB_GLOBAL, "a", 1, STT_FUNC, STB_LOCAL, "b", SYMBOL_A },
+		{ 1, STT_FUNC, STB_GLOBAL, "name", 1, STT_FUNC, STB_GLOBAL, "_name", SYMBOL_A },
+		{ 1, STT_FUNC, STB_GLOBAL, "a", 1, STT_FUNC, STB_GLOBAL, "long", SYMBOL_B },
+	};
+	size_t i;
+
+	for (i = 0; i < ARRAY_SIZE(cases); i++) {
+		struct duplicate_case *c = &cases[i];
+
+		if (symbol__choose_best(c->a_size, c->a_type, c->a_binding, c->a_name,
+					c->b_size, c->b_type, c->b_binding, c->b_name) !=
+		    c->expected)
+			return TEST_FAIL;
+	}
+	return TEST_OK;
+}
+
+#ifdef HAVE_LIBELF_SUPPORT
+static int test__symbol_bytes_lazy_name_lookup(struct test_suite *test __maybe_unused,
+					       int subtest __maybe_unused)
+{
+	static const char names[] = "first\0second\0";
+	unsigned long saved_max = symbol_conf.max_symbol_bytes;
+	size_t baseline = symbol__bytes_used();
+	char path[] = "/tmp/perf-lazy-names-XXXXXX";
+	struct dso_ondemand *od = NULL;
+	struct symbol *sym;
+	struct dso *dso = NULL;
+	struct map *map = NULL;
+	struct rb_node *node;
+	int nr_symbols = 0;
+	int ret = TEST_FAIL;
+	int fd = -1;
+
+	symbol_conf.max_symbol_bytes = 0;
+	fd = mkstemp(path);
+	if (fd < 0 || write(fd, names, sizeof(names)) != (ssize_t)sizeof(names))
+		goto out;
+	close(fd);
+	fd = -1;
+
+	dso = dso__new("/not/the/symbol/source");
+	od = zalloc(sizeof(*od));
+	if (!dso || !od)
+		goto out;
+	od->sorted = zalloc(2 * sizeof(*od->sorted));
+	od->data_dso = dso__new(path);
+	if (!od->sorted || !od->data_dso ||
+	    dso__data_set_path(od->data_dso, path) < 0)
+		goto out;
+	dso__set_binary_type(od->data_dso, DSO_BINARY_TYPE__SYSTEM_PATH_DSO);
+	od->strtab_size = sizeof(names);
+	od->nr_sorted = 2;
+	od->nr_alloc = 2;
+	od->sorted[0] = (struct sym_idx) {
+		.start = 0x10,
+		.end = 0x20,
+		.name_off = 0,
+		.binding = STB_GLOBAL,
+		.type = STT_FUNC,
+	};
+	od->sorted[1] = (struct sym_idx) {
+		.start = 0x20,
+		.end = 0x30,
+		.name_off = sizeof("first"),
+		.binding = STB_GLOBAL,
+		.type = STT_FUNC,
+	};
+	if (!symbol__try_account_bytes(od->nr_alloc * sizeof(*od->sorted)))
+		goto out;
+	dso__set_ondemand(dso, od);
+	od = NULL;
+	dso__set_loaded(dso);
+	map = map__new2(0, dso);
+	if (!map)
+		goto out;
+
+	sym = map__find_symbol(map, 0x11);
+	if (!sym || strcmp(sym->name, "first"))
+		goto out;
+
+	dso__data_close(dso__ondemand(dso)->data_dso);
+	sym = map__find_symbol_by_name(map, "second");
+	if (!sym || strcmp(sym->name, "second") || dso__ondemand(dso))
+		goto out;
+
+	for (node = rb_first_cached(dso__symbols(dso)); node; node = rb_next(node))
+		nr_symbols++;
+	if (nr_symbols != 2)
+		goto out;
+	ret = TEST_OK;
+out:
+	if (fd >= 0)
+		close(fd);
+	if (map)
+		map__put(map);
+	if (dso)
+		dso__put(dso);
+	if (od) {
+		if (od->data_dso)
+			dso__put(od->data_dso);
+		free(od->sorted);
+		free(od);
+	}
+	unlink(path);
+	symbol_conf.max_symbol_bytes = saved_max;
+	if (symbol__bytes_used() != baseline)
+		ret = TEST_FAIL;
+	return ret;
+}
+#endif
+
 static struct test_case tests__symbol_bytes[] = {
 	TEST_CASE("Long name accounting", symbol_bytes_long_name),
 	TEST_CASE("Concurrent strict reservations", symbol_bytes_reservation),
+	TEST_CASE("Shared duplicate selection", symbol_bytes_duplicate_selection),
+#ifdef HAVE_LIBELF_SUPPORT
+	TEST_CASE("Lazy address and name lookup", symbol_bytes_lazy_name_lookup),
+#endif
 	{ .name = NULL, }
 };
 
diff --git a/tools/perf/util/dso.c b/tools/perf/util/dso.c
index 42bfe30a3b51..af0440cb8449 100644
--- a/tools/perf/util/dso.c
+++ b/tools/perf/util/dso.c
@@ -526,8 +526,11 @@ static void dso__list_add(struct dso *dso) EXCLUSIVE_LOCKS_REQUIRED(_dso__data_o
 #ifdef REFCNT_CHECKING
 	dso__data(dso)->dso = dso__get(dso);
 #endif
-	/* Assume the dso is part of dsos, hence the optional reference count above. */
-	assert(dso__dsos(dso));
+	/*
+	 * Most data DSOs belong to a dsos collection. Private data sources,
+	 * such as a lazy symbol index's split-debuginfo file, are instead kept
+	 * alive by their owner.
+	 */
 	dso__data_open_cnt++;
 }
 
@@ -572,16 +575,22 @@ char *dso__filename_with_chroot(const struct dso *dso, const char *filename)
 static char *dso__get_filename(struct dso *dso, const char *root_dir,
 			       bool *decomp)
 {
-	char *name = malloc(PATH_MAX);
+	char *name;
 
 	*decomp = false;
 
-	if (name == NULL)
-		return NULL;
-
-	if (dso__read_binary_type_filename(dso, dso__binary_type(dso),
-					    root_dir, name, PATH_MAX))
-		goto out;
+	if (dso__data(dso)->path) {
+		name = strdup(dso__data(dso)->path);
+		if (!name)
+			return NULL;
+	} else {
+		name = malloc(PATH_MAX);
+		if (!name)
+			return NULL;
+		if (dso__read_binary_type_filename(dso, dso__binary_type(dso),
+						    root_dir, name, PATH_MAX))
+			goto out;
+	}
 
 	if (!is_regular_file(name)) {
 		struct stat st;
@@ -807,6 +816,17 @@ void dso__data_close(struct dso *dso)
 	mutex_unlock(dso__data_open_lock());
 }
 
+int dso__data_set_path(struct dso *dso, const char *path)
+{
+	char *new_path = strdup(path);
+
+	if (!new_path)
+		return -ENOMEM;
+	free(dso__data(dso)->path);
+	dso__data(dso)->path = new_path;
+	return 0;
+}
+
 static void try_to_open_dso(struct dso *dso, struct machine *machine)
 	EXCLUSIVE_LOCKS_REQUIRED(_dso__data_open_lock)
 {
@@ -1674,6 +1694,27 @@ void dso__set_sorted_by_name(struct dso *dso)
 	RC_CHK_ACCESS(dso)->sorted_by_name = true;
 }
 
+void dso__reset_symbol_names(struct dso *dso)
+{
+	zfree(&RC_CHK_ACCESS(dso)->symbol_names);
+	RC_CHK_ACCESS(dso)->symbol_names_len = 0;
+	RC_CHK_ACCESS(dso)->sorted_by_name = false;
+}
+
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
@@ -1755,7 +1796,11 @@ void dso__delete(struct dso *dso)
 
 	dso__data_close(dso);
 	auxtrace_cache__free(RC_CHK_ACCESS(dso)->auxtrace_cache);
+	mutex_lock(dso__lock(dso));
+	dso__free_ondemand(dso);
+	mutex_unlock(dso__lock(dso));
 	dso_cache__free(dso);
+	zfree(&RC_CHK_ACCESS(dso)->data.path);
 	dso__free_a2l(dso);
 	dso__free_libdw(dso);
 	dso__free_symsrc_filename(dso);
diff --git a/tools/perf/util/dso.h b/tools/perf/util/dso.h
index 55c4aaa53c38..301997642e6a 100644
--- a/tools/perf/util/dso.h
+++ b/tools/perf/util/dso.h
@@ -264,6 +264,7 @@ struct dso_data {
 #ifdef REFCNT_CHECKING
 	struct dso	 *dso;
 #endif
+	char		 *path;
 	int		 fd;
 	int		 status;
 	u32		 status_seen;
@@ -282,6 +283,27 @@ struct dso_bpf_prog {
 	struct perf_env	*env;
 };
 
+struct sym_idx {
+	u64	start;	/* adjusted st_value (same space as sym->start) */
+	u64	end;	/* start + st_size, or next start if st_size==0 */
+	u32	name_off; /* symbol's st_name: offset into the strtab */
+	u8	binding;
+	u8	type;
+	u8	flags;
+};
+
+#define SYM_IDX_FLAG_IFUNC_ALIAS	(1 << 0)
+#define SYM_IDX_FLAG_MATERIALIZED	(1 << 1)
+
+struct dso_ondemand {
+	struct dso	*data_dso;	/* exact symbol source, using the DSO data cache */
+	u64		 strtab_offset;	/* file offset of strtab section */
+	u64		 strtab_size;
+	struct sym_idx	*sorted;
+	u32		 nr_sorted;	/* deduped count */
+	u32		 nr_alloc;	/* allocated count, for accounting */
+};
+
 struct auxtrace_cache;
 
 DECLARE_RC_STRUCT(dso) {
@@ -308,6 +330,7 @@ DECLARE_RC_STRUCT(dso) {
 	char		 *symsrc_filename;
 	struct nsinfo	*nsinfo;
 	struct auxtrace_cache *auxtrace_cache;
+	struct dso_ondemand *ondemand;
 	union { /* Tool specific area */
 		void	 *priv;
 		u64	 db_id;
@@ -448,6 +471,16 @@ static inline void dso__set_auxtrace_cache(struct dso *dso, struct auxtrace_cach
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
@@ -823,6 +856,21 @@ int dso__read_binary_type_filename(const struct dso *dso, enum dso_binary_type t
 				   const char *root_dir, char *filename, size_t size);
 bool is_kernel_module(const char *pathname, int cpumode);
 bool dso__needs_decompress(struct dso *dso);
+struct symbol *dso__find_symbol_ondemand(struct dso *dso, u64 addr)
+	EXCLUSIVE_LOCKS_REQUIRED(dso__lock(dso));
+struct symbol *dso__find_symbol_ondemand_exact(struct dso *dso, u64 addr)
+	EXCLUSIVE_LOCKS_REQUIRED(dso__lock(dso));
+int dso__materialize_symbols_ondemand(struct dso *dso)
+	EXCLUSIVE_LOCKS_REQUIRED(dso__lock(dso));
+const char *dso__read_ondemand_symbol_name(struct dso *data_dso,
+					   u64 strtab_offset, u64 strtab_size,
+					   u64 name_off, char *buf,
+					   size_t buflen, char **to_free,
+					   unsigned int *nr_reads);
+void dso__free_ondemand(struct dso *dso)
+	EXCLUSIVE_LOCKS_REQUIRED(dso__lock(dso));
+void dso__reset_symbol_names(struct dso *dso)
+	EXCLUSIVE_LOCKS_REQUIRED(dso__lock(dso));
 int dso__decompress_kmodule_fd(struct dso *dso, const char *name);
 int dso__decompress_kmodule_path(struct dso *dso, const char *name,
 				 char *pathname, size_t len);
@@ -896,6 +944,7 @@ bool dso__data_get_fd(struct dso *dso, struct machine *machine, int *fd)
 	EXCLUSIVE_TRYLOCK_FUNCTION(true, _dso__data_open_lock);
 void dso__data_put_fd(struct dso *dso) UNLOCK_FUNCTION(_dso__data_open_lock);
 void dso__data_close(struct dso *dso) LOCKS_EXCLUDED(_dso__data_open_lock);
+int dso__data_set_path(struct dso *dso, const char *path);
 
 int dso__data_file_size(struct dso *dso, struct machine *machine);
 off_t dso__data_size(struct dso *dso, struct machine *machine);
diff --git a/tools/perf/util/map.c b/tools/perf/util/map.c
index 41cdddc987ee..c44698bc3a65 100644
--- a/tools/perf/util/map.c
+++ b/tools/perf/util/map.c
@@ -382,10 +382,28 @@ int map__load(struct map *map)
 
 struct symbol *map__find_symbol(struct map *map, u64 addr)
 {
+	struct dso *dso;
+	struct symbol *sym;
+
 	if (map__load(map) < 0)
 		return NULL;
 
-	return dso__find_symbol(map__dso(map), addr);
+	dso = map__dso(map);
+	if (dso__ondemand(dso)) {
+		/*
+		 * On-demand lookup may materialize and insert a symbol.  Keep
+		 * both the lookup and insertion under the DSO lock so another
+		 * thread cannot traverse or modify the rb-tree concurrently.
+		 */
+		mutex_lock(dso__lock(dso));
+		sym = dso__find_symbol(dso, addr);
+		if (!sym)
+			sym = dso__find_symbol_ondemand(dso, addr);
+		mutex_unlock(dso__lock(dso));
+	} else {
+		sym = dso__find_symbol(dso, addr);
+	}
+	return sym;
 }
 
 struct symbol *map__find_symbol_by_name_idx(struct map *map, const char *name, size_t *idx)
@@ -396,6 +414,16 @@ struct symbol *map__find_symbol_by_name_idx(struct map *map, const char *name, s
 		return NULL;
 
 	dso = map__dso(map);
+	if (dso__ondemand(dso)) {
+		mutex_lock(dso__lock(dso));
+		/*
+		 * Name lookup requires a complete name-sorted array. Preserve
+		 * that API by materializing the remaining address index first.
+		 * An explicit symbol-byte limit can leave a partial set.
+		 */
+		dso__materialize_symbols_ondemand(dso);
+		mutex_unlock(dso__lock(dso));
+	}
 	dso__sort_by_name(dso);
 
 	return dso__find_symbol_by_name(dso, name, idx);
diff --git a/tools/perf/util/symbol-elf.c b/tools/perf/util/symbol-elf.c
index 2f7ea1499cbf..094d5ffaa1f0 100644
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
@@ -1544,6 +1577,612 @@ static int dso__process_kernel_symbol(struct dso *dso, struct map *map,
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
+		return 0; /* fall back to the eager loader's per-symbol budget */
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
+	od->nr_alloc = count;	/* allocated; the deduped count may shrink */
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
+		/*
+		 * Sort equal-start aliases in original symtab order to match
+		 * rb-tree insertion order. Restore st_name after sorting.
+		 */
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
+	/*
+	 * Match the eager loader's ordering: fill zero-sized ranges before
+	 * choosing among equal-start aliases, so the size preference sees
+	 * the same synthesized lengths as symbols__fixup_duplicate().
+	 */
+	for (i = 0; i < count; i++) {
+		u64 size = od->sorted[i].end; /* was st_size */
+
+		if (size > 0)
+			od->sorted[i].end = od->sorted[i].start + size;
+		else if (i + 1 < count)
+			od->sorted[i].end = od->sorted[i + 1].start;
+		else
+			od->sorted[i].end = roundup(od->sorted[i].start, 4096) + 4096;
+	}
+
+	if (!symbol_conf.allow_aliases) {
+		u32 out = 0;
+
+		for (i = 0; i < count; i++) {
+			u32 best = i;
+			const char *na = NULL, *nb;
+			char *da = NULL, *db;
+			bool has_ifunc = od->sorted[i].type == STT_GNU_IFUNC;
+
+			na = elf_strptr(elf, shdr.sh_link,
+					od->sorted[best].name_off);
+			if (na) {
+				da = dso__demangle_sym(dso, 0, na);
+				if (da)
+					na = da;
+			}
+
+			for (j = i + 1; j < count &&
+			     od->sorted[j].start == od->sorted[i].start; j++) {
+				int choice;
+
+				has_ifunc |= od->sorted[j].type == STT_GNU_IFUNC;
+				nb = elf_strptr(elf, shdr.sh_link,
+						od->sorted[j].name_off);
+				if (!na || !nb)
+					continue;
+
+				db = dso__demangle_sym(dso, 0, nb);
+				if (db)
+					nb = db;
+
+				choice = symbol__choose_best(
+						od->sorted[best].end -
+						od->sorted[best].start,
+						od->sorted[best].type,
+						od->sorted[best].binding, na,
+						od->sorted[j].end -
+						od->sorted[j].start,
+						od->sorted[j].type,
+						od->sorted[j].binding, nb);
+				if (choice == SYMBOL_B) {
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
+			if (has_ifunc && od->sorted[out - 1].type != STT_GNU_IFUNC)
+				od->sorted[out - 1].flags |= SYM_IDX_FLAG_IFUNC_ALIAS;
+			i = j - 1; /* skip past all aliases of this start */
+		}
+
+		if (out < count) {
+			struct sym_idx *shrunk;
+
+			shrunk = realloc(od->sorted, out * sizeof(*od->sorted));
+			if (shrunk) {
+				od->sorted = shrunk;
+				symbol__unaccount_bytes((od->nr_alloc - out) *
+						       sizeof(*od->sorted));
+				od->nr_alloc = out;
+			}
+		}
+		count = out;
+	}
+
+	/*
+	 * The interval binary search requires non-overlapping ranges.  In
+	 * the default deduplicated mode, prefer the symbol with the nearest
+	 * preceding start when an ELF st_size overlaps the next symbol.
+	 */
+	if (!symbol_conf.allow_aliases) {
+		for (i = 0; i + 1 < count; i++) {
+			if (od->sorted[i].end > od->sorted[i + 1].start)
+				od->sorted[i].end = od->sorted[i + 1].start;
+		}
+	}
+
+	/*
+	 * Keep an exact-path data DSO for the symbol source.  This may differ
+	 * from the runtime image (for example, split debuginfo), so using the
+	 * primary DSO's data cache could read an unrelated string-table offset.
+	 * The standard DSO data cache manages descriptor eviction and reopening.
+	 */
+	od->data_dso = dso__new(syms_ss->name);
+	if (!od->data_dso ||
+	    dso__data_set_path(od->data_dso, syms_ss->name) < 0)
+		goto out_decline_source;
+	dso__set_binary_type(od->data_dso, DSO_BINARY_TYPE__SYSTEM_PATH_DSO);
+	dso__set_nsinfo(od->data_dso, nsinfo__get(dso__nsinfo(dso)));
+
+	/*
+	 * Open the managed source while eager fallback is still possible.
+	 * A later failure would otherwise turn materialization into a miss.
+	 */
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
+static struct symbol *dso__materialize_symbol_ondemand(struct dso *dso, u32 pos)
+	EXCLUSIVE_LOCKS_REQUIRED(dso__lock(dso))
+{
+	struct dso_ondemand *od = dso__ondemand(dso);
+	struct sym_idx *idx = &od->sorted[pos];
+	const char *name;
+	char namebuf[1024];
+	char *name_heap = NULL;
+	char *demangled;
+	bool budget_exceeded;
+	struct symbol *s = NULL;
+
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
+				idx->binding, idx->type, name, &budget_exceeded);
+	free(demangled);
+	free(name_heap);
+	if (!s && budget_exceeded)
+		symbol_budget_warning();
+	if (s) {
+		if (idx->flags & SYM_IDX_FLAG_IFUNC_ALIAS)
+			symbol__set_ifunc_alias(s, true);
+		dso__reset_symbol_names(dso);
+		__symbols__insert(dso__symbols(dso), s);
+		idx->flags |= SYM_IDX_FLAG_MATERIALIZED;
+	}
+	return s;
+}
+
+int dso__materialize_symbols_ondemand(struct dso *dso)
+{
+	struct dso_ondemand *od = dso__ondemand(dso);
+	u32 i;
+
+	if (!od)
+		return 0;
+	for (i = 0; i < od->nr_sorted; i++) {
+		if (od->sorted[i].flags & SYM_IDX_FLAG_MATERIALIZED)
+			continue;
+		if (!dso__materialize_symbol_ondemand(dso, i))
+			return -1;
+	}
+	dso__free_ondemand(dso);
+	return 0;
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
+		return idx ? dso__materialize_symbol_ondemand(dso, idx - od->sorted) : NULL;
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
+			return dso__materialize_symbol_ondemand(dso, mid);
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
+			return dso__materialize_symbol_ondemand(dso, mid);
+	}
+	return dso__materialize_symbol_ondemand(dso, lo);
+}
+
 static int
 dso__load_sym_internal(struct dso *dso, struct map *map, struct symsrc *syms_ss,
 		       struct symsrc *runtime_ss, int kmodule, int dynsym)
@@ -1656,6 +2295,34 @@ dso__load_sym_internal(struct dso *dso, struct map *map, struct symsrc *syms_ss,
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
index 0a71d1463952..245aed6b2788 100644
--- a/tools/perf/util/symbol-minimal.c
+++ b/tools/perf/util/symbol-minimal.c
@@ -373,6 +373,23 @@ void symbol__elf_init(void)
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
+int dso__materialize_symbols_ondemand(struct dso *dso __maybe_unused)
+{
+	return 0;
+}
+
 bool filename__has_section(const char *filename __maybe_unused, const char *sec __maybe_unused)
 {
 	return false;
diff --git a/tools/perf/util/symbol.c b/tools/perf/util/symbol.c
index 32eef666f748..3ca9655c36fd 100644
--- a/tools/perf/util/symbol.c
+++ b/tools/perf/util/symbol.c
@@ -143,72 +143,80 @@ int __weak arch__compare_symbol_names_n(const char *namea, const char *nameb,
 	return strncmp(namea, nameb, n);
 }
 
-int __weak arch__choose_best_symbol(struct symbol *syma,
-				    struct symbol *symb __maybe_unused)
+int __weak arch__choose_best_symbol(const char *syma_name)
 {
 	/* Avoid "SyS" kernel syscall aliases */
-	if (strlen(syma->name) >= 3 && !strncmp(syma->name, "SyS", 3))
+	if (strlen(syma_name) >= 3 && !strncmp(syma_name, "SyS", 3))
 		return SYMBOL_B;
-	if (strlen(syma->name) >= 10 && !strncmp(syma->name, "compat_SyS", 10))
+	if (strlen(syma_name) >= 10 && !strncmp(syma_name, "compat_SyS", 10))
 		return SYMBOL_B;
 
 	return SYMBOL_A;
 }
 
-static int choose_best_symbol(struct symbol *syma, struct symbol *symb)
+int symbol__choose_best(u64 a_size, u8 a_type, u8 a_binding,
+			const char *a_name,
+			u64 b_size, u8 b_type, u8 b_binding,
+			const char *b_name)
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
+	return arch__choose_best_symbol(a_name);
+}
+
+static int choose_best_symbol(struct symbol *syma, struct symbol *symb)
+{
+	return symbol__choose_best(syma->end - syma->start,
+				   symbol__type(syma), symbol__binding(syma), syma->name,
+				   symb->end - symb->start,
+				   symbol__type(symb), symbol__binding(symb), symb->name);
 }
 
 void symbols__fixup_duplicate(struct rb_root_cached *symbols)
@@ -1989,11 +1997,19 @@ int dso__load(struct dso *dso, struct map *map)
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
index f7331edf0b71..99563c9ff610 100644
--- a/tools/perf/util/symbol.h
+++ b/tools/perf/util/symbol.h
@@ -233,6 +233,10 @@ size_t symbol__bytes_used(void);
 void symbol__account_bytes(size_t bytes);
 bool symbol__try_account_bytes(size_t bytes);
 void symbol__unaccount_bytes(size_t bytes);
+int symbol__choose_best(u64 a_size, u8 a_type, u8 a_binding,
+			const char *a_name,
+			u64 b_size, u8 b_type, u8 b_binding,
+			const char *b_name);
 size_t __symbol__fprintf_symname_offs(const struct symbol *sym,
 				      const struct addr_location *al,
 				      bool unknown_as_addr,
@@ -308,7 +312,7 @@ const char *arch__normalize_symbol_name(const char *name);
 int arch__compare_symbol_names(const char *namea, const char *nameb);
 int arch__compare_symbol_names_n(const char *namea, const char *nameb,
 				 unsigned int n);
-int arch__choose_best_symbol(struct symbol *syma, struct symbol *symb);
+int arch__choose_best_symbol(const char *syma_name);
 
 enum symbol_tag_include {
 	SYMBOL_TAG_INCLUDE__NONE = 0,
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
Git-157)

