From: Mike Bazov <mikeba@sentinelone.com>
Date: Sun, 25 Oct 2026 13:02:59 +0200
Subject: [PATCH RFC bpf-next 2/2] selftests/bpf: Add trampoline preemption
 false-recursion test
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261025-b4-bpf-trampoline-preempt-v1-2-198dcdc0c6ac@sentinelone.com>
References: <20261025-b4-bpf-trampoline-preempt-v1-0-198dcdc0c6ac@sentinelone.com>
In-Reply-To: <20261025-b4-bpf-trampoline-preempt-v1-0-198dcdc0c6ac@sentinelone.com>
To: Alexei Starovoitov <ast@kernel.org>, 
 Daniel Borkmann <daniel@iogearbox.net>, Andrii Nakryiko <andrii@kernel.org>
Cc: Martin KaFai Lau <martin.lau@linux.dev>, 
 Eduard Zingerman <eddyz87@gmail.com>, 
 Kumar Kartikeya Dwivedi <memxor@gmail.com>, Song Liu <song@kernel.org>, 
 Yonghong Song <yonghong.song@linux.dev>, Jiri Olsa <jolsa@kernel.org>, 
 John Fastabend <john.fastabend@gmail.com>, Shuah Khan <shuah@kernel.org>, 
 bpf@vger.kernel.org, linux-kselftest@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Mike Bazov <mikeba@sentinelone.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792926242; l=8029;
 i=mikeba@sentinelone.com; s=20261022; h=from:subject:message-id;
 bh=qv0fLzMtw1iJpm8k4SDJiXQphyXRMM0DrZS/PJoAunw=;
 b=RJGCMhigpZyYGsDq3lpijLYrb1/nW2ChSLOD6mUqFKehxfygg3vFKt7QHMp7Ul2fYWMTlMkkd
 DIpiqKmARLKB651LOG7+55QfTQTyyMFV2ZCIAl5syW+Eztl06HpuKI6
X-Developer-Key: i=mikeba@sentinelone.com; a=ed25519;
 pk=DBXcQ0qoCkgacRsRwT1JU7oOWpWSYuTyLiXMfNLcP+A=
X-Endpoint-Received: by B4 Relay for mikeba@sentinelone.com/20261022 with auth_id=1284
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Verify that preempting a task while it is executing a non-sleepable
fentry or fexit program on a CPU does not cause a second task on the
same CPU to have its fentry/fexit execution skipped as a false
recursion_miss.

Pin two threads to the same CPU in separate fentry and fexit subtests:
worker_b (SCHED_FIFO) wakes worker_a via a pipe and blocks in
sigtimedwait(); worker_a invokes prctl(PR_SET_NAME) and its fentry/fexit
program sends SIGUSR1 to worker_b via bpf_send_signal_task(). On an
unpatched preemptible kernel, sending the signal wakes worker_b and
immediately preempts worker_a mid-program, causing worker_b's
subsequent prctl(PR_SET_NAME) to be skipped with recursion_misses++.
Assert that all invocations run for both threads with zero
recursion_misses, and skip on PREEMPT_RT or when SCHED_FIFO is
unavailable.

Assisted-by: Devin:gemini-4-argon-high
Signed-off-by: Mike Bazov <mikeba@sentinelone.com>
---
 .../selftests/bpf/prog_tests/trampoline_preempt.c  | 222 +++++++++++++++++++++
 .../selftests/bpf/progs/trampoline_preempt.c       |  56 ++++++
 2 files changed, 278 insertions(+)

diff --git a/tools/testing/selftests/bpf/prog_tests/trampoline_preempt.c b/tools/testing/selftests/bpf/prog_tests/trampoline_preempt.c
new file mode 100644
index 000000000000..ba9d35e3f0af
--- /dev/null
+++ b/tools/testing/selftests/bpf/prog_tests/trampoline_preempt.c
@@ -0,0 +1,222 @@
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
+struct ctx {
+	struct trampoline_preempt *skel;
+	int cpu;
+	int go_pipe[2];
+	int done_pipe[2];
+	sigset_t sigset;
+	int err_a;
+	int err_b;
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
+static void run_subtest(bool is_fexit)
+{
+	struct ctx c = {
+		.go_pipe = { -1, -1 },
+		.done_pipe = { -1, -1 },
+	};
+	struct bpf_prog_info info = {};
+	__u32 info_len = sizeof(info);
+	struct bpf_program *prog;
+	struct bpf_link *link = NULL;
+	sigset_t oldset;
+	pthread_t ta, tb;
+	bool ta_started = false, tb_started = false, sigmask_set = false;
+	char ch;
+	int err;
+
+	c.skel = trampoline_preempt__open_and_load();
+	if (!ASSERT_OK_PTR(c.skel, "open_and_load"))
+		return;
+
+	if (c.skel->kconfig->CONFIG_PREEMPT_RT) {
+		test__skip();
+		goto out;
+	}
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
+	prog = is_fexit ? c.skel->progs.on_fexit : c.skel->progs.on_fentry;
+	link = bpf_program__attach(prog);
+	if (!ASSERT_OK_PTR(link, "attach"))
+		goto out;
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
+	ASSERT_EQ(c.skel->bss->runs_a, NR_ROUNDS, "runs_a");
+	ASSERT_EQ(c.skel->bss->runs_b, NR_ROUNDS, "runs_b");
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
+	trampoline_preempt__destroy(c.skel);
+}
+
+void test_trampoline_preempt(void)
+{
+	if (test__start_subtest("fentry"))
+		run_subtest(false);
+	if (test__start_subtest("fexit"))
+		run_subtest(true);
+}
diff --git a/tools/testing/selftests/bpf/progs/trampoline_preempt.c b/tools/testing/selftests/bpf/progs/trampoline_preempt.c
new file mode 100644
index 000000000000..851037b33d03
--- /dev/null
+++ b/tools/testing/selftests/bpf/progs/trampoline_preempt.c
@@ -0,0 +1,56 @@
+// SPDX-License-Identifier: GPL-2.0
+#include "vmlinux.h"
+#include <bpf/bpf_helpers.h>
+#include <bpf/bpf_tracing.h>
+
+char _license[] SEC("license") = "GPL";
+
+extern bool CONFIG_PREEMPT_RT __kconfig __weak;
+
+struct task_struct *bpf_task_from_pid(s32 pid) __ksym;
+void bpf_task_release(struct task_struct *p) __ksym;
+int bpf_send_signal_task(struct task_struct *task, int sig, enum pid_type type, u64 value) __ksym;
+
+int tid_a;
+int tid_b;
+int sig;
+int runs_a;
+int runs_b;
+int sig_err;
+
+static int handle_comm(void)
+{
+	__u32 tid = (__u32)bpf_get_current_pid_tgid();
+
+	if (CONFIG_PREEMPT_RT)
+		return 0;
+
+	if (tid == tid_a) {
+		struct task_struct *task;
+
+		runs_a++;
+		task = bpf_task_from_pid(tid_b);
+		if (!task) {
+			sig_err = 1;
+			return 0;
+		}
+		if (bpf_send_signal_task(task, sig, PIDTYPE_PID, 0))
+			sig_err = 1;
+		bpf_task_release(task);
+	} else if (tid == tid_b) {
+		runs_b++;
+	}
+	return 0;
+}
+
+SEC("fentry/__set_task_comm")
+int BPF_PROG(on_fentry)
+{
+	return handle_comm();
+}
+
+SEC("fexit/__set_task_comm")
+int BPF_PROG(on_fexit)
+{
+	return handle_comm();
+}

-- 
2.43.0

