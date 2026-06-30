From: Miao Wang <shankerwangmiao@gmail.com>
Date: Wed, 01 Jul 2026 06:15:57 +0800
Subject: [PATCH 3/6] target/loongarch: gen_vreplve: Fix offset calculation
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260701-loong64-be-v1-3-9c7d65e00697@gmail.com>
References: <20260701-loong64-be-v1-0-9c7d65e00697@gmail.com>
In-Reply-To: <20260701-loong64-be-v1-0-9c7d65e00697@gmail.com>
To: qemu-devel@nongnu.org
Cc: Song Gao <gaosong@loongson.cn>, 
 Richard Henderson <richard.henderson@linaro.org>, 
 Miao Wang <shankerwangmiao@gmail.com>, b4-sent@feeds.kernel.org
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1277;
 i=shankerwangmiao@gmail.com; s=20250715; h=from:subject:message-id;
 bh=bC5SqslKnEPRqmw7UZDsgSavAaNwn/tX4lGdinMQfiM=;
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBqREAl3N+hxcxcq0u1qJyanEPHRKJo+Psrg6oJ7
 Py6YFFIKeSJAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCakRAJQAKCRCwMePKe/7Z
 bqqFD/90jfPSAFlcgay7PWLh0sTEnyfvqZ3J/xtOAcZudwA6HYfL5LNyaxiel/59YEn0tXeKobp
 fuL+sOnfcBbUXQApM1CkJMk6nhwgavHPw42s19O2ppEyWlgtimobR+sbGnHnoI8GP/guOyktqbz
 wGJqm6B51Fb389TIxaekNsZzaKNOGlHP+RevUvz4UHdYv3cLq/nwKnc9yIh6FlJR4ibOE7pgNBm
 W81WXW1Dr2V+YfHF693guguA/6gxahn0CivpOSxLF4QH0G5PyuCmjzCuepEPH3FUJaRNJWMm41u
 8mH7kRV1R3xlm3m7I6n92UE5LQwKuR/p+5HU/NChSsW7/wV84xgVwxa7ow6TUyzafA5mFbMKa/r
 TZ2IZtLPS41GvWxaxxZO2KbVnBjZzFmCwgAE9msQh9Ipj56S2tNrP+9Xoh5Rr+Lt0ZDLCg7WmyB
 xBaLfc2Fn5UDAg+uRQGE3T/CXfKm4tZhXpcOZUNgcQ/FW8Q2ri8XEEqPyT/S4P4LVaOohdgqM6I
 xv8Af3tT3O6cOjOjZ9tMDAUeHvN1PwKBnuBWXJs1LAH3zXihrNYgpOr9XR8t3w/F6mtv96XLaBa
 qR2uIo8mY32V+Jmp6PiGTGN+oZoG1gipgYzlGMXaM2krF6LRah1/hCL6eoQYkteSE2KXryhXk/C
 qdhp74IYeghk3sA==
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

