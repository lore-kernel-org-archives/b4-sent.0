From: Binoy Ravindran <binoy@vt.edu>
Date: Thu, 26 Nov 2026 11:41:32 -0500
Subject: [PATCH v4 1/3] rcu-tasks: Add helpers to visit tasks on the exit
 lists
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261126-klp-series-v3-v4-1-2ad73e9c9254@vt.edu>
References: <20261126-klp-series-v3-v4-0-2ad73e9c9254@vt.edu>
In-Reply-To: <20261126-klp-series-v3-v4-0-2ad73e9c9254@vt.edu>
To: "Paul E. McKenney" <paulmck@kernel.org>, 
 Frederic Weisbecker <frederic@kernel.org>, 
 Neeraj Upadhyay <neeraj.upadhyay@kernel.org>, 
 Joel Fernandes <joelagnelf@nvidia.com>, 
 Josh Triplett <josh@joshtriplett.org>, Boqun Feng <boqun@kernel.org>, 
 Uladzislau Rezki <urezki@gmail.com>, Steven Rostedt <rostedt@goodmis.org>, 
 Mathieu Desnoyers <mathieu.desnoyers@efficios.com>, 
 Lai Jiangshan <jiangshanlai@gmail.com>, Zqiang <qiang.zhang@linux.dev>, 
 Josh Poimboeuf <jpoimboe@kernel.org>, Miroslav Benes <mbenes@suse.cz>, 
 Petr Mladek <pmladek@suse.com>, Joe Lawrence <joe.lawrence@redhat.com>, 
 Song Liu <song@kernel.org>, Ingo Molnar <mingo@kernel.org>, 
 Jiri Kosina <jikos@kernel.org>
Cc: rcu@vger.kernel.org, linux-kernel@vger.kernel.org, 
 live-patching@vger.kernel.org, Yafang Shao <laoar.shao@gmail.com>, 
 Jaidev Shastri <jaidevshastri@vt.edu>, Binoy Ravindran <binoy@vt.edu>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795711306; l=6595;
 i=binoy@vt.edu; s=20261123; h=from:subject:message-id;
 bh=yjPjOhb/Atfnqas8UHt57mA11woD8FJQKXxBGP8uW1s=;
 b=9JjPDopv/FzV2BE3xbWYnLkY5+zY4UuS+0XPxoaBGbdW7BTJTeK0Pcql70MxVQZWLAQPAeXBn
 XAIT0NcWOufAJvcIHZsR7T3op/SkJsYzkKuc1LbDvY7bmUXkAHIB2WY
X-Developer-Key: i=binoy@vt.edu; a=ed25519;
 pk=4cNdKPHP0InmhK/9bb7Tm2ZMUXUvLGfw1pmVt5b98fA=
X-Endpoint-Received: by B4 Relay for binoy@vt.edu/20261123 with auth_id=1622
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A task joins its CPU's RCU-tasks exit list in exit_tasks_rcu_start(),
before exit_notify() unhashes it from the task list, and leaves it in
exit_tasks_rcu_finish(), after do_exit() has disabled preemption for the
final switch. Once exit_notify() has unhashed it, the task is no longer
found by for_each_process_thread(), but it still runs do_exit() and may
sleep there. Code that must reach every task that can still be
descheduled, such as the livepatch transition, has no way to find it.

Add two helpers. rcu_tasks_visit_exiting() calls a function on each
task on the exit lists under the list locks, without allocating.
rcu_tasks_snapshot_exiting() copies the tasks into a caller-supplied
array with a reference held on each, for callers that must sleep or take
other locks while examining them. Without CONFIG_TASKS_RCU there are no
exit lists, and the helpers do nothing.

rcu_tasks_postscan() keeps its place in an exit list with a bare
list_head while it drops the lock to reschedule, relying on nobody else
traversing the list. Move that cursor into struct rcu_tasks_percpu,
next to the list it marks, so that the new helpers can recognize and
skip it. Only the grace-period kthread runs postscan, one CPU's list at
a time, so one cursor per CPU suffices.

Assisted-by: Claude:claude-opus-5-5
Signed-off-by: Binoy Ravindran <binoy@vt.edu>
---
 include/linux/rcupdate.h |  9 +++++++
 kernel/rcu/tasks.h       | 69 +++++++++++++++++++++++++++++++++++++++++++-----
 2 files changed, 72 insertions(+), 6 deletions(-)

diff --git a/include/linux/rcupdate.h b/include/linux/rcupdate.h
index 3f74ae6d6e1f..55b8b4a0fa94 100644
--- a/include/linux/rcupdate.h
+++ b/include/linux/rcupdate.h
@@ -214,6 +214,15 @@ static inline void exit_tasks_rcu_start(void) { }
 static inline void exit_tasks_rcu_finish(void) { }
 #endif /* #else #ifdef CONFIG_TASKS_RCU_GENERIC */
 
+typedef void (*rcu_tasks_exiting_fn_t)(struct task_struct *t, void *arg);
+#ifdef CONFIG_TASKS_RCU
+void rcu_tasks_visit_exiting(rcu_tasks_exiting_fn_t fn, void *arg);
+int rcu_tasks_snapshot_exiting(struct task_struct **buf, int max);
+#else
+static inline void rcu_tasks_visit_exiting(rcu_tasks_exiting_fn_t fn, void *arg) { }
+static inline int rcu_tasks_snapshot_exiting(struct task_struct **buf, int max) { return 0; }
+#endif
+
 /**
  * cond_resched_tasks_rcu_qs - Report potential quiescent states to RCU
  *
diff --git a/kernel/rcu/tasks.h b/kernel/rcu/tasks.h
index fcac7361ec51..b5fa5a3a8503 100644
--- a/kernel/rcu/tasks.h
+++ b/kernel/rcu/tasks.h
@@ -33,6 +33,8 @@ typedef void (*postgp_func_t)(struct rcu_tasks *rtp);
  * @barrier_q_head: RCU callback for barrier operation.
  * @rtp_blkd_tasks: List of tasks blocked as readers.
  * @rtp_exit_list: List of tasks in the latter portion of do_exit().
+ * @rtp_exit_cursor: Placeholder that rcu_tasks_postscan() parks on @rtp_exit_list
+ *	while it drops the lock, so that exit-list walkers can skip it.
  * @cpu: CPU number corresponding to this entry.
  * @index: Index of this CPU in rtpcp_array of the rcu_tasks structure.
  * @rtpp: Pointer to the rcu_tasks structure.
@@ -49,6 +51,7 @@ struct rcu_tasks_percpu {
 	struct rcu_head barrier_q_head;
 	struct list_head rtp_blkd_tasks;
 	struct list_head rtp_exit_list;
+	struct list_head rtp_exit_cursor;
 	int cpu;
 	int index;
 	struct rcu_tasks *rtpp;
@@ -1068,7 +1071,6 @@ static void rcu_tasks_postscan(struct list_head *hop)
 		struct rcu_tasks_percpu *rtpcp = per_cpu_ptr(rcu_tasks.rtpcpu, cpu);
 		struct task_struct *t;
 		struct task_struct *t1;
-		struct list_head tmp;
 
 		raw_spin_lock_irq_rcu_node(rtpcp);
 		list_for_each_entry_safe(t, t1, &rtpcp->rtp_exit_list, rcu_tasks_exit_list) {
@@ -1081,14 +1083,15 @@ static void rcu_tasks_postscan(struct list_head *hop)
 				continue;
 
 			// Keep our place in the list while pausing.
-			// Nothing else traverses this list, so adding a
-			// bare list_head is OK.
-			list_add(&tmp, &t->rcu_tasks_exit_list);
+			// The cursor lives in rtpcp so that the exit-list
+			// visitors can recognize and skip it.
+			list_add(&rtpcp->rtp_exit_cursor, &t->rcu_tasks_exit_list);
 			raw_spin_unlock_irq_rcu_node(rtpcp);
 			cond_resched(); // For CONFIG_PREEMPT=n kernels
 			raw_spin_lock_irq_rcu_node(rtpcp);
-			t1 = list_entry(tmp.next, struct task_struct, rcu_tasks_exit_list);
-			list_del(&tmp);
+			t1 = list_entry(rtpcp->rtp_exit_cursor.next, struct task_struct,
+					rcu_tasks_exit_list);
+			list_del(&rtpcp->rtp_exit_cursor);
 			j = jiffies + 1;
 		}
 		raw_spin_unlock_irq_rcu_node(rtpcp);
@@ -1332,6 +1335,60 @@ void exit_tasks_rcu_finish(void)
 	raw_spin_unlock_irqrestore_rcu_node(rtpcp, flags);
 }
 
+/*
+ * Call fn on every task on the exit lists, in place, with the per-CPU list
+ * lock held and interrupts disabled. fn must not sleep. Does not allocate.
+ * These are the tasks that have passed exit_tasks_rcu_start() but not
+ * exit_tasks_rcu_finish(). Once exit_notify() has run they are no longer on
+ * the task list, but they still run do_exit() and may sleep there.
+ */
+void rcu_tasks_visit_exiting(rcu_tasks_exiting_fn_t fn, void *arg)
+{
+	int cpu;
+	unsigned long flags;
+	struct task_struct *t;
+
+	for_each_possible_cpu(cpu) {
+		struct rcu_tasks_percpu *rtpcp = per_cpu_ptr(rcu_tasks.rtpcpu, cpu);
+
+		raw_spin_lock_irqsave_rcu_node(rtpcp, flags);
+		list_for_each_entry(t, &rtpcp->rtp_exit_list, rcu_tasks_exit_list) {
+			if (&t->rcu_tasks_exit_list == &rtpcp->rtp_exit_cursor)
+				continue;
+			fn(t, arg);
+		}
+		raw_spin_unlock_irqrestore_rcu_node(rtpcp, flags);
+	}
+}
+
+/*
+ * Copy up to max tasks on the exit lists into buf, taking a reference on
+ * each. Returns the number of tasks on the lists, which may exceed max.
+ */
+int rcu_tasks_snapshot_exiting(struct task_struct **buf, int max)
+{
+	int cpu, n = 0;
+	unsigned long flags;
+	struct task_struct *t;
+
+	for_each_possible_cpu(cpu) {
+		struct rcu_tasks_percpu *rtpcp = per_cpu_ptr(rcu_tasks.rtpcpu, cpu);
+
+		raw_spin_lock_irqsave_rcu_node(rtpcp, flags);
+		list_for_each_entry(t, &rtpcp->rtp_exit_list, rcu_tasks_exit_list) {
+			if (&t->rcu_tasks_exit_list == &rtpcp->rtp_exit_cursor)
+				continue;
+			if (n < max) {
+				get_task_struct(t);
+				buf[n] = t;
+			}
+			n++;
+		}
+		raw_spin_unlock_irqrestore_rcu_node(rtpcp, flags);
+	}
+	return n;
+}
+
 #else /* #ifdef CONFIG_TASKS_RCU */
 void exit_tasks_rcu_start(void) { }
 void exit_tasks_rcu_finish(void) { }

-- 
2.39.5

