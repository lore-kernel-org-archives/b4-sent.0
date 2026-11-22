From: Hang Zhengyang <hang.zhengyang1010@gmail.com>
Date: Mon, 23 Nov 2026 02:04:54 +0800
Subject: [PATCH sched_ext/for-7.4-fixes 1/2] sched_ext: Attach fair_server
 before tasks fall back to fair on disable
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261123-scx-dlsrv-v1-1-87c342d8246e@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795370696; l=3219;
 i=hang.zhengyang1010@gmail.com; s=20261008; h=from:subject:message-id;
 bh=nZIUfbuOGTYsYcOP54zg7VH1iW7P5BzO0zfHVPDdacg=;
 b=7CgecdzBpDWmPQ+JV4LPQHJrvsL1ONJxu379+NJXAPNuMCNvriXWfwRcK17nY+MFZqjKpgDXt
 46jlWcEQPI/DB1jd/NwyIKYhksNo0Qiz3wPBRIFzQWfYIPednQV7g+U
X-Developer-Key: i=hang.zhengyang1010@gmail.com; a=ed25519;
 pk=5drRny3PqRPLhKVB0YIQXN5YyD8miKCpXWhnEPvafAI=
X-Endpoint-Received: by B4 Relay for hang.zhengyang1010@gmail.com/20261008 with auth_id=1133
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

In full mode, the enable path detaches fair_server, since no task runs
in the fair class. scx_root_disable() attaches it again only at the end,
in the dl_server_swap_bw() loop. But tasks fall back to fair well before
that. New forks and sched_setscheduler() calls do so once
scx_switching_all is cleared, and the switch loop moves all other tasks.
Until the swap, fair_server can't start, so an RT task that keeps a CPU
starves the fair tasks there.

Meanwhile, the disable path waits for RCU grace periods in
percpu_down_write() of scx_fork_rwsem and scx_cgroup_ops_rwsem. A grace
period can wait for a starved task, so the disable doesn't finish until
the RT task stops. The starved task can be a reader preempted under
PREEMPT_RCU, or the grace-period kthread itself. While the disable waits
in the scx_cgroup_lock() after the switch loop, scx_fork_rwsem and
cgroup_mutex are held, so forks wait too.

To reproduce, load scx_simple, pin SCHED_NORMAL tasks (/proc walkers,
stress-ng --fork) and a SCHED_FIFO spinner to CPU 1, and unload the
scheduler 50 ms after the spinner starts. The disable can then get
stuck in:

  synchronize_rcu_normal+0x1da/0x1f0
  rcu_sync_enter+0x56/0x140
  scx_root_disable+0x230/0x420
  kthread_worker_fn+0xf0/0x270

until the spinner stops.

Attach fair_server before tasks start to fall back, the same way the
enable path attaches ext_server before tasks switch to it. If the root
domain can't fit both servers, the swap attaches fair_server as before.

Fixes: e7b63427fdb4 ("sched_ext: Auto-register/unregister dl_server reservations")
Cc: stable@vger.kernel.org # v7.2+
Signed-off-by: Hang Zhengyang <hang.zhengyang1010@gmail.com>
---
 kernel/sched/ext/ext.c | 19 +++++++++++++++++--
 1 file changed, 17 insertions(+), 2 deletions(-)

diff --git a/kernel/sched/ext/ext.c b/kernel/sched/ext/ext.c
index e8c30a21e03e..23294897dd6e 100644
--- a/kernel/sched/ext/ext.c
+++ b/kernel/sched/ext/ext.c
@@ -7576,6 +7576,21 @@ static void scx_root_disable(struct scx_sched *sch)
 
 	was_switched_all = scx_switched_all();
 
+	/*
+	 * Tasks fall back to fair from here on. Attach fair_server now, or an
+	 * RT task can starve them while we wait for RCU grace periods below.
+	 * If its bandwidth doesn't fit, the swap at the end attaches it.
+	 */
+	if (was_switched_all) {
+		for_each_possible_cpu(cpu) {
+			struct rq *rq = cpu_rq(cpu);
+
+			guard(rq_lock_irqsave)(rq);
+			update_rq_clock(rq);
+			dl_server_attach_bw(&rq->fair_server);
+		}
+	}
+
 	static_branch_disable(&__scx_switched_all);
 	WRITE_ONCE(scx_switching_all, false);
 	WRITE_ONCE(scx_task_switch_enabled, false);
@@ -7626,8 +7641,8 @@ static void scx_root_disable(struct scx_sched *sch)
 
 	/*
 	 * Re-balance the dl_server bandwidth reservations: detach ext_server
-	 * (no more sched_ext tasks) and reinstate fair_server if it was
-	 * previously detached because we were running in full mode.
+	 * (no more sched_ext tasks) and attach fair_server if the attach
+	 * above failed.
 	 *
 	 * Unlike the enable path, this runs on a recovery path that cannot
 	 * fail, so we use dl_server_swap_bw() to atomically free ext_server's

-- 
2.53.0

