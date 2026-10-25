From: Mike Bazov <mikeba@sentinelone.com>
Subject: [PATCH RFC bpf-next 0/2] bpf: Do not let preemption cause false
 recursion drops in trampoline progs
Date: Sun, 25 Oct 2026 13:02:57 +0200
Message-Id: <20261025-b4-bpf-trampoline-preempt-v1-0-198dcdc0c6ac@sentinelone.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAOLh3WoC/x2MQQqDMBQFryJ/3Q8mWE27LfQA3ZYuoj7thxpDE
 oog3t3ocgZmVooIgkj3YqWAv0SZXQZ1Kaj7WjeCpc9MutS1KvWV24pbP3AKdvLzTxzYB2Dyia2
 qVGNuxhr0lPvsB1nO95tez8fhjtRhSfTZth2fjKKzfAAAAA==
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792926242; l=9082;
 i=mikeba@sentinelone.com; s=20261022; h=from:subject:message-id;
 bh=75UQ+QrC7KlIgE8x2+nWzHWRN7CbqCTK/qMOGy0MIe4=;
 b=cXo8/qjYGeZesl4tLjcsQl3LZg5928jT7pT1hgmFq0KIhnr9E2AxbAldDMUGb2Ed5pf/dWNbU
 GZTEHrIgK4eBby7dAKYJJGDzo7T5t1R8bj+AguTregHXRhOvQ2ZZiCr
X-Developer-Key: i=mikeba@sentinelone.com; a=ed25519;
 pk=DBXcQ0qoCkgacRsRwT1JU7oOWpWSYuTyLiXMfNLcP+A=
X-Endpoint-Received: by B4 Relay for mikeba@sentinelone.com/20261022 with auth_id=1284
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Problem
=======

Non-sleepable fentry and fexit BPF programs silently skip invocations
from unrelated tasks whenever the task currently executing the program
on that CPU is preempted. Every skipped invocation is counted in
prog->stats->recursion_misses, even though no recursion occurred.

In __bpf_prog_enter_recur() (kernel/bpf/trampoline.c), the per-CPU
recursion counter prog->active is acquired under
rcu_read_lock_dont_migrate(), which disables CPU migration but leaves
preemption enabled:

  CPU N
  -----
  Task A enters fentry/foo -> prog->active on CPU N becomes 1
  Task A is preempted mid-program on CPU N (prog->active stays 1)
  Task B runs on CPU N, calls foo() -> __bpf_prog_enter_recur()
    bpf_prog_get_recursion_context() sees prog->active == 2 != 1
    increments recursion_misses and returns 0 (skips BPF program)
  Task A resumes on CPU N, finishes, drops prog->active to 0

Before Linux 7.0 this was hidden on most distribution kernels because
they defaulted to PREEMPT_VOLUNTARY, and non-sleepable BPF programs
contain no voluntary preemption points. Commit 7dadeaa6e851 ("sched:
Further restrict the preemption modes") removed PREEMPT_NONE and
PREEMPT_VOLUNTARY on x86 and arm64, leaving only lazy and full
preemption. As a result, every distribution kernel on 7.0+ now preempts
tasks inside non-sleepable fentry/fexit programs during normal operation
and silently drops unrelated tasks' events on the same CPU.

BPF program authors cannot work around this from inside the program:
prog->active is tested by the trampoline before the first BPF
instruction executes, and bpf_preempt_disable() cannot span tail calls.
By contrast, kprobes and classic perf tracepoints run BPF programs with
preemption disabled (trace_call_bpf() asserts cant_sleep(), and commit
16718274ee75 ("tracing: perf: Have perf tracepoint callbacks always
disable preemption") explicitly kept preemption disabled for perf
tracepoint callbacks), so the same BPF logic has different completeness
guarantees depending solely on whether it attaches via fentry/fexit or
kprobe/tracepoint.

Why This Matters in Practice
============================

We hit this in a production security agent that attaches paired
fentry/fexit probes to inet_sendmsg(), inet6_sendmsg(), inet_recvmsg(),
and inet6_recvmsg() to inspect stateful application-layer protocols:

1. Broken entry/exit pairing: the fentry program snapshots the msghdr /
   iov_iter state into per-socket storage and the fexit program consumes
   that snapshot once the call completes with the byte count. Because
   each program has its own prog->active counter, preemption skips one
   half of the pair independently -- either dropping the payload and
   leaving stale per-socket state (when fexit is skipped) or losing the
   capture entirely (when fentry is skipped).
2. Broken stateful protocol parsing: for stateful protocols (HTTP/1.1
   keep-alive/pipelining/chunked framing, HTTP/2 header state, database
   wire protocols, or per-session first-message classification), a
   single skipped sendmsg/recvmsg call desynchronizes the state machine
   for the remainder of the connection.
3. Kprobes are not a drop-in replacement: on hot socket paths fentry is
   ~2x faster than kprobe (40M/s vs 20M/s in trig-fentry vs trig-kprobe),
   and kretprobe relies on a fixed maxactive instance pool that can be
   exhausted on blocking calls like inet_recvmsg().

Minimal Standalone Reproducer (47 lines)
========================================

repro.bpf.c:

  #include <linux/bpf.h>
  #include <bpf/bpf_helpers.h>

  char LICENSE[] SEC("license") = "GPL";
  static int cb(__u32 i, void *ctx) { return 0; }

  SEC("fentry/__set_task_comm")
  int on_fentry(void *ctx) { bpf_loop(1000000, cb, NULL, 0); return 0; }

  SEC("fexit/__set_task_comm")
  int on_fexit(void *ctx) { bpf_loop(1000000, cb, NULL, 0); return 0; }

repro.c:

  #define _GNU_SOURCE
  #include <sched.h>
  #include <stdio.h>
  #include <unistd.h>
  #include <sys/prctl.h>
  #include <sys/wait.h>
  #include <bpf/bpf.h>
  #include <bpf/libbpf.h>
  #include "repro.skel.h"

  int main(void)
  {
      int stats = bpf_enable_stats(BPF_STATS_RUN_TIME);
      struct repro *skel = repro__open_and_load();
      struct bpf_program *p;
      cpu_set_t cpu;

      repro__attach(skel);
      CPU_ZERO(&cpu);
      CPU_SET(sched_getcpu(), &cpu);
      sched_setaffinity(0, sizeof(cpu), &cpu);

      pid_t pid = fork();
      for (int i = 0; i < 100; i++) {
          prctl(PR_SET_NAME, "repro");
          if (!pid) usleep(50);
      }
      if (!pid)
          return 0;
      wait(NULL);

      bpf_object__for_each_program(p, skel->obj) {
          struct bpf_prog_info info = {};
          __u32 len = sizeof(info);

          bpf_prog_get_info_by_fd(bpf_program__fd(p), &info, &len);
          printf("%-9s expected=200 run_cnt=%-4llu recursion_misses=%llu\n",
                 bpf_program__name(p), info.run_cnt, info.recursion_misses);
      }
      repro__destroy(skel);
      close(stats);
  }

Results across 10 runs (2,000 total calls per probe) on the same x86_64
VM, comparing unmodified mainline (a804c5742bff) with this series:

  Kernel & Preemption Mode        fentry skipped       fexit skipped
  -----------------------------   ------------------   ------------------
  6.8.0-55 stock (voluntary)         0 / 1000 ( 0%)       0 / 1000 ( 0%)
  6.8.0-55 stock (full)            254 / 1000 (25%)     263 / 1000 (26%)
  7.3.0 mainline (lazy)            553 / 2000 (28%)     691 / 2000 (35%)
  7.3.0 mainline (full)            694 / 2000 (35%)     713 / 2000 (36%)
  7.3.0 + patch  (lazy)              0 / 2000 ( 0%)       0 / 2000 ( 0%)
  7.3.0 + patch  (full)              0 / 2000 ( 0%)       0 / 2000 ( 0%)

Why This Fix (and Why Not Per-Task Recursion Tracking)
======================================================

Relaxing prog->active to check whether current is the same task would
not be safe on its own:

1. Per-CPU private stack: since commit a76ab5731e32 ("bpf: Find eligible
   subprogs for private stack support"), recursion-checked trampoline
   programs allocate a single per-CPU private stack
   (prog->aux->priv_stack_ptr) and rely on prog->active to guarantee
   that at most one task on a CPU uses that stack at a time. Allowing a
   second task on the same CPU to enter the program while the first task
   is preempted would corrupt the first task's private stack frames.
2. Per-CPU scratch maps: existing fentry/fexit programs rely on the
   same per-CPU non-reentrancy guarantee when building events in
   BPF_MAP_TYPE_PERCPU_ARRAY scratch buffers.

Therefore, Patch 1 disables preemption (preempt_disable_notrace() +
rcu_read_lock()) in __bpf_prog_enter_recur() / __bpf_prog_exit_recur()
when !IS_ENABLED(CONFIG_PREEMPT_RT), matching classic perf tracepoint
and kprobe BPF execution while leaving PREEMPT_RT and sleepable
trampoline programs (__bpf_prog_enter_sleepable_recur) unchanged.

Testing
=======

- A/B reproducer above on mainline 7.3 (lazy and full preemption):
  drops go from 28-36% to 0%.
- True same-task recursion (fentry/htab_map_delete_elem deleting from
  its own map, as in prog_tests/recursion.c): still blocked 10/10 times.
- Debug kernel with CONFIG_DEBUG_ATOMIC_SLEEP=y, CONFIG_DEBUG_PREEMPT=y,
  CONFIG_PROVE_LOCKING=y, and CONFIG_PROVE_RCU=y: zero lockdep, RCU, or
  atomic-sleep warnings across both the reproducer and the full
  test_progs run (debug_locks remains 1).
- Full test_progs A/B comparison on mainline 7.3: zero new failures
  introduced; all fentry/fexit/trampoline/recursion test suites pass.
- Selftests bench trigger throughput (3 x 5s runs, pinned producer):
    trig-fentry:  39.93M/s (base) -> 42.05M/s (patched)
    trig-fexit:   31.98M/s (base) -> 33.54M/s (patched)
- CONFIG_PREEMPT_RT=y kernel (7.3.0-rt): builds cleanly with W=1; booted
  and verified that trampoline_preempt skips via __kconfig while the
  recursion selftest passes.

Question for Discussion
=======================

Is disabling preemption in __bpf_prog_enter_recur() on !PREEMPT_RT the
preferred fix for fentry/fexit, or would you prefer a different
mechanism for reconciling preemptible execution with prog->active and
the per-CPU private stack?

Signed-off-by: Mike Bazov <mikeba@sentinelone.com>
---
Mike Bazov (2):
      bpf: Keep recursion-checked trampoline programs non-preemptible on !PREEMPT_RT
      selftests/bpf: Add trampoline preemption false-recursion test

 kernel/bpf/trampoline.c                            |  17 +-
 .../selftests/bpf/prog_tests/trampoline_preempt.c  | 222 +++++++++++++++++++++
 .../selftests/bpf/progs/trampoline_preempt.c       |  56 ++++++
 3 files changed, 293 insertions(+), 2 deletions(-)
---
base-commit: a804c5742bff224d4cb4d25dd383554d598be32b
change-id: 20261025-b4-bpf-trampoline-preempt-a1417898a8ed

Best regards,
-- 
Mike Bazov <mikeba@sentinelone.com>

