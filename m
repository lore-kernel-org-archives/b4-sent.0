From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Thu, 04 Jun 2026 10:58:56 +0100
Subject: [PATCH v16 02/14] lib: kstrtox: Make _parse_integer() take
 variadic arguments
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260604-adf41513-iio-driver-v16-2-1a7d09143bc2@analog.com>
References: <20260604-adf41513-iio-driver-v16-0-1a7d09143bc2@analog.com>
In-Reply-To: <20260604-adf41513-iio-driver-v16-0-1a7d09143bc2@analog.com>
To: linux-kernel@vger.kernel.org, linux-iio@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-doc@vger.kernel.org, linux@analog.com
Cc: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, Andy Shevchenko <andy@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jonathan Corbet <corbet@lwn.net>, 
 Andrew Morton <akpm@linux-foundation.org>, Petr Mladek <pmladek@suse.com>, 
 Steven Rostedt <rostedt@goodmis.org>, 
 Andy Shevchenko <andriy.shevchenko@linux.intel.com>, 
 Rasmus Villemoes <linux@rasmusvillemoes.dk>, 
 Sergey Senozhatsky <senozhatsky@chromium.org>, 
 Shuah Khan <skhan@linuxfoundation.org>, 
 Rodrigo Alencar <rodrigo.alencar@analog.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780567181; l=1796;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=EqLdZR8cjHuyGGI5BXPc4y5RppVuc83EKeDLoTQ6DB4=;
 b=sx8H+UuquyJaYcDJrY/E91i+kcVZ05EXGkglT11SjCY2W6ytTrqy9MnKlj9Bsk2QtZbGZyUOo
 JwMgRmIzHdrDHKyaVEBRphl3F4tL/mm53auxaIe3BEkBbgeNYOY7HS1
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Andy Shevchenko <andriy.shevchenko@linux.intel.com>

Instead of having different functions that just use default parameters,
combine those to use variadic arguments, so the user may call it using
the same name.

Signed-off-by: Andy Shevchenko <andriy.shevchenko@linux.intel.com>
Acked-by: Petr Mladek <pmladek@suse.com>
Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 lib/kstrtox.c | 6 ------
 lib/kstrtox.h | 9 ++++++++-
 2 files changed, 8 insertions(+), 7 deletions(-)

diff --git a/lib/kstrtox.c b/lib/kstrtox.c
index 97be2a39f537..0399856713c1 100644
--- a/lib/kstrtox.c
+++ b/lib/kstrtox.c
@@ -87,12 +87,6 @@ unsigned int _parse_integer_limit(const char *s, unsigned int base, unsigned lon
 	return rv;
 }
 
-noinline
-unsigned int _parse_integer(const char *s, unsigned int base, unsigned long long *p)
-{
-	return _parse_integer_limit(s, base, p, INT_MAX);
-}
-
 static int _kstrtoull(const char *s, unsigned int base, unsigned long long *res)
 {
 	unsigned long long _res;
diff --git a/lib/kstrtox.h b/lib/kstrtox.h
index 158c400ca865..00cf3255bdd2 100644
--- a/lib/kstrtox.h
+++ b/lib/kstrtox.h
@@ -2,10 +2,17 @@
 #ifndef _LIB_KSTRTOX_H
 #define _LIB_KSTRTOX_H
 
+#include <linux/args.h>
+
 #define KSTRTOX_OVERFLOW	(1U << 31)
 const char *_parse_integer_fixup_radix(const char *s, unsigned int *base);
 unsigned int _parse_integer_limit(const char *s, unsigned int base, unsigned long long *res,
 				  size_t max_chars);
-unsigned int _parse_integer(const char *s, unsigned int base, unsigned long long *res);
+
+#define _parse_integer0(s, base, res, ...)						\
+	_parse_integer_limit(s, base, res, INT_MAX)
+
+#define _parse_integer(s, base, res, ...)						\
+	CONCATENATE(_parse_integer, COUNT_ARGS(__VA_ARGS__))(s, base, res, __VA_ARGS__)
 
 #endif

-- 
2.43.0

