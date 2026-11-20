From: Mike Bazov <mike.bazov@gmail.com>
Date: Fri, 20 Nov 2026 12:59:13 +0200
Subject: [PATCH bpf-next v3 3/3] bpf: Use an on-stack pt_regs in the raw
 tracepoint helpers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261120-bpf-raw-tp-regs-preempt-v3-3-ec109009a5d2@gmail.com>
References: <20261120-bpf-raw-tp-regs-preempt-v3-0-ec109009a5d2@gmail.com>
In-Reply-To: <20261120-bpf-raw-tp-regs-preempt-v3-0-ec109009a5d2@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795172363; l=6051;
 i=mike.bazov@gmail.com; s=gmail-20261116; h=from:subject:message-id;
 bh=s7MEhvtT+6ohAuicBJNZB/8ny74bXSZ+o4bia4zLuL0=;
 b=kUpdylDYVXs/VsBmjVcUGoS6H969ZbM/RU63nlC+8Ys7uei9+pAIfC63a/g3trISmRLMxJSwq
 ll2ST46/idUAQnOxHfIXgXpJ4+NGOGZKcQxebA5+pP6HMXBBduVZQtZ
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
preempted. This also removes the three-level nesting limit the slots put
on the three helpers. bpf_perf_event_output() keeps its own limit, and
the mmap_read_trylock() for build IDs has a separate one.

The cost is sizeof(struct pt_regs) of stack per call, 168 bytes on
x86-64, in helpers that can also run in IRQ and NMI context, and
zeroing it on every call. It has to be zeroed: perf_fetch_caller_regs()
sets only a few registers, and a sample with PERF_SAMPLE_REGS_INTR
copies all of them to user space.

Signed-off-by: Mike Bazov <mike.bazov@gmail.com>
---
 kernel/trace/bpf_trace.c | 78 +++++++-----------------------------------------
 1 file changed, 11 insertions(+), 67 deletions(-)

diff --git a/kernel/trace/bpf_trace.c b/kernel/trace/bpf_trace.c
index 8910d5d05..5c49c139d 100644
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

-- 
2.43.0

