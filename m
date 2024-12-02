From: Vincent Mailhol <mailhol.vincent@wanadoo.fr>
Date: Tue, 03 Dec 2024 02:33:23 +0900
Subject: [PATCH 01/10] compiler.h: add statically_false()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241203-is_constexpr-refactor-v1-1-4e4cbaecc216@wanadoo.fr>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1089;
 i=mailhol.vincent@wanadoo.fr; h=from:subject:message-id;
 bh=MUJOQQOOJL9dYDVaPT65KhZRSmD+ZVJ1pjvxSAixArY=;
 b=owGbwMvMwCV2McXO4Xp97WbG02pJDOm+74/KH7/U7qegXjXTofXb3TYljXrmuVYbMjW/tLXe4
 w0P49vQUcrCIMbFICumyLKsnJNboaPQO+zQX0uYOaxMIEMYuDgFYCKiExj+h59n32w4XUS9Q6Hd
 rUTL9LrKv/cufhltT6M9vi38WfriOSPDth1s9Y4XTgudV69oFplrmhzR2RRm0jljjlHtl08TxWX
 ZAQ==
X-Developer-Key: i=mailhol.vincent@wanadoo.fr; a=openpgp;
 fpr=ED8F700574E67F20E574E8E2AB5FEB886DBB99C2
X-Endpoint-Received: by B4 Relay for mailhol.vincent@wanadoo.fr/default with auth_id=291
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

For completion, add statically_false() which is the equivalent of
statically_true() except that it will return true only if the input is
known to be false at compile time.

The == operator is used instead of the ! negation to prevent a
-Wint-in-bool-context compiler warning when the argument is not a
boolean. For example:

  statically_false(var * 0)

Signed-off-by: Vincent Mailhol <mailhol.vincent@wanadoo.fr>
---
 include/linux/compiler.h | 1 +
 1 file changed, 1 insertion(+)

diff --git a/include/linux/compiler.h b/include/linux/compiler.h
index 469a64dd6495fefab2c85ffc279568a657b72660..a2a56a50dd85227a4fdc62236a2710ca37c5ba52 100644
--- a/include/linux/compiler.h
+++ b/include/linux/compiler.h
@@ -314,6 +314,7 @@ static inline void *offset_to_ptr(const int *off)
  * values to determine that the condition is statically true.
  */
 #define statically_true(x) (__builtin_constant_p(x) && (x))
+#define statically_false(x) (__builtin_constant_p(x) && (x) == 0)
 
 /*
  * This is needed in functions which generate the stack canary, see

-- 
2.45.2

