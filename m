From: Michalis Niarchos <michael.niarchos@gmail.com>
Date: Mon, 03 Aug 2026 15:51:53 +0200
Subject: [PATCH v3 2/3] perf tools: Fix double free and memory leak issues
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260803-perf-kvm-fixes-v3-2-e06268ec06fa@gmail.com>
References: <20260803-perf-kvm-fixes-v3-0-e06268ec06fa@gmail.com>
In-Reply-To: <20260803-perf-kvm-fixes-v3-0-e06268ec06fa@gmail.com>
To: Peter Zijlstra <peterz@infradead.org>, Ingo Molnar <mingo@redhat.com>, 
 Arnaldo Carvalho de Melo <acme@kernel.org>, 
 Namhyung Kim <namhyung@kernel.org>, Mark Rutland <mark.rutland@arm.com>, 
 Alexander Shishkin <alexander.shishkin@linux.intel.com>, 
 Jiri Olsa <jolsa@kernel.org>, Ian Rogers <irogers@google.com>, 
 Adrian Hunter <adrian.hunter@intel.com>, 
 James Clark <james.clark@linaro.org>
Cc: linux-perf-users@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Michalis Niarchos <michael.niarchos@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785765118; l=6450;
 i=michael.niarchos@gmail.com; s=20260731; h=from:subject:message-id;
 bh=pJlrs2g9K4W+VPjPzId6fOvC6ZaAAwlqcisBbFjHGDQ=;
 b=wlwDVDvesTS+7ow5n9HZXUAhYE/xzE6YaTzvh7Lh6YDlOyj9tyqBAUW0v23osz7d7Sa0fC29/
 rTaiu32VXrjAs8ZUVfN6ctdpzEu947hY0zlSIk7oCoFUFt9afVUNyBK
X-Developer-Key: i=michael.niarchos@gmail.com; a=ed25519;
 pk=/LBZRQzfuxTnSaZhgZE8EP7mHr0poyqlKeFssNqkzFE=
X-Endpoint-Received: by B4 Relay for michael.niarchos@gmail.com/20260731 with auth_id=912
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

parse_options() reorders the contents of the rec_argv pointer array, so
its entry order no longer matches the order in which the caller
originally allocated them. Freeing the contents of rec_argv by
iterating the reordered array results in some pointers being freed
twice and others never freed.

All the entries of rec_argv come from literals or pointers that are
valid for the lifetime of the respective call. Reference them directly
instead of duplicating to remove the need to individually track and free
each entry.

Signed-off-by: Michalis Niarchos <michael.niarchos@gmail.com>
---
 tools/perf/builtin-kvm.c                         | 51 +++++++++---------------
 tools/perf/util/kvm-stat-arch/kvm-stat-powerpc.c |  4 +-
 tools/perf/util/kvm-stat-arch/kvm-stat-x86.c     | 10 ++---
 3 files changed, 24 insertions(+), 41 deletions(-)

diff --git a/tools/perf/builtin-kvm.c b/tools/perf/builtin-kvm.c
index 16cfa7ce7856..8e14d037d7d9 100644
--- a/tools/perf/builtin-kvm.c
+++ b/tools/perf/builtin-kvm.c
@@ -1681,18 +1681,18 @@ kvm_events_record(struct perf_kvm_stat *kvm, int argc, const char **argv)
 		return -ENOMEM;
 
 	for (i = 0; i < ARRAY_SIZE(record_args); i++)
-		rec_argv[i] = STRDUP_FAIL_EXIT(record_args[i]);
+		rec_argv[i] = record_args[i];
 
 	for (j = 0; j < events_tp_size; j++) {
-		rec_argv[i++] = STRDUP_FAIL_EXIT("-e");
-		rec_argv[i++] = STRDUP_FAIL_EXIT(kvm_events_tp(e_machine)[j]);
+		rec_argv[i++] = "-e";
+		rec_argv[i++] = kvm_events_tp(e_machine)[j];
 	}
 
-	rec_argv[i++] = STRDUP_FAIL_EXIT("-o");
-	rec_argv[i++] = STRDUP_FAIL_EXIT(kvm->file_name);
+	rec_argv[i++] = "-o";
+	rec_argv[i++] = kvm->file_name;
 
 	for (j = 1; j < (unsigned int)argc; j++, i++)
-		rec_argv[i] = STRDUP_FAIL_EXIT(argv[j]);
+		rec_argv[i] = argv[j];
 
 	set_option_flag(record_options, 'e', "event", PARSE_OPT_HIDDEN);
 	set_option_flag(record_options, 0, "filter", PARSE_OPT_HIDDEN);
@@ -1717,9 +1717,6 @@ kvm_events_record(struct perf_kvm_stat *kvm, int argc, const char **argv)
 	record_usage = kvm_stat_record_usage;
 	ret = cmd_record(i, rec_argv);
 
-EXIT:
-	for (i = 0; i < rec_argc; i++)
-		free((void *)rec_argv[i]);
 	free(rec_argv);
 	return ret;
 }
@@ -2006,11 +2003,11 @@ static int __cmd_record(const char *file_name, int argc, const char **argv)
 	if (!rec_argv)
 		return -ENOMEM;
 
-	rec_argv[i++] = STRDUP_FAIL_EXIT("record");
-	rec_argv[i++] = STRDUP_FAIL_EXIT("-o");
-	rec_argv[i++] = STRDUP_FAIL_EXIT(file_name);
+	rec_argv[i++] = "record";
+	rec_argv[i++] = "-o";
+	rec_argv[i++] = file_name;
 	for (j = 1; j < argc; j++, i++)
-		rec_argv[i] = STRDUP_FAIL_EXIT(argv[j]);
+		rec_argv[i] = argv[j];
 
 	BUG_ON(i + 2 != rec_argc);
 
@@ -2021,8 +2018,6 @@ static int __cmd_record(const char *file_name, int argc, const char **argv)
 	ret = cmd_record(i, rec_argv);
 
 EXIT:
-	for (i = 0; i < rec_argc; i++)
-		free((void *)rec_argv[i]);
 	free(rec_argv);
 	return ret;
 }
@@ -2037,19 +2032,16 @@ static int __cmd_report(const char *file_name, int argc, const char **argv)
 	if (!rec_argv)
 		return -ENOMEM;
 
-	rec_argv[i++] = STRDUP_FAIL_EXIT("report");
-	rec_argv[i++] = STRDUP_FAIL_EXIT("-i");
-	rec_argv[i++] = STRDUP_FAIL_EXIT(file_name);
+	rec_argv[i++] = "report";
+	rec_argv[i++] = "-i";
+	rec_argv[i++] = file_name;
 	for (j = 1; j < argc; j++, i++)
-		rec_argv[i] = STRDUP_FAIL_EXIT(argv[j]);
+		rec_argv[i] = argv[j];
 
 	BUG_ON(i != rec_argc);
 
 	ret = cmd_report(i, rec_argv);
 
-EXIT:
-	for (i = 0; i < rec_argc; i++)
-		free((void *)rec_argv[i]);
 	free(rec_argv);
 	return ret;
 }
@@ -2065,19 +2057,16 @@ __cmd_buildid_list(const char *file_name, int argc, const char **argv)
 	if (!rec_argv)
 		return -ENOMEM;
 
-	rec_argv[i++] = STRDUP_FAIL_EXIT("buildid-list");
-	rec_argv[i++] = STRDUP_FAIL_EXIT("-i");
-	rec_argv[i++] = STRDUP_FAIL_EXIT(file_name);
+	rec_argv[i++] = "buildid-list";
+	rec_argv[i++] = "-i";
+	rec_argv[i++] = file_name;
 	for (j = 1; j < argc; j++, i++)
-		rec_argv[i] = STRDUP_FAIL_EXIT(argv[j]);
+		rec_argv[i] = argv[j];
 
 	BUG_ON(i != rec_argc);
 
 	ret = cmd_buildid_list(i, rec_argv);
 
-EXIT:
-	for (i = 0; i < rec_argc; i++)
-		free((void *)rec_argv[i]);
 	free(rec_argv);
 	return ret;
 }
@@ -2097,7 +2086,7 @@ static int __cmd_top(int argc, const char **argv)
 		return -ENOMEM;
 
 	for (i = 0; i < argc; i++)
-		rec_argv[i] = STRDUP_FAIL_EXIT(argv[i]);
+		rec_argv[i] = argv[i];
 
 	BUG_ON(i != argc);
 
@@ -2108,8 +2097,6 @@ static int __cmd_top(int argc, const char **argv)
 	ret = cmd_top(i, rec_argv);
 
 EXIT:
-	for (i = 0; i < rec_argc; i++)
-		free((void *)rec_argv[i]);
 	free(rec_argv);
 	return ret;
 }
diff --git a/tools/perf/util/kvm-stat-arch/kvm-stat-powerpc.c b/tools/perf/util/kvm-stat-arch/kvm-stat-powerpc.c
index 96d9c4ae0209..37f36c6bf895 100644
--- a/tools/perf/util/kvm-stat-arch/kvm-stat-powerpc.c
+++ b/tools/perf/util/kvm-stat-arch/kvm-stat-powerpc.c
@@ -196,8 +196,8 @@ int __kvm_add_default_arch_event_powerpc(int *argc, const char **argv)
 	parse_options(j, tmp, event_options, NULL, PARSE_OPT_KEEP_UNKNOWN);
 	if (!event) {
 		if (perf_pmus__have_event("trace_imc", "trace_cycles")) {
-			argv[j++] = strdup("-e");
-			argv[j++] = strdup("trace_imc/trace_cycles/");
+			argv[j++] = "-e";
+			argv[j++] = "trace_imc/trace_cycles/";
 			*argc += 2;
 		} else {
 			free(tmp);
diff --git a/tools/perf/util/kvm-stat-arch/kvm-stat-x86.c b/tools/perf/util/kvm-stat-arch/kvm-stat-x86.c
index 788d216f0852..67babdd3daf1 100644
--- a/tools/perf/util/kvm-stat-arch/kvm-stat-x86.c
+++ b/tools/perf/util/kvm-stat-arch/kvm-stat-x86.c
@@ -213,7 +213,7 @@ int __kvm_add_default_arch_event_x86(int *argc, const char **argv)
 {
 	const char **tmp;
 	bool event = false;
-	int ret = 0, i, j = *argc;
+	int i, j = *argc;
 
 	const struct option event_options[] = {
 		OPT_BOOLEAN('e', "event", &event, NULL),
@@ -233,17 +233,13 @@ int __kvm_add_default_arch_event_x86(int *argc, const char **argv)
 
 	parse_options(j, tmp, event_options, NULL, PARSE_OPT_KEEP_UNKNOWN);
 	if (!event) {
-		argv[j++] = STRDUP_FAIL_EXIT("-e");
-		argv[j++] = STRDUP_FAIL_EXIT("cycles");
+		argv[j++] = "-e";
+		argv[j++] = "cycles";
 		*argc += 2;
 	}
 
 	free(tmp);
 	return 0;
-
-EXIT:
-	free(tmp);
-	return ret;
 }
 
 const char * const *__kvm_events_tp_x86(void)

-- 
2.55.0

