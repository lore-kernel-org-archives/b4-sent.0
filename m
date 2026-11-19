From: Mike Bazov <mike.bazov@gmail.com>
Date: Thu, 19 Nov 2026 12:37:24 +0200
Subject: [PATCH bpf-next v2] bpf: Use an on-stack pt_regs in the raw
 tracepoint helpers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261119-bpf-raw-tp-regs-preempt-v2-1-e1e1b90857d6@gmail.com>
X-B4-Tracking: v=1; b=H4sIAGPR/moC/4WNQQ6CMBBFr0Jm7RgGI1BX3MOwKO0Akwg0bYMYw
 t2tXMDl+z///R0Ce+EAj2wHz6sEWeYExSUDM+p5YBSbGIq8KImoxM716PUbo0PPQ0DnmScXkfo
 qJ6VqpTsFaZ3yXrbT/ITfaOYtQpuaUUJc/Oe8XOns/9pXQkKbU1daW9+rm2mGScvrapYJ2uM4v
 vBaRBzIAAAA
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795084644; l=7871;
 i=mike.bazov@gmail.com; s=gmail-20261116; h=from:subject:message-id;
 bh=6EzdZ5kXAytUcjASHjJSyHChrRCCQ5aVdBi0WKUNNmo=;
 b=vMA5md7CjaQ3aLL1nyJkX/CdbsbM2YZYb81DrOEviachWJFUb67oHo3Gq+7Olntr3jZO5+BQT
 wEc1LJzi6OTBRw8zF0ZURweTCLE4WvL7DFkOHCIfFdA8+LW06lSI8HY
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

Fill in a pt_regs on the stack of each helper instead, as
bpf_get_stack_raw_tp_sleepable() already does, and remove the slots.
Each caller then has its own registers, however it nests or gets
preempted, and the helpers no longer fail with -EBUSY when nested more
than three deep.

The cost is sizeof(struct pt_regs) of stack per call, 168 bytes on
x86-64, in helpers that can also run in IRQ and NMI context, and
zeroing it on every call. It has to be zeroed: perf_fetch_caller_regs()
sets only a few registers, and a sample with PERF_SAMPLE_REGS_INTR
copies all of them to user space.

Signed-off-by: Mike Bazov <mike.bazov@gmail.com>
---
A reproducer, x86-64: two raw tracepoint programs on sys_enter call
bpf_perf_event_output() once each, with the program's number as data.
Two threads make syscalls on CPU 0, and a SCHED_FIFO thread preempts
them every 20us. The IP of a sample is regs->ip, the return address of
the helper call. The reproducer reads that address for both programs
from their JIT images and checks every sample.

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
Changes in v2:
- Use a pt_regs on the stack of each helper and remove the per-CPU
  slots, instead of disabling preemption while a slot is in use
  (per Andrii's suggestion).
- Link to v1: https://lore.kernel.org/r/20261116-bpf-raw-tp-regs-preempt-v1-1-d01b6dd8573c@gmail.com
---
 kernel/trace/bpf_trace.c | 78 +++++++-----------------------------------------
 1 file changed, 11 insertions(+), 67 deletions(-)

diff --git a/kernel/trace/bpf_trace.c b/kernel/trace/bpf_trace.c
index b4ff9d4e8..3f1901ae6 100644
--- a/kernel/trace/bpf_trace.c
+++ b/kernel/trace/bpf_trace.c
@@ -1624,51 +1624,13 @@ pe_prog_func_proto(enum bpf_func_id func_id, const struct bpf_prog *prog)
 	}
 }
 
-/*
- * bpf_raw_tp_regs are separate from bpf_pt_regs used from skb/xdp
- * to avoid potential recursive reuse issue when/if tracepoints are added
- * inside bpf_*_event_output, bpf_get_stackid and/or bpf_get_stack.
- *
- * Since raw tracepoints run despite bpf_prog_active, support concurrent usage
- * in normal, irq, and nmi context.
- */
-struct bpf_raw_tp_regs {
-	struct pt_regs regs[3];
-};
-static DEFINE_PER_CPU(struct bpf_raw_tp_regs, bpf_raw_tp_regs);
-static DEFINE_PER_CPU(int, bpf_raw_tp_nest_level);
-static struct pt_regs *get_bpf_raw_tp_regs(void)
-{
-	struct bpf_raw_tp_regs *tp_regs = this_cpu_ptr(&bpf_raw_tp_regs);
-	int nest_level = this_cpu_inc_return(bpf_raw_tp_nest_level);
-
-	if (nest_level > ARRAY_SIZE(tp_regs->regs)) {
-		this_cpu_dec(bpf_raw_tp_nest_level);
-		return ERR_PTR(-EBUSY);
-	}
-
-	return &tp_regs->regs[nest_level - 1];
-}
-
-static void put_bpf_raw_tp_regs(void)
-{
-	this_cpu_dec(bpf_raw_tp_nest_level);
-}
-
 BPF_CALL_5(bpf_perf_event_output_raw_tp, struct bpf_raw_tracepoint_args *, args,
 	   struct bpf_map *, map, u64, flags, void *, data, u64, size)
 {
-	struct pt_regs *regs = get_bpf_raw_tp_regs();
-	int ret;
-
-	if (IS_ERR(regs))
-		return PTR_ERR(regs);
-
-	perf_fetch_caller_regs(regs);
-	ret = ____bpf_perf_event_output(regs, map, flags, data, size);
+	struct pt_regs regs = {};
 
-	put_bpf_raw_tp_regs();
-	return ret;
+	perf_fetch_caller_regs(&regs);
+	return ____bpf_perf_event_output(&regs, map, flags, data, size);
 }
 
 static const struct bpf_func_proto bpf_perf_event_output_proto_raw_tp = {
@@ -1689,18 +1651,12 @@ extern const struct bpf_func_proto bpf_xdp_get_buff_len_trace_proto;
 BPF_CALL_3(bpf_get_stackid_raw_tp, struct bpf_raw_tracepoint_args *, args,
 	   struct bpf_map *, map, u64, flags)
 {
-	struct pt_regs *regs = get_bpf_raw_tp_regs();
-	int ret;
-
-	if (IS_ERR(regs))
-		return PTR_ERR(regs);
+	struct pt_regs regs = {};
 
-	perf_fetch_caller_regs(regs);
+	perf_fetch_caller_regs(&regs);
 	/* similar to bpf_perf_event_output_tp, but pt_regs fetched differently */
-	ret = bpf_get_stackid((unsigned long) regs, (unsigned long) map,
-			      flags, 0, 0);
-	put_bpf_raw_tp_regs();
-	return ret;
+	return bpf_get_stackid((unsigned long) &regs, (unsigned long) map,
+			       flags, 0, 0);
 }
 
 static const struct bpf_func_proto bpf_get_stackid_proto_raw_tp = {
@@ -1715,17 +1671,11 @@ static const struct bpf_func_proto bpf_get_stackid_proto_raw_tp = {
 BPF_CALL_4(bpf_get_stack_raw_tp, struct bpf_raw_tracepoint_args *, args,
 	   void *, buf, u32, size, u64, flags)
 {
-	struct pt_regs *regs = get_bpf_raw_tp_regs();
-	int ret;
-
-	if (IS_ERR(regs))
-		return PTR_ERR(regs);
+	struct pt_regs regs = {};
 
-	perf_fetch_caller_regs(regs);
-	ret = bpf_get_stack((unsigned long) regs, (unsigned long) buf,
-			    (unsigned long) size, flags, 0);
-	put_bpf_raw_tp_regs();
-	return ret;
+	perf_fetch_caller_regs(&regs);
+	return bpf_get_stack((unsigned long) &regs, (unsigned long) buf,
+			     (unsigned long) size, flags, 0);
 }
 
 static const struct bpf_func_proto bpf_get_stack_proto_raw_tp = {
@@ -1741,12 +1691,6 @@ static const struct bpf_func_proto bpf_get_stack_proto_raw_tp = {
 BPF_CALL_4(bpf_get_stack_raw_tp_sleepable, struct bpf_raw_tracepoint_args *, args,
 	   void *, buf, u32, size, u64, flags)
 {
-	/*
-	 * Don't take a per-CPU bpf_raw_tp_regs slot here: those slots are a
-	 * LIFO nest counter and are vulnerable to slot overwrite and
-	 * corruption across sleep.  Sleepable programs never run in
-	 * IRQ/NMI context, so a local pt_regs is sufficient.
-	 */
 	struct pt_regs regs = {};
 
 	perf_fetch_caller_regs(&regs);

---
base-commit: 8835113107b2cf75df33a71e265cdeec5d5d13e0
change-id: 20261116-bpf-raw-tp-regs-preempt-1f7019989ab9

Best regards,
-- 
Mike Bazov <mike.bazov@gmail.com>

