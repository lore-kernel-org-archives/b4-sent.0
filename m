From: Jacob Lefkowitz <jlefkowi@akamai.com>
Date: Mon, 02 Nov 2026 21:14:17 +0000
Subject: [PATCH v2 2/2] perf jevents: add amd specific device table entry
 metrics
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261102-perf-tools-next-v2-2-4d237f886710@akamai.com>
References: <20261102-perf-tools-next-v2-0-4d237f886710@akamai.com>
In-Reply-To: <20261102-perf-tools-next-v2-0-4d237f886710@akamai.com>
To: Peter Zijlstra <peterz@infradead.org>, Ingo Molnar <mingo@redhat.com>, 
 Arnaldo Carvalho de Melo <acme@kernel.org>, 
 Namhyung Kim <namhyung@kernel.org>, Mark Rutland <mark.rutland@arm.com>, 
 Alexander Shishkin <alexander.shishkin@linux.intel.com>, 
 Jiri Olsa <jolsa@kernel.org>, Ian Rogers <irogers@google.com>, 
 Adrian Hunter <adrian.hunter@intel.com>, 
 James Clark <james.clark@linaro.org>
Cc: linux-perf-users@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Ben Chaney <bchaney@akamai.com>, Matt Pelland <mpelland@akamai.com>, 
 Jacob Lefkowitz <jlefkowi@akamai.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2209; i=jlefkowi@akamai.com;
 h=from:subject:message-id; bh=liVzmx/OhcmtQ0v9uWwEdDDwpJFJAvmAPKfhOvaaGtU=;
 b=owEBbQKS/ZANAwAKAdLKfgzjwTS1AcsmYgBq6P0z1sUnsehURv0ALuYnX1+zEAwb5p3U5PjJv
 oEGb4ghktyJAjMEAAEKAB0WIQQKFmVpIhg7hFI7scTSyn4M48E0tQUCauj9MwAKCRDSyn4M48E0
 te7HD/0QD4bsU5JlUnn0wH2XgtqBjawzmQiqfUzZH9u9gN+d3nGBKQs5skQMG5TWckPPvVFczI5
 Q2y8kSwYY+yrmEn2g/9tf9i1yl8NerMFCKXYpObkSPRLSKXhg6q4EZ8xllUVz0LLpPUeqTJhzqR
 u185cvqeWB7CP3vCW2ataEdMCFVW1HXGg7Tk37LWtNtFsRU9kPcc8v4sVJZlzJfgqraGuehAQF4
 CjSTe4UalT0c78WC1TciXG5PFDoZG7J4OPwCz3uGSzFBmXP740b8nLvPHuT8/vYb4BIrv5t0LmW
 Sh45TxR2q8qFriuvAqsQy7a1Bgg8Ut57/n+8UJ1mHrR71sZo2EVKCBfJxk6cl0Krc6ar4Tr1n+X
 D2Y9bg1R1k/riX49n0rtDR7NavjFxrCADDXM/l64jEEs4gJi8GTxngBENu9FkKjBWaSMh69+lgn
 Dt0p9bvjTKaFnb9XyUq+JXkp9l5GhT0ZUud7ceouxRBBnUZM760JV67R8E+6FAtx01mIhcC+whN
 MsGu1wstc4QfHdC3JEaklajKtSSFbW42M9ArpCq9dilyr1FB/AakgKoXAqDsoCL634ARaCDKv8T
 WRt49feqhciT/ABIfTK3ZvgRQ2JNnHs0tHuyHfHfu8BKbh8VJfZEtp7mZyPrRXY7ckZkyp1/me2
 afyBcIWWeSccv1g==
X-Developer-Key: i=jlefkowi@akamai.com; a=openpgp;
 fpr=0A16656922183B84523BB1C4D2CA7E0CE3C134B5
X-Endpoint-Received: by B4 Relay for jlefkowi@akamai.com/default with auth_id=1357
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Adds AMD specific device table entry metrics to perf jevents.
These metrics are only allowed on Zen 2+ processors and are
implemented using the 'amd_iommu' PMU events.

The list of metrics added are:
- lpm_iommu_dte_miss_rate
- lpm_iommu_dte_lookups

The metrics were tested with the standard 'sleep' workload:

perf stat -M iommudte --per-socket --metric-only -j -a -- sleep 10
{"socket" : "S0", "counters" : 8,
"lookups/s  lpm_iommu_dte_lookups" : "4117.3",
"%  lpm_iommu_dte_miss_rate" : "0.0"}
{"socket" : "S1", "counters" : 0,
"lookups/s  lpm_iommu_dte_lookups" : "none",
"%  lpm_iommu_dte_miss_rate" : "none"}

Signed-off-by: Jacob Lefkowitz <jlefkowi@akamai.com>
---
 tools/perf/pmu-events/amd_metrics.py | 30 ++++++++++++++++++++++++++++++
 1 file changed, 30 insertions(+)

diff --git a/tools/perf/pmu-events/amd_metrics.py b/tools/perf/pmu-events/amd_metrics.py
index 452b88033492..fd0bd9f16529 100755
--- a/tools/perf/pmu-events/amd_metrics.py
+++ b/tools/perf/pmu-events/amd_metrics.py
@@ -318,6 +318,35 @@ def AmdIotlb() -> Optional[MetricGroup]:
     )
 
 
+def AmdIommudte() -> Optional[MetricGroup]:
+    if _zen_model < 2:
+        return None
+
+    dte_hit = Event("amd_iommu/mem_dte_hit/")
+    dte_mis = Event("amd_iommu/mem_dte_mis/")
+    lookups = dte_hit + dte_mis
+
+    return MetricGroup(
+        "iommudte",
+        [
+            Metric(
+                "lpm_iommu_dte_miss_rate",
+                "IOMMU device table cache miss rate",
+                d_ratio(dte_mis, lookups),
+                "100%"
+            ),
+            Metric(
+                "lpm_iommu_dte_lookups",
+                "IOMMU device table cache lookups",
+                d_ratio(lookups, interval_sec),
+                "lookups/s"
+            )
+        ],
+        description="IOMMU Device Table Cache Metrics"
+    )
+
+
+
 def AmdIommuptw() -> Optional[MetricGroup]:
     if _zen_model < 2:
         return None
@@ -570,6 +599,7 @@ def main() -> None:
         AmdCtxSw(),
         AmdDtlb(),
         AmdIotlb(),
+        AmdIommudte(),
         AmdIommuptw(),
         AmdItlb(),
         AmdLdSt(),

-- 
2.53.0

