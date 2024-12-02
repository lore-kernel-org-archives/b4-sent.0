From: Vincent Mailhol <mailhol.vincent@wanadoo.fr>
Date: Tue, 03 Dec 2024 02:33:31 +0900
Subject: [PATCH 09/10] coresight: etm4x: replace __is_const_expr() by
 is_const()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241203-is_constexpr-refactor-v1-9-4e4cbaecc216@wanadoo.fr>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1152;
 i=mailhol.vincent@wanadoo.fr; h=from:subject:message-id;
 bh=2a9e0Sg1+HnRtDgEsb84OXVQoFxUHpuXTO0qI7avR5g=;
 b=owGbwMvMwCV2McXO4Xp97WbG02pJDOm+749O6FPas2ybatTeWc7prF16x3VX6XbM9TgktOrU7
 v8zpTx3dZSyMIhxMciKKbIsK+fkVugo9A479NcSZg4rE8gQBi5OAZjIEUmGf4rH5jmVbpEP/Ddj
 A+/Sm/sTG/nmCVoanpxpWRL3vYGNfyIjQ/eqI0k+TNe37ZmStZpB6ZREi/BkBbfsadXL0zZxGHr
 +5wYA
X-Developer-Key: i=mailhol.vincent@wanadoo.fr; a=openpgp;
 fpr=ED8F700574E67F20E574E8E2AB5FEB886DBB99C2
X-Endpoint-Received: by B4 Relay for mailhol.vincent@wanadoo.fr/default with auth_id=291
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

is_const() is a one to one replacement of __is_constexpr(). Do the
replacement so that __is_constexpr() can be removed.

Refer to [1] for an explaination of why __builtin_constant_p() can not
be used as a replacement here.

[1] commit 4d45bc82df66 ("coresight: etm4x: avoid build failure with unrolled loops")
Link: https://git.kernel.org/torvalds/c/4d45bc82df66

Signed-off-by: Vincent Mailhol <mailhol.vincent@wanadoo.fr>
---
 drivers/hwtracing/coresight/coresight-etm4x.h | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/hwtracing/coresight/coresight-etm4x.h b/drivers/hwtracing/coresight/coresight-etm4x.h
index 9e9165f62e81fe5a87d35b4e30bc23f93cb211ec..91cf81ac46f44418f76783c102477d08f9abc70f 100644
--- a/drivers/hwtracing/coresight/coresight-etm4x.h
+++ b/drivers/hwtracing/coresight/coresight-etm4x.h
@@ -492,7 +492,7 @@
 	({									\
 		u64 __val;							\
 										\
-		if (__is_constexpr((offset)))					\
+		if (is_const(offset))						\
 			__val = read_etm4x_sysreg_const_offset((offset));	\
 		else								\
 			__val = etm4x_sysreg_read((offset), true, (_64bit));	\

-- 
2.45.2

