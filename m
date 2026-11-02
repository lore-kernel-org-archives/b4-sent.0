From: Jacob Lefkowitz <jlefkowi@akamai.com>
Date: Mon, 02 Nov 2026 21:14:16 +0000
Subject: [PATCH v2 1/2] perf jevents: add iommu page table walk metrics
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261102-perf-tools-next-v2-1-4d237f886710@akamai.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=3362; i=jlefkowi@akamai.com;
 h=from:subject:message-id; bh=o+fTHAReSL+rEvSd6OyDxXB8zlYMgzMiuuHLzYKbvtA=;
 b=owEBbQKS/ZANAwAKAdLKfgzjwTS1AcsmYgBq6P0yeccUtD2GLhej/d2Lavjp2eNUncZ012Hbe
 GNY/SMVB1eJAjMEAAEKAB0WIQQKFmVpIhg7hFI7scTSyn4M48E0tQUCauj9MgAKCRDSyn4M48E0
 tRJED/0Sba2qk0SsG8L3HcbaWylkq/NbfhGCI8nOYlremFZXTbIuAg3+CLg8cM0hChvAqfhkNll
 K87NzMDOwGdEgkRPngmFdHlBClMRXU8bGGMeMOFiqYX/uCnOkgZBJdCxwBrM4kDMweXZeU1pNMc
 rapnrsIvkNOamrOUAHFV62r9G+RI0oTu58JGSwSlDC14YsNBULXG2LDwuwT+Yz9hCicFjdLQFxg
 ACeFHxf6vRGZ3CdKFVTnU+91EP1sWfVZ72vccn+a8yaR/iTGjlVLU9vFPIMuvfC+v4k0T3qdjqr
 t0JPvpaDIEDPNzWN4mkWngP9eDdaBtKl6nBUeANXkziGwqscrU4ubuzP4bKJ8BzL9FABJYcDIx0
 IC8BdXAp+ZcTmJMCnSHUHAB4RiUAFs2rDaPudGfhySZZer6ucR96kLhyipGHIVKBI94bRhbthIF
 Wsg4lRbbSdwR+XBNLPe80Exz3p8fvWnkEWqPCps0+JNKE4RMkd8v8zj7eWEgyDyfWnt/QfmoCmj
 aUBLVQvrdxKCyOMwFons6T8jsemhJH2p/k8nerKf3ZXNgTlFCT23ROoqtby0lNosw9vq36znJvo
 7MT+4ZPqON5YozilW+iUwgcEIxtHUw0mfly8Bp+GhBe77QtZGYtMh6M2k1yMD68PfrzM6eF1Q80
 9NfTGqngAr2hiVw==
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
"%  lpm_iommu_ptw_nested_read_ratio" : "none",
"%  lpm_iommu_ptw_guest_read_ratio" : "0.0",
"trans/s  lpm_iommu_trans_per_sec" : "971.5"}
{"socket" : "S1", "counters" : 0,
"reads/tlb_miss  lpm_iommu_ptw_reads_per_tlb_miss" : "none",
"%  lpm_iommu_ptw_nested_read_ratio" : "none",
"%  lpm_iommu_ptw_guest_read_ratio" : "none,
"trans/s  lpm_iommu_trans_per_sec" : "none"}

Signed-off-by: Jacob Lefkowitz <jlefkowi@akamai.com>
---
 tools/perf/pmu-events/amd_metrics.py | 45 ++++++++++++++++++++++++++++++++++++
 1 file changed, 45 insertions(+)

diff --git a/tools/perf/pmu-events/amd_metrics.py b/tools/perf/pmu-events/amd_metrics.py
index 42569b9153f4..452b88033492 100755
--- a/tools/perf/pmu-events/amd_metrics.py
+++ b/tools/perf/pmu-events/amd_metrics.py
@@ -318,6 +318,50 @@ def AmdIotlb() -> Optional[MetricGroup]:
     )
 
 
+def AmdIommuptw() -> Optional[MetricGroup]:
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
+                "Share of IOMMU page table reads from nested (host) tables",
+                d_ratio(pt_rd_nst, pt_rd),
+                "100%"
+            ),
+            Metric(
+                "lpm_iommu_ptw_guest_read_ratio",
+                "Share of IOMMU page table reads from guest tables",
+                d_ratio(pt_rd_gst, pt_rd),
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
@@ -526,6 +570,7 @@ def main() -> None:
         AmdCtxSw(),
         AmdDtlb(),
         AmdIotlb(),
+        AmdIommuptw(),
         AmdItlb(),
         AmdLdSt(),
         AmdUpc(),

-- 
2.53.0

