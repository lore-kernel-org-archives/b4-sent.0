From: Mike Bazov <mike.bazov@gmail.com>
Subject: [PATCH bpf-next v3 0/3] bpf: Use an on-stack pt_regs in the raw
 tracepoint helpers
Date: Fri, 20 Nov 2026 12:59:10 +0200
Message-Id: <20261120-bpf-raw-tp-regs-preempt-v3-0-ec109009a5d2@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAP8nAGsC/4XNQQ6CMBAF0KuQWTuGKRGoK+9hXBQ6QBOBpm0qh
 nB3Kys2xuWfn/9mBc/OsIdrtoLjaLyZpxSKUwbtoKae0eiUQeSiJKISG9uhUy8MFh33Hq1jHm1
 A6qqcpKylaiSkdbp3ZtnlO3xHEy8BHqkZjA+ze+8vI+39Xz0SEuqcmlLr+lIV7a0flXme23ncz
 SiOjvztiOQwMTUyT44uj862bR/iVWwyEAEAAA==
To: Song Liu <song@kernel.org>, Jiri Olsa <jolsa@kernel.org>, 
 Ihor Solodrai <ihor.solodrai@linux.dev>, 
 Alexei Starovoitov <ast@kernel.org>, Daniel Borkmann <daniel@iogearbox.net>, 
 Andrii Nakryiko <andrii@kernel.org>, Eduard Zingerman <eddyz87@gmail.com>, 
 Kumar Kartikeya Dwivedi <memxor@gmail.com>, 
 Martin KaFai Lau <martin.lau@linux.dev>, 
 Yonghong Song <yonghong.song@linux.dev>, 
 Emil Tsalapatis <emil@etsalapatis.com>, KP Singh <kpsingh@kernel.org>, 
 Matt Bobrowski <matt@bobrowski.net>, Steven Rostedt <rostedt@goodmis.org>, 
 Masami Hiramatsu <mhiramat@kernel.org>, 
 Mathieu Desnoyers <mathieu.desnoyers@efficios.com>
Cc: bpf@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-trace-kernel@vger.kernel.org, Mike Bazov <mike.bazov@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795172363; l=4481;
 i=mike.bazov@gmail.com; s=gmail-20261116; h=from:subject:message-id;
 bh=4aGQ30fVGQcDktz+c2aNUCUwsz1tlkmURfv5+dT5M+Q=;
 b=Br8yFWWxoQSuqlWMGIXaNofyvpYJBZw/pOHE4k/eXeU9vSibz9Je439VzXK+bUFun4kq4wd3B
 uwmLjp4+fnAAwiorDfpWyDqkMjypn0a3NRNE4spCWtXCt3+lzo0sbyU
X-Developer-Key: i=mike.bazov@gmail.com; a=ed25519;
 pk=Rr9fagn0pNA+bs8tgc6DXZpRAhl/maU6BeqkttIR7DA=
X-Endpoint-Received: by B4 Relay for mike.bazov@gmail.com/gmail-20261116 with auth_id=1544
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

bpf_perf_event_output(), bpf_get_stackid() and bpf_get_stack() of raw
tracepoint and tracing programs share three per-CPU pt_regs slots,
picked by a nest counter. These programs can be preempted, and tasks
then leave the slots out of order, so a sample or stack trace of one
task gets the registers of another. Patch 3 fills in a pt_regs on the
stack of each helper instead and removes the slots.

The slots also limited how deep these helpers nest. Two things need a
limit of their own without them, and both can already be hit today
without raw tracepoint programs:

- bpf_perf_event_output() WARNs when entered a fourth time on a CPU.

- Build ID collection in bpf_get_stack()/bpf_get_stackid() and
  bpf_find_vma() take mmap_read_trylock(), which fires the mmap_lock
  tracepoints. Programs on them that call these helpers nest into each
  other as deep as there are programs. Patch 2 limits it to three
  levels.

Results on bpf-next 0fb18ce8a2e9, x86-64, debug config, CONFIG_PREEMPT=y,
preempt=full. "base" is that tree, "v2" adds only patch 3, "v3" all
three.

The slot race, 5 runs of 10s each. Two raw tracepoint programs on
sys_enter call the helper, two threads make syscalls on CPU 0 and a
SCHED_FIFO thread preempts them every 20us. For bpf_perf_event_output()
the reproducer reads the return address of each program's helper call
from its JIT image and checks the IP of every sample; bpf_get_stack()
and bpf_get_stackid() get an empty kernel stack instead, because the
unwinder looks for the other task's sp on the current stack:

                                     base        v3
  bpf_perf_event_output, wrong IP    7-18        0      per program
  bpf_get_stack, empty stacks        362-535     0
  bpf_get_stackid, empty stacks      168-364     0

The bpf_get_stackid() case with bpftrace, whose kstack calls it; @a[]
and @b[] count the empty stacks:

  bpftrace -e '
  rawtracepoint:sys_enter /comm == "dd"/ { @a[kstack(1)] = count(); }
  rawtracepoint:sys_enter /comm == "dd"/ { @b[kstack(1)] = count(); }' &
  taskset -c 0 dd if=/dev/zero of=/dev/null bs=1 &
  taskset -c 0 dd if=/dev/zero of=/dev/null bs=1 &
  taskset -c 0 chrt -f 1 perl -e 'select(undef, undef, undef, 2e-5) while 1' &

Nesting. For the WARN, a raw tracepoint or kprobe program calls
bpf_perf_event_output(), and three fentry programs on
perf_event_output() call it too. For mmap_read_trylock(), six programs
on mmap_lock_acquire_returned call bpf_get_stack() with build IDs, or
bpf_find_vma(), while the process does 1000 mmap()/munmap():

                                         base     v2       v3
  WARN, started from raw tracepoint      no       yes      no
  WARN, started from kprobe              yes      -        no
  bpf_get_stack, build IDs: depth        4        6        4
                            calls        1.5M     5.9M     1.5M
  bpf_find_vma: depth                    6        6        4
                calls                    5.9M     5.9M     1.5M

Depth counts the programs on the stack; at 4, the last one gets -EBUSY
or the fallback to IPs. The kprobe case wasn't run on v2, which doesn't
change that path.

---
Changes in v3:
- New patch 1: don't WARN when bpf_perf_event_output() nests too deep
  (reported by the BPF CI bot).
- New patch 2: limit nesting of mmap_read_trylock() in BPF helpers
  (per Alexei's suggestion).
- Patch 3: correct the commit message, bpf_perf_event_output() keeps
  its own nesting limit.
- Link to v2: https://lore.kernel.org/r/20261119-bpf-raw-tp-regs-preempt-v2-1-e1e1b90857d6@gmail.com

Changes in v2:
- Use a pt_regs on the stack of each helper and remove the per-CPU
  slots, instead of disabling preemption while a slot is in use
  (per Andrii's suggestion).
- Link to v1: https://lore.kernel.org/r/20261116-bpf-raw-tp-regs-preempt-v1-1-d01b6dd8573c@gmail.com

---
Mike Bazov (3):
      bpf: Don't WARN when bpf_perf_event_output() nests too deep
      bpf: Limit nesting of mmap_read_trylock() in BPF helpers
      bpf: Use an on-stack pt_regs in the raw tracepoint helpers

 kernel/bpf/mmap_unlock_work.h | 16 +++++++--
 kernel/trace/bpf_trace.c      | 80 +++++++------------------------------------
 2 files changed, 26 insertions(+), 70 deletions(-)
---
base-commit: 8835113107b2cf75df33a71e265cdeec5d5d13e0
change-id: 20261116-bpf-raw-tp-regs-preempt-1f7019989ab9

Best regards,
-- 
Mike Bazov <mike.bazov@gmail.com>

