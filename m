From: Miao Wang <shankerwangmiao@gmail.com>
Date: Wed, 01 Jul 2026 06:15:56 +0800
Subject: [PATCH 2/6] target/loongarch: Fix offset calculation in vector
 registers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260701-loong64-be-v1-2-9c7d65e00697@gmail.com>
References: <20260701-loong64-be-v1-0-9c7d65e00697@gmail.com>
In-Reply-To: <20260701-loong64-be-v1-0-9c7d65e00697@gmail.com>
To: qemu-devel@nongnu.org
Cc: Song Gao <gaosong@loongson.cn>, 
 Richard Henderson <richard.henderson@linaro.org>, 
 Miao Wang <shankerwangmiao@gmail.com>, b4-sent@feeds.kernel.org
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1231;
 i=shankerwangmiao@gmail.com; s=20250715; h=from:subject:message-id;
 bh=V/jhXbT74YZEsNz79vjrDNku8mR/iHXLwWV1UlDe90E=;
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBqREAl+bcJ7f+U2U5uTFeHz7/5qdEHL64tWwFiz
 gRJsD+C6hmJAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCakRAJQAKCRCwMePKe/7Z
 bhwIEAC9fH/P9OwZ+Qs+vSKOX/GHsaNQez0LoUzXDQmkFoQWC7eDQ09qKg14ZzLIcYfPI9raqMV
 Nv7xycWLt45jJ1SPeOfxcvdR3Hg7l0sXPKY0htMiin0TOy9bAU4dqipm/0hDX6S1i728WqnrU3f
 RKEX0M5a96YiIcuJXZKLovNVx5gc8NlWM2+6YNxuavyyIdWjixbPQIYR1jUL2Wrdq4BuwUFf4O+
 J6FsUIUHajNBWwvIQ3mCgUHSrBhpPfGokQDcH2vJp+LcnjZRUrhO+vw/UvIhGD8+9e4fji/5FRa
 QsXL/tHyPcWMh9EbEdJOlfctSgkdx25GxBYD12UeXWsOkL8m7077GH1zR8YxNxQMpVRinMqaqiH
 MLWkpFejwqWZ2uZOGkyUyDEr8PDA98ZcG8jAZ//JGCUEyf2D21DQatLDYkS3okwfEypWMhwUiyB
 cuhRlcn6ZiCGRBJvlO9nCI1GhivBT14gxmEis2fsn0N0eiYJZWPmFVlq486LwAXK/X9/O0BMEfX
 BLiLt1h1AHsoZWPfW9ruPDIUSEgty0LoA7nTTzcM7WGUIJzin4xYVm3Sly0f51rs7BKmFXr8W7T
 x+OinzlmczsHaBfsrF6e2Ue+eMZcH4UrGj8wXnby889O53i7eWEDryONunwP8KjBEU3CUADTTzy
 ygcDqCrE90pKl+g==
X-Developer-Key: i=shankerwangmiao@gmail.com; a=openpgp;
 fpr=6FAEFF06B7D212A774C60BFDFA0D166D6632EF4A
X-Endpoint-Received: by B4 Relay for shankerwangmiao@gmail.com/20250715 with auth_id=462
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When vector registers are extended to 256 bits long, the expected layout
of the registers is storing two 128-bit integers in host endianness, as
indicated in vec.h. So when the registers are visited in the unit of
64-bit, the index should also be reversed.

Fixes: f5ce2c8f2c0a ("target/loongarch: Implement xvinsgr2vr xvpickve2gr")
Signed-off-by: Miao Wang <shankerwangmiao@gmail.com>
---
 target/loongarch/tcg/translate.c | 6 +++---
 1 file changed, 3 insertions(+), 3 deletions(-)

diff --git a/target/loongarch/tcg/translate.c b/target/loongarch/tcg/translate.c
index 124dce626954a85e5754de847ccba1796aebd8a6..ac4daadfdb5298a0850bdd0b1fce32407f1eeecc 100644
--- a/target/loongarch/tcg/translate.c
+++ b/target/loongarch/tcg/translate.c
@@ -41,11 +41,11 @@ static inline int vec_full_offset(int regno)
 
 static inline int vec_reg_offset(int regno, int index, MemOp mop)
 {
-    const uint8_t size = 1 << mop;
+    const unsigned int size = memop_size(mop);
     int offs = index * size;
 
-    if (HOST_BIG_ENDIAN && size < 8 ) {
-        offs ^= (8 - size);
+    if (HOST_BIG_ENDIAN && size < 16) {
+        offs ^= (16 - size);
     }
 
     return offs + vec_full_offset(regno);

-- 
2.49.0

