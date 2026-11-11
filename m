From: Mike Bazov <mikeba@sentinelone.com>
Date: Wed, 11 Nov 2026 21:39:48 +0200
Subject: [PATCH bpf-next v2 2/5] bpf: Check program recursion per task via
 bpf_ctx
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261111-bpf-preempt-v2-r2-v2-2-9d8f6b952ad2@sentinelone.com>
References: <20261111-bpf-preempt-v2-r2-v2-0-9d8f6b952ad2@sentinelone.com>
In-Reply-To: <20261111-bpf-preempt-v2-r2-v2-0-9d8f6b952ad2@sentinelone.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794425986; l=11813;
 i=mikeba@sentinelone.com; s=20261022; h=from:subject:message-id;
 bh=Fk8rqqs0y7uTUP/pR+dO3Qn8hZPBQ2naNG3kArVqijw=;
 b=ej6mtqR43DfToEjMNuSU3ySt81M0GkU9XqrrcOXTLI1149nR9m6XdbSdfQ6M2Kx/EsTedAyMA
 ymvVcSkm929DUKyhW2HiTw2AM/Icwa4k/+H1Y6JB0FJsNdASNjGLdW/
X-Developer-Key: i=mikeba@sentinelone.com; a=ed25519;
 pk=DBXcQ0qoCkgacRsRwT1JU7oOWpWSYuTyLiXMfNLcP+A=
X-Endpoint-Received: by B4 Relay for mikeba@sentinelone.com/20261022 with auth_id=1284
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Trampoline programs (fentry, fexit, fsession, fmod_ret and their
sleepable variants) and raw tracepoint programs (raw_tp, raw_tp.s,
tp_btf) run preemptibly: their runners only disable migration, and with
PREEMPT_RCU the RCU read section doesn't disable preemption either.
Raw tracepoint programs do so since tracepoints switched to SRCU-fast in
commit a46023d5616e ("tracing: Guard __DECLARE_TRACE() use of
__DO_TRACE_CALL() with SRCU-fast").
Their recursion check is a per-CPU, per-program counter. When a task is
preempted inside a program on CPU N, the counter stays raised, and every
other task that enters the same program on CPU N is dropped and counted
as a recursion miss, although nothing recursed.

Check recursion per task instead. Each of these runners already links a
stack-allocated bpf_run_ctx into current->bpf_ctx. Move saved_run_ctx
into struct bpf_run_ctx, so every frame links to the outer one, and
record in each frame the program it runs. A program is recursing if a
frame in the current task's chain already runs it. Interrupts and NMIs
run on top of the interrupted task's chain, so recursion through them is
still caught; only other tasks are no longer blocked.

bpf_set_run_ctx() initializes the frame before publishing it, and
bpf_reset_run_ctx() unlinks it before its stack storage can be reused.
bpf_set_run_ctx() also accepts a NULL ctx, which io_uring passes to hide
the BPF context while submitting user requests.

Programs that use a per-CPU private stack keep the per-CPU check, since
two tasks must never use that stack on one CPU. After the previous
patch, these are only struct_ops programs that request one.

As a result, the same program can now run in two tasks at once on one
CPU. Programs that use a per-CPU map as scratch space across helper
calls may see another run's data, where the run was dropped before.
And as commit ec274bb4665c ("bpf: One may_goto time slice per prog
invocation") notes, a second invocation of a program on the same CPU
gives its may_goto loops more time; that invocation can now come from
another task, while the first one is preempted.

Link: https://lore.kernel.org/bpf/20261025-b4-bpf-trampoline-preempt-v1-0-198dcdc0c6ac@sentinelone.com/
Fixes: ca06f55b9002 ("bpf: Add per-program recursion prevention mechanism")
Fixes: a46023d5616e ("tracing: Guard __DECLARE_TRACE() use of __DO_TRACE_CALL() with SRCU-fast")
Fixes: 439ebd5b5708 ("bpf: Add sleepable support for raw tracepoint programs")
Signed-off-by: Mike Bazov <mikeba@sentinelone.com>
---
 include/linux/bpf.h      | 48 +++++++++++++++++++++++++++++++++++++++++++-----
 kernel/bpf/trampoline.c  | 28 ++++++++++++++--------------
 kernel/trace/bpf_trace.c | 12 +++++-------
 net/bpf/test_run.c       |  4 ++--
 net/ipv4/bpf_tcp_ops.c   |  6 +++---
 5 files changed, 67 insertions(+), 31 deletions(-)

diff --git a/include/linux/bpf.h b/include/linux/bpf.h
index 520fd72e21fd..52e29b374b4a 100644
--- a/include/linux/bpf.h
+++ b/include/linux/bpf.h
@@ -2785,7 +2785,10 @@ int bpf_prog_array_copy(struct bpf_prog_array *old_array,
 			struct bpf_prog_array **new_array);
 struct bpf_prog *bpf_prog_dummy(void);
 
-struct bpf_run_ctx {};
+struct bpf_run_ctx {
+	struct bpf_run_ctx *saved_run_ctx;
+	const struct bpf_prog *prog;
+};
 
 struct bpf_cg_run_ctx {
 	struct bpf_run_ctx run_ctx;
@@ -2803,7 +2806,6 @@ struct bpf_tramp_run_ctx {
 	struct bpf_run_ctx run_ctx;
 	u64 bpf_cookie;
 	int retval;
-	struct bpf_run_ctx *saved_run_ctx;
 };
 
 static inline struct bpf_run_ctx *bpf_set_run_ctx(struct bpf_run_ctx *new_ctx)
@@ -2811,8 +2813,17 @@ static inline struct bpf_run_ctx *bpf_set_run_ctx(struct bpf_run_ctx *new_ctx)
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
@@ -2820,10 +2831,37 @@ static inline struct bpf_run_ctx *bpf_set_run_ctx(struct bpf_run_ctx *new_ctx)
 static inline void bpf_reset_run_ctx(struct bpf_run_ctx *old_ctx)
 {
 #ifdef CONFIG_BPF_SYSCALL
-	current->bpf_ctx = old_ctx;
+	WRITE_ONCE(current->bpf_ctx, old_ctx);
+	/* Unlink the frame before its stack storage can be reused. */
+	barrier();
 #endif
 }
 
+static __always_inline bool
+bpf_prog_enter_recur_ctx(struct bpf_prog *prog, struct bpf_run_ctx *run_ctx)
+{
+	if (unlikely(prog->aux->jits_use_priv_stack))
+		return bpf_prog_get_recursion_context(prog);
+#ifdef CONFIG_BPF_SYSCALL
+	for (struct bpf_run_ctx *ctx = run_ctx->saved_run_ctx;
+	     ctx; ctx = ctx->saved_run_ctx) {
+		if (READ_ONCE(ctx->prog) == prog)
+			return false;
+	}
+	WRITE_ONCE(run_ctx->prog, prog);
+#endif
+	return true;
+}
+
+static __always_inline void
+bpf_prog_exit_recur_ctx(struct bpf_prog *prog, struct bpf_run_ctx *run_ctx)
+{
+	if (unlikely(prog->aux->jits_use_priv_stack))
+		bpf_prog_put_recursion_context(prog);
+	else
+		WRITE_ONCE(run_ctx->prog, NULL);
+}
+
 /* BPF program asks to bypass CAP_NET_BIND_SERVICE in bind. */
 #define BPF_RET_BIND_NO_CAP_NET_BIND_SERVICE			(1 << 0)
 /* BPF program asks to set CN on the packet. */
diff --git a/kernel/bpf/trampoline.c b/kernel/bpf/trampoline.c
index 21d460866dfe..d66aa688688f 100644
--- a/kernel/bpf/trampoline.c
+++ b/kernel/bpf/trampoline.c
@@ -1342,9 +1342,9 @@ static u64 notrace __bpf_prog_enter_recur(struct bpf_prog *prog, struct bpf_tram
 {
 	rcu_read_lock_dont_migrate();
 
-	run_ctx->saved_run_ctx = bpf_set_run_ctx(&run_ctx->run_ctx);
+	bpf_set_run_ctx(&run_ctx->run_ctx);
 
-	if (unlikely(!bpf_prog_get_recursion_context(prog))) {
+	if (unlikely(!bpf_prog_enter_recur_ctx(prog, &run_ctx->run_ctx))) {
 		bpf_prog_inc_misses_counter(prog);
 		if (prog->aux->recursion_detected)
 			prog->aux->recursion_detected(prog);
@@ -1385,10 +1385,10 @@ static void notrace __bpf_prog_exit_recur(struct bpf_prog *prog, u64 start,
 					  struct bpf_tramp_run_ctx *run_ctx)
 	__releases(RCU)
 {
-	bpf_reset_run_ctx(run_ctx->saved_run_ctx);
+	bpf_reset_run_ctx(run_ctx->run_ctx.saved_run_ctx);
 
 	update_prog_stats(prog, start);
-	bpf_prog_put_recursion_context(prog);
+	bpf_prog_exit_recur_ctx(prog, &run_ctx->run_ctx);
 	rcu_read_unlock_migrate();
 }
 
@@ -1401,7 +1401,7 @@ static u64 notrace __bpf_prog_enter_lsm_cgroup(struct bpf_prog *prog,
 	 */
 	rcu_read_lock_dont_migrate();
 
-	run_ctx->saved_run_ctx = bpf_set_run_ctx(&run_ctx->run_ctx);
+	bpf_set_run_ctx(&run_ctx->run_ctx);
 
 	return NO_START_TIME;
 }
@@ -1410,7 +1410,7 @@ static void notrace __bpf_prog_exit_lsm_cgroup(struct bpf_prog *prog, u64 start,
 					       struct bpf_tramp_run_ctx *run_ctx)
 	__releases(RCU)
 {
-	bpf_reset_run_ctx(run_ctx->saved_run_ctx);
+	bpf_reset_run_ctx(run_ctx->run_ctx.saved_run_ctx);
 
 	rcu_read_unlock_migrate();
 }
@@ -1422,9 +1422,9 @@ u64 notrace __bpf_prog_enter_sleepable_recur(struct bpf_prog *prog,
 	migrate_disable();
 	might_fault();
 
-	run_ctx->saved_run_ctx = bpf_set_run_ctx(&run_ctx->run_ctx);
+	bpf_set_run_ctx(&run_ctx->run_ctx);
 
-	if (unlikely(!bpf_prog_get_recursion_context(prog))) {
+	if (unlikely(!bpf_prog_enter_recur_ctx(prog, &run_ctx->run_ctx))) {
 		bpf_prog_inc_misses_counter(prog);
 		if (prog->aux->recursion_detected)
 			prog->aux->recursion_detected(prog);
@@ -1436,10 +1436,10 @@ u64 notrace __bpf_prog_enter_sleepable_recur(struct bpf_prog *prog,
 void notrace __bpf_prog_exit_sleepable_recur(struct bpf_prog *prog, u64 start,
 					     struct bpf_tramp_run_ctx *run_ctx)
 {
-	bpf_reset_run_ctx(run_ctx->saved_run_ctx);
+	bpf_reset_run_ctx(run_ctx->run_ctx.saved_run_ctx);
 
 	update_prog_stats(prog, start);
-	bpf_prog_put_recursion_context(prog);
+	bpf_prog_exit_recur_ctx(prog, &run_ctx->run_ctx);
 	migrate_enable();
 	rcu_read_unlock_trace();
 }
@@ -1451,7 +1451,7 @@ static u64 notrace __bpf_prog_enter_sleepable(struct bpf_prog *prog,
 	migrate_disable();
 	might_fault();
 
-	run_ctx->saved_run_ctx = bpf_set_run_ctx(&run_ctx->run_ctx);
+	bpf_set_run_ctx(&run_ctx->run_ctx);
 
 	return bpf_prog_start_time();
 }
@@ -1459,7 +1459,7 @@ static u64 notrace __bpf_prog_enter_sleepable(struct bpf_prog *prog,
 static void notrace __bpf_prog_exit_sleepable(struct bpf_prog *prog, u64 start,
 					      struct bpf_tramp_run_ctx *run_ctx)
 {
-	bpf_reset_run_ctx(run_ctx->saved_run_ctx);
+	bpf_reset_run_ctx(run_ctx->run_ctx.saved_run_ctx);
 
 	update_prog_stats(prog, start);
 	migrate_enable();
@@ -1472,7 +1472,7 @@ static u64 notrace __bpf_prog_enter(struct bpf_prog *prog,
 {
 	rcu_read_lock_dont_migrate();
 
-	run_ctx->saved_run_ctx = bpf_set_run_ctx(&run_ctx->run_ctx);
+	bpf_set_run_ctx(&run_ctx->run_ctx);
 
 	return bpf_prog_start_time();
 }
@@ -1481,7 +1481,7 @@ static void notrace __bpf_prog_exit(struct bpf_prog *prog, u64 start,
 				    struct bpf_tramp_run_ctx *run_ctx)
 	__releases(RCU)
 {
-	bpf_reset_run_ctx(run_ctx->saved_run_ctx);
+	bpf_reset_run_ctx(run_ctx->run_ctx.saved_run_ctx);
 
 	update_prog_stats(prog, start);
 	rcu_read_unlock_migrate();
diff --git a/kernel/trace/bpf_trace.c b/kernel/trace/bpf_trace.c
index 2aec56d7f3d3..d596c333b7eb 100644
--- a/kernel/trace/bpf_trace.c
+++ b/kernel/trace/bpf_trace.c
@@ -2127,19 +2127,17 @@ void __bpf_trace_run(struct bpf_raw_tp_link *link, u64 *args)
 		rcu_read_lock_dont_migrate();
 	}
 
-	if (unlikely(!bpf_prog_get_recursion_context(prog))) {
+	run_ctx.bpf_cookie = link->cookie;
+	old_run_ctx = bpf_set_run_ctx(&run_ctx.run_ctx);
+	if (unlikely(!bpf_prog_enter_recur_ctx(prog, &run_ctx.run_ctx))) {
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
+	bpf_reset_run_ctx(old_run_ctx);
+	bpf_prog_exit_recur_ctx(prog, &run_ctx.run_ctx);
 
 	if (sleepable) {
 		migrate_enable();
diff --git a/net/bpf/test_run.c b/net/bpf/test_run.c
index d6c9dc62182e..362d9ec0d8f8 100644
--- a/net/bpf/test_run.c
+++ b/net/bpf/test_run.c
@@ -759,7 +759,7 @@ __bpf_prog_test_run_raw_tp(void *data)
 		rcu_read_lock();
 	}
 
-	if (unlikely(!bpf_prog_get_recursion_context(info->prog))) {
+	if (unlikely(!bpf_prog_enter_recur_ctx(info->prog, &run_ctx.run_ctx))) {
 		bpf_prog_inc_misses_counter(info->prog);
 		goto out;
 	}
@@ -767,7 +767,7 @@ __bpf_prog_test_run_raw_tp(void *data)
 	info->retval = bpf_prog_run(info->prog, info->ctx);
 
 out:
-	bpf_prog_put_recursion_context(info->prog);
+	bpf_prog_exit_recur_ctx(info->prog, &run_ctx.run_ctx);
 
 	if (info->prog->sleepable) {
 		migrate_enable();
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

