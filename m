From: Michalis Niarchos <michael.niarchos@gmail.com>
Date: Mon, 03 Aug 2026 15:51:52 +0200
Subject: [PATCH v3 1/3] perf tools: Fix memory leak in cmd_kvm()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260803-perf-kvm-fixes-v3-1-e06268ec06fa@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785765118; l=1401;
 i=michael.niarchos@gmail.com; s=20260731; h=from:subject:message-id;
 bh=g8MhihpU3z6FgOHyL6TpVKQEHy5oaO74U3jKb0sNYoY=;
 b=BbRDa2JL+T5vHyyCpP1ffABm/DHENH52ZcIixvt5R+vfjvE4bHm9TXCeYzkjepYGFE17yRfwp
 kJ0Oa4an6p1CKk+vy+ZE9JgCNLaI2P3PW2iYhyOqtAcvw9w7Cg9IUa9
X-Developer-Key: i=michael.niarchos@gmail.com; a=ed25519;
 pk=/LBZRQzfuxTnSaZhgZE8EP7mHr0poyqlKeFssNqkzFE=
X-Endpoint-Received: by B4 Relay for michael.niarchos@gmail.com/20260731 with auth_id=912
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

filename may get allocated by get_filename_for_perf_kvm(), but is
never freed. Use string literals to remove the need for freeing.

Signed-off-by: Michalis Niarchos <michael.niarchos@gmail.com>
---
 tools/perf/builtin-kvm.c | 14 ++++----------
 1 file changed, 4 insertions(+), 10 deletions(-)

diff --git a/tools/perf/builtin-kvm.c b/tools/perf/builtin-kvm.c
index 394302ebdb16..16cfa7ce7856 100644
--- a/tools/perf/builtin-kvm.c
+++ b/tools/perf/builtin-kvm.c
@@ -606,11 +606,11 @@ static const char *get_filename_for_perf_kvm(void)
 	const char *filename;
 
 	if (perf_host && !perf_guest)
-		filename = strdup("perf.data.host");
+		filename = "perf.data.host";
 	else if (!perf_host && perf_guest)
-		filename = strdup("perf.data.guest");
+		filename = "perf.data.guest";
 	else
-		filename = strdup("perf.data.kvm");
+		filename = "perf.data.kvm";
 
 	return filename;
 }
@@ -2158,15 +2158,9 @@ int cmd_kvm(int argc, const char **argv)
 	if (!perf_host)
 		perf_guest = 1;
 
-	if (!file_name) {
+	if (!file_name)
 		file_name = get_filename_for_perf_kvm();
 
-		if (!file_name) {
-			pr_err("Failed to allocate memory for filename\n");
-			return -ENOMEM;
-		}
-	}
-
 	if (strlen(argv[0]) > 2 && strstarts("record", argv[0]))
 		return __cmd_record(file_name, argc, argv);
 	else if (strlen(argv[0]) > 2 && strstarts("report", argv[0]))

-- 
2.55.0

