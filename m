From: Michalis Niarchos <michael.niarchos@gmail.com>
Date: Mon, 03 Aug 2026 12:33:21 +0200
Subject: [PATCH 2/4] perf tools: Fix memory leak in kvm_events_report()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260803-perf-kvm-fixes-v1-2-a5db849ac973@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785753204; l=761;
 i=michael.niarchos@gmail.com; s=20260731; h=from:subject:message-id;
 bh=+xGD7FspTyvyggckeT50Nwqu43WI7i8N4AYpJ8estqw=;
 b=AdZ2NDsuv585bd+dL1dq8Z6u78WO7LwJ50KwamPaKemrMj3ZQDmMM4oB3Ot8YfkM7/YVw528o
 XgrkQSZEBeID61nF3k/9x40UxpiivbdVB4ZmP5KlpbNNa1GM7zFp6pL
X-Developer-Key: i=michael.niarchos@gmail.com; a=ed25519;
 pk=/LBZRQzfuxTnSaZhgZE8EP7mHr0poyqlKeFssNqkzFE=
X-Endpoint-Received: by B4 Relay for michael.niarchos@gmail.com/20260731 with auth_id=912
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

parse_options() calls parse_options_subcommand(), which allocates the
usage string. Free it.

Signed-off-by: Michalis Niarchos <michael.niarchos@gmail.com>
---
 tools/perf/builtin-kvm.c | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/tools/perf/builtin-kvm.c b/tools/perf/builtin-kvm.c
index 44c6998f2ee5..1a013698cae3 100644
--- a/tools/perf/builtin-kvm.c
+++ b/tools/perf/builtin-kvm.c
@@ -1755,6 +1755,9 @@ kvm_events_report(struct perf_kvm_stat *kvm, int argc, const char **argv)
 		if (argc)
 			usage_with_options(kvm_events_report_usage,
 					   kvm_events_report_options);
+
+		/* free usage string allocated by parse_options */
+		free((void *)kvm_events_report_usage[0]);
 	}
 
 #ifndef HAVE_SLANG_SUPPORT

-- 
2.55.0

