From: Mike Bazov <mikeba@sentinelone.com>
Date: Tue, 17 Nov 2026 13:29:17 +0200
Subject: [PATCH bpf-next v3 4/4] selftests/bpf: Add preemption recursion
 test for tracing programs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261117-bpf-preempt-v2-r2-v3-4-586376ec3672@sentinelone.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794914965; l=21631;
 i=mikeba@sentinelone.com; s=20261022; h=from:subject:message-id;
 bh=WjiK8dAWhVcaMSoACIh3b5DIFIqls0LN19VE1gGzYZ4=;
 b=7Z/XyOWfdaRq3/wHpnlRJIC6ejDQJVsFzo+tWWPcHSKEuENvShRp/tyR0Blkia6g7YXGV+RJI
 zGv7rP1JrQ8AQTqn9dfiBci1bzJNoE0lXXTG4VwKplTHrCTbFBJciar
X-Developer-Key: i=mikeba@sentinelone.com; a=ed25519;
 pk=DBXcQ0qoCkgacRsRwT1JU7oOWpWSYuTyLiXMfNLcP+A=
X-Endpoint-Received: by B4 Relay for mikeba@sentinelone.com/20261022 with auth_id=1284
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Pin two threads to one CPU. Thread B is SCHED_FIFO and waits for a
signal that thread A sends from inside the program under test, so B
preempts A there and enters the same program on the same CPU. Each
subtest runs 20 rounds and checks in every round that A was inside the
program when B ran. It is skipped if that never happens, as on a kernel
that doesn't preempt kernel code.

- fentry, fentry_s, raw_tp, raw_tp_s, tp_syscall: a program without
  per-CPU state. Both threads must run it in every round, without
  recursion misses.
- *_percpu, percpu_var, this_cpu_ptr, tail_call, may_goto: a program
  with a per-CPU map, a per-CPU variable, bpf_this_cpu_ptr(), a tail
  call or timed may_goto. B must be dropped and counted in every
  round. A constant selects the per-CPU state that the handler
  touches; with none selected, the same code doesn't mark the program.
- two_dispatchers: two raw tracepoint programs tail-call one handler.
  Both threads run it at once, and A checks that the stack buffer it
  filled before B ran is intact.
- recursion_raw_tp, recursion_two_hops, recursion_test_run: true
  recursion is still dropped and counted: directly, through a second
  program, and from BPF_PROG_TEST_RUN.
- ext_attach: an extension that uses a per-CPU map can't be attached
  to a raw tracepoint program that doesn't, while one without can.

Signed-off-by: Mike Bazov <mikeba@sentinelone.com>
---
 .../selftests/bpf/prog_tests/trampoline_preempt.c  | 352 +++++++++++++++++++++
 .../selftests/bpf/progs/trampoline_preempt.c       | 258 +++++++++++++++
 2 files changed, 610 insertions(+)

diff --git a/tools/testing/selftests/bpf/prog_tests/trampoline_preempt.c b/tools/testing/selftests/bpf/prog_tests/trampoline_preempt.c
new file mode 100644
index 000000000000..f282fdba5d16
--- /dev/null
+++ b/tools/testing/selftests/bpf/prog_tests/trampoline_preempt.c
@@ -0,0 +1,352 @@
+// SPDX-License-Identifier: GPL-2.0
+#define _GNU_SOURCE
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
+/* The kernel's own "not supported" error, which the libc headers don't have */
+#ifndef ENOTSUPP
+#define ENOTSUPP 524
+#endif
+
+/*
+ * Threads A and B are pinned to one CPU. B is SCHED_FIFO and waits for a signal:
+ *
+ *   A: prctl() -> enters the program under test
+ *                 the program sends B the signal
+ *   B:            wakes up and preempts A, which is still inside the program
+ *                 prctl() -> enters the same program on the same CPU
+ *
+ * A program whose recursion is checked per task runs for B too. A program that
+ * keeps per-CPU state keeps the per-CPU check: B's run is dropped and counted
+ * as a recursion miss.
+ */
+
+/* The per-CPU state that a program touches, see progs/trampoline_preempt.c */
+enum { NO_PERCPU, PERCPU_MAP, PERCPU_VAR, THIS_CPU_PTR };
+
+enum expect {
+	B_RUNS,		/* B runs the program, without recursion misses */
+	B_DROPPED,	/* B's runs are dropped and counted as recursion misses */
+	B_RUNS_HANDLER,	/* two_dispatchers: dropped by one dispatcher, runs through the other */
+};
+
+/* What threads A and B share */
+struct ctx {
+	struct trampoline_preempt *skel;
+	sigset_t sigset;
+	int cpu, err_a, err_b;
+	int overlaps;	/* rounds in which B found A still inside the program */
+};
+
+/* Only timed may_goto keeps its budget per CPU, and only these JITs have it */
+static bool has_timed_may_goto(void)
+{
+#if defined(__x86_64__) || defined(__aarch64__) || defined(__s390x__) || \
+	defined(__powerpc64__) || (defined(__riscv) && __riscv_xlen == 64) || \
+	(defined(__loongarch__) && __loongarch_grlen == 64)
+	return is_jit_enabled();
+#else
+	return false;
+#endif
+}
+
+static int pin_to_cpu(int cpu)
+{
+	cpu_set_t set;
+
+	CPU_ZERO(&set);
+	CPU_SET(cpu, &set);
+	return sched_setaffinity(0, sizeof(set), &set) ? -errno : 0;
+}
+
+/* A enters the program under test, which wakes B from inside it */
+static void *worker_a(void *arg)
+{
+	struct ctx *c = arg;
+	int i;
+
+	c->err_a = pin_to_cpu(c->cpu);
+	c->skel->bss->tid_a = syscall(SYS_gettid);
+	for (i = 0; i < NR_ROUNDS && !c->err_a; i++) {
+		/* Passes every hook that the programs under test are attached to */
+		if (prctl(PR_SET_NAME, "worker_a"))
+			c->err_a = -errno;
+	}
+	return NULL;
+}
+
+/* B is SCHED_FIFO on A's CPU: A runs only while B waits, and B preempts A as soon as A wakes it */
+static void *worker_b(void *arg)
+{
+	struct sched_param sp = { .sched_priority = 1 };
+	struct timespec ts = { .tv_sec = 5 };	/* give up if the signal never comes */
+	struct ctx *c = arg;
+	int i;
+
+	c->err_b = pin_to_cpu(c->cpu);
+	if (!c->err_b && sched_setscheduler(0, SCHED_FIFO, &sp))
+		c->err_b = -errno;
+	c->skel->bss->tid_b = syscall(SYS_gettid);
+	for (i = 0; i < NR_ROUNDS && !c->err_b; i++) {
+		while (sigtimedwait(&c->sigset, NULL, &ts) < 0) {
+			if (errno != EINTR) {
+				c->err_b = -errno;
+				return NULL;
+			}
+		}
+		/* B preempted A only if A is still inside the program */
+		if (*(volatile int *)&c->skel->bss->a_inside)
+			c->overlaps++;
+		/* B's own run of the program, while A is preempted inside it */
+		if (prctl(PR_SET_NAME, "worker_b"))
+			c->err_b = -errno;
+	}
+	return NULL;
+}
+
+/* Load and attach only programs @a, @b and @c. NULL after a failure or a skip. */
+static struct trampoline_preempt *load_progs(const char *a, const char *b, const char *c,
+					      int percpu)
+{
+	struct trampoline_preempt *skel = trampoline_preempt__open();
+	struct bpf_program *p;
+	const char *name;
+	int err;
+
+	if (!ASSERT_OK_PTR(skel, "open"))
+		return NULL;
+	bpf_object__for_each_program(p, skel->obj) {
+		name = bpf_program__name(p);
+		bpf_program__set_autoload(p, !strcmp(name, a) || (b && !strcmp(name, b)) ||
+					     (c && !strcmp(name, c)));
+	}
+	skel->bss->sig = SIGUSR1;
+	skel->rodata->percpu = percpu;
+	err = trampoline_preempt__load(skel);
+	/* The kernel or its JIT doesn't support one of the programs */
+	if (err == -EOPNOTSUPP || err == -ENOTSUPP)
+		test__skip();
+	else if (ASSERT_OK(err, "load") && ASSERT_OK(trampoline_preempt__attach(skel), "attach"))
+		return skel;
+	trampoline_preempt__destroy(skel);
+	return NULL;
+}
+
+static const struct subtest {
+	const char *name;
+	const char *prog;	/* A enters it; its recursion misses are checked */
+	int percpu;		/* the per-CPU state that the program touches */
+	enum expect expect;
+	const char *prog_b;	/* two_dispatchers: B reaches the handler through this one */
+	const char *handler;	/* two_dispatchers: the target of both tail calls */
+} subtests[] = {
+	/* Each kind of program, without per-CPU state and with a per-CPU map lookup */
+	{ "fentry",		"on_fentry",		NO_PERCPU,	B_RUNS },
+	{ "fentry_percpu",	"on_fentry",		PERCPU_MAP,	B_DROPPED },
+	{ "fentry_s",		"on_fentry_s",		NO_PERCPU,	B_RUNS },
+	{ "fentry_s_percpu",	"on_fentry_s",		PERCPU_MAP,	B_DROPPED },
+	{ "raw_tp",		"on_raw_tp",		NO_PERCPU,	B_RUNS },
+	{ "raw_tp_percpu",	"on_raw_tp",		PERCPU_MAP,	B_DROPPED },
+	{ "raw_tp_s",		"on_raw_tp_s",		NO_PERCPU,	B_RUNS },
+	{ "raw_tp_s_percpu",	"on_raw_tp_s",		PERCPU_MAP,	B_DROPPED },
+	{ "tp_syscall",		"on_tp_syscall",	NO_PERCPU,	B_RUNS },
+	{ "tp_syscall_percpu",	"on_tp_syscall",	PERCPU_MAP,	B_DROPPED },
+	/* The other things that keep a program on the per-CPU check */
+	{ "percpu_var",		"on_raw_tp",		PERCPU_VAR,	B_DROPPED },
+	{ "this_cpu_ptr",	"on_raw_tp",		THIS_CPU_PTR,	B_DROPPED },
+	{ "tail_call",		"on_tail_call",		NO_PERCPU,	B_DROPPED },
+	{ "may_goto",		"on_may_goto",		NO_PERCPU,	B_DROPPED },
+	/* Both threads are inside the handler at once, and A's stack must stay intact */
+	{ "two_dispatchers",	"dispatcher_a",		NO_PERCPU,	B_RUNS_HANDLER,
+	  "dispatcher_b", "handler" },
+};
+
+static void run_subtest(const struct subtest *t)
+{
+	struct bpf_prog_info info = {};
+	__u32 info_len = sizeof(info), zero = 0;
+	struct ctx c = {};
+	sigset_t oldset;
+	pthread_t ta, tb;
+	int err, fd;
+
+	if (!strcmp(t->name, "may_goto") && !has_timed_may_goto()) {
+		test__skip();
+		return;
+	}
+	c.skel = load_progs(t->prog, t->prog_b, t->handler, t->percpu);
+	if (!c.skel)
+		return;
+	if (t->handler) {
+		/* Both dispatchers tail-call the handler through the prog array */
+		fd = bpf_program__fd(bpf_object__find_program_by_name(c.skel->obj, t->handler));
+		err = bpf_map_update_elem(bpf_map__fd(c.skel->maps.prog_array), &zero, &fd,
+					  BPF_ANY);
+		if (!ASSERT_OK(err, "prog_array_update"))
+			goto out;
+	}
+
+	/* Both threads go on this CPU. B takes the signal with sigtimedwait(), so block it. */
+	c.cpu = sched_getcpu();
+	sigemptyset(&c.sigset);
+	sigaddset(&c.sigset, SIGUSR1);
+	if (!ASSERT_OK(pthread_sigmask(SIG_BLOCK, &c.sigset, &oldset), "sigmask"))
+		goto out;
+	if (ASSERT_OK(pthread_create(&tb, NULL, worker_b, &c), "pthread_b")) {
+		/* A's program needs tid_b to wake B */
+		while (!c.skel->bss->tid_b)
+			usleep(1000);
+		if (ASSERT_OK(pthread_create(&ta, NULL, worker_a, &c), "pthread_a"))
+			pthread_join(ta, NULL);
+		pthread_join(tb, NULL);
+	}
+	pthread_sigmask(SIG_SETMASK, &oldset, NULL);
+
+	/* B may not be allowed to become SCHED_FIFO */
+	if (c.err_b == -EPERM || c.err_b == -EACCES) {
+		test__skip();
+		goto out;
+	}
+	ASSERT_OK(c.err_a, "worker_a");
+	ASSERT_OK(c.err_b, "worker_b");
+	ASSERT_EQ(c.skel->bss->sig_err, 0, "sig_err");
+	if (!c.overlaps) {
+		/* B never preempted A inside the program, so nothing was tested */
+		test__skip();
+		goto out;
+	}
+	ASSERT_EQ(c.overlaps, NR_ROUNDS, "overlaps");
+	ASSERT_EQ(c.skel->bss->runs_a, NR_ROUNDS, "runs_a");
+	ASSERT_EQ(c.skel->bss->runs_b, t->expect == B_DROPPED ? 0 : NR_ROUNDS, "runs_b");
+	if (t->handler)
+		ASSERT_EQ(c.skel->bss->stack_corrupt, 0, "stack_corrupt");
+	fd = bpf_program__fd(bpf_object__find_program_by_name(c.skel->obj, t->prog));
+	err = bpf_prog_get_info_by_fd(fd, &info, &info_len);
+	if (!ASSERT_OK(err, "prog_info"))
+		goto out;
+	/* A program on sys_enter also misses B's other syscalls: at least one miss per round */
+	if (t->expect == B_RUNS)
+		ASSERT_EQ(info.recursion_misses, 0, "recursion_misses");
+	else
+		ASSERT_GE(info.recursion_misses, NR_ROUNDS, "recursion_misses");
+out:
+	trampoline_preempt__destroy(c.skel);
+}
+
+/*
+ * The program calls bpf_printk(), which fires the bpf_trace_printk tracepoint
+ * that it is attached to: the nested run must be rejected as recursion. With a
+ * hop, a second program runs in between, so the check has to look past the
+ * frame right below.
+ */
+static const struct recursion {
+	const char *name, *prog, *hop;
+	bool test_run;	/* Start the outer run with BPF_PROG_TEST_RUN of @prog */
+} recursions[] = {
+	{ "recursion_raw_tp", "recur_raw_tp" },
+	{ "recursion_two_hops", "recur_two_hops", "recur_hop" },
+	{ "recursion_test_run", "recur_raw_tp", .test_run = true },
+};
+
+static void run_recursion(const struct recursion *t)
+{
+	struct trampoline_preempt *skel = load_progs(t->prog, t->hop, "recur_trigger", NO_PERCPU);
+	LIBBPF_OPTS(bpf_test_run_opts, opts);
+	struct bpf_prog_info info = {};
+	__u32 info_len = sizeof(info);
+	int err, fd, run_fd;
+
+	if (!skel)
+		return;
+	fd = bpf_program__fd(bpf_object__find_program_by_name(skel->obj, t->prog));
+	/* The outer run: of @prog itself, or of a program that fires its tracepoint */
+	run_fd = t->test_run ? fd : bpf_program__fd(skel->progs.recur_trigger);
+	skel->bss->recur_tid = syscall(SYS_gettid);
+	err = bpf_prog_test_run_opts(run_fd, &opts);
+	skel->bss->recur_tid = 0;
+	/* The outer run got in; the nested one was dropped and counted */
+	if (ASSERT_OK(err, "test_run")) {
+		ASSERT_EQ(skel->bss->recur_runs, 1, "recur_runs");
+		ASSERT_EQ(skel->bss->hop_runs, t->hop ? 1 : 0, "hop_runs");
+		err = bpf_prog_get_info_by_fd(fd, &info, &info_len);
+		if (ASSERT_OK(err, "prog_info"))
+			ASSERT_EQ(info.recursion_misses, 1, "recursion_misses");
+	}
+	trampoline_preempt__destroy(skel);
+}
+
+/*
+ * An extension runs under the recursion check of its target. A target that
+ * keeps no per-CPU state is checked per task, so an extension that does keep
+ * such state can't be attached to it.
+ */
+static void run_ext_subtest(void)
+{
+	static const struct {
+		const char *prog;
+		int err;
+	} exts[] = {
+		{ "ext_plain", 0 },		/* no per-CPU state: attaches */
+		{ "ext_percpu", -EINVAL },	/* a per-CPU map lookup: rejected */
+	};
+	struct trampoline_preempt *tgt_skel, *skel = NULL;
+	struct bpf_program *ext, *p;
+	struct bpf_link *link;
+	int i, err, tgt_fd;
+
+	tgt_skel = trampoline_preempt__open();
+	if (!ASSERT_OK_PTR(tgt_skel, "open_tgt"))
+		return;
+	bpf_object__for_each_program(p, tgt_skel->obj)
+		bpf_program__set_autoload(p, p == tgt_skel->progs.ext_target);
+	if (!ASSERT_OK(trampoline_preempt__load(tgt_skel), "load_tgt"))
+		goto out;
+	tgt_fd = bpf_program__fd(tgt_skel->progs.ext_target);
+
+	for (i = 0; i < ARRAY_SIZE(exts); i++) {
+		skel = trampoline_preempt__open();
+		if (!ASSERT_OK_PTR(skel, "open_ext"))
+			goto out;
+		ext = bpf_object__find_program_by_name(skel->obj, exts[i].prog);
+		bpf_object__for_each_program(p, skel->obj)
+			bpf_program__set_autoload(p, p == ext);
+		err = bpf_program__set_attach_target(ext, tgt_fd, "ext_target");
+		if (!ASSERT_OK(err, "set_attach_target"))
+			goto out;
+		if (!ASSERT_OK(trampoline_preempt__load(skel), "load_ext"))
+			goto out;
+
+		link = bpf_program__attach_freplace(ext, tgt_fd, "ext_target");
+		ASSERT_EQ(libbpf_get_error(link), exts[i].err, "attach_ext");
+		bpf_link__destroy(link);
+		trampoline_preempt__destroy(skel);
+		skel = NULL;
+	}
+out:
+	trampoline_preempt__destroy(skel);
+	trampoline_preempt__destroy(tgt_skel);
+}
+
+void test_trampoline_preempt(void)
+{
+	int i;
+
+	for (i = 0; i < ARRAY_SIZE(subtests); i++) {
+		if (test__start_subtest(subtests[i].name))
+			run_subtest(&subtests[i]);
+	}
+	for (i = 0; i < ARRAY_SIZE(recursions); i++) {
+		if (test__start_subtest(recursions[i].name))
+			run_recursion(&recursions[i]);
+	}
+	if (test__start_subtest("ext_attach"))
+		run_ext_subtest();
+}
diff --git a/tools/testing/selftests/bpf/progs/trampoline_preempt.c b/tools/testing/selftests/bpf/progs/trampoline_preempt.c
new file mode 100644
index 000000000000..ce596528c8a5
--- /dev/null
+++ b/tools/testing/selftests/bpf/progs/trampoline_preempt.c
@@ -0,0 +1,258 @@
+// SPDX-License-Identifier: GPL-2.0
+#include "vmlinux.h"
+#include <asm/unistd.h>
+#include <bpf/bpf_helpers.h>
+#include <bpf/bpf_tracing.h>
+#include "bpf_misc.h"
+#include "bpf_compiler.h"
+#include <bpf_may_goto.h>
+
+/* The programs of prog_tests/trampoline_preempt.c. The comment there describes the test. */
+
+char _license[] SEC("license") = "GPL";
+
+struct task_struct *bpf_task_from_pid(s32 pid) __ksym;
+void bpf_task_release(struct task_struct *p) __ksym;
+int bpf_send_signal_task(struct task_struct *task, int sig, enum pid_type type, u64 value) __ksym;
+
+/* The target of the tail calls: empty for tail_call, the handler for two_dispatchers */
+struct {
+	__uint(type, BPF_MAP_TYPE_PROG_ARRAY);
+	__uint(max_entries, 1);
+	__type(key, __u32);
+	__type(value, __u32);
+} prog_array SEC(".maps");
+
+/* recur_two_hops deletes from it, which runs recur_hop */
+struct {
+	__uint(type, BPF_MAP_TYPE_HASH);
+	__uint(max_entries, 1);
+	__type(key, int);
+	__type(value, int);
+} recur_map SEC(".maps");
+
+/* The three kinds of per-CPU state: a map, a variable, and a kernel variable for the helper */
+struct {
+	__uint(type, BPF_MAP_TYPE_PERCPU_ARRAY);
+	__uint(max_entries, 1);
+	__type(key, int);
+	__type(value, __u64);
+} percpu_map SEC(".maps");
+
+__u64 percpu_var SEC(".percpu");
+extern const struct rq runqueues __ksym;
+
+/* The per-CPU state that a program touches. The test picks one before the load. */
+enum { NO_PERCPU, PERCPU_MAP, PERCPU_VAR, THIS_CPU_PTR };
+const volatile int percpu;
+
+/* Set by the test */
+int tid_a, tid_b, sig, recur_tid;
+int loops;	/* 0, read at run time so that the may_goto loop is not optimized away */
+
+/* Read by the test */
+int runs_a, runs_b, sig_err, stack_corrupt, recur_runs, hop_runs;
+int a_inside;	/* A is inside the program: B reads it to see that it preempted A there */
+
+static void signal_worker_b(void)
+{
+	struct task_struct *task = bpf_task_from_pid(tid_b);
+
+	if (!task || bpf_send_signal_task(task, sig, PIDTYPE_PID, 0))
+		sig_err = 1;
+	if (task)
+		bpf_task_release(task);
+}
+
+/*
+ * The body of every program under test: count the run of A or of B. A also
+ * wakes B from here, so B preempts A inside the program and enters it too.
+ */
+static __always_inline int record_run(void)
+{
+	__u32 tid = (__u32)bpf_get_current_pid_tgid();
+	int zero = 0;
+
+	/* The verifier walks only the selected branch, so only that one marks the program */
+	switch (percpu) {
+	case PERCPU_MAP:
+		bpf_map_lookup_elem(&percpu_map, &zero);
+		break;
+	case PERCPU_VAR:
+		percpu_var++;
+		break;
+	case THIS_CPU_PTR:
+		bpf_this_cpu_ptr(&runqueues);
+		break;
+	}
+
+	if (tid == tid_a) {
+		runs_a++;
+		/* volatile: both stores must stay, B reads a_inside between them */
+		*(volatile int *)&a_inside = 1;
+		signal_worker_b();
+		*(volatile int *)&a_inside = 0;
+	} else if (tid == tid_b) {
+		runs_b++;
+	}
+	return 0;
+}
+
+/* Both threads call prctl(PR_SET_NAME), which passes each of the hooks below */
+
+SEC("fentry/__set_task_comm")
+int BPF_PROG(on_fentry)
+{
+	return record_run();
+}
+
+SEC("fentry.s/" SYS_PREFIX "sys_prctl")
+int BPF_PROG(on_fentry_s)
+{
+	return record_run();
+}
+
+SEC("raw_tp/task_rename")
+int BPF_PROG(on_raw_tp)
+{
+	return record_run();
+}
+
+SEC("raw_tp.s/sys_enter")
+int BPF_PROG(on_raw_tp_s, struct pt_regs *regs, long id)
+{
+	return id == __NR_prctl ? record_run() : 0;
+}
+
+SEC("tp/syscalls/sys_enter_prctl")
+int on_tp_syscall(void *ctx)
+{
+	return record_run();
+}
+
+/* The prog array is empty, so the tail call does nothing */
+SEC("raw_tp/task_rename")
+int on_tail_call(void *ctx)
+{
+	bpf_tail_call(ctx, &prog_array, 0);
+	return record_run();
+}
+
+/* can_loop is a may_goto. With timed may_goto its time budget is per CPU. */
+SEC("raw_tp/task_rename")
+int on_may_goto(void *ctx)
+{
+	int i;
+
+	for (i = loops; i < 1 && can_loop; i++)
+		;
+	return record_run();
+}
+
+/* Two dispatchers tail-call one handler: A enters through dispatcher_a, B through dispatcher_b */
+SEC("raw_tp/task_rename")
+int dispatcher_a(void *ctx)
+{
+	if ((__u32)bpf_get_current_pid_tgid() == tid_a)
+		bpf_tail_call(ctx, &prog_array, 0);
+	return 0;
+}
+
+SEC("raw_tp/sys_enter")
+int BPF_PROG(dispatcher_b, struct pt_regs *regs, long id)
+{
+	if (id == __NR_prctl && (__u32)bpf_get_current_pid_tgid() == tid_b)
+		bpf_tail_call(ctx, &prog_array, 0);
+	return 0;
+}
+
+/* The handler keeps 64 bytes of stack across the point where B runs it too */
+SEC("raw_tp")
+int handler(void *ctx)
+{
+	__u32 tid = (__u32)bpf_get_current_pid_tgid();
+	__u64 buf[8];
+
+	__pragma_loop_unroll
+	for (int i = 0; i < 8; i++)
+		buf[i] = ((__u64)tid << 32) | i;
+	/* Make the compiler keep buf on the stack across record_run() */
+	asm volatile("" : "+m"(buf));
+
+	record_run();
+
+	asm volatile("" : "+m"(buf));
+	/* Don't trust a copy of tid that may have been spilled to the stack under test */
+	tid = (__u32)bpf_get_current_pid_tgid();
+	__pragma_loop_unroll
+	for (int i = 0; i < 8; i++) {
+		if (buf[i] != (((__u64)tid << 32) | i))
+			stack_corrupt = 1;
+	}
+	return 0;
+}
+
+/* bpf_printk() fires the bpf_trace_printk tracepoint that the program is attached to */
+SEC("raw_tp/bpf_trace_printk")
+int recur_raw_tp(void *ctx)
+{
+	/* Other tasks print too: only the runs of the test's thread count */
+	if ((__u32)bpf_get_current_pid_tgid() != recur_tid)
+		return 0;
+	recur_runs++;
+	bpf_printk("recur");
+	return 0;
+}
+
+/* The test runs it with BPF_PROG_TEST_RUN to fire the tracepoint once */
+SEC("syscall")
+int recur_trigger(void *ctx)
+{
+	bpf_printk("trigger");
+	return 0;
+}
+
+/* The same through a second program: recur_two_hops -> recur_hop -> recur_two_hops */
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
+	if (map != (struct bpf_map *)&recur_map || (__u32)bpf_get_current_pid_tgid() != recur_tid)
+		return 0;
+	hop_runs++;
+	bpf_printk("hop");
+	return 0;
+}
+
+/* For ext_attach: a target without per-CPU state, and an extension without and with it */
+SEC("raw_tp/task_rename")
+int ext_target(struct bpf_raw_tracepoint_args *ctx)
+{
+	return 0;
+}
+
+SEC("freplace")
+int ext_plain(struct bpf_raw_tracepoint_args *ctx)
+{
+	return 0;
+}
+
+SEC("freplace")
+int ext_percpu(struct bpf_raw_tracepoint_args *ctx)
+{
+	int zero = 0;
+
+	bpf_map_lookup_elem(&percpu_map, &zero);
+	return 0;
+}

-- 
2.43.0

