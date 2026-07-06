From: Miao Wang <shankerwangmiao@gmail.com>
Date: Tue, 07 Jul 2026 04:02:04 +0800
Subject: [PATCH v2 4/6] target/loongarch: gen_xvreplve0: Fix elem0 offset
 calculation
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260707-loong64-be-v2-4-8634f93c1dc9@gmail.com>
References: <20260707-loong64-be-v2-0-8634f93c1dc9@gmail.com>
In-Reply-To: <20260707-loong64-be-v2-0-8634f93c1dc9@gmail.com>
To: qemu-devel@nongnu.org
Cc: Song Gao <gaosong@loongson.cn>, Jiaxun Yang <jiaxun.yang@flygoat.com>, 
 Richard Henderson <richard.henderson@linaro.org>, 
 =?utf-8?q?Philippe_Mathieu-Daud=C3=A9?= <philmd@oss.qualcomm.com>, 
 Miao Wang <shankerwangmiao@gmail.com>, b4-sent@feeds.kernel.org
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1177;
 i=shankerwangmiao@gmail.com; s=20250715; h=from:subject:message-id;
 bh=JVeeeYSYmuNx8G6YkhYHh9AnFOY8pRrWSpHwtr34lFg=;
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBqTAnYtNN+KK4/+Kng0gO/ykCyo9h6WMWH8ORYi
 931tMbOTK2JAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCakwJ2AAKCRCwMePKe/7Z
 bgIHEACZbPxGekTV/dsvZToilBU6OYzCQ6YxQ7H3mRvz15AcFwb6xRW15l01VSuni97lRyfCSPg
 6WRyxGdPLmQeJQej/2GCAOJ0A/yGqHcX/AbTtoRGdLPSjpX61XbPdQbczFE1bo3p3vOZ56wnwdO
 r+mLzaVDQSxf7EjrPmHYE8a13hC9PiD63LZ5zyL2mz5BVVS/dqhJmI3r8F4FKy8v9IWauhoPZwN
 J/MF7h2+jVaATqVZVbudhRfM5QC+URbSo2V5sfg+F1PQtF6dPwjswxj7/Afvbn7/P5PTdvJ0rH6
 g+Wwr2n7eLrX1cxAn1+zmVXPRx68u/Bof3brz0SMjrhr2cILsFRGLex0b7udrE7N+iy2VY0Zd0K
 TFVf8fiwYp2PdWDF5IQMX4mxY8+N2Y4RDB3OWedOk9XLQ3xF9RcfR0m4HWJbwAaTebqz+n/UExq
 uSY8LdCz7WgA3chP5BHNwKoIP81Hv+oSbvWfdOnfrXD2ldfegVGANlbwr+MNlGqwauXR6384Txz
 EAI7MsSqOQSTKosL21HZEbUhhSS+M9vwx5ZACrQv5J7uMTLiLp3cOgL7D1gW5JjGYoI5GRTfCv0
 MXpCuKPCliMzPvqxOx/bXTkUWi5feqGc3cnYuogs6LKx4HZveVvtqlFGx9vdj9MGpT2JnknkrSL
 OsbG5Jm9PZo3yXQ==
X-Developer-Key: i=shankerwangmiao@gmail.com; a=openpgp;
 fpr=6FAEFF06B7D212A774C60BFDFA0D166D6632EF4A
X-Endpoint-Received: by B4 Relay for shankerwangmiao@gmail.com/20250715 with auth_id=462
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When xvreplve0 is implemented, it should not be taken for granted that
the first element of a vector register is at the starting point of the
vector register on big endian hosts, vec_reg_offset() is used to fix
this.

Fixes: df97f3380760 ("target/loongarch: Implement xvreplve xvinsve0 xvpickve")
Reviewed-by: Philippe Mathieu-Daudé <philmd@oss.qualcomm.com>
Signed-off-by: Miao Wang <shankerwangmiao@gmail.com>
---
 target/loongarch/tcg/insn_trans/trans_vec.c.inc | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/target/loongarch/tcg/insn_trans/trans_vec.c.inc b/target/loongarch/tcg/insn_trans/trans_vec.c.inc
index df0e809d544678490ca3ccfddab3fd4d74f7189a..03938b1f052335190cdc437fc2d453b4f4fe16a4 100644
--- a/target/loongarch/tcg/insn_trans/trans_vec.c.inc
+++ b/target/loongarch/tcg/insn_trans/trans_vec.c.inc
@@ -5099,7 +5099,7 @@ static bool gen_xvreplve0(DisasContext *ctx, arg_vv *a, MemOp mop)
     }
 
     tcg_gen_gvec_dup_mem(mop, vec_full_offset(a->vd),
-                         vec_full_offset(a->vj), 32, 32);
+                         vec_reg_offset(a->vj, 0, mop), 32, 32);
     return true;
 }
 

-- 
2.49.0

