From: Miao Wang <shankerwangmiao@gmail.com>
Date: Wed, 01 Jul 2026 06:15:59 +0800
Subject: [PATCH 5/6] target/loongarch: do_vldrepl_vl: Fix endianness when
 reading from guest memory
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260701-loong64-be-v1-5-9c7d65e00697@gmail.com>
References: <20260701-loong64-be-v1-0-9c7d65e00697@gmail.com>
In-Reply-To: <20260701-loong64-be-v1-0-9c7d65e00697@gmail.com>
To: qemu-devel@nongnu.org
Cc: Song Gao <gaosong@loongson.cn>, 
 Richard Henderson <richard.henderson@linaro.org>, 
 Miao Wang <shankerwangmiao@gmail.com>, b4-sent@feeds.kernel.org
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1181;
 i=shankerwangmiao@gmail.com; s=20250715; h=from:subject:message-id;
 bh=RtvkqLT2lF+j/y7Kk8Hb/ToTorcK/6EJPDqknnL+4/4=;
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBqREAlrK6i6XyJdiKWN0toYUEKqq9Qyr+VysqGL
 zUe31NoKo+JAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCakRAJQAKCRCwMePKe/7Z
 bvmSD/4kJL6SmlcOLBv8kQ5R8OZd9I2aWBFLDh5a14cMLJSc8AxZdHkkadnzRXpPs8iDtWVb8jG
 duGxzhg053VSNUStLotWDxGwPm51dvE+ofkE29ukogp0F7gWlmAtHrdgLXn3itSAT3NEu7KeOVv
 OUELvLQkpq+s2w65Sb7StmYYc9mvHdA7O0TAF1igVf0j9awZEulh0Ti/GO42djHauQSCUUBdVO9
 ZhA8XFiXe55dL3n0DJYqu3gn5da/DyVEx/N316VTJd1BQDf6Rz1TWGcekkNUlzQI09v93WPJ5zG
 G6gmx+AH9DKvyZYZ75OMY/UBlyyi9eCSwwEr/lWqVEaSYpf+19vmprNmwkSZnopD4kwKemp+PLC
 udJ5JMnsq3Bx3lVjmdgF8y1eGwWc33eSdsO1whCiVK2uq4DnOa6e2lMsJc71FCSMBafq67HswMs
 4UHX105nrUpVp6VqxWB66XXUORI7yvLzYxm+dB47t84M5xWSeqetXnszXtzHL+72pu0hJqPiyMZ
 tUz6jQByQVFU+uSqQBlYkV4Eb8bfrbmMEZV/AHjKhT1fAvnfzmjoEmGxS+C3LvTET/cqAsPBUUo
 +fEuWOa5wUPZJfm4Jn/bMm0XUe5TOiNoo/Xdn2Va/n457c0MOplCr8BBr6l9hSwyEPpEtaYyPXO
 oKBUCaW5Dxs6lJA==
X-Developer-Key: i=shankerwangmiao@gmail.com; a=openpgp;
 fpr=6FAEFF06B7D212A774C60BFDFA0D166D6632EF4A
X-Endpoint-Received: by B4 Relay for shankerwangmiao@gmail.com/20250715 with auth_id=462
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When reading from guest memory into vector registers, endianness should
be considered since the data in guest memory is in guest endianness and
the values in vector registers is in host endianness. Add MO_LE flag to
tcg_gen_qemu_ld_i64() to fix this.

Fixes: 4a26512f01e0 ("target/loongarch: Implement xvld xvst")
Signed-off-by: Miao Wang <shankerwangmiao@gmail.com>
---
 target/loongarch/tcg/insn_trans/trans_vec.c.inc | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/target/loongarch/tcg/insn_trans/trans_vec.c.inc b/target/loongarch/tcg/insn_trans/trans_vec.c.inc
index 03938b1f052335190cdc437fc2d453b4f4fe16a4..91b1e15b61cac5d119892df1abd2ecf8a4c8e59d 100644
--- a/target/loongarch/tcg/insn_trans/trans_vec.c.inc
+++ b/target/loongarch/tcg/insn_trans/trans_vec.c.inc
@@ -5397,7 +5397,7 @@ static bool do_vldrepl_vl(DisasContext *ctx, arg_vr_i *a,
 
     addr = make_address_i(ctx, addr, a->imm);
 
-    tcg_gen_qemu_ld_i64(val, addr, ctx->mem_idx, mop);
+    tcg_gen_qemu_ld_i64(val, addr, ctx->mem_idx, mop | MO_LE);
     tcg_gen_gvec_dup_i64(mop, vec_full_offset(a->vd), oprsz, ctx->vl / 8, val);
 
     return true;

-- 
2.49.0

