From: Alireza Haghdoost <haghdoost@uber.com>
Date: Fri, 02 Oct 2026 11:45:34 -0700
Subject: [PATCH v4 2/5] perf dso: Allow reading DSO data from an explicit
 file
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261002-perf-symbol-memory-send-v4-2-0a592bb2539e@uber.com>
References: <20261002-perf-symbol-memory-send-v4-0-0a592bb2539e@uber.com>
In-Reply-To: <20261002-perf-symbol-memory-send-v4-0-0a592bb2539e@uber.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=6171; i=haghdoost@uber.com;
 h=from:subject:message-id; bh=zHOBxWbVfbd1CinZEWKES+6xUEv+Rr9ivgGHO2OKulE=;
 b=owEBiQJ2/ZANAwAIAVNlBDxl2ALYAcsmYgBqv/vlacBMx4u+Gc+9zCAAstqxXq5l2tRZq1QQ2
 Nz/ts58mYyJAk8EAAEIADkWIQS5+sFL3gX/8PrA0S1TZQQ8ZdgC2AUCar/75RsUgAAAAAAEAA5t
 YW51MiwyLjUrMS4xMiwwLDMACgkQU2UEPGXYAtg7Hg/+LIRkW2VZ2prNJzuT5t13INR4VliDyq7
 Bq7+BcBKEM7Dcba0NmjKf3Qp1zXDD9OaYRv2F7kbLCi+O+G3l4+ds4rE1//zyTz/kSggy0DZTzC
 mH70C7nQMietV9LY9mkDSn7yZECqmg55Y1cruyT9JgGAjKwqMf6orra8e867UrQd8bu9ewYfMaG
 mXmB7xvE6bDwLXYQIFgv2EbuQPNVv7BK3pS9oFiGv0NnA9qWc4WsngoNf20AFLrLu7PrZy83UDf
 d7Um0bTH1j4JkpIpYjUzQhrki+WIBJzimjAxusGZe1XfmyVh76WCRcE37XIQjt54akUf2eZv2F5
 mppetaudZp8cgxr0lhmuslii6PGPlV9vrDDNEr0ZbKMUOuFMLU06WG6lp6mRjyBLJHB1FZgHV7N
 giHmFjnSwVdGvBhihxFAPuZq/k+YR511AObNw8RTCySoeUQDkFX+MdqyNTkOGIMdrGRd6fKC630
 Pgi+9/zEQxGUP7CL5T8RSECAcoWkHJz/Vw+/IWzSxiNE3RnbTLI8V7Opwo+ovGfU+GVIm8ayaiW
 vnVBUT5INNpPhZds696AgMiH9T6TNLvsKpWzaKtYrHf7dOBXWxVPAHl0DAu3aeefgbATW37fqbW
 J3Fjw0292zPYD8Ypcfu8/dBm6jCcVaMZ/3GN4oT1GUQlGuc8Qg0s=
X-Developer-Key: i=haghdoost@uber.com; a=openpgp;
 fpr=B9FAC14BDE05FFF0FAC0D12D5365043C65D802D8
X-Endpoint-Received: by B4 Relay for haghdoost@uber.com/default with auth_id=764
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The DSO data cache derives the file to open from the DSO's binary type,
which can resolve to the runtime image rather than the file a symbol
table was read from. The lazy symbol loader added later in this series
reads symbol names at string-table offsets in the file the symbol table
came from. With split debuginfo, the data cache would apply those
debuginfo offsets to the runtime image.

This patch adds dso__data_set_path() so a DSO can be configured to read
from one exact file while keeping the data cache's descriptor eviction
and reopening. The path is used only when the data cache opens the file;
dso__get_filename() and its debuginfo callers are unchanged. Such DSOs
may be owned privately rather than being part of a dsos collection, so
the patch also drops the assertion that every opened data DSO is in one.

Add a DSO data test that reads through an explicit path, closes the
descriptor, and reads an uncached offset to exercise reopening.

Signed-off-by: Alireza Haghdoost <haghdoost@uber.com>
---
 tools/perf/tests/dso-data.c | 42 ++++++++++++++++++++++++++++++++++++++++++
 tools/perf/util/dso.c       | 30 ++++++++++++++++++++++++++----
 tools/perf/util/dso.h       |  2 ++
 3 files changed, 70 insertions(+), 4 deletions(-)

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
index d3017c82ffb5..5c4872810ada 100644
--- a/tools/perf/util/dso.c
+++ b/tools/perf/util/dso.c
@@ -547,8 +547,6 @@ static void dso__list_add(struct dso *dso) EXCLUSIVE_LOCKS_REQUIRED(_dso__data_o
 #ifdef REFCNT_CHECKING
 	dso__data(dso)->dso = dso__get(dso);
 #endif
-	/* Assume the dso is part of dsos, hence the optional reference count above. */
-	assert(dso__dsos(dso));
 	dso__data_open_cnt++;
 }
 
@@ -678,8 +676,11 @@ static int __open_dso(struct dso *dso, struct machine *machine)
 
 	mutex_lock(dso__lock(dso));
 
-	name = dso__get_filename(dso, machine ? machine->root_dir : "", &decomp,
-				 dso__binary_type(dso));
+	if (dso__data(dso)->path)
+		name = strdup(dso__data(dso)->path);
+	else
+		name = dso__get_filename(dso, machine ? machine->root_dir : "",
+					 &decomp, dso__binary_type(dso));
 	if (name) {
 		fd = do_open(name);
 	} else {
@@ -833,6 +834,26 @@ void dso__data_close(struct dso *dso)
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
@@ -1783,6 +1804,7 @@ void dso__delete(struct dso *dso)
 	dso__data_close(dso);
 	auxtrace_cache__free(RC_CHK_ACCESS(dso)->auxtrace_cache);
 	dso_cache__free(dso);
+	zfree(&RC_CHK_ACCESS(dso)->data.path);
 	dso__free_a2l(dso);
 	dso__free_a2l_libbfd(dso);
 	dso__free_libdw(dso);
diff --git a/tools/perf/util/dso.h b/tools/perf/util/dso.h
index 3f08d45e7f53..7bcd5ec0c312 100644
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
@@ -921,6 +922,7 @@ bool dso__data_get_fd(struct dso *dso, struct machine *machine, int *fd)
 	EXCLUSIVE_TRYLOCK_FUNCTION(true, _dso__data_open_lock);
 void dso__data_put_fd(struct dso *dso) UNLOCK_FUNCTION(_dso__data_open_lock);
 void dso__data_close(struct dso *dso) LOCKS_EXCLUDED(_dso__data_open_lock);
+int dso__data_set_path(struct dso *dso, const char *path);
 
 int dso__data_file_size(struct dso *dso, struct machine *machine);
 off_t dso__data_size(struct dso *dso, struct machine *machine);

-- 
Git-157)

