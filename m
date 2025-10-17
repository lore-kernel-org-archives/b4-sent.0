From: Shubhang Kaushik <shubhang@os.amperecomputing.com>
Date: Fri, 17 Oct 2025 16:00:44 -0700
Subject: [PATCH] sched/fair: Prefer cache-hot prev_cpu for wakeup
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251017-b4-sched-cfs-refactor-propagate-v1-1-1eb0dc5b19b3@os.amperecomputing.com>
X-B4-Tracking: v=1; b=H4sIAJvK8mgC/x2NQQqDQAwAvyI5N7C7rFT7ldJDGqPm4i6JFEH8e
 xePA8PMCS6m4vDqTjD5qWvZGsRHB7zStgjq1BhSSH0M8YnfjM6rTMizo8lMvBfDaqXSQrtg4kx
 DCuM4UIZWqc3R4z68P9f1ByI6ub1xAAAA
X-Change-ID: 20251017-b4-sched-cfs-refactor-propagate-2c4a820998a4
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1760742065; l=2401;
 i=shubhang@os.amperecomputing.com; s=20251010; h=from:subject:message-id;
 bh=mj055oq7WnkP9xwqfOm87rkrgswcSedbXUDF3DZAKlo=;
 b=bJTba887Ti8Qb2WO6yKDozWXzUjJtMwujM4S3dNIgzpHADDvqmk1ZZ9NbcIOjdy2fE3S0QR4p
 oq32R7Aq8eUAM/AMMH9D/h59bRGmdPKGSYXuBiAgSGVgsOrR014ZsyN
X-Developer-Key: i=shubhang@os.amperecomputing.com; a=ed25519;
 pk=jc8YIRvxPSyJaBRe5y+a4N0RXKBUEcAh8+OFhlROXPY=
X-Endpoint-Received: by B4 Relay for shubhang@os.amperecomputing.com/20251010 with auth_id=539
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Modify the wakeup path in `select_task_rq_fair()` to prioritize cache
locality for waking tasks. The previous fast path always attempted to
find an idle sibling, even if the task's prev CPU was not truly busy.

The original problem was that under some circumstances, this could lead
to unnecessary task migrations away from a cache-hot core, even when
the task's prev CPU was a suitable candidate. The scheduler's internal
mechanism `cpu_overutilized()` provide an evaluation of CPU load.

To address this, the wakeup heuristic is updated to check the status of
the task's `prev_cpu` first:
- If the `prev_cpu` is  not overutilized (as determined by
  `cpu_overutilized()`, via PELT), the task is woken up on
  its previous CPU. This leverages cache locality and avoids
  a potentially unnecessary migration.
- If the `prev_cpu` is considered busy or overutilized, the scheduler
  falls back to the existing behavior of searching for an idle sibling.

Signed-off-by: Shubhang Kaushik <shubhang@os.amperecomputing.com>
---
This patch optimizes the scheduler's wakeup path to prioritize cache 
locality by keeping a task on its previous CPU if it is not overutilized,
falling back to a sibling search only when necessary.
---
 kernel/sched/fair.c | 11 ++++++++++-
 1 file changed, 10 insertions(+), 1 deletion(-)

diff --git a/kernel/sched/fair.c b/kernel/sched/fair.c
index bc0b7ce8a65d6bbe616953f530f7a02bb619537c..bb0d28d7d9872642cb5a4076caeb3ac9d8fe7bcd 100644
--- a/kernel/sched/fair.c
+++ b/kernel/sched/fair.c
@@ -8618,7 +8618,16 @@ select_task_rq_fair(struct task_struct *p, int prev_cpu, int wake_flags)
 		new_cpu = sched_balance_find_dst_cpu(sd, p, cpu, prev_cpu, sd_flag);
 	} else if (wake_flags & WF_TTWU) { /* XXX always ? */
 		/* Fast path */
-		new_cpu = select_idle_sibling(p, prev_cpu, new_cpu);
+
+		/*
+		 * Avoid wakeup on an overutilized CPU.
+		 * If the previous CPU is not overloaded, retain the same for cache locality.
+		 * Otherwise, search for an idle sibling.
+		 */
+		if (!cpu_overutilized(prev_cpu))
+			new_cpu = prev_cpu;
+		else
+			new_cpu = select_idle_sibling(p, prev_cpu, new_cpu);
 	}
 	rcu_read_unlock();
 

---
base-commit: 9b332cece987ee1790b2ed4c989e28162fa47860
change-id: 20251017-b4-sched-cfs-refactor-propagate-2c4a820998a4

Best regards,
-- 
Shubhang Kaushik <shubhang@os.amperecomputing.com>

