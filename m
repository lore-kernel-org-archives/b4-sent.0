From: Jacob Lefkowitz <jlefkowi@akamai.com>
Date: Thu, 29 Oct 2026 19:05:50 +0000
Subject: [PATCH 1/2] perf jevents: add iommu page table walk metrics
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261029-perf-tools-next-v1-1-a75a2b64a15e@akamai.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=3881; i=jlefkowi@akamai.com;
 h=from:subject:message-id; bh=vi12b5KTiVUT3//EtfmECCInovAIRPbBmoFjz6jP4xo=;
 b=owEBbQKS/ZANAwAKAdLKfgzjwTS1AcsmYgBq45kgbws/mkXO7RgLc1YXyZDQ6ZoM3ruOiFqpK
 FU0D2DafAiJAjMEAAEKAB0WIQQKFmVpIhg7hFI7scTSyn4M48E0tQUCauOZIAAKCRDSyn4M48E0
 tTJ7D/9LxuJke4JN3hiFOgiGe2IBY3C7fO48/Dqk219DTUzc602LXw7LUyNfG7AC06nOQugBwSc
 447fdJ+RhZ3k5voqJI+hubB97tEwVsjH1cxEcTkLZTJSh4qcfJM0lzQLoIZwzjVPXLeclUwgqBo
 9ue8SVTvaFQ8S2TKR/Ll4W6F9FwPsixvkqbeFNUo4QJ8jCTXfkYPunVLXyZRZAXFPrxTTCLFf5S
 f0O+YFGFDPa/QB8c4nRReWSS91nR04gVWC5EbhzxIS3xkzIaURPqSnt2rP7B97TT3dWFLftWqCG
 V0lECv0s9QlVWraWW8VDDu9YzpLLvcBPJUU/dx9NFRfT2MtR42qVPA6qMRXKID9F3xHw37PVrxo
 bTKvjdB+bPfV/AoRvoePekpfYqyjs0hCp0kzWi12EwUoOVgfOrhdcrPvjM3nAGeVXnkwP+xsKvm
 DHbdJ2Ot0kDxkR6Iw29af/oFw0Q7kI7a++MqcB1t43zfzZmeHWL9+KOkPUgYfMjsSLZlsRVO+dc
 j7/4zgVeD07vk0N3pnmkQdCj3VCUqDCD4WlJq7wzJm7p/xVDHsVIDwlLEDSOB7eSpIRuYmqDMK6
 dFwGZtqlvogt2AKUQ9Imw9EyZhNHqrRph6otyNhv5o96d5/s7QdjkjcyJj5v7EGUGemZ98c2JZi
 18ZQcmHirBqALTA==
X-Developer-Key: i=jlefkowi@akamai.com; a=openpgp;
 fpr=0A16656922183B84523BB1C4D2CA7E0CE3C134B5
X-Endpoint-Received: by B4 Relay for jlefkowi@akamai.com/default with auth_id=1357
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Adds page table walk metrics specfically to perf jevents for AMD
platforms to enhance observability into IOMMU overhead. The metrics
are supported on Zen 2 and neweer processors. They are implemented
using the amd_iommu PMU events.

The list of metrics added here are:
- lpm_iommu_ptw_reads_per_tlb_miss
- lpm_iommu_ptw_nested_read_ratio
- lpm_iommu_ptw_guest_read_ratio
- lpm_iommu_trans_per_sec

The changes here have been tested with 'sleep 10' as the workload:

perf stat -M iommuptw --per-socket --metric-only -j -a -- sleep 10
{"socket" : "S0", "counters" : 8,
"reads/tlb_miss lpm_iommu_ptw_reads_per_tlb_miss" : "0.5",
"%  lpm_iommu_ptw_nested_read_ratio" : "100.0",
"%  lpm_iommu_ptw_guest_read_ratio" : "0.0",
"trans/s  lpm_iommu_trans_per_sec" : "971.5"}
{"socket" : "S1", "counters" : 0,
"reads/tlb_miss  lpm_iommu_ptw_reads_per_tlb_miss" : "none",
"%  lpm_iommu_ptw_nested_read_ratio" : "100.0",
"%  lpm_iommu_ptw_guest_read_ratio" : "100.0",
"trans/s  lpm_iommu_trans_per_sec" : "none"}

Signed-off-by: Jacob Lefkowitz <jlefkowi@akamai.com>
---
 tools/perf/pmu-events/amd_metrics.py | 49 +++++++++++++++++++++++++++++++++++-
 1 file changed, 48 insertions(+), 1 deletion(-)

diff --git a/tools/perf/pmu-events/amd_metrics.py b/tools/perf/pmu-events/amd_metrics.py
index 42569b9153f4..dcffd6e268fa 100755
--- a/tools/perf/pmu-events/amd_metrics.py
+++ b/tools/perf/pmu-events/amd_metrics.py
@@ -5,7 +5,7 @@ import math
 import os
 from typing import Optional, Union
 from common_metrics import Cycles
-from metric import (d_ratio, has_event, max, Event, JsonEncodeMetric,
+from metric import (d_ratio, has_event, max, min, Event, JsonEncodeMetric,
                     JsonEncodeMetricGroupDescriptions, Literal, LoadEvents,
                     Metric, MetricGroup, Select)
 
@@ -318,6 +318,52 @@ def AmdIotlb() -> Optional[MetricGroup]:
     )
 
 
+def AmdIommuptw() -> Optional[MetricGroup]:
+    global _zen_model
+
+    if _zen_model < 2:
+        return None
+
+    walks = Event("amd_iommu/mem_iommu_tlb_pte_mis/") + Event(
+        "amd_iommu/mem_iommu_tlb_pde_mis/"
+    )
+    pt_rd = Event("amd_iommu/page_tbl_read_tot/")
+    pt_rd_nst = Event("amd_iommu/page_tbl_read_nst/")
+    pt_rd_gst = Event("amd_iommu/page_tbl_read_gst/")
+    trans = Event("amd_iommu/mem_trans_total/")
+
+    return MetricGroup(
+        "iommuptw",
+        [
+            Metric(
+                "lpm_iommu_ptw_reads_per_tlb_miss",
+                "Average IOMMU page table reads per IOTLB miss",
+                d_ratio(pt_rd, walks),
+                "reads/tlb_miss"
+            ),
+            Metric(
+                "lpm_iommu_ptw_nested_read_ratio",
+                "Share of IOMMU page table reads from nested (host) tables", # 0 without nested translation
+                min(d_ratio(pt_rd_nst, pt_rd), 1),
+                "100%"
+            ),
+            Metric(
+                "lpm_iommu_ptw_guest_read_ratio",
+                "Share of IOMMU page table reads from guest tables", # 0 without nested translation
+                min(d_ratio(pt_rd_gst, pt_rd), 1),
+                "100%"
+            ),
+            Metric(
+                "lpm_iommu_trans_per_sec",
+                "IOMMU translation requests per second",
+                d_ratio(trans, interval_sec),
+                "trans/s"
+            )
+        ],
+        description="IOMMU page table walk metrics"
+    )
+
+
 def AmdItlb():
     l2h = Event("bp_l1_tlb_miss_l2_tlb_hit", "bp_l1_tlb_miss_l2_hit")
     l2m = Event("bp_l1_tlb_miss_l2_tlb_miss.all", "l2_itlb_misses",)
@@ -526,6 +572,7 @@ def main() -> None:
         AmdCtxSw(),
         AmdDtlb(),
         AmdIotlb(),
+        AmdIommuptw(),
         AmdItlb(),
         AmdLdSt(),
         AmdUpc(),

-- 
2.53.0

