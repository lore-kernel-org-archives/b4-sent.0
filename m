From: Mike Bazov <mikeba@sentinelone.com>
Date: Tue, 17 Nov 2026 13:29:16 +0200
Subject: [PATCH bpf-next v3 3/4] bpf: Check program recursion per task via
 bpf_ctx
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261117-bpf-preempt-v2-r2-v3-3-586376ec3672@sentinelone.com>
References: <20261117-bpf-preempt-v2-r2-v3-0-586376ec3672@sentinelone.com>
In-Reply-To: <20261117-bpf-preempt-v2-r2-v3-0-586376ec3672@sentinelone.com>
To: bpf@vger.kernel.org, Alexei Starovoitov <ast@kernel.org>, 
 Daniel Borkmann <daniel@iogearbox.net>, Andrii Nakryiko <andrii@kernel.org>
Cc: Martin KaFai Lau <martin.lau@linux.dev>, 
 Eduard Zingerman <eddyz87@gmail.com>, 
 Kumar Kartikeya Dwivedi <memxor@gmail.com>, Song Liu <song@kernel.org>, 
 Yonghong Song <yonghong.song@linux.dev>, Jiri Olsa <jolsa@kernel.org>, 
 John Fastabend <john.fastabend@gmail.com>, 
 Emil Tsalapatis <emil@etsalapatis.com>, 
 Ihor Solodrai <ihor.solodrai@linux.dev>, 
 Steven Rostedt <rostedt@goodmis.org>, 
 Masami Hiramatsu <mhiramat@kernel.org>, 
 Mathieu Desnoyers <mathieu.desnoyers@efficios.com>, 
 JP Kobryn <jp.kobryn@linux.dev>, linux-trace-kernel@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Mike Bazov <mikeba@sentinelone.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794914965; l=17100;
 i=mikeba@sentinelone.com; s=20261022; h=from:subject:message-id;
 bh=Cs3m7sP+M8pDEVDYqCJI2djblo8/YU3DYyYJGAsHEi8=;
 b=XwrPNyeXpwzH/qhZ71lf1GE0XsMdgTknkIE4C8i0rOaOK3u8vvXHswzwD7bnGgMayBicrrnCZ
 Zl0wmsvi6DRCufrWX5pK19XiM097sw5nMhwN0oORhaIzeVEPMZLbEma
X-Developer-Key: i=mikeba@sentinelone.com; a=ed25519;
 pk=DBXcQ0qoCkgacRsRwT1JU7oOWpWSYuTyLiXMfNLcP+A=
X-Endpoint-Received: by B4 Relay for mikeba@sentinelone.com/20261022 with auth_id=1284
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Trampoline programs (fentry, fexit, fsession, fmod_ret and their
sleepable variants), raw tracepoint programs (raw_tp, raw_tp.s, tp_btf)
and tracepoint programs on syscall tracepoints run preemptibly, but
their recursion check is a per-CPU, per-program counter. When a task is
preempted inside a program, the counter stays raised, and every other
task that enters the program on that CPU is dropped and counted as a
recursion miss, although nothing recursed. A program can't avoid that:
the counter is checked before its first insn.

Since commit 7dadeaa6e851 ("sched: Further restrict the preemption
modes") x86 and arm64 have only lazy and full preemption, so this
happens in normal operation. A security agent that pairs fentry and
fexit programs on inet_sendmsg() and inet_recvmsg() loses one half of a
pair with every drop. With 200,000 HTTP requests and four CPU-bound
tasks on a 4-CPU VM, 9,254 of 7,966,760 runs of these programs were
dropped on bpf-next, and none of 7,975,426 with this series.

Check recursion per task instead. The runners already link a
stack-allocated bpf_run_ctx into current->bpf_ctx. Move saved_run_ctx
into struct bpf_run_ctx, so every frame links to the outer one, and
record in each frame the program it runs. A program is recursing if a
frame in the current task's chain already runs it. Interrupts and NMIs
run on top of the interrupted task's chain, so recursion through them
is still caught.

bpf_prog_enter_run_ctx() and bpf_prog_exit_run_ctx() do the check for
all runners. The syscall tracepoint runner linked one frame around its
program array and now links one per program. bpf_set_run_ctx() accepts
a NULL ctx, which io_uring passes to hide the BPF context; the frames
below are not walked while it is hidden.

Programs marked by the previous patch keep the per-CPU counter and
behave exactly as before, so no counted drop is traded for corrupted
per-CPU data or a renewed may_goto budget. An extension (freplace) runs
under the check of its target, so a marked one can't be attached to a
target that is checked per task.

Trade-offs:

- An unmarked program that keeps per-CPU slots of its own, see the
  previous patch, can have two runs use one slot, and nothing counts
  that.
- Marked programs lose runs to preemption as before.
- bench trig-rawtp is about 2% slower: 42.6 and 42.1 M/s on bpf-next,
  41.3 and 41.5 M/s with the series. trig-fentry and trig-fexit are
  not slower.
- Attaching a marked extension to an unmarked raw_tp, tp_btf or
  tracepoint program now fails with -EINVAL.

Signed-off-by: Mike Bazov <mikeba@sentinelone.com>
---
 include/linux/bpf.h          | 95 ++++++++++++++++++++++++++++++++++++++------
 include/linux/bpf_verifier.h | 19 +++++++++
 kernel/bpf/syscall.c         | 10 +++++
 kernel/bpf/trampoline.c      | 26 +++++-------
 kernel/trace/bpf_trace.c     | 11 ++---
 net/bpf/test_run.c           |  9 +----
 net/ipv4/bpf_tcp_ops.c       |  6 +--
 7 files changed, 129 insertions(+), 47 deletions(-)

diff --git a/include/linux/bpf.h b/include/linux/bpf.h
index 7873f0ef2817..97cbcd4b0d67 100644
--- a/include/linux/bpf.h
+++ b/include/linux/bpf.h
@@ -2783,7 +2783,16 @@ int bpf_prog_array_copy(struct bpf_prog_array *old_array,
 			struct bpf_prog_array **new_array);
 struct bpf_prog *bpf_prog_dummy(void);
 
-struct bpf_run_ctx {};
+/*
+ * A frame in the chain of the programs that a task is running, from
+ * current->bpf_ctx to the outermost one.
+ */
+struct bpf_run_ctx {
+	/* The next outer frame, NULL in the outermost one */
+	struct bpf_run_ctx *saved_run_ctx;
+	/* Set while a program whose recursion is checked per task runs in the frame */
+	const struct bpf_prog *prog;
+};
 
 struct bpf_cg_run_ctx {
 	struct bpf_run_ctx run_ctx;
@@ -2801,7 +2810,6 @@ struct bpf_tramp_run_ctx {
 	struct bpf_run_ctx run_ctx;
 	u64 bpf_cookie;
 	int retval;
-	struct bpf_run_ctx *saved_run_ctx;
 };
 
 static inline struct bpf_run_ctx *bpf_set_run_ctx(struct bpf_run_ctx *new_ctx)
@@ -2809,8 +2817,17 @@ static inline struct bpf_run_ctx *bpf_set_run_ctx(struct bpf_run_ctx *new_ctx)
 	struct bpf_run_ctx *old_ctx = NULL;
 
 #ifdef CONFIG_BPF_SYSCALL
-	old_ctx = current->bpf_ctx;
-	current->bpf_ctx = new_ctx;
+	old_ctx = READ_ONCE(current->bpf_ctx);
+	if (new_ctx) {
+		new_ctx->saved_run_ctx = old_ctx;
+		new_ctx->prog = NULL;
+	}
+	/* Initialize the frame before interrupts and NMIs on this CPU see it. */
+	barrier();
+	WRITE_ONCE(current->bpf_ctx, new_ctx);
+#else
+	if (new_ctx)
+		new_ctx->saved_run_ctx = NULL;
 #endif
 	return old_ctx;
 }
@@ -2818,8 +2835,64 @@ static inline struct bpf_run_ctx *bpf_set_run_ctx(struct bpf_run_ctx *new_ctx)
 static inline void bpf_reset_run_ctx(struct bpf_run_ctx *old_ctx)
 {
 #ifdef CONFIG_BPF_SYSCALL
-	current->bpf_ctx = old_ctx;
+	WRITE_ONCE(current->bpf_ctx, old_ctx);
+	/* Unlink the frame before its stack storage can be reused. */
+	barrier();
+#endif
+}
+
+/*
+ * Enter @prog, unless that would be recursion:
+ *
+ * - A program that keeps per-CPU state (prog->recur_per_cpu) takes the per-CPU
+ *   counter. No other run of it starts on this CPU until it exits.
+ * - Any other program recurses only if the current task is already inside it:
+ *   a frame in the task's chain runs it. Interrupts and NMIs run on top of the
+ *   chain of the task they interrupt, so they are covered too.
+ *
+ * Returns false if @prog must not run. Call bpf_prog_exit_run_ctx() either way.
+ *
+ * The chain is walked before the frame is linked, so a run that must not start
+ * links nothing. Always inline: the callers are notrace.
+ */
+static __always_inline bool bpf_prog_enter_run_ctx(struct bpf_prog *prog,
+						   struct bpf_run_ctx *run_ctx)
+{
+	struct bpf_run_ctx *old_ctx = NULL;
+
+#ifdef CONFIG_BPF_SYSCALL
+	old_ctx = READ_ONCE(current->bpf_ctx);
+#endif
+	run_ctx->saved_run_ctx = old_ctx;
+	if (prog->recur_per_cpu) {
+		run_ctx->prog = NULL;
+		if (!bpf_prog_get_recursion_context(prog))
+			return false;
+	} else {
+		for (struct bpf_run_ctx *ctx = old_ctx; ctx; ctx = ctx->saved_run_ctx) {
+			if (READ_ONCE(ctx->prog) == prog)
+				return false;
+		}
+		run_ctx->prog = prog;
+	}
+#ifdef CONFIG_BPF_SYSCALL
+	/* Initialize the frame before interrupts and NMIs on this CPU see it. */
+	barrier();
+	WRITE_ONCE(current->bpf_ctx, run_ctx);
 #endif
+	return true;
+}
+
+/*
+ * Also correct after an enter that returned false: the frame was not linked,
+ * so resetting to its saved_run_ctx changes nothing.
+ */
+static __always_inline void bpf_prog_exit_run_ctx(struct bpf_prog *prog,
+						  struct bpf_run_ctx *run_ctx)
+{
+	bpf_reset_run_ctx(run_ctx->saved_run_ctx);
+	if (prog->recur_per_cpu)
+		bpf_prog_put_recursion_context(prog);
 }
 
 /* BPF program asks to bypass CAP_NET_BIND_SERVICE in bind. */
@@ -3492,7 +3565,6 @@ bpf_prog_run_array_sleepable(const struct bpf_prog_array *array,
 {
 	const struct bpf_prog_array_item *item;
 	struct bpf_prog *prog;
-	struct bpf_run_ctx *old_run_ctx;
 	struct bpf_trace_run_ctx run_ctx;
 	u32 ret = 1;
 
@@ -3503,7 +3575,6 @@ bpf_prog_run_array_sleepable(const struct bpf_prog_array *array,
 
 	run_ctx.is_uprobe = false;
 
-	old_run_ctx = bpf_set_run_ctx(&run_ctx.run_ctx);
 	item = &array->items[0];
 	while ((prog = READ_ONCE(item->prog))) {
 		/* Skip dummy_bpf_prog placeholder (len == 0) */
@@ -3512,15 +3583,14 @@ bpf_prog_run_array_sleepable(const struct bpf_prog_array *array,
 			continue;
 		}
 
-		if (unlikely(!bpf_prog_get_recursion_context(prog))) {
+		run_ctx.bpf_cookie = item->bpf_cookie;
+		if (unlikely(!bpf_prog_enter_run_ctx(prog, &run_ctx.run_ctx))) {
 			bpf_prog_inc_misses_counter(prog);
-			bpf_prog_put_recursion_context(prog);
+			bpf_prog_exit_run_ctx(prog, &run_ctx.run_ctx);
 			item++;
 			continue;
 		}
 
-		run_ctx.bpf_cookie = item->bpf_cookie;
-
 		if (!prog->sleepable) {
 			guard(rcu)();
 			ret &= run_prog(prog, ctx);
@@ -3528,10 +3598,9 @@ bpf_prog_run_array_sleepable(const struct bpf_prog_array *array,
 			ret &= run_prog(prog, ctx);
 		}
 
-		bpf_prog_put_recursion_context(prog);
+		bpf_prog_exit_run_ctx(prog, &run_ctx.run_ctx);
 		item++;
 	}
-	bpf_reset_run_ctx(old_run_ctx);
 	migrate_enable();
 	return ret;
 }
diff --git a/include/linux/bpf_verifier.h b/include/linux/bpf_verifier.h
index f45c18b3cfa2..086d59588d81 100644
--- a/include/linux/bpf_verifier.h
+++ b/include/linux/bpf_verifier.h
@@ -1827,6 +1827,25 @@ static inline bool bpf_prog_check_recur(const struct bpf_prog *prog)
 	}
 }
 
+/* Is the recursion of @prog checked per task, so that two tasks can run it at once on a CPU? */
+static inline bool bpf_prog_recur_per_task(const struct bpf_prog *prog)
+{
+	if (prog->recur_per_cpu)
+		return false;
+
+	switch (resolve_prog_type(prog)) {
+	case BPF_PROG_TYPE_RAW_TRACEPOINT:
+	case BPF_PROG_TYPE_RAW_TRACEPOINT_WRITABLE:
+	/* It may be attached to a syscall tracepoint */
+	case BPF_PROG_TYPE_TRACEPOINT:
+		return true;
+	case BPF_PROG_TYPE_TRACING:
+		return bpf_prog_check_recur(prog);
+	default:
+		return false;
+	}
+}
+
 #define BPF_REG_TRUSTED_MODIFIERS (MEM_ALLOC | PTR_TRUSTED | NON_OWN_REF)
 
 static inline bool bpf_type_has_unsafe_modifiers(u32 type)
diff --git a/kernel/bpf/syscall.c b/kernel/bpf/syscall.c
index ec8e78792911..a05eda7c1eeb 100644
--- a/kernel/bpf/syscall.c
+++ b/kernel/bpf/syscall.c
@@ -3849,6 +3849,16 @@ static int bpf_tracing_prog_attach(struct bpf_prog *prog,
 		err = -EINVAL;
 		goto out_unlock;
 	}
+	/*
+	 * An extension runs under the recursion check of its target. One that
+	 * keeps per-CPU state relies on its runs not overlapping on a CPU, which
+	 * a target whose recursion is checked per task doesn't provide.
+	 */
+	if (prog->type == BPF_PROG_TYPE_EXT && prog->recur_per_cpu &&
+	    bpf_prog_recur_per_task(tgt_prog)) {
+		err = -EINVAL;
+		goto out_unlock;
+	}
 	/*
 	 * The size of these contexts depends on what the program is attached
 	 * to, or run with. That is compared with max_ctx_offset of the program,
diff --git a/kernel/bpf/trampoline.c b/kernel/bpf/trampoline.c
index 21d460866dfe..195379cd81ab 100644
--- a/kernel/bpf/trampoline.c
+++ b/kernel/bpf/trampoline.c
@@ -1342,9 +1342,7 @@ static u64 notrace __bpf_prog_enter_recur(struct bpf_prog *prog, struct bpf_tram
 {
 	rcu_read_lock_dont_migrate();
 
-	run_ctx->saved_run_ctx = bpf_set_run_ctx(&run_ctx->run_ctx);
-
-	if (unlikely(!bpf_prog_get_recursion_context(prog))) {
+	if (unlikely(!bpf_prog_enter_run_ctx(prog, &run_ctx->run_ctx))) {
 		bpf_prog_inc_misses_counter(prog);
 		if (prog->aux->recursion_detected)
 			prog->aux->recursion_detected(prog);
@@ -1385,10 +1383,9 @@ static void notrace __bpf_prog_exit_recur(struct bpf_prog *prog, u64 start,
 					  struct bpf_tramp_run_ctx *run_ctx)
 	__releases(RCU)
 {
-	bpf_reset_run_ctx(run_ctx->saved_run_ctx);
+	bpf_prog_exit_run_ctx(prog, &run_ctx->run_ctx);
 
 	update_prog_stats(prog, start);
-	bpf_prog_put_recursion_context(prog);
 	rcu_read_unlock_migrate();
 }
 
@@ -1401,7 +1398,7 @@ static u64 notrace __bpf_prog_enter_lsm_cgroup(struct bpf_prog *prog,
 	 */
 	rcu_read_lock_dont_migrate();
 
-	run_ctx->saved_run_ctx = bpf_set_run_ctx(&run_ctx->run_ctx);
+	bpf_set_run_ctx(&run_ctx->run_ctx);
 
 	return NO_START_TIME;
 }
@@ -1410,7 +1407,7 @@ static void notrace __bpf_prog_exit_lsm_cgroup(struct bpf_prog *prog, u64 start,
 					       struct bpf_tramp_run_ctx *run_ctx)
 	__releases(RCU)
 {
-	bpf_reset_run_ctx(run_ctx->saved_run_ctx);
+	bpf_reset_run_ctx(run_ctx->run_ctx.saved_run_ctx);
 
 	rcu_read_unlock_migrate();
 }
@@ -1422,9 +1419,7 @@ u64 notrace __bpf_prog_enter_sleepable_recur(struct bpf_prog *prog,
 	migrate_disable();
 	might_fault();
 
-	run_ctx->saved_run_ctx = bpf_set_run_ctx(&run_ctx->run_ctx);
-
-	if (unlikely(!bpf_prog_get_recursion_context(prog))) {
+	if (unlikely(!bpf_prog_enter_run_ctx(prog, &run_ctx->run_ctx))) {
 		bpf_prog_inc_misses_counter(prog);
 		if (prog->aux->recursion_detected)
 			prog->aux->recursion_detected(prog);
@@ -1436,10 +1431,9 @@ u64 notrace __bpf_prog_enter_sleepable_recur(struct bpf_prog *prog,
 void notrace __bpf_prog_exit_sleepable_recur(struct bpf_prog *prog, u64 start,
 					     struct bpf_tramp_run_ctx *run_ctx)
 {
-	bpf_reset_run_ctx(run_ctx->saved_run_ctx);
+	bpf_prog_exit_run_ctx(prog, &run_ctx->run_ctx);
 
 	update_prog_stats(prog, start);
-	bpf_prog_put_recursion_context(prog);
 	migrate_enable();
 	rcu_read_unlock_trace();
 }
@@ -1451,7 +1445,7 @@ static u64 notrace __bpf_prog_enter_sleepable(struct bpf_prog *prog,
 	migrate_disable();
 	might_fault();
 
-	run_ctx->saved_run_ctx = bpf_set_run_ctx(&run_ctx->run_ctx);
+	bpf_set_run_ctx(&run_ctx->run_ctx);
 
 	return bpf_prog_start_time();
 }
@@ -1459,7 +1453,7 @@ static u64 notrace __bpf_prog_enter_sleepable(struct bpf_prog *prog,
 static void notrace __bpf_prog_exit_sleepable(struct bpf_prog *prog, u64 start,
 					      struct bpf_tramp_run_ctx *run_ctx)
 {
-	bpf_reset_run_ctx(run_ctx->saved_run_ctx);
+	bpf_reset_run_ctx(run_ctx->run_ctx.saved_run_ctx);
 
 	update_prog_stats(prog, start);
 	migrate_enable();
@@ -1472,7 +1466,7 @@ static u64 notrace __bpf_prog_enter(struct bpf_prog *prog,
 {
 	rcu_read_lock_dont_migrate();
 
-	run_ctx->saved_run_ctx = bpf_set_run_ctx(&run_ctx->run_ctx);
+	bpf_set_run_ctx(&run_ctx->run_ctx);
 
 	return bpf_prog_start_time();
 }
@@ -1481,7 +1475,7 @@ static void notrace __bpf_prog_exit(struct bpf_prog *prog, u64 start,
 				    struct bpf_tramp_run_ctx *run_ctx)
 	__releases(RCU)
 {
-	bpf_reset_run_ctx(run_ctx->saved_run_ctx);
+	bpf_reset_run_ctx(run_ctx->run_ctx.saved_run_ctx);
 
 	update_prog_stats(prog, start);
 	rcu_read_unlock_migrate();
diff --git a/kernel/trace/bpf_trace.c b/kernel/trace/bpf_trace.c
index b4ff9d4e86b3..4cb8a51ba999 100644
--- a/kernel/trace/bpf_trace.c
+++ b/kernel/trace/bpf_trace.c
@@ -2167,7 +2167,6 @@ void __bpf_trace_run(struct bpf_raw_tp_link *link, u64 *args)
 	struct srcu_ctr __percpu *scp = NULL;
 	struct bpf_prog *prog = link->link.prog;
 	bool sleepable = prog->sleepable;
-	struct bpf_run_ctx *old_run_ctx;
 	struct bpf_trace_run_ctx run_ctx;
 
 	if (sleepable) {
@@ -2177,19 +2176,15 @@ void __bpf_trace_run(struct bpf_raw_tp_link *link, u64 *args)
 		rcu_read_lock_dont_migrate();
 	}
 
-	if (unlikely(!bpf_prog_get_recursion_context(prog))) {
+	run_ctx.bpf_cookie = link->cookie;
+	if (unlikely(!bpf_prog_enter_run_ctx(prog, &run_ctx.run_ctx))) {
 		bpf_prog_inc_misses_counter(prog);
 		goto out;
 	}
 
-	run_ctx.bpf_cookie = link->cookie;
-	old_run_ctx = bpf_set_run_ctx(&run_ctx.run_ctx);
-
 	(void)bpf_prog_run(prog, args);
-
-	bpf_reset_run_ctx(old_run_ctx);
 out:
-	bpf_prog_put_recursion_context(prog);
+	bpf_prog_exit_run_ctx(prog, &run_ctx.run_ctx);
 
 	if (sleepable) {
 		migrate_enable();
diff --git a/net/bpf/test_run.c b/net/bpf/test_run.c
index cc3236e3c0c4..8b8c4e9ded9d 100644
--- a/net/bpf/test_run.c
+++ b/net/bpf/test_run.c
@@ -748,9 +748,6 @@ __bpf_prog_test_run_raw_tp(void *data)
 	struct bpf_raw_tp_test_run_info *info = data;
 	struct srcu_ctr __percpu *scp = NULL;
 	struct bpf_trace_run_ctx run_ctx = {};
-	struct bpf_run_ctx *old_run_ctx;
-
-	old_run_ctx = bpf_set_run_ctx(&run_ctx.run_ctx);
 
 	if (info->prog->sleepable) {
 		scp = rcu_read_lock_tasks_trace();
@@ -759,7 +756,7 @@ __bpf_prog_test_run_raw_tp(void *data)
 		rcu_read_lock();
 	}
 
-	if (unlikely(!bpf_prog_get_recursion_context(info->prog))) {
+	if (unlikely(!bpf_prog_enter_run_ctx(info->prog, &run_ctx.run_ctx))) {
 		bpf_prog_inc_misses_counter(info->prog);
 		goto out;
 	}
@@ -767,7 +764,7 @@ __bpf_prog_test_run_raw_tp(void *data)
 	info->retval = bpf_prog_run(info->prog, info->ctx);
 
 out:
-	bpf_prog_put_recursion_context(info->prog);
+	bpf_prog_exit_run_ctx(info->prog, &run_ctx.run_ctx);
 
 	if (info->prog->sleepable) {
 		migrate_enable();
@@ -775,8 +772,6 @@ __bpf_prog_test_run_raw_tp(void *data)
 	} else {
 		rcu_read_unlock();
 	}
-
-	bpf_reset_run_ctx(old_run_ctx);
 }
 
 int bpf_prog_test_run_raw_tp(struct bpf_prog *prog,
diff --git a/net/ipv4/bpf_tcp_ops.c b/net/ipv4/bpf_tcp_ops.c
index 2ba73dd6c52c..e1ca34e63de0 100644
--- a/net/ipv4/bpf_tcp_ops.c
+++ b/net/ipv4/bpf_tcp_ops.c
@@ -207,11 +207,11 @@ BPF_CALL_0(bpf_tcp_ops_get_retval)
 	 * return value chained across the bpf_tcp_ops attached to the cgroup
 	 * and is this program's saved_run_ctx.
 	 */
-	if (WARN_ON_ONCE(!ctx->saved_run_ctx))
+	if (WARN_ON_ONCE(!ctx->run_ctx.saved_run_ctx))
 		return 0;
 
-	return container_of(ctx->saved_run_ctx, struct bpf_tramp_run_ctx,
-			    run_ctx)->retval;
+	return container_of(ctx->run_ctx.saved_run_ctx,
+			    struct bpf_tramp_run_ctx, run_ctx)->retval;
 }
 
 const struct bpf_func_proto bpf_tcp_ops_get_retval_proto = {

-- 
2.43.0

