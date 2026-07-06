From: Miao Wang <shankerwangmiao@gmail.com>
Date: Tue, 07 Jul 2026 04:02:02 +0800
Subject: [PATCH v2 2/6] target/loongarch: Fix offset calculation in vector
 registers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260707-loong64-be-v2-2-8634f93c1dc9@gmail.com>
References: <20260707-loong64-be-v2-0-8634f93c1dc9@gmail.com>
In-Reply-To: <20260707-loong64-be-v2-0-8634f93c1dc9@gmail.com>
To: qemu-devel@nongnu.org
Cc: Song Gao <gaosong@loongson.cn>, Jiaxun Yang <jiaxun.yang@flygoat.com>, 
 Richard Henderson <richard.henderson@linaro.org>, 
 =?utf-8?q?Philippe_Mathieu-Daud=C3=A9?= <philmd@oss.qualcomm.com>, 
 Miao Wang <shankerwangmiao@gmail.com>, b4-sent@feeds.kernel.org
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1231;
 i=shankerwangmiao@gmail.com; s=20250715; h=from:subject:message-id;
 bh=V/jhXbT74YZEsNz79vjrDNku8mR/iHXLwWV1UlDe90E=;
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBqTAnYggITlpKUwRmFxh1aB05ohhyyRzmGoL2M+
 CqtCJX5A46JAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCakwJ2AAKCRCwMePKe/7Z
 bnmOEACnU5DLPMfDA5MFQ1iD4PapxQTzeGM5AH8+uDNVR6FyI2WMEp4xETs9/ks7vZF0xAZROdv
 tK6T8i04iGtK6skVP0YBw0aEEIWQ3aLb9EcCtDNB9vTHHF6oOs5OAEAd4Vv3noMSdUGwEOGHUzX
 dvW/isJeMnpOQjbKp+VKFiVecH5P88GnNawO1eNlnbuwcfRzbzckkTQ5LsjamjFgeqimhYRCD4F
 i7BaycWHd6PkJdoPEWWo6sTc631d8Ma/2saWcIp/A7GiGE+2D36am/fRyccW0dpAwAz8/7hLZlT
 qnJCnIbUFG9LJv1TnJ8dmOy/mtmOV424heF++hPA2tA/yShEt+gVLNKlP7su+16pYueRny/HtM9
 aW9/OVQyPGE9lZuXOPwRTgW1BnN9qe7xYIIsnTzOTzWHDpoz4uX2hiymRKQFFWQ6a0UwKp4ruSJ
 C05DNJ8znDMk3g2Rm38XSa7zMIJ7ygGptG3gzjNRaQyvQcauHxg3xxtIiu/9VpesUPL8ALP+Zvl
 Cdl/uIsp21eqhkLh3GBULw8sT7UIcrBMAjXtDOf/W220FK942HvOcFHprE0vylo0QXFnt66+VGF
 /bkpNBXXBw8G03IZNDVON67tEbgCoVFjZO1hvrjHeX6NjhxrvOu6FybiAVTjiTrz6J+0/IJk+K3
 jhv6e61ii03LbiA==
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

