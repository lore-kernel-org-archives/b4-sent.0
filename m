From: Vincent Mailhol <mailhol.vincent@wanadoo.fr>
Date: Sat, 22 Mar 2025 18:23:12 +0900
Subject: [PATCH v7 1/5] bits: introduce fixed-type GENMASK_U*()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250322-fixed-type-genmasks-v7-1-da380ff1c5b9@wanadoo.fr>
References: <20250322-fixed-type-genmasks-v7-0-da380ff1c5b9@wanadoo.fr>
In-Reply-To: <20250322-fixed-type-genmasks-v7-0-da380ff1c5b9@wanadoo.fr>
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
 Andy Shevchenko <andriy.shevchenko@linux.intel.com>, 
 Jani Nikula <jani.nikula@intel.com>, 
 Vincent Mailhol <mailhol.vincent@wanadoo.fr>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=6346;
 i=mailhol.vincent@wanadoo.fr; h=from:subject:message-id;
 bh=H6EVGTMFrJBD0BwQz7pCCSuZTsJFcePLWSVIjCdGvXE=;
 b=owGbwMvMwCV2McXO4Xp97WbG02pJDOn3Gtde2+1v1nxEf4F+zeI94jPc4968UvMWzmgI477QZ
 H2rUM2po5SFQYyLQVZMkWVZOSe3Qkehd9ihv5Ywc1iZQIYwcHEKwERUbzIy7O3kMXO/Yb1M5cre
 TWe6jk/n/sguLd62K8pt+XdnY583cQz/jPrUQiue7ORie8KhFKY3q2ZCaPrdVx+W/VrrXbu6nN2
 BDwA=
X-Developer-Key: i=mailhol.vincent@wanadoo.fr; a=openpgp;
 fpr=ED8F700574E67F20E574E8E2AB5FEB886DBB99C2
X-Endpoint-Received: by B4 Relay for mailhol.vincent@wanadoo.fr/default with auth_id=291
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add GENMASK_TYPE() which generalizes __GENMASK() to support different
types, and implement fixed-types versions of GENMASK() based on it.
The fixed-type version allows more strict checks to the min/max values
accepted, which is useful for defining registers like implemented by
i915 and xe drivers with their REG_GENMASK*() macros.

The strict checks rely on shift-count-overflow compiler check to fail
the build if a number outside of the range allowed is passed.
Example:

  #define FOO_MASK GENMASK_U32(33, 4)

will generate a warning like:

  include/linux/bits.h:51:27: error: right shift count >= width of type [-Werror=shift-count-overflow]
     51 |               type_max(t) >> (BITS_PER_TYPE(t) - 1 - (h)))))
        |                           ^~

While GENMASK_TYPE() is crafted to cover all variants, including the
already existing GENMASK(), GENMASK_ULL() and GENMASK_U128(), for the
moment, only use it for the newly introduced GENMASK_U*(). The
consolidation will be done in a separate change.

Co-developed-by: Yury Norov <yury.norov@gmail.com>
Signed-off-by: Yury Norov <yury.norov@gmail.com>
Signed-off-by: Lucas De Marchi <lucas.demarchi@intel.com>
Acked-by: Jani Nikula <jani.nikula@intel.com>
Signed-off-by: Vincent Mailhol <mailhol.vincent@wanadoo.fr>
---
Changelog:

  v6 -> v7:

    - Fix grammar in comment: 'GENMASK_U*() depends' -> 'GENMASK_U*()
      depend'.

    - Fix typo in comment: 'Nethertheless' -> 'Nevertheless'

    - Do an artificial early line wrap in comment so that the next
      patch only has a one line diff change.

    - Re-wrap the comments to the 80th column.

    - The patch changed a lot since Yury first version: put myself as
      main author and Yury as Co-developer.

    - Add a new paragraph to the patch description to explain that
      consolidation will be done later.

  v5 -> v6:

    - No changes.

  v4 -> v5:

    - Rename GENMASK_t() to GENMASK_TYPE().

    - Fix typo in patch description.

    - Use tab indentations instead of single space to separate the
      macro name from its body.

    - s/__GENMASK_U*()/GENMASK_U*()/g in the comment.

    - Add a tag to credit myself as Co-developer. Keep Yury as the
      main author.

    - Modify GENMASK_TYPE() to match the changes made to __GENMASK()
      in: https://github.com/norov/linux/commit/1e7933a575ed

    - Replace (t)~_ULL(0) with type_max(t). This is OK because
      GENMASK_TYPE() is not available in asm.

    - linux/const.h and asm/bitsperlong.h are not used anymore. Remove
      them.

    - Apply GENMASK_TYPE() to GENMASK_U128().

    - Remove the unsigned int cast for the U8 and U16 variants. Cast
      to the target type instead. Do that cast directly in
      GENMASK_TYPE().

  v3 -> v4:

    - The v3 is one year old. Meanwhile people started using
      __GENMASK() directly. So instead of generalizing __GENMASK() to
      support different types, add a new GENMASK_t().

    - replace ~0ULL by ~_ULL(0). Otherwise, GENMASK_t() would fail in
      asm code.

    - Make GENMASK_U8() and GENMASK_U16() return an unsigned int. In
      v3, due to the integer promotion rules, these were returning a
      signed integer. By casting these to unsigned int, at least the
      signedness is kept.
---
 include/linux/bitops.h |  1 -
 include/linux/bits.h   | 39 +++++++++++++++++++++++++++++++++++++--
 2 files changed, 37 insertions(+), 3 deletions(-)

diff --git a/include/linux/bitops.h b/include/linux/bitops.h
index c1cb53cf2f0f8662ed3e324578f74330e63f935d..9be2d50da09a417966b3d11c84092bb2f4cd0bef 100644
--- a/include/linux/bitops.h
+++ b/include/linux/bitops.h
@@ -8,7 +8,6 @@
 
 #include <uapi/linux/kernel.h>
 
-#define BITS_PER_TYPE(type)	(sizeof(type) * BITS_PER_BYTE)
 #define BITS_TO_LONGS(nr)	__KERNEL_DIV_ROUND_UP(nr, BITS_PER_TYPE(long))
 #define BITS_TO_U64(nr)		__KERNEL_DIV_ROUND_UP(nr, BITS_PER_TYPE(u64))
 #define BITS_TO_U32(nr)		__KERNEL_DIV_ROUND_UP(nr, BITS_PER_TYPE(u32))
diff --git a/include/linux/bits.h b/include/linux/bits.h
index 14fd0ca9a6cd17339dd2f69e449558312a8a001b..beb3ee2f1bc74a9346dd72eb06c722a9bc536051 100644
--- a/include/linux/bits.h
+++ b/include/linux/bits.h
@@ -12,6 +12,7 @@
 #define BIT_ULL_MASK(nr)	(ULL(1) << ((nr) % BITS_PER_LONG_LONG))
 #define BIT_ULL_WORD(nr)	((nr) / BITS_PER_LONG_LONG)
 #define BITS_PER_BYTE		8
+#define BITS_PER_TYPE(type)	(sizeof(type) * BITS_PER_BYTE)
 
 /*
  * Create a contiguous bitmask starting at bit position @l and ending at
@@ -19,16 +20,50 @@
  * GENMASK_ULL(39, 21) gives us the 64bit vector 0x000000ffffe00000.
  */
 #if !defined(__ASSEMBLY__)
+
+/*
+ * Missing asm support
+ *
+ * GENMASK_U*() depend on BITS_PER_TYPE() which relies on sizeof(),
+ * something not available in asm. Nevertheless, fixed width integers is a C
+ * concept. Assembly code can rely on the long and long long versions instead.
+ */
+
 #include <linux/build_bug.h>
 #include <linux/compiler.h>
+#include <linux/overflow.h>
+
 #define GENMASK_INPUT_CHECK(h, l) BUILD_BUG_ON_ZERO(const_true((l) > (h)))
-#else
+
+/*
+ * Generate a mask for the specified type @t. Additional checks are made to
+ * guarantee the value returned fits in that type, relying on
+ * shift-count-overflow compiler check to detect incompatible arguments.
+ * For example, all these create build errors or warnings:
+ *
+ * - GENMASK(15, 20): wrong argument order
+ * - GENMASK(72, 15): doesn't fit unsigned long
+ * - GENMASK_U32(33, 15): doesn't fit in a u32
+ */
+#define GENMASK_TYPE(t, h, l)					\
+	((t)(GENMASK_INPUT_CHECK(h, l) +			\
+	     (type_max(t) << (l) &				\
+	      type_max(t) >> (BITS_PER_TYPE(t) - 1 - (h)))))
+
+#define GENMASK_U8(h, l)	GENMASK_TYPE(u8, h, l)
+#define GENMASK_U16(h, l)	GENMASK_TYPE(u16, h, l)
+#define GENMASK_U32(h, l)	GENMASK_TYPE(u32, h, l)
+#define GENMASK_U64(h, l)	GENMASK_TYPE(u64, h, l)
+
+#else /* defined(__ASSEMBLY__) */
+
 /*
  * BUILD_BUG_ON_ZERO is not available in h files included from asm files,
  * disable the input check if that is the case.
  */
 #define GENMASK_INPUT_CHECK(h, l) 0
-#endif
+
+#endif /* !defined(__ASSEMBLY__) */
 
 #define GENMASK(h, l) \
 	(GENMASK_INPUT_CHECK(h, l) + __GENMASK(h, l))

-- 
2.48.1

