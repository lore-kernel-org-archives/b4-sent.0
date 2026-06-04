From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Thu, 04 Jun 2026 10:58:57 +0100
Subject: [PATCH v16 03/14] lib: vsprintf: use _parse_integer() instead of
 _parse_integer_limit()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260604-adf41513-iio-driver-v16-3-1a7d09143bc2@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780567181; l=1516;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=HnHwwNxnBXJiolG9zBUbHrPgMO46GbC/RCE69yuI1/o=;
 b=3u1uRjndj72I3RRHTZ/96+S5fBdcevBkPJrFmkplGDrC66PxSMptJrMQzvs3ikSOT33yDJUVy
 BzLeid1vQuCBCSTB+g+s34w96MbUahV9/dUD4qRnl5Xc8gpL2nkjmgy
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Andy Shevchenko <andriy.shevchenko@linux.intel.com>

Use _parse_integer() that allows optional arguments to be explicitly
initialised.

Signed-off-by: Andy Shevchenko <andriy.shevchenko@linux.intel.com>
Acked-by: Petr Mladek <pmladek@suse.com>
Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 lib/kstrtox.h  | 3 +++
 lib/vsprintf.c | 2 +-
 2 files changed, 4 insertions(+), 1 deletion(-)

diff --git a/lib/kstrtox.h b/lib/kstrtox.h
index 00cf3255bdd2..ff84fe434a00 100644
--- a/lib/kstrtox.h
+++ b/lib/kstrtox.h
@@ -12,6 +12,9 @@ unsigned int _parse_integer_limit(const char *s, unsigned int base, unsigned lon
 #define _parse_integer0(s, base, res, ...)						\
 	_parse_integer_limit(s, base, res, INT_MAX)
 
+#define _parse_integer1(s, base, res, max_chars, ...)					\
+	_parse_integer_limit(s, base, res, max_chars)
+
 #define _parse_integer(s, base, res, ...)						\
 	CONCATENATE(_parse_integer, COUNT_ARGS(__VA_ARGS__))(s, base, res, __VA_ARGS__)
 
diff --git a/lib/vsprintf.c b/lib/vsprintf.c
index 9f359b31c8d1..e6cf5f62738d 100644
--- a/lib/vsprintf.c
+++ b/lib/vsprintf.c
@@ -86,7 +86,7 @@ static unsigned long long simple_strntoull(const char *startp, char **endp, unsi
 	cp = _parse_integer_fixup_radix(startp, &base);
 	prefix_chars = cp - startp;
 	if (prefix_chars < max_chars) {
-		rv = _parse_integer_limit(cp, base, &result, max_chars - prefix_chars);
+		rv = _parse_integer(cp, base, &result, max_chars - prefix_chars);
 		/* FIXME */
 		cp += (rv & ~KSTRTOX_OVERFLOW);
 	} else {

-- 
2.43.0

