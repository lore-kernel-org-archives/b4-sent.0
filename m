From: Vincent Mailhol <mailhol.vincent@wanadoo.fr>
Date: Wed, 05 Mar 2025 22:00:13 +0900
Subject: [PATCH v4 1/8] bits: fix typo 'unsigned __init128' -> 'unsigned
 __int128'
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250305-fixed-type-genmasks-v4-1-1873dcdf6723@wanadoo.fr>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=880;
 i=mailhol.vincent@wanadoo.fr; h=from:subject:message-id;
 bh=OwRhvflyURxATxZcko1vxuJdGFTknPZsp+6vhXZr8YE=;
 b=owGbwMvMwCV2McXO4Xp97WbG02pJDOknvL7N+3ySo8NTU7DScMITxwmchcZbm/4cihU4M8dPw
 mvSidVTOkpZGMS4GGTFFFmWlXNyK3QUeocd+msJM4eVCWQIAxenAExEX4Phf2T/rL9/Pv794nb5
 +Ua+T2lfdugeviDXEML4ROTLXFa/vSsYGTadUTy/IEmr81Rqja7Fn7SrpqdXHIr6aLihs8v7/jI
 HBhYA
X-Developer-Key: i=mailhol.vincent@wanadoo.fr; a=openpgp;
 fpr=ED8F700574E67F20E574E8E2AB5FEB886DBB99C2
X-Endpoint-Received: by B4 Relay for mailhol.vincent@wanadoo.fr/default with auth_id=291
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

"int" was misspelled as "init" in GENMASK_U128() comments. Fix the typo.

Signed-off-by: Vincent Mailhol <mailhol.vincent@wanadoo.fr>
---
 include/linux/bits.h | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/include/linux/bits.h b/include/linux/bits.h
index 61a75d3f294bfa96267383b5e2fd2a5d4593fcee..14fd0ca9a6cd17339dd2f69e449558312a8a001b 100644
--- a/include/linux/bits.h
+++ b/include/linux/bits.h
@@ -40,7 +40,7 @@
  * Missing asm support
  *
  * __GENMASK_U128() depends on _BIT128() which would not work
- * in the asm code, as it shifts an 'unsigned __init128' data
+ * in the asm code, as it shifts an 'unsigned __int128' data
  * type instead of direct representation of 128 bit constants
  * such as long and unsigned long. The fundamental problem is
  * that a 128 bit constant will get silently truncated by the

-- 
2.45.3

