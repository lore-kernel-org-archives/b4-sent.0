From: Mike Bazov <mikeba@sentinelone.com>
Date: Wed, 11 Nov 2026 21:39:47 +0200
Subject: [PATCH bpf-next v2 1/5] bpf: Avoid per-CPU private stack in
 preemptible tracing progs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261111-bpf-preempt-v2-r2-v2-1-9d8f6b952ad2@sentinelone.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794425986; l=17240;
 i=mikeba@sentinelone.com; s=20261022; h=from:subject:message-id;
 bh=PekFndKt98NGFT88PptYcKIC4n99ma6nIpyu/eKEku0=;
 b=+ta0i54LN8eZYWnATg+h0HYk8uAfneTy0O1W7nn/WuHfF+cJ1tragrFEgLdIyFr07mjutNBdP
 hnfZN0IXqWwCP8ggMjuCxSQRQOcwu/jvC4ocifJwxCshVHN3S//6+un
X-Developer-Key: i=mikeba@sentinelone.com; a=ed25519;
 pk=DBXcQ0qoCkgacRsRwT1JU7oOWpWSYuTyLiXMfNLcP+A=
X-Endpoint-Received: by B4 Relay for mikeba@sentinelone.com/20261022 with auth_id=1284
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A per-CPU private stack is only safe if a program never runs in two
tasks at once on one CPU. Tracing, raw_tp and tracepoint programs run
preemptibly, and that already happens today:

- Two raw_tp dispatchers that tail-call the same handler each pass their
  own per-CPU recursion check, so two tasks can run the handler at once
  on one CPU and share its private stack.

  event 1 -> dispatcher A --+
                            +--> jump_table[0] --> handler H
  event 2 -> dispatcher B --+

- A tracepoint program attached to a syscall tracepoint, which runs
  preemptibly since commit 57918341dd19 ("bpf: Add sleepable support for
  classic tracepoint programs"), and to a regular tracepoint can be
  entered by a second task through the regular tracepoint, which only
  checks bpf_prog_active.

In both cases the second task overwrites the preempted task's stack.
Never give these program types a private stack. Checking their recursion
per task, as the next patches do, makes such overlap the normal case.

check_recursion() told tracing programs apart by whether they can get
a private stack, so it would start accepting recursive subprograms in
these program types. Make it check the program type instead, and test
it for raw_tp.

On the kernel stack, the frames of a call chain share one stack budget,
while a private stack checks each frame on its own. A program whose
main function and callee each use close to the per-frame limit no
longer loads: two 2000-byte frames are rejected with "combined stack
size of 2 calls is 4000. Too large".

Update the selftests that relied on these program types having a
private stack to use kprobe.multi and perf_event programs. Raw
tracepoint programs were the only ones with a private stack that
BPF_PROG_TEST_RUN actually runs, so unwinding on a private stack is now
checked in the generated code only, not at run time.

Fixes: a76ab5731e32 ("bpf: Find eligible subprogs for private stack support")
Fixes: 57918341dd19 ("bpf: Add sleepable support for classic tracepoint programs")
Signed-off-by: Mike Bazov <mikeba@sentinelone.com>
---
 kernel/bpf/verifier.c                              | 43 +++++++++-----
 .../selftests/bpf/prog_tests/may_goto_priv_stack.c |  6 +-
 .../selftests/bpf/prog_tests/timed_may_goto.c      |  6 +-
 .../selftests/bpf/progs/may_goto_priv_stack.c      | 14 ++++-
 .../selftests/bpf/progs/test_global_func3.c        |  9 +++
 .../selftests/bpf/progs/timed_may_goto_user.c      | 16 +++++-
 .../selftests/bpf/progs/verifier_private_stack.c   | 65 ++++++++++++----------
 .../testing/selftests/bpf/progs/verifier_unwind.c  | 33 +++++++++--
 8 files changed, 139 insertions(+), 53 deletions(-)

diff --git a/kernel/bpf/verifier.c b/kernel/bpf/verifier.c
index 20b1b9ff574c..fe59a0e27380 100644
--- a/kernel/bpf/verifier.c
+++ b/kernel/bpf/verifier.c
@@ -5470,9 +5470,16 @@ static enum priv_stack_mode bpf_enable_priv_stack(struct bpf_prog *prog)
 	if (!bpf_jit_supports_private_stack())
 		return NO_PRIV_STACK;
 
-	/* bpf_prog_check_recur() checks all prog types that use bpf trampoline
-	 * while kprobe/tp/perf_event/raw_tp don't use trampoline hence checked
-	 * explicitly.
+	/*
+	 * A private stack is per CPU, so a program using it must never run in two
+	 * tasks at once on one CPU. Tracing, raw_tp and tracepoint programs run
+	 * preemptibly, and the same program can be entered by another task on the
+	 * same CPU, e.g. through a second tail-call dispatcher, or as a tracepoint
+	 * program attached to both a syscall and a regular tracepoint. They always
+	 * use the task's kernel stack. Kprobe multi and session programs are
+	 * serialized per CPU by bpf_prog_active, perf_event programs run in
+	 * interrupt context, and struct_ops programs that request a private stack
+	 * keep per-CPU recursion protection.
 	 */
 	switch (prog->type) {
 	case BPF_PROG_TYPE_KPROBE:
@@ -5485,14 +5492,10 @@ static enum priv_stack_mode bpf_enable_priv_stack(struct bpf_prog *prog)
 		    prog->expected_attach_type != BPF_TRACE_KPROBE_SESSION)
 			return NO_PRIV_STACK;
 		fallthrough;
-	case BPF_PROG_TYPE_TRACEPOINT:
 	case BPF_PROG_TYPE_PERF_EVENT:
-	case BPF_PROG_TYPE_RAW_TRACEPOINT:
 		return PRIV_STACK_ADAPTIVE;
-	case BPF_PROG_TYPE_TRACING:
-	case BPF_PROG_TYPE_LSM:
 	case BPF_PROG_TYPE_STRUCT_OPS:
-		if (prog->aux->priv_stack_requested || bpf_prog_check_recur(prog))
+		if (prog->aux->priv_stack_requested)
 			return PRIV_STACK_ADAPTIVE;
 		fallthrough;
 	default:
@@ -5502,6 +5505,22 @@ static enum priv_stack_mode bpf_enable_priv_stack(struct bpf_prog *prog)
 	return NO_PRIV_STACK;
 }
 
+/* Progs that run on top of other progs, whose frames are still on the stack */
+static bool bpf_prog_runs_nested(struct bpf_prog *prog)
+{
+	switch (prog->type) {
+	case BPF_PROG_TYPE_KPROBE:
+	case BPF_PROG_TYPE_PERF_EVENT:
+	case BPF_PROG_TYPE_TRACEPOINT:
+	case BPF_PROG_TYPE_RAW_TRACEPOINT:
+		return true;
+	case BPF_PROG_TYPE_TRACING:
+		return bpf_prog_check_recur(prog);
+	default:
+		return false;
+	}
+}
+
 static int round_up_stack_depth(struct bpf_verifier_env *env, int stack_depth)
 {
 	if (env->prog->jit_requested)
@@ -5684,12 +5703,10 @@ static int check_recursion(struct bpf_verifier_env *env, struct bpf_call_graph *
 		}
 		if (env->subprog_info[s].recursive) {
 			/*
-			 * These progs run on top of other progs. Their frames belong in the
-			 * private stack, which has room for one frame of a subprog. A kprobe prog
-			 * that can be attached to a uprobe has no private stack, and is no better.
+			 * These progs run on top of other progs. A private stack has room for one
+			 * frame of a subprog, and the kernel stack under them is already in use.
 			 */
-			if ((bpf_enable_priv_stack(env->prog) != NO_PRIV_STACK ||
-			     env->prog->type == BPF_PROG_TYPE_KPROBE) &&
+			if (bpf_prog_runs_nested(env->prog) &&
 			    !env->prog->aux->priv_stack_requested) {
 				verbose(env, "recursive %s() in a tracing program\n",
 					bpf_subprog_name(env, s));
diff --git a/tools/testing/selftests/bpf/prog_tests/may_goto_priv_stack.c b/tools/testing/selftests/bpf/prog_tests/may_goto_priv_stack.c
index 4f8476d36250..b4aab50b8a77 100644
--- a/tools/testing/selftests/bpf/prog_tests/may_goto_priv_stack.c
+++ b/tools/testing/selftests/bpf/prog_tests/may_goto_priv_stack.c
@@ -24,13 +24,17 @@ void test_may_goto_priv_stack(void)
 		return;
 
 	err = may_goto_priv_stack__attach(skel);
+	if (err == -EOPNOTSUPP) {
+		test__skip();
+		goto out;
+	}
 	if (!ASSERT_OK(err, "attach"))
 		goto out;
 
 	memset(skel->bss->regs_64, 0xff, sizeof(skel->bss->regs_64));
 	memset(skel->bss->regs_128, 0xff, sizeof(skel->bss->regs_128));
 
-	err = bpf_prog_test_run_opts(bpf_program__fd(skel->progs.priv_stack_64), &topts);
+	err = bpf_prog_test_run_opts(bpf_program__fd(skel->progs.trigger), &topts);
 	if (!ASSERT_OK(err, "test_run"))
 		goto out;
 
diff --git a/tools/testing/selftests/bpf/prog_tests/timed_may_goto.c b/tools/testing/selftests/bpf/prog_tests/timed_may_goto.c
index 3da3f33a2898..ee7b79ef77e0 100644
--- a/tools/testing/selftests/bpf/prog_tests/timed_may_goto.c
+++ b/tools/testing/selftests/bpf/prog_tests/timed_may_goto.c
@@ -131,10 +131,14 @@ static void test_user_ringbuf(struct timed_may_goto_user *skel)
 static void test_priv_stack(struct timed_may_goto_user *skel)
 {
 	LIBBPF_OPTS(bpf_test_run_opts, opts);
-	int fd = bpf_program__fd(skel->progs.priv_stack);
+	int fd = bpf_program__fd(skel->progs.trigger);
 	struct bpf_link *link;
 
 	link = bpf_program__attach(skel->progs.priv_stack);
+	if (!link && errno == EOPNOTSUPP) {
+		test__skip();
+		return;
+	}
 	if (!ASSERT_OK_PTR(link, "attach"))
 		return;
 	ASSERT_OK(bpf_prog_test_run_opts(fd, &opts), "test_run");
diff --git a/tools/testing/selftests/bpf/progs/may_goto_priv_stack.c b/tools/testing/selftests/bpf/progs/may_goto_priv_stack.c
index 5c2aa0aa5055..e11a7f7493a6 100644
--- a/tools/testing/selftests/bpf/progs/may_goto_priv_stack.c
+++ b/tools/testing/selftests/bpf/progs/may_goto_priv_stack.c
@@ -10,11 +10,11 @@ __u64 regs_64[7];
 __u64 regs_128[7];
 
 /*
- * fentry prog with 64 or more bytes of stack uses private stack.
+ * kprobe.multi prog with 64 or more bytes of stack uses private stack.
  * Loop until may_goto expires. r0-r5 should stay zero.
  */
 #define TIMED_MAY_GOTO_PRIV_STACK(size, func)				\
-SEC("fentry/" #func)							\
+SEC("kprobe.multi/" #func)						\
 __naked void priv_stack_##size(void)					\
 {									\
 	asm volatile (							\
@@ -49,4 +49,14 @@ __naked void priv_stack_##size(void)					\
 TIMED_MAY_GOTO_PRIV_STACK(64, bpf_fentry_test1)
 TIMED_MAY_GOTO_PRIV_STACK(128, bpf_fentry_test2)
 
+/*
+ * No tests in here, just to trigger 'bpf_fentry_test*'
+ * through tracing test_run
+ */
+SEC("fentry/bpf_modify_return_test")
+int trigger(void *ctx)
+{
+	return 0;
+}
+
 char _license[] SEC("license") = "GPL";
diff --git a/tools/testing/selftests/bpf/progs/test_global_func3.c b/tools/testing/selftests/bpf/progs/test_global_func3.c
index b916355c5e59..a473bed346d2 100644
--- a/tools/testing/selftests/bpf/progs/test_global_func3.c
+++ b/tools/testing/selftests/bpf/progs/test_global_func3.c
@@ -267,6 +267,15 @@ int global_func3_recursion_in_tracing_prog(void *ctx)
 	return depth(again + 7);
 }
 
+SEC("raw_tp")
+__arch_x86_64
+__arch_arm64
+__failure __msg("recursive depth() in a tracing program")
+int global_func3_recursion_in_raw_tp(void *ctx)
+{
+	return depth(again + 7);
+}
+
 __attribute__ ((noinline))
 int redirects(struct __sk_buff *skb, int n)
 {
diff --git a/tools/testing/selftests/bpf/progs/timed_may_goto_user.c b/tools/testing/selftests/bpf/progs/timed_may_goto_user.c
index 8b85815d45d2..ed56b6afb607 100644
--- a/tools/testing/selftests/bpf/progs/timed_may_goto_user.c
+++ b/tools/testing/selftests/bpf/progs/timed_may_goto_user.c
@@ -277,7 +277,7 @@ int drain(void *ctx)
 }
 
 /*
- * A tracing prog with large frames: they are in a private stack.
+ * A kprobe.multi prog with large frames: they are in a private stack.
  */
 int priv_stack_spun, priv_stack_cb_spun;
 
@@ -296,8 +296,8 @@ static int priv_stack_cb(__u64 i, int *spun)
 	return 0;
 }
 
-SEC("fentry/bpf_fentry_test1")
-int BPF_PROG(priv_stack)
+SEC("kprobe.multi/bpf_fentry_test1")
+int BPF_KPROBE(priv_stack)
 {
 	volatile char buf[128] = {};
 	int i, n = buf[zero & 127], spun = 0;
@@ -309,3 +309,13 @@ int BPF_PROG(priv_stack)
 	priv_stack_cb_spun = spun;
 	return 0;
 }
+
+/*
+ * No tests in here, just to trigger 'bpf_fentry_test*'
+ * through tracing test_run
+ */
+SEC("fentry/bpf_modify_return_test")
+int BPF_PROG(trigger)
+{
+	return 0;
+}
diff --git a/tools/testing/selftests/bpf/progs/verifier_private_stack.c b/tools/testing/selftests/bpf/progs/verifier_private_stack.c
index e7f410a74a21..bebdb0aff23f 100644
--- a/tools/testing/selftests/bpf/progs/verifier_private_stack.c
+++ b/tools/testing/selftests/bpf/progs/verifier_private_stack.c
@@ -127,6 +127,23 @@ __naked void no_private_stack_kprobe(void)
 "	::: __clobber_all);
 }
 
+SEC("fentry/bpf_fentry_test9")
+__description("No private stack, fentry")
+__success
+__arch_x86_64
+__jited("	subq	$0x100, %rsp")
+__arch_arm64
+__jited("	sub	sp, sp, #0x100")
+__naked void no_private_stack_fentry(void)
+{
+	asm volatile ("			\
+	r1 = 42;			\
+	*(u64 *)(r10 - 256) = r1;	\
+	r0 = 0;				\
+	exit;				\
+"	::: __clobber_all);
+}
+
 SEC("uprobe")
 __description("No private stack, uprobe")
 __success
@@ -215,7 +232,7 @@ static unsigned long loop_callback(void)
 	: __clobber_common);
 }
 
-SEC("raw_tp")
+SEC("kprobe.multi")
 __description("Private stack, callback")
 __success
 __arch_x86_64
@@ -273,9 +290,9 @@ __naked void private_stack_callback(void)
 	: __clobber_common);
 }
 
-SEC("fentry/bpf_fentry_test9")
+SEC("perf_event")
 __description("Private stack, exception in main prog")
-__success __retval(0)
+__success
 __arch_x86_64
 __jited("	pushq	%r9")
 __jited("...")
@@ -321,9 +338,9 @@ __used static int subprog_exception(void)
 	return 0;
 }
 
-SEC("fentry/bpf_fentry_test9")
+SEC("perf_event")
 __description("Private stack, exception in subprog")
-__success __retval(0)
+__success
 __arch_x86_64
 __jited("	movq	%rdi, -0x200(%r9)")
 __jited("	pushq	%r9")
@@ -355,19 +372,15 @@ int private_stack_exception_sub_prog(void)
 }
 
 /*
- * Nothing attaches the two fentry progs above, so they are loaded, but never
- * run. BPF_PROG_TEST_RUN does run a raw_tp prog. The default exception callback
- * returns the cookie of bpf_throw().
+ * Nothing attaches the two perf_event progs above, so they are loaded, but
+ * never run. BPF_PROG_TEST_RUN does run a raw_tp prog. The default exception
+ * callback returns the cookie of bpf_throw().
  */
 SEC("raw_tp")
-__description("Private stack, run, exception in main prog")
+__description("No private stack, run, exception in main prog")
 __success __retval(1)
 __arch_x86_64
-__jited("	movq	%rdi, -0x200(%r9)")
-__jited("	movl	$0x1, %edi")
-__jited("	pushq	%r9")
-__jited("...")
-__jited("	callq")
+__jited("	subq	$0x200, %rsp")
 __naked void private_stack_run_exception_main_prog(void)
 {
 	asm volatile ("			\
@@ -396,14 +409,10 @@ __naked static void subprog_throw(void)
 }
 
 SEC("raw_tp")
-__description("Private stack, run, exception in subprog")
+__description("No private stack, run, exception in subprog")
 __success __retval(2)
 __arch_x86_64
-__jited("	movq	%rdi, -0x200(%r9)")
-__jited("	pushq	%r9")
-__jited("...")
-__jited("	callq")
-__jited("	popq	%r9")
+__jited("	subq	$0x200, %rsp")
 __naked void private_stack_run_exception_sub_prog(void)
 {
 	asm volatile ("			\
@@ -432,16 +441,14 @@ __naked static void private_stack_subprog_throw(void)
 
 /* Only the frame of the main prog counts, and it has nothing pushed at the call */
 SEC("raw_tp")
-__description("Private stack, run, exception in subprog, no private stack in main prog")
+__description("No private stack, run, exception in subprog with a large stack")
 __success __retval(3)
 __arch_x86_64
 __jited("	subq	$0x8, %rsp")
 __jited("...")
 __jited("func #1")
 __jited("...")
-__jited("	movq	%rdi, -0x200(%r9)")
-__jited("	movl	$0x3, %edi")
-__jited("	pushq	%r9")
+__jited("	subq	$0x200, %rsp")
 __naked void no_private_stack_run_exception_sub_prog(void)
 {
 	asm volatile ("				\
@@ -478,9 +485,9 @@ __noinline static int timer_cb2(void *map, int *key, struct bpf_timer *timer)
 	return 0;
 }
 
-SEC("fentry/bpf_fentry_test9")
+SEC("kprobe.multi")
 __description("Private stack, async callback, not nested")
-__success __retval(0)
+__success
 __arch_x86_64
 __jited("	movabsq	$0x{{.*}}, %r9")
 __arch_arm64
@@ -503,9 +510,9 @@ int private_stack_async_callback_1(void)
 	return 0;
 }
 
-SEC("fentry/bpf_fentry_test9")
+SEC("kprobe.multi")
 __description("Private stack, async callback, potential nesting")
-__success __retval(0)
+__success
 __load_if_JITed()
 __log_level(4) __msg("stack depth max 272")
 __msg("subprog 0 (private_stack_async_callback_2) main {{.*}} stack 8")
@@ -532,7 +539,7 @@ int private_stack_async_callback_2(void)
 	return 0;
 }
 
-SEC("fentry/bpf_fentry_test9")
+SEC("kprobe.multi")
 __description("private stack, max stack depth is private stack")
 __success
 __log_level(4) __msg("stack depth max 256")
diff --git a/tools/testing/selftests/bpf/progs/verifier_unwind.c b/tools/testing/selftests/bpf/progs/verifier_unwind.c
index 5a21345c34d4..5cdfda16d22f 100644
--- a/tools/testing/selftests/bpf/progs/verifier_unwind.c
+++ b/tools/testing/selftests/bpf/progs/verifier_unwind.c
@@ -1165,9 +1165,9 @@ static unsigned long may_unwind_big_stack(void)
  * x86-64 keeps the pointer to the private stack in r9 and saves it around a call.
  * The value that is read back in the pad is there only when r9 is restored.
  */
-SEC("raw_tp")
+SEC("kprobe.multi")
 __description("unwind: private stack, the callee unwinds")
-__success __retval(47)
+__success
 __load_if_JITed()
 __arch_x86_64
 __jited("	movl	$0x1234, %esi") /* past the load, see above */
@@ -1200,12 +1200,37 @@ __naked int private_stack_unwinds(void)
 }
 
 SEC("raw_tp")
-__description("unwind: private stack, the callee returns")
+__description("unwind: big stack, the callee unwinds")
+__success __retval(47)
+__load_if_JITed()
+__arch_x86_64
+__arch_arm64
+__naked int big_stack_unwinds(void)
+{
+	asm volatile (
+		"*(u64 *)(r10 - 200) = 42;"
+		"r1 = %[one] ll;"
+		"r1 = *(u64 *)(r1 + 0);"
+		"call may_unwind_big_stack;"
+		unwind_goto(1)
+		"exit;"
+		"r1 = *(u64 *)(r10 - 200);"
+		"r0 += r1;"
+		"exit;"
+		:
+		: __imm_addr(one),
+		  __imm_unwind_goto(1)
+		: __clobber_all
+	);
+}
+
+SEC("raw_tp")
+__description("unwind: big stack, the callee returns")
 __success __retval(49)
 __load_if_JITed()
 __arch_x86_64
 __arch_arm64
-__naked int private_stack_returns(void)
+__naked int big_stack_returns(void)
 {
 	asm volatile (
 		"*(u64 *)(r10 - 200) = 42;"

-- 
2.43.0

