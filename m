From: Miao Wang <shankerwangmiao@gmail.com>
Date: Wed, 01 Jul 2026 06:16:00 +0800
Subject: [PATCH 6/6] target/loongarch: vstelm: Fix reading from vector
 registers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260701-loong64-be-v1-6-9c7d65e00697@gmail.com>
References: <20260701-loong64-be-v1-0-9c7d65e00697@gmail.com>
In-Reply-To: <20260701-loong64-be-v1-0-9c7d65e00697@gmail.com>
To: qemu-devel@nongnu.org
Cc: Song Gao <gaosong@loongson.cn>, 
 Richard Henderson <richard.henderson@linaro.org>, 
 Miao Wang <shankerwangmiao@gmail.com>, b4-sent@feeds.kernel.org
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=3494;
 i=shankerwangmiao@gmail.com; s=20250715; h=from:subject:message-id;
 bh=w1LZlKN7nRieAuFL85XuNkbOAVyXj/vQYFGAsWAwHMw=;
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBqREAm+KaHKt/kouxKGKw9jj76gAyfCrcvqzSdC
 uUnMJMODL2JAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCakRAJgAKCRCwMePKe/7Z
 buCTEADOZVsQSrUuWrKrBlkJ2am0uEJoF3ECQoKshzh6St3B7xlPyWmc8rZEmcbPqcs75//lre1
 /INAdPyZ7PTwWdsTUi+HO0uEWF06qsoSXSpx7vPEPx9VbIMEgQ8TesQ+bKcNrnnrftumHfi76Ju
 67l0OtvkK4ZHPVVUgRsCBP+BI+f26kSGazoau7JecrR1BTIasXtqAF3njRRdg1Z7YMsuBI5u9Ti
 Ecmngloj1rVWKTSblbezlRjaRxvS7envmX42ewWR7CphL+jyCaCI6YZDx7VpOJ9Ogn+MgmzY5lQ
 MA48O7xm8W3yqSe9bnaQAC8FlgpAzIvpRC5GTcdBo1WVFXfV3bTzypEY+I059RZ31jAituK44aY
 l4btG34UX2UO0yvaLR592L/nF7pCDkSzysk2oRi0kRFNjmSw/cprGXkSHpCaRafVT3H1XSqSn2R
 Z4GMNJJFjr/ZMm2FMykKetlslEAAooA4tpqsSAH87is3buiGbzLKwRUn1MfIRFMHz0QPV/ceol8
 MzmddQINj3/TrE3f5Rv/l7b91pP+PO2gFT+TuKnRKb/UExct9AB/xka4aTPar2/L4x3ILR28tZW
 ZsxzZbqTFqjMsEOgjaXHBxY0wxVPqk2rKMWapvpODszCV5aRty+FA3QagseeRsRKUKMbxZBJzkJ
 NVSKsWVXk4XMHlA==
X-Developer-Key: i=shankerwangmiao@gmail.com; a=openpgp;
 fpr=6FAEFF06B7D212A774C60BFDFA0D166D6632EF4A
X-Endpoint-Received: by B4 Relay for shankerwangmiao@gmail.com/20250715 with auth_id=462
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When reading data from vector registers, endianess should be in
consideration. Use tcg_gen_ld<len>_i64() functions to read a integer in
certain length at a certain offset from vector registers into an i64
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

