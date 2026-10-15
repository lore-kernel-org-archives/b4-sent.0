From: Antoine Huret <antoine.huret@bull.com>
Date: Thu, 15 Oct 2026 14:55:56 +0200
Subject: [PATCH] perf/core: Update cgroup time when rotating multiplexed
 events
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261015-perf-cgroup-rotation-time-v1-1-93e177dfee5d@bull.com>
X-B4-Tracking: v=1; b=H4sIAFvN0GoC/x3MQQqEMAxA0atI1gasThW8iriINWoW2pJWEcS7W
 2b5F+8/EFmFI/TFA8qXRPFHDlMW4DY6VkaZc0Nd1a2pjMXAuqBb1Z8B1SdKGWCSndFOrpksdb+
 ZCLIPyovc//cwvu8H7YmOAGsAAAA=
To: Peter Zijlstra <peterz@infradead.org>, Ingo Molnar <mingo@redhat.com>, 
 Arnaldo Carvalho de Melo <acme@kernel.org>, 
 Namhyung Kim <namhyung@kernel.org>, Mark Rutland <mark.rutland@arm.com>, 
 Alexander Shishkin <alexander.shishkin@linux.intel.com>, 
 Jiri Olsa <jolsa@kernel.org>, Ian Rogers <irogers@google.com>, 
 Adrian Hunter <adrian.hunter@intel.com>, 
 James Clark <james.clark@linaro.org>, Ravi Bangoria <ravi.bangoria@amd.com>
Cc: linux-perf-users@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Antoine Huret <antoine.huret@bull.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2339;
 i=antoine.huret@bull.com; h=from:subject:message-id;
 bh=X7lpvPKxkCTOPsqZeaF8a05zl2DLcvYi9kNi4gotLAU=;
 b=owEBbQKS/ZANAwAKAWMOnjplmIryAcsmYgBq0M2vTy8KMWluHcORRg4tu0qi8yEiNAtJORZf5
 UHeKGrI93KJAjMEAAEKAB0WIQSxtbJhhOISBbCx2QNjDp46ZZiK8gUCatDNrwAKCRBjDp46ZZiK
 8kjfD/98IihVBZxoHPjnYVh20iml/h60ZNgA8PlrLO66uTy4xUtpl5uyFYxgtCv6t/+vu2l93oR
 wYPO90o6rZfmkawFtrkM+lxx3yVEh4twOQGW/6O/57L+9A93RA2FjNlGRDWa+O8//0gifYstakI
 Opkj+K17hhJLyCcqc9ma5Ojqp/IMoUJ0dBLXIc7Mp8EcAwXCmpz8ewpvXjW6wdNH/LC6c3RKDP/
 4f2feS7nVOiduVysTkc514NV4XRmDzJQyj6ZKMT2XIA6mIsw3cNLInsKQ8x/NF1dejoaV1a8X5d
 3giuk/+bsVPfiD+lzhxWaCPZRR4wO6a/A7WPMlPTtT1+TyFK/ovy5Z2ExxFInSWKjnk/jr1OOc/
 EhXNUsj88bxr3qPgQX5cpe1PTjntM72+YeLi5nAFNSpy7VuaSGWDKPtvTG/bYP1BHPllZa0RrBs
 sg2RvvNUiDxGKoIEe3MM9s3M1gjuz2OSgfSLIqLXv81QvxXk29pfQhP+jK9pqRw2xJ+vV+toMqO
 xfjvVYW6z7GzRcoaMXz6AVXXMMbZtSZR3ZPB8b32a8/j15W6efHF5fD+xnvYSDM48mG50AFtiG9
 rrl9wx+DYJmDD/6UXqsLg5GDLIsBr2zyHIB96NnRU6YUe06lhpc1cMZv+7r3hlQr9HqpS6qvq+d
 JXWZc2VGuLd5B/w==
X-Developer-Key: i=antoine.huret@bull.com; a=openpgp;
 fpr=B1B5B26184E21205B0B1D903630E9E3A65988AF2
X-Endpoint-Received: by B4 Relay for antoine.huret@bull.com/default with auth_id=1191
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Since commit bd2756811766 ("perf: Rewrite core context handling"),
perf_rotate_context() only updates the context time before scheduling
out the flexible events. It no longer updates the cgroup time, which
ctx_sched_out() used to do.

Cgroup events take their times from the per-cpu cgroup clock, so
between two cgroup switches the rotations see a frozen clock. The
events rotated out lose the running time they accumulated, and the next
update, usually a read, credits the whole interval to the events that
happen to be on the PMU at that moment.

As a result, the time_running of multiplexed cgroup events is wrong,
and so are their scaled counts, as long as no other cgroup runs on the
CPU, e.g. a busy job alone on its CPUs. Counting cycles over one second
of a busy loop in a cgroup gives from half to several times the max
frequency of the CPU.

Update the cgroup time before rotating the CPU context, as was done
before the rewrite.

Fixes: bd2756811766 ("perf: Rewrite core context handling")
Closes: https://lore.kernel.org/r/PR3PR07MB69223331EED5BEBE150375B7849C2@PR3PR07MB6922.eurprd07.prod.outlook.com/
Cc: stable@vger.kernel.org
Assisted-by: Claude:claude-opus-5-5
Signed-off-by: Antoine Huret <antoine.huret@bull.com>
---
The reproducer and the results are in the report linked by the Closes:
tag. Tested on v7.3-rc7: multiplexed cgroup events read correct values
again. The culprit was confirmed by testing bd2756811766 and its parent
(v6.1-rc2).

Peter suggested a cleanup using ctx_time_update() in the rotation, to
go on top of this minimal fix.
---
 kernel/events/core.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/kernel/events/core.c b/kernel/events/core.c
index 7846d70be..971cd4b49 100644
--- a/kernel/events/core.c
+++ b/kernel/events/core.c
@@ -4639,6 +4639,7 @@ static bool perf_rotate_context(struct perf_cpu_pmu_context *cpc)
 
 	if (cpu_event) {
 		update_context_time(&cpuctx->ctx);
+		update_cgrp_time_from_cpuctx(cpuctx, false);
 		__pmu_ctx_sched_out(cpu_epc, EVENT_FLEXIBLE);
 		rotate_ctx(&cpuctx->ctx, cpu_event);
 		__pmu_ctx_sched_in(cpu_epc, EVENT_FLEXIBLE);

---
base-commit: 357e8a77a501d96c9517f01f4a211eed5e9c9184
change-id: 20261015-perf-cgroup-rotation-time-5bc3b5a74daa

Best regards,
-- 
Antoine Huret <antoine.huret@bull.com>

