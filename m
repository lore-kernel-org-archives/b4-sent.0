From: Jaidev Shastri <jaidevshastri@vt.edu>
Date: Mon, 21 Sep 2026 21:21:59 -0400
Subject: [PATCH] perf/hw_breakpoint: publish constraints_initialized with
 release semantics
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260921-mb-hw-breakpoint-v1-1-59aa06e1acf9@vt.edu>
X-B4-Tracking: v=1; b=H4sIADbYsWoC/yXM0Q7CIAyF4VdZem0NQx3BVzFeAKtSjWyhc5ose
 3dhXn5Nz7+AUGYSODcLZJpZeEgF7a6BEF26E3JfDFrpTlnd4stj/KDP5J7jwGlCY3tPqjtp4yy
 U2Zjpxt8tebn+LW//oDDVTv3wTqgUXAqxnjbOZn/AHI6wrj8ITyg3lAAAAA==
X-Change-ID: 20260921-mb-hw-breakpoint-79dbe06527a9
To: Peter Zijlstra <peterz@infradead.org>, Ingo Molnar <mingo@redhat.com>, 
 Arnaldo Carvalho de Melo <acme@kernel.org>, 
 Namhyung Kim <namhyung@kernel.org>, Mark Rutland <mark.rutland@arm.com>, 
 Alexander Shishkin <alexander.shishkin@linux.intel.com>, 
 Jiri Olsa <jolsa@kernel.org>, Ian Rogers <irogers@google.com>, 
 Adrian Hunter <adrian.hunter@intel.com>, 
 James Clark <james.clark@linaro.org>
Cc: linux-perf-users@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Jaidev Shastri <jaidevshastri@vt.edu>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790040119; l=1906;
 i=jaidevshastri@vt.edu; s=20260921; h=from:subject:message-id;
 bh=ZTittwT4zsRNTqrg94X6kSrWHkSFjRamZEdBKAP1Vdk=;
 b=79RBPT8VnBlXr45ayEwTi+Ic3H1TPdwDJDto1NDeYNDLfc58YVk+ARoEkFDNLZZep6Elae7+x
 vwgbLBs2k6gClkTEr8HFg+z5IYaPVT6S4l1la7dnOf29Gc+W1kVW8Ah
X-Developer-Key: i=jaidevshastri@vt.edu; a=ed25519;
 pk=J7+xYJRlTPds+pv5hbqFFRqGCpDeJDzmZT1ggRwj7/0=
X-Endpoint-Received: by B4 Relay for jaidevshastri@vt.edu/20260921 with auth_id=1044
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

init_breakpoint_slots() fills __nr_bp_slots[], cpu_pinned and
tsk_pinned_all and then sets constraints_initialized with a plain store.
__reserve_bp_slot() and hw_breakpoint_is_used() test the flag with a
plain load before they use those tables.

Set the flag with smp_store_release() and read it with
smp_load_acquire().

Found with MBCheck, a static herd7-based memory consistency checker.

Signed-off-by: Jaidev Shastri <jaidevshastri@vt.edu>
---
 kernel/events/hw_breakpoint.c | 9 ++++++---
 1 file changed, 6 insertions(+), 3 deletions(-)

diff --git a/kernel/events/hw_breakpoint.c b/kernel/events/hw_breakpoint.c
index 789add0c1..8532c8a35 100644
--- a/kernel/events/hw_breakpoint.c
+++ b/kernel/events/hw_breakpoint.c
@@ -577,7 +577,8 @@ static int __reserve_bp_slot(struct perf_event *bp, u64 bp_type)
 	int weight;
 
 	/* We couldn't initialize breakpoint constraints on boot */
-	if (!constraints_initialized)
+	/* Pairs with the smp_store_release() in init_breakpoint_slots(). */
+	if (!smp_load_acquire(&constraints_initialized))
 		return -ENOMEM;
 
 	/* Basic checks */
@@ -897,7 +898,8 @@ bool hw_breakpoint_is_used(void)
 {
 	int cpu;
 
-	if (!constraints_initialized)
+	/* Pairs with the smp_store_release() in init_breakpoint_slots(). */
+	if (!smp_load_acquire(&constraints_initialized))
 		return false;
 
 	for_each_possible_cpu(cpu) {
@@ -1017,7 +1019,8 @@ int __init init_hw_breakpoint(void)
 	if (ret)
 		return ret;
 
-	constraints_initialized = true;
+	/* Pairs with the smp_load_acquire() in the slot reservation paths. */
+	smp_store_release(&constraints_initialized, true);
 
 	perf_pmu_register(&perf_breakpoint, "breakpoint", PERF_TYPE_BREAKPOINT);
 

---
base-commit: 93f51579e7df248780214094418f205253383cc5
change-id: 20260921-mb-hw-breakpoint-79dbe06527a9

Best regards,
--  
Jaidev Shastri <jaidevshastri@vt.edu>

