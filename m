From: Alireza Haghdoost <haghdoost@uber.com>
Date: Fri, 25 Sep 2026 12:09:39 -0700
Subject: [PATCH v3 2/6] perf dso: Allow reading DSO data from an explicit
 file
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260925-perf-symbol-memory-send-v3-2-3e4e234c363b@uber.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=6269; i=haghdoost@uber.com;
 h=from:subject:message-id; bh=y6glUl+dokKT/nsYUSatFYnBRNntBRVmypJDz1I2m20=;
 b=owEBiQJ2/ZANAwAIAVNlBDxl2ALYAcsmYgBqtshDL0pWyyuT+eUv8jZG25N4hwDniqAJYkLSG
 3Md2uYhWsmJAk8EAAEIADkWIQS5+sFL3gX/8PrA0S1TZQQ8ZdgC2AUCarbIQxsUgAAAAAAEAA5t
 YW51MiwyLjUrMS4xMiwwLDMACgkQU2UEPGXYAthQ2w/+LoLYOXvQ0lDbzwyyclv56rLiu+ORYG0
 7BECCtbCE+QBBcWP7qFG3OzTJLpvRfQm1Oz327FFvo/4SgN69oOXMYTPzuq1vAKhYHyHg+tu2sp
 10VFfSKAkTsa9aSrcf+rFO0qYjQc3ScXb4WuvKRYAOwFztsUj0QZXlZnvD0AnKf0ZGLUkR97/3V
 HOwPOHHdecw3a8Kn3GSdJdu83G2C2Cj6FXIgiY5MoQxaHgJaKh7nHaRbs7NbH8o4ny01UnBiSkA
 hlhzy0XOLn7JPcebjRVBXtm98DutNIAv/CKLlkFvgJM6FX2xQ/Zaw+K6ZReLCgVQBUC7AtmRjT5
 Z37jVfTN1AfcYKMtrqsQ6a4+hLHywfXshO3bWpRxqwI78eYWxJdt3xqpvddxzNmraPlDkvWiAPw
 JWTM0aQtVfzxDQUvZcAPvJEOH3ggXgB5HjCvdZOXWEYW/WbysDAtGGxH0CEuuMI4+3Yw1HycmLh
 FtKN9JePWenvm67JdfHx33jFjyAhtWE5otRTNBmarEsfP80NCyHUKWGznlF4pp/34jYbbVsmNel
 FvgIexnz3PbydQ4Cx6/7NoOyZLFzDYSCllHd5njk3oc7KHdeNXqM9lEugoWIs48S9AKuYXSfw9Z
 9pS1zSYHU2M6QGudizpltc6/8btUHJP4OOMO5bffBwn8r4oDhq+o=
X-Developer-Key: i=haghdoost@uber.com; a=openpgp;
 fpr=B9FAC14BDE05FFF0FAC0D12D5365043C65D802D8
X-Endpoint-Received: by B4 Relay for haghdoost@uber.com/default with auth_id=764
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The DSO data cache derives the file to open from the DSO's binary type,
which can resolve to the runtime image rather than the file a symbol
table was read from. With split debuginfo, offsets taken from the
debuginfo file (for example string-table offsets) are then applied to an
unrelated file.

Add dso__data_set_path() so a DSO can be configured to read from one
exact file while keeping the data cache's descriptor eviction and
reopening. Such DSOs may be owned privately rather than being part of a
dsos collection, so drop the assertion that every opened data DSO is in
one.

Add a DSO data test that reads through an explicit path, closes the
descriptor, and reads an uncached offset to exercise reopening.

Signed-off-by: Alireza Haghdoost <haghdoost@uber.com>
---
 tools/perf/tests/dso-data.c | 42 ++++++++++++++++++++++++++++++++++++++++++
 tools/perf/util/dso.c       | 43 ++++++++++++++++++++++++++++++++++---------
 tools/perf/util/dso.h       |  2 ++
 3 files changed, 78 insertions(+), 9 deletions(-)

diff --git a/tools/perf/tests/dso-data.c b/tools/perf/tests/dso-data.c
index 46bc3f597260..fbfb2f08d3ba 100644
--- a/tools/perf/tests/dso-data.c
+++ b/tools/perf/tests/dso-data.c
@@ -393,11 +393,53 @@ static int test__dso_data_reopen(struct test_suite *test __maybe_unused, int sub
 	return 0;
 }
 
+static int test__dso_data_path(struct test_suite *test __maybe_unused, int subtest __maybe_unused)
+{
+	u8 expect[10] = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 };
+	char *file = test_file(TEST_FILE_SIZE);
+	struct dso *dso;
+	long nr, nr_end;
+	u8 buf[10];
+
+	TEST_ASSERT_VAL("No test file", file);
+	nr = open_files_cnt();
+
+	/*
+	 * The DSO name does not exist and the DSO is not in a dsos
+	 * collection; reads must come from the configured path.
+	 */
+	dso = dso__new("/nonexistent/perf-test-dso-data-path");
+	TEST_ASSERT_VAL("Failed to create dso", dso);
+	dso__set_binary_type(dso, DSO_BINARY_TYPE__SYSTEM_PATH_DSO);
+	TEST_ASSERT_VAL("Failed to set path", !dso__data_set_path(dso, file));
+
+	TEST_ASSERT_VAL("Wrong size",
+			dso__data_read_offset(dso, NULL, 10, buf, 10) == 10);
+	TEST_ASSERT_VAL("Wrong data", !memcmp(buf, expect, 10));
+
+	/* An uncached offset after close must reopen the configured path. */
+	dso__data_close(dso);
+	memset(buf, 0, sizeof(buf));
+	TEST_ASSERT_VAL("Wrong size after reopen",
+			dso__data_read_offset(dso, NULL, DSO__DATA_CACHE_SIZE * 2 + 10,
+					      buf, 10) == 10);
+	TEST_ASSERT_VAL("Wrong data after reopen",
+			buf[0] == (DSO__DATA_CACHE_SIZE * 2 + 10) % 10);
+
+	dso__data_close(dso);
+	dso__put(dso);
+	unlink(file);
+
+	nr_end = open_files_cnt();
+	TEST_ASSERT_VAL("failed leaking files", nr == nr_end);
+	return 0;
+}
 
 static struct test_case tests__dso_data[] = {
 	TEST_CASE("read", dso_data),
 	TEST_CASE("cache", dso_data_cache),
 	TEST_CASE("reopen", dso_data_reopen),
+	TEST_CASE("explicit path", dso_data_path),
 	{	.name = NULL, }
 };
 
diff --git a/tools/perf/util/dso.c b/tools/perf/util/dso.c
index 9e90de92fcfa..c88b2a771832 100644
--- a/tools/perf/util/dso.c
+++ b/tools/perf/util/dso.c
@@ -532,8 +532,6 @@ static void dso__list_add(struct dso *dso) EXCLUSIVE_LOCKS_REQUIRED(_dso__data_o
 #ifdef REFCNT_CHECKING
 	dso__data(dso)->dso = dso__get(dso);
 #endif
-	/* Assume the dso is part of dsos, hence the optional reference count above. */
-	assert(dso__dsos(dso));
 	dso__data_open_cnt++;
 }
 
@@ -578,16 +576,22 @@ char *dso__filename_with_chroot(const struct dso *dso, const char *filename)
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
+						   root_dir, name, PATH_MAX))
+			goto out;
+	}
 
 	if (!is_regular_file(name)) {
 		struct stat st;
@@ -813,6 +817,26 @@ void dso__data_close(struct dso *dso)
 	mutex_unlock(dso__data_open_lock());
 }
 
+/**
+ * dso__data_set_path - Read @dso's data from an explicit file
+ * @dso: dso object
+ * @path: file to open instead of the path derived from the binary type
+ *
+ * Used when the data must come from one specific file, such as the separate
+ * debuginfo file that a symbol table was read from. Must be called before any
+ * data is read, as already cached data is not invalidated.
+ */
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
@@ -1762,6 +1786,7 @@ void dso__delete(struct dso *dso)
 	dso__data_close(dso);
 	auxtrace_cache__free(RC_CHK_ACCESS(dso)->auxtrace_cache);
 	dso_cache__free(dso);
+	zfree(&RC_CHK_ACCESS(dso)->data.path);
 	dso__free_a2l(dso);
 	dso__free_a2l_libbfd(dso);
 	dso__free_libdw(dso);
diff --git a/tools/perf/util/dso.h b/tools/perf/util/dso.h
index e7d5f4bbf894..ff2c91e9a2b9 100644
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
@@ -910,6 +911,7 @@ bool dso__data_get_fd(struct dso *dso, struct machine *machine, int *fd)
 	EXCLUSIVE_TRYLOCK_FUNCTION(true, _dso__data_open_lock);
 void dso__data_put_fd(struct dso *dso) UNLOCK_FUNCTION(_dso__data_open_lock);
 void dso__data_close(struct dso *dso) LOCKS_EXCLUDED(_dso__data_open_lock);
+int dso__data_set_path(struct dso *dso, const char *path);
 
 int dso__data_file_size(struct dso *dso, struct machine *machine);
 off_t dso__data_size(struct dso *dso, struct machine *machine);

-- 
Git-157)

