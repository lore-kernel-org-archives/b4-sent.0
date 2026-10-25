From: Mike Bazov <mikeba@sentinelone.com>
Date: Sun, 25 Oct 2026 13:02:58 +0200
Subject: [PATCH RFC bpf-next 1/2] bpf: Keep recursion-checked trampoline
 programs non-preemptible on !PREEMPT_RT
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261025-b4-bpf-trampoline-preempt-v1-1-198dcdc0c6ac@sentinelone.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792926242; l=3369;
 i=mikeba@sentinelone.com; s=20261022; h=from:subject:message-id;
 bh=im30M5hxZEzaHqyEhAAnmhe/8ENnb4qNYKDcXtbtVVo=;
 b=GrLfHA1TCeRD1/d8BI/1u+pE6udJo7/utUi8Et3C/aczd72dGCkpJjvj6+21yG6GPVJsVToff
 tgyp5k/12nuBMhR/8xDWMNTdHniBbK+QYY7GABsqk2+s73MsjpXNA9f
X-Developer-Key: i=mikeba@sentinelone.com; a=ed25519;
 pk=DBXcQ0qoCkgacRsRwT1JU7oOWpWSYuTyLiXMfNLcP+A=
X-Endpoint-Received: by B4 Relay for mikeba@sentinelone.com/20261022 with auth_id=1284
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

__bpf_prog_enter_recur() acquires the per-CPU recursion counter
(prog->active) under rcu_read_lock_dont_migrate(), which disables CPU
migration but leaves preemption enabled.

When a task executing a non-sleepable fentry/fexit program on CPU N is
preempted mid-program, prog->active remains 1 on CPU N while the
preempted task is off-CPU. Any unrelated task scheduled onto CPU N that
triggers the same hook observes prog->active != 1 in
bpf_prog_get_recursion_context(), increments recursion_misses, and has
its BPF program invocation silently skipped, even though no recursion
occurred.

Before Linux 7.0 this was mostly masked on distribution kernels that
defaulted to PREEMPT_VOLUNTARY, because non-sleepable BPF programs
contain no voluntary scheduling points. Commit 7dadeaa6e851 ("sched:
Further restrict the preemption modes") removed PREEMPT_NONE and
PREEMPT_VOLUNTARY on x86 and arm64, so every distribution kernel now
runs with lazy or full preemption and triggers these false recursion
drops during normal multi-task execution on the same CPU.

Simply switching prog->active to per-task tracking is not sufficient:
since commit a76ab5731e32 ("bpf: Find eligible subprogs for private
stack support"), recursion-checked trampoline programs also rely on
prog->active to guarantee exclusive ownership of the single per-CPU
private stack (prog->aux->priv_stack_ptr), as well as per-CPU scratch
maps.

Match the guarantee already provided by kprobe and classic perf
tracepoint BPF callbacks (commit 16718274ee75 ("tracing: perf: Have perf
tracepoint callbacks always disable preemption")) by disabling
preemption in __bpf_prog_enter_recur() / __bpf_prog_exit_recur() when
!IS_ENABLED(CONFIG_PREEMPT_RT). This preserves preemptible BPF execution
on PREEMPT_RT while eliminating false recursion drops and protecting
per-CPU private stacks on non-RT kernels.

Fixes: ca06f55b9002 ("bpf: Add per-program recursion prevention mechanism")
Assisted-by: Devin:gemini-4-argon-high
Signed-off-by: Mike Bazov <mikeba@sentinelone.com>
---
 kernel/bpf/trampoline.c | 17 +++++++++++++++--
 1 file changed, 15 insertions(+), 2 deletions(-)

diff --git a/kernel/bpf/trampoline.c b/kernel/bpf/trampoline.c
index bf4cb3dd444d..632c104112b2 100644
--- a/kernel/bpf/trampoline.c
+++ b/kernel/bpf/trampoline.c
@@ -1339,7 +1339,15 @@ static __always_inline u64 notrace bpf_prog_start_time(void)
 static u64 notrace __bpf_prog_enter_recur(struct bpf_prog *prog, struct bpf_tramp_run_ctx *run_ctx)
 	__acquires(RCU)
 {
-	rcu_read_lock_dont_migrate();
+	if (IS_ENABLED(CONFIG_PREEMPT_RT)) {
+		rcu_read_lock_dont_migrate();
+	} else {
+		/* prog->active and the private stack are per-CPU: don't let
+		 * another task run on this CPU while we hold them.
+		 */
+		preempt_disable_notrace();
+		rcu_read_lock();
+	}
 
 	run_ctx->saved_run_ctx = bpf_set_run_ctx(&run_ctx->run_ctx);
 
@@ -1388,7 +1396,12 @@ static void notrace __bpf_prog_exit_recur(struct bpf_prog *prog, u64 start,
 
 	update_prog_stats(prog, start);
 	bpf_prog_put_recursion_context(prog);
-	rcu_read_unlock_migrate();
+	if (IS_ENABLED(CONFIG_PREEMPT_RT)) {
+		rcu_read_unlock_migrate();
+	} else {
+		rcu_read_unlock();
+		preempt_enable_notrace();
+	}
 }
 
 static u64 notrace __bpf_prog_enter_lsm_cgroup(struct bpf_prog *prog,

-- 
2.43.0

