From: Vincent Mailhol <mailhol.vincent@wanadoo.fr>
Date: Sat, 22 Mar 2025 18:23:16 +0900
Subject: [PATCH v7 5/5] test_bits: add tests for BIT_U*()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250322-fixed-type-genmasks-v7-5-da380ff1c5b9@wanadoo.fr>
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
 Vincent Mailhol <mailhol.vincent@wanadoo.fr>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1486;
 i=mailhol.vincent@wanadoo.fr; h=from:subject:message-id;
 bh=ZIzsmwCR7M/9F3S6iGoR6o+XM+b50ACvCduIf3sMObs=;
 b=owGbwMvMwCV2McXO4Xp97WbG02pJDOn3Gncc3C0demDBd7u6H+w84pwPnFzdLFeuCRYy/8x59
 obxQv5jHaUsDGJcDLJiiizLyjm5FToKvcMO/bWEmcPKBDKEgYtTACZy5DMjQ5NU+Z3di0y1pwis
 XFu1tZOjb/8hVmc3i6DCHW7i15yipBj+WS7aV3/p9RSFTofNiXGKKvWZRnl6hmur2UX7trO8mr+
 TAwA=
X-Developer-Key: i=mailhol.vincent@wanadoo.fr; a=openpgp;
 fpr=ED8F700574E67F20E574E8E2AB5FEB886DBB99C2
X-Endpoint-Received: by B4 Relay for mailhol.vincent@wanadoo.fr/default with auth_id=291
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add some additional tests in lib/test_bits.c to cover the expected
results of the fixed type BIT_U*() macros.

Signed-off-by: Vincent Mailhol <mailhol.vincent@wanadoo.fr>
Reviewed-by: Lucas De Marchi <lucas.demarchi@intel.com>
---
Changelog:

  v6 -> v7:

    - Add Lucas's Reviewed-by tag.

  v5 -> v6:

    - No changes.

  v4 -> v5:

    - BIT_U8()/BIT_U16() are now back to u8/u16.

  v3 -> v4:

    - New patch.
---
 lib/test_bits.c | 10 ++++++++++
 1 file changed, 10 insertions(+)

diff --git a/lib/test_bits.c b/lib/test_bits.c
index f443476f3265c463c1219b13c1ef9663d238d58b..47325b41515fde2c3ed434ed6f4094925c98886b 100644
--- a/lib/test_bits.c
+++ b/lib/test_bits.c
@@ -9,6 +9,16 @@
 
 #define assert_type(t, x) _Generic(x, t: x, default: 0)
 
+static_assert(assert_type(u8, BIT_U8(0)) == 1u);
+static_assert(assert_type(u16, BIT_U16(0)) == 1u);
+static_assert(assert_type(u32, BIT_U32(0)) == 1u);
+static_assert(assert_type(u64, BIT_U64(0)) == 1ull);
+
+static_assert(assert_type(u8, BIT_U8(7)) == 0x80u);
+static_assert(assert_type(u16, BIT_U16(15)) == 0x8000u);
+static_assert(assert_type(u32, BIT_U32(31)) == 0x80000000u);
+static_assert(assert_type(u64, BIT_U64(63)) == 0x8000000000000000ull);
+
 static_assert(assert_type(unsigned long, GENMASK(31, 0)) == U32_MAX);
 static_assert(assert_type(unsigned long long, GENMASK_ULL(63, 0)) == U64_MAX);
 static_assert(assert_type(u8, GENMASK_U8(7, 0)) == U8_MAX);

-- 
2.48.1

