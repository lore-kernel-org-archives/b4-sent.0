From: Shubhang Kaushik <shubhang@os.amperecomputing.com>
Date: Thu, 30 Oct 2025 12:19:29 -0700
Subject: [PATCH v2] sched/fair: Prefer cache locality for EAS wakeup
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251030-b4-follow-up-v2-1-19a23c83b837@os.amperecomputing.com>
X-B4-Tracking: v=1; b=H4sIAEC6A2kC/02Myw6CMBBFf8V07ZDSQoyu/A/joo8pNAGmmRY0I
 fy71ZW5m3sW5+wiI0fM4nbaBeMWc6SlgjqfhBvNMiBEX1koqfpWagm2g0DTRC9YE4Qgte16rY3
 yoiqJMcT3L/d4Vg5MM5SR0fxF2ss3kt2IHlzIUB3jCjEkpmQGUxC2FurQSu96216tvlNuzJyQ0
 dGc1hKXoalPHMcHLdrE38IAAAA=
X-Change-ID: 20251030-b4-follow-up-ff03b4533a2d
To: Ingo Molnar <mingo@redhat.com>, Peter Zijlstra <peterz@infradead.org>, 
 Juri Lelli <juri.lelli@redhat.com>, 
 Vincent Guittot <vincent.guittot@linaro.org>, 
 Dietmar Eggemann <dietmar.eggemann@arm.com>, 
 Steven Rostedt <rostedt@goodmis.org>, Ben Segall <bsegall@google.com>, 
 Mel Gorman <mgorman@suse.de>, Valentin Schneider <vschneid@redhat.com>, 
 Shubhang Kaushik <sh@gentwo.org>, 
 Shijie Huang <Shijie.Huang@amperecomputing.com>, 
 Frank Wang <zwang@amperecomputing.com>
Cc: Christopher Lameter <cl@gentwo.org>, 
 Adam Li <adam.li@amperecomputing.com>, linux-kernel@vger.kernel.org, 
 Shubhang Kaushik <shubhang@os.amperecomputing.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1761851978; l=2430;
 i=shubhang@os.amperecomputing.com; s=20251010; h=from:subject:message-id;
 bh=q1httNTq42jPnpET+Sx8sWschV5NJ0NnZZCoUwuq6j4=;
 b=LVoAUrJlhLEI/Uwv5GFzSfwnnGQrFv7lbdagNGPHLpvykljZEFL7Rxiwv3UJIV49hTGokc4sh
 synCF+87bmECw/RLhxZGyqs3O3U+1YMQs38BlLtpLk0OcK+nJWnNvio
X-Developer-Key: i=shubhang@os.amperecomputing.com; a=ed25519;
 pk=jc8YIRvxPSyJaBRe5y+a4N0RXKBUEcAh8+OFhlROXPY=
X-Endpoint-Received: by B4 Relay for shubhang@os.amperecomputing.com/20251010 with auth_id=539
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When Energy Aware Scheduling (EAS) is enabled, a task waking up on a
sibling CPU might migrate away from its previous CPU even if that CPU
is not overutilized. This sacrifices cache locality and introduces
unnecessary migration overhead.

This patch refines the wakeup heuristic in `select_idle_sibling()`. If
EAS is active and the task's previous CPU (`prev`) is not overutilized,
the scheduler will prioritize waking the task on `prev`, avoiding an
unneeded migration and preserving cache-hotness.

---
v2:
- Addressed reviewer comments to handle this special condition
  within the selection logic, prioritizing the
  previous CPU if not overutilized for EAS.
- Link to v1: https://lore.kernel.org/all/20251017-b4-sched-cfs-refactor-propagate-v1-1-1eb0dc5b19b3@os.amperecomputing.com/

Signed-off-by: Shubhang Kaushik <shubhang@os.amperecomputing.com>
---
 kernel/sched/fair.c | 12 +++++++++---
 1 file changed, 9 insertions(+), 3 deletions(-)

diff --git a/kernel/sched/fair.c b/kernel/sched/fair.c
index 25970dbbb27959bc130d288d5f80677f75f8db8b..ac94463627778f09522fb5420f67b903a694ad4d 100644
--- a/kernel/sched/fair.c
+++ b/kernel/sched/fair.c
@@ -7847,9 +7847,7 @@ static int select_idle_sibling(struct task_struct *p, int prev, int target)
 	    asym_fits_cpu(task_util, util_min, util_max, target))
 		return target;
 
-	/*
-	 * If the previous CPU is cache affine and idle, don't be stupid:
-	 */
+	/* Reschedule on an idle, cache-sharing sibling to preserve affinity: */
 	if (prev != target && cpus_share_cache(prev, target) &&
 	    (available_idle_cpu(prev) || sched_idle_cpu(prev)) &&
 	    asym_fits_cpu(task_util, util_min, util_max, prev)) {
@@ -7861,6 +7859,14 @@ static int select_idle_sibling(struct task_struct *p, int prev, int target)
 		prev_aff = prev;
 	}
 
+	/*
+	 * If the previous CPU is not overutilized, prefer it for cache locality.
+	 * This prevents migration away from a cache-hot CPU that can still
+	 * handle the task without causing an overload.
+	 */
+	if (sched_energy_enabled() && !cpu_overutilized(prev))
+		return prev;
+
 	/*
 	 * Allow a per-cpu kthread to stack with the wakee if the
 	 * kworker thread and the tasks previous CPUs are the same.

---
base-commit: e53642b87a4f4b03a8d7e5f8507fc3cd0c595ea6
change-id: 20251030-b4-follow-up-ff03b4533a2d

Best regards,
-- 
Shubhang Kaushik <shubhang@os.amperecomputing.com>

