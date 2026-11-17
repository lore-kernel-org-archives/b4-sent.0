From: Mike Bazov <mikeba@sentinelone.com>
Date: Tue, 17 Nov 2026 13:29:15 +0200
Subject: [PATCH bpf-next v3 2/4] bpf: Mark programs whose runs must not
 overlap on a CPU
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261117-bpf-preempt-v2-r2-v3-2-586376ec3672@sentinelone.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794914965; l=5254;
 i=mikeba@sentinelone.com; s=20261022; h=from:subject:message-id;
 bh=sZKv3nEdFS7U9tT9jquxnUBbxZnVHMpe/RJEhWApfKw=;
 b=FFpHt5swdYxbQvf402P6T1LVGHeaBsGagHwsdWzmWqlRnHoE631Ij1uo0xTB2E0LZLYAyEZYN
 IC3/LR/gOpHCa4ErghooNEnwlFHauXSc1E1ahTC5m0C21W9+/O3FGQH
X-Developer-Key: i=mikeba@sentinelone.com; a=ed25519;
 pk=DBXcQ0qoCkgacRsRwT1JU7oOWpWSYuTyLiXMfNLcP+A=
X-Endpoint-Received: by B4 Relay for mikeba@sentinelone.com/20261022 with auth_id=1284
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The per-CPU recursion counter of tracing and raw tracepoint programs
also keeps a second task out of a program while another task is
preempted inside it on the same CPU. Programs rely on that:

- A per-CPU map value that a program looked up stays its own until the
  run ends, which is how programs use these maps as scratch space.
- The budget of timed may_goto is per-CPU memory that the first insns
  of a run reset, see commit ec274bb4665c ("bpf: One may_goto time
  slice per prog invocation"). A second run on the CPU gives the first
  one more time.
- A private stack is per CPU. After the previous patch, struct_ops
  programs that request one are the only programs with this check that
  still have it.

The next patch checks recursion per task, which lets a second task in.
For these programs that would turn a counted, dropped run into silently
corrupted data, or into a may_goto loop that another task keeps
renewing. Mark them at load time, so that they keep the per-CPU counter.

Set prog->recur_per_cpu when the verifier sees:

- a helper called with a per-CPU map, also through an inner map,
- the address of a per-CPU array value loaded directly,
- bpf_this_cpu_ptr() or bpf_per_cpu_ptr(),
- a tail call: the target runs without its own recursion check,
- timed may_goto,
- a private stack, in a struct_ops program that requests one.

Only verified code counts: a per-CPU map referenced in a branch that a
constant in .rodata disables doesn't mark the program.

No functional change: nothing reads the flag yet.

Trade-offs, once the next patch reads it:

- A program that keeps per-CPU slots of its own, e.g. in a regular
  array indexed by bpf_get_smp_processor_id(), is not marked.
- Marked programs keep losing runs to preemption.

Signed-off-by: Mike Bazov <mikeba@sentinelone.com>
---
 include/linux/bpf.h   |  3 ++-
 kernel/bpf/fixups.c   |  1 +
 kernel/bpf/verifier.c | 11 +++++++++++
 3 files changed, 14 insertions(+), 1 deletion(-)

diff --git a/include/linux/bpf.h b/include/linux/bpf.h
index a5ad08b7937c..7873f0ef2817 100644
--- a/include/linux/bpf.h
+++ b/include/linux/bpf.h
@@ -2063,7 +2063,8 @@ struct bpf_prog {
 				call_get_func_ip:1, /* Do we call get_func_ip() */
 				call_session_cookie:1, /* Do we call bpf_session_cookie() */
 				tstamp_type_access:1, /* Accessed __sk_buff->tstamp_type */
-				sleepable:1;	/* BPF program is sleepable */
+				sleepable:1,	/* BPF program is sleepable */
+				recur_per_cpu:1; /* Runs must not overlap on a CPU */
 	enum bpf_prog_type	type;		/* Type of BPF program */
 	enum bpf_attach_type	expected_attach_type; /* For some prog types */
 	u32			len;		/* Number of filter blocks */
diff --git a/kernel/bpf/fixups.c b/kernel/bpf/fixups.c
index 4d9b67981520..82ad0d3bf465 100644
--- a/kernel/bpf/fixups.c
+++ b/kernel/bpf/fixups.c
@@ -2591,6 +2591,7 @@ int bpf_do_misc_fixups(struct bpf_verifier_env *env)
 				if (!tmg)
 					return -ENOMEM;
 				prog->aux->timed_may_goto = tmg;
+				prog->recur_per_cpu = true;
 			}
 			prog->jit_required = 1;
 			cnt = may_goto_expand_timed(insn_buf, &jmp, tmg, reg, save_off);
diff --git a/kernel/bpf/verifier.c b/kernel/bpf/verifier.c
index 2ca1469d8dee..3d54520df3e3 100644
--- a/kernel/bpf/verifier.c
+++ b/kernel/bpf/verifier.c
@@ -6050,6 +6050,7 @@ static int check_max_stack_depth(struct bpf_verifier_env *env)
 		if (round_up_stack_depth(env, si[s].stack_depth) >= BPF_PRIV_STACK_MIN_SIZE) {
 			si[s].priv_stack_mode = PRIV_STACK_ADAPTIVE;
 			env->prog->aux->jits_use_priv_stack = true;
+			env->prog->recur_per_cpu = true;
 		}
 	}
 
@@ -12916,6 +12917,10 @@ static int check_helper_call(struct bpf_verifier_env *env, struct bpf_insn *insn
 	if (err)
 		return err;
 
+	/* A per-CPU value stays the run's own only while no other run starts on the CPU */
+	if (meta.map.ptr && bpf_map_is_percpu_map(meta.map.ptr->map_type))
+		env->prog->recur_per_cpu = true;
+
 	err = record_func_map(env, &meta, func_id, insn_idx);
 	if (err)
 		return err;
@@ -12942,6 +12947,8 @@ static int check_helper_call(struct bpf_verifier_env *env, struct bpf_insn *insn
 
 	switch (func_id) {
 	case BPF_FUNC_tail_call:
+		/* The target runs without a recursion check of its own */
+		env->prog->recur_per_cpu = true;
 		err = check_resource_leak(env, false, true, "tail_call");
 		if (err)
 			return err;
@@ -13048,6 +13055,8 @@ static int check_helper_call(struct bpf_verifier_env *env, struct bpf_insn *insn
 		struct bpf_reg_state *reg = &regs[BPF_REG_1];
 		const struct btf_type *type;
 
+		env->prog->recur_per_cpu = true;
+
 		if (reg->type & MEM_RCU) {
 			type = btf_type_by_id(reg->btf, reg->btf_id);
 			if (!type || !btf_type_is_struct(type)) {
@@ -19690,6 +19699,8 @@ static int check_ld_imm(struct bpf_verifier_env *env, struct bpf_insn *insn)
 		__mark_reg_known(dst_reg, aux->map_off);
 		dst_reg->type = PTR_TO_MAP_VALUE;
 		dst_reg->map_ptr = map;
+		if (bpf_map_is_percpu_map(map->map_type))
+			env->prog->recur_per_cpu = true;
 		WARN_ON_ONCE(map->map_type != BPF_MAP_TYPE_INSN_ARRAY &&
 			     map->max_entries != 1);
 		/* We want reg->id to be same (0) as map_value is not distinct */

-- 
2.43.0

