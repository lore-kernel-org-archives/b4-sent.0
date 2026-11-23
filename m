From: Binoy Ravindran <binoy@vt.edu>
Date: Mon, 23 Nov 2026 15:52:16 -0500
Subject: [PATCH 2/2] livepatch: Include exiting tasks in the transition
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261123-klp-series-v3-v1-2-427c95811d9b@vt.edu>
References: <20261123-klp-series-v3-v1-0-427c95811d9b@vt.edu>
In-Reply-To: <20261123-klp-series-v3-v1-0-427c95811d9b@vt.edu>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795467163; l=7421;
 i=binoy@vt.edu; s=20261123; h=from:subject:message-id;
 bh=DICXGKJPQRZsHdvzpkCU+AkCDTBnYgA2Bym/JeoST64=;
 b=9LGWfXDI3VkCdbrIIvoD5DE/NFNApyZ71G+KuUBj7IeOtCe8XzjaLAshZSLzWS+T7UZazhtu0
 XJ2+lklkdwYAMehFUge1IsU4p8IPgKK1S+g5KQAKDYugrJaA/uax4of
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

Make every step of a transition also visit the tasks on the RCU-tasks
exit lists, using the helpers from the previous patch.
klp_init_transition(), klp_start_transition(), klp_complete_transition(),
klp_reverse_transition() and klp_force_transition() only set fields and
flags, so they walk the lists in place under the list locks and cannot
fail. klp_try_complete_transition() may inspect a task's stack, so it
takes a snapshot with a reference on each task. If the snapshot cannot
be allocated, or more tasks start exiting than it has room for, the
transition is treated as incomplete and retried. An exiting task must
therefore switch, like any other task, before the transition can
complete.

Covering the initialization and completion steps matters as well:
otherwise an exiting task keeps a stale patch_state from an earlier
transition, which can equal the new target. Likewise, the reverse path
clears TIF_PATCH_PENDING on exiting tasks and the force path updates
their patch state, so neither leaves an exiting task behind.
klp_send_signals() is not extended: a task that has passed exit_notify()
never returns to user space, so a fake signal cannot help it switch.

After exit_tasks_rcu_finish() the task runs with preemption disabled
until its final switch, so it cannot sleep or be preempted while it is
off both lists. Kernels without CONFIG_TASKS_RCU have no exit lists, so
this change does not cover them.

Testing was done on v6.12.1, x86-64, under QEMU/KVM; this posting is a
forward port of that change. The test alternates two atomic-replace
livepatches that both replace do_exit() while self-reaping tasks exit
continuously, with a debug-only msleep() after exit_notify() to widen
the window. Without this series, 11 of 12 runs crash in the removed
module; with it, 0 of 12, and 0 of 12 for a control pair that does not
patch do_exit(). With the series, there were also no crashes in 1,200
replace cycles of a /proc mount/unmount stress test, or in 400 cycles
with preempt=full, with and without a real-time task contending for the
CPU of a busy-waiting exiting task. Without the delay, the series did
not change transition time: the median was 0.29 s with it and 0.27 to
0.31 s per run without it. The series does not change the exit path
itself.

Fixes: d83a7cb375ee ("livepatch: change to a per-task consistency model")
Link: https://lore.kernel.org/all/20250127063526.76687-1-laoar.shao@gmail.com/
Reviewed-by: Jaidev Shastri <jaidevshastri@vt.edu>
Assisted-by: Claude:claude-opus-5-5
Signed-off-by: Binoy Ravindran <binoy@vt.edu>
---
 kernel/livepatch/transition.c | 72 +++++++++++++++++++++++++++++++++++++++++++
 1 file changed, 72 insertions(+)

diff --git a/kernel/livepatch/transition.c b/kernel/livepatch/transition.c
index 2351a19ac2a9..cab167417190 100644
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
@@ -74,6 +75,70 @@ static void klp_synchronize_transition(void)
 	schedule_on_each_cpu(klp_sync);
 }
 
+static bool klp_try_switch_task(struct task_struct *task);
+
+/*
+ * Tasks past exit_notify() are off the task list but still run do_exit() and its
+ * callees, possibly from this patch's or a replaced patch's code, so the
+ * transition must cover them too. The try step inspects stacks, which needs a
+ * reference on each task, so it works on a snapshot of the exit lists.
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
+	t->patch_state = *(int *)arg;
+}
+
+static void klp_exiting_start(struct task_struct *t, void *arg)
+{
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
+	clear_tsk_thread_flag(t, TIF_PATCH_PENDING);
+	t->patch_state = KLP_TRANSITION_IDLE;
+}
+
+static void klp_exiting_clear_pending(struct task_struct *t, void *arg)
+{
+	clear_tsk_thread_flag(t, TIF_PATCH_PENDING);
+}
+
+static void klp_exiting_force(struct task_struct *t, void *arg)
+{
+	klp_update_patch_state(t);
+}
+
 /*
  * The transition to the target patch state is complete.  Clean up the data
  * structures.
@@ -124,6 +189,7 @@ static void klp_complete_transition(void)
 		task->patch_state = KLP_TRANSITION_IDLE;
 	}
 	read_unlock(&tasklist_lock);
+	rcu_tasks_visit_exiting(klp_exiting_complete, NULL);
 
 	for_each_possible_cpu(cpu) {
 		task = idle_task(cpu);
@@ -450,6 +516,8 @@ void klp_try_complete_transition(void)
 		if (!klp_try_switch_task(task))
 			complete = false;
 	read_unlock(&tasklist_lock);
+	if (!klp_visit_exiting_tasks(klp_exiting_try, &complete))
+		complete = false;
 
 	/*
 	 * Ditto for the idle "swapper" tasks.
@@ -527,6 +595,7 @@ void klp_start_transition(void)
 		if (task->patch_state != klp_target_state)
 			set_tsk_thread_flag(task, TIF_PATCH_PENDING);
 	read_unlock(&tasklist_lock);
+	rcu_tasks_visit_exiting(klp_exiting_start, NULL);
 
 	/*
 	 * Mark all idle tasks as needing a patch state update.  They'll switch
@@ -580,6 +649,7 @@ void klp_init_transition(struct klp_patch *patch, int state)
 		task->patch_state = initial_state;
 	}
 	read_unlock(&tasklist_lock);
+	rcu_tasks_visit_exiting(klp_exiting_init, &initial_state);
 
 	/*
 	 * Ditto for the idle "swapper" tasks.
@@ -643,6 +713,7 @@ void klp_reverse_transition(void)
 	for_each_process_thread(g, task)
 		clear_tsk_thread_flag(task, TIF_PATCH_PENDING);
 	read_unlock(&tasklist_lock);
+	rcu_tasks_visit_exiting(klp_exiting_clear_pending, NULL);
 
 	for_each_possible_cpu(cpu)
 		clear_tsk_thread_flag(idle_task(cpu), TIF_PATCH_PENDING);
@@ -715,6 +786,7 @@ void klp_force_transition(void)
 	for_each_process_thread(g, task)
 		klp_update_patch_state(task);
 	read_unlock(&tasklist_lock);
+	rcu_tasks_visit_exiting(klp_exiting_force, NULL);
 
 	for_each_possible_cpu(cpu)
 		klp_update_patch_state(idle_task(cpu));

-- 
2.39.5

