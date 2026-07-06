From: Miao Wang <shankerwangmiao@gmail.com>
Date: Tue, 07 Jul 2026 04:02:06 +0800
Subject: [PATCH v2 6/6] target/loongarch: vstelm: Fix reading from vector
 registers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260707-loong64-be-v2-6-8634f93c1dc9@gmail.com>
References: <20260707-loong64-be-v2-0-8634f93c1dc9@gmail.com>
In-Reply-To: <20260707-loong64-be-v2-0-8634f93c1dc9@gmail.com>
To: qemu-devel@nongnu.org
Cc: Song Gao <gaosong@loongson.cn>, Jiaxun Yang <jiaxun.yang@flygoat.com>, 
 Richard Henderson <richard.henderson@linaro.org>, 
 =?utf-8?q?Philippe_Mathieu-Daud=C3=A9?= <philmd@oss.qualcomm.com>, 
 Miao Wang <shankerwangmiao@gmail.com>, b4-sent@feeds.kernel.org
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=3495;
 i=shankerwangmiao@gmail.com; s=20250715; h=from:subject:message-id;
 bh=2iuxs5risliYf2dBgG2FUXCXbQZaaq0rhiN1iTetazE=;
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBqTAnYQ2//ZPQz0sCn6Kt+i4UQWMvWeLUaa0kCz
 qpXjNKgVg2JAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCakwJ2AAKCRCwMePKe/7Z
 buDfEACiHGv8hm5H9imnVFk6uM1MX/2A9+udugFDce0onU8pQHccJUFWLNJ8PvteKMh6v+3pAzS
 dx0f3LttNqvXV1MsY5H+RHsHaEo/NrdxsK6BstDanvR7tv6CidZVo/kih/NElfS/CziC5R8Eys6
 qsSuzAbn6rdg1ce/6Fi0mu3HVR0sXnB6tYgHhy2G1oAB+yOAk+iO7lPHiA3Rjt/+ZTqQuDfYDox
 CD0QfLpPG/kLhB3ztSG2dwcLwvlreBspYjjJP1A+N4/R3hW5MHPO7Mmj7TEI9OkS40xYy2L2ycj
 4Ccu6UHVRY0EfvdSUMlnL4r19TqZqjsJZ5bskJFcuimXuh1pyBOtloTsXrynK3QVtaEOw0w8cGy
 4fRIWnaujOd/RQBt25z/Gq4VZ8E7Gex5fPRWr8snTntfoEWs9JRB+9UfSc3Q4ptFBmoqOwSaRiN
 XYCCaGYsAu8sP76MM3fTZn8PYG2ccx+7Ac0o+eNe8orw2HnibmzVDPU8PQvSLlNIppmEaBc3p0s
 yOjHAriTrwzAufyk1fwNCydpqcgaphSH9fKA9vZbfVNGsEP134kxwSj9Gc5p2bafGJHKHOvLeqI
 TpP+K8rueFGBlNC0vdz2p+OhHD7jyb+gj+C/+g+l/IbjElpHw8hgRn6kuYMz85asOQ2bdp+4ROs
 KCb2aCpl2hLMR+Q==
X-Developer-Key: i=shankerwangmiao@gmail.com; a=openpgp;
 fpr=6FAEFF06B7D212A774C60BFDFA0D166D6632EF4A
X-Endpoint-Received: by B4 Relay for shankerwangmiao@gmail.com/20250715 with auth_id=462
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When reading data from vector registers, endianess should be in
consideration. Use tcg_gen_ld<len>_i64() functions to read an integer
in certain length at a certain offset from vector registers into an i64
temporary variable. tcg_gen_ld_i64() cannot achieve this on big endian
hosts. When writing data to guest memory, endianess should also be
declared using the MO_LE flag for tcg_gen_qemu_st_i64().

Fixes: 4a26512f01e0 ("target/loongarch: Implement xvld xvst")
Fixes: 843b627a395a ("target/loongarch: Implement vld vst")
Signed-off-by: Miao Wang <shankerwangmiao@gmail.com>
---
 target/loongarch/tcg/insn_trans/trans_vec.c.inc | 33 ++++++++++++++-----------
 1 file changed, 18 insertions(+), 15 deletions(-)

diff --git a/target/loongarch/tcg/insn_trans/trans_vec.c.inc b/target/loongarch/tcg/insn_trans/trans_vec.c.inc
index 91b1e15b61cac5d119892df1abd2ecf8a4c8e59d..3cac981be1dba11db46744f88e851838aea651cd 100644
--- a/target/loongarch/tcg/insn_trans/trans_vec.c.inc
+++ b/target/loongarch/tcg/insn_trans/trans_vec.c.inc
@@ -5423,7 +5423,8 @@ TRANS(xvldrepl_w, LASX, do_xvldrepl, MO_32)
 TRANS(xvldrepl_d, LASX, do_xvldrepl, MO_64)
 
 static bool do_vstelm_vl(DisasContext *ctx,
-                         arg_vr_ii *a, uint32_t oprsz, MemOp mop)
+                         arg_vr_ii *a, uint32_t oprsz, MemOp mop,
+                         void (*func)(TCGv, TCGv_ptr, tcg_target_long))
 {
     TCGv addr;
     TCGv_i64 val;
@@ -5436,29 +5437,31 @@ static bool do_vstelm_vl(DisasContext *ctx,
     val = tcg_temp_new_i64();
 
     addr = make_address_i(ctx, addr, a->imm);
-    tcg_gen_ld_i64(val, tcg_env, vec_reg_offset(a->vd, a->imm2, mop));
-    tcg_gen_qemu_st_i64(val, addr, ctx->mem_idx, mop);
+    func(val, tcg_env, vec_reg_offset(a->vd, a->imm2, mop));
+    tcg_gen_qemu_st_i64(val, addr, ctx->mem_idx, mop | MO_LE);
     return true;
 }
 
-static bool do_vstelm(DisasContext *ctx, arg_vr_ii *a, MemOp mop)
+static bool do_vstelm(DisasContext *ctx, arg_vr_ii *a, MemOp mop,
+                      void (*func)(TCGv, TCGv_ptr, tcg_target_long))
 {
-    return do_vstelm_vl(ctx, a, 16, mop);
+    return do_vstelm_vl(ctx, a, 16, mop, func);
 }
 
-static bool do_xvstelm(DisasContext *ctx, arg_vr_ii *a, MemOp mop)
+static bool do_xvstelm(DisasContext *ctx, arg_vr_ii *a, MemOp mop,
+                       void (*func)(TCGv, TCGv_ptr, tcg_target_long))
 {
-    return do_vstelm_vl(ctx, a, 32, mop);
+    return do_vstelm_vl(ctx, a, 32, mop, func);
 }
 
-TRANS(vstelm_b, LSX, do_vstelm, MO_8)
-TRANS(vstelm_h, LSX, do_vstelm, MO_16)
-TRANS(vstelm_w, LSX, do_vstelm, MO_32)
-TRANS(vstelm_d, LSX, do_vstelm, MO_64)
-TRANS(xvstelm_b, LASX, do_xvstelm, MO_8)
-TRANS(xvstelm_h, LASX, do_xvstelm, MO_16)
-TRANS(xvstelm_w, LASX, do_xvstelm, MO_32)
-TRANS(xvstelm_d, LASX, do_xvstelm, MO_64)
+TRANS(vstelm_b, LSX, do_vstelm, MO_8,  tcg_gen_ld8u_i64)
+TRANS(vstelm_h, LSX, do_vstelm, MO_16, tcg_gen_ld16u_i64)
+TRANS(vstelm_w, LSX, do_vstelm, MO_32, tcg_gen_ld32u_i64)
+TRANS(vstelm_d, LSX, do_vstelm, MO_64, tcg_gen_ld_i64)
+TRANS(xvstelm_b, LASX, do_xvstelm, MO_8,  tcg_gen_ld8u_i64)
+TRANS(xvstelm_h, LASX, do_xvstelm, MO_16, tcg_gen_ld16u_i64)
+TRANS(xvstelm_w, LASX, do_xvstelm, MO_32, tcg_gen_ld32u_i64)
+TRANS(xvstelm_d, LASX, do_xvstelm, MO_64, tcg_gen_ld_i64)
 
 static bool gen_lasx_memory(DisasContext *ctx, arg_vr_i *a,
                             void (*func)(DisasContext *, int, TCGv))

-- 
2.49.0

