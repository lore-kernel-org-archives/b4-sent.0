From: Yiyang Chen <chenyy23@mails.tsinghua.edu.cn>
Date: Wed, 29 Jul 2026 15:18:29 +0000
Subject: [PATCH bpf v4 3/4] bpf: Propagate untrusted pointer state in
 commuted arithmetic
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260729-c3-035-public-bpf-v4-v4-3-8ee297e2346b@mails.tsinghua.edu.cn>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785338329; l=1686;
 i=chenyy23@mails.tsinghua.edu.cn; s=kernel; h=from:subject:message-id;
 bh=yHtvihk7t702xySyUdiUvbGV+eWJSYwJqVOt//qmgOo=;
 b=HhStsKrRvBd7Pihhg2P46Wa2u4MhI0EMthAi+rZJtSSRuhCycAkueJtXIHx6+vU3r4LLJPfj4
 9dVefgXLeklCHi/dBFXh2XV7VSlgHhQhvoSPUS/hFV0+0X6Pp7sxbkt
X-Developer-Key: i=chenyy23@mails.tsinghua.edu.cn; a=ed25519;
 pk=+Q11PEDVzoU+87KHlIeNWKwv/GiutzE5094ej7opM+s=
X-Endpoint-Received: by B4 Relay for chenyy23@mails.tsinghua.edu.cn/kernel with auth_id=900
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The untrusted PTR_TO_MEM early return skips pointer offset tracking
because accesses go through probe-read handling. Moving it after full
pointer-state propagation ensures scalar += untrusted_pointer leaves the
destination as PTR_TO_MEM instead of an unrelated scalar.

Fixes: f2362a57aeff ("bpf: allow void* cast using bpf_rdonly_cast()")
Tested-by: Daniel Wade <danjwade95@gmail.com>
Signed-off-by: Yiyang Chen <chenyy23@mails.tsinghua.edu.cn>
---
 kernel/bpf/verifier.c | 14 +++++++-------
 1 file changed, 7 insertions(+), 7 deletions(-)

diff --git a/kernel/bpf/verifier.c b/kernel/bpf/verifier.c
index cdb61fab84351..fdc5fbb1f78ca 100644
--- a/kernel/bpf/verifier.c
+++ b/kernel/bpf/verifier.c
@@ -13707,13 +13707,6 @@ static int adjust_ptr_min_max_vals(struct bpf_verifier_env *env,
 		return -EACCES;
 	}
 
-	/*
-	 * Accesses to untrusted PTR_TO_MEM are done through probe
-	 * instructions, hence no need to track offsets.
-	 */
-	if (base_type(ptr_reg->type) == PTR_TO_MEM && (ptr_reg->type & PTR_UNTRUSTED))
-		return 0;
-
 	switch (base_type(ptr_reg->type)) {
 	case PTR_TO_CTX:
 	case PTR_TO_MAP_VALUE:
@@ -13750,6 +13743,13 @@ static int adjust_ptr_min_max_vals(struct bpf_verifier_env *env,
 	if (dst_reg != ptr_reg)
 		*dst_reg = *ptr_reg;
 
+	/*
+	 * Accesses to untrusted PTR_TO_MEM are done through probe
+	 * instructions, hence no need to track offsets.
+	 */
+	if (base_type(ptr_reg->type) == PTR_TO_MEM && (ptr_reg->type & PTR_UNTRUSTED))
+		return 0;
+
 	if (!check_reg_sane_offset_scalar(env, off_reg, ptr_reg->type) ||
 	    !check_reg_sane_offset_ptr(env, ptr_reg, ptr_reg->type))
 		return -EINVAL;

-- 
2.43.0

