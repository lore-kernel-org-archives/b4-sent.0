From: Miao Wang <shankerwangmiao@gmail.com>
Date: Wed, 01 Jul 2026 06:15:58 +0800
Subject: [PATCH 4/6] target/loongarch: gen_xvreplve0: Fix elem0 offset
 calculation
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260701-loong64-be-v1-4-9c7d65e00697@gmail.com>
References: <20260701-loong64-be-v1-0-9c7d65e00697@gmail.com>
In-Reply-To: <20260701-loong64-be-v1-0-9c7d65e00697@gmail.com>
To: qemu-devel@nongnu.org
Cc: Song Gao <gaosong@loongson.cn>, 
 Richard Henderson <richard.henderson@linaro.org>, 
 Miao Wang <shankerwangmiao@gmail.com>, b4-sent@feeds.kernel.org
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1113;
 i=shankerwangmiao@gmail.com; s=20250715; h=from:subject:message-id;
 bh=moaNZILUTzChJGSSSUB7fQ2em+5SHk2AQhoSA/9obmI=;
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBqREAl/AvX/TREG7mBTgwyhOylN3Moeb4f7cmBi
 +wnSDFqhfGJAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCakRAJQAKCRCwMePKe/7Z
 btUND/4qCUDVgECThnqGATsX5KczhGHIp7CeSCNjCTk8ODudZRfHrvmIVSBYe9+GXZHGK+j9+3H
 RVP0M6/Beq1+VkfectI4mGOT4I6nYvkvpqK8aIxShCyFi3+GAy60EZtP56BvlU3btl+hrWVMkwl
 UE2wyru+M92DyZYvnAsIonvEu593UiuqmxxtbfrX9w7Si+9SnQueFb0yMe8TwuAE+rhQP5+a8kn
 lra6nN/2nh6QCsuxTrUK/kH4T/28CbDlWLDDJKM1QMoFAgkA+23giXT8MVNM7orLcEfhyCwvmvM
 NsrQrH4En3UqtV9dKkR1kJoq5g3oB05qZ+8yGnYy+XXEwQo+vTHe8+eemEJM5C1G+FHKBbdKU5e
 3T5X/Ndcf0jOocPocJw8IU5EllOqjJOk9blQ4Y1bNpZNxsA5EBP5VR1FQeJiqKE4Eo0SemSDwU7
 vMX1RDaYH3k1NU/3ZRVvleSemkHrjc0CN43gdqAye4L6ANGx13EsNpOAHXXMZJ8Yzh8Dj42z6+L
 sGzvLRyCfZmsuL4XLUeRJCQZv8drMFJmBpihkjgdQslclSQ2shvugk7dCLK/+HusJKjKDjvOn0y
 g7ZiqA6nKL2Js0c9Z2EktHMfHvPk76Fw+6eU0bZ3AOR66jqyEhWQG1AKFDq7hYNK8WsBrT+7dXp
 7ULwfcSNyxXMg9A==
X-Developer-Key: i=shankerwangmiao@gmail.com; a=openpgp;
 fpr=6FAEFF06B7D212A774C60BFDFA0D166D6632EF4A
X-Endpoint-Received: by B4 Relay for shankerwangmiao@gmail.com/20250715 with auth_id=462
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When xvreplve0 is implemented, it should not be taken for granted that
the first element of a vector register is at the starting point of the
vector register on big endian hosts, vec_reg_offset() is used to fix
this.

Fixes: df97f3380760 ("target/loongarch: Implement xvreplve xvinsve0 xvpickve")
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

