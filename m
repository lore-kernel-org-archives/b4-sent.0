From: Yiyang Chen <chenyy23@mails.tsinghua.edu.cn>
Date: Wed, 29 Jul 2026 15:18:28 +0000
Subject: [PATCH bpf v4 2/4] bpf: Preserve pointer state for commuted
 arithmetic
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260729-c3-035-public-bpf-v4-v4-2-8ee297e2346b@mails.tsinghua.edu.cn>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785338329; l=2493;
 i=chenyy23@mails.tsinghua.edu.cn; s=kernel; h=from:subject:message-id;
 bh=XQur2Ha7xVzrdNs8jsFFaIPeEzwoqH2YGARgnVjxXF0=;
 b=PkxU4TzQv9tc7Z5GVBpbuzm28zweJinwkAo1/rrjSr2Wg/+x/bCU6DJ7RPpDtMBeXl92WZ97/
 u/iF6TdrvLyC41l/thi2GguN1lZOrSe6lpqHyrvIo1zJORmCuwzYiT6
X-Developer-Key: i=chenyy23@mails.tsinghua.edu.cn; a=ed25519;
 pk=+Q11PEDVzoU+87KHlIeNWKwv/GiutzE5094ej7opM+s=
X-Endpoint-Received: by B4 Relay for chenyy23@mails.tsinghua.edu.cn/kernel with auth_id=900
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When scalar += pointer is handled in adjust_ptr_min_max_vals(), the
destination register inherits the pointer state from the source pointer.
Copying only selected fields is fragile because pointer provenance is
tracked by several bpf_reg_state fields.

Use the caller's temporary offset register to preserve the scalar operand
while replacing the destination with the full pointer state. This preserves
the frame number for PTR_TO_STACK registers and keeps parent identity
fields consistent.

Fixes: f4d7e40a5b71 ("bpf: introduce function calls (verification)")
Signed-off-by: Yiyang Chen <chenyy23@mails.tsinghua.edu.cn>
Tested-by: Daniel Wade <danjwade95@gmail.com>
Signed-off-by: Eduard Zingerman <eddyz87@gmail.com>
---
 kernel/bpf/verifier.c | 15 ++++++++-------
 1 file changed, 8 insertions(+), 7 deletions(-)

diff --git a/kernel/bpf/verifier.c b/kernel/bpf/verifier.c
index 9792d6622ffd6..cdb61fab84351 100644
--- a/kernel/bpf/verifier.c
+++ b/kernel/bpf/verifier.c
@@ -13743,11 +13743,12 @@ static int adjust_ptr_min_max_vals(struct bpf_verifier_env *env,
 		return -EACCES;
 	}
 
-	/* In case of 'scalar += pointer', dst_reg inherits pointer type and id.
-	 * The id may be overwritten later if we create a new variable offset.
+	/* For 'scalar += pointer', dst_reg inherits the complete pointer
+	 * register state. Individual fields may be adjusted later by pointer
+	 * arithmetic. Callers guarantee that below does not overwrite off_reg.
 	 */
-	dst_reg->type = ptr_reg->type;
-	dst_reg->id = ptr_reg->id;
+	if (dst_reg != ptr_reg)
+		*dst_reg = *ptr_reg;
 
 	if (!check_reg_sane_offset_scalar(env, off_reg, ptr_reg->type) ||
 	    !check_reg_sane_offset_ptr(env, ptr_reg, ptr_reg->type))
@@ -13790,7 +13791,7 @@ static int adjust_ptr_min_max_vals(struct bpf_verifier_env *env,
 		}
 		break;
 	case BPF_SUB:
-		if (dst_reg == off_reg) {
+		if (dst_reg != ptr_reg) {
 			/* scalar -= pointer.  Creates an unknown scalar */
 			verbose(env, "R%d tried to subtract pointer from scalar\n",
 				dst);
@@ -14808,8 +14809,8 @@ static int adjust_reg_min_max_vals(struct bpf_verifier_env *env,
 				err = mark_chain_precision(env, insn->dst_reg);
 				if (err)
 					return err;
-				return adjust_ptr_min_max_vals(env, insn,
-							       src_reg, dst_reg);
+				off_reg = *dst_reg;
+				return adjust_ptr_min_max_vals(env, insn, src_reg, &off_reg);
 			}
 		} else if (ptr_reg) {
 			/* pointer += scalar */

-- 
2.43.0

