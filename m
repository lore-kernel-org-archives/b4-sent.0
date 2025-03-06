From: Vincent Mailhol <mailhol.vincent@wanadoo.fr>
Date: Thu, 06 Mar 2025 20:29:54 +0900
Subject: [PATCH v5 3/7] bits: introduce fixed-type BIT_U*()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250306-fixed-type-genmasks-v5-3-b443e9dcba63@wanadoo.fr>
References: <20250306-fixed-type-genmasks-v5-0-b443e9dcba63@wanadoo.fr>
In-Reply-To: <20250306-fixed-type-genmasks-v5-0-b443e9dcba63@wanadoo.fr>
To: Yury Norov <yury.norov@gmail.com>, 
 Lucas De Marchi <lucas.demarchi@intel.com>, 
 Rasmus Villemoes <linux@rasmusvillemoes.dk>, 
 Jani Nikula <jani.nikula@linux.intel.com>, 
 Joonas Lahtinen <joonas.lahtinen@linux.intel.com>, 
 Rodrigo Vivi <rodrigo.vivi@intel.com>, 
 Tvrtko Ursulin <tursulin@ursulin.net>, David Airlie <airlied@gmail.com>, 
 Simona Vetter <simona@ffwll.ch>, Andrew Morton <akpm@linux-foundation.org>
Cc: linux-kernel@vger.kernel.org, intel-gfx@lists.freedesktop.org, 
 dri-devel@lists.freedesktop.org, Andi Shyti <andi.shyti@linux.intel.com>, 
 David Laight <David.Laight@ACULAB.COM>, 
 Dmitry Baryshkov <dmitry.baryshkov@linaro.org>, 
 Andy Shevchenko <andriy.shevchenko@linux.intel.com>, 
 Jani Nikula <jani.nikula@intel.com>, 
 Vincent Mailhol <mailhol.vincent@wanadoo.fr>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=3125;
 i=mailhol.vincent@wanadoo.fr; h=from:subject:message-id;
 bh=/aH+fGg36Lo9Rl+YyRZ1Ip9fOrVONt1J6ojSjr5THkA=;
 b=owGbwMvMwCV2McXO4Xp97WbG02pJDOkn27PuLgnIWnpISCc95NZegW2f/9r/fhPBuGSKzX6OB
 cuaBTZP7ShlYRDjYpAVU2RZVs7JrdBR6B126K8lzBxWJpAhDFycAjARD39Ghu/7OxTMDJJYNje9
 nKJ9oX3Tek/uqBWL1N2n7hM4595xPpDhf4XZjzUMr9pWzJ22+7tq370d98UdJld96WC1ODo5zuT
 If3YA
X-Developer-Key: i=mailhol.vincent@wanadoo.fr; a=openpgp;
 fpr=ED8F700574E67F20E574E8E2AB5FEB886DBB99C2
X-Endpoint-Received: by B4 Relay for mailhol.vincent@wanadoo.fr/default with auth_id=291
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Lucas De Marchi <lucas.demarchi@intel.com>

Implement fixed-type BIT_U*() to help drivers add stricter checks,
like was done for GENMASK_U*().

Signed-off-by: Lucas De Marchi <lucas.demarchi@intel.com>
Acked-by: Jani Nikula <jani.nikula@intel.com>
Co-developed-by: Vincent Mailhol <mailhol.vincent@wanadoo.fr>
Signed-off-by: Vincent Mailhol <mailhol.vincent@wanadoo.fr>
---
Changelog:

  v4 -> v5:

    - Rename GENMASK_t() to GENMASK_TYPE().

    - Use tab indentations instead of single space to separate the
      macro name from its body.

    - Add a global comment at the beginning of the file to explain why
      GENMASK_U*() and BIT_U*() are not available in asm.

    - Add a new BIT_TYPE() helper function, similar to GENMASK_TYPE().

    - Remove the unsigned int cast for the U8 and U16 variants. Move
      the cast to BIT_TYPE().

    - Rename the argument from BIT_U*(b) to BIT_U=(nr) for consistency
      with vdso/bits.h.

  v3 -> v4:

    - Use const_true() to simplify BIT_INPUT_CHECK().

    - Make BIT_U8() and BIT_U16() return an unsigned int instead of a
      u8 and u16. Because of the integer promotion rules in C, an u8
      or an u16 would become a signed integer as soon as these are
      used in any expression. By casting these to unsigned ints, at
      least the signedness is kept.

    - Put the cast next to the BIT() macro.

    - In BIT_U64(): use BIT_ULL() instead of BIT().
---
 include/linux/bits.h | 26 ++++++++++++++++++++++----
 1 file changed, 22 insertions(+), 4 deletions(-)

diff --git a/include/linux/bits.h b/include/linux/bits.h
index 74219521a56e2639ccff7fdc899d6805ee355a0c..f95e7815cb18636cc47ac17ef66d1bd6668e6819 100644
--- a/include/linux/bits.h
+++ b/include/linux/bits.h
@@ -22,10 +22,10 @@
 /*
  * Missing asm support
  *
- * GENMASK_U*() depends on BITS_PER_TYPE() which relies on sizeof(),
- * something not available in asm. Nethertheless, fixed width integers
- * is a C concept. Assembly code can rely on the long and long long
- * versions instead.
+ * GENMASK_U*() and BIT_U*() depend on BITS_PER_TYPE() which relies on
+ * sizeof(), something not available in asm. Nethertheless, fixed
+ * width integers is a C concept. Assembly code can rely on the long
+ * and long long versions instead.
  */
 
 #include <linux/build_bug.h>
@@ -58,6 +58,24 @@
 #define GENMASK_U64(h, l)	GENMASK_TYPE(u64, h, l)
 #define GENMASK_U128(h, l)	GENMASK_TYPE(u128, h, l)
 
+/*
+ * Fixed-type variants of BIT(), with additional checks like GENMASK_TYPE(). The
+ * following examples generate compiler warnings due to shift-count-overflow:
+ *
+ * - BIT_U8(8)
+ * - BIT_U32(-1)
+ * - BIT_U32(40)
+ */
+#define BIT_INPUT_CHECK(type, nr) \
+	BUILD_BUG_ON_ZERO(const_true((nr) >= BITS_PER_TYPE(type)))
+
+#define BIT_TYPE(type, nr) ((type)(BIT_INPUT_CHECK(type, nr) + BIT_ULL(nr)))
+
+#define BIT_U8(nr)	BIT_TYPE(u8, nr)
+#define BIT_U16(nr)	BIT_TYPE(u16, nr)
+#define BIT_U32(nr)	BIT_TYPE(u32, nr)
+#define BIT_U64(nr)	BIT_TYPE(u64, nr)
+
 #else /* defined(__ASSEMBLY__) */
 
 #define GENMASK(h, l)		__GENMASK(h, l)

-- 
2.45.3

