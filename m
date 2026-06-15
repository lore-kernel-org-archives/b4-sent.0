From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Mon, 15 Jun 2026 16:51:15 +0100
Subject: [PATCH] lib: math: test_mul_u64_u64_div_u64: define div64_s64_rem
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260615-test-mul-div-u64-fixup-v1-1-ea186d825745@analog.com>
X-B4-Tracking: v=1; b=H4sIAHIfMGoC/x2MWwqAIBAArxL73YKG2uMq0UePrRbKQjMC6e5Jn
 8MwE8GTY/LQZBEc3ez5sAlknsG49nYh5CkxFKIwwkiNF/kL97DhxDcGo3DmJ5yohdS1Il1Wg4I
 Un46S+Mdt974ffzi4kGgAAAA=
X-Change-ID: 20260615-test-mul-div-u64-fixup-501594e578b4
To: linux-kernel@vger.kernel.org, linux-iio@vger.kernel.org
Cc: Jonathan Cameron <jic23@kernel.org>, Andy Shevchenko <andy@kernel.org>, 
 kernel test robot <lkp@intel.com>, 
 Rodrigo Alencar <rodrigo.alencar@analog.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781538698; l=1290;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=3SgBmMM2VffDRtuuezVRLfHjFVAyTOp0L7/XpgDfV7g=;
 b=9HkwyBphFaKPg7JgRsEPuVVqwzST1uKecopMKi4R7lg35cwA9c7HttRox6AXpByqGLpGr6qKm
 v+llbLZna0OAy4owfzHATkmHksIg5G223yKqQYiOlwWUAAiIzVmO174
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Define div64_s64_rem to avoid multiple definition or exports.

Reported-by: kernel test robot <lkp@intel.com>
Closes: https://lore.kernel.org/oe-kbuild-all/202606152154.P6pwbjhp-lkp@intel.com/
Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
Recently added div64_s64_rem() is causing issues in a the
test build. This could be a fixup patch amended to:

https://git.kernel.org/pub/scm/linux/kernel/git/jic23/iio.git/commit/?h=testing&id=adebf76278116a06166d0b5f8b4112ad5dd6389a
---
 lib/math/test_mul_u64_u64_div_u64.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/lib/math/test_mul_u64_u64_div_u64.c b/lib/math/test_mul_u64_u64_div_u64.c
index 338d014f0c73..d12dc05938fb 100644
--- a/lib/math/test_mul_u64_u64_div_u64.c
+++ b/lib/math/test_mul_u64_u64_div_u64.c
@@ -157,6 +157,7 @@ static void __exit test_exit(void)
 #define __div64_32 __div64_32
 #define div_s64_rem div_s64_rem
 #define div64_u64_rem div64_u64_rem
+#define div64_s64_rem div64_s64_rem
 #define div64_u64 div64_u64
 #define div64_s64 div64_s64
 #define iter_div_u64_rem iter_div_u64_rem

---
base-commit: a50909aa46dec46de3c73235fc15a7d6f763d996
change-id: 20260615-test-mul-div-u64-fixup-501594e578b4

Best regards,
-- 
Rodrigo Alencar <rodrigo.alencar@analog.com>

