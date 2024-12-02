From: Vincent Mailhol <mailhol.vincent@wanadoo.fr>
Date: Tue, 03 Dec 2024 02:33:27 +0900
Subject: [PATCH 05/10] minmax: simplify __clamp_once() by using
 is_const_false()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241203-is_constexpr-refactor-v1-5-4e4cbaecc216@wanadoo.fr>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1058;
 i=mailhol.vincent@wanadoo.fr; h=from:subject:message-id;
 bh=ktV9jrZU0giaHV9vBo3GiXQr/Qxl6VWxrueXUQe+OfY=;
 b=owGbwMvMwCV2McXO4Xp97WbG02pJDOm+74+eev1x37SU7/s4fOZsfexXwSuwUZXlqNClRp+XD
 71fb+e91lHKwiDGxSArpsiyrJyTW6Gj0Dvs0F9LmDmsTCBDGLg4BWAit84y/BX7aL9/YU3XnR7j
 ixp8Oy/Oeb/9EFPOXNM1rhuKog5yzH/PyPD2dPyivxyLOtx7gqSDZL8HtSqF7j576ccC5tVXdN5
 +EmADAA==
X-Developer-Key: i=mailhol.vincent@wanadoo.fr; a=openpgp;
 fpr=ED8F700574E67F20E574E8E2AB5FEB886DBB99C2
X-Endpoint-Received: by B4 Relay for mailhol.vincent@wanadoo.fr/default with auth_id=291
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

In __clamp_once(),

  __builtin_choose_expr(__is_constexpr((lo) > (hi)), (lo) <= (hi), true)

is equivalent to:

  !is_const_false((lo) <= (hi))

Apply is_const_false() to simplify __clamp_once().

Signed-off-by: Vincent Mailhol <mailhol.vincent@wanadoo.fr>
---
 include/linux/minmax.h | 3 +--
 1 file changed, 1 insertion(+), 2 deletions(-)

diff --git a/include/linux/minmax.h b/include/linux/minmax.h
index 98008dd92153db10c672155bca93201ffabee994..431bf76ac460a11a2e4af23acd90c0d26e99c862 100644
--- a/include/linux/minmax.h
+++ b/include/linux/minmax.h
@@ -111,8 +111,7 @@
 	__auto_type uval = (val);						\
 	__auto_type ulo = (lo);							\
 	__auto_type uhi = (hi);							\
-	static_assert(__builtin_choose_expr(__is_constexpr((lo) > (hi)), 	\
-			(lo) <= (hi), true),					\
+	static_assert(!is_const_false((lo) <= (hi)),				\
 		"clamp() low limit " #lo " greater than high limit " #hi);	\
 	BUILD_BUG_ON_MSG(!__types_ok3(val,lo,hi,uval,ulo,uhi),			\
 		"clamp("#val", "#lo", "#hi") signedness error");		\

-- 
2.45.2

