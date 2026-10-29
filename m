From: Jacob Lefkowitz <jlefkowi@akamai.com>
Date: Thu, 29 Oct 2026 19:05:51 +0000
Subject: [PATCH 2/2] perf jevents: add amd specific device table entry
 metrics
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261029-perf-tools-next-v1-2-a75a2b64a15e@akamai.com>
References: <20261029-perf-tools-next-v1-0-a75a2b64a15e@akamai.com>
In-Reply-To: <20261029-perf-tools-next-v1-0-a75a2b64a15e@akamai.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=2229; i=jlefkowi@akamai.com;
 h=from:subject:message-id; bh=j4bLiCRAXsXoexcyXQbQXPZqcKbIv4MvmP2HUvoUwU4=;
 b=owEBbQKS/ZANAwAKAdLKfgzjwTS1AcsmYgBq45kgqdp0MDUIlJfWPZQb/ObKYF9NTM7vQwqVq
 O4KeEz/zbyJAjMEAAEKAB0WIQQKFmVpIhg7hFI7scTSyn4M48E0tQUCauOZIAAKCRDSyn4M48E0
 tchWEACGQOvH0tHCJZQYAb4tfQ5W50rZqb0H7Zl60m9LMM8jK/GIYCnL/0YGXolGQWmt82Ed3Z7
 i6StigFwOmKNZfgtheMMfsv6aHVT2CBDkZBCdpEomPZ5ur8HDPk4TOlN5q5uYAzLeWjh9Cb/eJS
 TrgTVLOXKb7xjDzxFTWNcWeOVuggpkHXzLdf+Aeqa8n/MnqojyNUMLrPeP+nqVI7evlbZ0mXudo
 O59eudHMcwRHjSCPEkuccrKKG3r6wj60g8ypUoqK3yjLDTA3nxXUjv4UsqldlNEgn4khiIEb3EY
 Q6jjFKm5rlfUBl6uMAbXPuMp6JRxdWl1+F48yN6BYA2XvpayvBgn7a8VeCkR1phNk21FB9bqhGi
 UJ+nVqVGlEz0SFnT4qbGSEISC9N6qzo6eQ3jMO1w4m1v83w914QLxBapQp3oAhQxe9JtEO4IWsy
 m7L0zPyHcOcCwuSOFfJbCEpxhjFbUgLAJxEpjAERucwBrkRoVenqXU3JsxN+GhGcrS31WpMeOyq
 eaMNG+Ao96p4nTFqqKqbIpeNynhuH/+u4nQnF1z+OpylXVEjEm+ffx+i2wUk/BxaqUyLPIBG6G6
 Lp6Nw0nzpCNW4DsgZOFmQyWP8z8AI40SZzrUIOO9R4/qim/ykImw2jIVXla1vBynNOSCnGLKS0H
 9pFiy1di6We232Q==
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
"%  lpm_iommu_dte_miss_rate" : "100.0"}

Signed-off-by: Jacob Lefkowitz <jlefkowi@akamai.com>
---
 tools/perf/pmu-events/amd_metrics.py | 32 ++++++++++++++++++++++++++++++++
 1 file changed, 32 insertions(+)

diff --git a/tools/perf/pmu-events/amd_metrics.py b/tools/perf/pmu-events/amd_metrics.py
index dcffd6e268fa..912bceb57d67 100755
--- a/tools/perf/pmu-events/amd_metrics.py
+++ b/tools/perf/pmu-events/amd_metrics.py
@@ -318,6 +318,37 @@ def AmdIotlb() -> Optional[MetricGroup]:
     )
 
 
+def AmdIommudte() -> Optional[MetricGroup]:
+    global _zen_model
+
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
+                min(d_ratio(dte_mis, lookups), 1),
+                "100%"
+            ),
+            Metric(
+                "lpm_iommu_dte_lookups",
+                "IOMMU device table cache miss rate",
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
     global _zen_model
 
@@ -572,6 +603,7 @@ def main() -> None:
         AmdCtxSw(),
         AmdDtlb(),
         AmdIotlb(),
+        AmdIommudte(),
         AmdIommuptw(),
         AmdItlb(),
         AmdLdSt(),

-- 
2.53.0

