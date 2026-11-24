From: Binoy Ravindran <binoy@vt.edu>
Date: Tue, 24 Nov 2026 10:34:28 -0500
Subject: [PATCH v2 2/3] livepatch: Include exiting tasks in the transition
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261124-klp-series-v3-v2-2-50d20829a337@vt.edu>
References: <20261124-klp-series-v3-v2-0-50d20829a337@vt.edu>
In-Reply-To: <20261124-klp-series-v3-v2-0-50d20829a337@vt.edu>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795534504; l=9609;
 i=binoy@vt.edu; s=20261123; h=from:subject:message-id;
 bh=XnMqwNzaNU1AF5/MG6N/6Y8Nr0WxhwQvs8LAFW65XSc=;
 b=EV54nj0CaDPFbaxOUvbzfOSow1cqAkE8rveUEIICF4djSKfgSx1raACBV+Rr1f+lYqC7CiPvd
 tLBDz+2MJ03BpkbcA3k4OCGJUgszq0zHHuFuJ8nPOdr4LBLu0JMyoDC
X-Developer-Key: i=binoy@vt.edu; a=ed25519;
 pk=4cNdKPHP0InmhK/9bb7Tm2ZMUXUvLGfw1pmVt5b98fA=
X-Endpoint-Received: by B4 Relay for binoy@vt.edu/20261123 with auth_id=1622
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The transition walks tasks with for_each_process_thread(). A
self-reaping task is unhashed in exit_notify() but keeps running the rest
of do_exit(), so the walk never sees it. The transition can then
complete, and with atomic replace the previous patch module can be
freed, while that task is still executing, or about to return into, the
previous module's copy of a patched function. This is the race discussed
in the thread linked below.

An exiting task is on an RCU-tasks exit list from exit_tasks_rcu_start(),
before exit_notify(), until exit_tasks_rcu_finish(). Make every step of
a transition also visit the tasks on these lists, using the helpers from
the previous patch. klp_init_transition(), klp_start_transition(),
klp_complete_transition(), klp_reverse_transition() and
klp_force_transition() only set fields and flags. They walk the exit
lists in place, under tasklist_lock, and skip tasks that are still
hashed, so that each task is visited exactly once.
klp_try_complete_transition() may inspect a task's stack, so it takes a
snapshot with a reference on each task. If the snapshot cannot be
allocated, or more tasks start exiting than it has room for, the
transition is treated as incomplete and retried. An exiting task must
therefore switch, like any other task, before the transition can
complete.

After exit_tasks_rcu_finish() the task may be on neither list, but it
can still run patched code until its final switch. do_exit() disables
preemption before exit_tasks_rcu_finish(), so from then on the task
cannot sleep, be preempted or migrate, and the next context switch on
its CPU is its last. klp_synchronize_transition() returns only after
every online CPU has switched context, so it waits out every task in this
stretch. Call it in two places:

- In klp_init_transition(), after patch_state has been set on every
  task and before func->transition is set. An exiting task that the
  walks did not visit had left the exit lists before or during them,
  so it is gone before any function enters the transition.

- In klp_try_complete_transition(), before klp_complete_transition().
  A task that left the exit lists unswitched after the snapshot is gone
  before func->transition is cleared and before the previous patch can
  be freed.

Covering the initialization and completion steps matters as well:
otherwise an exiting task keeps a stale patch_state from an earlier
transition, which can equal the new target. Likewise, the reverse path
clears TIF_PATCH_PENDING on exiting tasks and the force path updates
their patch state, so neither leaves an exiting task behind.
klp_send_signals() is not extended: a task that has passed exit_notify()
never returns to user space, so a fake signal cannot help it switch.

The exit lists exist only with CONFIG_TASKS_RCU, which every kernel
that can enable LIVEPATCH builds today. A following patch makes
LIVEPATCH select it.

Tested on v7.4-rc2, x86-64, under QEMU/KVM. Two klp-build livepatches
that each replace do_exit() replace each other ten times per run while
self-reaping tasks exit continuously, with a debug-only msleep() after
exit_notify() to widen the window. Without this series, 9 of 12 runs
crashed executing freed module memory after the previous patch was
removed. With it, all 12 runs completed their 120 replace cycles
without a fault. Without the delay, both kernels completed 60 cycles
without a fault.

Fixes: d83a7cb375ee ("livepatch: change to a per-task consistency model")
Link: https://lore.kernel.org/all/20250127063526.76687-1-laoar.shao@gmail.com/
Assisted-by: Claude:claude-opus-5-5
Signed-off-by: Binoy Ravindran <binoy@vt.edu>
---
 kernel/livepatch/transition.c | 98 +++++++++++++++++++++++++++++++++++++++++++
 1 file changed, 98 insertions(+)

diff --git a/kernel/livepatch/transition.c b/kernel/livepatch/transition.c
index 2351a19ac2a9..1889aea5b6ff 100644
--- a/kernel/livepatch/transition.c
+++ b/kernel/livepatch/transition.c
@@ -10,6 +10,7 @@
 #include <linux/cpu.h>
 #include <linux/stacktrace.h>
 #include <linux/static_call.h>
+#include <linux/slab.h>
 #include "core.h"
 #include "patch.h"
 #include "transition.h"
@@ -74,6 +75,84 @@ static void klp_synchronize_transition(void)
 	schedule_on_each_cpu(klp_sync);
 }
 
+static bool klp_try_switch_task(struct task_struct *task);
+
+/*
+ * Tasks past exit_notify() are off the task list but still run do_exit() and its
+ * callees, possibly from this patch's or a replaced patch's code, so the
+ * transition must cover them too. The try step inspects stacks, which needs a
+ * reference on each task, so it works on a snapshot of the exit lists.
+ *
+ * The other steps run with tasklist_lock held and skip tasks that are still
+ * hashed, so every task is visited exactly once: an exiting task can be on
+ * both lists until release_task() unhashes it.
+ */
+static bool klp_visit_exiting_tasks(rcu_tasks_exiting_fn_t fn, void *arg)
+{
+	struct task_struct **xt;
+	int i, n, max;
+
+	/*
+	 * Size the array from a count taken now, plus slack for tasks that
+	 * start exiting before the copy is made. If even more arrive, report
+	 * an incomplete walk: klp_try_complete_transition() runs again later.
+	 */
+	max = rcu_tasks_snapshot_exiting(NULL, 0) + 64;
+	xt = kvmalloc_array(max, sizeof(*xt), GFP_KERNEL);
+	if (!xt)
+		return false;
+	n = rcu_tasks_snapshot_exiting(xt, max);
+	for (i = 0; i < min(n, max); i++) {
+		fn(xt[i], arg);
+		put_task_struct(xt[i]);
+	}
+	kvfree(xt);
+	return n <= max;
+}
+
+static void klp_exiting_init(struct task_struct *t, void *arg)
+{
+	if (pid_alive(t))
+		return;	/* still on the task list: already visited */
+	t->patch_state = *(int *)arg;
+}
+
+static void klp_exiting_start(struct task_struct *t, void *arg)
+{
+	if (pid_alive(t))
+		return;	/* still on the task list: already visited */
+	if (t->patch_state != klp_target_state)
+		set_tsk_thread_flag(t, TIF_PATCH_PENDING);
+}
+
+static void klp_exiting_try(struct task_struct *t, void *arg)
+{
+	if (!klp_try_switch_task(t))
+		*(bool *)arg = false;
+}
+
+static void klp_exiting_complete(struct task_struct *t, void *arg)
+{
+	if (pid_alive(t))
+		return;	/* still on the task list: already visited */
+	clear_tsk_thread_flag(t, TIF_PATCH_PENDING);
+	t->patch_state = KLP_TRANSITION_IDLE;
+}
+
+static void klp_exiting_clear_pending(struct task_struct *t, void *arg)
+{
+	if (pid_alive(t))
+		return;	/* still on the task list: already visited */
+	clear_tsk_thread_flag(t, TIF_PATCH_PENDING);
+}
+
+static void klp_exiting_force(struct task_struct *t, void *arg)
+{
+	if (pid_alive(t))
+		return;	/* still on the task list: already visited */
+	klp_update_patch_state(t);
+}
+
 /*
  * The transition to the target patch state is complete.  Clean up the data
  * structures.
@@ -123,6 +202,7 @@ static void klp_complete_transition(void)
 		WARN_ON_ONCE(test_tsk_thread_flag(task, TIF_PATCH_PENDING));
 		task->patch_state = KLP_TRANSITION_IDLE;
 	}
+	rcu_tasks_visit_exiting(klp_exiting_complete, NULL);
 	read_unlock(&tasklist_lock);
 
 	for_each_possible_cpu(cpu) {
@@ -450,6 +530,8 @@ void klp_try_complete_transition(void)
 		if (!klp_try_switch_task(task))
 			complete = false;
 	read_unlock(&tasklist_lock);
+	if (!klp_visit_exiting_tasks(klp_exiting_try, &complete))
+		complete = false;
 
 	/*
 	 * Ditto for the idle "swapper" tasks.
@@ -489,6 +571,11 @@ void klp_try_complete_transition(void)
 	/* Done!  Now cleanup the data structures. */
 	klp_resched_disable();
 	patch = klp_transition_patch;
+	/*
+	 * A task can leave the exit lists unswitched after the snapshot. Wait until
+	 * every such task has made its final switch before completing.
+	 */
+	klp_synchronize_transition();
 	klp_complete_transition();
 
 	/*
@@ -526,6 +613,7 @@ void klp_start_transition(void)
 	for_each_process_thread(g, task)
 		if (task->patch_state != klp_target_state)
 			set_tsk_thread_flag(task, TIF_PATCH_PENDING);
+	rcu_tasks_visit_exiting(klp_exiting_start, NULL);
 	read_unlock(&tasklist_lock);
 
 	/*
@@ -579,6 +667,7 @@ void klp_init_transition(struct klp_patch *patch, int state)
 		WARN_ON_ONCE(task->patch_state != KLP_TRANSITION_IDLE);
 		task->patch_state = initial_state;
 	}
+	rcu_tasks_visit_exiting(klp_exiting_init, &initial_state);
 	read_unlock(&tasklist_lock);
 
 	/*
@@ -590,6 +679,13 @@ void klp_init_transition(struct klp_patch *patch, int state)
 		task->patch_state = initial_state;
 	}
 
+	/*
+	 * A task that has passed exit_tasks_rcu_finish() is on neither list but
+	 * may still call patched code until its final switch. It runs with
+	 * preemption disabled, so this returns only after every such task is gone.
+	 */
+	klp_synchronize_transition();
+
 	/*
 	 * Enforce the order of the task->patch_state initializations and the
 	 * func->transition updates to ensure that klp_ftrace_handler() doesn't
@@ -642,6 +738,7 @@ void klp_reverse_transition(void)
 	read_lock(&tasklist_lock);
 	for_each_process_thread(g, task)
 		clear_tsk_thread_flag(task, TIF_PATCH_PENDING);
+	rcu_tasks_visit_exiting(klp_exiting_clear_pending, NULL);
 	read_unlock(&tasklist_lock);
 
 	for_each_possible_cpu(cpu)
@@ -714,6 +811,7 @@ void klp_force_transition(void)
 	read_lock(&tasklist_lock);
 	for_each_process_thread(g, task)
 		klp_update_patch_state(task);
+	rcu_tasks_visit_exiting(klp_exiting_force, NULL);
 	read_unlock(&tasklist_lock);
 
 	for_each_possible_cpu(cpu)

-- 
2.39.5

