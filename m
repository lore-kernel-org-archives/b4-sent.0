From: Alireza Haghdoost <haghdoost@uber.com>
Date: Sat, 21 Nov 2026 08:41:04 -0800
Subject: [PATCH v8 4/7] perf symbols: Check the file before reading lazy
 symbol names
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261121-perf-symbol-memory-send-v8-4-370561cbb5a7@uber.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=11684; i=haghdoost@uber.com;
 h=from:subject:message-id; bh=JS869OEz8dw6yAAshowhllrx/6Wt2PsY8FPNOz6dads=;
 b=owEBiQJ2/ZANAwAIAVNlBDxl2ALYAcsmYgBrAcmuJDqeGN+xO3e1hxHFJKhVylmZQDUDR6GPo
 WidU9B8bUqJAk8EAAEIADkWIQS5+sFL3gX/8PrA0S1TZQQ8ZdgC2AUCawHJrhsUgAAAAAAEAA5t
 YW51MiwyLjUrMS4xMiwwLDMACgkQU2UEPGXYAthjEg//U+toREe+iYYI5YeLYuqojeS2mtV7pYY
 VAVlyDt84cwWVk4qhv18AvNiGpzRinz9d1JLCOmfwJVcTn91gay1EDjEVNATCIq9/ORg9YTBvRJ
 IWWmI9AQHunx1a1D7KWplTl/fOHpCab9sreAGEuSmRHExZpaBbLWmnClxke/VmZX8oZF3wWBdEZ
 NIi7PV3EMnokPsdagL8HW7SfmoIoVSiWt6XjHryq7OmyWuGeqmHqZpdqkMDgbzX3HeXs3e9JvQe
 q6pHgTTKiebmBTq7zZc9cC397Ge3GcUXHtvJoCwgQpK4KCbXfuCUpDkyPoPWth6arviT7jv8Xwz
 Sx7GGIvdMBwDuXeSCtu3/wmFdtPL7D7hqmKeNRG/AnmgDZO5MNCMnhZ8qngTLpOTuAROYbuNQcn
 tqNBb+C3BYzGyEryPxDtOkCVHZM5eh2e5Ht5gX834XYA2hoeH5ysZUohh5O509AybWFPv62kPiQ
 ZLUd0h50X0O59LlfGGAsMCMXth6Gw/mkET0Vb5/2s0MamKY0LP3a4HWBp5U4KbYAhBFC26tJzYA
 potVZQAlpnGHbtDpX9Zn42n/ov5e5g80ekcobsGVhUTzQj5+/5TuBUorN6tL2py96EArXvXI4R7
 HMHjoYhcQHxR9Uh21owFX1kX0jG5YsbmL9FPB8yJ3OW2OXXj6yHc=
X-Developer-Key: i=haghdoost@uber.com; a=openpgp;
 fpr=B9FAC14BDE05FFF0FAC0D12D5365043C65D802D8
X-Endpoint-Received: by B4 Relay for haghdoost@uber.com/default with auth_id=764
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch makes perf check that a file is still the one it loaded
before it reads lazy symbol names from it. A lazy name is read later
from a file that perf opens again by path, at the offset that its
string table had at load time. If the file was replaced in between,
for example by a deploy, perf would read names from the wrong file and
print wrong names without a warning. Eager loading rejects such a
file, since symsrc__init() checks its build ID.

perf checks the file each time it opens it again. dso__set_lazy_file()
records the file at load time. Nothing calls it yet: the next patch
makes the ELF loader call it when it creates lazy symbols.

If the DSO has a build ID, symsrc__init() matched the file with it at
load time, so accept a file with that build ID, such as a copy of the
same build. The build ID alone is not enough, since the offsets are
only valid if the string tables did not move: objcopy
--add-gnu-debuglink keeps the build ID but moves .strtab, and strip
--strip-debug removes sections. So perf also records the index, offset
and size of the .symtab and .dynsym string tables, and compares them.

Reading the build ID each time is slow when most lookups load a name:
the parity test on a 524 MiB binary, which loads 260k names one at a
time, takes 9.3 seconds instead of 3.9. So perf also records the
device, inode, size, mtime and ctime of the file, and reads the build
ID only if they changed. The ctime changes when another file is copied
over this one in place, even if its size and mtime are kept, as with
cp -p. Then perf keeps the identity of the accepted file for later
reads. With this, the test takes 4.1 seconds. A DSO without a build ID
must keep the same identity.

If the file is not the one perf loaded, perf warns and shows the
remaining lazy symbols of that DSO as "[unknown]" rather than print
wrong names, without opening the file again. If the file cannot be
opened or checked, for example because perf ran out of file descriptors
or fstat() or a read of its ELF headers failed, perf warns once and
shows the symbols it was reading the names of as "[unknown]", but tries
again for later names, since the failure can be temporary. A file whose
build ID cannot be read counts as not checked, since perf cannot tell a
failed read from a missing build ID note; perf reads no names from it
either.

Like symsrc__init(), the check trusts the build ID: a file edited after
linking without a new build ID, and with its string tables in place,
gives the edited names.

The unit tests later in this series cover these cases.

No functional change, since no symbol has a lazy name yet.

Signed-off-by: Alireza Haghdoost <haghdoost@uber.com>
---
 tools/perf/util/dso.h        |  33 +++++++++
 tools/perf/util/symbol-elf.c | 156 ++++++++++++++++++++++++++++++++++++++++++-
 tools/perf/util/symbol.h     |   3 +
 3 files changed, 189 insertions(+), 3 deletions(-)

diff --git a/tools/perf/util/dso.h b/tools/perf/util/dso.h
index 10eac0b31b7d..216a9bc9366b 100644
--- a/tools/perf/util/dso.h
+++ b/tools/perf/util/dso.h
@@ -282,6 +282,33 @@ struct dso_bpf_prog {
 	struct perf_env	*env;
 };
 
+/* A string table that lazy symbol names point into. */
+struct dso_lazy_strtab {
+	u64		shndx;
+	u64		off;
+	u64		size;
+};
+
+/* The file that lazy symbol names are read from, as it was at load time. */
+struct dso_lazy_file {
+	u64		dev;
+	u64		ino;
+	u64		size;
+	u64		mtime_sec;
+	u64		mtime_nsec;
+	/* Copying over the file in place, keeping its size and mtime, changes it. */
+	u64		ctime_sec;
+	u64		ctime_nsec;
+	/* The string tables of .symtab and .dynsym. */
+	struct dso_lazy_strtab strtab[2];
+	/* symsrc__init() matched the file with the build ID of the DSO. */
+	bool		check_build_id;
+	/* The file changed after the names were loaded. */
+	bool		rejected;
+	/* perf warned that the file could not be opened or checked again. */
+	bool		retry_warned;
+};
+
 struct auxtrace_cache;
 
 DECLARE_RC_STRUCT(dso) {
@@ -321,6 +348,7 @@ DECLARE_RC_STRUCT(dso) {
 	struct dso_bpf_prog bpf_prog;
 	/* dso data file */
 	struct dso_data	 data;
+	struct dso_lazy_file lazy_file;
 	struct dso_id	 id;
 	unsigned int	 a2l_fails;
 	int		 comp;
@@ -503,6 +531,11 @@ static inline struct dso_data *dso__data(struct dso *dso)
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
diff --git a/tools/perf/util/symbol-elf.c b/tools/perf/util/symbol-elf.c
index 82d6a76176d2..468a0695809e 100644
--- a/tools/perf/util/symbol-elf.c
+++ b/tools/perf/util/symbol-elf.c
@@ -6,6 +6,7 @@
 #include <string.h>
 #include <unistd.h>
 #include <inttypes.h>
+#include <sys/stat.h>
 
 #include "compress.h"
 #include "dso.h"
@@ -1678,6 +1679,148 @@ static int read_symbol_names(struct dso *dso, int fd, struct symbol **syms, size
 	return err;
 }
 
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
+	lf->ctime_sec = st.st_ctim.tv_sec;
+	lf->ctime_nsec = st.st_ctim.tv_nsec;
+	return 0;
+}
+
+/*
+ * Record that lazy names of @dso point into @strtab of the file of @fd, the
+ * string table of .dynsym if @dynsym, else of .symtab. The caller holds the
+ * DSO lock, as dso__load() does.
+ */
+int dso__set_lazy_file(struct dso *dso, int fd, int dynsym,
+		       const struct dso_lazy_strtab *strtab)
+{
+	struct dso_lazy_file *lf = dso__lazy_file(dso);
+
+	if (lazy_file__stat(lf, fd))
+		return -1;
+	lf->strtab[dynsym] = *strtab;
+	lf->check_build_id = dso__has_build_id(dso) && !symbol_conf.ignore_vmlinux_buildid;
+	lf->rejected = false;
+	lf->retry_warned = false;
+	return 0;
+}
+
+enum lazy_file_check {
+	LAZY_FILE_MATCH,
+	LAZY_FILE_MISMATCH,
+	/* The file cannot be read, which can be temporary. */
+	LAZY_FILE_ERROR,
+};
+
+/* Check that the file of @fd has the identity in @lf. */
+static enum lazy_file_check lazy_file__check_stat(const struct dso_lazy_file *lf, int fd)
+{
+	struct dso_lazy_file now;
+
+	if (lazy_file__stat(&now, fd))
+		return LAZY_FILE_ERROR;
+	if (now.dev == lf->dev && now.ino == lf->ino && now.size == lf->size &&
+	    now.mtime_sec == lf->mtime_sec && now.mtime_nsec == lf->mtime_nsec &&
+	    now.ctime_sec == lf->ctime_sec && now.ctime_nsec == lf->ctime_nsec)
+		return LAZY_FILE_MATCH;
+	return LAZY_FILE_MISMATCH;
+}
+
+/*
+ * Check that the file of @fd has the build ID of @dso and the string tables
+ * where @lf has them. A copy with an added section, such as a
+ * .gnu_debuglink, keeps the build ID but can move the tables.
+ */
+static enum lazy_file_check lazy_file__check_build(const struct dso_lazy_file *lf,
+						   struct dso *dso, int fd)
+{
+	enum lazy_file_check ret = LAZY_FILE_ERROR;
+	u8 build_id[BUILD_ID_SIZE];
+	struct build_id bid;
+	GElf_Shdr shdr;
+	size_t shnum;
+	Elf *elf;
+	int size;
+
+	elf = elf_begin(fd, PERF_ELF_C_READ_MMAP, NULL);
+	if (!elf)
+		return LAZY_FILE_ERROR;
+	/* A failed read cannot be told from a missing build ID note. */
+	size = elf_read_build_id(elf, build_id, sizeof(build_id));
+	if (size <= 0)
+		goto out;
+	build_id__init(&bid, build_id, size);
+	if (!dso__build_id_equal(dso, &bid)) {
+		ret = LAZY_FILE_MISMATCH;
+		goto out;
+	}
+	if (elf_getshdrnum(elf, &shnum))
+		goto out;
+	ret = LAZY_FILE_MATCH;
+	for (size_t i = 0; ret == LAZY_FILE_MATCH && i < ARRAY_SIZE(lf->strtab); i++) {
+		const struct dso_lazy_strtab *st = &lf->strtab[i];
+
+		if (!st->size)
+			continue;
+		/* A stripped copy can have fewer sections. */
+		if (st->shndx >= shnum)
+			ret = LAZY_FILE_MISMATCH;
+		else if (!gelf_getshdr(elf_getscn(elf, st->shndx), &shdr))
+			ret = LAZY_FILE_ERROR;
+		else if (shdr.sh_type != SHT_STRTAB || (shdr.sh_flags & SHF_COMPRESSED) ||
+			 shdr.sh_offset != st->off || shdr.sh_size != st->size)
+			ret = LAZY_FILE_MISMATCH;
+	}
+out:
+	elf_end(elf);
+	return ret;
+}
+
+/*
+ * The name offsets are only valid in the file that dso__load() read. Accept
+ * @fd if it is that file, or another file with the build ID of @dso and the
+ * same string tables, such as a copy, and keep its identity for later reads.
+ * If it is not, for example after the binary was replaced, reject it and
+ * every later read for @dso. If it cannot be checked, do not read from it,
+ * but let later reads try again.
+ */
+static bool dso__lazy_file_ok(struct dso *dso, int fd, const char *name)
+{
+	struct dso_lazy_file *lf = dso__lazy_file(dso);
+	/* Reading the build ID at every lookup that loads a name is slow. */
+	enum lazy_file_check status = lazy_file__check_stat(lf, fd);
+
+	if (status == LAZY_FILE_MATCH)
+		return true;
+	if (lf->check_build_id) {
+		status = lazy_file__check_build(lf, dso, fd);
+		if (status == LAZY_FILE_MATCH) {
+			lazy_file__stat(lf, fd);
+			return true;
+		}
+	}
+	if (status == LAZY_FILE_ERROR) {
+		if (!lf->retry_warned)
+			pr_warning("%s cannot be checked after its symbols were loaded, some of its symbol names are not shown\n",
+				   name);
+		lf->retry_warned = true;
+		return false;
+	}
+	pr_warning("%s changed after its symbols were loaded, its symbol names are not shown\n",
+		   name);
+	lf->rejected = true;
+	return false;
+}
+
 /*
  * A name that cannot be read becomes "[unknown]". The caller holds the
  * DSO lock.
@@ -1699,6 +1842,8 @@ void dso__load_symbol_names(struct dso *dso, struct symbol **syms, size_t nr)
 		;
 	if (i == nr)
 		return;
+	if (dso__lazy_file(dso)->rejected)
+		goto out_unknown;
 	if (!own_ns)
 		nsinfo__mountns_enter(dso__nsinfo(dso), &nsc);
 	name = dso__get_filename(dso, "", &decomp, type);
@@ -1708,13 +1853,18 @@ void dso__load_symbol_names(struct dso *dso, struct symbol **syms, size_t nr)
 		nsinfo__mountns_exit(&nsc);
 
 	if (fd >= 0) {
-		read_symbol_names(dso, fd, syms, nr);
+		if (dso__lazy_file_ok(dso, fd, name))
+			read_symbol_names(dso, fd, syms, nr);
 		close(fd);
-	} else {
-		pr_debug("%s: cannot open the symbol table file\n", dso__long_name(dso));
+	} else if (!dso__lazy_file(dso)->retry_warned) {
+		/* The failure can be temporary, so later reads try again. */
+		pr_warning("%s cannot be opened after its symbols were loaded, some of its symbol names are not shown\n",
+			   name ?: dso__long_name(dso));
+		dso__lazy_file(dso)->retry_warned = true;
 	}
 	if (name)
 		dso__put_filename(dso, name, decomp);
+out_unknown:
 	for (i = 0; i < nr; i++) {
 		if (symbol__needs_lazy_name(syms[i]))
 			symbol__set_unknown_name(syms[i]);
diff --git a/tools/perf/util/symbol.h b/tools/perf/util/symbol.h
index d690cb1d021c..27def18f0f5c 100644
--- a/tools/perf/util/symbol.h
+++ b/tools/perf/util/symbol.h
@@ -271,6 +271,9 @@ int dso__load_sym(struct dso *dso, struct map *map, struct symsrc *syms_ss,
 		  struct symsrc *runtime_ss, int kmodule);
 int dso__synthesize_plt_symbols(struct dso *dso, struct symsrc *ss);
 void dso__load_symbol_names(struct dso *dso, struct symbol **syms, size_t nr);
+struct dso_lazy_strtab;
+int dso__set_lazy_file(struct dso *dso, int fd, int dynsym,
+		       const struct dso_lazy_strtab *strtab);
 
 char *dso__demangle_sym(struct dso *dso, int kmodule, const char *elf_name);
 

-- 
Git-157)

