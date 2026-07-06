From: Miao Wang <shankerwangmiao@gmail.com>
Date: Tue, 07 Jul 2026 04:02:05 +0800
Subject: [PATCH v2 5/6] target/loongarch: do_vldrepl_vl: Fix endianness
 when reading from guest memory
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260707-loong64-be-v2-5-8634f93c1dc9@gmail.com>
References: <20260707-loong64-be-v2-0-8634f93c1dc9@gmail.com>
In-Reply-To: <20260707-loong64-be-v2-0-8634f93c1dc9@gmail.com>
To: qemu-devel@nongnu.org
Cc: Song Gao <gaosong@loongson.cn>, Jiaxun Yang <jiaxun.yang@flygoat.com>, 
 Richard Henderson <richard.henderson@linaro.org>, 
 =?utf-8?q?Philippe_Mathieu-Daud=C3=A9?= <philmd@oss.qualcomm.com>, 
 Miao Wang <shankerwangmiao@gmail.com>, b4-sent@feeds.kernel.org
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1181;
 i=shankerwangmiao@gmail.com; s=20250715; h=from:subject:message-id;
 bh=RtvkqLT2lF+j/y7Kk8Hb/ToTorcK/6EJPDqknnL+4/4=;
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBqTAnYI+bqkC6gGNAr40pvc+CXTiQU+Y5uUvjEr
 aN15vBtPxqJAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCakwJ2AAKCRCwMePKe/7Z
 bvB/D/9bjkFMJ3sFx1LJDz9/e20Eo07D7IBG7qg7aporvf6hwXMrEkbMLUJimU+TboYwBxkn3WZ
 xzrgHOS9P5cXiE0YpV5hhDg7i45qGPaQLa1OQ2DWPDuXp0B5t7a0D/pXx8N8JskpzPTb4KB15Qv
 r+zcsusPN2p0K5xuSY3MAOnWpbNnI4VAx5VAr0jqJNtqRoo/zaK7OWl1QcZwUkgrRqv1cZ8DSj+
 fioLY5J8jaArYiHFat3zevtECDc71v6LGOXaGHVAK5FA3Ozp/mpUUJ7oQKZE9JyW/ahwFr8lg60
 PdVV4IsPvrbw7G1olH7JugCCwrbU6ZNrOK5HddxHNPaJLelK456nzLegiBdYDAC4XVQ1f2Pe8L1
 3ErYXEZQxd4p85OLw7UdRkcRaThY2LTPxBgNK79yAAMg64xuNhfXF7oYFTz7RpBiD8QoaHaIFt3
 CJmhTVtrCe6QUc+w8pj0+1zKaDbgp7xAtLeocGSvWS9uxj7tXs7YEl2NFIxIWKxdY6jZeO9+ACA
 Z5BWAh05zM70AvzOq3UmMNN7vy5+06agJj7uQ+m6Ta9gRCXJUZYUW+h589083iBHUDPDTh+bSkN
 6O2+CBxop8RmJF7MD5FIcUwN2SmWo25XPrt27BGdT18LzzlwQXHKrknly2JcNP2ogOhs3vQSH+s
 8mtdic388SRfaZQ==
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

