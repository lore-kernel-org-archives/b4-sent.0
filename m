From: Vincent Mailhol <mailhol.vincent@wanadoo.fr>
Date: Tue, 03 Dec 2024 02:33:29 +0900
Subject: [PATCH 07/10] overflow: replace __is_constexpr() by is_const()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241203-is_constexpr-refactor-v1-7-4e4cbaecc216@wanadoo.fr>
References: <20241203-is_constexpr-refactor-v1-0-4e4cbaecc216@wanadoo.fr>
In-Reply-To: <20241203-is_constexpr-refactor-v1-0-4e4cbaecc216@wanadoo.fr>
To: Linus Torvalds <torvalds@linux-foundation.org>, 
 David Laight <David.Laight@aculab.com>, 
 Luc Van Oostenryck <luc.vanoostenryck@gmail.com>, 
 Nathan Chancellor <nathan@kernel.org>, 
 Nick Desaulniers <ndesaulniers@google.com>, 
 Bill Wendling <morbo@google.com>, Justin Stitt <justinstitt@google.com>, 
 Yury Norov <yury.norov@gmail.com>, 
 Rasmus Villemoes <linux@rasmusvillemoes.dk>, Kees Cook <kees@kernel.org>, 
 "Gustavo A. R. Silva" <gustavoars@kernel.org>, 
 Jani Nikula <jani.nikula@linux.intel.com>, 
 Joonas Lahtinen <joonas.lahtinen@linux.intel.com>, 
 Rodrigo Vivi <rodrigo.vivi@intel.com>, 
 Tvrtko Ursulin <tursulin@ursulin.net>, David Airlie <airlied@gmail.com>, 
 Simona Vetter <simona@ffwll.ch>, Suzuki K Poulose <suzuki.poulose@arm.com>, 
 Mike Leach <mike.leach@linaro.org>, James Clark <james.clark@linaro.org>, 
 Alexander Shishkin <alexander.shishkin@linux.intel.com>, 
 Rikard Falkeborn <rikard.falkeborn@gmail.com>, 
 Martin Uecker <Martin.Uecker@med.uni-goettingen.de>
Cc: linux-sparse@vger.kernel.org, linux-kernel@vger.kernel.org, 
 llvm@lists.linux.dev, linux-hardening@vger.kernel.org, 
 intel-gfx@lists.freedesktop.org, dri-devel@lists.freedesktop.org, 
 coresight@lists.linaro.org, linux-arm-kernel@lists.infradead.org, 
 Vincent Mailhol <mailhol.vincent@wanadoo.fr>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2119;
 i=mailhol.vincent@wanadoo.fr; h=from:subject:message-id;
 bh=3zhdAHGJKxe/cfP6gSQHSq0jEALX5ywlxJaLknSE8PU=;
 b=owGbwMvMwCV2McXO4Xp97WbG02pJDOm+74/q876MC9CKYjyo9Ky9cdPpsilBc38vnbBxvs6ZW
 UF5mtXRHaUsDGJcDLJiiizLyjm5FToKvcMO/bWEmcPKBDKEgYtTACbyQ5fhr7xK1ZyIKSviHgrp
 8+d4/NxvmD6DX/jspxv39qf9Nnzx8QYjw5+v16eWdS2+XNXV/TjVMnulR8GKU3Mazly4pdn98Ng
 OKx4A
X-Developer-Key: i=mailhol.vincent@wanadoo.fr; a=openpgp;
 fpr=ED8F700574E67F20E574E8E2AB5FEB886DBB99C2
X-Endpoint-Received: by B4 Relay for mailhol.vincent@wanadoo.fr/default with auth_id=291
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

is_const() is a one to one replacement of __is_constexpr(). Do the
replacement so that __is_constexpr() can be removed.

Signed-off-by: Vincent Mailhol <mailhol.vincent@wanadoo.fr>
---
 include/linux/overflow.h | 8 ++++----
 1 file changed, 4 insertions(+), 4 deletions(-)

diff --git a/include/linux/overflow.h b/include/linux/overflow.h
index 0c7e3dcfe8670cb95f371a6f7d41bb8b63b1786c..d69361a3128897d493b5e2ec471f077ca2b9861d 100644
--- a/include/linux/overflow.h
+++ b/include/linux/overflow.h
@@ -234,7 +234,7 @@ static inline bool __must_check __must_check_overflow(bool overflow)
  * Returns: true if overflow can occur, false otherwise.
  */
 #define overflows_type(n, T)					\
-	__builtin_choose_expr(__is_constexpr(n),		\
+	__builtin_choose_expr(is_const(n),			\
 			      __overflows_type_constexpr(n, T),	\
 			      __overflows_type(n, T))
 
@@ -250,7 +250,7 @@ static inline bool __must_check __must_check_overflow(bool overflow)
  * back to __same_type().
  */
 #define castable_to_type(n, T)						\
-	__builtin_choose_expr(__is_constexpr(n),			\
+	__builtin_choose_expr(is_const(n),				\
 			      !__overflows_type_constexpr(n, T),	\
 			      __same_type(n, T))
 
@@ -352,7 +352,7 @@ static inline size_t __must_check size_sub(size_t minuend, size_t subtrahend)
  * Return: number of bytes needed or SIZE_MAX on overflow.
  */
 #define flex_array_size(p, member, count)				\
-	__builtin_choose_expr(__is_constexpr(count),			\
+	__builtin_choose_expr(is_const(count),				\
 		(count) * sizeof(*(p)->member) + __must_be_array((p)->member),	\
 		size_mul(count, sizeof(*(p)->member) + __must_be_array((p)->member)))
 
@@ -368,7 +368,7 @@ static inline size_t __must_check size_sub(size_t minuend, size_t subtrahend)
  * Return: number of bytes needed or SIZE_MAX on overflow.
  */
 #define struct_size(p, member, count)					\
-	__builtin_choose_expr(__is_constexpr(count),			\
+	__builtin_choose_expr(is_const(count),				\
 		sizeof(*(p)) + flex_array_size(p, member, count),	\
 		size_add(sizeof(*(p)), flex_array_size(p, member, count)))
 

-- 
2.45.2

