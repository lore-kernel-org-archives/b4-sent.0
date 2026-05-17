From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Sun, 17 May 2026 10:13:57 +0100
Subject: [PATCH v13 02/12] iio: kstrtox: add local
 _parse_integer_limit_init() helper
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260517-adf41513-iio-driver-v13-2-bb6e134a360f@analog.com>
References: <20260517-adf41513-iio-driver-v13-0-bb6e134a360f@analog.com>
In-Reply-To: <20260517-adf41513-iio-driver-v13-0-bb6e134a360f@analog.com>
To: linux-kernel@vger.kernel.org, linux-iio@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-doc@vger.kernel.org
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779009279; l=2705;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=mGRnMQZeAYz6SA0BAdOFz4NmZ5AZL80o15nnDtMxAeE=;
 b=PcQ1Fq/lSTC4mjgow6RknzXzQDlL+zzswGaRCQRhqMbPvSMka8Gng2KFKvSKgFmiVz20/JDYp
 itBpsK4ErmwBcALil/lechOEHX4/7Ls35bFTrI9yD4HzX0D4QF1IoWz
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add parsing helper that accepts an initial value for the accumulated
result when parsing an 64-bit integer. It reuses current implementation
for _parse_integer_limit(), which now consumes the new function with
init = 0. The diff algorithm would have the documentation header and
prototype of _parse_integer_limit() moved around so it is adjusted
according to guidelines.

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 lib/kstrtox.c | 39 ++++++++++++++++++++++++++-------------
 1 file changed, 26 insertions(+), 13 deletions(-)

diff --git a/lib/kstrtox.c b/lib/kstrtox.c
index 97be2a39f537..0705461f51c0 100644
--- a/lib/kstrtox.c
+++ b/lib/kstrtox.c
@@ -39,23 +39,15 @@ const char *_parse_integer_fixup_radix(const char *s, unsigned int *base)
 	return s;
 }
 
-/*
- * Convert non-negative integer string representation in explicitly given radix
- * to an integer. A maximum of max_chars characters will be converted.
- *
- * Return number of characters consumed maybe or-ed with overflow bit.
- * If overflow occurs, result integer (incorrect) is still returned.
- *
- * Don't you dare use this function.
- */
-noinline
-unsigned int _parse_integer_limit(const char *s, unsigned int base, unsigned long long *p,
-				  size_t max_chars)
+static unsigned int _parse_integer_limit_init(const char *s, unsigned int base,
+					      unsigned long long init,
+					      unsigned long long *p,
+					      size_t max_chars)
 {
 	unsigned long long res;
 	unsigned int rv;
 
-	res = 0;
+	res = init;
 	rv = 0;
 	while (max_chars--) {
 		unsigned int c = *s;
@@ -87,6 +79,27 @@ unsigned int _parse_integer_limit(const char *s, unsigned int base, unsigned lon
 	return rv;
 }
 
+/**
+ * _parse_integer_limit() - Convert integer string representation to an integer
+ *			    limiting the number of characters parsed.
+ * @s: The start of the string.
+ * @base: The number base to use.
+ * @p: Where to write the result of the conversion.
+ * @max_chars: Maximum amount of characters to consume.
+ *
+ * Convert non-negative integer string representation in explicitly given radix
+ * to an integer. A maximum of max_chars characters will be converted.
+ *
+ * Return: Number of characters consumed maybe or-ed with overflow bit.
+ *	   If overflow occurs, result integer (incorrect) is still returned.
+ */
+noinline
+unsigned int _parse_integer_limit(const char *s, unsigned int base,
+				  unsigned long long *p, size_t max_chars)
+{
+	return _parse_integer_limit_init(s, base, 0, p, max_chars);
+}
+
 noinline
 unsigned int _parse_integer(const char *s, unsigned int base, unsigned long long *p)
 {

-- 
2.43.0

