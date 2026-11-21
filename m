From: Alireza Haghdoost <haghdoost@uber.com>
Date: Sat, 21 Nov 2026 08:41:05 -0800
Subject: [PATCH v8 5/7] perf script: Add --lazy-load-symbols to load symbol
 names lazily
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261121-perf-symbol-memory-send-v8-5-370561cbb5a7@uber.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=9524; i=haghdoost@uber.com;
 h=from:subject:message-id; bh=tlJIUoPpSy1y4jLw3r8xZ0bLXUYYFxAz4xSLlEjQLLA=;
 b=owEBiAJ3/ZANAwAIAVNlBDxl2ALYAcsmYgBrAcmvN1yLRClSHBY9PASGdgx7d8V+VlnUUYqXh
 kUlY2lRfgiJAk4EAAEIADkWIQS5+sFL3gX/8PrA0S1TZQQ8ZdgC2AUCawHJrxsUgAAAAAAEAA5t
 YW51MiwyLjUrMS4xMiwwLDMACgkQU2UEPGXYAtgUfA/2KC16mI9c+abIgwXFv7VBlcyxzXsO0xb
 o62sroH48Fb39fPZs6qqYP+FX0+owd1S65KBFvDfi2tO+1bF2yxkJA1TljxrLitC2/RFd2DNWAg
 EYce7ftD+8sSIDUKP1v25U0SrwD+JRUy3/aG25gaL371PMi5W3PZ7NQpvrIviPudgTr26sh+nQY
 Gl6fI3ixBDnMhDIEVF59feZ2D2ABT+h0+kj6l4lTWNd49GbFODgk+jUXHg1Jh6+laYBlEZoAjI7
 Jogl1ig7CUD17x9jrNQRnX4aPCrn4t1tBPiJA4UbHJH5TntFRmnJZka54qEaHOwHzJegTDXXlon
 dfNQF2MnS3oIfoQ2EdthycpeGIF3PGTSZVZxdM1YrQXCypP+a2AC9RcZNFloh5Z88Znz9wt18m5
 JY/4i84t4N6jPmuUXK70c++RkzMbdV6Kr+5K/lBhozWs4RFJYVcr7CSYSwe2wloLg/vjrhac71e
 DswwU33JVsAuZFmA7fBqoM3tv6bM03BCPb2Jqbs1F6a8xU0XUiByvYtp6jQksf8MG9YmPjpTIZ8
 XB8GqfLpmXYGqqixx9WUIihR97JHPDPCTSkpVvu8Dx7GhmF+Iv826ucuoEodd5MIvLEG3RiYaBy
 SQiNgpnxcHpGJWd/2gYLHgEd4rtpp9y9koF3CpuXCy20D8UrkJQ==
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

The loader still creates every symbol, so end fixup, duplicate
selection, PLT synthesis and IFUNC marking do not change. It uses lazy
names only if the string table is stored as is in the symbol table file,
since names are read from it with pread().

A few names are still read at load time: aliases that duplicate
selection can tell apart only by name, such as the .dynsym copies of
.symtab symbols, and IFUNC symbols, whose names PLT synthesis uses.

The offsets are only valid in the file that perf loaded, so the loader
records the file and its string tables with dso__set_lazy_file(), and
perf checks the file, as the previous patch describes, before it reads
names from it.

The kernel, modules, PPC64 .opd and .gnu_debugdata still load names
eagerly.

On a 45,073-sample callchain profile of a large C++ service (about 1M
symbols), lazy loading cuts max RSS from 327 MiB to 174 MiB, with
identical output. It saves little run time, 3.56 seconds against 3.75,
because one of the binaries exports most of its symbols, and duplicate
selection reads the names of each .dynsym copy and of the .symtab
symbol that it copies.

Signed-off-by: Alireza Haghdoost <haghdoost@uber.com>
---
 tools/perf/Documentation/perf-script.txt |  11 ++++
 tools/perf/builtin-script.c              |   2 +
 tools/perf/util/symbol-elf.c             | 108 +++++++++++++++++++++++++++----
 3 files changed, 110 insertions(+), 11 deletions(-)

diff --git a/tools/perf/Documentation/perf-script.txt b/tools/perf/Documentation/perf-script.txt
index f0228e784ced..4d04f5ecae8a 100644
--- a/tools/perf/Documentation/perf-script.txt
+++ b/tools/perf/Documentation/perf-script.txt
@@ -343,6 +343,17 @@ include::itrace.txt[]
 
         Default: 127
 
+--lazy-load-symbols::
+	Read and demangle userspace ELF symbol names only when perf needs
+	them. By default, perf reads every symbol name from each binary
+	referenced by a sample. This option reduces memory use when samples
+	reference only a small fraction of a large binary's symbols. The
+	names are read while perf script runs. If a binary cannot be opened
+	then, or no longer matches the one perf loaded, perf warns and shows
+	the symbols whose names it cannot read as unknown. A binary matches
+	if it has the same build ID and string table layout or, without a
+	build ID, if it is the same unchanged file.
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
index 468a0695809e..76f4aecb8632 100644
--- a/tools/perf/util/symbol-elf.c
+++ b/tools/perf/util/symbol-elf.c
@@ -1871,6 +1871,52 @@ void dso__load_symbol_names(struct dso *dso, struct symbol **syms, size_t nr)
 	}
 }
 
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
+				    read_symbol_names(dso, fd, pair, 2))
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
+		    read_symbol_names(dso, fd, &pos, 1))
+			return -1;
+	}
+	return 0;
+}
+
 static int
 dso__load_sym_internal(struct dso *dso, struct map *map, struct symsrc *syms_ss,
 		       struct symsrc *runtime_ss, int kmodule, int dynsym)
@@ -1888,11 +1934,21 @@ dso__load_sym_internal(struct dso *dso, struct map *map, struct symsrc *syms_ss,
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
+	bool lazy_allowed = symbol_conf.lazy_load_symbols && !dso__kernel(dso) &&
+			  !kmodule && syms_ss->type == dso__symtab_type(dso) &&
+			  syms_ss->type != DSO_BINARY_TYPE__GNU_DEBUGDATA &&
+			  !runtime_ss->opdsec;
+	bool lazy_names = false;
+	GElf_Shdr strshdr;
 
 	if (kmap && !kmaps)
 		return -1;
@@ -1928,6 +1984,17 @@ dso__load_sym_internal(struct dso *dso, struct map *map, struct symsrc *syms_ss,
 	if (symstrs == NULL)
 		goto out_elf_end;
 
+	/*
+	 * Names are read with pread(), so the string table must be stored as
+	 * is, and later reads must find it in the same place.
+	 */
+	if (lazy_allowed && gelf_getshdr(sec, &strshdr) &&
+	    strshdr.sh_type == SHT_STRTAB && !(strshdr.sh_flags & SHF_COMPRESSED) &&
+	    !dso__set_lazy_file(dso, syms_ss->fd, dynsym,
+				&(struct dso_lazy_strtab){ shdr.sh_link, strshdr.sh_offset,
+							   strshdr.sh_size }))
+		lazy_names = true;
+
 	sec_strndx = elf_getscn(runtime_ss->elf, runtime_ss->ehdr.e_shstrndx);
 	if (sec_strndx == NULL)
 		goto out_elf_end;
@@ -2166,16 +2233,24 @@ dso__load_sym_internal(struct dso *dso, struct map *map, struct symsrc *syms_ss,
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
 
@@ -2186,6 +2261,10 @@ dso__load_sym_internal(struct dso *dso, struct map *map, struct symsrc *syms_ss,
 	}
 	dso__put(curr_dso);
 	elf_phdr_cache__exit(&phdr_cache);
+
+	if (lazy_names)
+		pr_debug("%s: %d %s symbols with lazy names\n", dso__long_name(dso),
+			 nr_lazy, dynsym ? ".dynsym" : ".symtab");
 	return nr;
 out_elf_end:
 	dso__put(curr_dso);
@@ -2256,9 +2335,16 @@ int dso__load_sym(struct dso *dso, struct map *map, struct symsrc *syms_ss,
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

-- 
Git-157)

