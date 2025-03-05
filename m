From: Vincent Mailhol <mailhol.vincent@wanadoo.fr>
Date: Wed, 05 Mar 2025 22:00:20 +0900
Subject: [PATCH v4 8/8] test_bits: add tests for fixed-type BIT
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250305-fixed-type-genmasks-v4-8-1873dcdf6723@wanadoo.fr>
References: <20250305-fixed-type-genmasks-v4-0-1873dcdf6723@wanadoo.fr>
In-Reply-To: <20250305-fixed-type-genmasks-v4-0-1873dcdf6723@wanadoo.fr>
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
 Vincent Mailhol <mailhol.vincent@wanadoo.fr>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1258;
 i=mailhol.vincent@wanadoo.fr; h=from:subject:message-id;
 bh=0up3uFESGy3X95xnLn4wawoX+zEk4W6rPzSDoRogONM=;
 b=owGbwMvMwCV2McXO4Xp97WbG02pJDOknvLnbrFb2/uWTiXxxiKelgVuB/1Bj79+Qksmtweq5U
 ZtjJ23uKGVhEONikBVTZFlWzsmt0FHoHXboryXMHFYmkCEMXJwCMJFd3xgZXvMzMBya4yV9OIC9
 b7bGwd/2IlcOnjIVb5j4Y637ik9mQBXnHqX5CYqk2T6bffkdm1/YSdOTftnrDwVoh2283qRxgYs
 TAA==
X-Developer-Key: i=mailhol.vincent@wanadoo.fr; a=openpgp;
 fpr=ED8F700574E67F20E574E8E2AB5FEB886DBB99C2
X-Endpoint-Received: by B4 Relay for mailhol.vincent@wanadoo.fr/default with auth_id=291
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add some additional tests in lib/test_bits.c to cover the expected
results of the BIT_U*() macros.

Signed-off-by: Vincent Mailhol <mailhol.vincent@wanadoo.fr>
---
 lib/test_bits.c | 10 ++++++++++
 1 file changed, 10 insertions(+)

diff --git a/lib/test_bits.c b/lib/test_bits.c
index c3a40995a2577322252371eb10ada0c33fb5d9b4..641001a04f21bc3b788ae05c6d2eaaba9052e463 100644
--- a/lib/test_bits.c
+++ b/lib/test_bits.c
@@ -9,6 +9,16 @@
 
 #define assert_type(t, x) _Generic(x, t: x, default: 0)
 
+static_assert(assert_type(unsigned int, BIT_U8(0)) == 1u);
+static_assert(assert_type(unsigned int, BIT_U16(0)) == 1u);
+static_assert(assert_type(u32, BIT_U32(0)) == 1u);
+static_assert(assert_type(u64, BIT_U64(0)) == 1ull);
+
+static_assert(assert_type(unsigned int, BIT_U8(7)) == 0x80u);
+static_assert(assert_type(unsigned int, BIT_U16(15)) == 0x8000u);
+static_assert(assert_type(u32, BIT_U32(31)) == 0x80000000u);
+static_assert(assert_type(u64, BIT_U64(63)) == 0x8000000000000000ull);
+
 static_assert(assert_type(unsigned long, GENMASK(31, 0)) == U32_MAX);
 static_assert(assert_type(unsigned long long, GENMASK_ULL(63, 0)) == U64_MAX);
 static_assert(assert_type(unsigned int, GENMASK_U8(7, 0)) == U8_MAX);

-- 
2.45.3

