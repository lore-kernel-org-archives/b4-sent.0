From: Miao Wang <shankerwangmiao@gmail.com>
Date: Tue, 07 Jul 2026 04:02:01 +0800
Subject: [PATCH v2 1/6] target/loongarch: make VReg aligned to 16 bytes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260707-loong64-be-v2-1-8634f93c1dc9@gmail.com>
References: <20260707-loong64-be-v2-0-8634f93c1dc9@gmail.com>
In-Reply-To: <20260707-loong64-be-v2-0-8634f93c1dc9@gmail.com>
To: qemu-devel@nongnu.org
Cc: Song Gao <gaosong@loongson.cn>, Jiaxun Yang <jiaxun.yang@flygoat.com>, 
 Richard Henderson <richard.henderson@linaro.org>, 
 =?utf-8?q?Philippe_Mathieu-Daud=C3=A9?= <philmd@oss.qualcomm.com>, 
 Miao Wang <shankerwangmiao@gmail.com>, b4-sent@feeds.kernel.org
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1091;
 i=shankerwangmiao@gmail.com; s=20250715; h=from:subject:message-id;
 bh=AFdjbsegFHP4zmAfzZSPK1zArtZDW6YGlRIIeT2QlgY=;
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBqTAnY6E5saa448LT9jtA+RJc6CB4bOwmFMfB25
 Ime763L0FCJAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCakwJ2AAKCRCwMePKe/7Z
 bsIED/0QTJidMnd1Q9kvhQF4E9k4rzyLL8gogp4fW/ULp4awxGpbOdpEdiaPBSJw+czbg3GTOhO
 K4yxhqmV3ADm5CFEtDNOkqsKTrlNWX9Bo9W2JSpsSyCKXoDD71X6Gg04qljSlAODvZMEqA0C2Dt
 5BJguxb82RiJ7O31P5vyBydTi6Mbm87bquB8pnvyBNK2wEYMFix8kFn+7TqNy5hy7ssOV9ISRNI
 k/FLtbL4+up000tMXcNv29fvIn6WpXVUNxuGRicDRTkEH+eIJc02j65kWjtmUmbCGx0dlaW7LG6
 Hmbg3wdbssJh6XtHYHE5ZYsS8/nWHeFXevmoYD82fHKkC7wShd2v32t7SIG6wUCm2oNyUDGBTA5
 HufnLwO6NLGwXd+nWZo6YyyAY0ahn0n4v16KjMpTj/joO58T7bIcTM/w2PJW75ZUIjkMErV+AnI
 z9tuVVJvYvbHxYl+CTQKAhaQAzHgaET4yL7YyW8MYuTtg3n8BlStYy1k9hkqvmQfyFjaDzZgQuj
 YIBumRlLGqqx+nvqMDaSjS/PNA5Sbf1MqjTDzh3j0emHX9r2slOIuCmiscjcx81ZixEcZxaHf+N
 UkpCfY3agZxc+WVBOZ46FwDFs+IhjQZs4bW/uQIwy0d7S8b7c5RwoOYX/09AFcDBX4Jjs1Zzarw
 QibMjpIyAoB1bxA==
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

Fixes: 2d5f950c054b ("target/loongarch: Implement vaddw/vsubw")
Fixes: 16f5396cec23 ("target/loongarch: Add LSX data type VReg")
Signed-off-by: Miao Wang <shankerwangmiao@gmail.com>
---
 target/loongarch/cpu.h | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/target/loongarch/cpu.h b/target/loongarch/cpu.h
index ad30c73167ecf6d8dc6faa8c6a18c212fe4fce55..166d831f29c5d239e1c8129fa3448d6242fc562b 100644
--- a/target/loongarch/cpu.h
+++ b/target/loongarch/cpu.h
@@ -276,7 +276,7 @@ typedef union VReg {
     uint32_t UW[LASX_LEN / 32];
     uint64_t UD[LASX_LEN / 64];
     Int128   Q[LASX_LEN / 128];
-} VReg;
+} QEMU_ALIGNED(16) VReg;
 
 typedef union fpr_t fpr_t;
 union fpr_t {

-- 
2.49.0

