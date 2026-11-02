From: Jacob Lefkowitz <jlefkowi@akamai.com>
Subject: [PATCH v2 0/2] perf jevents: Add IOMMU PTW & device entry metrics
Date: Mon, 02 Nov 2026 21:14:15 +0000
Message-Id: <20261102-perf-tools-next-v2-0-4d237f886710@akamai.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/2WNyw6CMBBFf4XM2jG0PERX/odhMcIgE6UlbdNgC
 P9uJXHl8pzknruCZyfs4ZKt4DiKF2sS6EMG3UjmwSh9YtC5rlWuG5zZDRisfXk0vARshl71ZVE
 UqiZIq9nxIMtevLWJR/HBuvd+ENXX/lrnv1ZUmCOdKtL3uiRV8ZWeNJEcOztBu23bB+KDHySvA
 AAA
X-Change-ID: 20261028-perf-tools-next-8fd1d433316a
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1932; i=jlefkowi@akamai.com;
 h=from:subject:message-id; bh=d66B5JAoBXgjBVfpcoxVXE9rM8vAjKvyKdmOxdyzjJs=;
 b=owEBbQKS/ZANAwAKAdLKfgzjwTS1AcsmYgBq6P0rROw5wdqaVhUI1FzlhV0u8sWTxMPI3V5w4
 73IVmoN9leJAjMEAAEKAB0WIQQKFmVpIhg7hFI7scTSyn4M48E0tQUCauj9KwAKCRDSyn4M48E0
 tTv8D/46cbO7uCat3xnsVx99k3cPiDz4YBgdQxmUZORhslhy04HrNpTqLj8Rv1UWowXhmW2bIBh
 KQvqwJYspXh/7idcZtxE6udAYhVAWFVUmNjY+6o8yFztleoME63wtUHVsYix+6PDVXDvnyVS1xz
 uM6+PiMiyXg2HF04A8yavRLbPNu4ZeF6oiL0FZ5qc2NKEBlTT11qqW2UI4S9Yxxn/vYIGmkRzxu
 ApErMtCnesZdk8gatxg0DJ0g5VL5CMlVndVDWRfIy19B+GJfrtuIFZDPSSe9ELogvWZtay/JCAe
 C+Au+N5IDz7Pk0C7AiaIACz23POrYYoTXukRSEvDmWP6zRB/0FlOjDZlA3ZCSlJPCnm2RLeCn/h
 xL6hooCg4XweLs7qdfg8WwIYgxiMD+v15tCWtDaiJxOzVONBU8zt3zYZw9UhQwQmmFTnMDAQQv5
 NXloMm9AQhTnQhOfHJIAelDy4LlMyMHidksVmY1Z7xADHzOuke26+m5lrNge8RDQPDmFILl5a1k
 Pzu/YuXzvki7mdGzA3kx4i8uV+deZiRIhHUc+MrzP4Xp5SbO4kQzLPaI/IOhh75xHlZz7pnI9Ls
 nuSSQBsxYWU/MBHgV3VFFf8VM/dj4z1f4Dr5HxGhuJzD9LwZTGfRHFOqfXlCmmwraQ6DHjlSWrJ
 +lx8orRLVDZTaMw==
X-Developer-Key: i=jlefkowi@akamai.com; a=openpgp;
 fpr=0A16656922183B84523BB1C4D2CA7E0CE3C134B5
X-Endpoint-Received: by B4 Relay for jlefkowi@akamai.com/default with auth_id=1357
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Adds AMD specific metrics for the IOMMU with respect to page table
walks and device table entires. The metrics cover ratios, rates, and
percentages with respect to any event which might be triggered during
a page table walk or device table entry lookup.

The metrics target Zen 2+ processors and use the standard amd_iommu
PMU events. All metrics are tested with 'sleep 10' and behave as
expected. An example output of sleep 10 is provided within each
individual change. 

The changes are split into two patches:
1. perf jevents: add iommu page table walk metrics
2. perf jevents: add amd specific device table entry metrics

The specific metris added are:
- lpm_iommu_dte_miss_rate
- lpm_iommu_dte_lookups
- lpm_iommu_ptw_reads_per_tlb_miss
- lpm_iommu_ptw_nested_read_ratio
- lpm_iommu_ptw_guest_read_ratio
- lpm_iommu_trans_per_sec

Signed-off-by: Jacob Lefkowitz <jlefkowi@akamai.com>
---
Changes in v2:
- Drop min() wrappers d_ratio() for the IOMMU ratio metrics: min(NaN, 1)
  evaluated to 1, reporting a false 100% on sockets with no amd_counts
- Did not test with previously mentioned custom workload and did not add
  to the workloads collection. The workload stressed the CPU TLB,
  but the IOMMU only translates device DMA, so the load never reaches
  the IOMMU.
- Remove unused min import
- Remove global declaration of '_zen_model' within each function
- Link to v1: https://lore.kernel.org/r/20261029-perf-tools-next-v1-0-a75a2b64a15e@akamai.com

---
Jacob Lefkowitz (2):
      perf jevents: add iommu page table walk metrics
      perf jevents: add amd specific device table entry metrics

 tools/perf/pmu-events/amd_metrics.py | 75 ++++++++++++++++++++++++++++++++++++
 1 file changed, 75 insertions(+)
---
base-commit: 1c90f0a3c8a1c4e38f9edd97af9e20848805a7fb
change-id: 20261028-perf-tools-next-8fd1d433316a

Best regards,
-- 
Jacob Lefkowitz <jlefkowi@akamai.com>

