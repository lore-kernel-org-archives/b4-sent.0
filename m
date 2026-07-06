From: Miao Wang <shankerwangmiao@gmail.com>
Date: Tue, 07 Jul 2026 04:02:03 +0800
Subject: [PATCH v2 3/6] target/loongarch: gen_vreplve: Fix offset
 calculation
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260707-loong64-be-v2-3-8634f93c1dc9@gmail.com>
References: <20260707-loong64-be-v2-0-8634f93c1dc9@gmail.com>
In-Reply-To: <20260707-loong64-be-v2-0-8634f93c1dc9@gmail.com>
To: qemu-devel@nongnu.org
Cc: Song Gao <gaosong@loongson.cn>, Jiaxun Yang <jiaxun.yang@flygoat.com>, 
 Richard Henderson <richard.henderson@linaro.org>, 
 =?utf-8?q?Philippe_Mathieu-Daud=C3=A9?= <philmd@oss.qualcomm.com>, 
 Miao Wang <shankerwangmiao@gmail.com>, b4-sent@feeds.kernel.org
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1277;
 i=shankerwangmiao@gmail.com; s=20250715; h=from:subject:message-id;
 bh=bC5SqslKnEPRqmw7UZDsgSavAaNwn/tX4lGdinMQfiM=;
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBqTAnYscDls0eB4JiNHScwXQeJOVLTKEidTGKjm
 kyqxRx7m8yJAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCakwJ2AAKCRCwMePKe/7Z
 bm13EAC6I8w3R4d7yFSrRVdd73QdLS8M7IjTtulokzm/xZ70nQfgtSoEzD39FnorbxmsUJ9I74K
 z5dMh3rLAcl74+adtdmkFCrEZImPalS81glsSzuWJmM5Tap1+/HTwTfAXaLdWGfCi6pKwrtGJWO
 8ZQ+qXzq3zUxZbLXJ0OFy/bgDuMJZYei0ynpInEfb5EhpLwFzX9mchG44feSeDSWV4O6vg6qt/J
 LlB/VXir8hQzmWhQdTstlTzNhZz1ZXIw76BHiXwqEDh3D7DMmdna44WREcV4495FKicDU1nPuA/
 LWNJtAohCU93iymw9jSEM+90KK6wHw/MiT7VbEoaoBohgzNo1D3iXDj8UK9C3Z0Qr/0abS56XHz
 Dek4tD6kjB3CattiDdHN3bThh0oKbhr5Dnll3MI+y4aq12L+a8sH9OoB+bD1pIc9tGpiSd8MFWM
 BlTG3heaL3oOzrkEql0YmD5nd3/5u5MeILgs/08zGHzcet6XnGS7nru2GvxITWJzD3SBJQlhPOI
 V/u4PQyM0S9EaALEZhBON0kXzZByTDDL8tg9dgPw2yEQItOideIyG6iDLAunMq4a7ECiEicqh0L
 xfJOasqS+BDqrc99fLqAtVTAxbYP6VYaUwIidsNwT2UTkQDs+6jaU50FYSzTzhEYHLBTW2tkrnO
 jb0pcIledTa2sSw==
X-Developer-Key: i=shankerwangmiao@gmail.com; a=openpgp;
 fpr=6FAEFF06B7D212A774C60BFDFA0D166D6632EF4A
X-Endpoint-Received: by B4 Relay for shankerwangmiao@gmail.com/20250715 with auth_id=462
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When generating tcg instructions for vreplve, the calculation of the
offset in the vector registers from given channel in the general
register should be done using tcg op codes. The algorithm should be
similar as vec_reg_offset().

Fixes: df97f3380760 ("target/loongarch: Implement xvreplve xvinsve0 xvpickve")
Fixes: 008a3b1662b6 ("target/loongarch: Add LASX data support")
Signed-off-by: Miao Wang <shankerwangmiao@gmail.com>
---
 target/loongarch/tcg/insn_trans/trans_vec.c.inc | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/target/loongarch/tcg/insn_trans/trans_vec.c.inc b/target/loongarch/tcg/insn_trans/trans_vec.c.inc
index 195b89f78834b208f0ba83930b844e792dc488b6..df0e809d544678490ca3ccfddab3fd4d74f7189a 100644
--- a/target/loongarch/tcg/insn_trans/trans_vec.c.inc
+++ b/target/loongarch/tcg/insn_trans/trans_vec.c.inc
@@ -5036,7 +5036,7 @@ static bool gen_vreplve_vl(DisasContext *ctx, arg_vvr *a,
     tcg_gen_andi_i64(t0, gpr_src(ctx, a->rk, EXT_NONE), (LSX_LEN / bit) - 1);
     tcg_gen_shli_i64(t0, t0, vece);
     if (HOST_BIG_ENDIAN) {
-        tcg_gen_xori_i64(t0, t0, vece << ((LSX_LEN / bit) - 1));
+        tcg_gen_xori_i64(t0, t0, 16 - (bit / 8));
     }
 
     tcg_gen_trunc_i64_ptr(t1, t0);

-- 
2.49.0

