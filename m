From: Vincent Mailhol <mailhol.vincent@wanadoo.fr>
Date: Wed, 26 Mar 2025 01:00:00 +0900
Subject: [PATCH v8 5/6] test_bits: add tests for GENMASK_U*()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250326-fixed-type-genmasks-v8-5-24afed16ca00@wanadoo.fr>
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
 linux-arm-kernel@lists.infradead.org, 
 Vincent Mailhol <mailhol.vincent@wanadoo.fr>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2520;
 i=mailhol.vincent@wanadoo.fr; h=from:subject:message-id;
 bh=Nb/G0eCNCNsy7H+SqFg3vz5WdbZbgtEPSfg4VSWoDLg=;
 b=owGbwMvMwCV2McXO4Xp97WbG02pJDOmPLmuZWLx5XdtmddnzTrXHjbsRirLftRcHlV3ve82Ze
 PtK2PkLHaUsDGJcDLJiiizLyjm5FToKvcMO/bWEmcPKBDKEgYtTACaSsIaR4UTMnxXpZsEWv/zz
 O2U9jNom2c1a/K0zImnWe8t21YI39xj+52aEnPt9+sn5rB87ZMrPrgwo6FvdGd7VIdcZ4f990uc
 YVgA=
X-Developer-Key: i=mailhol.vincent@wanadoo.fr; a=openpgp;
 fpr=ED8F700574E67F20E574E8E2AB5FEB886DBB99C2
X-Endpoint-Received: by B4 Relay for mailhol.vincent@wanadoo.fr/default with auth_id=291
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Lucas De Marchi <lucas.demarchi@intel.com>

Add some additional tests in lib/tests/test_bits.c to cover the
expected/non-expected values of the fixed-type GENMASK_U*() macros.

Also check that the result value matches the expected type. Since
those are known at build time, use static_assert() instead of normal
kunit tests.

Signed-off-by: Lucas De Marchi <lucas.demarchi@intel.com>
Signed-off-by: Vincent Mailhol <mailhol.vincent@wanadoo.fr>
---
Changelog:

  v7 -> v8:

    - In commit db6fe4d61ece ("lib: Move KUnit tests into tests/
      subdirectory"), lib/test_bits.c was moved to
      lib/tests/test_bits.c. Adjust the patch descrption accordingly.

  v6 -> v7:
  v5 -> v6:

    - No changes.

  v4 -> v5:

    - Revert v4 change. GENMASK_U8()/GENMASK_U16() are now back to
      u8/u16.

  v3 -> v4:

    - Adjust the type of GENMASK_U8()/GENMASK_U16() from u8/u16 to
      unsigned int.

    - Reorder the tests to match the order in which the macros are
      declared in bits.h.
---
 lib/tests/test_bits.c | 20 ++++++++++++++++++++
 1 file changed, 20 insertions(+)

diff --git a/lib/tests/test_bits.c b/lib/tests/test_bits.c
index c7b38d91e1f16d42b7ca92e62fbd6c19b37e76a0..f443476f3265c463c1219b13c1ef9663d238d58b 100644
--- a/lib/tests/test_bits.c
+++ b/lib/tests/test_bits.c
@@ -5,6 +5,16 @@
 
 #include <kunit/test.h>
 #include <linux/bits.h>
+#include <linux/types.h>
+
+#define assert_type(t, x) _Generic(x, t: x, default: 0)
+
+static_assert(assert_type(unsigned long, GENMASK(31, 0)) == U32_MAX);
+static_assert(assert_type(unsigned long long, GENMASK_ULL(63, 0)) == U64_MAX);
+static_assert(assert_type(u8, GENMASK_U8(7, 0)) == U8_MAX);
+static_assert(assert_type(u16, GENMASK_U16(15, 0)) == U16_MAX);
+static_assert(assert_type(u32, GENMASK_U32(31, 0)) == U32_MAX);
+static_assert(assert_type(u64, GENMASK_U64(63, 0)) == U64_MAX);
 
 
 static void genmask_test(struct kunit *test)
@@ -14,11 +24,21 @@ static void genmask_test(struct kunit *test)
 	KUNIT_EXPECT_EQ(test, 6ul, GENMASK(2, 1));
 	KUNIT_EXPECT_EQ(test, 0xFFFFFFFFul, GENMASK(31, 0));
 
+	KUNIT_EXPECT_EQ(test, 1u, GENMASK_U8(0, 0));
+	KUNIT_EXPECT_EQ(test, 3u, GENMASK_U16(1, 0));
+	KUNIT_EXPECT_EQ(test, 0x10000, GENMASK_U32(16, 16));
+
 #ifdef TEST_GENMASK_FAILURES
 	/* these should fail compilation */
 	GENMASK(0, 1);
 	GENMASK(0, 10);
 	GENMASK(9, 10);
+
+	GENMASK_U32(0, 31);
+	GENMASK_U64(64, 0);
+	GENMASK_U32(32, 0);
+	GENMASK_U16(16, 0);
+	GENMASK_U8(8, 0);
 #endif
 
 

-- 
2.48.1

