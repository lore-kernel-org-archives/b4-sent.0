From: Miao Wang <shankerwangmiao@gmail.com>
Date: Wed, 01 Jul 2026 06:15:55 +0800
Subject: [PATCH 1/6] target/loongarch: make VReg aligned to 16 bytes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260701-loong64-be-v1-1-9c7d65e00697@gmail.com>
References: <20260701-loong64-be-v1-0-9c7d65e00697@gmail.com>
In-Reply-To: <20260701-loong64-be-v1-0-9c7d65e00697@gmail.com>
To: qemu-devel@nongnu.org
Cc: Song Gao <gaosong@loongson.cn>, 
 Richard Henderson <richard.henderson@linaro.org>, 
 Miao Wang <shankerwangmiao@gmail.com>, b4-sent@feeds.kernel.org
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1057;
 i=shankerwangmiao@gmail.com; s=20250715; h=from:subject:message-id;
 bh=jW/M08ur9xKxaX4nfsRSNoLMXNSMRPuO/YQmGnCRU14=;
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBqREAlZC/CoiyZbfeQ4JRHGq3Bidgvf3saMzRjL
 BxIy0WCVTGJAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCakRAJQAKCRCwMePKe/7Z
 bt+JD/9wiuXoP+ozxMbiMhcgjtalEQcnjQYwhFVBoGUTX4r+2L+PIY8VJu5fyIFTF7a4qYsTGXb
 ev2OBVU5nhPN1A2ilSnucnrX8aArTm+Draa2ngN350UbNv9zQUSttr77RxwpVv1kCDBxHyV4v56
 f2q/pzLgoQxuokW9PmMERo2Lp1SBw9i4gP517OszDeAko3mJRDRe+dSe5mTggtx6UjM8w9RXSwu
 ls/h5yUPTT0cXVuhLzkUvt0ugJAK7xnSdZ9dU4yNfjzdPgM9bXs1pLDHa4Cr3M5G6clwqJ+AvCS
 Tt2El3WcRexS0ka7Envz1JalkuqUESoXYJzaSo4VKNck2P1Cg4J9nOLUax09z5ciDGBji7mR3dU
 9CdZxBjIYVxP19GxKJ7fpMjHtYjXclWwO6gWt8S08myolWbmdzFToZYqESXY6wNrltOYOWf/aEP
 FQKQT2jn5Xd1IbRQt3Q/VBA6kQrHo5bBsfxB85ySsXIfzBkLuDF4cL9ytU2HxIJ9wJuwcOBU0Ap
 8ErUYosznO03CmDj4MK2cE1decfm4xZIrPsty7+h9evq0MijNafy0oF8UOStvOL7EaxO4Eh3hor
 KoNPMGvnMpyaWcSRWO3+EcJqhnMZONNJJE5bKiZJtQcPkFJUOMdJML7Uo0Op1ewbP6koW/AYXFk
 BtP6Q4y60r7l6GA==
X-Developer-Key: i=shankerwangmiao@gmail.com; a=openpgp;
 fpr=6FAEFF06B7D212A774C60BFDFA0D166D6632EF4A
X-Endpoint-Received: by B4 Relay for shankerwangmiao@gmail.com/20250715 with auth_id=462
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When tcg_gen_gvec_* functions are used to operate on 128-bit
vector registers, the registers are required to be aligned
to 16 bytes. On some platforms, such as s390x, __int128 is
not aligned to 16 bytes, which will break the requirement
and make tcg_gen_gvec_* functions operate on only 64 bits.
Explicitly use aligned 128-bit integer to fix this.

Fixes: 008a3b1662b6 ("target/loongarch: Add LASX data support")
Signed-off-by: Miao Wang <shankerwangmiao@gmail.com>
---
 target/loongarch/cpu.h | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/target/loongarch/cpu.h b/target/loongarch/cpu.h
index ad30c73167ecf6d8dc6faa8c6a18c212fe4fce55..d3eb35953abb87dfb34b8f3340f8dfd83264a484 100644
--- a/target/loongarch/cpu.h
+++ b/target/loongarch/cpu.h
@@ -275,7 +275,7 @@ typedef union VReg {
     uint16_t UH[LASX_LEN / 16];
     uint32_t UW[LASX_LEN / 32];
     uint64_t UD[LASX_LEN / 64];
-    Int128   Q[LASX_LEN / 128];
+    Int128Aligned   Q[LASX_LEN / 128];
 } VReg;
 
 typedef union fpr_t fpr_t;

-- 
2.49.0

