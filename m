From: Hang Zhengyang <hang.zhengyang1010@gmail.com>
Date: Fri, 20 Nov 2026 16:44:22 +0800
Subject: [PATCH sched_ext/for-7.5 1/2] sched_ext: idle: Don't stack a sync
 wakee behind a higher-class task
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261120-scx-fix75-v1-1-254f782ff9b0@gmail.com>
References: <20261120-scx-fix75-v1-0-254f782ff9b0@gmail.com>
In-Reply-To: <20261120-scx-fix75-v1-0-254f782ff9b0@gmail.com>
To: Tejun Heo <tj@kernel.org>, David Vernet <void@manifault.com>, 
 Andrea Righi <arighi@nvidia.com>, Changwoo Min <changwoo@igalia.com>, 
 Ingo Molnar <mingo@redhat.com>, Peter Zijlstra <peterz@infradead.org>, 
 Juri Lelli <juri.lelli@redhat.com>, 
 Vincent Guittot <vincent.guittot@linaro.org>, 
 Dietmar Eggemann <dietmar.eggemann@arm.com>, 
 Steven Rostedt <rostedt@goodmis.org>, Ben Segall <bsegall@google.com>, 
 Mel Gorman <mgorman@suse.de>, Valentin Schneider <vschneid@redhat.com>, 
 K Prateek Nayak <kprateek.nayak@amd.com>, Shuah Khan <shuah@kernel.org>
Cc: Kuba Piecuch <jpiecuch@google.com>, 
 Jonathan Bastari Thamrin <thamrinjonathan@gmail.com>, 
 Hui Su <sh_def@163.com>, sched-ext@lists.linux.dev, 
 linux-kernel@vger.kernel.org, bpf@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, 
 Hang Zhengyang <hang.zhengyang1010@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795164273; l=3366;
 i=hang.zhengyang1010@gmail.com; s=20261008; h=from:subject:message-id;
 bh=XDlfptL4/63rv6xAwJeSPuaqpC6qexTX9EZsXa6XdeE=;
 b=+041VgJyuR080Y7h/zrFkwlzfmEXSrTActdVaCPfTvYKiDijZMidGqycmug0BVWAySZtC+EO0
 2NNuASmdAXDD3trtjhj9q2R1TZdKG0rJKoRLJrsGFG6ehfgS4OCidu5
X-Developer-Key: i=hang.zhengyang1010@gmail.com; a=ed25519;
 pk=5drRny3PqRPLhKVB0YIQXN5YyD8miKCpXWhnEPvafAI=
X-Endpoint-Received: by B4 Relay for hang.zhengyang1010@gmail.com/20261008 with auth_id=1133
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On a sync wakeup, scx_select_cpu_dfl() can return the waker's CPU. It
does this when the waker's local DSQ is empty and some CPU is idle,
because the waker is expected to give up its CPU soon.

This is wrong when the waker's CPU runs an RT or DL task, or a fair
task in partial mode. The BPF scheduler can't preempt such a task. The
wakee waits on the local DSQ until that task blocks, or until the ext
dl_server runs the wakee. Meanwhile, other CPUs are idle.

The waker may not sleep at all. pipe_write() and sock_def_readable()
always set WF_SYNC, even if the writer keeps running.

This affects every BPF scheduler that leaves CPU selection to the
kernel, or that passes SCX_WAKE_SYNC to scx_bpf_select_cpu_dfl() or
scx_bpf_select_cpu_and(). In an 8 vCPU guest with scx_simple, an RT
task on CPU 0 wrote to a pipe and kept spinning. In 16 of 16 wakeups,
the reader ran on CPU 0, 169 ms to 1.5 s later. With an eventfd write
instead, which is not a sync wakeup, the reader ran on an idle CPU
within 0.1 ms.

SCX_OPS_ALWAYS_ENQ_IMMED doesn't fix this. It re-enqueues the wakee,
but in the same test the wakee still ran 16 to 483 ms late. The fair
class doesn't have this problem. wake_affine_idle() also picks the
waker's CPU, but select_idle_sibling() only uses it if it is idle.

Skip the shortcut when a task of a higher class than EXT is running,
or about to run, on the waker's CPU. rq->next_class shows this, and
rq_is_open() uses the same check for SCX_ENQ_IMMED. The wakee then
goes to an idle CPU, as in any other wakeup. Sync wakeups between EXT
tasks don't change, unless a higher-class task is about to run on the
waker's CPU.

Signed-off-by: Hang Zhengyang <hang.zhengyang1010@gmail.com>
---
 kernel/sched/ext/idle.c | 11 +++++++++++
 1 file changed, 11 insertions(+)

diff --git a/kernel/sched/ext/idle.c b/kernel/sched/ext/idle.c
index 922fbc3065cc..bf4dd8cb4255 100644
--- a/kernel/sched/ext/idle.c
+++ b/kernel/sched/ext/idle.c
@@ -534,6 +534,7 @@ s32 scx_select_cpu_dfl(struct task_struct *p, s32 prev_cpu, u64 wake_flags,
 	 * If WAKE_SYNC, try to migrate the wakee to the waker's CPU.
 	 */
 	if (wake_flags & SCX_WAKE_SYNC) {
+		const struct sched_class *next_class;
 		int waker_node;
 
 		/*
@@ -559,9 +560,19 @@ s32 scx_select_cpu_dfl(struct task_struct *p, s32 prev_cpu, u64 wake_flags,
 		 * insufficient as the local DSQ of the waker could have tasks
 		 * piled up on it even if there is an idle core elsewhere on
 		 * the system.
+		 *
+		 * Also don't put @p behind a task of a higher class (RT, DL,
+		 * or fair in partial mode). The BPF scheduler can't preempt
+		 * that task, and it may keep the CPU for a long time. @p would
+		 * wait on the local DSQ until that task stops, or until the
+		 * ext dl_server runs @p. ->next_class also shows a higher-class
+		 * task that is about to run here. Reading it without the rq
+		 * lock is fine, since this is only a hint.
 		 */
+		next_class = READ_ONCE(cpu_rq(cpu)->next_class);
 		waker_node = scx_cpu_node_if_enabled(cpu);
 		if (!(current->flags & PF_EXITING) &&
+		    !sched_class_above(next_class, &ext_sched_class) &&
 		    cpu_rq(cpu)->scx.local_dsq.nr == 0 &&
 		    (!(flags & SCX_PICK_IDLE_IN_NODE) || (waker_node == node)) &&
 		    !cpumask_empty(idle_cpumask(waker_node)->cpu)) {

-- 
2.53.0

