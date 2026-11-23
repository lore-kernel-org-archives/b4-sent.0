From: "Josh Lafleur (Zipline)" <josh.lafleur@outlook.com>
Date: Mon, 23 Nov 2026 11:21:43 -0800
Subject: [PATCH 1/2] sched/rt: Allow queued stopper targets past the
 pushable-head check
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261123-migrate-on-ipi-v1-1-eacfe7e4b808@outlook.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795461730; l=2708;
 i=josh.lafleur@outlook.com; s=20260930; h=from:subject:message-id;
 bh=o4GzxLYqqTV3IeOkvWTrIx4wPgWzaqGktUyZ0rosvB8=;
 b=F7U76h1hy9eXYv5ekR6RwyYyecYwEn7/TSFjYsIfG3AIoeP1vWcvQZmmTUO6sMmuxcHGoHYJ9
 fD7ipgBdECoDNS1NCHjwELfyxCVSwWyzn/Bw5kG80/HmMxdIMfoaqpw
X-Developer-Key: i=josh.lafleur@outlook.com; a=ed25519;
 pk=slf3cskRg11vRnFROP6D9bMBKyvvRNsP2Msvm4/qpmM=
X-Endpoint-Received: by B4 Relay for josh.lafleur@outlook.com/20260930 with auth_id=1090
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Commit a7c81556ec4d ("sched: Fix migrate_disable() vs rt/dl
balancing") added a stopper push when RT balancing cannot push a
migrate-disabled task which moves the running task so the pinned
task can run locally. The PUSH_IPI path can request the same fallback
when it selects a pinned push candidate.

Commit 690e47d1403e ("sched/rt: Fix race in push_rt_task") added a
pushable-head check after find_lock_lowest_rq() drops and reacquires
the source rq lock. That check protects ordinary pushes, but can
reject a queued stopper target when another task remains ahead of it
in the pushable list. The stopper then gives up without moving the
task. Since we know in the stopper push case the rq is actively
owning the last running task and the rq is push_busy, we can be
confident that it will not be migrated between the push_rt_task()
and subsequent stopper handler.

Allow a queued stopper target that is still on the source rq to pass
the head comparison. Keep the migration-disable and affinity checks,
and retain the head comparison for ordinary pushes. This also makes
the PUSH_IPI fallback usable when pinned candidates are selected by
the following patch.

Fixes: 690e47d1403e ("sched/rt: Fix race in push_rt_task")
---
 kernel/sched/rt.c | 11 +++++++++--
 1 file changed, 9 insertions(+), 2 deletions(-)

diff --git a/kernel/sched/rt.c b/kernel/sched/rt.c
index 1535046a23ffa..54a6533cffe07 100644
--- a/kernel/sched/rt.c
+++ b/kernel/sched/rt.c
@@ -1923,19 +1923,26 @@ static struct rq *find_lock_lowest_rq(struct task_struct *task, struct rq *rq)
 
 		/* if the prio of this runqueue changed, try again */
 		if (double_lock_balance(rq, lowest_rq)) {
+			bool stopper_push = rq->push_busy &&
+					    (rq->curr == rq->stop) &&
+					    (task_rq(task) == rq) &&
+					    task_on_rq_queued(task);
+
 			/*
 			 * We had to unlock the run queue. In
 			 * the mean time, task could have
 			 * migrated already or had its affinity changed,
 			 * therefore check if the task is still at the
-			 * head of the pushable tasks list.
+			 * head of the pushable tasks list. A queued stopper
+			 * target need not be at the head of that list.
 			 * It is possible the task was scheduled, set
 			 * "migrate_disabled" and then got preempted, so we must
 			 * check the task migration disable flag here too.
 			 */
 			if (unlikely(is_migration_disabled(task) ||
 				     !cpumask_test_cpu(lowest_rq->cpu, &task->cpus_mask) ||
-				     task != pick_next_pushable_task(rq))) {
+				     (task != pick_next_pushable_task(rq) &&
+				      !stopper_push))) {
 
 				double_unlock_balance(rq, lowest_rq);
 				lowest_rq = NULL;

-- 
2.53.0

