From: Yiyang Chen <chenyy23@mails.tsinghua.edu.cn>
Date: Wed, 29 Jul 2026 15:18:27 +0000
Subject: [PATCH bpf v4 1/4] bpf: simplify sanitize_err() signature
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260729-c3-035-public-bpf-v4-v4-1-8ee297e2346b@mails.tsinghua.edu.cn>
References: <20260729-c3-035-public-bpf-v4-v4-0-8ee297e2346b@mails.tsinghua.edu.cn>
In-Reply-To: <20260729-c3-035-public-bpf-v4-v4-0-8ee297e2346b@mails.tsinghua.edu.cn>
To: Alexei Starovoitov <ast@kernel.org>, 
 Daniel Borkmann <daniel@iogearbox.net>, Andrii Nakryiko <andrii@kernel.org>, 
 Eduard Zingerman <eddyz87@gmail.com>, 
 Kumar Kartikeya Dwivedi <memxor@gmail.com>
Cc: John Fastabend <john.fastabend@gmail.com>, 
 Martin KaFai Lau <martin.lau@linux.dev>, Song Liu <song@kernel.org>, 
 Yonghong Song <yonghong.song@linux.dev>, Jiri Olsa <jolsa@kernel.org>, 
 Shuah Khan <shuah@kernel.org>, Emil Tsalapatis <emil@etsalapatis.com>, 
 Ihor Solodrai <ihor.solodrai@linux.dev>, 
 Shung-Hsi Yu <shung-hsi.yu@suse.com>, Daniel Wade <danjwade95@gmail.com>, 
 bpf@vger.kernel.org, linux-kselftest@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Yiyang Chen <chenyy23@mails.tsinghua.edu.cn>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785338329; l=2912;
 i=chenyy23@mails.tsinghua.edu.cn; s=kernel; h=from:subject:message-id;
 bh=GVQU8AnKSNW9owP8OxZQ3/UbDFKuSBhgGQANm+vY8V8=;
 b=S7JpiM+T54LdGYo0bXqvB5yR6ZU7IPIwWWjaqVy3nUBaysIxF93v/lV2pkm3U881VicJrYfsY
 miMuoOq3h9CDoHWU31m7iWZ1O42d3JMkqh9C7aYR7dnSC2XPQiloH+T
X-Developer-Key: i=chenyy23@mails.tsinghua.edu.cn; a=ed25519;
 pk=+Q11PEDVzoU+87KHlIeNWKwv/GiutzE5094ej7opM+s=
X-Endpoint-Received: by B4 Relay for chenyy23@mails.tsinghua.edu.cn/kernel with auth_id=900
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Eduard Zingerman <eddyz87@gmail.com>

The sanitize_err() function is called when:
- ptr += scalar
- scalar += ptr
- scalar += scalar
ALU operations are processed.

This commit drops offset and pointer registers parameters from its
signature to simplify the follow-up changes for 'scalar += ptr' case.
regs[src].type is safe to access, as it is not mutated by the callers.

Signed-off-by: Eduard Zingerman <eddyz87@gmail.com>
Signed-off-by: Yiyang Chen <chenyy23@mails.tsinghua.edu.cn>
---
 kernel/bpf/verifier.c | 16 +++++++---------
 1 file changed, 7 insertions(+), 9 deletions(-)

diff --git a/kernel/bpf/verifier.c b/kernel/bpf/verifier.c
index 7aa47342dc659..9792d6622ffd6 100644
--- a/kernel/bpf/verifier.c
+++ b/kernel/bpf/verifier.c
@@ -13557,23 +13557,21 @@ static void sanitize_mark_insn_seen(struct bpf_verifier_env *env)
 		env->insn_aux_data[env->insn_idx].seen = env->pass_cnt;
 }
 
-static int sanitize_err(struct bpf_verifier_env *env,
-			const struct bpf_insn *insn, int reason,
-			const struct bpf_reg_state *off_reg,
-			const struct bpf_reg_state *dst_reg)
+static int sanitize_err(struct bpf_verifier_env *env, const struct bpf_insn *insn, int reason)
 {
 	static const char *err = "pointer arithmetic with it prohibited for !root";
 	const char *op = BPF_OP(insn->code) == BPF_ADD ? "add" : "sub";
 	u32 dst = insn->dst_reg, src = insn->src_reg;
+	struct bpf_reg_state *regs = cur_regs(env);
 
 	switch (reason) {
 	case REASON_BOUNDS:
 		verbose(env, "R%d has unknown scalar with mixed signed bounds, %s\n",
-			off_reg == dst_reg ? dst : src, err);
+			regs[src].type == SCALAR_VALUE ? src : dst, err);
 		break;
 	case REASON_TYPE:
 		verbose(env, "R%d has pointer with unsupported alu operation, %s\n",
-			off_reg == dst_reg ? src : dst, err);
+			regs[src].type == SCALAR_VALUE ? dst : src, err);
 		break;
 	case REASON_PATHS:
 		verbose(env, "R%d tried to %s from different maps, paths or scalars, %s\n",
@@ -13762,7 +13760,7 @@ static int adjust_ptr_min_max_vals(struct bpf_verifier_env *env,
 		ret = sanitize_ptr_alu(env, insn, ptr_reg, off_reg, dst_reg,
 				       &info, false);
 		if (ret < 0)
-			return sanitize_err(env, insn, ret, off_reg, dst_reg);
+			return sanitize_err(env, insn, ret);
 	}
 
 	switch (opcode) {
@@ -13855,7 +13853,7 @@ static int adjust_ptr_min_max_vals(struct bpf_verifier_env *env,
 			return -EFAULT;
 		}
 		if (ret < 0)
-			return sanitize_err(env, insn, ret, off_reg, dst_reg);
+			return sanitize_err(env, insn, ret);
 	}
 
 	return 0;
@@ -14607,7 +14605,7 @@ static int adjust_scalar_min_max_vals(struct bpf_verifier_env *env,
 	if (sanitize_needed(opcode)) {
 		ret = sanitize_val_alu(env, insn);
 		if (ret < 0)
-			return sanitize_err(env, insn, ret, NULL, NULL);
+			return sanitize_err(env, insn, ret);
 	}
 
 	/* Calculate sign/unsigned bounds and tnum for alu32 and alu64 bit ops.

-- 
2.43.0

