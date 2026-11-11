From: Mike Bazov <mikeba@sentinelone.com>
Subject: [PATCH bpf-next v2 0/5] bpf: Check recursion per task for
 preemptible programs
Date: Wed, 11 Nov 2026 21:39:46 +0200
Message-Id: <20261111-bpf-preempt-v2-r2-v2-0-9d8f6b952ad2@sentinelone.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAILE9GoC/x2MwQqEMAxEf0VyNqBhXXB/RTy0NtUctltSEUH8d
 9Od28ybmQsKq3CBT3OB8iFFfskMtQ0sm0srowTzQB29exP6HDEr8zfveBAqYRzj6LrgwxBeYDu
 jUc7/5wS1nvjcYTbiXWH06tKy1U+b1wTu+wEeWWynhwAAAA==
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794425986; l=7090;
 i=mikeba@sentinelone.com; s=20261022; h=from:subject:message-id;
 bh=LnQxenO2766xlJbzVCrrwOOFPUjVzlBWWREwY5b6Gkw=;
 b=Dn6g7Cnpd+M2gnaHODrGbsuqgZ2AsyoQ16gWyQpXx1aDsAJSq9CUqKtv2Xji2GAVNBv+T7v2u
 sDmRS2JTvCpCbHDMPiTLMnfiNzstDSRPy7rlzn7vPlCL9ozZ1XzP+MK
X-Developer-Key: i=mikeba@sentinelone.com; a=ed25519;
 pk=DBXcQ0qoCkgacRsRwT1JU7oOWpWSYuTyLiXMfNLcP+A=
X-Endpoint-Received: by B4 Relay for mikeba@sentinelone.com/20261022 with auth_id=1284
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Tracing programs run preemptibly: trampoline programs only disable
migration, tracepoint probes run under SRCU-fast, and syscall tracepoint
and sleepable programs can fault. Their recursion check is a per-CPU
counter:

  CPU N
  -----
  task A enters prog -> prog->active on CPU N becomes 1
  task A is preempted inside prog
  task B enters prog on CPU N -> prog->active is already raised:
    the run is dropped and counted as a recursion miss
  task A resumes and finishes -> prog->active drops to 0

Nothing recursed, but task B's event is lost. Before 7.0 this was mostly
hidden, because distribution kernels used PREEMPT_VOLUNTARY. Commit
7dadeaa6e851 ("sched: Further restrict the preemption modes") left only
lazy and full preemption on x86 and arm64, so 7.0+ distribution kernels
drop such events in normal operation. Programs can't work around it: the
counter is checked before their first instruction.

In a production security agent with paired fentry/fexit programs on
inet_sendmsg() and inet_recvmsg(), a dropped half breaks the entry/exit
pairing and desynchronizes stateful protocol parsing. On a stock 7.0
kernel, 4,063 of 38.0M runs were dropped under 10 minutes of HTTP load.
v1 has the detailed analysis and a standalone reproducer.

This series checks recursion per task instead. Each run already links a
run context into the task's chain (current->bpf_ctx); the run context
now records the program, and the check walks the task's chain. Real
recursion, including through interrupts and NMIs, which run on top of
the interrupted task's chain, is still rejected; a second task is not.
Programs that keep a private stack keep the per-CPU check.

Patch 1 comes first and stands on its own. A per-CPU private stack is
only safe if a program never runs in two tasks at once on one CPU, and
that already happens on bpf-next today: two raw_tp dispatchers
tail-calling one handler, or one tracepoint program attached to a
syscall and a regular tracepoint, let a second task overwrite the
preempted task's stack. The selftests reproduce both. Patch 1 stops
giving tracing, raw_tp and tracepoint programs a private stack. Without
it, the per-task check would let a dispatcher in while its tail-call
target still uses a per-CPU stack.

  1. bpf: Avoid per-CPU private stack in preemptible tracing progs
  2. bpf: Check program recursion per task via bpf_ctx
  3. bpf: Check recursion per task for programs on syscall tracepoints
  4. selftests/bpf: Add trampoline and raw_tp preemption recursion test
  5. selftests/bpf: Test syscall tracepoint programs under preemption

Behavior changes worth a look:

- On the kernel stack, the frames of a call chain share one stack
  budget, while a private stack checks each frame on its own. Programs
  whose frames only fit separately no longer load, e.g. a raw_tp program
  with two 2000-byte frames: "combined stack size of 2 calls is 4000.
  Too large". Is that acceptable, or would an opt-in private stack, which
  would keep the per-CPU check, be preferred as a follow-up?
- Raw tracepoint programs were the only ones with a private stack that
  BPF_PROG_TEST_RUN runs, so unwinding on a private stack is now checked
  in the generated code only. A run-time test could use bpf_testmod's
  struct_ops that requests a private stack: wanted in this series or as
  a follow-up?
- The same program can now run in two tasks at once on one CPU, so a
  program using a per-CPU map as scratch space can see another run's
  data.
- Timed may_goto keeps its budget per program and CPU, as before: a run
  in another task can renew the budget of a preempted run.

Testing:

x86-64 VM with 4 vCPUs, full preemption, bpf-next 0fb18ce8a2e9 with and
without the series.

- The same test_progs binary on both kernels:

                                            bpf-next    series
  trampoline_preempt, 14 preemption         all fail    all pass
    subtests (20 rounds each, the
    overlap is checked in every round)
  trampoline_preempt, 4 recursion           all pass    all pass
    subtests
  verifier_unwind, may_goto_priv_stack,     pass        pass
    timed_may_goto, test_global_funcs,
    recursion, task_local_storage

  On bpf-next the second task is dropped in every round of every
  preemption subtest, and two_dispatchers and tp_dual also corrupt the
  preempted task's stack.

- HTTP load: nginx -> gunicorn -> Redis on the VM, the production
  fentry/fexit probe (8 programs on inet[6]_{send,recv}msg()), 4
  CPU-bound tasks, and 200,000 requests from wrk on each kernel:

                probe runs    recursion misses
  bpf-next       7,966,760               9,254
  series         7,976,662                   0

Changes in v2:
- v1 kept recursion-checked trampoline programs non-preemptible. As
  discussed on v1, v2 checks recursion per task instead, using the
  bpf_ctx chain, so programs stay preemptible.
- Cover raw_tp/tp_btf, sleepable trampoline programs, BPF_PROG_TEST_RUN
  and syscall tracepoints, not only trampolines.
- New patch 1: no per-CPU private stack for these program types, which
  also fixes two existing stack corruptions.
- New deterministic selftests: every round forces a second task into the
  program while the first is preempted inside it, proves the overlap,
  and checks the preempted task's stack; plus true-recursion tests.

v1: https://lore.kernel.org/bpf/20261025-b4-bpf-trampoline-preempt-v1-0-198dcdc0c6ac@sentinelone.com/

---
Mike Bazov (5):
      bpf: Avoid per-CPU private stack in preemptible tracing progs
      bpf: Check program recursion per task via bpf_ctx
      bpf: Check recursion per task for programs on syscall tracepoints
      selftests/bpf: Add trampoline and raw_tp preemption recursion test
      selftests/bpf: Test syscall tracepoint programs under preemption

 include/linux/bpf.h                                |  54 ++-
 kernel/bpf/trampoline.c                            |  28 +-
 kernel/bpf/verifier.c                              |  43 +-
 kernel/trace/bpf_trace.c                           |  12 +-
 net/bpf/test_run.c                                 |   4 +-
 net/ipv4/bpf_tcp_ops.c                             |   6 +-
 .../selftests/bpf/prog_tests/may_goto_priv_stack.c |   6 +-
 .../selftests/bpf/prog_tests/timed_may_goto.c      |   6 +-
 .../selftests/bpf/prog_tests/trampoline_preempt.c  | 464 +++++++++++++++++++++
 .../selftests/bpf/progs/may_goto_priv_stack.c      |  14 +-
 .../selftests/bpf/progs/test_global_func3.c        |   9 +
 .../selftests/bpf/progs/timed_may_goto_user.c      |  16 +-
 .../selftests/bpf/progs/trampoline_preempt.c       | 302 ++++++++++++++
 .../selftests/bpf/progs/verifier_private_stack.c   |  65 +--
 .../testing/selftests/bpf/progs/verifier_unwind.c  |  33 +-
 15 files changed, 975 insertions(+), 87 deletions(-)
---
base-commit: 0fb18ce8a2e9de830433923cf65838933d615359
change-id: 20261111-bpf-preempt-v2-r2-f9f9a0dbd5d4

Best regards,
-- 
Mike Bazov <mikeba@sentinelone.com>

