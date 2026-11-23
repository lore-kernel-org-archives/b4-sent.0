From: "Josh Lafleur (Zipline)" <josh.lafleur@outlook.com>
Date: Mon, 23 Nov 2026 11:21:44 -0800
Subject: [PATCH 2/2] sched/rt: Restore pinned candidates for PUSH_IPI
 balancing
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261123-migrate-on-ipi-v1-2-eacfe7e4b808@outlook.com>
References: <20261123-migrate-on-ipi-v1-0-eacfe7e4b808@outlook.com>
In-Reply-To: <20261123-migrate-on-ipi-v1-0-eacfe7e4b808@outlook.com>
To: Ingo Molnar <mingo@redhat.com>, Peter Zijlstra <peterz@infradead.org>, 
 Juri Lelli <juri.lelli@redhat.com>, 
 Vincent Guittot <vincent.guittot@linaro.org>, 
 Dietmar Eggemann <dietmar.eggemann@arm.com>, 
 Steven Rostedt <rostedt@goodmis.org>, Ben Segall <bsegall@google.com>, 
 Mel Gorman <mgorman@suse.de>, Valentin Schneider <vschneid@redhat.com>, 
 K Prateek Nayak <kprateek.nayak@amd.com>, 
 Gauri Patwardhan <gauri.patwardhan@nutanix.com>, 
 Phil Auld <pauld@redhat.com>, Harshit Agarwal <harshit@nutanix.com>, 
 Jon Kohler <jon@nutanix.com>, Seiji Nishikawa <snishika@redhat.com>
Cc: Rahul Chunduru <rahul.chunduru@nutanix.com>, 
 linux-kernel@vger.kernel.org, 
 "Josh Lafleur (Zipline)" <josh.lafleur@outlook.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795461730; l=3070;
 i=josh.lafleur@outlook.com; s=20260930; h=from:subject:message-id;
 bh=xltmhTC4RivVjUMo09gIqOcjEP9mbokiZAZj+95EZ6g=;
 b=0YV6/7c+5cwgzNUPkUGAx13DqJZ7wyn8eIKKFO7PbXP4S4QivJ70H5drE25ME4KwOFRVOccSG
 AC1btqTljKgDrHVaiRajvKgXBEoYu2d78o0PxApzIPRK6+D6ubTRfX0
X-Developer-Key: i=josh.lafleur@outlook.com; a=ed25519;
 pk=slf3cskRg11vRnFROP6D9bMBKyvvRNsP2Msvm4/qpmM=
X-Endpoint-Received: by B4 Relay for josh.lafleur@outlook.com/20260930 with auth_id=1090
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Commit a7c81556ec4d ("sched: Fix migrate_disable() vs rt/dl
balancing") added a PUSH_IPI fallback for a migrate-disabled RT
candidate. It runs the stopper to move the running task so that the
pinned task can run on its current CPU.

Commit dae5c0292080 ("sched/rt,dl: Skip migrate-disabled tasks when
picking a push candidate") made the RT picker skip pinned candidates.
This avoids futile ordinary pushes, but also prevents the push-IPI
path from reaching that fallback.

Select migrate-disabled candidates on the PUSH_IPI path, while
continuing to skip them on ordinary pushes. An ordinary push can
therefore still reach a movable task behind a pinned one. Use the
same selection mode when retrying after a failed destination search;
the head recheck for ordinary candidates continues to skip pinned
tasks.

The preceding patch allows the stopper target to pass the head
recheck after the source rq lock is reacquired.

Fixes: dae5c0292080 ("sched/rt,dl: Skip migrate-disabled tasks when picking a push candidate")
---
 kernel/sched/rt.c | 13 +++++++------
 1 file changed, 7 insertions(+), 6 deletions(-)

diff --git a/kernel/sched/rt.c b/kernel/sched/rt.c
index 54a6533cffe07..bb0d125889bd1 100644
--- a/kernel/sched/rt.c
+++ b/kernel/sched/rt.c
@@ -1866,7 +1866,7 @@ static int find_lowest_rq(struct task_struct *task)
 	return -1;
 }
 
-static struct task_struct *pick_next_pushable_task(struct rq *rq)
+static struct task_struct *pick_next_pushable_task(struct rq *rq, bool pull)
 {
 	struct plist_head *head = &rq->rt.pushable_tasks;
 	struct task_struct *i, *p = NULL;
@@ -1875,8 +1875,9 @@ static struct task_struct *pick_next_pushable_task(struct rq *rq)
 		return NULL;
 
 	plist_for_each_entry(i, head, pushable_tasks) {
-		/* skip tasks that cannot be migrated */
-		if (!task_on_cpu(rq, i) && !is_migration_disabled(i)) {
+		/* Only the push-IPI path can push the current task instead. */
+		if (!task_on_cpu(rq, i) &&
+		    (pull || !is_migration_disabled(i))) {
 			p = i;
 			break;
 		}
@@ -1941,7 +1942,7 @@ static struct rq *find_lock_lowest_rq(struct task_struct *task, struct rq *rq)
 			 */
 			if (unlikely(is_migration_disabled(task) ||
 				     !cpumask_test_cpu(lowest_rq->cpu, &task->cpus_mask) ||
-				     (task != pick_next_pushable_task(rq) &&
+				     (task != pick_next_pushable_task(rq, false) &&
 				      !stopper_push))) {
 
 				double_unlock_balance(rq, lowest_rq);
@@ -1976,7 +1977,7 @@ static int push_rt_task(struct rq *rq, bool pull)
 	if (!rq->rt.overloaded)
 		return 0;
 
-	next_task = pick_next_pushable_task(rq);
+	next_task = pick_next_pushable_task(rq, pull);
 	if (!next_task)
 		return 0;
 
@@ -2051,7 +2052,7 @@ static int push_rt_task(struct rq *rq, bool pull)
 		 * run-queue and is also still the next task eligible for
 		 * pushing.
 		 */
-		task = pick_next_pushable_task(rq);
+		task = pick_next_pushable_task(rq, pull);
 		if (task == next_task) {
 			/*
 			 * The task hasn't migrated, and is still the next

-- 
2.53.0

