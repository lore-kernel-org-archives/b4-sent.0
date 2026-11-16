From: Mike Bazov <mike.bazov@gmail.com>
Date: Mon, 16 Nov 2026 19:18:18 +0200
Subject: [PATCH bpf-next] bpf: Disable preemption while a raw tracepoint
 regs slot is in use
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261116-bpf-raw-tp-regs-preempt-v1-1-d01b6dd8573c@gmail.com>
X-B4-Tracking: v=1; b=H4sIANk6+2oC/x2MQQqEMAwAvyI5GzAedOtXxEN1UzcHa0mLFsS/2
 /U4AzMXRFbhCEN1gfIhUXZfgOoKlp/1K6N8C0PbtB0RdTgHh2pPTAGV14hBmbeQkFzfkDEfY2c
 DpS7eSX7PI/wjzznBdN8P/zFbfnMAAAA=
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794849502; l=4672;
 i=mike.bazov@gmail.com; s=gmail-20261116; h=from:subject:message-id;
 bh=UzSSLc393SFgDdsvt18pcI0fmb0CrVnIVQAxJGAGphQ=;
 b=GAaY2hAzCna3cUR6yb/ptwCvXlNZZpMOdEud5eOwnnXQGAMSvuhEv67Lifu1O9VSPVnxIgyvp
 K4RpB9ZFgbMBpw2s5+w+zg8VGN24RO/Q9/4brbIap9OuxqdeVa+jz+u
X-Developer-Key: i=mike.bazov@gmail.com; a=ed25519;
 pk=Rr9fagn0pNA+bs8tgc6DXZpRAhl/maU6BeqkttIR7DA=
X-Endpoint-Received: by B4 Relay for mike.bazov@gmail.com/gmail-20261116 with auth_id=1544
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

bpf_perf_event_output(), bpf_get_stackid() and bpf_get_stack() of raw
tracepoint and tracing programs have no pt_regs, so they fill in one of
three per-CPU slots, picked by a per-CPU nest counter:

  get_bpf_raw_tp_regs()   level++, use regs[level - 1]
  put_bpf_raw_tp_regs()   level--

That only works if the users of a CPU leave in the reverse order they
came, as a task, an interrupt and an NMI do. These programs run with
migration disabled but preemption enabled, so tasks can leave in any
order:

  task A              task B              task C
  get: regs[0]
  <preempted>
                      get: regs[1]
                      <preempted>
  put: level 1
                                          get: regs[1]
                                          fills in its regs
                      uses regs[1]

B sends a sample or a stack trace with the registers of C. Profilers and
tracers then attribute it to the wrong task, and nothing reports an
error. The per-CPU recursion counter of a program doesn't prevent it:
the slots are shared by all programs, so it takes two of them.

Disable preemption from get to put, as the two other users of this
scheme do since commit f2c67a3e60d1 ("bpf: Disable preemption in
bpf_perf_event_output") and commit d62cc390c2e9 ("bpf: Disable
preemption in bpf_event_output"). Nothing in between sleeps: the
sleepable bpf_get_stack() of these programs doesn't use the slots.

The cost is small: the helpers already disable preemption around most
of their work, the unwind in bpf_get_stack() and bpf_get_stackid() and
all of bpf_perf_event_output(); this adds the few instructions around
it.

Signed-off-by: Mike Bazov <mike.bazov@gmail.com>
---
A reproducer, x86-64: two raw tracepoint programs on sys_enter call
bpf_perf_event_output() once each, with the program's number as data.
Two threads make syscalls on CPU 0, and a SCHED_FIFO thread preempts
them every 20us. The IP of a sample is regs->ip of the slot, the return
address of the helper call. The reproducer reads that address for both
programs from their JIT images and checks every sample.

Without this patch, 7 to 18 samples per program and 10s run have the IP
of the other program, out of 1.4M. With it, none. bpf_get_stack() and
bpf_get_stackid() in the same setup return an empty kernel stack
instead: the unwinder looks for the other task's sp on the current
stack and doesn't find it.

5 runs of 10s, debug config, CONFIG_PREEMPT=y, preempt=full, on
bpf-next 0fb18ce8a2e9:

                                     without     with
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
---
 kernel/trace/bpf_trace.c | 11 +++++++++--
 1 file changed, 9 insertions(+), 2 deletions(-)

diff --git a/kernel/trace/bpf_trace.c b/kernel/trace/bpf_trace.c
index b4ff9d4e8..eb3daf2bf 100644
--- a/kernel/trace/bpf_trace.c
+++ b/kernel/trace/bpf_trace.c
@@ -1639,11 +1639,17 @@ static DEFINE_PER_CPU(struct bpf_raw_tp_regs, bpf_raw_tp_regs);
 static DEFINE_PER_CPU(int, bpf_raw_tp_nest_level);
 static struct pt_regs *get_bpf_raw_tp_regs(void)
 {
-	struct bpf_raw_tp_regs *tp_regs = this_cpu_ptr(&bpf_raw_tp_regs);
-	int nest_level = this_cpu_inc_return(bpf_raw_tp_nest_level);
+	struct bpf_raw_tp_regs *tp_regs;
+	int nest_level;
+
+	/* The slots nest: a task must not be preempted while it holds one */
+	preempt_disable();
+	tp_regs = this_cpu_ptr(&bpf_raw_tp_regs);
+	nest_level = this_cpu_inc_return(bpf_raw_tp_nest_level);
 
 	if (nest_level > ARRAY_SIZE(tp_regs->regs)) {
 		this_cpu_dec(bpf_raw_tp_nest_level);
+		preempt_enable();
 		return ERR_PTR(-EBUSY);
 	}
 
@@ -1653,6 +1659,7 @@ static struct pt_regs *get_bpf_raw_tp_regs(void)
 static void put_bpf_raw_tp_regs(void)
 {
 	this_cpu_dec(bpf_raw_tp_nest_level);
+	preempt_enable();
 }
 
 BPF_CALL_5(bpf_perf_event_output_raw_tp, struct bpf_raw_tracepoint_args *, args,

---
base-commit: 8835113107b2cf75df33a71e265cdeec5d5d13e0
change-id: 20261116-bpf-raw-tp-regs-preempt-1f7019989ab9

Best regards,
-- 
Mike Bazov <mike.bazov@gmail.com>

