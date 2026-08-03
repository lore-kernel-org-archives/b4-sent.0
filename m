From: Michalis Niarchos <michael.niarchos@gmail.com>
Date: Mon, 03 Aug 2026 12:33:23 +0200
Subject: [PATCH 4/4] perf tools: Fix memory leak in cmd_kvm()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260803-perf-kvm-fixes-v1-4-a5db849ac973@gmail.com>
References: <20260803-perf-kvm-fixes-v1-0-a5db849ac973@gmail.com>
In-Reply-To: <20260803-perf-kvm-fixes-v1-0-a5db849ac973@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785753204; l=2666;
 i=michael.niarchos@gmail.com; s=20260731; h=from:subject:message-id;
 bh=aAXwiliLnci6ARcvdP09SP99aBXKZEyzobOz6tm8hbA=;
 b=1HQJR92TTBq0FroPdOZA3NsqlEbOi/eh3gya1ArmHe/YqCqXG/yB1xKKbd9s4KbDvgWa9eNj8
 uu4K3EbE7WZB7ScJc+nn1uROs3i2P9Hsn7Hce3RKQ72cWvH1r0zqN3M
X-Developer-Key: i=michael.niarchos@gmail.com; a=ed25519;
 pk=/LBZRQzfuxTnSaZhgZE8EP7mHr0poyqlKeFssNqkzFE=
X-Endpoint-Received: by B4 Relay for michael.niarchos@gmail.com/20260731 with auth_id=912
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The usage string is allocated by parse_options_subcommand() and freed
only on one return path. Using a single return point guarantees it is
freed on all occasions.

Signed-off-by: Michalis Niarchos <michael.niarchos@gmail.com>
---
 tools/perf/builtin-kvm.c | 39 +++++++++++++++++++++++++--------------
 1 file changed, 25 insertions(+), 14 deletions(-)

diff --git a/tools/perf/builtin-kvm.c b/tools/perf/builtin-kvm.c
index 189ef3576e34..56062c305db1 100644
--- a/tools/perf/builtin-kvm.c
+++ b/tools/perf/builtin-kvm.c
@@ -2145,6 +2145,7 @@ int cmd_kvm(int argc, const char **argv)
 	const char *const kvm_subcommands[] = { "top", "record", "report", "diff",
 						"buildid-list", "stat", NULL };
 	const char *kvm_usage[] = { NULL, NULL };
+	int ret = 0;
 
 	exclude_GH_default = true;
 	perf_host  = 0;
@@ -2163,29 +2164,39 @@ int cmd_kvm(int argc, const char **argv)
 
 		if (!file_name) {
 			pr_err("Failed to allocate memory for filename\n");
-			return -ENOMEM;
+			ret = -ENOMEM;
+			goto exit;
 		}
 	}
 
-	if (strlen(argv[0]) > 2 && strstarts("record", argv[0]))
-		return __cmd_record(file_name, argc, argv);
-	else if (strlen(argv[0]) > 2 && strstarts("report", argv[0]))
-		return __cmd_report(file_name, argc, argv);
-	else if (strlen(argv[0]) > 2 && strstarts("diff", argv[0]))
-		return cmd_diff(argc, argv);
-	else if (!strcmp(argv[0], "top"))
-		return __cmd_top(argc, argv);
-	else if (strlen(argv[0]) > 2 && strstarts("buildid-list", argv[0]))
-		return __cmd_buildid_list(file_name, argc, argv);
+	if (strlen(argv[0]) > 2 && strstarts("record", argv[0])) {
+		ret = __cmd_record(file_name, argc, argv);
+		goto exit;
+	} else if (strlen(argv[0]) > 2 && strstarts("report", argv[0])) {
+		ret = __cmd_report(file_name, argc, argv);
+		goto exit;
+	} else if (strlen(argv[0]) > 2 && strstarts("diff", argv[0])) {
+		ret = cmd_diff(argc, argv);
+		goto exit;
+	} else if (!strcmp(argv[0], "top")) {
+		ret = __cmd_top(argc, argv);
+		goto exit;
+	} else if (strlen(argv[0]) > 2 && strstarts("buildid-list", argv[0])) {
+		ret = __cmd_buildid_list(file_name, argc, argv);
+		goto exit;
+	}
 #if defined(HAVE_LIBTRACEEVENT)
-	else if (strlen(argv[0]) > 2 && strstarts("stat", argv[0]))
-		return kvm_cmd_stat(file_name, argc, argv);
+	else if (strlen(argv[0]) > 2 && strstarts("stat", argv[0])) {
+		ret = kvm_cmd_stat(file_name, argc, argv);
+		goto exit;
+	}
 #endif
 	else
 		usage_with_options(kvm_usage, kvm_options);
 
+exit:
 	/* free usage string allocated by parse_options_subcommand */
 	free((void *)kvm_usage[0]);
 
-	return 0;
+	return ret;
 }

-- 
2.55.0

