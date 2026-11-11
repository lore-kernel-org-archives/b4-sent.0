From: Mike Bazov <mikeba@sentinelone.com>
Date: Wed, 11 Nov 2026 21:39:51 +0200
Subject: [PATCH bpf-next v2 5/5] selftests/bpf: Test syscall tracepoint
 programs under preemption
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261111-bpf-preempt-v2-r2-v2-5-9d8f6b952ad2@sentinelone.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794425986; l=5984;
 i=mikeba@sentinelone.com; s=20261022; h=from:subject:message-id;
 bh=tZ3h3zlk5gZewJOcwTZGC4amQ/qD5S2tjhbroNJXdXY=;
 b=HN1crOzSpxHdzxcK5fDb6DdVngujp0zKQb13Vx/Ms1+8BGezDElI2FaTiIHp2RSDzM+iowa0y
 kcOR0NlmXZ7Cj/JPKgkSJkYeT0id2Msa8Cn7VdaS97m4Hvx2fPlzN9f
X-Developer-Key: i=mikeba@sentinelone.com; a=ed25519;
 pk=DBXcQ0qoCkgacRsRwT1JU7oOWpWSYuTyLiXMfNLcP+A=
X-Endpoint-Received: by B4 Relay for mikeba@sentinelone.com/20261022 with auth_id=1284
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add subtests for classic tracepoint programs on sys_enter_prctl, which
run preemptibly:

- tp_syscall: the same two-thread scenario as the other subtests.
- tailcall_tp: a tracepoint dispatcher tail-calls a large-stack handler.
- tp_dual: one program attached to sys_enter_prctl and to the regular
  task_rename tracepoint, told apart by their attach cookies. A enters
  it through the syscall tracepoint, B through task_rename.

Without the per-task check, every subtest counts recursion misses:
tp_syscall and tailcall_tp drop B's run, and tp_dual drops B's run
through sys_enter_prctl. Without the private-stack change, tailcall_tp
and tp_dual corrupt A's stack.

Signed-off-by: Mike Bazov <mikeba@sentinelone.com>
---
 .../selftests/bpf/prog_tests/trampoline_preempt.c  | 43 ++++++++++++++++++++--
 .../selftests/bpf/progs/trampoline_preempt.c       | 37 +++++++++++++++++++
 2 files changed, 76 insertions(+), 4 deletions(-)

diff --git a/tools/testing/selftests/bpf/prog_tests/trampoline_preempt.c b/tools/testing/selftests/bpf/prog_tests/trampoline_preempt.c
index e01a2ba8916a..a8109290e88d 100644
--- a/tools/testing/selftests/bpf/prog_tests/trampoline_preempt.c
+++ b/tools/testing/selftests/bpf/prog_tests/trampoline_preempt.c
@@ -25,8 +25,11 @@ enum subtest_kind {
 	SUBTEST_RAW_TP_S,
 	SUBTEST_TP_BTF,
 	SUBTEST_FSESSION,
+	SUBTEST_TP_SYSCALL,
 	SUBTEST_TAILCALL_RAW_TP,
+	SUBTEST_TAILCALL_TP,
 	SUBTEST_TWO_DISPATCHERS,
+	SUBTEST_TP_DUAL,
 	SUBTEST_NESTED_PROG,
 };
 
@@ -158,7 +161,7 @@ static void run_subtest(enum subtest_kind kind)
 	sigset_t oldset;
 	pthread_t ta, tb;
 	bool ta_started = false, tb_started = false, sigmask_set = false;
-	bool via_map;
+	bool via_map, dual = false;
 	__u32 zero = 0;
 	int tail_fd;
 	char ch;
@@ -193,17 +196,29 @@ static void run_subtest(enum subtest_kind kind)
 	case SUBTEST_FSESSION:
 		prog = c.skel->progs.on_fsession;
 		break;
+	case SUBTEST_TP_SYSCALL:
+		prog = c.skel->progs.on_tp_syscall;
+		break;
 	case SUBTEST_TAILCALL_RAW_TP:
 		prog = c.skel->progs.dispatcher_raw_tp;
 		tail = c.skel->progs.handler_raw_tp;
 		jmp = c.skel->maps.jmp_raw_tp;
 		break;
+	case SUBTEST_TAILCALL_TP:
+		prog = c.skel->progs.dispatcher_tp;
+		tail = c.skel->progs.handler_tp;
+		jmp = c.skel->maps.jmp_tp;
+		break;
 	case SUBTEST_TWO_DISPATCHERS:
 		prog = c.skel->progs.dispatcher_a;
 		extra = c.skel->progs.dispatcher_b;
 		tail = c.skel->progs.handler_raw_tp;
 		jmp = c.skel->maps.jmp_raw_tp;
 		break;
+	case SUBTEST_TP_DUAL:
+		prog = c.skel->progs.on_tp_dual;
+		dual = true;
+		break;
 	case SUBTEST_NESTED_PROG:
 		prog = c.skel->progs.on_raw_tp_nested;
 		break;
@@ -242,9 +257,23 @@ static void run_subtest(enum subtest_kind kind)
 		if (!ASSERT_OK_PTR(wakeup_link, "attach_wakeup"))
 			goto out;
 	}
-	link = bpf_program__attach(prog);
-	if (!ASSERT_OK_PTR(link, "attach"))
-		goto out;
+	if (dual) {
+		LIBBPF_OPTS(bpf_tracepoint_opts, topts, .bpf_cookie = 1);
+
+		link = bpf_program__attach_tracepoint_opts(prog, "syscalls",
+							   "sys_enter_prctl", &topts);
+		if (!ASSERT_OK_PTR(link, "attach_sys_enter"))
+			goto out;
+		topts.bpf_cookie = 2;
+		link2 = bpf_program__attach_tracepoint_opts(prog, "task",
+							    "task_rename", &topts);
+		if (!ASSERT_OK_PTR(link2, "attach_task_rename"))
+			goto out;
+	} else {
+		link = bpf_program__attach(prog);
+		if (!ASSERT_OK_PTR(link, "attach"))
+			goto out;
+	}
 	if (extra) {
 		link2 = bpf_program__attach(extra);
 		if (!ASSERT_OK_PTR(link2, "attach_extra"))
@@ -412,10 +441,16 @@ void test_trampoline_preempt(void)
 		run_subtest(SUBTEST_TP_BTF);
 	if (test__start_subtest("fsession"))
 		run_subtest(SUBTEST_FSESSION);
+	if (test__start_subtest("tp_syscall"))
+		run_subtest(SUBTEST_TP_SYSCALL);
 	if (test__start_subtest("tailcall_raw_tp"))
 		run_subtest(SUBTEST_TAILCALL_RAW_TP);
+	if (test__start_subtest("tailcall_tp"))
+		run_subtest(SUBTEST_TAILCALL_TP);
 	if (test__start_subtest("two_dispatchers"))
 		run_subtest(SUBTEST_TWO_DISPATCHERS);
+	if (test__start_subtest("tp_dual"))
+		run_subtest(SUBTEST_TP_DUAL);
 	if (test__start_subtest("nested_prog"))
 		run_subtest(SUBTEST_NESTED_PROG);
 	if (test__start_subtest("recursion_raw_tp"))
diff --git a/tools/testing/selftests/bpf/progs/trampoline_preempt.c b/tools/testing/selftests/bpf/progs/trampoline_preempt.c
index 78ed74627a79..e8e610fc885e 100644
--- a/tools/testing/selftests/bpf/progs/trampoline_preempt.c
+++ b/tools/testing/selftests/bpf/progs/trampoline_preempt.c
@@ -27,6 +27,13 @@ struct {
 	__type(value, __u32);
 } jmp_raw_tp SEC(".maps");
 
+struct {
+	__uint(type, BPF_MAP_TYPE_PROG_ARRAY);
+	__uint(max_entries, 1);
+	__type(key, __u32);
+	__type(value, __u32);
+} jmp_tp SEC(".maps");
+
 int tid_a;
 int tid_b;
 int sig;
@@ -184,6 +191,12 @@ int BPF_PROG(on_fsession)
 	return handle_comm(false);
 }
 
+SEC("tp/syscalls/sys_enter_prctl")
+int on_tp_syscall(void *ctx)
+{
+	return handle_comm(false);
+}
+
 SEC("raw_tp/task_rename")
 int dispatcher_raw_tp(void *ctx)
 {
@@ -197,6 +210,19 @@ int handler_raw_tp(void *ctx)
 	return handle_comm(false);
 }
 
+SEC("tp/syscalls/sys_enter_prctl")
+int dispatcher_tp(void *ctx)
+{
+	bpf_tail_call(ctx, &jmp_tp, 0);
+	return 0;
+}
+
+SEC("tp/syscalls/sys_enter_prctl")
+int handler_tp(void *ctx)
+{
+	return handle_comm(false);
+}
+
 SEC("raw_tp/task_rename")
 int dispatcher_a(void *ctx)
 {
@@ -213,6 +239,17 @@ int BPF_PROG(dispatcher_b, struct pt_regs *regs, long id)
 	return 0;
 }
 
+SEC("tp/syscalls/sys_enter_prctl")
+int on_tp_dual(void *ctx)
+{
+	__u32 tid = (__u32)bpf_get_current_pid_tgid();
+	__u64 cookie = bpf_get_attach_cookie(ctx);
+
+	if ((tid == tid_a && cookie != 1) || (tid == tid_b && cookie != 2))
+		return 0;
+	return handle_comm(false);
+}
+
 SEC("raw_tp/bpf_trace_printk")
 int recur_raw_tp(void *ctx)
 {

-- 
2.43.0

