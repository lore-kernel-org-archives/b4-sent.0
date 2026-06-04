From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Thu, 04 Jun 2026 10:58:58 +0100
Subject: [PATCH v16 04/14] lib: kstrtox: add initial value to
 _parse_integer_limit()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260604-adf41513-iio-driver-v16-4-1a7d09143bc2@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780567181; l=2039;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=E5LdU8JOCTVd77KslWCd6DlpfzZCyFPV4Z1fW685/A4=;
 b=cN8sRipwhFQl1XXm6PbB5GabZgWh4kkqLQz+4qpJUL9BD0fzRI4ASVs4V7JRshsmhxVUlG/Ql
 ZJUUmAHcvOACpegWpB0ivzTtQtcCHU1FsTfwaW8s5QrVyOEjKwtJV4e
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add init parameter to _parse_integer_limit() that defines an initial
value for the accumulated result when parsing an 64-bit integer. The
new function prototype is adjusted so that the _parse_integer() macros
stay consistent allowing for one more argument, which defaults to 0.

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 lib/kstrtox.c | 4 ++--
 lib/kstrtox.h | 9 ++++++---
 2 files changed, 8 insertions(+), 5 deletions(-)

diff --git a/lib/kstrtox.c b/lib/kstrtox.c
index 0399856713c1..cc6869a97bf2 100644
--- a/lib/kstrtox.c
+++ b/lib/kstrtox.c
@@ -50,12 +50,12 @@ const char *_parse_integer_fixup_radix(const char *s, unsigned int *base)
  */
 noinline
 unsigned int _parse_integer_limit(const char *s, unsigned int base, unsigned long long *p,
-				  size_t max_chars)
+				  size_t max_chars, unsigned long long init)
 {
 	unsigned long long res;
 	unsigned int rv;
 
-	res = 0;
+	res = init;
 	rv = 0;
 	while (max_chars--) {
 		unsigned int c = *s;
diff --git a/lib/kstrtox.h b/lib/kstrtox.h
index ff84fe434a00..73dee79fd8ed 100644
--- a/lib/kstrtox.h
+++ b/lib/kstrtox.h
@@ -7,13 +7,16 @@
 #define KSTRTOX_OVERFLOW	(1U << 31)
 const char *_parse_integer_fixup_radix(const char *s, unsigned int *base);
 unsigned int _parse_integer_limit(const char *s, unsigned int base, unsigned long long *res,
-				  size_t max_chars);
+				  size_t max_chars, unsigned long long init);
 
 #define _parse_integer0(s, base, res, ...)						\
-	_parse_integer_limit(s, base, res, INT_MAX)
+	_parse_integer_limit(s, base, res, INT_MAX, 0)
 
 #define _parse_integer1(s, base, res, max_chars, ...)					\
-	_parse_integer_limit(s, base, res, max_chars)
+	_parse_integer_limit(s, base, res, max_chars, 0)
+
+#define _parse_integer2(s, base, res, max_chars, init, ...)				\
+	_parse_integer_limit(s, base, res, max_chars, init)
 
 #define _parse_integer(s, base, res, ...)						\
 	CONCATENATE(_parse_integer, COUNT_ARGS(__VA_ARGS__))(s, base, res, __VA_ARGS__)

-- 
2.43.0

