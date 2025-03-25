From: Vincent Mailhol <mailhol.vincent@wanadoo.fr>
Date: Wed, 26 Mar 2025 00:59:59 +0900
Subject: [PATCH v8 4/6] drm/i915: Convert REG_GENMASK*() to fixed-width
 GENMASK_U*()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250326-fixed-type-genmasks-v8-4-24afed16ca00@wanadoo.fr>
References: <20250326-fixed-type-genmasks-v8-0-24afed16ca00@wanadoo.fr>
In-Reply-To: <20250326-fixed-type-genmasks-v8-0-24afed16ca00@wanadoo.fr>
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
 Catalin Marinas <catalin.marinas@arm.com>, 
 Anshuman Khandual <anshuman.khandual@arm.com>, 
 linux-arm-kernel@lists.infradead.org, Jani Nikula <jani.nikula@intel.com>, 
 Vincent Mailhol <mailhol.vincent@wanadoo.fr>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=5740;
 i=mailhol.vincent@wanadoo.fr; h=from:subject:message-id;
 bh=1ou22BtqXrIJAaAiPkSG694MjDxDXtsfNMr9EFCnSzs=;
 b=owGbwMvMwCV2McXO4Xp97WbG02pJDOmPLqtfykv8x2G4K39lrNPn+haX/mJeHdOUXdpfTCId1
 q06cupPRykLgxgXg6yYIsuyck5uhY5C77BDfy1h5rAygQxh4OIUgIloejEy3BSpUn6ttPkIw6qp
 12Qs004ErJ0k3q1Vlip2qYtJ4SbzfUaGlTlZaxMzTm9vzn78w9Ztw/zCzSxbWbIKfio9miVQPPs
 xAwA=
X-Developer-Key: i=mailhol.vincent@wanadoo.fr; a=openpgp;
 fpr=ED8F700574E67F20E574E8E2AB5FEB886DBB99C2
X-Endpoint-Received: by B4 Relay for mailhol.vincent@wanadoo.fr/default with auth_id=291
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Lucas De Marchi <lucas.demarchi@intel.com>

Now that include/linux/bits.h implements fixed-width GENMASK_U*(), use
them to implement the i915/xe specific macros. Converting each driver
to use the generic macros are left for later, when/if other
driver-specific macros are also generalized.

Signed-off-by: Lucas De Marchi <lucas.demarchi@intel.com>
Acked-by: Jani Nikula <jani.nikula@intel.com>
Signed-off-by: Vincent Mailhol <mailhol.vincent@wanadoo.fr>
---
Changelog:

  v7 -> v8:

    - No changes.

  v6 -> v7:

    - Replace BIT_* and GENMASK_* by BIT_U*() and GENMASK_U*() in the
      description.

    - Add the information in the description that BIT_U*() and
      GENMASK_U*() are fixed width.

  v5 -> v6:

    - No changes.

  v4 -> v5:

    - Add brackets to macro names in patch description,
      e.g. 'REG_GENMASK*' -> 'REG_GENMASK*()'

  v3 -> v4:

    - Remove the prefixes in macro parameters,
      e.g. 'REG_GENMASK(__high, __low)' -> 'REG_GENMASK(high, low)'
---
 drivers/gpu/drm/i915/i915_reg_defs.h | 108 ++++-------------------------------
 1 file changed, 11 insertions(+), 97 deletions(-)

diff --git a/drivers/gpu/drm/i915/i915_reg_defs.h b/drivers/gpu/drm/i915/i915_reg_defs.h
index e251bcc0c89f5710125bc70f07851b2cb978c89c..e0bc9cf5fa9ed98f7d36f6cb667999aa6522c384 100644
--- a/drivers/gpu/drm/i915/i915_reg_defs.h
+++ b/drivers/gpu/drm/i915/i915_reg_defs.h
@@ -9,76 +9,19 @@
 #include <linux/bitfield.h>
 #include <linux/bits.h>
 
-/**
- * REG_BIT() - Prepare a u32 bit value
- * @__n: 0-based bit number
- *
- * Local wrapper for BIT() to force u32, with compile time checks.
- *
- * @return: Value with bit @__n set.
+/*
+ * Wrappers over the generic fixed width BIT_U*() and GENMASK_U*()
+ * implementations, for compatibility reasons with previous implementation.
  */
-#define REG_BIT(__n)							\
-	((u32)(BIT(__n) +						\
-	       BUILD_BUG_ON_ZERO(__is_constexpr(__n) &&		\
-				 ((__n) < 0 || (__n) > 31))))
+#define REG_GENMASK(high, low)		GENMASK_U32(high, low)
+#define REG_GENMASK64(high, low)	GENMASK_U64(high, low)
+#define REG_GENMASK16(high, low)	GENMASK_U16(high, low)
+#define REG_GENMASK8(high, low)		GENMASK_U8(high, low)
 
-/**
- * REG_BIT8() - Prepare a u8 bit value
- * @__n: 0-based bit number
- *
- * Local wrapper for BIT() to force u8, with compile time checks.
- *
- * @return: Value with bit @__n set.
- */
-#define REG_BIT8(__n)                                                   \
-	((u8)(BIT(__n) +                                                \
-	       BUILD_BUG_ON_ZERO(__is_constexpr(__n) &&         \
-				 ((__n) < 0 || (__n) > 7))))
-
-/**
- * REG_GENMASK() - Prepare a continuous u32 bitmask
- * @__high: 0-based high bit
- * @__low: 0-based low bit
- *
- * Local wrapper for GENMASK() to force u32, with compile time checks.
- *
- * @return: Continuous bitmask from @__high to @__low, inclusive.
- */
-#define REG_GENMASK(__high, __low)					\
-	((u32)(GENMASK(__high, __low) +					\
-	       BUILD_BUG_ON_ZERO(__is_constexpr(__high) &&	\
-				 __is_constexpr(__low) &&		\
-				 ((__low) < 0 || (__high) > 31 || (__low) > (__high)))))
-
-/**
- * REG_GENMASK64() - Prepare a continuous u64 bitmask
- * @__high: 0-based high bit
- * @__low: 0-based low bit
- *
- * Local wrapper for GENMASK_ULL() to force u64, with compile time checks.
- *
- * @return: Continuous bitmask from @__high to @__low, inclusive.
- */
-#define REG_GENMASK64(__high, __low)					\
-	((u64)(GENMASK_ULL(__high, __low) +				\
-	       BUILD_BUG_ON_ZERO(__is_constexpr(__high) &&		\
-				 __is_constexpr(__low) &&		\
-				 ((__low) < 0 || (__high) > 63 || (__low) > (__high)))))
-
-/**
- * REG_GENMASK8() - Prepare a continuous u8 bitmask
- * @__high: 0-based high bit
- * @__low: 0-based low bit
- *
- * Local wrapper for GENMASK() to force u8, with compile time checks.
- *
- * @return: Continuous bitmask from @__high to @__low, inclusive.
- */
-#define REG_GENMASK8(__high, __low)                                     \
-	((u8)(GENMASK(__high, __low) +                                  \
-	       BUILD_BUG_ON_ZERO(__is_constexpr(__high) &&      \
-				 __is_constexpr(__low) &&               \
-				 ((__low) < 0 || (__high) > 7 || (__low) > (__high)))))
+#define REG_BIT(n)			BIT_U32(n)
+#define REG_BIT64(n)			BIT_U64(n)
+#define REG_BIT16(n)			BIT_U16(n)
+#define REG_BIT8(n)			BIT_U8(n)
 
 /*
  * Local integer constant expression version of is_power_of_2().
@@ -143,35 +86,6 @@
  */
 #define REG_FIELD_GET64(__mask, __val)	((u64)FIELD_GET(__mask, __val))
 
-/**
- * REG_BIT16() - Prepare a u16 bit value
- * @__n: 0-based bit number
- *
- * Local wrapper for BIT() to force u16, with compile time
- * checks.
- *
- * @return: Value with bit @__n set.
- */
-#define REG_BIT16(__n)                                                   \
-	((u16)(BIT(__n) +                                                \
-	       BUILD_BUG_ON_ZERO(__is_constexpr(__n) &&         \
-				 ((__n) < 0 || (__n) > 15))))
-
-/**
- * REG_GENMASK16() - Prepare a continuous u8 bitmask
- * @__high: 0-based high bit
- * @__low: 0-based low bit
- *
- * Local wrapper for GENMASK() to force u16, with compile time
- * checks.
- *
- * @return: Continuous bitmask from @__high to @__low, inclusive.
- */
-#define REG_GENMASK16(__high, __low)                                     \
-	((u16)(GENMASK(__high, __low) +                                  \
-	       BUILD_BUG_ON_ZERO(__is_constexpr(__high) &&      \
-				 __is_constexpr(__low) &&               \
-				 ((__low) < 0 || (__high) > 15 || (__low) > (__high)))))
 
 /**
  * REG_FIELD_PREP16() - Prepare a u16 bitfield value

-- 
2.48.1

