From: Mike Bazov <mikeba@sentinelone.com>
Date: Wed, 11 Nov 2026 21:39:50 +0200
Subject: [PATCH bpf-next v2 4/5] selftests/bpf: Add trampoline and raw_tp
 preemption recursion test
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261111-bpf-preempt-v2-r2-v2-4-9d8f6b952ad2@sentinelone.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794425986; l=19749;
 i=mikeba@sentinelone.com; s=20261022; h=from:subject:message-id;
 bh=nRQ8sdr3Hm4v84tuvpJRSRuPYU7hhDZIWTJyLmDlJtI=;
 b=PxcCbc2s03fMRb75uQ7mrJnHH1qIGi7a1cumwMSN8q85+p5OHVCwRHBD8vijP1CEZNTK27d/c
 v7ZwzMY9KjmAUBBhJwImuK4luO5rcCQyWpuSNOsRaD3jqFwY0VpOxcM
X-Developer-Key: i=mikeba@sentinelone.com; a=ed25519;
 pk=DBXcQ0qoCkgacRsRwT1JU7oOWpWSYuTyLiXMfNLcP+A=
X-Endpoint-Received: by B4 Relay for mikeba@sentinelone.com/20261022 with auth_id=1284
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Pin two threads to one CPU. Thread A enters the program under test and,
from inside it, fills a 64-byte stack buffer and wakes thread B, which
is SCHED_FIFO, so B preempts A in the middle of the program and enters
the same program on the same CPU. Right before entering, B checks that A
is still inside the program, and A confirms that B's run ended before A
checks its buffer. When A resumes, it checks its buffer against its
thread ID, read again from the kernel. Each subtest runs 20 rounds and
asserts that B preempted A inside the program in every round, that both
threads ran every round, that there were no recursion misses, and that
A's stack is intact. If B never preempted A inside the program, the
subtest is skipped.

Subtests: fentry, fexit, fentry.s, fexit.s, fsession, raw_tp, raw_tp.s
and tp_btf. Without the per-task recursion check, B is dropped in every
round.

tailcall_raw_tp and two_dispatchers enter a large-stack handler through
tail calls, from one dispatcher and from two dispatchers. Without the
private-stack change, two_dispatchers corrupts A's stack. nested_prog
wakes B from a second program that runs nested inside A's.

recursion_raw_tp, recursion_tp_btf and recursion_test_run check that
true recursion is still rejected: the program calls bpf_printk(), which
fires the bpf_trace_printk tracepoint it is attached to, and the nested
run must be dropped and counted as a recursion miss. recursion_test_run
starts the outer run with BPF_PROG_TEST_RUN. recursion_two_hops has a
second program run in between, so the check has to look past the frame
right below.

Each subtest loads only its own programs, and is skipped if the kernel
doesn't support its program type.

Signed-off-by: Mike Bazov <mikeba@sentinelone.com>
---
 .../selftests/bpf/prog_tests/trampoline_preempt.c  | 429 +++++++++++++++++++++
 .../selftests/bpf/progs/trampoline_preempt.c       | 265 +++++++++++++
 2 files changed, 694 insertions(+)

diff --git a/tools/testing/selftests/bpf/prog_tests/trampoline_preempt.c b/tools/testing/selftests/bpf/prog_tests/trampoline_preempt.c
new file mode 100644
index 000000000000..e01a2ba8916a
--- /dev/null
+++ b/tools/testing/selftests/bpf/prog_tests/trampoline_preempt.c
@@ -0,0 +1,429 @@
+// SPDX-License-Identifier: GPL-2.0
+#define _GNU_SOURCE
+#include <errno.h>
+#include <pthread.h>
+#include <sched.h>
+#include <signal.h>
+#include <sys/prctl.h>
+#include <sys/syscall.h>
+#include <unistd.h>
+#include <test_progs.h>
+#include "trampoline_preempt.skel.h"
+
+#define NR_ROUNDS 20
+
+#ifndef ENOTSUPP
+#define ENOTSUPP 524
+#endif
+
+enum subtest_kind {
+	SUBTEST_FENTRY,
+	SUBTEST_FEXIT,
+	SUBTEST_FENTRY_S,
+	SUBTEST_FEXIT_S,
+	SUBTEST_RAW_TP,
+	SUBTEST_RAW_TP_S,
+	SUBTEST_TP_BTF,
+	SUBTEST_FSESSION,
+	SUBTEST_TAILCALL_RAW_TP,
+	SUBTEST_TWO_DISPATCHERS,
+	SUBTEST_NESTED_PROG,
+};
+
+enum recursion_kind {
+	RECURSION_RAW_TP,
+	RECURSION_TP_BTF,
+	RECURSION_TEST_RUN,
+	RECURSION_TWO_HOPS,
+};
+
+struct ctx {
+	struct trampoline_preempt *skel;
+	int cpu;
+	int go_pipe[2];
+	int done_pipe[2];
+	sigset_t sigset;
+	int err_a;
+	int err_b;
+	int overlaps;
+};
+
+static int pin_to_cpu(int cpu)
+{
+	cpu_set_t set;
+
+	CPU_ZERO(&set);
+	CPU_SET(cpu, &set);
+	if (sched_setaffinity(0, sizeof(set), &set))
+		return -errno;
+	return 0;
+}
+
+static void *worker_a(void *arg)
+{
+	struct ctx *c = arg;
+	char comm[16] = {};
+	char ch = 'a';
+
+	c->err_a = pin_to_cpu(c->cpu);
+	if (!c->err_a && prctl(PR_GET_NAME, comm, 0, 0, 0))
+		c->err_a = -errno;
+	c->skel->bss->tid_a = (int)syscall(SYS_gettid);
+
+	if (write(c->done_pipe[1], &ch, 1) != 1 || c->err_a)
+		goto out;
+
+	while (read(c->go_pipe[0], &ch, 1) == 1) {
+		if (prctl(PR_SET_NAME, comm, 0, 0, 0)) {
+			c->err_a = -errno;
+			break;
+		}
+		if (write(c->done_pipe[1], &ch, 1) != 1) {
+			c->err_a = -EIO;
+			break;
+		}
+	}
+
+out:
+	close(c->done_pipe[1]);
+	c->done_pipe[1] = -1;
+	return NULL;
+}
+
+static void *worker_b(void *arg)
+{
+	struct sched_param sp = { .sched_priority = 1 };
+	struct timespec ts = { .tv_sec = 5 };
+	struct ctx *c = arg;
+	char comm[16] = {};
+	char ch = 'b';
+	int i;
+
+	c->err_b = pin_to_cpu(c->cpu);
+	if (c->err_b)
+		goto out;
+	if (sched_setscheduler(0, SCHED_FIFO, &sp)) {
+		c->err_b = -errno;
+		goto out;
+	}
+	if (prctl(PR_GET_NAME, comm, 0, 0, 0)) {
+		c->err_b = -errno;
+		goto out;
+	}
+	c->skel->bss->tid_b = (int)syscall(SYS_gettid);
+
+	for (i = 0; i < NR_ROUNDS; i++) {
+		if (write(c->go_pipe[1], &ch, 1) != 1) {
+			c->err_b = -EIO;
+			break;
+		}
+		while (sigtimedwait(&c->sigset, NULL, &ts) < 0) {
+			if (errno == EINTR)
+				continue;
+			c->err_b = -errno;
+			break;
+		}
+		if (c->err_b)
+			break;
+		/* B preempted A only if A is still inside the program */
+		if (*(volatile int *)&c->skel->bss->a_inside)
+			c->overlaps++;
+		if (prctl(PR_SET_NAME, comm, 0, 0, 0)) {
+			c->err_b = -errno;
+			break;
+		}
+		if (read(c->done_pipe[0], &ch, 1) != 1) {
+			c->err_b = -EIO;
+			break;
+		}
+	}
+
+out:
+	close(c->go_pipe[1]);
+	c->go_pipe[1] = -1;
+	return NULL;
+}
+
+static void run_subtest(enum subtest_kind kind)
+{
+	struct ctx c = {
+		.go_pipe = { -1, -1 },
+		.done_pipe = { -1, -1 },
+	};
+	struct bpf_prog_info info = {};
+	__u32 info_len = sizeof(info);
+	struct bpf_program *prog = NULL, *extra = NULL, *tail = NULL, *p;
+	struct bpf_link *link = NULL, *link2 = NULL, *wakeup_link = NULL;
+	struct bpf_map *jmp = NULL;
+	sigset_t oldset;
+	pthread_t ta, tb;
+	bool ta_started = false, tb_started = false, sigmask_set = false;
+	bool via_map;
+	__u32 zero = 0;
+	int tail_fd;
+	char ch;
+	int err;
+
+	c.skel = trampoline_preempt__open();
+	if (!ASSERT_OK_PTR(c.skel, "open"))
+		return;
+
+	switch (kind) {
+	case SUBTEST_FENTRY:
+		prog = c.skel->progs.on_fentry;
+		break;
+	case SUBTEST_FEXIT:
+		prog = c.skel->progs.on_fexit;
+		break;
+	case SUBTEST_FENTRY_S:
+		prog = c.skel->progs.on_fentry_s;
+		break;
+	case SUBTEST_FEXIT_S:
+		prog = c.skel->progs.on_fexit_s;
+		break;
+	case SUBTEST_RAW_TP:
+		prog = c.skel->progs.on_raw_tp;
+		break;
+	case SUBTEST_RAW_TP_S:
+		prog = c.skel->progs.on_raw_tp_s;
+		break;
+	case SUBTEST_TP_BTF:
+		prog = c.skel->progs.on_tp_btf;
+		break;
+	case SUBTEST_FSESSION:
+		prog = c.skel->progs.on_fsession;
+		break;
+	case SUBTEST_TAILCALL_RAW_TP:
+		prog = c.skel->progs.dispatcher_raw_tp;
+		tail = c.skel->progs.handler_raw_tp;
+		jmp = c.skel->maps.jmp_raw_tp;
+		break;
+	case SUBTEST_TWO_DISPATCHERS:
+		prog = c.skel->progs.dispatcher_a;
+		extra = c.skel->progs.dispatcher_b;
+		tail = c.skel->progs.handler_raw_tp;
+		jmp = c.skel->maps.jmp_raw_tp;
+		break;
+	case SUBTEST_NESTED_PROG:
+		prog = c.skel->progs.on_raw_tp_nested;
+		break;
+	}
+	via_map = kind == SUBTEST_NESTED_PROG;
+	bpf_object__for_each_program(p, c.skel->obj)
+		bpf_program__set_autoload(p, p == prog || p == extra || p == tail ||
+					  (via_map && p == c.skel->progs.on_wakeup_delete));
+
+	err = trampoline_preempt__load(c.skel);
+	if (err == -EOPNOTSUPP || err == -ENOTSUPP) {
+		test__skip();
+		goto out;
+	}
+	if (!ASSERT_OK(err, "load"))
+		goto out;
+
+	c.cpu = sched_getcpu();
+	if (!ASSERT_GE(c.cpu, 0, "sched_getcpu"))
+		goto out;
+
+	if (!ASSERT_OK(pipe(c.go_pipe), "go_pipe"))
+		goto out;
+	if (!ASSERT_OK(pipe(c.done_pipe), "done_pipe"))
+		goto out;
+
+	sigemptyset(&c.sigset);
+	sigaddset(&c.sigset, SIGUSR1);
+	if (!ASSERT_OK(pthread_sigmask(SIG_BLOCK, &c.sigset, &oldset), "sigmask"))
+		goto out;
+	sigmask_set = true;
+
+	c.skel->bss->sig = SIGUSR1;
+	if (via_map) {
+		wakeup_link = bpf_program__attach(c.skel->progs.on_wakeup_delete);
+		if (!ASSERT_OK_PTR(wakeup_link, "attach_wakeup"))
+			goto out;
+	}
+	link = bpf_program__attach(prog);
+	if (!ASSERT_OK_PTR(link, "attach"))
+		goto out;
+	if (extra) {
+		link2 = bpf_program__attach(extra);
+		if (!ASSERT_OK_PTR(link2, "attach_extra"))
+			goto out;
+	}
+	if (tail) {
+		tail_fd = bpf_program__fd(tail);
+		if (!ASSERT_OK(bpf_map_update_elem(bpf_map__fd(jmp), &zero, &tail_fd,
+						   BPF_ANY), "jmp_update"))
+			goto out;
+	}
+
+	if (!ASSERT_OK(pthread_create(&ta, NULL, worker_a, &c), "pthread_a"))
+		goto out;
+	ta_started = true;
+
+	if (!ASSERT_EQ(read(c.done_pipe[0], &ch, 1), 1, "ready_a"))
+		goto out;
+	if (!ASSERT_OK(c.err_a, "setup_a"))
+		goto out;
+
+	if (!ASSERT_OK(pthread_create(&tb, NULL, worker_b, &c), "pthread_b"))
+		goto out;
+	tb_started = true;
+
+	pthread_join(tb, NULL);
+	tb_started = false;
+	pthread_join(ta, NULL);
+	ta_started = false;
+
+	if (c.err_b == -EPERM || c.err_b == -EACCES) {
+		test__skip();
+		goto out;
+	}
+
+	ASSERT_OK(c.err_a, "worker_a_err");
+	ASSERT_OK(c.err_b, "worker_b_err");
+	ASSERT_EQ(c.skel->bss->sig_err, 0, "sig_err");
+	if (!c.overlaps) {
+		/* B never preempted A inside the program, so nothing was tested */
+		test__skip();
+		goto out;
+	}
+	ASSERT_EQ(c.overlaps, NR_ROUNDS, "overlaps");
+	ASSERT_EQ(c.skel->bss->stack_corrupt, 0, "stack_corrupt");
+	ASSERT_EQ(c.skel->bss->runs_a, NR_ROUNDS, "runs_a");
+	ASSERT_EQ(c.skel->bss->runs_b, NR_ROUNDS, "runs_b");
+	ASSERT_EQ(c.skel->bss->b_inside_a, c.skel->bss->runs_b, "b_inside_a");
+
+	err = bpf_prog_get_info_by_fd(bpf_program__fd(prog), &info, &info_len);
+	if (ASSERT_OK(err, "prog_info"))
+		ASSERT_EQ(info.recursion_misses, 0, "recursion_misses");
+
+out:
+	if (c.go_pipe[1] >= 0)
+		close(c.go_pipe[1]);
+	if (tb_started)
+		pthread_join(tb, NULL);
+	if (ta_started)
+		pthread_join(ta, NULL);
+	if (c.go_pipe[0] >= 0)
+		close(c.go_pipe[0]);
+	if (c.done_pipe[0] >= 0)
+		close(c.done_pipe[0]);
+	if (c.done_pipe[1] >= 0)
+		close(c.done_pipe[1]);
+	if (sigmask_set)
+		pthread_sigmask(SIG_SETMASK, &oldset, NULL);
+	bpf_link__destroy(link);
+	bpf_link__destroy(link2);
+	bpf_link__destroy(wakeup_link);
+	trampoline_preempt__destroy(c.skel);
+}
+
+/*
+ * The program calls bpf_printk(), which fires the bpf_trace_printk tracepoint
+ * the program is attached to. The nested run must be rejected as recursion.
+ * With two hops, a second program runs in between, so the check has to look
+ * past the frame right below.
+ */
+static void run_recursion_subtest(enum recursion_kind kind)
+{
+	LIBBPF_OPTS(bpf_test_run_opts, opts);
+	struct bpf_prog_info info = {};
+	__u32 info_len = sizeof(info);
+	struct trampoline_preempt *skel;
+	struct bpf_program *prog, *hop = NULL, *trigger, *p;
+	struct bpf_link *link = NULL, *hop_link = NULL;
+	int err;
+
+	skel = trampoline_preempt__open();
+	if (!ASSERT_OK_PTR(skel, "open"))
+		return;
+
+	switch (kind) {
+	case RECURSION_TP_BTF:
+		prog = skel->progs.recur_tp_btf;
+		break;
+	case RECURSION_TWO_HOPS:
+		prog = skel->progs.recur_two_hops;
+		hop = skel->progs.recur_hop;
+		break;
+	default:
+		prog = skel->progs.recur_raw_tp;
+		break;
+	}
+	trigger = kind == RECURSION_TEST_RUN ? prog : skel->progs.recur_trigger;
+	bpf_object__for_each_program(p, skel->obj)
+		bpf_program__set_autoload(p, p == prog || p == hop || p == trigger);
+
+	err = trampoline_preempt__load(skel);
+	if (err == -EOPNOTSUPP || err == -ENOTSUPP) {
+		test__skip();
+		goto out;
+	}
+	if (!ASSERT_OK(err, "load"))
+		goto out;
+	link = bpf_program__attach(prog);
+	if (!ASSERT_OK_PTR(link, "attach"))
+		goto out;
+	if (hop) {
+		hop_link = bpf_program__attach(hop);
+		if (!ASSERT_OK_PTR(hop_link, "attach_hop"))
+			goto out;
+	}
+
+	skel->bss->recur_tid = (int)syscall(SYS_gettid);
+	err = bpf_prog_test_run_opts(bpf_program__fd(trigger), &opts);
+	skel->bss->recur_tid = 0;
+	if (!ASSERT_OK(err, "test_run"))
+		goto out;
+
+	ASSERT_EQ(skel->bss->recur_runs, 1, "recur_runs");
+	err = bpf_prog_get_info_by_fd(bpf_program__fd(prog), &info, &info_len);
+	if (ASSERT_OK(err, "prog_info"))
+		ASSERT_EQ(info.recursion_misses, 1, "recursion_misses");
+	if (hop) {
+		ASSERT_EQ(skel->bss->hop_runs, 1, "hop_runs");
+		memset(&info, 0, sizeof(info));
+		err = bpf_prog_get_info_by_fd(bpf_program__fd(hop), &info, &info_len);
+		if (ASSERT_OK(err, "hop_info"))
+			ASSERT_EQ(info.recursion_misses, 0, "hop_recursion_misses");
+	}
+out:
+	bpf_link__destroy(hop_link);
+	bpf_link__destroy(link);
+	trampoline_preempt__destroy(skel);
+}
+
+void test_trampoline_preempt(void)
+{
+	if (test__start_subtest("fentry"))
+		run_subtest(SUBTEST_FENTRY);
+	if (test__start_subtest("fexit"))
+		run_subtest(SUBTEST_FEXIT);
+	if (test__start_subtest("fentry_s"))
+		run_subtest(SUBTEST_FENTRY_S);
+	if (test__start_subtest("fexit_s"))
+		run_subtest(SUBTEST_FEXIT_S);
+	if (test__start_subtest("raw_tp"))
+		run_subtest(SUBTEST_RAW_TP);
+	if (test__start_subtest("raw_tp_s"))
+		run_subtest(SUBTEST_RAW_TP_S);
+	if (test__start_subtest("tp_btf"))
+		run_subtest(SUBTEST_TP_BTF);
+	if (test__start_subtest("fsession"))
+		run_subtest(SUBTEST_FSESSION);
+	if (test__start_subtest("tailcall_raw_tp"))
+		run_subtest(SUBTEST_TAILCALL_RAW_TP);
+	if (test__start_subtest("two_dispatchers"))
+		run_subtest(SUBTEST_TWO_DISPATCHERS);
+	if (test__start_subtest("nested_prog"))
+		run_subtest(SUBTEST_NESTED_PROG);
+	if (test__start_subtest("recursion_raw_tp"))
+		run_recursion_subtest(RECURSION_RAW_TP);
+	if (test__start_subtest("recursion_tp_btf"))
+		run_recursion_subtest(RECURSION_TP_BTF);
+	if (test__start_subtest("recursion_test_run"))
+		run_recursion_subtest(RECURSION_TEST_RUN);
+	if (test__start_subtest("recursion_two_hops"))
+		run_recursion_subtest(RECURSION_TWO_HOPS);
+}
diff --git a/tools/testing/selftests/bpf/progs/trampoline_preempt.c b/tools/testing/selftests/bpf/progs/trampoline_preempt.c
new file mode 100644
index 000000000000..78ed74627a79
--- /dev/null
+++ b/tools/testing/selftests/bpf/progs/trampoline_preempt.c
@@ -0,0 +1,265 @@
+// SPDX-License-Identifier: GPL-2.0
+#include "vmlinux.h"
+#include <asm/unistd.h>
+#include <bpf/bpf_helpers.h>
+#include <bpf/bpf_tracing.h>
+#include "bpf_misc.h"
+
+char _license[] SEC("license") = "GPL";
+
+struct task_struct *bpf_task_from_pid(s32 pid) __ksym;
+void bpf_task_release(struct task_struct *p) __ksym;
+int bpf_send_signal_task(struct task_struct *task, int sig, enum pid_type type, u64 value) __ksym;
+void bpf_rcu_read_lock(void) __ksym;
+void bpf_rcu_read_unlock(void) __ksym;
+
+struct {
+	__uint(type, BPF_MAP_TYPE_HASH);
+	__uint(max_entries, 1);
+	__type(key, int);
+	__type(value, int);
+} wakeup_map SEC(".maps");
+
+struct {
+	__uint(type, BPF_MAP_TYPE_PROG_ARRAY);
+	__uint(max_entries, 1);
+	__type(key, __u32);
+	__type(value, __u32);
+} jmp_raw_tp SEC(".maps");
+
+int tid_a;
+int tid_b;
+int sig;
+int runs_a;
+int runs_b;
+int sig_err;
+int stack_corrupt;
+int a_inside;
+int b_inside_a;
+int recur_tid;
+int recur_runs;
+
+static __always_inline void fill_stack(__u64 *buf, __u32 tid)
+{
+	#pragma unroll
+	for (int i = 0; i < 8; i++)
+		buf[i] = ((__u64)tid << 32) | (0x5a5a0000U + i);
+}
+
+static __always_inline void check_stack(const __u64 *buf, __u32 tid)
+{
+	#pragma unroll
+	for (int i = 0; i < 8; i++) {
+		if (buf[i] != (((__u64)tid << 32) | (0x5a5a0000U + i)))
+			stack_corrupt = 1;
+	}
+}
+
+static void signal_worker_b(void)
+{
+	struct task_struct *task;
+
+	bpf_rcu_read_lock();
+	task = bpf_task_from_pid(tid_b);
+	if (!task) {
+		sig_err = 1;
+		bpf_rcu_read_unlock();
+		return;
+	}
+	if (bpf_send_signal_task(task, sig, PIDTYPE_PID, 0))
+		sig_err = 1;
+	bpf_task_release(task);
+	bpf_rcu_read_unlock();
+}
+
+static __always_inline int handle_comm(bool via_map)
+{
+	__u32 tid = (__u32)bpf_get_current_pid_tgid();
+	__u64 stack_buf[8];
+	int zero = 0;
+
+	if (tid != tid_a && tid != tid_b)
+		return 0;
+
+	fill_stack(stack_buf, tid);
+	asm volatile("" : "+m"(stack_buf));
+
+	if (tid == tid_a) {
+		int runs_b_before = *(volatile int *)&runs_b;
+
+		runs_a++;
+		*(volatile int *)&a_inside = 1;
+		if (via_map)
+			bpf_map_delete_elem(&wakeup_map, &zero);
+		else
+			signal_worker_b();
+		/* B's whole run happened after the wakeup and before the stack check */
+		if (*(volatile int *)&runs_b != runs_b_before)
+			b_inside_a++;
+	} else {
+		runs_b++;
+	}
+
+	asm volatile("" : "+m"(stack_buf));
+	/* Don't trust a copy of tid that may have been spilled to the stack under test */
+	tid = (__u32)bpf_get_current_pid_tgid();
+	check_stack(stack_buf, tid);
+	if (tid == tid_a)
+		*(volatile int *)&a_inside = 0;
+	return 0;
+}
+
+static __always_inline int recur_body(void)
+{
+	if ((__u32)bpf_get_current_pid_tgid() != recur_tid)
+		return 0;
+	recur_runs++;
+	bpf_printk("recur");
+	return 0;
+}
+
+SEC("fentry/__set_task_comm")
+int BPF_PROG(on_fentry)
+{
+	return handle_comm(false);
+}
+
+SEC("fexit/__set_task_comm")
+int BPF_PROG(on_fexit)
+{
+	return handle_comm(false);
+}
+
+SEC("fentry.s/" SYS_PREFIX "sys_prctl")
+int BPF_PROG(on_fentry_s)
+{
+	return handle_comm(false);
+}
+
+SEC("fexit.s/" SYS_PREFIX "sys_prctl")
+int BPF_PROG(on_fexit_s)
+{
+	return handle_comm(false);
+}
+
+SEC("fentry/htab_map_delete_elem")
+int BPF_PROG(on_wakeup_delete, struct bpf_map *map)
+{
+	if (map == (struct bpf_map *)&wakeup_map)
+		signal_worker_b();
+	return 0;
+}
+
+SEC("raw_tp/task_rename")
+int BPF_PROG(on_raw_tp)
+{
+	return handle_comm(false);
+}
+
+SEC("raw_tp/task_rename")
+int BPF_PROG(on_raw_tp_nested)
+{
+	return handle_comm(true);
+}
+
+SEC("raw_tp.s/sys_enter")
+int BPF_PROG(on_raw_tp_s, struct pt_regs *regs, long id)
+{
+	if (id != __NR_prctl)
+		return 0;
+	return handle_comm(false);
+}
+
+SEC("tp_btf/task_rename")
+int BPF_PROG(on_tp_btf)
+{
+	return handle_comm(false);
+}
+
+SEC("fsession/__set_task_comm")
+int BPF_PROG(on_fsession)
+{
+	if (bpf_session_is_return(ctx))
+		return 0;
+	return handle_comm(false);
+}
+
+SEC("raw_tp/task_rename")
+int dispatcher_raw_tp(void *ctx)
+{
+	bpf_tail_call(ctx, &jmp_raw_tp, 0);
+	return 0;
+}
+
+SEC("raw_tp/task_rename")
+int handler_raw_tp(void *ctx)
+{
+	return handle_comm(false);
+}
+
+SEC("raw_tp/task_rename")
+int dispatcher_a(void *ctx)
+{
+	if ((__u32)bpf_get_current_pid_tgid() == tid_a)
+		bpf_tail_call(ctx, &jmp_raw_tp, 0);
+	return 0;
+}
+
+SEC("raw_tp/sys_enter")
+int BPF_PROG(dispatcher_b, struct pt_regs *regs, long id)
+{
+	if (id == __NR_prctl && (__u32)bpf_get_current_pid_tgid() == tid_b)
+		bpf_tail_call(ctx, &jmp_raw_tp, 0);
+	return 0;
+}
+
+SEC("raw_tp/bpf_trace_printk")
+int recur_raw_tp(void *ctx)
+{
+	return recur_body();
+}
+
+SEC("tp_btf/bpf_trace_printk")
+int BPF_PROG(recur_tp_btf)
+{
+	return recur_body();
+}
+
+SEC("syscall")
+int recur_trigger(void *ctx)
+{
+	bpf_printk("trigger");
+	return 0;
+}
+
+struct {
+	__uint(type, BPF_MAP_TYPE_HASH);
+	__uint(max_entries, 1);
+	__type(key, int);
+	__type(value, int);
+} recur_map SEC(".maps");
+
+int hop_runs;
+
+SEC("raw_tp/bpf_trace_printk")
+int recur_two_hops(void *ctx)
+{
+	int zero = 0;
+
+	if ((__u32)bpf_get_current_pid_tgid() != recur_tid)
+		return 0;
+	recur_runs++;
+	bpf_map_delete_elem(&recur_map, &zero);
+	return 0;
+}
+
+SEC("fentry/htab_map_delete_elem")
+int BPF_PROG(recur_hop, struct bpf_map *map)
+{
+	if (map != (struct bpf_map *)&recur_map ||
+	    (__u32)bpf_get_current_pid_tgid() != recur_tid)
+		return 0;
+	hop_runs++;
+	bpf_printk("hop");
+	return 0;
+}

-- 
2.43.0

