From: Mike Bazov <mikeba@sentinelone.com>
Subject: [PATCH bpf-next v3 0/4] bpf: Check recursion per task for
 preemptible programs
Date: Tue, 17 Nov 2026 13:29:13 +0200
Message-Id: <20261117-bpf-preempt-v2-r2-v3-0-586376ec3672@sentinelone.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAIk6/GoC/32O0Q7CIAxFf2XpszUT3SI++R9mDzCKI3FAgCwzy
 /7dsg+wD01ub89tN8iUHGV4NBskWlx2wbO4nhoYJ+XfhM6wBtGK/sKFOlqMiWiOBReBSaCVVqr
 WaNOZGzDHrnXrkfmCuu5pLTCwo1Um1En5caqZjNdJZSaXS0jf441FHOSfi9xblOZuey07oYx4Z
 vLFefoET+cxzDDs+/4DhLVYndwAAAA=
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794914965; l=5620;
 i=mikeba@sentinelone.com; s=20261022; h=from:subject:message-id;
 bh=iXdF4zhpTBB0WR/Vg7N3hJ/ku8CPAUtTtheOzQmGZ5U=;
 b=hsouugmYGYwbzXIHtNkW6q0V2xs5xgVAaAibt6QOJ98mJDJTcaeke7pugVgjsuF8so8s+y+n8
 4IgbekfqXlbCZsmsxlyz13FeWLFsTv6BtyZHAoordqrqjODlsO96X2g
X-Developer-Key: i=mikeba@sentinelone.com; a=ed25519;
 pk=DBXcQ0qoCkgacRsRwT1JU7oOWpWSYuTyLiXMfNLcP+A=
X-Endpoint-Received: by B4 Relay for mikeba@sentinelone.com/20261022 with auth_id=1284
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

fentry, fexit, raw_tp and syscall tracepoint programs can be preempted
while they run, but their recursion check is a per-CPU counter:

  task A enters prog on CPU 0       prog->active = 1
  task A is preempted inside prog
  task B enters prog on CPU 0       dropped, counted as recursion miss

Nothing recursed, but B's event is lost. Since 7.0, x86 and arm64 have
only lazy and full preemption, so this happens on stock kernels. Our
fentry/fexit probe on inet_sendmsg() and inet_recvmsg() loses 9,254 of
8 million runs under HTTP load on a 4-CPU VM. With the series it loses
none.

The series checks recursion per task instead: a program is recursing
only if the current task is already inside it.

v2 did that for every program, which breaks a program that uses a
per-CPU map as scratch space: the second task overwrites its buffer,
and nothing counts that. So in v3 the verifier marks the programs that
keep per-CPU state, and those keep the per-CPU counter and behave
exactly as today:

  - per-CPU maps, bpf_this_cpu_ptr(), bpf_per_cpu_ptr()
  - tail calls: the target has no recursion check of its own
  - timed may_goto: its budget is per CPU
  - a private stack

Trade-offs:

- Marked programs are not fixed. A program with a per-CPU map or a
  tail call loses runs to preemption as it does today.
- The verifier can't see everything. A program that keeps per-CPU
  slots of its own, like array[bpf_get_smp_processor_id()], is not
  marked. Today the counter keeps its runs apart. With the series two
  runs can write one slot, and nothing counts that.
- raw_tp is about 2% slower in bench, see the table below. fentry and
  fexit are within noise.
- Tracing, raw_tp and tracepoint programs lose the private stack
  (patch 1). It is already unsafe for them: two raw_tp programs that
  tail-call one handler let two tasks share its stack today. A program
  with two 2000-byte frames no longer loads.
- A marked freplace program can't be attached to an unmarked raw_tp or
  tracepoint program: -EINVAL.

One question: the marking is automatic. A flag that the program's
author sets would avoid the second trade-off, but existing programs
would keep losing runs until they are rebuilt. Which do you prefer?

  1. bpf: Avoid per-CPU private stack in preemptible tracing progs
  2. bpf: Mark programs whose runs must not overlap on a CPU
  3. bpf: Check program recursion per task via bpf_ctx
  4. selftests/bpf: Add preemption recursion test for tracing programs

Testing, x86-64 VM with 4 vCPUs:

The selftest pins two tasks to one CPU and makes B enter the program
while A is preempted inside it, 20 rounds per subtest. With the series
all 19 subtests pass. On bpf-next 7 fail: B is dropped in every round
(fentry, fentry_s, raw_tp, raw_tp_s, tp_syscall), A's stack is
overwritten (two_dispatchers), and the freplace attach is not rejected
(ext_attach).

bench -w2 -d12 -a trig-<x>, M/s, median of 10 runs [min-max], lazy
preemption, in boot order, on bpf-next 0fb18ce8a2e9:

               trig-fentry          trig-fexit           trig-rawtp
  bpf-next     41.65 [40.81-42.14]  38.89 [37.58-39.41]  42.62 [41.95-42.80]
  series       42.40 [41.87-43.04]  39.33 [35.24-41.68]  41.31 [40.48-41.74]
  bpf-next #2  41.64 [40.87-41.74]  39.29 [35.18-40.62]  42.05 [41.24-42.35]
  series #2    42.34 [42.12-42.78]  39.87 [39.46-41.38]  41.53 [40.79-41.75]

Changes in v3:

- Programs with per-CPU state keep the per-CPU counter.
- One pair of helpers does the check for all runners; the syscall
  tracepoint patch is folded into patch 3.
- raw_tp: walk the chain before linking the frame, 5-7% -> 2% slower.
- A marked extension can't be attached to an unmarked target.

v2: https://lore.kernel.org/bpf/20261111-bpf-preempt-v2-r2-v2-0-9d8f6b952ad2@sentinelone.com/
v1: https://lore.kernel.org/bpf/20261025-b4-bpf-trampoline-preempt-v1-0-198dcdc0c6ac@sentinelone.com/

---
Mike Bazov (4):
      bpf: Avoid per-CPU private stack in preemptible tracing progs
      bpf: Mark programs whose runs must not overlap on a CPU
      bpf: Check program recursion per task via bpf_ctx
      selftests/bpf: Add preemption recursion test for tracing programs

 include/linux/bpf.h                                |  98 +++++-
 include/linux/bpf_verifier.h                       |  19 ++
 kernel/bpf/fixups.c                                |   1 +
 kernel/bpf/syscall.c                               |  10 +
 kernel/bpf/trampoline.c                            |  26 +-
 kernel/bpf/verifier.c                              |  53 +++-
 kernel/trace/bpf_trace.c                           |  11 +-
 net/bpf/test_run.c                                 |   9 +-
 net/ipv4/bpf_tcp_ops.c                             |   6 +-
 .../selftests/bpf/prog_tests/may_goto_priv_stack.c |   6 +-
 .../selftests/bpf/prog_tests/timed_may_goto.c      |   6 +-
 .../selftests/bpf/prog_tests/trampoline_preempt.c  | 352 +++++++++++++++++++++
 .../selftests/bpf/progs/may_goto_priv_stack.c      |  14 +-
 .../selftests/bpf/progs/test_global_func3.c        |   9 +
 .../selftests/bpf/progs/timed_may_goto_user.c      |  16 +-
 .../selftests/bpf/progs/trampoline_preempt.c       | 258 +++++++++++++++
 .../selftests/bpf/progs/verifier_private_stack.c   |  81 ++---
 .../testing/selftests/bpf/progs/verifier_unwind.c  |  33 +-
 18 files changed, 899 insertions(+), 109 deletions(-)
---
base-commit: 32b66b94c86f009b49668de7340f2ed65aad2dc5
change-id: 20261111-bpf-preempt-v2-r2-f9f9a0dbd5d4

Best regards,
-- 
Mike Bazov <mikeba@sentinelone.com>

