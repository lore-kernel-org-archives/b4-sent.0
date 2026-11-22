From: Hang Zhengyang <hang.zhengyang1010@gmail.com>
Date: Mon, 23 Nov 2026 02:04:55 +0800
Subject: [PATCH sched_ext/for-7.4-fixes 2/2] sched_ext: Start ext_server on
 every enqueue
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261123-scx-dlsrv-v1-2-87c342d8246e@gmail.com>
References: <20261123-scx-dlsrv-v1-0-87c342d8246e@gmail.com>
In-Reply-To: <20261123-scx-dlsrv-v1-0-87c342d8246e@gmail.com>
To: Tejun Heo <tj@kernel.org>, David Vernet <void@manifault.com>, 
 Andrea Righi <arighi@nvidia.com>, Changwoo Min <changwoo@igalia.com>, 
 Ingo Molnar <mingo@redhat.com>, Peter Zijlstra <peterz@infradead.org>, 
 Juri Lelli <juri.lelli@redhat.com>, 
 Vincent Guittot <vincent.guittot@linaro.org>, 
 Dietmar Eggemann <dietmar.eggemann@arm.com>, 
 Steven Rostedt <rostedt@goodmis.org>, Ben Segall <bsegall@google.com>, 
 Mel Gorman <mgorman@suse.de>, Valentin Schneider <vschneid@redhat.com>, 
 K Prateek Nayak <kprateek.nayak@amd.com>
Cc: Joel Fernandes <joelagnelf@nvidia.com>, sched-ext@lists.linux.dev, 
 linux-kernel@vger.kernel.org, stable@vger.kernel.org, 
 Hang Zhengyang <hang.zhengyang1010@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795370696; l=2788;
 i=hang.zhengyang1010@gmail.com; s=20261008; h=from:subject:message-id;
 bh=IN+RzU0ozG0gu9jpgj8RQX7xnqAmt1p/9Ryev7xZsHs=;
 b=PBlzI9W8mu3TSEauajkWdQrAzd1AqzlaCENqlVjkb4t0v+4rFy34xdXGM5gfws4X31CEenbmz
 J5mBQnzaSbJDb/CHHWnwHEP9oZMXC+/uynAZfLq+Dk6hzmBLX9Vi1OS
X-Developer-Key: i=hang.zhengyang1010@gmail.com; a=ed25519;
 pk=5drRny3PqRPLhKVB0YIQXN5YyD8miKCpXWhnEPvafAI=
X-Endpoint-Received: by B4 Relay for hang.zhengyang1010@gmail.com/20261008 with auth_id=1133
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Since commit a3a70caf7906 ("sched/deadline: Fix dl_server behaviour"),
ext_server stops when a pick finds no task, and a later wakeup starts
it again. But enqueue_task_scx() starts it only when
rq->scx.nr_running goes from 0 to 1.

For sched_ext, a pick can find no task while tasks are still counted on
the rq. During a disable, scx_claim_exit() sets sch->aborting. After
that, scx_consume_dispatch_q() no longer takes tasks from the
scheduler's DSQs. nr_running stays above 0, so no enqueue restarts the
server. An RT task that keeps the CPU then starves the sched_ext tasks
there.

A stress test hit this on a debug kernel. While CPU hotplug was
disabling scx_simple, the server on CPU 0 stopped with 3 tasks counted.
A SCHED_FIFO spinner then took the CPU with 15 tasks behind it. One of
them was the RCU grace-period kthread:

  rcu: rcu_preempt kthread starved for 65011 jiffies! ... ->state=R ->cpu=0

The disable was waiting for a reader of scx_fork_rwsem and never
finished.

Call dl_server_start() on every enqueue. On a running server, it only
clears dl_defer_idle. On a stopped server that ran in this period, it
restarts the server at once and reschedules the CPU, even under an RT
task. So while picks find nothing, each enqueue costs one extra pick.
This lasts at most one server period (1 s by default).

Peter Zijlstra asked whether the server should start only when a task
reaches the local DSQ [1]. That is not enough. A task often gets to the
local DSQ only through this CPU's own pick, and that pick needs the
server to run.

This doesn't cover a task that another CPU dispatches to this CPU's
local DSQ.

Link: https://lore.kernel.org/all/20260202195035.GG1282955@noisy.programming.kicks-ass.net/ [1]
Fixes: cd959a356205 ("sched_ext: Add a DL server for sched_ext tasks")
Cc: stable@vger.kernel.org # v7.0+
Signed-off-by: Hang Zhengyang <hang.zhengyang1010@gmail.com>
---
 kernel/sched/ext/ext.c | 8 +++++---
 1 file changed, 5 insertions(+), 3 deletions(-)

diff --git a/kernel/sched/ext/ext.c b/kernel/sched/ext/ext.c
index 23294897dd6e..1031267508fd 100644
--- a/kernel/sched/ext/ext.c
+++ b/kernel/sched/ext/ext.c
@@ -2501,9 +2501,11 @@ static void enqueue_task_scx(struct rq *rq, struct task_struct *p, int core_enq_
 	if (SCX_HAS_OP(sch, runnable) && !task_on_rq_migrating(p))
 		SCX_CALL_OP_TASK(sch, runnable, rq, p, enq_flags);
 
-	/* Start dl_server if this is the first task being enqueued */
-	if (rq->scx.nr_running == 1)
-		dl_server_start(&rq->ext_server);
+	/*
+	 * Start on every enqueue: a pick can stop the server while tasks
+	 * counted here are out of its reach.
+	 */
+	dl_server_start(&rq->ext_server);
 
 	scx_do_enqueue_task(rq, p, enq_flags, sticky_cpu);
 out:

-- 
2.53.0

